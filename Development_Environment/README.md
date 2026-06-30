# Development Environment

This folder contains OS-specific local development setup and operator workflows for FortisAI application services.

## Platforms

- [mac/README.md](mac/README.md)
  Mac local environment setup for Dify, Honcho, OpenClaw, Hermes, Firecrawl, MongoDB, Redis, RabbitMQ, HashiCorp Vault, pgvector, Qdrant, n8n, OpenWebUI, OpenVSCode Server, Oracle AI Database Free, LM Studio, Traefik, CodeIndexer, Milvus, OpenMetadata, and OpenSearch.

- [windows/README.md](windows/README.md)
  Windows local environment setup for Dify, Honcho, OpenClaw, Hermes, Firecrawl, MongoDB, Redis, RabbitMQ, HashiCorp Vault, pgvector, Qdrant, n8n, OpenWebUI, OpenVSCode Server, Oracle AI Database Free, LM Studio, Traefik, CodeIndexer, Milvus, OpenMetadata, and OpenSearch.

- [linux/README.md](linux/README.md)
  Linux local environment setup for Dify, Honcho, OpenClaw, Hermes, Firecrawl, MongoDB, Redis, RabbitMQ, HashiCorp Vault, pgvector, Qdrant, n8n, OpenWebUI, OpenVSCode Server, Oracle AI Database Free, LM Studio, Traefik, CodeIndexer, Milvus, OpenMetadata, and OpenSearch.

## Repository Layout

- `mac/` - macOS helper and operating guides.
- `windows/` - Windows PowerShell helper and operating guides.
- `linux/` - Linux helper and systemd-oriented operating guides.
- `mcp/` - MCP and OpenAPI bridge assets for SQLcl, n8n, Dify, CodeIndexer, Websearch, Daytona, Composio, OpenMetadata, debug, and optional Proxmox integrations.
- `linux/active_host.json` - active FortisAI host inventory with connectivity metadata, Podman SSH connection names, required containers, and no stored host passwords.
- `llm_directory/` - default GGUF model directory for the Linux llama router helper commands.
- `oracle-node-api/` - local Node.js REST/WebSocket API for SQLcl-backed Oracle tooling.
- `aiagents/` - OpenWebUI tool and skill creation scripts for Hermes and OpenClaw.
- `templates/` - starter Dify app and n8n workflow export templates.
- `training_materials/` - reference training material for local development workflows.

Primary lifecycle commands should be run from the platform helper directories. MCP bridge launchers live under `Development_Environment/mcp/`; any root-level copies are legacy compatibility artifacts and are not the preferred operator path.

Generated local runtime files are intentionally not part of the portable documentation/source state. Examples include `.DS_Store`, `__pycache__/`, `.env` files, `~/fortisai-dev/vault/vault-init.json`, and generated bridge caches such as `Development_Environment/mcp/dify-mcp/dify-api-key.json`.

## Quick Start

1. Choose your platform guide (`mac`, `windows`, or `linux`).
2. Run the platform helper script for setup and lifecycle.
3. Start the Oracle AI Database Free container if you want a shared general/vector database for local app wiring.
4. Use the packaged ORDS endpoint and SQLcl sidecar for local database API and admin workflows.
5. Use Qdrant as the default local vector store for Dify and as a shared vector endpoint for n8n workflows.
6. Use MongoDB, Redis, RabbitMQ, HashiCorp Vault, and pgvector as shared local data services for workflow and app integrations, including Honcho memory services.
7. Use Appsmith as a default low-code UI builder connected to the same local network and wired to MongoDB + Redis.
8. Use OpenClaw as a local gateway wired to Honcho memory and the FortisAI proxy model endpoint.
9. Use Firecrawl as a local crawl/scrape API service available on the shared network.
10. Optionally run the APEX helper workflow to install Oracle APEX for local browser-based development.
11. Install and launch LM Studio with the helper command set.
12. Follow the Git import/export guide for Dify YAML and n8n JSON config repos.
13. On macOS, Windows, and Linux, use `codeindexer-up`, `openmetadata-up`, and `traefik-up` for the standalone operator components, or `all-up` to run the full Linux-parity sequence: CodeIndexer, OpenMetadata, MCP OpenAPI bridges, OpenClaw, Hermes, Daytona, and Traefik. On Apple Silicon, use a 24 GB Podman VM allocation for the full `all-up` stack when host RAM permits.
14. Configure bastion-linked production access if needed.
15. For MCP bridge bootstrap and validation, run:
  - macOS: `./mac/fortisai-dev-helper.sh mcp-up`
  - Windows: `.\windows\fortisai-dev-helper.ps1 mcp-up`
  - Linux: `./linux/fortisai-dev-helper.sh mcp-up`
16. To stop MCP bridge containers, run:
  - macOS: `./mac/fortisai-dev-helper.sh mcp-down`
  - Windows: `.\windows\fortisai-dev-helper.ps1 mcp-down`
  - Linux: `./linux/fortisai-dev-helper.sh mcp-down`

## Linux Multi-Host CoreDNS

Linux hosts listed in `linux/active_host.json` can be prepared with `./linux/fortisai-dev-helper.sh calico-up` or `linux/deploy-calico-network.sh`. The deployment creates a rootless Podman network named `fortisai-calico-net` on each host, starts `fortisai-coredns`, installs the Podman DNS registration watcher, and keeps shared records refreshed from the primary host with `fortisai-calico-sync-dns.timer`.

Rootless Podman bridge subnets remain host-local. Same-host service names resolve to local container IPs. Cross-host names resolve through CoreDNS to the owning host's LAN IP when that service publishes a LAN-reachable host port. For example, containers on `aiengine001` can use `http://fortisai-llama-server.fortisai.local:8011/v1` to reach the primary llama endpoint on `aiengine000`.

## Qdrant (Local)

Qdrant is part of the default helper `up` and `down` lifecycle on macOS, Windows, and Linux.

- Default URL: `http://127.0.0.1:6333`
- Default gRPC port: `6334`
- Logs target: `qdrant`
- Default API key: `difyai123456`
- Dify wiring: enabled as the default `VECTOR_STORE=qdrant`
- n8n wiring: generated compose exposes `QDRANT_URL`, `QDRANT_API_KEY`, and `FORTISAI_QDRANT_URL`

## Redis and pgvector (Local)

Redis and pgvector are part of the default helper `up` and `down` lifecycle on macOS, Windows, and Linux.

- Redis URL: `redis://127.0.0.1:6379`
- Redis logs target: `redis`
- pgvector SQL endpoint: `127.0.0.1:5432`
- pgvector default DSN: `postgresql://fortisai:fortisai@127.0.0.1:5432/fortisai`
- pgvector logs target: `pgvector`
- Shared-service model: Dify, n8n, OpenWebUI, and Appsmith expose shared connection variables for Redis/pgvector.
- Dify runtime model: helper startup uses Dify with the `qdrant` profile while database and cache connectivity are pointed at shared `fortisai-pgvector` and `fortisai-redis` services.

## Local Llama Endpoint Wiring

Helper-generated Dify and n8n runtimes expose the same OpenAI-compatible model endpoint variables:

- `FORTISAI_LLAMA_SERVER_URL`
- `FORTISAI_LLAMA_SERVER_BASE_URL`
- `FORTISAI_LLAMA_OPENAI_BASE_URL`
- `FORTISAI_LLAMA_OPENAI_API_KEY`

Linux defaults to two helper-managed llama endpoints plus the FortisAI proxy facade. The primary endpoint, `http://fortisai-llama-server.fortisai.local:8011/v1`, is reserved for the FortisAI OpenAI-compatible proxy and Dify router path and remains stable when the llama service moves between active hosts. The FortisAI proxy facade is `http://fortisai-mcp-openapi-dify.fortisai.local:8093/v1` inside the shared network and exposes model `fortisai`. Hermes and OpenClaw use that proxy endpoint on all platforms. The secondary endpoint, `http://fortisai-llama-server-secondary.fortisai.local:8012/v1`, is used by support tools that need direct LLM or embedding access, including Honcho and CodeIndexer. Host-side checks use `http://127.0.0.1:8011/v1`, `http://127.0.0.1:8012/v1`, and `http://127.0.0.1:8093/v1`. The proxy applies a default 1536-token output cap when clients omit `max_tokens`/`max_output_tokens`, routes public `fortisai` embedding requests through the generated monthly `embeddings` request type unless `FORTISAI_OPENAI_EMBEDDING_MODEL` is intentionally set, queues Firecrawl-to-Qdrant web-result upserts off the foreground chat path, mediates direct Dify/OpenAI chat tool calls through registered OpenAPI bridge endpoints, and returns stage timing metadata for diagnosis. macOS and Windows helper-generated Dify/n8n runtimes default to `http://host.docker.internal:8011/v1`, which can be overridden before running helper setup/up if a different host-side llama-compatible server is used.

The Linux llama routers mount `LLAMA_MODELS_DIR` directly; on `aiengine000` this resolves to `/db/AI/llm_directory`. Because llama-server only scans top-level GGUF files or one-level model folders from `--models-dir`, the helper generates `~/fortisai-dev/llama-router/models.ini` with direct paths to every runnable nested GGUF and starts both routers with `--models-preset`. Primary and secondary llama routers default to `--models-max 2` and `--parallel 8`, giving each loaded model up to eight active slots while allowing each router to keep two models resident. The retired `~/fortisai-dev/llama-router/model-catalog` symlink directory is not used by primary or secondary startup.

On Linux, `linux/systemd_services/model_update.py run-once` runs the monthly Hugging Face GGUF discovery/download pass immediately. Downloads use one Hugging Face worker by default, skip support/high-precision artifacts (`mmproj`, `BF16`, `FP16`) unless `HF_DOWNLOAD_EXCLUDE_GLOBS` is overridden, and time out a stuck provider download after 900 seconds unless `HF_DOWNLOAD_TIMEOUT_SECONDS` is overridden. `linux/systemd_services/test_llama_models.py` refreshes the llama router before validation, validates every router-advertised model from the direct `LLAMA_MODELS_DIR`, gives slow first loads a retry window, applies a hard wall-clock request timeout, renames unloadable or non-runnable support/high-precision assets from `.gguf` to `.gguf.disable...`, and records the quarantine in `llm_directory/disabled_models.json`. It also excludes unsupported Bitnet `ggml-model-i2_s` files for the current llama.cpp runtime. Use `LLAMA_START_AT_MODEL=<model-id>` to resume a manual validation pass after a known-good prefix. The llama router is restarted after validation so n8n/Dify classification only sees loadable local models.

## Traefik, CodeIndexer, and OpenMetadata

The macOS, Windows, and Linux helpers include the additional operator components below.

- Traefik: `traefik-up`, `traefik-down`, and `traefik-check`; web entrypoint `http://127.0.0.1:18000`, dashboard `http://127.0.0.1:18088/dashboard/`.
- CodeIndexer: `codeindexer-up`, `codeindexer-down`, and `codeindexer-check`; Milvus-backed semantic code indexing using the secondary llama-server OpenAI-compatible embeddings on Linux, with OpenAPI bridge `http://127.0.0.1:8096/openapi.json` and GitHub clone/pull/index/search skill support through `mcp-up`.
- OpenMetadata: `openmetadata-up`, `openmetadata-down`, and `openmetadata-check`; reuses shared pgvector for Postgres and adds OpenSearch for search. The OpenMetadata MCP bridge adds OpenWebUI catalog, source onboarding, and ingestion runner skills on port `8100`.
- Full lifecycle: `all-up` includes CodeIndexer, OpenMetadata, MCP OpenAPI bridges, OpenClaw, Hermes, Daytona, and Traefik; `all-down` stops them in reverse order.
- Repeat local startup is idempotent for n8n, Milvus, and OpenSearch; helpers reuse healthy containers and remove stale stopped containers before compose startup.
- OpenWebUI MCP tool wiring is nonfatal before first-run OpenWebUI initialization creates the config row; rerun platform `mcp-up` after first login to populate `tool_server.connections`.

Vault-backed values for these services live under `secret/fortisai/dev/traefik/*`, `secret/fortisai/dev/codeindexer/*`, `secret/fortisai/dev/milvus/*`, and `secret/fortisai/dev/openmetadata/*`. The Composio MCP bridge uses the local `fortisai-composio-local` proxy and reads `secret/fortisai/dev/composio/*` for API key or upstream session MCP configuration. TradeEngine OpenMetadata source credentials are stored in Vault under normalized TradeEngine and OpenMetadata source paths, not in the repository.

## HashiCorp Vault (Local)

HashiCorp Vault is part of the default helper `up` and `down` lifecycle on all platforms.

- Vault URL: `http://127.0.0.1:8200`
- Vault image: `docker.io/hashicorp/vault:latest`
- Vault logs target: `vault`
- Storage model: persistent local file storage under `~/fortisai-dev/vault/file`
- Config path: `~/fortisai-dev/vault/config/vault.hcl`
- Init credentials path: `~/fortisai-dev/vault/vault-init.json`
- Host exposure: bound to `127.0.0.1:8200`; other containers use `http://fortisai-vault.fortisai.local:8200` on the selected shared network. macOS and Windows default to `fortisai-dev-net`; Linux uses `fortisai-calico-net` when the Calico/CoreDNS deployment is present and otherwise falls back to `fortisai-dev-net`.
- Health status before initialization: Vault returns HTTP `501` while reachable but uninitialized; after initialization it returns HTTP `503` while sealed.
- Helper `up` starts Vault and runs the saved-key unseal step before the rest of the stack, so dependent services can read from Vault during startup.
- First-time init:
  - macOS: `./mac/fortisai-dev-helper.sh vault-init`
  - Windows: `.\windows\fortisai-dev-helper.ps1 vault-init`
  - Linux: `./linux/fortisai-dev-helper.sh vault-init`
- After restarts, unseal with:
  - macOS: `./mac/fortisai-dev-helper.sh vault-unseal`
  - Windows: `.\windows\fortisai-dev-helper.ps1 vault-unseal`
  - Linux: `./linux/fortisai-dev-helper.sh vault-unseal`
- Read or write helper-managed local secrets with paths relative to `secret/fortisai/dev/`:
  - macOS: `./mac/fortisai-dev-helper.sh vault-read <path>`, `./mac/fortisai-dev-helper.sh vault-write <path> <value>`, and `./mac/fortisai-dev-helper.sh vault-del <path>`
  - Windows: `.\windows\fortisai-dev-helper.ps1 vault-read <path>`, `.\windows\fortisai-dev-helper.ps1 vault-write <path> <value>`, and `.\windows\fortisai-dev-helper.ps1 vault-del <path>`
  - Linux: `./linux/fortisai-dev-helper.sh vault-read <path>`, `./linux/fortisai-dev-helper.sh vault-write <path> <value>`, and `./linux/fortisai-dev-helper.sh vault-del <path>`
- Runtime secret sync:
  - `up`, `openclaw-up`, and `hermes-up` start Vault, run the saved-key unseal step, sync helper-managed runtime secrets, and verify required Vault paths before declaring Vault-backed runtime secrets ready.
  - Exported environment values seed or rotate Vault. If an environment value is not provided, the helper reads the existing Vault value. If neither exists, the helper stores the local development default.
  - Generated component compose/config files receive `VAULT_ADDR`, `FORTISAI_VAULT_ADDR`, and a helper-created read-only `VAULT_TOKEN` for `secret/fortisai/dev/*`.
  - Helper-managed values are stored under `secret/fortisai/dev/` paths for n8n, Oracle/ORDS/APEX, RabbitMQ, pgvector, Qdrant, OpenVSCode, Appsmith, Honcho, `claw-gateway`, Hermes, Firecrawl, Dify, and the local Vault service token.
  - Dify's `Development_Environment/mcp/dify-mcp/dify-api-key.json` is generated as a local compatibility cache for MCP/bridge startup when needed; Vault is the startup source of truth after sync, and the generated cache should not be committed.

Security note: `vault-init.json` contains the local root token and unseal key. Keep it out of Git and do not reuse it outside local development.

## MongoDB (Local)

MongoDB is part of the default helper `up` and `down` lifecycle on all platforms.

- MongoDB URL: `mongodb://127.0.0.1:27017/appsmith?replicaSet=rs0`
- MongoDB logs target: `mongodb`
- Appsmith DB wiring: helper config sets `APPSMITH_DB_URL` and `APPSMITH_MONGODB_URI` to the shared `fortisai-mongodb` service.
- Replica set: helper startup ensures replica set initialization (`rs0`) before Appsmith starts.

## Honcho (Local)

Honcho is part of the default helper `up` and `down` lifecycle on macOS, Windows, and Linux.

- Honcho URL: `http://127.0.0.1:8010`
- Honcho logs target: `honcho`
- Honcho runtime services: `api` and `deriver`
- Shared-service model: Honcho uses shared `fortisai-pgvector` and `fortisai-redis` on the platform selected shared network.
- Dedicated Honcho database: helper-managed `honcho` database on shared pgvector (`HONCHO_DB=honcho` by default).
- LLM provider requirement: Honcho requires at least one configured provider key (helper default `HONCHO_LLM_OPENAI_API_KEY=lmstudio`; override for real usage).
- Linux LLM wiring: helper-generated Honcho feature `MODEL_CONFIG__OVERRIDES__BASE_URL` values point directly to the secondary llama-server endpoint `http://fortisai-llama-server-secondary.fortisai.local:8012/v1` by default. LM Studio remains available by overriding those values to `http://host.docker.internal:1234/v1` for containers or `http://localhost:1234/v1` for host-native runtime.
- FortisAI proxy memory flow: the Linux Dify OpenAPI bridge requires Honcho memory for chat/completion/responses by default, looks up context before routing, and writes the user/assistant exchange back to Honcho after the selected local model responds. This path was validated on `aiengine000` with a unique marker present in both Honcho `messages/list` and session `context`.

## OpenClaw (Local)

OpenClaw is managed with dedicated helper commands on all platforms (`openclaw-up` and `openclaw-down`). It is not started/stopped by the default `up` and `down` flow.

- OpenClaw URL: `http://127.0.0.1:18789`
- OpenClaw logs target: `openclaw`
- OpenClaw shell command: `openclaw-shell`
- OpenWebUI shell command: `openwebui-shell`
- OpenClaw host ports: `18789` (gateway) and `18790` (bridge)
- `openclaw-up` prepares the OpenClaw runtime only, starts Vault, and runs the saved-key unseal step before launching OpenClaw.
- `openclaw-down` stops OpenClaw only; Vault remains available as a shared local service.
- OpenWebUI override path: set `OPENWEBUI_LLM_BACKEND=openclaw` to point OpenWebUI to `http://fortisai-claw-gateway.fortisai.local:18789/v1`.
- Honcho integration: helper-generated OpenClaw config enables the `@honcho-ai/openclaw-honcho` plugin and points to local Honcho API by default.
- LLM integration: helper-generated OpenClaw config creates an OpenAI-compatible provider that points to the FortisAI proxy at `http://fortisai-mcp-openapi-dify.fortisai.local:8093/v1` and model `fortisai` by default. Override `OPENCLAW_LMSTUDIO_BASE_URL` to use LM Studio or another provider.
- Conflict protection: helper setup validates OpenClaw ports do not overlap known default service ports.

## Hermes Agent (Local)

Hermes is managed with dedicated helper commands on macOS, Windows, and Linux (`hermes-up` and `hermes-down`). It is not started/stopped by the default `up` and `down` flow.

- Hermes URL: `http://127.0.0.1:8642`
- Hermes health endpoint: `http://127.0.0.1:8642/health`
- Hermes dashboard port: `9119` (enabled when `HERMES_DASHBOARD=1`)
- Hermes logs target: `hermes`
- Hermes shell command: `hermes-shell`
- OpenWebUI default wiring: helper-generated OpenWebUI compose points `OPENAI_API_BASE_URL` to `http://fortisai-hermes.fortisai.local:8642/v1` when `OPENWEBUI_LLM_BACKEND` is not set.
- Hermes LLM wiring: helper-generated Hermes compose points the custom provider at the FortisAI proxy `http://fortisai-mcp-openapi-dify.fortisai.local:8093/v1`, model `fortisai`, and exports current `OPENAI_API_KEY`, `OPENAI_BASE_URL`, and `OPENAI_API_BASE_URL` values for Hermes fallback/client-rebuild paths.
- Runtime image: `nousresearch/hermes-agent:latest`
- Runtime command: `gateway run`
- Data mount: `~/fortisai-dev/hermes-agent:/opt/data`
- WhatsApp gateway: disabled by default with `HERMES_WHATSAPP_ENABLED=false`; helper startup also rewrites Hermes persisted `.env` to `WHATSAPP_ENABLED=false`, so an old paired session is ignored unless explicitly re-enabled.
- Stream watchdog: Linux defaults `HERMES_STREAM_STALE_TIMEOUT=900` so slow local FortisAI routing/model-prefill paths do not trigger false stale-stream reconnect loops.
- Runtime cleanup: helper startup removes stale persisted Hermes `.env` LLM/OpenRouter keys before writing the current runtime config.
- Honcho context wiring: helper injects `FORTISAI_HONCHO_BASE_URL`, `FORTISAI_HONCHO_WORKSPACE_ID`, and optional `FORTISAI_HONCHO_API_KEY` into Hermes runtime env.
- Daytona context wiring: helper injects `FORTISAI_DAYTONA_DASHBOARD_URL` and `FORTISAI_DAYTONA_API_URL` into Hermes runtime env.
- Conflict protection: helper setup validates Hermes ports do not overlap known default service ports.

## Firecrawl (Local)

Firecrawl is part of the default helper `up` and `down` lifecycle on macOS, Windows, and Linux.

- Firecrawl URL: `http://127.0.0.1:3002`
- Logs target: `firecrawl`
- Default image: `ghcr.io/firecrawl/firecrawl:latest`
- Default API key env: `FIRECRAWL_API_KEY` (default `fortisai-firecrawl-dev-api-key`)
- Shared wiring: Firecrawl uses shared `fortisai-pgvector`, `fortisai-rabbitmq`, and `fortisai-redis` services on the platform selected shared network.
- DB bootstrap: helper startup auto-creates Firecrawl DB (`FIRECRAWL_DB_NAME`, default `firecrawl`) on shared pgvector.
- NUQ bootstrap: helper startup applies upstream NUQ schema (`apps/nuq-postgres/nuq.sql`) before Firecrawl launch.
- Redis wiring envs: `FIRECRAWL_REDIS_URL`, `FIRECRAWL_REDIS_EVICT_URL`, `FIRECRAWL_REDIS_RATE_LIMIT_URL`.
- NUQ schema source override: `FIRECRAWL_NUQ_SQL_URL`.
- OpenClaw integration envs: `FIRECRAWL_BASE_URL`, `FIRECRAWL_API_KEY`
- Hermes integration envs: `FORTISAI_FIRECRAWL_BASE_URL`, `FORTISAI_FIRECRAWL_API_KEY`

## OpenVSCode Server (Local)

OpenVSCode Server is part of the default helper `up` and `down` lifecycle on macOS, Windows, and Linux.

- OpenVSCode URL: `http://localhost:13000`
- Logs target: `openvscode`
- Shell command:
  - macOS: `./mac/fortisai-dev-helper.sh openvscode-shell`
  - Windows: `.\windows\fortisai-dev-helper.ps1 openvscode-shell`
  - Linux: `./linux/fortisai-dev-helper.sh openvscode-shell`
- Default container/image:
  - container: `fortisai-openvscode`
  - image: `gitpod/openvscode-server:latest`
- Default auth variable: `OPENVSCODE_CONNECTION_TOKEN` (local dev default is set by helper; override it in your environment for stronger local security)
- Workspace mount overrides:
  - `OPENVSCODE_WORKSPACE_DIR` (default: host home directory)
  - `OPENVSCODE_WORKSPACE_MOUNT_PATH` (default: `/workspace`)

macOS, Windows, and Linux support helper-managed OpenVSCode user instances. OpenVSCode itself is single-user per server process, so each helper maps every configured user to a separate container, port, token file, user-data volume, and extension volume. The first/default user keeps `fortisai-openvscode` on port `13000` so watchdog checks and existing URLs remain stable.

- Configure users with `OPENVSCODE_USERS`, using comma or space separated entries in the form `user[:port[:token[:workspace]]]`.
- macOS example: `OPENVSCODE_USERS="lester:13000 alice:13001" ./mac/fortisai-dev-helper.sh openvscode-up`
- Windows example: `$env:OPENVSCODE_USERS="lester:13000 alice:13001"; .\windows\fortisai-dev-helper.ps1 openvscode-up`
- Linux example: `OPENVSCODE_USERS="aiuser:13000 alice:13001" ./linux/fortisai-dev-helper.sh openvscode-up`
- List configured users with `openvscode-users`.
- Extension commands: `openvscode-list-extensions [user]`, `openvscode-install-extension [user] <extension-id-or-vsix>`, and `openvscode-uninstall-extension [user] <extension-id>`.
- Host VSIX paths are copied into the selected OpenVSCode container before installation.
- Token files live under `~/fortisai-dev/openvscode/users/<user>/connection-token`; unauthenticated browser requests return `403`.

## n8n Workflow Import

The platform helpers include `n8n-import-workflows` to run the repository importer at `Development_Environment/n8n-config/import-n8n-workflows.sh`. The command starts and unseals Vault, ensures n8n is running, then imports or updates the checked-in workflows without manual API calls.

### OpenWebUI Custom Tool Example

Use this OpenWebUI custom tool to send prompts to Hermes from inside the OpenWebUI tool runner. It follows the standard OpenWebUI Python tool layout with a `Tools` class and configurable valves.

```python
"""
title: Hermes Chat Tool
author: FortisAI
version: 1.0.0
description: Query the Hermes Agent gateway from OpenWebUI.
"""

from pydantic import BaseModel, Field
import requests


class Tools:
  class Valves(BaseModel):
    hermes_base_url: str = Field(
      default="http://fortisai-hermes.fortisai.local:8642/v1",
      description="Hermes OpenAI-compatible base URL",
    )
    hermes_api_key: str = Field(
      default="fortisai-hermes-dev-api-key",
      description="Hermes API server key",
    )
    hermes_model: str = Field(
      default="default",
      description="Hermes model name exposed by the gateway",
    )

  def __init__(self):
    self.valves = self.Valves()

  def ask_hermes(self, prompt: str) -> str:
    """Send a prompt to Hermes and return the assistant response."""
    headers = {
      "Authorization": f"Bearer {self.valves.hermes_api_key}",
      "Content-Type": "application/json",
    }
    payload = {
      "model": self.valves.hermes_model,
      "messages": [{"role": "user", "content": prompt}],
      "temperature": 0.2,
    }

    response = requests.post(
      f"{self.valves.hermes_base_url}/chat/completions",
      headers=headers,
      json=payload,
      timeout=60,
    )
    response.raise_for_status()
    data = response.json()
    return data["choices"][0]["message"]["content"]
```

Recommended values for this workspace:

- `hermes_base_url`: `http://fortisai-hermes.fortisai.local:8642/v1`
- `hermes_api_key`: `fortisai-hermes-dev-api-key`
- `hermes_model`: the model identifier exposed by your Hermes gateway

## Operational Notes (Managed macOS Hosts)

- On some endpoint-managed macOS hosts, endpoint-security controls may terminate OpenClaw-related process launches with `Killed: 9` based on command/path matching.
- When this occurs, default `up` cannot complete full OpenClaw bring-up even though other services can run normally.
- Podman compose may intermittently return `no container with name or ID ... found` during `up`/`down` for individual projects (observed with OpenWebUI and some Dify operations); rerun from a clean state and validate with `status`.
- The full macOS `all-up` stack is memory-heavy. A 12 GB Podman VM can wedge the Podman API when Oracle, Dify, OpenMetadata/OpenSearch, Milvus, and MCP bridges are all active; use 24 GB where possible.
- Shared network bootstrap is idempotent on all helpers; existing `fortisai-dev-net` no longer causes macOS/Windows startup failure, and Linux automatically selects `fortisai-calico-net` when the Calico/CoreDNS deployment is present.

## Agent Framework Wiring

- [development_env_agentframework.md](development_env_agentframework.md)
  Documents Honcho integration and all local components wired around shared data services and agent workflows.

## OpenWebUI AI Agent Helpers

- [aiagents/README.md](aiagents/README.md)
  Includes guided and direct scripts for creating OpenWebUI custom tools for Hermes and OpenClaw.
- Preferred helper command:
  `bash Development_Environment/aiagents/openwebui-onboard-and-create-tools.sh`

## MCP Bridge Helper

macOS, Windows, and Linux helpers include `mcp-up` to automate MCP bridge bring-up and validation. The active bridge scripts and component assets live under `Development_Environment/mcp/`.

- macOS: `./mac/fortisai-dev-helper.sh mcp-up`
- Windows: `.\windows\fortisai-dev-helper.ps1 mcp-up`
- Linux: `./linux/fortisai-dev-helper.sh mcp-up`
- macOS: `./mac/fortisai-dev-helper.sh mcp-down`
- Windows: `.\windows\fortisai-dev-helper.ps1 mcp-down`
- Linux: `./linux/fortisai-dev-helper.sh mcp-down`

`mcp-up` performs the following:

1. Starts MCP OpenAPI bridge containers for SQLcl, n8n, Dify, CodeIndexer, and debug.
2. Starts the optional Proxmox OpenAPI bridge when Proxmox config or enabling environment variables are present. The Proxmox facade includes authenticated VM resource, VM disk creation, and LXC resource update endpoints guarded by the Vault-managed update key.
3. Resolves `N8N_API_KEY` from environment or SQLcl MCP config when available.
4. Validates OpenAPI endpoints are responsive.
5. Runs debug, SQL, n8n, Dify, CodeIndexer, and optional Proxmox `/livez` smoke checks where the backing services are available.
6. Validates Dify API container reachability to bridge endpoints, including CodeIndexer and optional Proxmox, when Dify API container is running.
7. Auto-resolves Dify console admin routing context (`ADMIN_API_KEY` and `X-WORKSPACE-ID`) from running Dify/pgvector services when not explicitly set.

`mcp-down` performs the following:

1. Stops and removes `fortisai-mcp-openapi-sqlcl`.
2. Stops and removes `fortisai-mcp-openapi-n8n`.
3. Stops and removes `fortisai-mcp-openapi-dify`.
4. Stops and removes `fortisai-mcp-openapi-debug`.
5. Stops and removes `fortisai-mcp-openapi-codeindexer` when present.
6. Stops and removes `fortisai-mcp-openapi-proxmox` and `fortisai-mcp-openapi-proxmox-upstream` when present.

## OpenWebUI MCP Wiring (OpenAPI)

OpenWebUI OpenAPI tool templates now include MCP bridge endpoints for SQLcl, n8n, Dify, CodeIndexer, debug, and optional Proxmox in addition to the default filesystem/memory/time servers.

- Generated/env-driven URLs include:
  - `OPENAPI_MCP_SQLCL_URL`
  - `OPENAPI_MCP_N8N_URL`
  - `OPENAPI_MCP_DIFY_URL`
  - `OPENAPI_MCP_CODEINDEXER_URL`
  - `OPENAPI_MCP_DEBUG_URL`
  - `OPENAPI_MCP_PROXMOX_URL` when Proxmox is enabled
- Generated JSON/import payloads include:
  - `mcp-sqlcl-server`
  - `mcp-n8n-server`
  - `mcp-dify-server`
  - `mcp-codeindexer-server`
  - debug bridge payloads used for smoke validation
  - `mcp-proxmox-server` when the optional Proxmox bridge is configured

Generate or refresh templates via helper `setup` on your platform, and ensure bridges are running with platform `mcp-up` before importing into OpenWebUI.

## Canonical URL Index

- [development_env_url.md](development_env_url.md)
  Single source of truth for local service URLs, helper commands, and optional APEX/Daytona endpoints.
  Includes the authoritative default credentials/password matrix for all local components.

## Appsmith (Local)

Appsmith is part of the default helper `up` and `down` lifecycle on macOS, Windows, and Linux.

- Default URL: `http://localhost:18080`
- Logs target: `appsmith`
- Default image: `appsmith/appsmith-ce:latest`
- Shared network: `fortisai-dev-net` on macOS/Windows; `fortisai-calico-net` on Linux when the Calico/CoreDNS deployment is present
- Default DB backend in helper runtime: MongoDB (`fortisai-mongodb`)

## Oracle Node API Container

A local Node.js API container is available at:

- `oracle-node-api/`

It exposes these endpoints:

- `POST /exec`
- `POST /script`
- `POST /ddl`
- `POST /format`
- `POST /mcp` (returns 426; use websocket)
- `WS /mcp`
- `GET /health`
- `GET /version`

Start it:

```bash
./mac/fortisai-dev-helper.sh up
# or
.\windows\fortisai-dev-helper.ps1 up
```

Direct compose run is also supported:

```bash
cd Development_Environment/oracle-node-api
podman compose up -d --build
```

Base URL: `http://127.0.0.1:8090`

### Runtime Requirements (SQLcl Stdio, Option 3)

`/exec`, `/script`, `/ddl`, and `/format` execute through the SQLcl sidecar using container stdio (`podman exec -i fortisai-sqlcl ...`).

Required conditions:

- SQLcl sidecar container is running and reachable as `fortisai-sqlcl`.
- Oracle Node API container has Podman CLI available.
- Podman socket is mounted into Oracle Node API (`/tmp/podman.sock`) and `CONTAINER_HOST` is set.
- Option 3 runtime policy is enabled in compose for local operation (`privileged: true` and `security_opt: label=disable`).

Validate communication:

```bash
curl -s http://127.0.0.1:8090/health
curl -s -X POST http://127.0.0.1:8090/exec -H "Content-Type: application/json" -d '{"statement":"select 1 from dual"}'
```

For implementation details and full endpoint examples, see `oracle-node-api/README.md`.

## Optional Self-Hosted Daytona (Container Stack)

Daytona OSS is supported as an optional self-hosted container stack in local development.

- It is not part of the default `up` / `down` flow for Dify, n8n, and OpenWebUI.
- Daytona can be used as the preferred isolated code-execution substrate for generated code, instead of auto-running shell commands in the FortisAI host or OpenWebUI container. Wire agents to Daytona-created workspaces with scoped API keys, resource limits, and no host secret mounts.
- It uses remapped host ports by default to avoid conflicts with existing services.
- `daytona-up` now prefers Docker Compose for runner stability; it only falls back to Podman compose when Docker Compose is unavailable.
- Linux NVIDIA GPU hosts are auto-enabled by `DAYTONA_GPU_MODE=auto`: the helper generates a Daytona NVIDIA payload, a CDI spec, sets runner `GPU_ENABLED=true`, and uses `daytonaio/sandbox-gpu:latest` as the default Daytona snapshot.
- On Linux, `daytona-setup` and `daytona-up` apply the FortisAI Daytona GPU type patch so older NVIDIA cards reported by `nvidia-smi`, including `NVIDIA GeForce GTX 1070`, are recorded as `GTX-1070` instead of producing repeated unrecognized GPU warnings from the Daytona API.
- macOS Apple Silicon hosts report the local Metal GPU, but Daytona Linux containers remain CPU-only because Docker/Podman on macOS do not expose Metal/MPS devices to Linux containers.
- Validate platform GPU status with `daytona-gpu-check` after `daytona-up`.
- Dashboard URL: `http://localhost:3300` — default login: **Email** `dev@daytona.io` / **Password** `password` (Dex static user).
- To change credentials use: `daytona-set-admin-creds <email> <password>` then restart the stack (`daytona-down` + `daytona-up`).
- Use platform helper commands:
  - macOS: `./mac/fortisai-dev-helper.sh daytona-setup|daytona-up|daytona-check|daytona-down`
  - Windows: `.\windows\fortisai-dev-helper.ps1 daytona-setup|daytona-up|daytona-check|daytona-down`
  - Linux: `./linux/fortisai-dev-helper.sh daytona-setup|daytona-up|daytona-check|daytona-down`

## Oracle AI Database Free (Local)

The helper scripts generate a local Oracle AI Database Free container from `container-registry.oracle.com/database/free:latest` and attach it to the selected shared network used by Dify, n8n, OpenWebUI, ORDS, SQLcl sidecar, and Daytona. Linux and macOS OpenWebUI helper startup sets `AIOHTTP_CLIENT_TIMEOUT` to an empty value by default so OpenWebUI does not impose an upstream chat timeout; FortisAI bridge startup keeps a finite `FORTISAI_OPENAI_ROUTER_TIMEOUT_SECONDS=1800` safety limit. Helper-generated OpenWebUI startup also enables SQLite WAL mode, sets `DATABASE_SQLITE_PRAGMA_BUSY_TIMEOUT=60000`, and uses `DATABASE_SQLITE_PRAGMA_SYNCHRONOUS=NORMAL` to reduce transient database lock failures during long tool and chat sessions. macOS and Windows use `fortisai-dev-net`; Linux uses `fortisai-calico-net` after `linux/deploy-calico-network.sh` or `./linux/fortisai-dev-helper.sh calico-up`.

During `setup`, the helpers also create `~/fortisai-dev/oracle-wallet` with shell helpers for wallet-related local workflow setup.

- Listener port: `1521`
- PDB: `FREEPDB1`
- Default helper credentials: `pdbadmin` / `FortisAI26ai!2026`
- Logs target: `oracle-db`
- Manual pre-pull command: `oracle-db-pull` (mac, Windows, and Linux helpers)

Bundled companion services:

- ORDS image: `container-registry.oracle.com/database/ords:latest`
- ORDS host URL (default): `http://127.0.0.1:8181/ords/`
- SQLcl sidecar image: `container-registry.oracle.com/database/sqlcl:latest`
- Open interactive SQLcl shell via helper command: `sqlcl-shell`
- Run the SQLcl MCP stdio server via helper command: `sqlcl-mcp`
- Validate the SQLcl MCP config + handshake via helper command: `sqlcl-mcp-smoke`
- Generated SQLcl MCP client config: `~/fortisai-dev/sqlcl-mcp/mcp.json`
- Optional APEX URL after helper install: `http://127.0.0.1:8181/ords/apex`
- Optional APEX workflow commands: `apex-install`, `apex-check`, and `apex-reset`

Optional OCR auth automation variables (for private/token-gated pulls):

- `OCR_USERNAME`
- `OCR_AUTH_TOKEN`
- `OCR_REGISTRY` (defaults to `container-registry.oracle.com`)

If you are pulling the image for the first time, sign in to Oracle Container Registry first.

## Pushing Configurations to OCI DevOps Repositories

Once you have local n8n and dify configurations (exported or created), push them to the FortisAI OCI DevOps repositories to trigger production import pipelines:

### Prerequisites

1. Landing-zone has been applied (creates `n8n-config` and `dify-config` OCI DevOps repositories)
2. You have local configurations in `Development_Environment/n8n-config/main/` and `Development_Environment/dify-config/main/` directories
3. You have OCI DevOps Git access credentials (stored in OCI Vault)

### Mac Workflow

```bash
# Get the OCI DevOps repository URLs
terraform -chdir=landing-zone output devops_repository_http_urls

# Push n8n configurations
cd Development_Environment/n8n-config/main
git init
git remote add oci <n8n-config-repo-url-from-output>
git add .
git commit -m "Initial or updated n8n workflows"
git push oci HEAD:main -f

# Push dify configurations
cd ../../dify-config/main
git init
git remote add oci <dify-config-repo-url-from-output>
git add .
git commit -m "Initial or updated dify applications"
git push oci HEAD:main -f
```

### Windows Workflow

```powershell
# Get the OCI DevOps repository URLs
terraform -chdir=landing-zone output devops_repository_http_urls

# Push n8n configurations
cd Development_Environment\n8n-config\main
git init
git remote add oci <n8n-config-repo-url-from-output>
git add .
git commit -m "Initial or updated n8n workflows"
git push oci HEAD:main -f

# Push dify configurations
cd ..\..\dify-config\main
git init
git remote add oci <dify-config-repo-url-from-output>
git add .
git commit -m "Initial or updated dify applications"
git push oci HEAD:main -f
```

### After Push

1. OCI DevOps automatically detects push to `main` branch
2. Dify trigger fires on YAML/YML file changes → `dify-config-import` pipeline
3. n8n trigger fires on JSON file changes → `n8n-config-import` pipeline
4. Import pipeline clones the repository, validates files, and imports via API
5. Monitor build pipeline in OCI Console for import status

### Continuous Workflow

For ongoing updates:

1. Make local changes to Dify/n8n apps
2. Export configurations locally (via UI or helper scripts)
3. Commit changes: `git add . && git commit -m "<description>"`
4. Push to OCI: `git push oci main`
5. Monitor import pipeline in OCI Console

For feature branches and PRs (if using OCI DevOps PR workflow), merge to `main` to trigger import.

## Local Templates

- `templates/dify/app-template.yaml`
  Copy and customize for local Dify app creation and export/import testing.

- `templates/n8n/workflow-template.json`
  Copy and customize for local n8n workflow creation and import testing.
