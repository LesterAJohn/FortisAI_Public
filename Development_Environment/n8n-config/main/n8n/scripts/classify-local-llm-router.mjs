#!/usr/bin/env node
"use strict";

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const DEFAULT_CLASSIFIER_MODEL = "mistral__mistralai_Mistral-Small-3.2-24B-Instruct-2506-Q8_0";
const TOOL_USE_REQUEST_TYPE = "agentic_tool_use";
const EMBEDDINGS_REQUEST_TYPE = "embeddings";
const REQUEST_TYPES = [
  {
    id: "coding",
    description: "Software engineering, code generation, debugging, refactoring, and repository analysis.",
  },
  {
    id: "agentic_tool_use",
    description: "Multi-step tool use, workflow orchestration, API planning, and autonomous task execution.",
  },
  {
    id: "reasoning_math",
    description: "Logical reasoning, math, proofs, planning, and careful multi-step analysis.",
  },
  {
    id: "analysis_research",
    description: "Synthesis, research, comparison, policy/architecture analysis, and long-form answers.",
  },
  {
    id: "summarization",
    description: "Summaries, extraction, rewrite, document condensation, and structured notes.",
  },
  {
    id: "classification_extraction",
    description: "Fast labels, routing decisions, entity extraction, JSON normalization, and triage.",
  },
  {
    id: "embeddings",
    description: "Stable text embedding generation for Qdrant, RAG, memory, and vector-store insertion.",
  },
  {
    id: "long_context",
    description: "Large document or codebase context where context length matters more than raw speed.",
  },
  {
    id: "fast_chat",
    description: "Low-latency general chat, simple Q&A, drafts, and inexpensive repeated tasks.",
  },
  {
    id: "multimodal_vision",
    description: "Vision-capable or image-adjacent tasks where a local multimodal model is available.",
  },
  {
    id: "safety_guardrail",
    description: "Safety, policy, moderation, jailbreak checks, and guardrail review.",
  },
];

function argValue(name, fallback) {
  const index = process.argv.indexOf(name);
  if (index >= 0 && process.argv[index + 1]) return process.argv[index + 1];
  return fallback;
}

function repoRoot() {
  if (process.env.FORTISAI_REPO_ROOT) return process.env.FORTISAI_REPO_ROOT;
  if (fs.existsSync("/FortisAI/Development_Environment/n8n-config") && fs.existsSync("/FortisAI/Development_Environment/dify-config")) return "/FortisAI";

  let current = process.cwd();
  while (current !== path.dirname(current)) {
    if (fs.existsSync(path.join(current, "Development_Environment", "n8n-config")) && fs.existsSync(path.join(current, "Development_Environment", "dify-config"))) {
      return current;
    }
    current = path.dirname(current);
  }
  return path.resolve(__dirname, "../../../../..");
}

function normalizeBaseUrl(value) {
  return String(value || "").replace(/\/+$/, "");
}

function primaryOpenAiBaseUrl() {
  return normalizeBaseUrl(
    argValue("--base-url", process.env.LOCAL_OPENAI_BASE_URL) ||
    process.env.FORTISAI_LLAMA_OPENAI_BASE_URL ||
    process.env.FORTISAI_LLAMA_SERVER_BASE_URL ||
    "http://127.0.0.1:8011/v1",
  );
}

function defaultLlamaModelsDir(root) {
  if (process.env.LLAMA_MODELS_DIR) return path.resolve(process.env.LLAMA_MODELS_DIR);
  if (fs.existsSync("/db/AI/llm_directory")) return "/db/AI/llm_directory";
  return path.join(root, "Development_Environment", "llm_directory");
}

function disabledModelsFile(root) {
  return path.resolve(
    process.env.LLAMA_DISABLED_MODELS_FILE ||
    path.join(defaultLlamaModelsDir(root), "disabled_models.json"),
  );
}

function readDisabledManifest(root) {
  const file = disabledModelsFile(root);
  if (!fs.existsSync(file)) {
    return { file, records: [] };
  }
  try {
    const parsed = JSON.parse(fs.readFileSync(file, "utf8"));
    const records = Array.isArray(parsed?.disabled_models) ? parsed.disabled_models : [];
    return { file, records };
  } catch (error) {
    return { file, records: [], warning: `Could not read disabled model manifest: ${error.message}` };
  }
}

function stripModelArtifactSuffix(value) {
  return String(value || "")
    .replace(/\\/g, "/")
    .replace(/\.gguf\.disable(?:\.[^/]+)?$/i, "")
    .replace(/\.gguf$/i, "")
    .replace(/\.disable(?:\.[^/]+)?$/i, "");
}

function modelAliasKey(value) {
  return stripModelArtifactSuffix(value).replace(/^\/+/, "").toLowerCase();
}

function modelAliases(value, modelsDir) {
  const aliases = new Set();
  const add = (candidate) => {
    const key = modelAliasKey(candidate);
    if (!key) return;
    aliases.add(key);
    aliases.add(key.replace(/\//g, "__"));
    aliases.add(key.replace(/__/g, "/"));
    aliases.add(path.posix.basename(key));
  };

  const raw = String(value || "").trim().replace(/\\/g, "/");
  if (!raw) return aliases;
  add(raw);

  const normalizedModelsDir = String(modelsDir || "").replace(/\\/g, "/").replace(/\/+$/, "");
  if (normalizedModelsDir && raw.startsWith(`${normalizedModelsDir}/`)) {
    add(raw.slice(normalizedModelsDir.length + 1));
  }

  const marker = "/llm_directory/";
  const markerIndex = raw.indexOf(marker);
  if (markerIndex >= 0) {
    add(raw.slice(markerIndex + marker.length));
  }

  return aliases;
}

function disabledModelAliases(manifest, root) {
  const aliases = new Set();
  const modelsDir = defaultLlamaModelsDir(root);
  for (const record of manifest.records) {
    for (const field of ["model_id", "original_path", "disabled_path"]) {
      for (const alias of modelAliases(record?.[field], modelsDir)) {
        aliases.add(alias);
      }
    }
  }
  return aliases;
}

function splitShardInfo(modelId) {
  const normalized = stripModelArtifactSuffix(modelId).replace(/\\/g, "/").replace(/__/g, "/");
  const name = path.posix.basename(normalized);
  const match = name.match(/-(\d{5})-of-(\d{5})$/i);
  if (!match) return null;
  return {
    index: Number(match[1]),
    count: Number(match[2]),
    indexText: match[1],
    countText: match[2],
  };
}

function filterNonFirstSplitShardModels(localModels) {
  const excludedSplitShardModels = [];
  const filtered = localModels.filter((model) => {
    const info = splitShardInfo(model.id);
    if (info && info.index !== 1) {
      excludedSplitShardModels.push(model.id);
      return false;
    }
    return true;
  });
  return { localModels: filtered, excludedSplitShardModels };
}

function filterDisabledLocalModels(localModels, manifest, root) {
  const disabledAliases = disabledModelAliases(manifest, root);
  if (!disabledAliases.size) {
    return { localModels, excludedDisabledModels: [] };
  }
  const excludedDisabledModels = [];
  const filtered = localModels.filter((model) => {
    const aliases = modelAliases(model.id, defaultLlamaModelsDir(root));
    const matched = [...aliases].some((alias) => disabledAliases.has(alias));
    if (matched) {
      excludedDisabledModels.push(model.id);
      return false;
    }
    return true;
  });
  return { localModels: filtered, excludedDisabledModels };
}

function difyOpenAiBaseUrl(fetchBaseUrl) {
  return normalizeBaseUrl(
    argValue("--dify-openai-base-url", process.env.DIFY_LOCAL_OPENAI_BASE_URL) ||
    process.env.DIFY_FORTISAI_LLAMA_OPENAI_BASE_URL ||
    fetchBaseUrl,
  );
}

function classifierModel() {
  return argValue("--classifier-model", process.env.LLM_ROUTER_CLASSIFIER_MODEL || DEFAULT_CLASSIFIER_MODEL);
}

function chooseActiveClassifierModel(requestedModelId, localModels) {
  const ids = localModels.map((model) => model.id).filter(Boolean);
  if (ids.includes(requestedModelId)) {
    return { modelId: requestedModelId, requestedModelId, changed: false, note: null };
  }

  const preferredPatterns = [
    /qwen.*coder.*q5_k_m$/i,
    /qwen.*coder.*q5_k_m-00001-of-\d+$/i,
    /qwen.*coder.*q5_0-00001-of-\d+$/i,
    /qwen.*coder.*q4_k_m$/i,
    /qwen.*coder.*q4_k_m-00001-of-\d+$/i,
    /qwen.*coder.*q4_0$/i,
    /qwen.*coder.*q4_0-00001-of-\d+$/i,
    /microsoft.*phi/i,
    /qwen.*1\.5b.*q8/i,
    /qwen.*1\.5b.*q6/i,
    /qwen.*0\.5b.*q8/i,
  ];
  for (const pattern of preferredPatterns) {
    const match = ids.find((id) => pattern.test(id));
    if (match) {
      return {
        modelId: match,
        requestedModelId,
        changed: true,
        note: `Configured classifier model ${requestedModelId} is not active; using active fallback ${match}.`,
      };
    }
  }

  const fallback = ids[0];
  return {
    modelId: fallback,
    requestedModelId,
    changed: fallback !== requestedModelId,
    note: `Configured classifier model ${requestedModelId} is not active; using first active local model ${fallback}.`,
  };
}

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function writeFileReplacing(file, value, mode = null) {
  ensureDir(path.dirname(file));
  try {
    fs.writeFileSync(file, value, "utf8");
  } catch (error) {
    if (!["EACCES", "EPERM"].includes(error?.code)) {
      throw error;
    }
    try {
      fs.unlinkSync(file);
    } catch (unlinkError) {
      if (unlinkError?.code !== "ENOENT") {
        throw error;
      }
    }
    fs.writeFileSync(file, value, "utf8");
  }
  if (mode !== null) {
    try {
      fs.chmodSync(file, mode);
    } catch (error) {
      if (!["EACCES", "EPERM"].includes(error?.code)) {
        throw error;
      }
    }
  }
}

function writeJson(file, value) {
  writeFileReplacing(file, JSON.stringify(value, null, 2) + "\n", 0o666);
}

function writeText(file, value, mode = 0o644) {
  writeFileReplacing(file, value, mode);
}

function yamlScalar(value) {
  if (value === null || value === undefined) return "null";
  if (typeof value === "number" || typeof value === "boolean") return String(value);
  const text = String(value);
  if (text === "") return '""';
  if (/^[A-Za-z0-9_.:/@+\-]+$/.test(text)) return text;
  return JSON.stringify(text);
}

function toYaml(value, indent = 0) {
  const pad = " ".repeat(indent);
  if (Array.isArray(value)) {
    if (value.length === 0) return "[]";
    return value.map((item) => {
      if (item && typeof item === "object" && !Array.isArray(item)) {
        const nested = toYaml(item, indent + 2);
        return `${pad}- ${nested.trimStart()}`;
      }
      return `${pad}- ${yamlScalar(item)}`;
    }).join("\n");
  }
  if (value && typeof value === "object") {
    const entries = Object.entries(value);
    if (entries.length === 0) return "{}";
    return entries.map(([key, item]) => {
      if (Array.isArray(item)) {
        return item.length ? `${pad}${key}:\n${toYaml(item, indent + 2)}` : `${pad}${key}: []`;
      }
      if (item && typeof item === "object") {
        return `${pad}${key}:\n${toYaml(item, indent + 2)}`;
      }
      return `${pad}${key}: ${yamlScalar(item)}`;
    }).join("\n");
  }
  return yamlScalar(value);
}

async function fetchWithTimeout(url, options = {}, timeoutMs = 60000) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetch(url, { ...options, signal: controller.signal });
    const text = await response.text();
    if (!response.ok) {
      throw new Error(`${url} returned HTTP ${response.status}: ${text.slice(0, 500)}`);
    }
    return { response, text };
  } finally {
    clearTimeout(timer);
  }
}

async function fetchOpenAiModels(baseUrl) {
  const { text } = await fetchWithTimeout(`${baseUrl}/models`, {}, 45000);
  const parsed = JSON.parse(text);
  const data = Array.isArray(parsed.data) ? parsed.data : [];
  return data.map((model) => ({
    id: String(model.id || model.name || "").trim(),
    object: model.object || "model",
    owned_by: model.owned_by || model.owner || "",
  })).filter((model) => model.id);
}

async function fetchLlmdbModels() {
  const llmdbUrl = process.env.LLMDB_MODELS_URL || "https://llmdb.com/models";
  const { text } = await fetchWithTimeout(llmdbUrl, {}, 60000);
  const match = text.match(/<script id="__NEXT_DATA__" type="application\/json">([\s\S]*?)<\/script>/);
  if (!match) {
    return { sourceUrl: llmdbUrl, models: [], warning: "Could not find __NEXT_DATA__ in LLMDB models page." };
  }
  const parsed = JSON.parse(match[1]);
  const pageProps = parsed?.props?.pageProps || {};
  const models = Array.isArray(pageProps.models) ? pageProps.models : [];
  return { sourceUrl: llmdbUrl, models };
}

function norm(value) {
  return String(value || "").toLowerCase().replace(/[^a-z0-9]+/g, "");
}

function words(value) {
  return String(value || "").toLowerCase().split(/[^a-z0-9]+/).filter(Boolean);
}

function providerFromLocalId(modelId) {
  const raw = String(modelId).split("__", 1)[0] || "";
  const map = {
    claude: "Anthropic",
    google: "Google",
    microsoft: "Microsoft",
    mistral: "Mistral AI",
    openai: "OpenAI",
    qwen: "Alibaba",
  };
  return map[raw.toLowerCase()] || raw || "local";
}

function quantization(modelId) {
  const match = String(modelId).match(/(?:^|[-_])(Q[0-9](?:_[A-Z0-9]+)?|BF16|FP16|MXFP4|q[0-9](?:_[a-z0-9]+)?)(?:$|[-_])/);
  return match ? match[1].toUpperCase() : "";
}

function uniqueValues(values) {
  const result = [];
  for (const value of values) {
    const text = String(value || "").trim();
    if (text && !result.includes(text)) result.push(text);
  }
  return result;
}

function toolUsePolicy() {
  return {
    request_type: TOOL_USE_REQUEST_TYPE,
    required_capabilities: ["tool_use"],
    force_model_load: true,
    selection_policy:
      "Always route to the classified preferred model. Do not substitute an already-loaded model; allow the selected model to load when cold.",
  };
}

function toolUseProfile(modelId, capabilities = [], llmdbMatches = [], agentMarkedToolUse = false) {
  const lower = String(modelId || "").toLowerCase();
  if (lower.includes("mmproj")) {
    return {
      capable: false,
      score: 0,
      force_model_load: false,
      modes: [],
      evidence: ["model is a multimodal projection support asset, not a runnable tool-use model"],
    };
  }

  const evidence = [];
  const modes = new Set();
  let score = 0;

  function add(reason, points, mode = "") {
    if (reason && !evidence.includes(reason)) evidence.push(reason);
    if (mode) modes.add(mode);
    score += points;
  }

  if (/devstral/.test(lower)) add("model family is Devstral, a coding/agentic model", 95, "agentic_coding");
  if (/agent|tool|function|workflow|orchestrat|api/.test(lower)) add("model id contains tool or agent keywords", 35, "tool_planning");
  if (/mistral-small|mistral_small/.test(lower)) add("Mistral Small family is suitable for structured tool planning", 25, "tool_planning");

  const capabilityText = uniqueValues([
    ...capabilities,
    ...llmdbMatches.flatMap((match) => Array.isArray(match?.capabilities) ? match.capabilities : []),
  ]);
  for (const capability of capabilityText) {
    const normalized = capability.toLowerCase();
    if (/\bparallel tool\b|parallel tool execution/.test(normalized)) {
      add(`LLMDB capability: ${capability}`, 25, "parallel_tool_execution");
    } else if (/\btool use\b|\btools?\b/.test(normalized)) {
      add(`LLMDB capability: ${capability}`, 30, "tool_calling");
    } else if (/function calling|function call/.test(normalized)) {
      add(`LLMDB capability: ${capability}`, 35, "function_calling");
    } else if (/agentic|autonomous|workflow|api orchestration/.test(normalized)) {
      add(`LLMDB capability: ${capability}`, 25, "tool_planning");
    }
  }

  if (agentMarkedToolUse) add("classifier agent marked the model as tool-use capable", 40, "classifier_reviewed");

  const capable = score >= 45;
  return {
    capable,
    score: Math.max(0, Math.min(100, score)),
    force_model_load: capable,
    modes: capable ? [...modes] : [],
    evidence: evidence.slice(0, 6),
  };
}

function embeddingProfile(modelId, capabilities = [], llmdbMatches = []) {
  const lower = String(modelId || "").toLowerCase();
  if (lower.includes("mmproj")) {
    return {
      capable: false,
      score: 0,
      dimension_hint: null,
      evidence: ["model is a multimodal projection support asset, not a text embedding model"],
    };
  }

  const evidence = [];
  let score = 0;
  let dimensionHint = null;

  function add(reason, points, dimension = null) {
    if (reason && !evidence.includes(reason)) evidence.push(reason);
    if (dimension !== null && dimensionHint === null) dimensionHint = dimension;
    score += points;
  }

  if (/qwen2\.5-1\.5b/.test(lower)) add("Qwen2.5 1.5B has a known 1536-dimensional local embedding output", 95, 1536);
  if (/qwen2\.5/.test(lower)) add("Qwen2.5 family is suitable for lightweight local embedding support", 45);
  if (/embed|embedding|bge|e5|gte|nomic/.test(lower)) add("model id contains embedding-specific keywords", 100);
  if (/mini|small|1\.5b|3-8b|ministral|phi/.test(lower)) add("small local model is suitable for recurring vector-store embedding work", 25);
  if (/q8|bf16|fp16/.test(lower)) add("higher precision quantization is available", 8);
  if (/35b|24b|12b|opus|claude|reason|magistral|devstral/.test(lower)) add("large or reasoning/tool model is less ideal for embedding throughput", -35);

  const capabilityText = uniqueValues([
    ...capabilities,
    ...llmdbMatches.flatMap((match) => Array.isArray(match?.capabilities) ? match.capabilities : []),
  ]);
  for (const capability of capabilityText) {
    const normalized = capability.toLowerCase();
    if (/embedding|retrieval|vector|semantic search/.test(normalized)) {
      add(`LLMDB capability: ${capability}`, 45);
    }
  }

  const capable = score >= 45;
  return {
    capable,
    score: Math.max(0, Math.min(100, score)),
    dimension_hint: dimensionHint,
    evidence: evidence.slice(0, 6),
  };
}

function heuristicClassification(modelId, llmdbMatches = []) {
  const id = String(modelId);
  const lower = id.toLowerCase();
  const isSupportAsset = lower.includes("mmproj");
  const provider = providerFromLocalId(id);
  const q = quantization(id);
  const primaryMatch = llmdbMatches[0] || {};
  const caps = new Set();
  const requestTypes = new Set();

  if (isSupportAsset) {
    caps.add("vision_adapter");
    requestTypes.add("multimodal_vision");
  }
  if (/devstral|code|coder|codex|swe|terminal/.test(lower)) {
    caps.add("code");
    caps.add("agentic_coding");
    requestTypes.add("coding");
    requestTypes.add("agentic_tool_use");
  }
  if (/magistral|reason|math|apex|qwen3\.6|opus|claude|gpt-oss/.test(lower)) {
    caps.add("reasoning");
    requestTypes.add("reasoning_math");
    requestTypes.add("analysis_research");
  }
  if (/ministral|phi|qwen2\.5-1\.5b|1\.5b|3-8b/.test(lower)) {
    caps.add("fast_local_inference");
    requestTypes.add("fast_chat");
    requestTypes.add("classification_extraction");
    requestTypes.add("summarization");
  }
  if (/gemma|vision|mmproj|multimodal/.test(lower)) {
    caps.add("multimodal_or_vision_adjacent");
    requestTypes.add("multimodal_vision");
  }
  if (/safeguard|guard|safety|moderation/.test(lower)) {
    caps.add("safety");
    requestTypes.add("safety_guardrail");
  }
  if (/mistral-small-3\.2|mistral-small/.test(lower)) {
    caps.add("general_instruction");
    caps.add("classification_agent");
    requestTypes.add("analysis_research");
    requestTypes.add("classification_extraction");
    requestTypes.add("summarization");
  }

  for (const cap of primaryMatch.capabilities || []) caps.add(String(cap));
  const toolUse = toolUseProfile(id, [...caps], llmdbMatches);
  const embedding = embeddingProfile(id, [...caps], llmdbMatches);
  if (toolUse.capable && !isSupportAsset) {
    caps.add("tool_use");
    requestTypes.add(TOOL_USE_REQUEST_TYPE);
  }
  if (embedding.capable && !isSupportAsset) {
    caps.add("embeddings");
    requestTypes.add(EMBEDDINGS_REQUEST_TYPE);
  }
  if (caps.size === 0) caps.add("general_instruction");
  if (requestTypes.size === 0) {
    requestTypes.add("analysis_research");
    requestTypes.add("summarization");
  }

  let qualityTier = "balanced";
  if (isSupportAsset) qualityTier = "support_asset";
  else if (/Q8|BF16|FP16/.test(q)) qualityTier = "high";
  else if (/Q2|Q3|Q4/.test(q)) qualityTier = "fast";
  else if (/safeguard|guard/.test(lower)) qualityTier = "safety";

  return {
    model_id: id,
    provider,
    family: primaryMatch.family || inferFamily(id),
    quantization: q || "unknown",
    runnable: !isSupportAsset,
    primary_capability: [...caps][0],
    secondary_capabilities: [...caps].slice(1, 8),
    request_types: [...requestTypes],
    tool_use: toolUse,
    embedding,
    quality_tier: qualityTier,
    routing_weight: isSupportAsset ? 0 : routeWeight(id, qualityTier),
    llmdb_reference: primaryMatch.id ? {
      id: primaryMatch.id,
      name: primaryMatch.name,
      provider: primaryMatch.provider,
      aggregateScore: primaryMatch.aggregateScore || 0,
    } : null,
    rationale: primaryMatch.description
      ? `Matched local model naming to LLMDB entry ${primaryMatch.name}; capabilities were combined with local quantization/name heuristics.`
      : "No close LLMDB match found; classification uses local model naming, provider prefix, quantization, and known family hints.",
  };
}

function inferFamily(modelId) {
  const lower = String(modelId).toLowerCase();
  if (lower.includes("devstral")) return "Devstral";
  if (lower.includes("magistral")) return "Magistral";
  if (lower.includes("mistral")) return "Mistral";
  if (lower.includes("ministral")) return "Ministral";
  if (lower.includes("qwen")) return "Qwen";
  if (lower.includes("gemma")) return "Gemma";
  if (lower.includes("phi")) return "Phi";
  if (lower.includes("gpt-oss")) return "GPT-OSS";
  if (lower.includes("claude")) return "Claude-derived";
  return providerFromLocalId(modelId);
}

function routeWeight(modelId, qualityTier) {
  const lower = String(modelId).toLowerCase();
  let score = 50;
  if (qualityTier === "high") score += 20;
  if (qualityTier === "fast") score += 5;
  if (lower.includes("q8")) score += 10;
  if (lower.includes("bf16") || lower.includes("fp16")) score += 8;
  if (lower.includes("q2") || lower.includes("q3")) score -= 12;
  if (lower.includes("safeguard")) score += 30;
  return Math.max(0, Math.min(100, score));
}

function matchLlmdb(localId, llmdbModels) {
  const localNorm = norm(localId);
  const localWords = new Set(words(localId));
  const provider = providerFromLocalId(localId).toLowerCase();
  const scored = [];

  for (const model of llmdbModels) {
    const fields = [model.id, model.name, model.family, model.provider, ...(model.variants || [])].filter(Boolean);
    const modelNorm = fields.map(norm).join(" ");
    let score = 0;
    if (model.provider && String(model.provider).toLowerCase().includes(provider.split(" ")[0])) score += 12;
    for (const field of fields) {
      const fieldNorm = norm(field);
      if (fieldNorm && localNorm.includes(fieldNorm)) score += Math.min(60, fieldNorm.length);
      if (fieldNorm && fieldNorm.includes(localNorm)) score += 30;
    }
    for (const word of words(model.name || model.id || "")) {
      if (word.length >= 4 && localWords.has(word)) score += 8;
    }
    if (score > 0) scored.push({ score, model });
  }

  return scored.sort((a, b) => b.score - a.score).slice(0, 3).map((entry) => entry.model);
}

function buildFallbackResult(localModels, llmdbModels, sourceUrl) {
  const models = localModels.map((model) => heuristicClassification(model.id, matchLlmdb(model.id, llmdbModels)));
  return {
    classification_source: "heuristic_fallback",
    generated_by_model: null,
    llmdb_source_url: sourceUrl,
    tool_use_policy: toolUsePolicy(),
    models,
    routes: buildRoutes(models),
    notes: [
      "Generated without a successful classifier-agent response.",
      "Classifications use local model IDs, quantization hints, and nearest LLMDB model matches.",
    ],
  };
}

function selectForRoute(classifiedModels, requestType) {
  const runnable = classifiedModels.filter((model) => model.runnable !== false);
  const exact = runnable.filter((model) => (model.request_types || []).includes(requestType));
  const pool = exact.length ? exact : runnable;
  return pool
    .slice()
    .sort((a, b) => {
      if (requestType === TOOL_USE_REQUEST_TYPE) {
        const toolDelta = (b.tool_use?.score || 0) - (a.tool_use?.score || 0);
        if (toolDelta !== 0) return toolDelta;
      }
      if (requestType === EMBEDDINGS_REQUEST_TYPE) {
        const embeddingDelta = (b.embedding?.score || 0) - (a.embedding?.score || 0);
        if (embeddingDelta !== 0) return embeddingDelta;
      }
      return (b.routing_weight || 0) - (a.routing_weight || 0);
    })
    .slice(0, 4);
}

function buildRoutes(classifiedModels) {
  return REQUEST_TYPES.map((requestType) => {
    const candidates = selectForRoute(classifiedModels, requestType.id);
    return {
      request_type: requestType.id,
      description: requestType.description,
      primary_model: candidates[0]?.model_id || null,
      fallback_models: candidates.slice(1).map((model) => model.model_id),
      match_hints: routeHints(requestType.id),
      ...(requestType.id === TOOL_USE_REQUEST_TYPE ? {
        required_capabilities: ["tool_use"],
        force_model_load: true,
        selection_policy: "force_selected_model_load",
      } : {}),
      ...(requestType.id === EMBEDDINGS_REQUEST_TYPE ? {
        required_capabilities: ["embeddings"],
        selection_policy: "classified_embedding_model",
      } : {}),
    };
  });
}

function routeHints(requestType) {
  const hints = {
    coding: ["code", "debug", "refactor", "repository", "function", "script", "software", "api"],
    agentic_tool_use: ["tool", "tool use", "tool call", "function call", "tool_choice", "workflow", "api call", "mcp tool", "orchestrate", "multi-step", "agent", "plan"],
    reasoning_math: ["reason", "prove", "math", "calculate", "logic", "derive", "constraint"],
    analysis_research: ["analyze", "compare", "research", "architecture", "strategy", "explain"],
    summarization: ["summarize", "rewrite", "brief", "extract key points", "condense"],
    classification_extraction: ["classify", "label", "extract", "json", "schema", "triage"],
    embeddings: ["embedding", "embeddings", "vector", "semantic search", "qdrant", "rag", "memory"],
    long_context: ["long document", "large context", "many files", "full report", "codebase"],
    fast_chat: ["quick", "draft", "chat", "simple", "short answer"],
    multimodal_vision: ["image", "vision", "screenshot", "chart", "diagram"],
    safety_guardrail: ["safety", "policy", "moderation", "jailbreak", "risk"],
  };
  return hints[requestType] || [];
}

function compactString(value, maxLength = 96) {
  if (value === null || value === undefined) return "";
  const text = typeof value === "object" ? JSON.stringify(value) : String(value);
  return text.length > maxLength ? text.slice(0, maxLength) : text;
}

function compactForAgent(localModels, llmdbModels) {
  return localModels.map((model, index) => {
    const rawMatches = matchLlmdb(model.id, llmdbModels);
    const seed = heuristicClassification(model.id, rawMatches);
    const match = rawMatches[0] ? {
      name: compactString(rawMatches[0].name || rawMatches[0].id, 80),
      provider: compactString(rawMatches[0].provider, 40),
      family: compactString(rawMatches[0].family, 60),
      parameters: compactString(rawMatches[0].parameters, 40),
      context_window: compactString(rawMatches[0].contextWindow || rawMatches[0].context_window, 40),
      aggregate_score: rawMatches[0].aggregateScore || 0,
    } : null;
    return {
      i: index + 1,
      model_id: model.id,
      provider_hint: providerFromLocalId(model.id),
      quantization: quantization(model.id) || "unknown",
      llmdb_match: match,
      seed_request_types: seed.request_types,
      seed_tool_use: {
        capable: seed.tool_use?.capable === true,
        score: seed.tool_use?.score || 0,
        modes: seed.tool_use?.modes || [],
      },
      seed_embedding: {
        capable: seed.embedding?.capable === true,
        score: seed.embedding?.score || 0,
        dimension_hint: seed.embedding?.dimension_hint || null,
      },
      seed_quality_tier: seed.quality_tier,
      seed_routing_weight: seed.routing_weight,
    };
  });
}

function extractJsonObject(text) {
  const raw = String(text || "").trim();
  try {
    return JSON.parse(raw);
  } catch (_) {
    const start = raw.indexOf("{");
    const end = raw.lastIndexOf("}");
    if (start >= 0 && end > start) {
      return JSON.parse(raw.slice(start, end + 1));
    }
    throw new Error("Classifier response did not contain a JSON object.");
  }
}

function extractOpenAiContent(text) {
  const raw = String(text || "");
  const streamed = [];
  const lines = raw.replaceAll(String.fromCharCode(13), "").split(String.fromCharCode(10));
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed.startsWith("data:")) continue;
    const payload = trimmed.slice(5).trim();
    if (!payload || payload === "[DONE]") continue;
    try {
      const event = JSON.parse(payload);
      const delta = event?.choices?.[0]?.delta?.content || event?.choices?.[0]?.message?.content || event?.choices?.[0]?.text || "";
      if (delta) streamed.push(delta);
    } catch (_) {
      // Ignore non-JSON stream comments or partial transport lines.
    }
  }
  if (streamed.length) return streamed.join("");

  const parsed = JSON.parse(raw);
  return parsed?.choices?.[0]?.message?.content || parsed?.choices?.[0]?.text || "";
}

function normalizeAgentResult(result, localModels, llmdbModels, sourceUrl, modelId) {
  const fallback = buildFallbackResult(localModels, llmdbModels, sourceUrl);
  const byId = new Map();
  const idByIndex = new Map(localModels.map((model, index) => [String(index + 1), model.id]));
  for (const item of Array.isArray(result.models) ? result.models : []) {
    if (!item) continue;
    const modelId = item.model_id || item.m || idByIndex.get(String(item.i));
    if (!modelId) continue;
    byId.set(modelId, {
      ...item,
      model_id: modelId,
      request_types: item.request_types || item.r,
      quality_tier: item.quality_tier || item.t,
      routing_weight: item.routing_weight ?? item.w,
      tool_use_capable: item.tool_use_capable ?? item.u,
    });
  }

  const models = fallback.models.map((seed) => {
    const agent = byId.get(seed.model_id) || {};
    const agentRequestTypes = Array.isArray(agent.request_types) ? agent.request_types : [];
    const agentMarkedToolUse = agent.tool_use_capable === true || agentRequestTypes.includes(TOOL_USE_REQUEST_TYPE);
    const capabilitySeed = uniqueValues([
      seed.primary_capability,
      ...(Array.isArray(seed.secondary_capabilities) ? seed.secondary_capabilities : []),
      ...(Array.isArray(agent.secondary_capabilities) ? agent.secondary_capabilities : []),
    ]);
    const toolUse = toolUseProfile(seed.model_id, capabilitySeed, matchLlmdb(seed.model_id, llmdbModels), agentMarkedToolUse);
    const embedding = embeddingProfile(seed.model_id, capabilitySeed, matchLlmdb(seed.model_id, llmdbModels));
    const requestTypes = Array.isArray(agent.request_types) && agent.request_types.length ? agent.request_types : seed.request_types;
    if (toolUse.capable && !requestTypes.includes(TOOL_USE_REQUEST_TYPE)) requestTypes.push(TOOL_USE_REQUEST_TYPE);
    if (embedding.capable && !requestTypes.includes(EMBEDDINGS_REQUEST_TYPE)) requestTypes.push(EMBEDDINGS_REQUEST_TYPE);
    const secondaryCapabilities = Array.isArray(agent.secondary_capabilities) ? agent.secondary_capabilities : seed.secondary_capabilities;
    if (toolUse.capable && !secondaryCapabilities.includes("tool_use")) secondaryCapabilities.push("tool_use");
    if (embedding.capable && !secondaryCapabilities.includes("embeddings")) secondaryCapabilities.push("embeddings");
    return {
      ...seed,
      ...agent,
      model_id: seed.model_id,
      provider: agent.provider || seed.provider,
      family: agent.family || seed.family,
      quantization: agent.quantization || seed.quantization,
      runnable: agent.runnable === false ? false : seed.runnable,
      request_types: requestTypes,
      secondary_capabilities: secondaryCapabilities,
      tool_use: toolUse,
      embedding,
      routing_weight: Number.isFinite(agent.routing_weight) ? agent.routing_weight : seed.routing_weight,
      llmdb_reference: agent.llmdb_reference || seed.llmdb_reference,
      rationale: agent.rationale || seed.rationale,
    };
  });

  return {
    classification_source: "classifier_agent",
    generated_by_model: modelId,
    llmdb_source_url: sourceUrl,
    tool_use_policy: toolUsePolicy(),
    models,
    routes: buildRoutes(models),
    notes: Array.isArray(result.notes) ? result.notes : [
      "Generated by local classifier agent with LLMDB references and deterministic route normalization.",
    ],
  };
}

function buildRouterPrompt(classification, baseUrl) {
  const routes = Array.isArray(classification.routes) ? classification.routes : [];
  const lines = [
    "You are the FortisAI local LLM router.",
    "Classify the user's request and select the best local OpenAI-compatible model from the routing table.",
    "Return a concise routing decision with request_type, selected_model, fallback_models, and rationale.",
    "If a request includes tools, function calls, API actions, workflow orchestration, or explicit tool_choice, use agentic_tool_use.",
    "All routes must use the selected preferred model; do not substitute a warm model for cold-load avoidance.",
    "The agentic_tool_use route also requires tool_use capability and force-loads the selected model.",
    "If the request does not clearly match a specialized route, use analysis_research.",
    "",
    `Local OpenAI-compatible endpoint: ${baseUrl}`,
    "",
    "Routing table:",
  ];

  for (const route of routes) {
    if (!route || typeof route !== "object") continue;
    const fallbackModels = Array.isArray(route.fallback_models) ? route.fallback_models : [];
    const hints = Array.isArray(route.match_hints) ? route.match_hints : [];
    lines.push([
      `- request_type: ${route.request_type || "unknown"}`,
      `description: ${route.description || ""}`,
      `primary_model: ${route.primary_model || ""}`,
      `fallback_models: ${fallbackModels.join(", ") || "none"}`,
      `match_hints: ${hints.join(", ") || "none"}`,
      `required_capabilities: ${(route.required_capabilities || []).join(", ") || "none"}`,
      `force_model_load: ${route.force_model_load === true ? "true" : "false"}`,
    ].join("; "));
  }

  return lines.join("\n");
}

async function classifyWithAgent(baseUrl, modelId, localModels, llmdbModels, sourceUrl) {
  if (process.env.SKIP_LLM_CLASSIFIER === "1") {
    return buildFallbackResult(localModels, llmdbModels, sourceUrl);
  }

  const compactModels = compactForAgent(localModels, llmdbModels);
  const system = [
    "You are the FortisAI local LLM routing classifier agent.",
    "Use the compact local model rows, seed labels, and nearest LLMDB hints to review routing labels for Dify.",
    "Return only valid JSON. Do not wrap the result in markdown.",
    "Return only models[] rows that need changes from the provided seed labels.",
    "It is valid to return {\"models\":[]} when the seed labels are already suitable.",
    "Use request_types from this controlled list only: " + REQUEST_TYPES.map((item) => item.id).join(", ") + ".",
    "Mark u:true for models that can reliably plan or execute tool/function/API calls; keep agentic_tool_use in r for those models.",
    "Keep embeddings in r for small, stable text embedding models used by Qdrant/RAG/vector memory; avoid assigning embeddings to large reasoning or tool-specialist models unless they are explicitly embedding-oriented.",
    "Prefer the seed labels unless the model name or LLMDB hint clearly supports a better route.",
    "Return compact JSON as {\"models\":[{\"i\":1,\"r\":[...],\"t\":\"balanced\",\"w\":70,\"u\":true},...]}; i must match the input row number.",
    "Do not repeat model IDs in the output. Omit rationales and notes.",
  ].join("\n");
  const user = {
    task: "Review the seed route labels for each local OpenAI-compatible model.",
    output_schema: {
      models: [{
        i: "input row number",
        r: ["controlled request_type ids"],
        u: "true when the model should be treated as tool-use capable",
        t: "high|balanced|fast|safety|support_asset",
        w: "integer 0-100"
      }]
    },
    request_type_ids: REQUEST_TYPES.map((item) => item.id),
    local_models: compactModels,
  };
  const body = {
    model: modelId,
    messages: [
      { role: "system", content: system },
      { role: "user", content: JSON.stringify(user) },
    ],
    temperature: 0.1,
    max_tokens: Number(process.env.LLM_ROUTER_CLASSIFIER_MAX_TOKENS || 2048),
    response_format: { type: "json_object" },
    stream: process.env.LLM_ROUTER_CLASSIFIER_STREAM !== "0",
  };

  const timeout = Number(process.env.LLM_ROUTER_CLASSIFIER_TIMEOUT_MS || 900000);
  const { text } = await fetchWithTimeout(`${baseUrl}/chat/completions`, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      authorization: `Bearer ${process.env.FORTISAI_LLAMA_OPENAI_API_KEY || process.env.OPENAI_API_KEY || "local-llama"}`,
    },
    body: JSON.stringify(body),
  }, timeout);
  const content = extractOpenAiContent(text);
  const result = extractJsonObject(content);
  return normalizeAgentResult(result, localModels, llmdbModels, sourceUrl, modelId);
}

function buildRouterReferenceConfig(classification, baseUrl, generatedAt) {
  return {
    kind: "fortisai.dify.openai-compatible-router.v1",
    metadata: {
      name: "local-openai-compatible-router",
      description: "Routes Dify requests across local OpenAI-compatible models using scheduled LLMDB-assisted classification.",
      generated_at: generatedAt,
      generated_by: "n8n local-llm-router-classification",
    },
    provider: {
      name: "fortisai-local-openai-compatible",
      type: "openai_api_compatible",
      endpoint_base_url: baseUrl,
      api_key_env: "FORTISAI_LLAMA_OPENAI_API_KEY",
      classifier_model: classification.generated_by_model || classification.classifier_model || DEFAULT_CLASSIFIER_MODEL,
    },
    routing_policy: {
      default_request_type: "analysis_research",
      request_type_order: REQUEST_TYPES.map((item) => item.id),
      selection: "Use the first route whose match_hints or upstream classifier match the user request; fall back to analysis_research.",
      tool_use_policy: classification.tool_use_policy || toolUsePolicy(),
    },
    routes: classification.routes,
    models: classification.models,
    llmdb: {
      source_url: classification.llmdb_source_url,
      classification_source: classification.classification_source,
    },
    notes: classification.notes,
  };
}

function buildDifyAppConfig(classification, baseUrl, generatedAt) {
  const appName = "local-openai-compatible-router";
  const classifierModel = classification.generated_by_model || classification.classifier_model || DEFAULT_CLASSIFIER_MODEL;
  const description = "Routes Dify requests across local OpenAI-compatible models using scheduled LLMDB-assisted classification.";
  const prompt = buildRouterPrompt(classification, baseUrl);
  const routeModels = [...new Set((classification.routes || []).flatMap((route) => {
    if (!route || typeof route !== "object") return [];
    return [route.primary_model, ...(Array.isArray(route.fallback_models) ? route.fallback_models : [])].filter(Boolean);
  }))];

  return {
    app: {
      description,
      icon: "🤖",
      icon_background: "#FFEAD5",
      icon_type: "emoji",
      mode: "advanced-chat",
      name: appName,
      use_icon_as_answer_icon: false,
    },
    dependencies: [
      {
        current_identifier: null,
        type: "marketplace",
        value: {
          marketplace_plugin_unique_identifier: "langgenius/openai_api_compatible:0.0.53@a0dfb462961a03c6a6415d4185043185b01017c64da93cf82a9e5ecaf59f8ed0",
          version: null,
        },
      },
    ],
    kind: "app",
    version: "0.6.0",
    workflow: {
      conversation_variables: [],
      environment_variables: [],
      features: {
        file_upload: {
          enabled: false,
          allowed_file_extensions: [],
          allowed_file_types: [],
          allowed_file_upload_methods: [],
          fileUploadConfig: {
            attachment_image_file_size_limit: 2,
            audio_file_size_limit: 50,
            batch_count_limit: 5,
            file_size_limit: 15,
            file_upload_limit: 20,
            image_file_batch_limit: 10,
            image_file_size_limit: 10,
            single_chunk_attachment_limit: 10,
            video_file_size_limit: 100,
            workflow_file_upload_limit: 10,
          },
          image: {
            enabled: false,
            number_limits: 3,
            transfer_methods: [],
          },
          number_limits: 3,
        },
        opening_statement: "",
        retriever_resource: {
          enabled: false,
        },
        sensitive_word_avoidance: {
          enabled: false,
        },
        speech_to_text: {
          enabled: false,
        },
        suggested_questions: [],
        suggested_questions_after_answer: {
          enabled: false,
        },
        text_to_speech: {
          enabled: false,
          language: "",
          voice: "",
        },
      },
      graph: {
        edges: [
          {
            data: {
              isInLoop: false,
              sourceType: "start",
              targetType: "llm",
            },
            id: "start-to-llm",
            source: "start",
            sourceHandle: "source",
            target: "llm",
            targetHandle: "target",
            type: "custom",
            zIndex: 0,
          },
          {
            data: {
              isInLoop: false,
              sourceType: "llm",
              targetType: "answer",
            },
            id: "llm-to-answer",
            source: "llm",
            sourceHandle: "source",
            target: "answer",
            targetHandle: "target",
            type: "custom",
            zIndex: 0,
          },
        ],
        nodes: [
          {
            data: {
              desc: "",
              selected: false,
              title: "User Input",
              type: "start",
              variables: [],
            },
            height: 74,
            id: "start",
            position: {
              x: 80,
              y: 280,
            },
            positionAbsolute: {
              x: 80,
              y: 280,
            },
            selected: false,
            sourcePosition: "right",
            targetPosition: "left",
            type: "custom",
            width: 243,
          },
          {
            data: {
              context: {
                enabled: false,
                variable_selector: [],
              },
              desc: "",
              model: {
                completion_params: {
                  temperature: 0.1,
                },
                mode: "chat",
                name: classifierModel,
                provider: "langgenius/openai_api_compatible/openai_api_compatible",
              },
              prompt_template: [
                {
                  id: "fortisai-router-system-prompt",
                  role: "system",
                  text: prompt,
                },
              ],
              selected: false,
              title: "Route Request",
              type: "llm",
              vision: {
                enabled: false,
              },
            },
            height: 89,
            id: "llm",
            position: {
              x: 400,
              y: 280,
            },
            positionAbsolute: {
              x: 400,
              y: 280,
            },
            selected: false,
            sourcePosition: "right",
            targetPosition: "left",
            type: "custom",
            width: 243,
          },
          {
            data: {
              answer: "{{#llm.text#}}",
              desc: "",
              selected: false,
              title: "Answer",
              type: "answer",
              variables: [],
            },
            height: 105,
            id: "answer",
            position: {
              x: 720,
              y: 280,
            },
            positionAbsolute: {
              x: 720,
              y: 280,
            },
            sourcePosition: "right",
            targetPosition: "left",
            type: "custom",
            width: 243,
          },
        ],
        viewport: {
          x: 0,
          y: 0,
          zoom: 1,
        },
      },
      rag_pipeline_variables: [],
    },
    fortisai: {
      generated_at: generatedAt,
      generated_by: "n8n local-llm-router-classification",
      openai_base_url: baseUrl,
      classifier_model: classifierModel,
      route_models: routeModels,
      classification_source: classification.classification_source,
      router_kind: "fortisai.dify.openai-compatible-router.v1",
    },
  };
}

function buildGeneratedSetupScript() {
  return `#!/usr/bin/env node
"use strict";

import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const generatedDir = path.dirname(fileURLToPath(import.meta.url));
const difyConfigDir = path.resolve(generatedDir, "../../..");
const script = path.join(difyConfigDir, "setup-openai-compatible-models.mjs");
const args = [
  script,
  "--classification-json",
  path.join(generatedDir, "local-llm-classification.generated.json"),
  ...process.argv.slice(2),
];

const result = spawnSync(process.execPath, args, {
  env: process.env,
  stdio: "inherit",
});

if (result.error) {
  console.error(JSON.stringify({ status: "error", message: result.error.message }, null, 2));
  process.exit(1);
}
process.exit(result.status ?? 1);
`;
}

function buildGeneratedImportScript() {
  return `#!/usr/bin/env node
"use strict";

import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const generatedDir = path.dirname(fileURLToPath(import.meta.url));
const difyConfigDir = path.resolve(generatedDir, "../../..");
const script = path.join(difyConfigDir, "import-local-openai-compatible-router.mjs");
const args = [
  script,
  "--yaml",
  path.resolve(generatedDir, "../configurations/local-openai-compatible-router.yaml"),
  ...process.argv.slice(2),
];

const result = spawnSync(process.execPath, args, {
  env: process.env,
  stdio: "inherit",
});

if (result.error) {
  console.error(JSON.stringify({ status: "error", message: result.error.message }, null, 2));
  process.exit(1);
}
process.exit(result.status ?? 1);
`;
}

async function main() {
  const root = repoRoot();
  const n8nConfigDir = process.env.FORTISAI_N8N_CONFIG_DIR || path.join(root, "Development_Environment", "n8n-config");
  const difyConfigDir = process.env.FORTISAI_DIFY_CONFIG_DIR || path.join(root, "Development_Environment", "dify-config");
  const baseUrl = primaryOpenAiBaseUrl();
  const difyBaseUrl = difyOpenAiBaseUrl(baseUrl);
  const requestedClassifierModel = classifierModel();
  const generatedAt = new Date().toISOString();

  const disabledManifest = readDisabledManifest(root);
  const fetchedLocalModels = await fetchOpenAiModels(baseUrl);
  if (!fetchedLocalModels.length) throw new Error(`No models returned by ${baseUrl}/models`);
  const splitFilter = filterNonFirstSplitShardModels(fetchedLocalModels);
  const { localModels, excludedDisabledModels } = filterDisabledLocalModels(splitFilter.localModels, disabledManifest, root);
  const excludedSplitShardModels = splitFilter.excludedSplitShardModels;
  if (!localModels.length) {
    throw new Error(
      `All ${fetchedLocalModels.length} model(s) returned by ${baseUrl}/models were filtered by split-shard and disabled-model rules`,
    );
  }
  const classifierChoice = chooseActiveClassifierModel(requestedClassifierModel, localModels);
  const modelId = classifierChoice.modelId;

  const llmdb = await fetchLlmdbModels();
  let classification;
  let classifierError = null;
  try {
    classification = await classifyWithAgent(baseUrl, modelId, localModels, llmdb.models, llmdb.sourceUrl);
  } catch (error) {
    classifierError = error;
    classification = buildFallbackResult(localModels, llmdb.models, llmdb.sourceUrl);
    classification.notes.push(`Classifier agent failed: ${error.message}`);
  }
  if (disabledManifest.warning) {
    classification.notes.push(disabledManifest.warning);
  }
  if (excludedDisabledModels.length) {
    classification.notes.push(
      `Excluded ${excludedDisabledModels.length} disabled local model(s) from router classification.`,
    );
  }
  if (excludedSplitShardModels.length) {
    classification.notes.push(
      `Excluded ${excludedSplitShardModels.length} non-first split GGUF shard(s); split sets are classified through shard 00001 only.`,
    );
  }
  if (classifierChoice.note) {
    classification.notes.push(classifierChoice.note);
  }
  classification.classifier_model = modelId;
  classification.requested_classifier_model = classifierChoice.requestedModelId;
  classification.classifier_model_changed = classifierChoice.changed;

  const difyAppConfig = buildDifyAppConfig(classification, difyBaseUrl, generatedAt);
  const routerReferenceConfig = buildRouterReferenceConfig(classification, difyBaseUrl, generatedAt);
  const difyGeneratedDir = path.join(difyConfigDir, "main", "dify", "generated");
  const difyConfigurationsDir = path.join(difyConfigDir, "main", "dify", "configurations");
  const n8nGeneratedDir = path.join(n8nConfigDir, "main", "n8n", "generated");
  ensureDir(difyGeneratedDir);
  ensureDir(difyConfigurationsDir);
  ensureDir(n8nGeneratedDir);

  const routerYamlFile = path.join(difyConfigurationsDir, "local-openai-compatible-router.yaml");
  const routerGeneratedYamlFile = path.join(difyGeneratedDir, "local-openai-compatible-router.generated.yaml");
  const routerReferenceYamlFile = path.join(difyGeneratedDir, "local-openai-compatible-router.reference.yaml");
  const classificationJsonFile = path.join(difyGeneratedDir, "local-llm-classification.generated.json");
  const modelSetupScriptFile = path.join(difyGeneratedDir, "setup-openai-compatible-models.mjs");
  const routerImportScriptFile = path.join(difyGeneratedDir, "import-local-openai-compatible-router.mjs");
  const runReportFile = path.join(n8nGeneratedDir, "weekly-local-llm-router-classification.last-run.json");

  const yaml = toYaml(difyAppConfig) + "\n";
  const referenceYaml = toYaml(routerReferenceConfig) + "\n";
  fs.writeFileSync(routerYamlFile, yaml, "utf8");
  fs.writeFileSync(routerGeneratedYamlFile, yaml, "utf8");
  fs.writeFileSync(routerReferenceYamlFile, referenceYaml, "utf8");
  writeText(modelSetupScriptFile, buildGeneratedSetupScript(), 0o755);
  writeText(routerImportScriptFile, buildGeneratedImportScript(), 0o755);
  writeJson(classificationJsonFile, {
    generated_at: generatedAt,
    openai_base_url: baseUrl,
    dify_openai_base_url: difyBaseUrl,
    classifier_model: modelId,
    classifier_error: classifierError ? classifierError.message : null,
    disabled_manifest_file: disabledManifest.file,
    disabled_model_count: disabledManifest.records.length,
    excluded_split_shard_model_count: excludedSplitShardModels.length,
    excluded_split_shard_models: excludedSplitShardModels,
    excluded_disabled_model_count: excludedDisabledModels.length,
    excluded_disabled_models: excludedDisabledModels,
    requested_classifier_model: classifierChoice.requestedModelId,
    classifier_model_changed: classifierChoice.changed,
    ...classification,
  });
  writeJson(runReportFile, {
    generated_at: generatedAt,
    openai_base_url: baseUrl,
    dify_openai_base_url: difyBaseUrl,
    local_model_count: localModels.length,
    fetched_local_model_count: fetchedLocalModels.length,
    disabled_manifest_file: disabledManifest.file,
    disabled_model_count: disabledManifest.records.length,
    excluded_split_shard_model_count: excludedSplitShardModels.length,
    excluded_split_shard_models: excludedSplitShardModels,
    excluded_disabled_model_count: excludedDisabledModels.length,
    excluded_disabled_models: excludedDisabledModels,
    llmdb_model_count: llmdb.models.length,
    requested_classifier_model: classifierChoice.requestedModelId,
    classifier_model: modelId,
    classifier_model_changed: classifierChoice.changed,
    classification_source: classification.classification_source,
    classifier_error: classifierError ? classifierError.message : null,
    outputs: {
      routerYamlFile,
      routerGeneratedYamlFile,
      routerReferenceYamlFile,
      classificationJsonFile,
      modelSetupScriptFile,
      routerImportScriptFile,
    },
  });

  const summary = {
    status: "ok",
    generated_at: generatedAt,
    openai_base_url: baseUrl,
    dify_openai_base_url: difyBaseUrl,
    local_model_count: localModels.length,
    fetched_local_model_count: fetchedLocalModels.length,
    disabled_model_count: disabledManifest.records.length,
    excluded_split_shard_model_count: excludedSplitShardModels.length,
    excluded_disabled_model_count: excludedDisabledModels.length,
    llmdb_model_count: llmdb.models.length,
    requested_classifier_model: classifierChoice.requestedModelId,
    classifier_model: modelId,
    classifier_model_changed: classifierChoice.changed,
    classification_source: classification.classification_source,
    classifier_error: classifierError ? classifierError.message : null,
    router_yaml: routerYamlFile,
    router_reference_yaml: routerReferenceYamlFile,
    classification_json: classificationJsonFile,
    model_setup_script: modelSetupScriptFile,
    router_import_script: routerImportScriptFile,
  };
  console.log(JSON.stringify(summary, null, 2));
}

main().catch((error) => {
  console.error(JSON.stringify({ status: "error", message: error.message, stack: error.stack }, null, 2));
  process.exit(1);
});
