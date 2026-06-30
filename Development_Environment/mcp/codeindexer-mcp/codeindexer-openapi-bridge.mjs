#!/usr/bin/env node
"use strict";

import http from "node:http";
import { spawn } from "node:child_process";
import path from "node:path";
import fs from "node:fs";

const PORT = Number(process.env.CODEINDEXER_BRIDGE_PORT || "8096");
const CODEINDEXER_REPO_DIR = process.env.CODEINDEXER_REPO_DIR || "/codeindexer";
const CODEINDEXER_STATE_DIR = process.env.CODEINDEXER_STATE_DIR || "/codeindexer-state";
const CODEINDEXER_WORKSPACE = process.env.CODEINDEXER_WORKSPACE || "/workspace";
const CODEINDEXER_GITHUB_WORKSPACE = process.env.CODEINDEXER_GITHUB_WORKSPACE || "/codeindexer-github";
const CODEINDEXER_HOST_WORKSPACE = process.env.CODEINDEXER_HOST_WORKSPACE || "";
const CODEINDEXER_MCP_SCRIPT =
  process.env.CODEINDEXER_MCP_SCRIPT || path.join(CODEINDEXER_REPO_DIR, "packages/mcp/dist/index.js");
const OPENAI_API_KEY = process.env.OPENAI_API_KEY || process.env.FORTISAI_LLAMA_OPENAI_API_KEY || "local-llama";
const OPENAI_BASE_URL = process.env.OPENAI_BASE_URL || "http://fortisai-mcp-openapi-dify.fortisai.local:8093/v1";
const OPENAI_EMBEDDING_MODEL = process.env.OPENAI_EMBEDDING_MODEL || "fortisai";
const OPENAI_EMBEDDING_DIMENSION = process.env.OPENAI_EMBEDDING_DIMENSION || "";
const MILVUS_ADDRESS = process.env.MILVUS_ADDRESS || "fortisai-milvus.fortisai.local:19530";
const MILVUS_TOKEN = process.env.MILVUS_TOKEN || "";
const MCP_TIMEOUT_MS = Number(process.env.CODEINDEXER_MCP_TIMEOUT_MS || "900000");
const GITHUB_TOKEN = process.env.CODEINDEXER_GITHUB_TOKEN || process.env.GITHUB_TOKEN || "";
const GITHUB_ALLOWED_ORGS = String(process.env.CODEINDEXER_GITHUB_ALLOWED_ORGS || "")
  .split(",")
  .map((item) => item.trim().toLowerCase())
  .filter(Boolean);
const GITHUB_ALLOWED_REPOS = String(process.env.CODEINDEXER_GITHUB_ALLOWED_REPOS || "")
  .split(",")
  .map((item) => item.trim().toLowerCase())
  .filter(Boolean);

function sendJson(res, status, payload) {
  const body = JSON.stringify(payload, null, 2);
  res.writeHead(status, {
    "content-type": "application/json; charset=utf-8",
    "content-length": Buffer.byteLength(body),
  });
  res.end(body);
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let body = "";
    req.on("data", (chunk) => {
      body += chunk;
      if (body.length > 10 * 1024 * 1024) {
        reject(new Error("request body too large"));
        req.destroy();
      }
    });
    req.on("end", () => {
      if (!body.trim()) {
        resolve({});
        return;
      }
      try {
        resolve(JSON.parse(body));
      } catch (error) {
        reject(new Error(`invalid JSON body: ${error.message}`));
      }
    });
    req.on("error", reject);
  });
}

function normalizeCodebasePath(inputPath) {
  const rawPath = String(inputPath || "").trim() || CODEINDEXER_WORKSPACE;
  if (CODEINDEXER_HOST_WORKSPACE && rawPath.startsWith(CODEINDEXER_HOST_WORKSPACE)) {
    return path.join(CODEINDEXER_WORKSPACE, rawPath.slice(CODEINDEXER_HOST_WORKSPACE.length));
  }
  return rawPath;
}


function parseGithubRepository(input) {
  const raw = String(input || "").trim();
  if (!raw) throw new Error("repository is required");

  let owner = "";
  let repo = "";
  if (/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(raw)) {
    [owner, repo] = raw.split("/", 2);
  } else {
    const parsed = new URL(raw.replace(/^git@github\.com:/, "https://github.com/"));
    if (parsed.hostname.toLowerCase() !== "github.com") {
      throw new Error("only github.com repositories are supported");
    }
    const parts = parsed.pathname.replace(/^\/+/, "").replace(/\.git$/, "").split("/");
    owner = parts[0] || "";
    repo = parts[1] || "";
  }

  if (!/^[A-Za-z0-9_.-]+$/.test(owner) || !/^[A-Za-z0-9_.-]+$/.test(repo)) {
    throw new Error("invalid GitHub owner or repository name");
  }
  const fullName = `${owner}/${repo}`;
  const normalized = fullName.toLowerCase();
  if (GITHUB_ALLOWED_ORGS.length && !GITHUB_ALLOWED_ORGS.includes(owner.toLowerCase())) {
    throw new Error(`GitHub owner is not allowed by FortisAI policy: ${owner}`);
  }
  if (GITHUB_ALLOWED_REPOS.length && !GITHUB_ALLOWED_REPOS.includes(normalized)) {
    throw new Error(`GitHub repository is not allowed by FortisAI policy: ${fullName}`);
  }

  return {
    owner,
    repo,
    fullName,
    cloneUrl: `https://github.com/${owner}/${repo}.git`,
  };
}

function safeRef(inputRef) {
  const ref = String(inputRef || "default").trim() || "default";
  if (!/^[A-Za-z0-9._/-]+$/.test(ref) || ref.includes("..")) {
    throw new Error("invalid Git ref");
  }
  return ref;
}

function githubRepoPath(repository, ref = "default") {
  const repo = parseGithubRepository(repository);
  const refValue = safeRef(ref);
  const refName = refValue.replace(/\//g, "__");
  return {
    ...repo,
    ref: refValue,
    localPath: path.join(CODEINDEXER_GITHUB_WORKSPACE, "github.com", repo.owner, repo.repo, refName),
  };
}

function runCommand(command, args, options = {}, timeoutMs = 300000) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      ...options,
      stdio: ["ignore", "pipe", "pipe"],
    });
    let stdout = "";
    let stderr = "";
    const timer = setTimeout(() => {
      child.kill("SIGTERM");
      reject(new Error(`${command} timed out after ${timeoutMs}ms`));
    }, timeoutMs);
    child.stdout.on("data", (chunk) => (stdout += chunk.toString("utf8")));
    child.stderr.on("data", (chunk) => (stderr += chunk.toString("utf8")));
    child.on("error", (error) => {
      clearTimeout(timer);
      reject(error);
    });
    child.on("exit", (code) => {
      clearTimeout(timer);
      if (code === 0) {
        resolve({ code, stdout: stdout.slice(-4000), stderr: stderr.slice(-4000) });
      } else {
        reject(new Error(`${command} exited with code ${code}: ${stderr.slice(-4000)}`));
      }
    });
  });
}

function gitAuthArgs() {
  if (!GITHUB_TOKEN) return [];
  return ["-c", `http.https://github.com/.extraheader=Authorization: Bearer ${GITHUB_TOKEN}`];
}

async function cloneOrPullGithubRepository(repository, ref = "default", force = false, timeoutMs = 900000) {
  const target = githubRepoPath(repository, ref);
  fs.mkdirSync(path.dirname(target.localPath), { recursive: true });
  const gitArgs = gitAuthArgs();
  if (fs.existsSync(path.join(target.localPath, ".git"))) {
    await runCommand("git", [...gitArgs, "fetch", "--prune", "origin"], { cwd: target.localPath }, timeoutMs);
  } else {
    if (fs.existsSync(target.localPath) && force) {
      fs.rmSync(target.localPath, { recursive: true, force: true });
    }
    if (!fs.existsSync(target.localPath)) {
      await runCommand("git", [...gitArgs, "clone", "--filter=blob:none", target.cloneUrl, target.localPath], {}, timeoutMs);
    }
  }
  if (target.ref !== "default") {
    await runCommand("git", [...gitArgs, "checkout", target.ref], { cwd: target.localPath }, timeoutMs);
    await runCommand("git", [...gitArgs, "pull", "--ff-only"], { cwd: target.localPath }, timeoutMs).catch(() => null);
  } else {
    await runCommand("git", [...gitArgs, "pull", "--ff-only"], { cwd: target.localPath }, timeoutMs).catch(() => null);
  }
  const rev = await runCommand("git", ["rev-parse", "--short", "HEAD"], { cwd: target.localPath }, 30000);
  return {
    ok: true,
    repository: target.fullName,
    ref: target.ref,
    path: target.localPath,
    commit: rev.stdout.trim(),
    has_github_token: Boolean(GITHUB_TOKEN),
  };
}

function listGithubRepositories() {
  const root = path.join(CODEINDEXER_GITHUB_WORKSPACE, "github.com");
  const repos = [];
  if (!fs.existsSync(root)) return repos;
  for (const owner of fs.readdirSync(root)) {
    const ownerPath = path.join(root, owner);
    if (!fs.statSync(ownerPath).isDirectory()) continue;
    for (const repo of fs.readdirSync(ownerPath)) {
      const repoRoot = path.join(ownerPath, repo);
      if (!fs.statSync(repoRoot).isDirectory()) continue;
      for (const ref of fs.readdirSync(repoRoot)) {
        const localPath = path.join(repoRoot, ref);
        if (fs.existsSync(path.join(localPath, ".git"))) {
          repos.push({ repository: `${owner}/${repo}`, ref: ref.replace(/__/g, "/"), path: localPath });
        }
      }
    }
  }
  return repos;
}

function mcpEnvironment() {
  return {
    ...process.env,
    HOME: CODEINDEXER_STATE_DIR,
    MCP_SERVER_NAME: "FortisAI CodeIndexer MCP Server",
    MCP_SERVER_VERSION: "1.0.0",
    OPENAI_API_KEY,
    OPENAI_BASE_URL,
    OPENAI_EMBEDDING_MODEL,
    OPENAI_EMBEDDING_DIMENSION,
    MILVUS_ADDRESS,
    MILVUS_TOKEN,
  };
}

function flattenMcpText(result) {
  const content = Array.isArray(result?.content) ? result.content : [];
  return content
    .filter((item) => item && item.type === "text" && typeof item.text === "string")
    .map((item) => item.text)
    .join("\n");
}

function runMcpRequest(method, params = {}, timeoutMs = MCP_TIMEOUT_MS) {
  return new Promise((resolve, reject) => {
    if (!fs.existsSync(CODEINDEXER_MCP_SCRIPT)) {
      reject(new Error(`CodeIndexer MCP build not found: ${CODEINDEXER_MCP_SCRIPT}`));
      return;
    }

    fs.mkdirSync(CODEINDEXER_STATE_DIR, { recursive: true });

    const child = spawn("node", [CODEINDEXER_MCP_SCRIPT], {
      cwd: CODEINDEXER_REPO_DIR,
      env: mcpEnvironment(),
      stdio: ["pipe", "pipe", "pipe"],
    });

    let nextId = 1;
    const pending = new Map();
    const stderrChunks = [];
    let stdoutBuffer = "";
    let settled = false;

    const timer = setTimeout(() => {
      child.kill("SIGTERM");
      reject(new Error(`CodeIndexer MCP request timed out after ${timeoutMs}ms`));
    }, timeoutMs);

    function cleanup() {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      child.kill("SIGTERM");
    }

    function send(methodName, requestParams, waitForResponse = true) {
      const payload = { jsonrpc: "2.0", method: methodName };
      let id = null;
      if (waitForResponse) {
        id = nextId++;
        payload.id = id;
      }
      if (requestParams !== undefined) payload.params = requestParams;
      child.stdin.write(`${JSON.stringify(payload)}\n`);
      if (!waitForResponse) return Promise.resolve(null);
      return new Promise((res, rej) => pending.set(id, { resolve: res, reject: rej }));
    }

    child.stderr.on("data", (chunk) => stderrChunks.push(chunk.toString("utf8")));
    child.stdout.on("data", (chunk) => {
      stdoutBuffer += chunk.toString("utf8");
      let newlineIndex;
      while ((newlineIndex = stdoutBuffer.indexOf("\n")) >= 0) {
        const rawLine = stdoutBuffer.slice(0, newlineIndex).trim();
        stdoutBuffer = stdoutBuffer.slice(newlineIndex + 1);
        if (!rawLine) continue;
        let message;
        try {
          message = JSON.parse(rawLine);
        } catch {
          stderrChunks.push(`[stdout] ${rawLine}`);
          continue;
        }
        if (message.id !== undefined && pending.has(message.id)) {
          const waiter = pending.get(message.id);
          pending.delete(message.id);
          if (message.error) {
            waiter.reject(new Error(JSON.stringify(message.error)));
          } else {
            waiter.resolve(message.result);
          }
        }
      }
    });

    child.on("error", (error) => {
      cleanup();
      reject(error);
    });

    child.on("exit", (code) => {
      if (!settled && code !== null && code !== 0 && pending.size > 0) {
        cleanup();
        reject(new Error(`CodeIndexer MCP exited with code ${code}: ${stderrChunks.join("").slice(-4000)}`));
      }
    });

    (async () => {
      try {
        await send("initialize", {
          protocolVersion: "2024-11-05",
          capabilities: {},
          clientInfo: { name: "fortisai-codeindexer-openapi-bridge", version: "1.0.0" },
        });
        await send("notifications/initialized", {}, false);
        const result = await send(method, params);
        cleanup();
        resolve({
          ok: !result?.isError,
          text: flattenMcpText(result),
          result,
          stderr: stderrChunks.join("").slice(-4000),
        });
      } catch (error) {
        cleanup();
        reject(error);
      }
    })();
  });
}

async function mcpToolCall(name, args, timeoutMs = MCP_TIMEOUT_MS) {
  return runMcpRequest("tools/call", { name, arguments: args }, timeoutMs);
}

function openapiSpec() {
  return {
    openapi: "3.1.0",
    info: {
      title: "fortisai-codeindexer-openapi-bridge",
      version: "1.0.0",
      description: "OpenAPI facade for the CodeIndexer MCP semantic code indexing tools.",
    },
    paths: {
      "/healthz": { get: { operationId: "codeindexer_healthz", responses: { "200": { description: "OK" } } } },
      "/codeindexer_connection_info": {
        get: { operationId: "codeindexer_connection_info", responses: { "200": { description: "Connection info" } } },
      },
      "/codeindexer_tools": {
        get: { operationId: "codeindexer_tools", responses: { "200": { description: "MCP tools" } } },
      },
      "/codeindexer_index": {
        post: {
          operationId: "codeindexer_index",
          summary: "Index a codebase path for semantic search",
          requestBody: { required: true, content: { "application/json": { schema: { $ref: "#/components/schemas/IndexRequest" } } } },
          responses: { "200": { description: "Index result" } },
        },
      },
      "/codeindexer_search": {
        post: {
          operationId: "codeindexer_search",
          summary: "Search an indexed codebase with a natural-language query",
          requestBody: { required: true, content: { "application/json": { schema: { $ref: "#/components/schemas/SearchRequest" } } } },
          responses: { "200": { description: "Search result" } },
        },
      },
      "/codeindexer_clear": {
        post: {
          operationId: "codeindexer_clear",
          summary: "Clear the CodeIndexer index for a codebase path",
          requestBody: { required: true, content: { "application/json": { schema: { $ref: "#/components/schemas/ClearRequest" } } } },
          responses: { "200": { description: "Clear result" } },
        },
      },
      "/codeindexer_mcp_tool": {
        post: {
          operationId: "codeindexer_mcp_tool",
          summary: "Call a raw CodeIndexer MCP tool",
          requestBody: { required: true, content: { "application/json": { schema: { $ref: "#/components/schemas/McpToolRequest" } } } },
          responses: { "200": { description: "MCP tool result" } },
        },
      },
      "/codeindexer_clone_github_repository": {
        post: { operationId: "codeindexer_clone_github_repository", summary: "Clone or update a GitHub repository into the FortisAI CodeIndexer cache", requestBody: { required: true, content: { "application/json": { schema: { $ref: "#/components/schemas/GithubRepositoryRequest" } } } }, responses: { "200": { description: "Clone or update result" } } },
      },
      "/codeindexer_pull_github_repository": {
        post: { operationId: "codeindexer_pull_github_repository", summary: "Pull updates for a cached GitHub repository", requestBody: { required: true, content: { "application/json": { schema: { $ref: "#/components/schemas/GithubRepositoryRequest" } } } }, responses: { "200": { description: "Pull result" } } },
      },
      "/codeindexer_index_github_repository": {
        post: { operationId: "codeindexer_index_github_repository", summary: "Clone or update and then index a GitHub repository", requestBody: { required: true, content: { "application/json": { schema: { $ref: "#/components/schemas/GithubIndexRequest" } } } }, responses: { "200": { description: "GitHub index result" } } },
      },
      "/codeindexer_search_github_repository": {
        post: { operationId: "codeindexer_search_github_repository", summary: "Search an indexed GitHub repository", requestBody: { required: true, content: { "application/json": { schema: { $ref: "#/components/schemas/GithubSearchRequest" } } } }, responses: { "200": { description: "GitHub search result" } } },
      },
      "/codeindexer_list_github_repositories": {
        get: { operationId: "codeindexer_list_github_repositories", responses: { "200": { description: "Cached GitHub repositories" } } },
      },
    },
    components: {
      schemas: {
        IndexRequest: {
          type: "object",
          properties: {
            path: { type: "string", description: "Codebase path. Defaults to the mounted FortisAI workspace." },
            force: { type: "boolean", default: false },
            splitter: { type: "string", enum: ["ast", "langchain"], default: "ast" },
          },
        },
        SearchRequest: {
          type: "object",
          required: ["query"],
          properties: {
            path: { type: "string", description: "Codebase path. Defaults to the mounted FortisAI workspace." },
            query: { type: "string" },
            limit: { type: "integer", default: 10, minimum: 1, maximum: 50 },
          },
        },
        ClearRequest: {
          type: "object",
          properties: { path: { type: "string", description: "Codebase path. Defaults to the mounted FortisAI workspace." } },
        },
        McpToolRequest: {
          type: "object",
          required: ["name"],
          properties: {
            name: { type: "string" },
            arguments: { type: "object", additionalProperties: true },
            timeoutMs: { type: "integer", default: MCP_TIMEOUT_MS },
          },
        },
        GithubRepositoryRequest: {
          type: "object",
          required: ["repository"],
          properties: {
            repository: { type: "string", description: "GitHub repository URL or owner/repo." },
            ref: { type: "string", default: "default", description: "Branch, tag, or commit. Use default for the repository default branch." },
            force: { type: "boolean", default: false },
            timeoutMs: { type: "integer", default: MCP_TIMEOUT_MS },
          },
        },
        GithubIndexRequest: {
          type: "object",
          required: ["repository"],
          properties: {
            repository: { type: "string" },
            ref: { type: "string", default: "default" },
            force: { type: "boolean", default: false },
            splitter: { type: "string", enum: ["ast", "langchain"], default: "ast" },
            timeoutMs: { type: "integer", default: MCP_TIMEOUT_MS },
          },
        },
        GithubSearchRequest: {
          type: "object",
          required: ["repository", "query"],
          properties: {
            repository: { type: "string" },
            ref: { type: "string", default: "default" },
            query: { type: "string" },
            limit: { type: "integer", default: 10, minimum: 1, maximum: 50 },
            timeoutMs: { type: "integer", default: MCP_TIMEOUT_MS },
          },
        },
      },
    },
  };
}

async function route(req, res) {
  const url = new URL(req.url || "/", `http://${req.headers.host || "localhost"}`);
  try {
    if (req.method === "GET" && url.pathname === "/healthz") {
      sendJson(res, 200, {
        status: "ok",
        mcp_built: fs.existsSync(CODEINDEXER_MCP_SCRIPT),
        codeindexer_repo_dir: CODEINDEXER_REPO_DIR,
      });
      return;
    }
    if (req.method === "GET" && url.pathname === "/openapi.json") {
      sendJson(res, 200, openapiSpec());
      return;
    }
    if (req.method === "GET" && url.pathname === "/codeindexer_connection_info") {
      sendJson(res, 200, {
        codeindexer_repo_dir: CODEINDEXER_REPO_DIR,
        codeindexer_workspace: CODEINDEXER_WORKSPACE,
        codeindexer_github_workspace: CODEINDEXER_GITHUB_WORKSPACE,
        codeindexer_host_workspace: CODEINDEXER_HOST_WORKSPACE,
        codeindexer_state_dir: CODEINDEXER_STATE_DIR,
        mcp_script: CODEINDEXER_MCP_SCRIPT,
        mcp_built: fs.existsSync(CODEINDEXER_MCP_SCRIPT),
        milvus_address: MILVUS_ADDRESS,
        has_milvus_token: Boolean(MILVUS_TOKEN),
        openai_base_url: OPENAI_BASE_URL,
        openai_embedding_model: OPENAI_EMBEDDING_MODEL,
        openai_embedding_dimension: OPENAI_EMBEDDING_DIMENSION || "auto",
        has_openai_api_key: Boolean(OPENAI_API_KEY),
        has_github_token: Boolean(GITHUB_TOKEN),
        github_allowed_orgs: GITHUB_ALLOWED_ORGS,
        github_allowed_repos: GITHUB_ALLOWED_REPOS,
      });
      return;
    }
    if (req.method === "GET" && url.pathname === "/codeindexer_tools") {
      sendJson(res, 200, await runMcpRequest("tools/list", {}));
      return;
    }
    if (req.method === "POST" && url.pathname === "/codeindexer_index") {
      const body = await readBody(req);
      const args = {
        path: normalizeCodebasePath(body.path),
        force: Boolean(body.force),
        splitter: body.splitter || "ast",
      };
      sendJson(res, 200, await mcpToolCall("index_codebase", args, Number(body.timeoutMs || MCP_TIMEOUT_MS)));
      return;
    }
    if (req.method === "POST" && url.pathname === "/codeindexer_search") {
      const body = await readBody(req);
      const args = {
        path: normalizeCodebasePath(body.path),
        query: String(body.query || ""),
        limit: Math.max(1, Math.min(Number(body.limit || 10), 50)),
      };
      if (!args.query.trim()) throw new Error("query is required");
      sendJson(res, 200, await mcpToolCall("search_code", args, Number(body.timeoutMs || MCP_TIMEOUT_MS)));
      return;
    }
    if (req.method === "POST" && url.pathname === "/codeindexer_clear") {
      const body = await readBody(req);
      sendJson(res, 200, await mcpToolCall("clear_index", { path: normalizeCodebasePath(body.path) }, Number(body.timeoutMs || MCP_TIMEOUT_MS)));
      return;
    }
    if (req.method === "POST" && url.pathname === "/codeindexer_mcp_tool") {
      const body = await readBody(req);
      if (!body.name) throw new Error("name is required");
      sendJson(res, 200, await mcpToolCall(String(body.name), body.arguments || {}, Number(body.timeoutMs || MCP_TIMEOUT_MS)));
      return;
    }

    if (req.method === "POST" && (url.pathname === "/codeindexer_clone_github_repository" || url.pathname === "/codeindexer_pull_github_repository")) {
      const body = await readBody(req);
      sendJson(res, 200, await cloneOrPullGithubRepository(body.repository, body.ref || "default", Boolean(body.force), Number(body.timeoutMs || MCP_TIMEOUT_MS)));
      return;
    }
    if (req.method === "POST" && url.pathname === "/codeindexer_index_github_repository") {
      const body = await readBody(req);
      const cloned = await cloneOrPullGithubRepository(body.repository, body.ref || "default", Boolean(body.force), Number(body.timeoutMs || MCP_TIMEOUT_MS));
      const result = await mcpToolCall("index_codebase", {
        path: cloned.path,
        force: Boolean(body.force),
        splitter: body.splitter || "ast",
      }, Number(body.timeoutMs || MCP_TIMEOUT_MS));
      sendJson(res, 200, { ok: result.ok, repository: cloned, index: result });
      return;
    }
    if (req.method === "POST" && url.pathname === "/codeindexer_search_github_repository") {
      const body = await readBody(req);
      const target = githubRepoPath(body.repository, body.ref || "default");
      if (!fs.existsSync(path.join(target.localPath, ".git"))) {
        throw new Error(`GitHub repository is not cached yet: ${target.fullName} (${target.ref})`);
      }
      const query = String(body.query || "");
      if (!query.trim()) throw new Error("query is required");
      sendJson(res, 200, await mcpToolCall("search_code", {
        path: target.localPath,
        query,
        limit: Math.max(1, Math.min(Number(body.limit || 10), 50)),
      }, Number(body.timeoutMs || MCP_TIMEOUT_MS)));
      return;
    }
    if (req.method === "GET" && url.pathname === "/codeindexer_list_github_repositories") {
      sendJson(res, 200, { ok: true, repositories: listGithubRepositories() });
      return;
    }
    sendJson(res, 404, { error: "not found" });
  } catch (error) {
    sendJson(res, 500, { ok: false, error: error.message || String(error) });
  }
}

http.createServer(route).listen(PORT, "0.0.0.0", () => {
  process.stderr.write(`fortisai-codeindexer-openapi-bridge listening on ${PORT}\n`);
});
