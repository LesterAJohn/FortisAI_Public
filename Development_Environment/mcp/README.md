# FortisAI MCP Components

This directory contains the local MCP-related components used by FortisAI to expose external services through MCP-compatible tools and OpenAPI bridges.

## Contents

- `create-openwebui-skill.sh` - helper that posts an OpenWebUI skill payload to the local OpenWebUI API.
- `reload-openwebui-tool-connection.sh` - helper that upserts an OpenWebUI `tool_server.connections` entry from an import payload.
- `start-mcp-openapi-bridges.sh` - launches the SQLcl, n8n, Dify, debug, CodeIndexer, Websearch, Daytona, Composio, OpenMetadata, AOL IMAP, and optional Proxmox OpenAPI bridge containers.
- `stop-mcp-openapi-bridges.sh` - stops and removes the SQLcl, n8n, Dify, debug, CodeIndexer, Websearch, Daytona, Composio, OpenMetadata, AOL IMAP, and Proxmox OpenAPI bridge containers.
- `sqlcl-mcp/` - Oracle SQLcl MCP and OpenAPI bridge assets.
- `n8n-mcp/` - n8n MCP and OpenAPI bridge assets, including the daily OpenMetadata database catalog workflow export.
- `dify-mcp/` - Dify OpenAPI bridge assets, OpenWebUI skill content, and generated local key cache support.
- `codeindexer-mcp/` - CodeIndexer OpenAPI bridge assets and OpenWebUI import payloads, including GitHub repository clone/pull/index/search skill support.
- `composio-mcp/` - restricted Composio SaaS connector gateway bridge assets and OpenWebUI import payloads.
- `openmetadata-mcp/` - OpenMetadata catalog, source onboarding, and ingestion-runner bridge assets and OpenWebUI import payloads.
- `aol-imap-mcp/` - Vault-backed AOL IMAP action bridge used by n8n spam workflows.
- `websearch-mcp/` - Firecrawl-backed websearch OpenAPI bridge assets and OpenWebUI import payloads.
- `daytona-mcp/` - Daytona sandbox lifecycle and command-execution OpenAPI bridge assets and OpenWebUI import payloads.
- `repo-openapi/` - OpenWebUI import payloads and skills for the local repo filesystem, memory, and time OpenAPI servers.
- `debug-mcp/` - debug OpenAPI bridge used by helper smoke checks.
- `proxmox/` - optional ProxmoxMCP-Plus OpenAPI bridge configuration and OpenWebUI payloads.

## Component Map

### `sqlcl-mcp/`
Oracle database tooling exposed through MCP and OpenAPI.

Key files:
- `sqlcl-mcp-server.py` - MCP stdio server for SQLcl operations.
- `sqlcl-openapi-bridge.py` - OpenAPI bridge for SQLcl-style requests.
- `openwebui-sqlcl-mcp-tools.import.json` - OpenWebUI tool-server import payload.
- `openwebui-sqlcl-mcp-skill.create.json` - OpenWebUI skill payload.

Use this component when you need Oracle SQL access, schema inspection, or read/write database operations through MCP tools.

### `n8n-mcp/`
Workflow automation tooling exposed through MCP and OpenAPI.

Key files:
- `n8n-mcp-server.py` - MCP stdio server for n8n operations.
- `n8n-openapi-bridge.py` - OpenAPI bridge for n8n API calls.
- `openwebui-n8n-mcp-tools.import.json` - OpenWebUI tool-server import payload.
- `openwebui-n8n-mcp-skill.create.json` - OpenWebUI skill payload.
- `first-workflow.json` - sample workflow payload.

Native n8n MCP endpoint passthrough is also available through the n8n OpenAPI bridge routes:

- `GET /n8n_mcp_connection_info`
- `POST /n8n_mcp_initialize`
- `POST /n8n_mcp_request`
- `POST /n8n_mcp_list_tools`
- `POST /n8n_mcp_call_tool`

Linux helper `mcp-up` can load n8n MCP endpoint values from Vault:

- `secret/fortisai/dev/n8n/mcp_server_url`
- `secret/fortisai/dev/n8n/mcp_server_bearer_token`

Use this component when you need to list, inspect, create, update, or activate n8n workflows.

### `dify-mcp/`
Dify tooling exposed through the OpenAPI bridge and OpenWebUI assets.

Key files:
- `dify-openapi-bridge.py` - FastAPI bridge that proxies Dify requests.
- `dify-api-key.json` - generated local key cache for Dify bridge authentication values when helper startup needs compatibility with the bridge launcher; it should not be committed.
- `openwebui-dify-mcp-tools.import.json` - OpenWebUI tool-server import payload.
- `openwebui-dify-mcp-skill.create.json` - OpenWebUI skill payload.
- `openwebui-dify-mcp-skill.content.md` - skill content and endpoint guidance.
- `README.md` - Dify-specific usage notes.

Use this component when you need to query Dify console or runtime endpoints through the bridge, or when automation needs to configure local OpenAI-compatible model rows for Dify.

### `codeindexer-mcp/`
CodeIndexer semantic code search exposed through a FortisAI OpenAPI bridge.

Key files:
- `codeindexer-openapi-bridge.mjs` - Node bridge that exposes the CodeIndexer MCP server over HTTP/OpenAPI.
- `openwebui-codeindexer-mcp-tools.import.json` - OpenWebUI tool-server import payload.
- `openwebui-codeindexer-mcp-skill.create.json` - OpenWebUI skill payload.
- `openwebui-codeindexer-mcp-skill.content.md` - skill source content.
- `README.md` - CodeIndexer-specific startup and endpoint notes.

Use this component when you need to index the FortisAI repository, clone and refresh allowed GitHub repositories into the helper-managed cache, or run semantic code search from OpenWebUI, Cline/Continue-compatible OpenAPI tooling, or other local agents. GitHub endpoints are exposed as `codeindexer_clone_github_repository`, `codeindexer_pull_github_repository`, `codeindexer_index_github_repository`, `codeindexer_search_github_repository`, and `codeindexer_list_github_repositories`.

### `composio-mcp/`
Restricted Composio SaaS connector gateway exposed through a FortisAI OpenAPI bridge.

Key files:
- `composio-openapi-bridge.py` - FastAPI bridge for connection info, allowed toolkit/tool discovery, and controlled tool execution against Composio.
- `openwebui-composio-mcp-tools.import.json` - OpenWebUI tool-server import payload.
- `openwebui-composio-mcp-skill.create.json` - OpenWebUI skill payload.
- `openwebui-composio-mcp-skill.content.md` - skill source content and guardrails.

Use this component for SaaS connectors that are not already covered by FortisAI-native bridges. The bridge intentionally blocks overlapping toolkit prefixes such as Firecrawl, Daytona, SQLcl, n8n, Dify, CodeIndexer, Proxmox, and OpenMetadata so existing local MCPs remain authoritative. Helper startup runs a local proxy container, `fortisai-composio-local`, and points the bridge at `http://fortisai-composio-local.fortisai.local:8090/mcp` by default. Configure `secret/fortisai/dev/composio/api_key` so the proxy can create a Composio MCP session, or provide `secret/fortisai/dev/composio/upstream_mcp_url` plus optional `secret/fortisai/dev/composio/mcp_headers_json` to forward to an already-created Composio session endpoint.

### `openmetadata-mcp/`
Curated OpenMetadata catalog, source onboarding, and ingestion runner operations exposed through a FortisAI OpenAPI bridge.

Key files:
- `openmetadata-openapi-bridge.py` - FastAPI bridge for catalog search, entity lookup, lineage, service/source management, and ingestion pipeline control.
- `openwebui-openmetadata-mcp-tools.import.json` - OpenWebUI tool-server import payload.
- `openwebui-openmetadata-catalog-skill.create.json` - OpenWebUI catalog skill payload.
- `openwebui-openmetadata-source-onboarding-skill.create.json` - OpenWebUI source onboarding skill payload.

Use this component when OpenWebUI needs to search OpenMetadata, register known database sources, or trigger/status ingestion runs. TradeEngine MongoDB and InfluxDB credentials are read from Vault; do not place them in docs or workflow exports. The current OpenMetadata image does not expose InfluxDB as a native database service type, so the bridge maps the Influx source through the `CustomDatabase` service path until native support is available. Configure the OpenMetadata API token at `secret/fortisai/dev/openmetadata/api_token` before creating sources or ingestion pipelines. On Linux, helper startup can refresh this token automatically when `secret/fortisai/dev/openmetadata/admin_email` and `secret/fortisai/dev/openmetadata/admin_password` are present in Vault.

### `aol-imap-mcp/`
Vault-backed AOL IMAP actions exposed through a FortisAI OpenAPI bridge for n8n spam workflows.

Key files:
- `aol-imap-openapi-bridge.py` - FastAPI bridge for AOL mailbox connection info, folder listing/counts, Spam-folder message fetch, message move, and message delete actions.
- `README.md` - AOL-specific runtime, Vault path, and workflow notes.

Use this component when n8n needs to process AOL IMAP mailboxes without storing app passwords in workflow exports. The bridge reads app passwords from `secret/fortisai/dev/aol/imap/*/password`, uses CoreDNS FQDN `fortisai-mcp-openapi-aol-imap.fortisai.local:8101`, and prefers IMAP UID for move/delete actions. It is intentionally documented as an n8n workflow bridge instead of a general OpenWebUI tool because its primary operations mutate mailboxes.

### `websearch-mcp/`
Firecrawl-backed web search exposed through a FortisAI OpenAPI bridge.

Key files:
- `websearch-openapi-bridge.py` - FastAPI bridge for Firecrawl `/v1/search` and `/v1/scrape`.
- `openwebui-websearch-mcp-tools.import.json` - OpenWebUI tool-server import payload.
- `openwebui-websearch-mcp-skill.create.json` - OpenWebUI skill payload.
- `openwebui-websearch-mcp-skill.content.md` - skill source content and endpoint guidance.

Use this component when OpenWebUI needs current web search or URL scraping through the running Firecrawl pod. The current Firecrawl image returns HTTP 404 on `/health`; public health checks are `/v0/health/liveness` and `/v0/health/readiness`, and `/websearch_connection_info` reports those probes without exposing the API key.

OpenWebUI's tool planner expects tool-call JSON to use `parameters`. FortisAI's Linux helper applies a small OpenWebUI middleware patch on startup so OpenAI-style `arguments` payloads, simple XML-style `<tool_call>name(key=value)</tool_call>` planner output, and explicit web/current/site-data prompts with unstructured planner output are accepted as fallbacks. Direct Dify/OpenAI-compatible chat traffic is also mediated by the Dify OpenAPI bridge: if the model prints a websearch tool call or only plans a clear web/current/site-data request, the bridge executes the registered Websearch endpoint and reruns the model with the result. A 422 response with `body.query` missing means the model or parser sent the bridge an empty payload; re-run helper `mcp-up` and OpenWebUI wiring so the parser patch, Dify tool bridge, and updated Websearch skill are active.

Non-CodeIndexer bridge health endpoints are hidden from imported OpenAPI schemas to reduce planner noise. CodeIndexer remains in the callable OpenWebUI tool list, including its index, search, GitHub, and health operations.

### `daytona-mcp/`
Daytona sandbox lifecycle and sandbox command execution exposed through a FortisAI OpenAPI bridge.

Key files:
- `daytona-openapi-bridge.py` - FastAPI bridge for Daytona health, sandbox list/get/create/delete, toolbox proxy lookup, and sandbox command execution.
- `openwebui-daytona-mcp-tools.import.json` - OpenWebUI tool-server import payload.
- `openwebui-daytona-mcp-skill.create.json` - OpenWebUI skill payload.
- `openwebui-daytona-mcp-skill.content.md` - skill source content and endpoint guidance.

Use this component when OpenWebUI needs to create or inspect Daytona sandboxes, or run commands inside an existing sandbox through the Daytona toolbox proxy. The bridge uses the running Daytona API and proxy containers through CoreDNS FQDNs, defaults to `http://daytona-api.fortisai.local:3000/api` and `http://daytona-proxy.fortisai.local:4000/toolbox`, and receives `DAYTONA_API_KEY` and optional `DAYTONA_ORG_ID` from Vault-backed helper startup. On Linux, `daytona-up` and `mcp-up` create a `fortisai-openwebui-daytona` key in the Daytona database and store it at `secret/fortisai/dev/daytona/api_key` and `secret/fortisai/dev/daytona/org_id` when Vault does not already contain one. The bridge defaults sandbox creation to the helper-managed `fortisai-ubuntu-22.04` snapshot when no snapshot is supplied; Linux helper startup adapts that snapshot to CPU or GPU-only runners, waits for Daytona to mark it active, and ensures the OpenWebUI execution sandbox named by `FORTISAI_DAYTONA_DEFAULT_SANDBOX` exists. If `daytona_execute_command` targets a missing sandbox by name, the bridge creates it with the helper snapshot and waits for it to start before executing. The Dify tool bridge uses that sandbox for explicit generated Python execution prompts.

### `repo-openapi/`
OpenWebUI assets for the local repo OpenAPI tool-server trio started by helper `up`.

Key files:
- `openwebui-repo-filesystem-tools.import.json` - OpenWebUI tool-server import payload for `repo_filesystem-server_1`.
- `openwebui-repo-filesystem-skill.create.json` - OpenWebUI skill payload for filesystem operations.
- `openwebui-repo-memory-tools.import.json` - OpenWebUI tool-server import payload for `repo_memory-server_1`.
- `openwebui-repo-memory-skill.create.json` - OpenWebUI skill payload for memory graph operations.
- `openwebui-repo-time-tools.import.json` - OpenWebUI tool-server import payload for `repo_time-server_1`.
- `openwebui-repo-time-skill.create.json` - OpenWebUI skill payload for time and timezone operations.

Use this component when OpenWebUI needs direct access to the local repo filesystem, repo memory graph, or time utilities.

### `debug-mcp/`
Debug bridge used by helper-managed MCP validation. It provides a lightweight OpenAPI target for smoke tests and bridge routing checks.

Key files:
- `debug-openapi-bridge.py` - FastAPI debug endpoint used by `mcp-up` validation.

### `proxmox/`
Optional ProxmoxMCP-Plus bridge integration. The helper starts it when Proxmox config, Proxmox environment variables, or Proxmox values in Vault are present. FortisAI builds and runs the `LesterAJohn/ProxmoxMCP-Plus` fork by default so every read and write tool can select a Proxmox environment at request time.

Key files:
- `proxmox-config.json.example` - local config template.
- `proxmox-config.multi-environment.example.json` - runtime cluster-selection config template.
- `proxmox-config.json` - local operator seed config when present; it is ignored by Git and helper startup syncs its values into Vault.
- `openwebui-proxmox-mcp-tools.import.json` - OpenWebUI tool-server import payload.
- `openwebui-proxmox-mcp-skill.create.json` - OpenWebUI skill payload.

Use this component when you need OpenWebUI/MCP access to Proxmox discovery and administration operations.

## Runtime Flow

The usual startup path is:

1. Configure local service keys and JSON values through the FortisAI dev helper.
2. Start SQLcl, n8n, Dify, debug, CodeIndexer, Websearch, Daytona, Composio, OpenMetadata, AOL IMAP, and optional Proxmox bridges with `Development_Environment/mcp/start-mcp-openapi-bridges.sh` or helper `mcp-up`. In Linux `all-up`, this MCP step runs before OpenClaw and Hermes so the FortisAI proxy endpoint is online before agent gateways start.
3. Stop bridge containers with `Development_Environment/mcp/stop-mcp-openapi-bridges.sh` or helper `mcp-down` when done.
4. Import the OpenWebUI tool payloads or skills if you want OpenWebUI to call the bridges directly. Helper `up` imports repo OpenAPI payloads automatically when OpenWebUI is running.
5. Use the bridge endpoints for health checks and API proxying.

The Dify bridge supports three auth modes: `app` for `/v1/*` using `DIFY_API_KEY`, `admin` for `/console/api/*` using `DIFY_ADMIN_API_KEY` or `ADMIN_API_KEY`, and `console` for explicit console-token calls using `DIFY_CONSOLE_ACCESS_TOKEN`. The bridge auto-selects the auth mode by path and also accepts an explicit `authMode` override on `/dify_api_request`. The helper syncs Dify keys through Vault and can generate/load the local `dify-api-key.json` compatibility cache when needed.

The Dify bridge also exposes the FortisAI OpenAI-compatible facade at `/v1/*` with public model `fortisai`. Chat, completion, and responses requests use the flow `client -> FortisAI proxy -> Honcho personal-memory lookup -> Qdrant general-knowledge vector lookup -> Firecrawl web search -> classifier route -> primary llama-server -> Honcho writeback`. Honcho memory is user-scoped by default with `FORTISAI_HONCHO_SESSION_SCOPE=user`; the incoming conversation/session id is still written into Honcho message metadata as `source_conversation_id`, but the active Honcho session is stable per user so memory follows that user across chats. Set `FORTISAI_HONCHO_SESSION_SCOPE=conversation` only when per-chat isolation is required. Firecrawl search is attempted for every chat/completion request; usable web results are injected as live request context with explicit instructions not to claim browsing is unavailable when Firecrawl entries are present, and are queued by default for background upsert into Qdrant for future vector retrieval. Qdrant is used for this facade because it is the fastest fit in this stack for high-volume vector search, while pgvector remains shared relational/vector storage for Dify and Honcho backing data. The primary llama endpoint stays dedicated to this proxy/router path, while Honcho, CodeIndexer, and FortisAI RAG embeddings use the secondary llama endpoint for direct support-tool model and embedding access. Helper startup applies `FORTISAI_OPENAI_ROUTER_DEFAULT_MAX_TOKENS=1536` when clients omit a response cap, clamps explicit OpenAI client caps above `FORTISAI_OPENAI_ROUTER_MAX_TOKENS_HARD_LIMIT=3072`, and uses `FORTISAI_OPENAI_ROUTER_TIMEOUT_SECONDS=1800` for upstream local model requests; set either token cap to `0` only when intentionally allowing uncapped proxy behavior, which can run until the model, client, or bridge timeout stops generation. Retrieval metadata includes stage timings and the web upsert status so Hermes, Cline, and other clients can distinguish retrieval delay from LLM generation delay.

The Dify bridge also exposes `POST /dify_openai_compatible_model_setup` for FortisAI automation. That endpoint requires the Dify database environment (`DIFY_DB_HOST`, `DIFY_DB_PORT`, `DIFY_DB_NAME`, `DIFY_DB_USER`, and `DIFY_DB_PASSWORD`) and uses an existing validated OpenAI-compatible credential as a template to upsert all generated router models. It returns model names and counts only; credential payloads are not returned.

Read-only admin smoke test after `mcp-up`:

```bash
curl -sS -X POST http://127.0.0.1:8093/dify_api_request \
  -H 'Content-Type: application/json' \
  -d '{"method":"GET","path":"/console/api/workspaces/current/model-providers","query":{"model_type":"llm"},"authMode":"admin"}'
```

The response should have `"status": 200` and include the installed OpenAI-compatible provider when the Dify admin key has been loaded correctly from Vault.

Helper-managed MCP startup prepares Vault before launching bridge containers. SQLcl, n8n, Dify, debug, CodeIndexer, Websearch, Daytona, Composio, OpenMetadata, AOL IMAP, and Proxmox bridge containers receive `FORTISAI_VAULT_ADDR`, `VAULT_ADDR`, and the helper-created read-only `VAULT_TOKEN`; helper startup also injects the resolved legacy environment variables each bridge expects at process start. Proxmox values are stored under `secret/fortisai/dev/proxmox/*`. AOL IMAP app passwords are stored under `secret/fortisai/dev/aol/imap/*/password`. CodeIndexer uses Vault-backed FortisAI embedding settings, the secondary llama-server OpenAI-compatible endpoint on Linux, and Milvus connection values.

On macOS, Windows, and Linux, Proxmox uses a two-container local bridge. `fortisai-mcp-openapi-proxmox-upstream` runs the forked ProxmoxMCP-Plus OpenAPI service with its Vault-backed bearer key on internal port `8811`; `fortisai-mcp-openapi-proxmox` exposes the local OpenAPI facade on port `8095`, serves `/openapi.json` for curl/OpenWebUI without requiring the caller to know the key, and injects the upstream bearer key internally. The helper builds the fork into `localhost/fortisai-proxmoxmcp-plus:latest` from `https://github.com/LesterAJohn/ProxmoxMCP-Plus.git` when the image is missing.

Runtime Proxmox cluster selection is available on every proxied read/write endpoint and on the FortisAI local endpoints. Callers can pass `environment` or `proxmox_environment` in a JSON body, `environment` in the query string, or `X-FortisAI-Proxmox-Environment` as a header. The facade normalizes `proxmox_environment` to the fork's upstream `environment` parameter. If no selector is supplied, `default_environment` from `proxmox-config.json` or `PROXMOX_DEFAULT_ENVIRONMENT` is used.

The facade also exposes authenticated update operations for `/update_vm_resources`, `/update_container_resources`, and `/create_vm_disk`; these require the Vault-managed Proxmox update key and return before/after Proxmox config snapshots. Read-only per-guest statistics endpoints support the same runtime environment selector.

## Common Commands

From the repo root or the relevant helper directory:

```bash
./Development_Environment/mac/fortisai-dev-helper.sh mcp-up
./Development_Environment/windows/fortisai-dev-helper.ps1 mcp-up
./Development_Environment/linux/fortisai-dev-helper.sh mcp-up
./Development_Environment/mac/fortisai-dev-helper.sh mcp-down
./Development_Environment/windows/fortisai-dev-helper.ps1 mcp-down
./Development_Environment/linux/fortisai-dev-helper.sh mcp-down

# Direct bridge launchers, when you are already at the repository root:
bash Development_Environment/mcp/start-mcp-openapi-bridges.sh
bash Development_Environment/mcp/stop-mcp-openapi-bridges.sh
```

Bridge health endpoints:

- SQLcl: `http://127.0.0.1:8091/openapi.json`
- n8n: `http://127.0.0.1:8092/openapi.json`
- Dify: `http://127.0.0.1:8093/openapi.json`
- Debug: `http://127.0.0.1:8094/openapi.json`
- Proxmox, when enabled: `http://127.0.0.1:8095/openapi.json`
- CodeIndexer: `http://127.0.0.1:8096/openapi.json`
- Websearch: `http://127.0.0.1:8097/openapi.json`
- Dify bridge info: `http://127.0.0.1:8093/dify_connection_info`
- Dify OpenAI-compatible model setup: `http://127.0.0.1:8093/dify_openai_compatible_model_setup`
- CodeIndexer bridge info: `http://127.0.0.1:8096/codeindexer_connection_info`
- Websearch bridge info: `http://127.0.0.1:8097/websearch_connection_info`
- Websearch search: `http://127.0.0.1:8097/websearch_search`
- Websearch compatibility alias: `http://127.0.0.1:8097/websearch` maps to `websearch_search` when a model emits the shorter tool name.
- Daytona bridge info: `http://127.0.0.1:8098/daytona_connection_info`
- Daytona sandbox command execution: `http://127.0.0.1:8098/daytona_execute_command`
- Composio local proxy info: `http://127.0.0.1:18190/connection_info`
- Composio bridge info: `http://127.0.0.1:8099/composio_connection_info`
- OpenMetadata bridge info: `http://127.0.0.1:8100/openmetadata_connection_info`
- OpenMetadata supported service types: `http://127.0.0.1:8100/openmetadata_supported_service_types`
- AOL IMAP bridge info: `http://127.0.0.1:8101/aol_imap_connection_info`
- AOL IMAP mailbox list: `http://127.0.0.1:8101/aol_imap_list_mailboxes`

## OpenWebUI Integration

The bridge assets in each subdirectory are intended for OpenWebUI import or skill creation.

- Use the `*.import.json` files to register tool servers.
- Use the `*.skill.create.json` files to create OpenWebUI skills.
- Use the `openwebui-dify-mcp-skill.content.md` file for the Dify skill content itself.

### Reload OpenWebUI Tool + Skill

Use these helpers from the repository root or from `Development_Environment/mcp`; payload paths may be absolute, repo-relative, or MCP-directory-relative.

```bash
# Reload a tool-server connection from import JSON
bash Development_Environment/mcp/reload-openwebui-tool-connection.sh \
	Development_Environment/mcp/dify-mcp/openwebui-dify-mcp-tools.import.json

# Reload a skill from create payload (deletes same id first, then recreates)
bash Development_Environment/mcp/create-openwebui-skill.sh \
	Development_Environment/mcp/dify-mcp/openwebui-dify-mcp-skill.create.json

# Reload the CodeIndexer tool-server connection
bash Development_Environment/mcp/reload-openwebui-tool-connection.sh \
	Development_Environment/mcp/codeindexer-mcp/openwebui-codeindexer-mcp-tools.import.json

# Reload the Websearch tool-server connection
OPENWEBUI_CONTAINER=docker_open-webui_1 ./Development_Environment/mcp/reload-openwebui-tool-connection.sh \
  Development_Environment/mcp/websearch-mcp/openwebui-websearch-mcp-tools.import.json

# Reload the Websearch skill
OPENWEBUI_CONTAINER=docker_open-webui_1 ./Development_Environment/mcp/create-openwebui-skill.sh \
  Development_Environment/mcp/websearch-mcp/openwebui-websearch-mcp-skill.create.json

# Reload the CodeIndexer skill
bash Development_Environment/mcp/create-openwebui-skill.sh \
	Development_Environment/mcp/codeindexer-mcp/openwebui-codeindexer-mcp-skill.create.json

# Reload the CodeIndexer GitHub skill
bash Development_Environment/mcp/create-openwebui-skill.sh \
	Development_Environment/mcp/codeindexer-mcp/openwebui-codeindexer-github-mcp-skill.create.json

# Reload the Composio tool-server connection and skill
bash Development_Environment/mcp/reload-openwebui-tool-connection.sh \
	Development_Environment/mcp/composio-mcp/openwebui-composio-mcp-tools.import.json
bash Development_Environment/mcp/create-openwebui-skill.sh \
	Development_Environment/mcp/composio-mcp/openwebui-composio-mcp-skill.create.json

# Reload the OpenMetadata tool-server connection and skills
bash Development_Environment/mcp/reload-openwebui-tool-connection.sh \
	Development_Environment/mcp/openmetadata-mcp/openwebui-openmetadata-mcp-tools.import.json
bash Development_Environment/mcp/create-openwebui-skill.sh \
	Development_Environment/mcp/openmetadata-mcp/openwebui-openmetadata-catalog-skill.create.json
bash Development_Environment/mcp/create-openwebui-skill.sh \
	Development_Environment/mcp/openmetadata-mcp/openwebui-openmetadata-source-onboarding-skill.create.json
```

Notes:

- `create-openwebui-skill.sh` uses `OPENWEBUI_BEARER_TOKEN` when present, or `OPENWEBUI_API_KEY` as an alias.
- If token env vars are unset, it reads the user-scoped Vault key for `OPENWEBUI_API_USER`/`FORTISAI_OPENWEBUI_DEFAULT_API_KEY_USER` at `secret/fortisai/dev/openwebui/users/<normalized-user>/api_key`.
- Use `./Development_Environment/linux/fortisai-dev-helper.sh openwebui-api <user email> <api key>` to store or rotate an OpenWebUI API key under the per-user Vault path.
- The Dify/FortisAI OpenAI-compatible bridge discovers callable tools by fetching OpenWebUI skills with the current request user's API key, then matching skill text to imported OpenAPI tool servers. This avoids maintaining a separate static tool registry.
- If token env vars and the user-scoped Vault key are unset, skill creation attempts fallback to the newest key in `fortisai-openwebui:/app/backend/data/webui.db` table `api_key` and stores it under the configured user path.
- `reload-openwebui-tool-connection.sh` updates OpenWebUI config directly via the running `fortisai-openwebui` container and verifies the named connection after writing it.
- `OPENWEBUI_VALIDATE_TOOL_URL=false` skips the reload helper's best-effort OpenAPI URL fetch from inside the OpenWebUI container.

## Notes

- Dify API keys are synced through Vault by helper startup; `dify-api-key.json` is a generated local compatibility cache for bridge startup and should stay uncommitted.
- `Development_Environment/mcp/start-mcp-openapi-bridges.sh` manages the bridge containers directly.
- Keep bridge auth values out of docs, logs, and screenshots.
