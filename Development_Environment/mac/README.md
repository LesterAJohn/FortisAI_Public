# Mac Development Environment

This folder contains local development setup and operator workflows for FortisAI application services.

## Documents

- [MAC_DEV_SETUP_DIFY_N8N_OPENWEBUI.md](MAC_DEV_SETUP_DIFY_N8N_OPENWEBUI.md)
  Mac local environment setup for Dify, n8n, and OpenWebUI using Podman, plus production bastion linking steps.

- [LM_STUDIO_SETUP_MAC.md](LM_STUDIO_SETUP_MAC.md)
  Mac setup and helper-driven deployment flow for LM Studio local model serving.

- [windows/README.md](../windows/README.md)
  Windows local environment setup index for Dify, n8n, and OpenWebUI using Podman and PowerShell.

- [linux/README.md](../linux/README.md)
  Linux local environment setup index for the full FortisAI local operator stack using Podman and bash helper commands.

- [GIT_IMPORT_EXPORT_DIFY_N8N.md](GIT_IMPORT_EXPORT_DIFY_N8N.md)
  Git workflow for exporting Dify YAML and n8n JSON, naming conventions, repository layout, and production import flow through OCI DevOps.

- [ORACLE_TOOLS_ORAS_ORDS_SQLCL_APEX.md](ORACLE_TOOLS_ORAS_ORDS_SQLCL_APEX.md)
  Mac workflows for ORAS and ORDS plus SQLcl, Oracle Node API, and APEX helper operations.

- [AppSmith.md](AppSmith.md)
  Appsmith-specific FortisAI integration guide, including runtime wiring, commands, and troubleshooting.

## Helper App

- [fortisai-dev-helper.sh](fortisai-dev-helper.sh)
  Local helper CLI for setup, lifecycle management, bastion production linking, validation, and config-repo scaffolding.

Core commands:

```bash
./fortisai-dev-helper.sh setup
./fortisai-dev-helper.sh oracle-db-pull
./fortisai-dev-helper.sh up
./fortisai-dev-helper.sh down
./fortisai-dev-helper.sh all-up
./fortisai-dev-helper.sh all-down
./fortisai-dev-helper.sh vault-up
./fortisai-dev-helper.sh vault-down
./fortisai-dev-helper.sh vault-init
./fortisai-dev-helper.sh vault-unseal
./fortisai-dev-helper.sh vault-status
./fortisai-dev-helper.sh vault-read <path>
./fortisai-dev-helper.sh vault-write <path> <value>
./fortisai-dev-helper.sh vault-del <path>
./fortisai-dev-helper.sh openclaw-up
./fortisai-dev-helper.sh openclaw-down
./fortisai-dev-helper.sh openclaw-shell
./fortisai-dev-helper.sh openwebui-shell
./fortisai-dev-helper.sh openvscode-up
./fortisai-dev-helper.sh openvscode-down
./fortisai-dev-helper.sh openvscode-users
./fortisai-dev-helper.sh openvscode-shell [user]
./fortisai-dev-helper.sh openvscode-list-extensions [user]
./fortisai-dev-helper.sh openvscode-install-extension [user] <extension-id-or-vsix>
./fortisai-dev-helper.sh openvscode-uninstall-extension [user] <extension-id>
./fortisai-dev-helper.sh hermes-up
./fortisai-dev-helper.sh hermes-down
./fortisai-dev-helper.sh hermes-shell
./fortisai-dev-helper.sh status
./fortisai-dev-helper.sh check
./fortisai-dev-helper.sh sqlcl-shell
./fortisai-dev-helper.sh sqlcl-mcp
./fortisai-dev-helper.sh sqlcl-mcp-smoke
./fortisai-dev-helper.sh mcp-up
./fortisai-dev-helper.sh mcp-down
./fortisai-dev-helper.sh n8n-import-workflows
./fortisai-dev-helper.sh traefik-up
./fortisai-dev-helper.sh traefik-down
./fortisai-dev-helper.sh traefik-check
./fortisai-dev-helper.sh codeindexer-up
./fortisai-dev-helper.sh codeindexer-down
./fortisai-dev-helper.sh codeindexer-check
./fortisai-dev-helper.sh milvus-up
./fortisai-dev-helper.sh milvus-down
./fortisai-dev-helper.sh opensearch-up
./fortisai-dev-helper.sh opensearch-down
./fortisai-dev-helper.sh openmetadata-up
./fortisai-dev-helper.sh openmetadata-down
./fortisai-dev-helper.sh openmetadata-check
./fortisai-dev-helper.sh apex-install
./fortisai-dev-helper.sh apex-check
./fortisai-dev-helper.sh apex-reset
./fortisai-dev-helper.sh scaffold-config-repos
./fortisai-dev-helper.sh scaffold-templates all
./fortisai-dev-helper.sh scaffold-templates dify my-app
./fortisai-dev-helper.sh scaffold-templates n8n my-workflow
./fortisai-dev-helper.sh lmstudio-setup
./fortisai-dev-helper.sh lmstudio-start
./fortisai-dev-helper.sh lmstudio-check
./fortisai-dev-helper.sh daytona-setup
./fortisai-dev-helper.sh daytona-up
./fortisai-dev-helper.sh daytona-check
./fortisai-dev-helper.sh daytona-down
./fortisai-dev-helper.sh logs oracle-db
./fortisai-dev-helper.sh logs mongodb
./fortisai-dev-helper.sh logs redis
./fortisai-dev-helper.sh logs rabbitmq
./fortisai-dev-helper.sh logs vault
./fortisai-dev-helper.sh logs firecrawl
./fortisai-dev-helper.sh logs pgvector
./fortisai-dev-helper.sh logs honcho
./fortisai-dev-helper.sh logs openclaw
./fortisai-dev-helper.sh logs hermes
./fortisai-dev-helper.sh logs qdrant
./fortisai-dev-helper.sh logs appsmith
./fortisai-dev-helper.sh logs oracle-node-api
./fortisai-dev-helper.sh logs traefik
./fortisai-dev-helper.sh logs codeindexer
./fortisai-dev-helper.sh logs milvus
./fortisai-dev-helper.sh logs openmetadata
./fortisai-dev-helper.sh logs opensearch
./fortisai-dev-helper.sh daytona-set-admin-creds <email> <password>
./fortisai-dev-helper.sh prod-template
./fortisai-dev-helper.sh validate-prod
./fortisai-dev-helper.sh link-prod
```

For the consolidated endpoint list, see [Development_Environment/development_env_url.md](../development_env_url.md).
For the complete default credential/password matrix, also see [Development_Environment/development_env_url.md](../development_env_url.md).

## Oracle AI Database Free (Local)

The helper script now generates an Oracle AI Database Free container and joins it with MongoDB, Redis, RabbitMQ, HashiCorp Vault, Firecrawl, pgvector, Honcho, OpenClaw, Hermes, Dify, Qdrant, n8n, OpenWebUI, Appsmith, ORDS, SQLcl sidecar, Oracle Node API, Daytona, Traefik, CodeIndexer, Milvus, OpenMetadata, and OpenSearch on the shared `fortisai-dev-net` network.

Helper-generated Dify and n8n runtimes also expose `FORTISAI_LLAMA_SERVER_BASE_URL` and `FORTISAI_LLAMA_OPENAI_BASE_URL`. The default is `http://host.docker.internal:8011/v1`; override `FORTISAI_LLAMA_SERVER_URL` or `FORTISAI_LLAMA_SERVER_BASE_URL` before running `./fortisai-dev-helper.sh setup` when using a different local OpenAI-compatible model endpoint.

During `setup`, the helper also creates `~/fortisai-dev/oracle-wallet` with shell helpers for wallet-related local workflow setup.
The wallet directory includes `oracle-wallet-credentials.sh` for collecting DB inputs and optionally building `ewallet.p12` from separate certificate and private-key files.

- Start core services (excluding OpenClaw): `./fortisai-dev-helper.sh up`
- Start full operator stack: `./fortisai-dev-helper.sh all-up`
- Stop full operator stack: `./fortisai-dev-helper.sh all-down`
- Recommended Podman VM sizing for `all-up`: at least 24 GB memory on Apple Silicon hosts with 48 GB or more host RAM. Example: `podman machine stop podman-machine-default`, `podman machine set --memory 24576 podman-machine-default`, then `podman machine start podman-machine-default`.
- Start OpenClaw separately: `./fortisai-dev-helper.sh openclaw-up`
- Start Hermes separately: `./fortisai-dev-helper.sh hermes-up`
- Pre-pull Oracle DB image only: `./fortisai-dev-helper.sh oracle-db-pull`
- Stream database logs: `./fortisai-dev-helper.sh logs oracle-db`
- Default listener: `localhost:1521`
- Default PDB: `FREEPDB1`
- Default helper credentials: `pdbadmin` / `FortisAI26ai!2026`
- ORDS URL: `http://127.0.0.1:8181/ords/`
- ORDS logs: `./fortisai-dev-helper.sh logs ords`
- ORDS readiness note: immediately after `up`, ORDS may briefly return empty responses before settling to expected redirects (`HTTP 302`).
- SQLcl sidecar logs: `./fortisai-dev-helper.sh logs sqlcl`
- SQLcl interactive shell: `./fortisai-dev-helper.sh sqlcl-shell`
- SQLcl MCP stdio server: `./fortisai-dev-helper.sh sqlcl-mcp`
- SQLcl MCP smoke test: `./fortisai-dev-helper.sh sqlcl-mcp-smoke`
- MCP OpenAPI bridge startup + end-to-end validation: `./fortisai-dev-helper.sh mcp-up`
- MCP OpenAPI bridge shutdown: `./fortisai-dev-helper.sh mcp-down`
- Dify API key JSON is a generated local bridge cache: `Development_Environment/mcp/dify-mcp/dify-api-key.json`; Vault remains the runtime source of truth after helper sync.
- `mcp-up` starts SQLcl, n8n, Dify, CodeIndexer, debug, and optional Proxmox bridge containers, validates OpenAPI readiness, runs smoke checks, and auto-resolves Dify console admin routing context (`ADMIN_API_KEY` and `X-WORKSPACE-ID`) from running Dify/pgvector services when not explicitly set.
- SQLcl MCP client config: `~/fortisai-dev/sqlcl-mcp/mcp.json`
- Appsmith URL: `http://localhost:18080`
- Appsmith logs: `./fortisai-dev-helper.sh logs appsmith`
- MongoDB URL: `mongodb://127.0.0.1:27017/appsmith?replicaSet=rs0`
- MongoDB logs: `./fortisai-dev-helper.sh logs mongodb`
- Appsmith helper wiring defaults to MongoDB via `APPSMITH_DB_URL` and `APPSMITH_MONGODB_URI`.
- Redis URL: `redis://127.0.0.1:6379`
- Redis logs: `./fortisai-dev-helper.sh logs redis`
- RabbitMQ URL: `amqp://fortisai:fortisai@127.0.0.1:5672`
- RabbitMQ management URL: `http://127.0.0.1:15672`
- RabbitMQ logs: `./fortisai-dev-helper.sh logs rabbitmq`
- Vault URL: `http://127.0.0.1:8200`
- Vault logs: `./fortisai-dev-helper.sh logs vault`
- Vault first-time init: `./fortisai-dev-helper.sh vault-init`
- Vault unseal after restart: `./fortisai-dev-helper.sh vault-unseal`
- Vault operator read/write/delete: `./fortisai-dev-helper.sh vault-read <path>`, `./fortisai-dev-helper.sh vault-write <path> <value>`, and `./fortisai-dev-helper.sh vault-del <path>` for paths relative to `secret/fortisai/dev/`. `vault-del` permanently removes metadata and all versions for that path.
- Helper `up` starts Vault and runs `vault-unseal` before the rest of the stack after first-time init has created the local key file.
- Helper startup syncs runtime passwords/API keys into Vault under `secret/fortisai/dev/*`, then verifies required paths before starting dependent services.
- Exported env values seed or rotate Vault; otherwise existing Vault values are used before local development defaults.
- Generated app compose/env files receive `VAULT_ADDR`, `FORTISAI_VAULT_ADDR`, and a helper-created read-only `VAULT_TOKEN`.
- Vault uses `docker.io/hashicorp/vault:latest` with persistent file storage under `~/fortisai-dev/vault/file`.
- Traefik entrypoint: `http://127.0.0.1:18000`
- Traefik dashboard: `http://127.0.0.1:18088/dashboard/`
- Traefik logs: `./fortisai-dev-helper.sh logs traefik`
- CodeIndexer OpenAPI bridge: `http://127.0.0.1:8096/openapi.json`
- CodeIndexer logs: `./fortisai-dev-helper.sh logs codeindexer`
- Milvus health: `http://127.0.0.1:19091/healthz`
- Milvus logs: `./fortisai-dev-helper.sh logs milvus`
- OpenMetadata URL: `http://127.0.0.1:18585`
- OpenMetadata logs: `./fortisai-dev-helper.sh logs openmetadata`
- OpenSearch URL: `http://127.0.0.1:9200`
- OpenSearch logs: `./fortisai-dev-helper.sh logs opensearch`
- `codeindexer-up`, `openmetadata-up`, and `traefik-up` manage these standalone operator components individually; `all-up` runs the Linux-parity sequence: CodeIndexer, OpenMetadata, MCP OpenAPI bridges, OpenClaw, Hermes, Daytona, and Traefik.
- Firecrawl URL: `http://127.0.0.1:3002`
- Firecrawl logs: `./fortisai-dev-helper.sh logs firecrawl`
- Firecrawl default API key: `fortisai-firecrawl-dev-api-key` (`FIRECRAWL_API_KEY`)
- Firecrawl is started/stopped by default helper lifecycle (`up` / `down`); dedicated `firecrawl-up` / `firecrawl-down` commands were removed.
- Firecrawl is wired to shared pgvector, RabbitMQ, and Redis (`NUQ_DATABASE_URL`, `NUQ_RABBITMQ_URL`, `REDIS_URL`, `REDIS_EVICT_URL`, `REDIS_RATE_LIMIT_URL`).
- Helper startup auto-creates Firecrawl DB (`FIRECRAWL_DB_NAME`, default `firecrawl`) and applies upstream NUQ schema before Firecrawl launch.
- Override NUQ schema source with `FIRECRAWL_NUQ_SQL_URL` when needed.
- pgvector endpoint: `127.0.0.1:5432`
- pgvector default DSN: `postgresql://fortisai:fortisai@127.0.0.1:5432/fortisai`
- pgvector logs: `./fortisai-dev-helper.sh logs pgvector`
- Honcho URL: `http://127.0.0.1:8010`
- Honcho logs: `./fortisai-dev-helper.sh logs honcho`
- Honcho uses shared pgvector and Redis (`DB_CONNECTION_URI`, `CACHE_URL`) and runs API + deriver services.
- Honcho uses dedicated database `honcho` on shared pgvector by default (`HONCHO_DB=honcho`).
- Helper startup auto-creates the Honcho database before Honcho services start.
- Honcho requires an LLM provider key; helper default is `HONCHO_LLM_OPENAI_API_KEY=lmstudio`.
- OpenClaw URL: `http://127.0.0.1:18789`
- OpenClaw logs: `./fortisai-dev-helper.sh logs openclaw`
- OpenClaw shell: `./fortisai-dev-helper.sh openclaw-shell`
- Start OpenClaw separately: `./fortisai-dev-helper.sh openclaw-up`
- Stop OpenClaw separately: `./fortisai-dev-helper.sh openclaw-down`
- OpenClaw gateway + bridge ports: `18789` and `18790`
- `openclaw-up` prepares only the OpenClaw runtime, starts Vault, and runs `vault-unseal` before launching OpenClaw.
- `openclaw-down` stops OpenClaw only; Vault remains available as a shared local service.
- OpenClaw uses helper-generated config at `~/fortisai-dev/claw-gateway/fortisai-claw-gateway.json`.
- OpenClaw is pre-wired to Honcho using `@honcho-ai/openclaw-honcho` plugin config.
- OpenClaw is pre-wired to the FortisAI proxy using OpenAI-compatible base URL `http://fortisai-mcp-openapi-dify:8093/v1` and model `fortisai`. Override `OPENCLAW_LMSTUDIO_BASE_URL` and `OPENCLAW_LMSTUDIO_MODEL` only when intentionally using LM Studio or another provider.
- OpenClaw helper-managed secrets use Vault paths under `secret/fortisai/dev/claw-gateway/`.
- OpenWebUI defaults to Hermes via `OPENAI_API_BASE_URL=http://fortisai-hermes.fortisai.local:8642/v1` when CoreDNS is active and `http://fortisai-hermes:8642/v1` otherwise.
- To route OpenWebUI to OpenClaw, set `OPENWEBUI_LLM_BACKEND=openclaw` before running helper commands.
- OpenWebUI shell: `./fortisai-dev-helper.sh openwebui-shell`
- OpenVSCode per-user startup: `OPENVSCODE_USERS="lester:13000 alice:13001" ./fortisai-dev-helper.sh openvscode-up`
- OpenVSCode user/extension commands: `openvscode-users`, `openvscode-list-extensions [user]`, `openvscode-install-extension [user] <extension-id-or-vsix>`, and `openvscode-uninstall-extension [user] <extension-id>`.
- Helper validates OpenClaw host ports to avoid default-service conflicts before startup.
- Hermes URL: `http://127.0.0.1:8642`
- Hermes health endpoint: `http://127.0.0.1:8642/health`
- Hermes logs: `./fortisai-dev-helper.sh logs hermes`
- Hermes shell: `./fortisai-dev-helper.sh hermes-shell`
- Stop Hermes separately: `./fortisai-dev-helper.sh hermes-down`
- Hermes dashboard can be enabled with `HERMES_DASHBOARD=1` (default dashboard port `9119`).
- Hermes uses image `nousresearch/hermes-agent:latest`, keeps the image entrypoint intact, and runs `gateway run`.
- Hermes receives Honcho context via `FORTISAI_HONCHO_BASE_URL`, `FORTISAI_HONCHO_WORKSPACE_ID`, and optional `FORTISAI_HONCHO_API_KEY`.
- Hermes receives Daytona context via `FORTISAI_DAYTONA_DASHBOARD_URL` and `FORTISAI_DAYTONA_API_URL`.
- Hermes receives OpenAI-compatible model access through the FortisAI proxy by default using `OPENAI_BASE_URL=http://fortisai-mcp-openapi-dify:8093/v1` and `OPENAI_MODEL=fortisai`.
- Qdrant URL: `http://127.0.0.1:6333`
- Qdrant logs: `./fortisai-dev-helper.sh logs qdrant`
- Dify uses Qdrant as the default local vector store and starts with the `qdrant` profile.
- Dify uses shared services for database/cache (`fortisai-pgvector` and `fortisai-redis`) instead of internal PostgreSQL/Redis containers.
- Generated app compose/env files include shared Vault endpoint values (`VAULT_ADDR`, `FORTISAI_VAULT_ADDR`) alongside Redis, RabbitMQ, MongoDB, and pgvector wiring where applicable.
- OpenWebUI OpenAPI templates now include repo filesystem/memory/time servers plus MCP bridges for SQLcl, n8n, Dify, CodeIndexer, debug, and optional Proxmox (`repo-filesystem-server`, `repo-memory-server`, `repo-time-server`, `mcp-sqlcl-server`, `mcp-n8n-server`, `mcp-dify-server`, `mcp-codeindexer-server`, and `mcp-proxmox-server` when configured).
- Helper `up` imports OpenWebUI tool connections and skills for `repo-filesystem-server`, `repo-memory-server`, and `repo-time-server` after the repo OpenAPI servers start. Payloads live under `Development_Environment/mcp/repo-openapi/` and use `host.containers.internal` so the OpenWebUI container can reach the host-exposed repo server ports.
- Regenerate OpenWebUI OpenAPI templates via `./fortisai-dev-helper.sh setup`.
- Recommended MCP sequence for OpenWebUI:
  1. `./fortisai-dev-helper.sh setup`
  2. `./fortisai-dev-helper.sh mcp-up`
- `mcp-up` validates SQLcl/n8n/Dify/CodeIndexer/debug and optional Proxmox OpenAPI readiness, runs debug/SQL/n8n/Dify/CodeIndexer and optional Proxmox `/livez` smoke checks, upserts OpenWebUI `tool_server.connections` for `mcp-dify-server`, and imports the CodeIndexer OpenWebUI tool/skill payloads when OpenWebUI admin access is available.
- If OpenWebUI has not completed first-run initialization yet, helper-managed tool/skill wiring logs a skip and continues; rerun `mcp-up` after first login to populate `tool_server.connections`.
- When Proxmox is enabled, `mcp-up` starts `fortisai-mcp-openapi-proxmox-upstream` and the local facade `fortisai-mcp-openapi-proxmox`; config can come from `Development_Environment/mcp/proxmox/proxmox-config.json`, `PROXMOX_*` environment variables, or Vault after helper sync.
- `mcp-down` stops and removes bridge containers `fortisai-mcp-openapi-sqlcl`, `fortisai-mcp-openapi-n8n`, `fortisai-mcp-openapi-dify`, `fortisai-mcp-openapi-codeindexer`, `fortisai-mcp-openapi-debug`, `fortisai-mcp-openapi-proxmox`, and `fortisai-mcp-openapi-proxmox-upstream` when present.
- Dify OpenWebUI import asset: `Development_Environment/mcp/dify-mcp/openwebui-dify-mcp-tools.import.json`
- Oracle Node API URL: `http://127.0.0.1:8090`
- Oracle Node API logs: `./fortisai-dev-helper.sh logs oracle-node-api`
- Install APEX workflow (optional): `./fortisai-dev-helper.sh apex-install`
- Check APEX status + endpoint: `./fortisai-dev-helper.sh apex-check`
- Reset APEX runtime without uninstall: `./fortisai-dev-helper.sh apex-reset`
- APEX URL after install: `http://127.0.0.1:8181/ords/apex`

If you pull the image for the first time, sign in to Oracle Container Registry before running the helper:

- https://container-registry.oracle.com/ords/ocr/ba/database/free

For token-based automated OCR login, set `OCR_USERNAME` and `OCR_AUTH_TOKEN` before running `oracle-db-pull` or `up`.

## Optional Daytona OSS (Self-Hosted)

Daytona is available as an optional local self-hosted stack.

- It runs as a separate compose project from Dify, n8n, and OpenWebUI.
- It is intentionally not started by the default `up` command.
- `./fortisai-dev-helper.sh daytona-up` now prefers Docker Compose for runner stability and falls back to Podman compose only when Docker Compose is unavailable.
- `daytona-up` waits for the Daytona dashboard to answer before reporting the dashboard URL, avoiding the earlier immediate `daytona-check` empty-reply race.
- `daytona-gpu-check` detects Apple Silicon GPU/Metal availability and records that Daytona Linux containers remain CPU-only on macOS because Metal/MPS is not exposed through Docker/Podman Linux containers.
- Default dashboard URL is `http://localhost:3300` to avoid conflict with OpenWebUI on `3000`.
- Default dashboard login (Dex static user, defined in `~/fortisai-dev/daytona/docker/dex/config.yaml`):
  - **Email:** `dev@daytona.io`
  - **Password:** `password`
  - To change credentials: `./fortisai-dev-helper.sh daytona-set-admin-creds <new-email> <new-password>` then restart the stack.
- For preview URL wildcard routing, run Daytona DNS setup after repo initialization:
  - `cd ~/fortisai-dev/daytona && ./scripts/setup-proxy-dns.sh`

## Validation Snapshot (2026-06-11)

- Verified `./fortisai-dev-helper.sh up`, `./fortisai-dev-helper.sh check`, and `./fortisai-dev-helper.sh down` on the local macOS Podman machine.
- Verified full shutdown state after `down` for FortisAI, Dify, and OpenAPI containers (`podman ps` returned no running `fortisai-*`, `docker_*`, or `repo_*` containers).
- `check` passed for Oracle DB, n8n, OpenWebUI, Appsmith, MongoDB, Redis, RabbitMQ, Firecrawl reachability, pgvector, Honcho, Dify, Qdrant, ORDS, Oracle Node API, SQLcl sidecar, and SQLcl MCP config.
- Vault started successfully with `docker.io/hashicorp/vault:latest`; before first-time init, `check` reports reachable/uninitialized HTTP `501`.
- OpenClaw and Hermes remain optional services and are not started by default `up`.

## Validation Snapshot (2026-06-18)

- Revalidated `all-up` on local macOS through Vault, Oracle DB, n8n, OpenWebUI, OpenVSCode, MongoDB, Appsmith, repo OpenAPI servers, Redis, RabbitMQ, pgvector, Firecrawl, Honcho, Dify, Milvus, CodeIndexer, OpenMetadata/OpenSearch, and MCP OpenAPI bridges.
- Local first-run testing fixed repeat-start collisions for n8n, Milvus, and OpenSearch by reusing healthy containers or removing stale stopped containers before compose startup.
- OpenMetadata reached HTTP `200`; OpenSearch can exceed the default readiness window on a busy Mac but still becomes usable for OpenMetadata after startup settles.
- OpenWebUI tool wiring now skips cleanly when the config database row does not exist yet; rerun `mcp-up` after first login to complete imports.
- The full local stack is memory-heavy. A 12 GB Podman VM can wedge the Podman API under `all-up`; 24 GB is the current recommended local validation size.

## Runtime Fixes (2026-05-24)

- Shared network creation is now idempotent; existing `fortisai-dev-net` no longer fails setup/up.
- Firecrawl startup stabilization includes NUQ schema bootstrap and explicit shared Redis wiring.

## Runtime Fixes (2026-06-11)

- Core macOS `up` now reuses or restarts existing named containers instead of failing on podman-compose name collisions during repeat startup.
- Dify startup now handles partial existing `docker_*` containers by restarting existing containers first, then recreating the Dify compose stack cleanly when needed.
- Oracle Node API startup now resolves the active Podman machine socket path and passes `PODMAN_SOCKET_PATH` into compose, avoiding stale `/run/user/.../podman.sock` defaults.
- Vault startup with `docker.io/hashicorp/vault:latest` now skips missing `setcap`, lets the entrypoint chown bind mounts, and relies on the image entrypoint to load `/vault/config` once.
- Vault init now treats Vault CLI exit code `2` as reachable for the uninitialized or sealed local server, so first-time `vault-init` proceeds instead of waiting until timeout.
- Default `up` now starts Vault and runs the saved-key unseal step before starting the dependent local services.
- `openclaw-up` now uses an OpenClaw-only setup path, starts and unseals Vault first, and reuses or restarts the named OpenClaw container safely on repeat runs.

## Runtime Fixes (2026-06-18)

- Mac and Windows helpers now match Linux helper behavior for multi-user OpenVSCode, n8n workflow import, FortisAI proxy defaults for OpenClaw/Hermes, Vault-first startup, and full `all-up` / `all-down` ordering.
- n8n, Milvus, and OpenSearch startup paths now tolerate existing named containers and stale stopped containers during repeat local startup.
- OpenWebUI Dify and CodeIndexer MCP wiring is nonfatal when OpenWebUI has not initialized its config row yet.

## Local Config Templates

- `../templates/dify/app-template.yaml`
  Starter Dify app YAML for local customization.

- `../templates/n8n/workflow-template.json`
  Starter n8n workflow JSON for local customization.

## Recommended Reading Order

1. Read [MAC_DEV_SETUP_DIFY_N8N_OPENWEBUI.md](MAC_DEV_SETUP_DIFY_N8N_OPENWEBUI.md)
2. Read [LM_STUDIO_SETUP_MAC.md](LM_STUDIO_SETUP_MAC.md)
3. Run the helper app for local setup
4. Read [GIT_IMPORT_EXPORT_DIFY_N8N.md](GIT_IMPORT_EXPORT_DIFY_N8N.md)
5. Configure production bastion linking if needed

For cross-platform setup, see [windows/README.md](../windows/README.md) and [linux/README.md](../linux/README.md).
