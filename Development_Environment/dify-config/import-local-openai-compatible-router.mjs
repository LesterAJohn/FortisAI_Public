#!/usr/bin/env node
"use strict";

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = process.env.FORTISAI_REPO_ROOT || path.dirname(path.dirname(__dirname));
const DEFAULT_YAML = path.join(repoRoot, "Development_Environment/dify-config/main/dify/configurations/local-openai-compatible-router.yaml");
const DEFAULT_APP_NAME = "local-openai-compatible-router";

function argValue(name, fallback = "") {
  const index = process.argv.indexOf(name);
  if (index >= 0 && process.argv[index + 1]) return process.argv[index + 1];
  return fallback;
}

function hasFlag(name) {
  return process.argv.includes(name);
}

function normalizeBaseUrl(value) {
  return String(value || "").replace(/\/+$/, "");
}

function leadingSpaces(line) {
  const match = String(line || "").match(/^ */);
  return match ? match[0].length : 0;
}

function normalizeDifyRouterYamlContent(content) {
  const lines = String(content || "").split(/\r?\n/);
  const normalized = [];

  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    normalized.push(line);

    if (!/^ {14}type: start$/.test(line)) continue;
    const next = lines[index + 1] || "";
    if (!/^ {14}variables:/.test(next)) continue;

    normalized.push("              variables: []");
    index += 1;
    while (index + 1 < lines.length && leadingSpaces(lines[index + 1]) > 14) {
      index += 1;
    }
  }

  return normalized.join("\n");
}

async function fetchWithTimeout(url, options = {}, timeoutMs = 60000) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetch(url, { ...options, signal: controller.signal });
  } finally {
    clearTimeout(timer);
  }
}

async function detectBridgeUrl() {
  const configured = argValue("--bridge-url", process.env.FORTISAI_DIFY_OPENAPI_BRIDGE_URL || process.env.DIFY_OPENAPI_BRIDGE_URL || "");
  const candidates = [
    configured,
    "http://fortisai-mcp-openapi-dify.fortisai.local:8093",
    "http://127.0.0.1:8093",
  ].map(normalizeBaseUrl).filter(Boolean);
  const unique = [...new Set(candidates)];

  for (const candidate of unique) {
    try {
      const response = await fetchWithTimeout(`${candidate}/healthz`, {}, 4000);
      if (response.ok) return candidate;
    } catch (_) {
      // Try the next candidate.
    }
  }

  throw new Error(`Could not reach Dify OpenAPI bridge. Tried: ${unique.join(", ")}`);
}

async function bridgeRequest(bridgeUrl, method, requestPath, { query = null, body = null, timeoutMs = 60000 } = {}) {
  const response = await fetchWithTimeout(`${bridgeUrl}/dify_api_request`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({
      method,
      path: requestPath,
      query,
      body,
      authMode: "admin",
    }),
  }, timeoutMs);

  const text = await response.text();
  let parsed = {};
  try {
    parsed = text ? JSON.parse(text) : {};
  } catch (_) {
    parsed = { message: text.slice(0, 1000) };
  }

  if (!response.ok) {
    const detail = parsed.detail || parsed;
    const bodyText = typeof detail === "string" ? detail : JSON.stringify(detail).slice(0, 1000);
    throw new Error(`${method} ${requestPath} failed with HTTP ${response.status}: ${bodyText}`);
  }

  const status = Number(parsed.status || response.status || 200);
  if (status >= 400) {
    throw new Error(`${method} ${requestPath} returned Dify HTTP ${status}: ${JSON.stringify(parsed.body || parsed).slice(0, 1000)}`);
  }
  return parsed.body || {};
}

async function listApps(bridgeUrl) {
  const result = [];
  for (let page = 1; page < 100; page += 1) {
    const payload = await bridgeRequest(bridgeUrl, "GET", "/console/api/apps", {
      query: { page, limit: 100 },
      timeoutMs: 45000,
    });
    const data = Array.isArray(payload.data) ? payload.data : [];
    result.push(...data.filter((item) => item && typeof item === "object"));
    if (!payload.has_more) break;
  }
  return result;
}

async function main() {
  const yamlPath = path.resolve(argValue("--yaml", process.env.DIFY_IMPORT_YAML || DEFAULT_YAML));
  const appName = argValue("--app-name", process.env.DIFY_IMPORT_APP_NAME || DEFAULT_APP_NAME);
  const explicitAppId = argValue("--app-id", process.env.DIFY_IMPORT_APP_ID || "");
  const dryRun = hasFlag("--dry-run");
  const skipPublish = hasFlag("--skip-publish");
  const markedName = argValue("--marked-name", process.env.DIFY_IMPORT_MARKED_NAME || "FortisAI import").slice(0, 30);
  const markedComment = argValue("--marked-comment", process.env.DIFY_IMPORT_MARKED_COMMENT || "Imported from generated FortisAI router YAML").slice(0, 100);

  if (!fs.existsSync(yamlPath)) throw new Error(`Dify app YAML not found: ${yamlPath}`);

  const bridgeUrl = await detectBridgeUrl();
  const apps = await listApps(bridgeUrl);
  const matches = apps.filter((app) => String(app.name || "").trim() === appName);
  if (!explicitAppId && matches.length > 1) {
    throw new Error(`Multiple Dify apps named ${appName}; pass --app-id to select one.`);
  }
  const targetAppId = explicitAppId || (matches[0]?.id ? String(matches[0].id) : "");
  const action = targetAppId ? "update" : "create";

  if (dryRun) {
    console.log(JSON.stringify({
      status: "planned",
      bridge_url: bridgeUrl,
      yaml: yamlPath,
      app_name: appName,
      action,
      target_app_id: targetAppId || null,
      publish: skipPublish ? "skipped" : "enabled",
    }, null, 2));
    return;
  }

  const body = {
    mode: "yaml-content",
    yaml_content: normalizeDifyRouterYamlContent(fs.readFileSync(yamlPath, "utf8")),
  };
  if (targetAppId) body.app_id = targetAppId;

  let importResult = await bridgeRequest(bridgeUrl, "POST", "/console/api/apps/imports", {
    body,
    timeoutMs: 120000,
  });

  if (importResult.status === "pending" && importResult.id) {
    importResult = await bridgeRequest(bridgeUrl, "POST", `/console/api/apps/imports/${encodeURIComponent(importResult.id)}/confirm`, {
      body: {},
      timeoutMs: 120000,
    });
  }

  const appId = String(importResult.app_id || targetAppId || "");
  if (!appId) throw new Error("Dify import did not return an app id");

  let publish = "skipped";
  if (!skipPublish) {
    const publishResult = await bridgeRequest(bridgeUrl, "POST", `/console/api/apps/${encodeURIComponent(appId)}/workflows/publish`, {
      body: {
        marked_name: markedName,
        marked_comment: `${markedComment}; ${path.basename(yamlPath)}; ${Math.floor(Date.now() / 1000)}`.slice(0, 100),
      },
      timeoutMs: 120000,
    });
    publish = publishResult.result || publishResult.status || "unknown";
    if (publish !== "success") throw new Error(`Dify publish did not return success: ${JSON.stringify(publishResult).slice(0, 1000)}`);
  }

  console.log(JSON.stringify({
    status: "ok",
    bridge_url: bridgeUrl,
    yaml: yamlPath,
    app_name: appName,
    action,
    app_id: appId,
    import_status: importResult.status || "completed",
    publish,
  }, null, 2));
}

main().catch((error) => {
  console.error(JSON.stringify({ status: "error", message: error.message, stack: error.stack }, null, 2));
  process.exit(1);
});
