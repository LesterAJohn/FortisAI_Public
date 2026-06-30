#!/usr/bin/env node
"use strict";

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = process.env.FORTISAI_REPO_ROOT || path.dirname(path.dirname(__dirname));

const DEFAULT_PROVIDER = "langgenius/openai_api_compatible/openai_api_compatible";
const DEFAULT_PLUGIN = "langgenius/openai_api_compatible:0.0.53@a0dfb462961a03c6a6415d4185043185b01017c64da93cf82a9e5ecaf59f8ed0";
const DEFAULT_CLASSIFICATION_JSON = path.join(repoRoot, "Development_Environment/dify-config/main/dify/generated/local-llm-classification.generated.json");
const DEFAULT_CONTEXT_SIZE = "4096";
const DEFAULT_MAX_TOKENS = "4096";
const MODEL_CREDENTIAL_TIMEOUT_MS = Number(process.env.DIFY_MODEL_CREDENTIAL_TIMEOUT_MS || 300000);

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
  let response;
  try {
    response = await fetchWithTimeout(`${bridgeUrl}/dify_api_request`, {
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
  } catch (error) {
    return { ok: false, httpStatus: 0, payload: { message: error.message || String(error) } };
  }

  const text = await response.text();
  let parsed = {};
  try {
    parsed = text ? JSON.parse(text) : {};
  } catch (_) {
    parsed = { message: text.slice(0, 1000) };
  }

  if (!response.ok) {
    return { ok: false, httpStatus: response.status, payload: parsed };
  }

  const status = Number(parsed.status || response.status || 200);
  if (status >= 400) {
    return { ok: false, httpStatus: status, payload: parsed };
  }
  return { ok: true, httpStatus: status, payload: parsed };
}

function bodyOf(result) {
  return result?.payload?.body || {};
}

function errorText(result) {
  const payload = result?.payload || {};
  const detail = payload.detail || payload.body || payload;
  if (typeof detail === "string") return detail;
  const body = detail.body || detail;
  return String(body.message || body.error || body.code || JSON.stringify(body)).slice(0, 600);
}

function benignDuplicate(result) {
  const text = errorText(result).toLowerCase();
  return text.includes("same credential") || text.includes("already exists") || text.includes("duplicate");
}

function credentialId(payload) {
  const current = String(payload.current_credential_id || "").trim();
  if (current) return current;
  const available = Array.isArray(payload.available_credentials) ? payload.available_credentials : [];
  for (const item of available) {
    const id = String(item.credential_id || item.id || "").trim();
    if (id) return id;
  }
  return "";
}

async function sleep(ms) {
  await new Promise((resolve) => setTimeout(resolve, ms));
}

async function waitForCredentialId(bridgeUrl, credentialPath, query) {
  for (let attempt = 0; attempt < 6; attempt += 1) {
    if (attempt > 0) await sleep(5000);
    const reread = await bridgeRequest(bridgeUrl, "GET", credentialPath, { query, timeoutMs: 45000 });
    if (!reread.ok) continue;
    const id = credentialId(bodyOf(reread));
    if (id) return id;
  }
  return "";
}

function credentialCandidates(openaiBaseUrl, apiKey, mode) {
  const contextSize = String(process.env.DIFY_MODEL_CONTEXT_SIZE || DEFAULT_CONTEXT_SIZE);
  const maxTokens = String(process.env.DIFY_MODEL_MAX_TOKENS || DEFAULT_MAX_TOKENS);
  return [
    { endpoint_url: openaiBaseUrl, api_key: apiKey, mode, context_size: contextSize, max_tokens_to_sample: maxTokens },
    { endpoint_url: openaiBaseUrl, api_key: apiKey, mode, context_size: contextSize },
    { endpoint_url: openaiBaseUrl, api_key: apiKey, context_size: contextSize },
  ];
}

function activeRouteModelIds(classification) {
  const ids = new Set();
  const routes = Array.isArray(classification.routes) ? classification.routes : [];
  for (const route of routes) {
    const primary = String(route?.primary_model || "").trim();
    if (primary) ids.add(primary);
    for (const fallback of Array.isArray(route?.fallback_models) ? route.fallback_models : []) {
      const model = String(fallback || "").trim();
      if (model) ids.add(model);
    }
  }
  return ids;
}

function modelRefsFromClassification(classification, provider) {
  const models = Array.isArray(classification.models) ? classification.models : [];
  const runnableById = new Map();
  for (const model of models) {
    const modelId = String(model?.model_id || "").trim();
    if (!modelId || model?.runnable === false) continue;
    runnableById.set(modelId, model);
  }

  const routeIds = activeRouteModelIds(classification);
  const activeIds = [...routeIds].filter((modelId) => runnableById.has(modelId));
  const selectedIds = activeIds.length ? activeIds : [...runnableById.keys()];
  const refs = selectedIds.map((modelId) => ({ provider, model: modelId, mode: "chat", required: true }));

  if (!activeIds.length && routeIds.size) {
    console.error(
      `[dify-model-setup] router routes referenced ${routeIds.size} model(s), but none matched runnable classification models; using runnable model list`,
    );
  }

  const seen = new Set();
  return refs.filter((ref) => {
    const key = `${ref.provider}\n${ref.model}\n${ref.mode}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

async function ensureProvider(bridgeUrl, provider, pluginIdentifier) {
  const list = await bridgeRequest(
    bridgeUrl,
    "GET",
    "/console/api/workspaces/current/model-providers",
    { query: { model_type: "llm" }, timeoutMs: 45000 },
  );
  if (!list.ok) throw new Error(`Could not list Dify model providers: ${errorText(list)}`);

  const providers = Array.isArray(bodyOf(list).data) ? bodyOf(list).data : [];
  if (providers.some((item) => item?.provider === provider)) {
    return { status: "available", installed: false };
  }

  const install = await bridgeRequest(
    bridgeUrl,
    "POST",
    "/console/api/workspaces/current/plugin/install/pkg",
    { body: { plugin_unique_identifiers: [pluginIdentifier] }, timeoutMs: 120000 },
  );
  if (!install.ok) throw new Error(`Could not install Dify OpenAI-compatible plugin: ${errorText(install)}`);

  for (let attempt = 0; attempt < 15; attempt += 1) {
    await new Promise((resolve) => setTimeout(resolve, 2000));
    const retry = await bridgeRequest(
      bridgeUrl,
      "GET",
      "/console/api/workspaces/current/model-providers",
      { query: { model_type: "llm" }, timeoutMs: 45000 },
    );
    if (!retry.ok) continue;
    const retryProviders = Array.isArray(bodyOf(retry).data) ? bodyOf(retry).data : [];
    if (retryProviders.some((item) => item?.provider === provider)) {
      return { status: "available", installed: true, install_http: install.httpStatus };
    }
  }

  throw new Error(`Dify provider ${provider} was not available after plugin install`);
}

async function fastBridgeModelSetup(bridgeUrl, provider, refs, pruneStale) {
  const response = await fetchWithTimeout(`${bridgeUrl}/dify_openai_compatible_model_setup`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({
      provider,
      modelType: "llm",
      models: refs.map((ref) => ref.model),
      pruneStale,
    }),
  }, 120000);

  const text = await response.text();
  let parsed = {};
  try {
    parsed = text ? JSON.parse(text) : {};
  } catch (_) {
    parsed = { message: text.slice(0, 1000) };
  }
  if (!response.ok) {
    return { ok: false, httpStatus: response.status, payload: parsed };
  }
  return { ok: true, httpStatus: response.status, payload: parsed };
}

async function configureModel(bridgeUrl, provider, ref, openaiBaseUrl, apiKey) {
  const credentialPath = `/console/api/workspaces/current/model-providers/${provider}/models/credentials`;
  const modelPath = `/console/api/workspaces/current/model-providers/${provider}/models`;
  const enablePath = `/console/api/workspaces/current/model-providers/${provider}/models/enable`;
  const switchPath = `/console/api/workspaces/current/model-providers/${provider}/models/credentials/switch`;
  const query = { model: ref.model, model_type: "llm", config_from: "custom-model" };

  const existing = await bridgeRequest(bridgeUrl, "GET", credentialPath, { query, timeoutMs: 45000 });
  if (!existing.ok) throw new Error(`read credential failed: ${errorText(existing)}`);

  let id = credentialId(bodyOf(existing));
  let action = "existing";
  let schema = [];
  if (!id) {
    action = "create";
    let lastError = "";
    for (const credentials of credentialCandidates(openaiBaseUrl, apiKey, ref.mode || "chat")) {
      schema = Object.keys(credentials).sort();
      const saved = await bridgeRequest(bridgeUrl, "POST", credentialPath, {
        body: {
          model: ref.model,
          model_type: "llm",
          credentials,
          name: "FortisAI local",
        },
        timeoutMs: MODEL_CREDENTIAL_TIMEOUT_MS,
      });
      if (saved.ok || benignDuplicate(saved)) {
        lastError = "";
        break;
      }
      if (await waitForCredentialId(bridgeUrl, credentialPath, query)) {
        lastError = "";
        break;
      }
      lastError = errorText(saved);
    }
    if (lastError) throw new Error(`save credential failed: ${lastError}`);

    id = await waitForCredentialId(bridgeUrl, credentialPath, query);
    if (!id) throw new Error("credential save completed but no credential id was returned");
  }

  const switched = await bridgeRequest(bridgeUrl, "POST", switchPath, {
    body: { model: ref.model, model_type: "llm", credential_id: id },
    timeoutMs: 45000,
  });
  if (!switched.ok && !benignDuplicate(switched)) throw new Error(`switch credential failed: ${errorText(switched)}`);

  const added = await bridgeRequest(bridgeUrl, "POST", modelPath, {
    body: { model: ref.model, model_type: "llm", config_from: "custom-model", credential_id: id },
    timeoutMs: 45000,
  });
  if (!added.ok && !benignDuplicate(added)) throw new Error(`add model failed: ${errorText(added)}`);

  const enabled = await bridgeRequest(bridgeUrl, "PATCH", enablePath, {
    body: { model: ref.model, model_type: "llm" },
    timeoutMs: 45000,
  });
  if (!enabled.ok) throw new Error(`enable model failed: ${errorText(enabled)}`);

  return {
    provider,
    model: ref.model,
    action,
    credential_id_present: Boolean(id),
    schema,
  };
}

async function main() {
  const classificationPath = path.resolve(argValue("--classification-json", process.env.DIFY_MODEL_SETUP_CLASSIFICATION_JSON || DEFAULT_CLASSIFICATION_JSON));
  const provider = argValue("--provider", process.env.DIFY_OPENAI_COMPATIBLE_PROVIDER || DEFAULT_PROVIDER);
  const pluginIdentifier = argValue("--plugin", process.env.DIFY_OPENAI_COMPATIBLE_PLUGIN || DEFAULT_PLUGIN);
  const dryRun = hasFlag("--dry-run");
  const continueOnError = hasFlag("--continue-on-error");
  const pruneStale = !hasFlag("--keep-stale-models")
    && String(process.env.DIFY_MODEL_SETUP_PRUNE_STALE || "true").toLowerCase() !== "false";

  const classification = JSON.parse(fs.readFileSync(classificationPath, "utf8"));
  const refs = modelRefsFromClassification(classification, provider);
  const openaiBaseUrl = normalizeBaseUrl(
    argValue("--openai-base-url", process.env.DIFY_LOCAL_OPENAI_BASE_URL || process.env.DIFY_FORTISAI_LLAMA_OPENAI_BASE_URL || classification.dify_openai_base_url || classification.openai_base_url || "http://fortisai-llama-server.fortisai.local:8011/v1"),
  );
  const apiKeySource = process.env.FORTISAI_LLAMA_OPENAI_API_KEY
    ? "env:FORTISAI_LLAMA_OPENAI_API_KEY"
    : process.env.LOCAL_OPENAI_API_KEY
      ? "env:LOCAL_OPENAI_API_KEY"
      : process.env.OPENAI_API_KEY
        ? "env:OPENAI_API_KEY"
        : "default:local-llama";
  const apiKey = process.env.FORTISAI_LLAMA_OPENAI_API_KEY || process.env.LOCAL_OPENAI_API_KEY || process.env.OPENAI_API_KEY || "local-llama";

  if (dryRun) {
    console.log(JSON.stringify({
      status: "planned",
      classification_json: classificationPath,
      provider,
      plugin: pluginIdentifier,
      prune_stale: pruneStale,
      model_count: refs.length,
      openai_base_url: openaiBaseUrl,
      api_key_source: apiKeySource,
      models: refs.map((ref) => ref.model),
    }, null, 2));
    return;
  }

  const bridgeUrl = await detectBridgeUrl();
  const providerSetup = await ensureProvider(bridgeUrl, provider, pluginIdentifier);
  const configured = [];
  const failed = [];

  if (!hasFlag("--force-api-validation")) {
    console.error("[dify-model-setup] using bridge fast setup for model credential import");
    let fastSetup = await fastBridgeModelSetup(bridgeUrl, provider, refs, pruneStale);
    if (!fastSetup.ok && fastSetup.httpStatus === 409 && refs.length) {
      console.error("[dify-model-setup] no credential template found; creating one validated credential before fast setup");
      const templateRef = refs.find((ref) => /qwen2\.5-1\.5b.*q4_0/i.test(ref.model))
        || refs.find((ref) => /ministral.*q4/i.test(ref.model))
        || refs[0];
      configured.push(await configureModel(bridgeUrl, provider, templateRef, openaiBaseUrl, apiKey));
      fastSetup = await fastBridgeModelSetup(bridgeUrl, provider, refs, pruneStale);
    }
    if (fastSetup.ok) {
      const body = fastSetup.payload || {};
      console.log(JSON.stringify({
        status: "ok",
        bridge_url: bridgeUrl,
        setup_mode: "bridge-fast-db-import",
        classification_json: classificationPath,
        provider,
        provider_setup: providerSetup,
        prune_stale: pruneStale,
        openai_base_url: openaiBaseUrl,
        api_key_source: apiKeySource,
        model_count: body.model_count || refs.length,
        configured_model_count: body.configured_model_count || 0,
        removed_model_count: body.removed_model_count || 0,
        failed_model_count: 0,
        configured_models: body.configured_models || [],
        removed_models: body.removed_models || [],
      }, null, 2));
      return;
    }
    console.error(`[dify-model-setup] bridge fast setup unavailable: ${errorText(fastSetup)}`);
  }

  for (const [index, ref] of refs.entries()) {
    console.error(`[dify-model-setup] ${index + 1}/${refs.length} ${ref.model}`);
    try {
      configured.push(await configureModel(bridgeUrl, provider, ref, openaiBaseUrl, apiKey));
      console.error(`[dify-model-setup] configured ${ref.model}`);
    } catch (error) {
      failed.push({ provider, model: ref.model, reason: error.message });
      console.error(`[dify-model-setup] failed ${ref.model}: ${error.message}`);
      if (!continueOnError) break;
    }
  }

  const summary = {
    status: failed.length ? "error" : "ok",
    bridge_url: bridgeUrl,
    classification_json: classificationPath,
    provider,
    provider_setup: providerSetup,
    prune_stale: false,
    prune_stale_skipped_reason: pruneStale
      ? "bridge fast setup unavailable or --force-api-validation was used"
      : null,
    openai_base_url: openaiBaseUrl,
    api_key_source: apiKeySource,
    model_count: refs.length,
    configured_model_count: configured.length,
    failed_model_count: failed.length,
    configured_models: configured,
    failed_models: failed,
  };
  console.log(JSON.stringify(summary, null, 2));
  if (failed.length) process.exit(1);
}

main().catch((error) => {
  console.error(JSON.stringify({ status: "error", message: error.message, stack: error.stack }, null, 2));
  process.exit(1);
});
