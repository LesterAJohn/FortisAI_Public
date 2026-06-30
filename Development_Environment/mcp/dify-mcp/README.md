# Dify Skill Assets

This directory contains Dify-focused OpenWebUI skill assets only.

## Prerequisites

- Dify key cache location, generated locally when needed: `Development_Environment/mcp/dify-mcp/dify-api-key.json`
- API keys are synced through Vault by helper startup, then loaded from environment or the generated local compatibility cache for bridge startup.
- MCP bridges started via helper `mcp-up` command and stopped via `mcp-down`.

## Files

- `dify-openapi-bridge.py`: Dify API OpenAPI bridge for MCP-style tooling.
- `openwebui-dify-mcp-tools.import.json`: OpenWebUI tool-server import payload for the Dify bridge.
- `openwebui-dify-mcp-skill.py`: Dify-only OpenWebUI tool module.
- `openwebui-dify-mcp-skill.create.json`: OpenWebUI Skills API payload.
- `openwebui-dify-mcp-skill.content.md`: skill content text.

## OpenWebUI MCP Setup (Dify Bridge)

1. Start helper-managed MCP bridges (`mcp-up`) for SQLcl, n8n, Dify, debug, and optional Proxmox when configured.
2. Stop helper-managed MCP bridges with `mcp-down` when bridge access is no longer needed.
3. Confirm Dify bridge endpoint is healthy:
	- `http://127.0.0.1:8093/healthz`
	- `http://127.0.0.1:8093/openapi.json`
	- `http://127.0.0.1:8094/openapi.json`
	- `http://127.0.0.1:8093/dify_connection_info`
	- `http://127.0.0.1:8093/v1/models`
4. Import OpenWebUI tool payload using `openwebui-dify-mcp-tools.import.json`.
5. If using helper-managed OpenWebUI wiring, verify connection name `mcp-dify-server` exists in `tool_server.connections`.

## FortisAI OpenAI-Compatible Router

The Dify OpenAPI bridge exposes the generated `local-openai-compatible-router` app through an OpenAI-compatible facade. The public model is always `fortisai`; the bridge selects the supporting local model from `Development_Environment/dify-config/main/dify/generated/local-llm-classification.generated.json` and proxies to the primary `fortisai-llama-server` endpoint. Hermes and OpenClaw call this FortisAI proxy endpoint. The secondary `fortisai-llama-server-secondary` endpoint is reserved for support tools that need direct model or embedding access, including Honcho and CodeIndexer.

Host URL after helper startup:

```bash
curl -sS http://127.0.0.1:8093/v1/models | jq
```

Example chat request:

```bash
curl -sS http://127.0.0.1:8093/v1/chat/completions \
	-H 'Content-Type: application/json' \
	-d '{"model":"fortisai","messages":[{"role":"user","content":"Summarize FortisAI in one sentence."}],"max_tokens":80,"temperature":0}'
```

Example Responses API request:

```bash
curl -sS http://127.0.0.1:8093/v1/responses \
	-H 'Content-Type: application/json' \
	-d '{"model":"fortisai","input":"Summarize FortisAI in one sentence.","max_output_tokens":80}'
```

Example embeddings request:

```bash
curl -sS http://127.0.0.1:8093/v1/embeddings \
	-H 'Content-Type: application/json' \
	-d '{"model":"fortisai","input":"FortisAI local development"}'
```

The bridge preserves normal OpenAI-compatible request options such as `temperature`, `max_tokens`, `max_output_tokens`, `top_p`, `tools`, `response_format`, and `stream`. Before forwarding chat requests to llama.cpp, the bridge normalizes flat or legacy function-tool definitions into the nested OpenAI `{"type":"function","function":{...}}` schema required by llama.cpp, and merges all `system` and `developer` messages into one leading `system` message so strict Jinja chat templates do not reject system messages that appear later in the message list. Non-streaming chat/completion responses include a `fortisai` metadata object with the selected request type, routed local model, and Honcho memory session. The router always forwards to the classified preferred model and waits for that model to load when cold. Helper startup sets `FORTISAI_OPENAI_ROUTER_TIMEOUT_SECONDS=600` and `FORTISAI_OPENAI_ROUTER_PREFER_LOADED_MODELS=false`; already-loaded model substitution is disabled.

The FortisAI `/v1/chat/completions`, `/v1/completions`, and `/v1/responses` facade requires Honcho memory by default. Request flow is `client -> FortisAI proxy -> Honcho memory lookup -> classification/routing -> selected primary llama-server model -> Honcho writeback`. The proxy recognizes users from the OpenAI `user` field, common metadata fields, `X-FortisAI-User`, `X-User-ID`, OpenWebUI user headers, or a hashed authorization identity. If no caller identity is provided, it uses `fortisai_default_user`. The writeback path was validated on `aiengine000` with a unique marker present in Honcho `messages/list` and session `context`.

Route matching uses exact words and phrases from the generated `match_hints`, so short hints such as `api` or `script` do not match unrelated words like `capital` or `transcript`.

## FortisAI Tool Execution Bridge

The `/v1/chat/completions` facade includes a helper-managed tool execution bridge so direct Dify/OpenAI-compatible clients can execute the same OpenAPI/MCP tools advertised to OpenWebUI by skills. When the model emits an OpenAI `tool_calls` object, a JSON tool-call block, or XML-style text such as `<tool_call>n8n_list_workflows(limit=5)</code>`, the bridge searches installed OpenWebUI skills, confirms the named tool exists in the matching imported OpenAPI server, executes the endpoint, injects the tool result as real external data, and asks the model for the final answer.

The bridge also performs preflight execution for clear tool-backed requests before the first model planning pass. This covers explicit web/current/site-data prompts, read-only skill-backed prompts such as Proxmox/n8n/OpenMetadata status or listing requests, Dify app listing, CodeIndexer GitHub repository indexing, and explicit Daytona Python execution in the helper-managed sandbox. CodeIndexer, Dify app listing, and Daytona code execution keep their specialized precedence; explicit web/current/real-data prompts then select Websearch before the generic read-only and Qdrant tool-memory fallback paths. If a prompt only plans with XML/JSON tool-call text, the same generic parser still mediates the call after the first model pass.

Tool preflight and routing use a sanitized user-intent view of the prompt. OpenWebUI-generated Code Interpreter, Pyodide, and persistent-file-system instruction blocks are stripped before the bridge decides whether a tool is required. This keeps profiles that advertise Code Interpreter on every chat from accidentally triggering Daytona code execution or the `agentic_tool_use` route for ordinary informational questions. Explicit user requests such as "generate and execute a Python script" still select Daytona. Advertised OpenAI tool schemas with `tool_choice: auto` are treated as available tools, not as a hard tool-use requirement; forced `tool_choice` or `function_call` values still route as required tool use.

Tool discovery is skill-gated rather than maintained as a hand-built registry. The preferred source is `GET /api/v1/skills/export` on OpenWebUI, with `GET /api/v1/skills/id/{id}` as detail fallback when only summaries are available. For each skill-bound OpenAPI server, the bridge loads the imported OpenAPI schema and exposes all endpoints allowed by the OpenWebUI import filter, so future tools become callable when their tool-server connection and skill are imported. The bridge also stores tool metadata in Qdrant under the configured tool-memory collection for fallback recall when direct token matching is insufficient.

The bridge resolves the OpenWebUI API key from the current request user first, using OpenWebUI user headers and OpenAI `user` or metadata fields, then reads Vault path `secret/fortisai/dev/openwebui/users/<normalized-user>/api_key`. If no request user is provided, the bridge uses `FORTISAI_OPENWEBUI_DEFAULT_API_KEY_USER` for the lookup. If OpenWebUI skill lookup is unavailable, the bridge falls back to source-controlled skill payloads under `Development_Environment/mcp/`.

Helper startup makes this permanent with these environment variables on the Dify OpenAPI bridge container:

- `FORTISAI_TOOL_EXECUTION_BRIDGE_ENABLED=true`
- `FORTISAI_TOOL_EXECUTION_MAX_ROUNDS=1`
- `FORTISAI_TOOL_EXECUTION_TIMEOUT_SECONDS=300`
- `FORTISAI_TOOL_EXECUTION_PREFLIGHT_LLM_TIMEOUT_SECONDS=300`
- `FORTISAI_TOOL_EXECUTION_RESULT_LIMIT_CHARS=12000`
- `FORTISAI_TOOL_EXECUTION_SKILL_DISCOVERY_ENABLED=true`
- `FORTISAI_TOOL_EXECUTION_OPENWEBUI_SKILL_API_ENABLED=true`
- `FORTISAI_TOOL_MEMORY_QDRANT_ENABLED=true`
- `FORTISAI_TOOL_MEMORY_QDRANT_COLLECTION=fortisai_tool_registry`
- `FORTISAI_DAYTONA_DEFAULT_SANDBOX=fortisai-openwebui-smoke`
- `FORTISAI_OPENWEBUI_URL=http://fortisai-openwebui.fortisai.local:8080`
- `FORTISAI_OPENWEBUI_DEFAULT_API_KEY_USER=LesterAJohn@gmail.com`
- `FORTISAI_WEBSEARCH_OPENAPI_BASE_URL=http://fortisai-mcp-openapi-websearch.fortisai.local:8097`

Use helper command `./Development_Environment/linux/fortisai-dev-helper.sh openwebui-api <user email> <api key>` to add or rotate a user-scoped OpenWebUI API key. `FORTISAI_TOOL_EXECUTION_REGISTRY_JSON` remains available for explicit emergency overrides; otherwise the bridge should discover callable tools from OpenWebUI skills. The bridge logs detected tool calls, skipped unavailable tools, execution start/success/failure, status code, elapsed time, skill-discovery source, normalized user, and the final `tool_execution_bridge` metadata on the routed response. Health endpoints remain reachable for helper smoke checks; CodeIndexer remains in the callable OpenWebUI tool list.

Preview a routing decision without running a model:

```bash
curl -sS http://127.0.0.1:8093/fortisai_router_preview \
	-H 'Content-Type: application/json' \
	-d '{"model":"fortisai","messages":[{"role":"user","content":"Summarize this meeting transcript."}]}'
```

## Reload OpenWebUI Dify Assets

When `openwebui-dify-mcp-tools.import.json`, `openwebui-dify-mcp-skill.create.json`, or `openwebui-dify-mcp-skill.content.md` changes, reload both assets:

```bash
# Tool-server connection reload
bash Development_Environment/mcp/reload-openwebui-tool-connection.sh \
	Development_Environment/mcp/dify-mcp/openwebui-dify-mcp-tools.import.json

# Skill reload (same id is deleted first, then created)
bash Development_Environment/mcp/create-openwebui-skill.sh \
	Development_Environment/mcp/dify-mcp/openwebui-dify-mcp-skill.create.json
```

Verification:

```bash
curl -sS http://127.0.0.1:8093/dify_connection_info | jq
curl -sS http://127.0.0.1:8093/v1/chat/completions \
	-H 'Content-Type: application/json' \
	-H 'X-FortisAI-User: docs-smoke-user' \
	-d '{"model":"fortisai","messages":[{"role":"user","content":"Reply with one short sentence."}],"max_tokens":32}'
```

And in OpenWebUI:

- Tool connection name should be `mcp-dify-server`.
- Skill id should be `fortisai-dify-mcp-orchestrator`.

## Runtime Notes

- Dify bridge reads `DIFY_BASE_URL`, `DIFY_API_KEY`, `DIFY_ADMIN_API_KEY`, `DIFY_CONSOLE_ACCESS_TOKEN`, and optional `DIFY_ADMIN_WORKSPACE_ID` from environment.
- For model setup automation, the Dify bridge also reads `DIFY_DB_HOST`, `DIFY_DB_PORT`, `DIFY_DB_NAME`, `DIFY_DB_USER`, and `DIFY_DB_PASSWORD`.
- When `DIFY_ADMIN_WORKSPACE_ID` is unset, the bridge attempts to auto-resolve it at startup from `/console/api/workspaces` using `DIFY_ADMIN_API_KEY`.
- `ADMIN_API_KEY` is still accepted as a backward-compatible fallback for admin auth and, if needed, legacy app auth wiring.
- Helper and bridge launcher auto-load the app key from generated `dify-api-key.json` when env vars are unset; do not commit this local cache.
- `/dify_api_request` supports `authMode` values `auto`, `app`, `admin`, `console`, and `none`.
- `/dify_openai_compatible_model_setup` configures generated local OpenAI-compatible models by reusing an existing validated Dify credential template and upserting provider model rows directly in the Dify database.
- `/v1/models`, `/v1/chat/completions`, `/v1/completions`, `/v1/embeddings`, and `/v1/responses` provide the `fortisai` OpenAI-compatible router facade for local clients.
- Generation endpoints use Honcho before routing and after response. The default workspace is `fortisai`; user peers are generated from the request identity; assistant peer defaults to `assistant_fortisai_proxy`.
- The primary llama-server catalog is expected to stay populated while the secondary router is restarted. The Linux helper refreshes the shared model catalog in place so `/v1/models` on both primary and secondary routers keep the same router-visible model set.
- `/fortisai_router_preview` and `/fortisai/v1/router/preview` return the selected route and candidate models without calling the upstream LLM.
- Requests with forced `tool_choice`/`function_call` values or clear user tool-use language route to `agentic_tool_use`. Plain advertised OpenAI `tools` or `functions` with automatic tool choice no longer force that route by themselves.
- Streaming `/v1/chat/completions` requests return an SSE response immediately and send SSE comment keepalives while a local model is cold-loading or slow to produce its first token. Synthetic OpenAI stream chunks include `id`, `object`, `created`, and `model`; keepalives stay outside the JSON event stream so clients such as Cline do not interpret them as empty assistant content. Streamed upstream chunks are normalized back to the public `fortisai` model name and null content deltas are converted to empty strings. If the upstream stream closes without forwarding `data: [DONE]`, the bridge emits the final `[DONE]` marker before closing the client stream.
- Cline-style prompts and OpenAI tool definitions that reference `execute_command` receive an additional guard instruction requiring `requires_approval`. The bridge also patches forwarded `execute_command` tool schemas so `requires_approval` is required with a default of `true`. If a model still emits an `execute_command` block or tool call without that required field, the bridge repairs it to approval-required before returning the response, including when the XML opening tag is split across streaming chunks. Guarded Cline tool requests do not use a Cline-specific model default; they follow the generated FortisAI/Dify `agentic_tool_use` route recommendation. The default is approval-required, never auto-run.
- Cline tool requests still use Honcho and RAG, but the retrieval query and injected context are capped with `FORTISAI_CLINE_RETRIEVAL_QUERY_CHARS=1200` and `FORTISAI_CLINE_CONTEXT_LIMIT_CHARS=1600` by default. This keeps Cline workspace/tool prompts from being inflated by large memory and web-search context while preserving the normal FortisAI retrieval path for other clients.
- The router facade reads `FORTISAI_OPENAI_ROUTER_MODEL`, `FORTISAI_OPENAI_ROUTER_APP_NAME`, `FORTISAI_OPENAI_ROUTER_CLASSIFICATION_FILE`, `FORTISAI_OPENAI_ROUTER_TIMEOUT_SECONDS`, `FORTISAI_OPENAI_ROUTER_FORCE_LOAD_TIMEOUT_SECONDS`, `FORTISAI_OPENAI_ROUTER_STREAM_KEEPALIVE_SECONDS`, `FORTISAI_OPENAI_ROUTER_DEFAULT_MAX_TOKENS`, `FORTISAI_OPENAI_ROUTER_MAX_TOKENS_HARD_LIMIT`, `FORTISAI_OPENAI_ROUTER_MODEL_STATUS_TIMEOUT_SECONDS`, `FORTISAI_OPENAI_ROUTER_MODEL_STATUS_CACHE_SECONDS`, `FORTISAI_CLINE_TOOL_GUARD_ENABLED`, `FORTISAI_CLINE_TOOL_MAX_TOKENS`, `FORTISAI_CLINE_RETRIEVAL_QUERY_CHARS`, `FORTISAI_CLINE_CONTEXT_LIMIT_CHARS`, `FORTISAI_LLAMA_OPENAI_BASE_URL`, `FORTISAI_LLAMA_OPENAI_API_KEY`, `FORTISAI_OPENAI_EMBEDDING_MODEL`, `FORTISAI_HONCHO_BASE_URL`, `FORTISAI_HONCHO_REQUIRED`, `FORTISAI_HONCHO_WORKSPACE_ID`, `FORTISAI_HONCHO_ASSISTANT_PEER_ID`, and `FORTISAI_HONCHO_MODEL`; helper `mcp-up` sets Linux defaults automatically. The default max-token cap applies when clients omit a response limit, while the hard limit clamps explicit oversized OpenAI client values; set the hard limit to `0` only for intentionally uncapped tests. `FORTISAI_OPENAI_EMBEDDING_MODEL` is an explicit operator override; when unset, `/v1/embeddings` uses the generated `embeddings` route from the monthly local model classification.
- `FORTISAI_HONCHO_MODEL` defaults to `mistral__mistralai_Mistral-Small-3.2-24B-Instruct-2506-Q8_0`, selected from the local llama-server model list for memory summaries and derivations.
- `/v1/embeddings` requires the helper-managed primary llama server to start with `--embeddings --pooling mean`; Linux helper `llama-router-up` includes this by default. When clients request public model `fortisai`, the bridge selects the concrete embedding model from the generated `embeddings` request type. Direct clients can still request a specific embedding model explicitly.
- Inside `/dify_api_request` `auto` mode, Dify `/v1/*` paths use app auth and `/console/api/*` paths use admin auth. Use explicit `authMode: "console"` only when you want to send a Dify console user access token instead.
- `/dify_connection_info` can succeed without valid keys and reports which auth materials are present.
- Key-required operations fail when the credential for the selected auth mode is unset or invalid.
- HTTP 404 from proxied requests usually indicates wrong upstream Dify path, not bridge connectivity failure.

## Notes

- Non-Dify bridge/server references were removed from this directory.
- Bridge runtime scripts now live under sibling directories in `Development_Environment/mcp/`.
