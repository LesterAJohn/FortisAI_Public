#!/usr/bin/env node
"use strict";

import http from "node:http";
import { spawn } from "node:child_process";

const port = Number(process.env.FORTISAI_N8N_WORKFLOW_RUNNER_PORT || 5680);
const bindHost = process.env.FORTISAI_N8N_WORKFLOW_RUNNER_HOST || "0.0.0.0";
const runnerToken = process.env.FORTISAI_N8N_WORKFLOW_RUNNER_TOKEN || "";
const classifierScript = process.env.FORTISAI_LLM_ROUTER_SCRIPT || "/FortisAI/Development_Environment/n8n-config/main/n8n/scripts/classify-local-llm-router.mjs";
const difyModelSetupScript = process.env.FORTISAI_DIFY_MODEL_SETUP_SCRIPT || "/FortisAI/Development_Environment/dify-config/main/dify/generated/setup-openai-compatible-models.mjs";
const difyRouterImportScript = process.env.FORTISAI_DIFY_ROUTER_IMPORT_SCRIPT || "/FortisAI/Development_Environment/dify-config/main/dify/generated/import-local-openai-compatible-router.mjs";

let running = false;

function sendJson(res, statusCode, payload) {
  res.writeHead(statusCode, { "content-type": "application/json; charset=utf-8" });
  res.end(JSON.stringify(payload, null, 2) + "\n");
}

function authorize(req, res) {
  if (!runnerToken) return true;
  if (req.headers.authorization === `Bearer ${runnerToken}`) return true;
  sendJson(res, 401, { status: "error", message: "unauthorized" });
  return false;
}

function tail(text, maxLength = 12000) {
  return text.length > maxLength ? text.slice(text.length - maxLength) : text;
}

function extractLastJson(text) {
  const raw = String(text || "").trim();
  let start = raw.lastIndexOf("{");
  while (start >= 0) {
    try {
      return JSON.parse(raw.slice(start));
    } catch (_) {
      start = raw.lastIndexOf("{", start - 1);
    }
  }
  return null;
}

function runNodeScript(res, script, workflowName) {
  if (running) {
    sendJson(res, 409, { status: "error", message: "workflow runner is already executing" });
    return;
  }

  running = true;
  const startedAt = new Date();
  let stdout = "";
  let stderr = "";

  res.writeHead(200, { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" });
  const keepAlive = setInterval(() => res.write("\n"), 15000);

  const child = spawn(process.execPath, [script], {
    env: { ...process.env },
    stdio: ["ignore", "pipe", "pipe"],
  });

  child.stdout.on("data", (chunk) => { stdout = tail(stdout + chunk.toString()); });
  child.stderr.on("data", (chunk) => { stderr = tail(stderr + chunk.toString()); });
  child.on("error", (error) => {
    clearInterval(keepAlive);
    running = false;
    res.end(JSON.stringify({
      status: "error",
      message: error.message,
      started_at: startedAt.toISOString(),
      finished_at: new Date().toISOString(),
    }, null, 2) + "\n");
  });
  child.on("close", (code) => {
    clearInterval(keepAlive);
    running = false;
    const finishedAt = new Date();
    const scriptSummary = extractLastJson(stdout);
    res.end(JSON.stringify({
      status: code === 0 ? "ok" : "error",
      workflow: workflowName,
      script,
      exit_code: code,
      started_at: startedAt.toISOString(),
      finished_at: finishedAt.toISOString(),
      duration_seconds: Math.round((finishedAt - startedAt) / 1000),
      script_summary: scriptSummary,
      stderr: stderr || undefined,
    }, null, 2) + "\n");
  });
}

const server = http.createServer((req, res) => {
  if (req.method === "GET" && req.url === "/health") {
    sendJson(res, 200, { status: "ok", running });
    return;
  }

  if (req.method === "POST" && req.url === "/run/local-llm-router-classification") {
    if (!authorize(req, res)) return;
    req.resume();
    runNodeScript(res, classifierScript, "local-llm-router-classification");
    return;
  }

  if (req.method === "POST" && req.url === "/run/dify-openai-compatible-model-setup") {
    if (!authorize(req, res)) return;
    req.resume();
    runNodeScript(res, difyModelSetupScript, "dify-openai-compatible-model-setup");
    return;
  }

  if (req.method === "POST" && req.url === "/run/dify-local-openai-compatible-router-import") {
    if (!authorize(req, res)) return;
    req.resume();
    runNodeScript(res, difyRouterImportScript, "dify-local-openai-compatible-router-import");
    return;
  }

  sendJson(res, 404, { status: "error", message: "not found" });
});

server.listen(port, bindHost, () => {
  console.log(`FortisAI n8n workflow runner listening on ${bindHost}:${port}`);
});
