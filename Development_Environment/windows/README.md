# Windows Development Environment

This folder contains Windows-specific setup and operational workflows for the FortisAI local development stack.

## Documents

- [WINDOWS_DEV_SETUP_DIFY_N8N_OPENWEBUI.md](WINDOWS_DEV_SETUP_DIFY_N8N_OPENWEBUI.md)
  End-to-end Windows setup using Podman, including local runtime, helper commands, and production bastion linking.

- [LM_STUDIO_SETUP_WINDOWS.md](LM_STUDIO_SETUP_WINDOWS.md)
  Windows setup and helper-driven deployment flow for LM Studio local model serving.

- [GIT_IMPORT_EXPORT_DIFY_N8N_WINDOWS.md](GIT_IMPORT_EXPORT_DIFY_N8N_WINDOWS.md)
  Git workflow for exporting Dify YAML and n8n JSON artifacts from Windows environments.

- [ORACLE_TOOLS_ORAS_ORDS_SQLCL_APEX_WINDOWS.md](ORACLE_TOOLS_ORAS_ORDS_SQLCL_APEX_WINDOWS.md)
  Windows workflows for ORAS and ORDS plus SQLcl, Oracle Node API, and APEX helper operations.

- [AppSmith.md](AppSmith.md)
  Appsmith-specific FortisAI integration guide, including runtime wiring, commands, and troubleshooting.

- [../linux/README.md](../linux/README.md)
  Linux local environment setup index for the full FortisAI local operator stack using Podman and bash helper commands.

## Helper Script

- [fortisai-dev-helper.ps1](fortisai-dev-helper.ps1)

Core commands:

```powershell
.\fortisai-dev-helper.ps1 setup
.\fortisai-dev-helper.ps1 oracle-db-pull
.\fortisai-dev-helper.ps1 up
.\fortisai-dev-helper.ps1 down
.\fortisai-dev-helper.ps1 all-up
.\fortisai-dev-helper.ps1 all-down
.\fortisai-dev-helper.ps1 vault-up
.\fortisai-dev-helper.ps1 vault-down
.\fortisai-dev-helper.ps1 vault-init
.\fortisai-dev-helper.ps1 vault-unseal
.\fortisai-dev-helper.ps1 vault-status
.\fortisai-dev-helper.ps1 vault-read <path>
.\fortisai-dev-helper.ps1 vault-write <path> <value>
.\fortisai-dev-helper.ps1 vault-del <path>
.\fortisai-dev-helper.ps1 openclaw-up
.\fortisai-dev-helper.ps1 openclaw-down
.\fortisai-dev-helper.ps1 openclaw-shell
.\fortisai-dev-helper.ps1 openwebui-shell
.\fortisai-dev-helper.ps1 openvscode-up
.\fortisai-dev-helper.ps1 openvscode-down
.\fortisai-dev-helper.ps1 openvscode-users
.\fortisai-dev-helper.ps1 openvscode-shell [user]
.\fortisai-dev-helper.ps1 openvscode-list-extensions [user]
.\fortisai-dev-helper.ps1 openvscode-install-extension [user] <extension-id-or-vsix>
.\fortisai-dev-helper.ps1 openvscode-uninstall-extension [user] <extension-id>
.\fortisai-dev-helper.ps1 hermes-up
.\fortisai-dev-helper.ps1 hermes-down
.\fortisai-dev-helper.ps1 hermes-shell
.\fortisai-dev-helper.ps1 status
.\fortisai-dev-helper.ps1 check
.\fortisai-dev-helper.ps1 sqlcl-shell
.\fortisai-dev-helper.ps1 sqlcl-mcp
.\fortisai-dev-helper.ps1 sqlcl-mcp-smoke
.\fortisai-dev-helper.ps1 mcp-up
.\fortisai-dev-helper.ps1 mcp-down
.\fortisai-dev-helper.ps1 n8n-import-workflows
.\fortisai-dev-helper.ps1 traefik-up
.\fortisai-dev-helper.ps1 traefik-down
.\fortisai-dev-helper.ps1 traefik-check
.\fortisai-dev-helper.ps1 codeindexer-up
.\fortisai-dev-helper.ps1 codeindexer-down
.\fortisai-dev-helper.ps1 codeindexer-check
.\fortisai-dev-helper.ps1 milvus-up
.\fortisai-dev-helper.ps1 milvus-down
.\fortisai-dev-helper.ps1 opensearch-up
.\fortisai-dev-helper.ps1 opensearch-down
.\fortisai-dev-helper.ps1 openmetadata-up
.\fortisai-dev-helper.ps1 openmetadata-down
.\fortisai-dev-helper.ps1 openmetadata-check
.\fortisai-dev-helper.ps1 apex-install
.\fortisai-dev-helper.ps1 apex-check
.\fortisai-dev-helper.ps1 apex-reset
.\fortisai-dev-helper.ps1 scaffold-config-repos
.\fortisai-dev-helper.ps1 scaffold-templates all
.\fortisai-dev-helper.ps1 scaffold-templates dify my-app
.\fortisai-dev-helper.ps1 scaffold-templates n8n my-workflow
.\fortisai-dev-helper.ps1 lmstudio-setup
.\fortisai-dev-helper.ps1 lmstudio-start
.\fortisai-dev-helper.ps1 lmstudio-check
.\fortisai-dev-helper.ps1 daytona-setup
.\fortisai-dev-helper.ps1 daytona-up
.\fortisai-dev-helper.ps1 daytona-check
.\fortisai-dev-helper.ps1 daytona-down
.\fortisai-dev-helper.ps1 logs oracle-db
.\fortisai-dev-helper.ps1 logs mongodb
.\fortisai-dev-helper.ps1 logs redis
.\fortisai-dev-helper.ps1 logs rabbitmq
.\fortisai-dev-helper.ps1 logs vault
.\fortisai-dev-helper.ps1 logs firecrawl
.\fortisai-dev-helper.ps1 logs pgvector
.\fortisai-dev-helper.ps1 logs honcho
.\fortisai-dev-helper.ps1 logs openclaw
.\fortisai-dev-helper.ps1 logs hermes
.\fortisai-dev-helper.ps1 logs qdrant
.\fortisai-dev-helper.ps1 logs appsmith
.\fortisai-dev-helper.ps1 logs oracle-node-api
.\fortisai-dev-helper.ps1 logs ords
.\fortisai-dev-helper.ps1 logs sqlcl
.\fortisai-dev-helper.ps1 logs traefik
.\fortisai-dev-helper.ps1 logs codeindexer
.\fortisai-dev-helper.ps1 logs milvus
.\fortisai-dev-helper.ps1 logs openmetadata
.\fortisai-dev-helper.ps1 logs opensearch
.\fortisai-dev-helper.ps1 daytona-set-admin-creds <email> <password>
.\fortisai-dev-helper.ps1 prod-template
.\fortisai-dev-helper.ps1 validate-prod
.\fortisai-dev-helper.ps1 link-prod
```

For the consolidated endpoint list, see [Development_Environment/development_env_url.md](../development_env_url.md).
For the complete default credential/password matrix, also see [Development_Environment/development_env_url.md](../development_env_url.md).

## Oracle AI Database Free (Local)

The helper script now generates an Oracle AI Database Free container and joins it with MongoDB, Redis, RabbitMQ, HashiCorp Vault, Firecrawl, pgvector, Honcho, OpenClaw, Hermes, Dify, Qdrant, n8n, OpenWebUI, Appsmith, ORDS, SQLcl sidecar, Oracle Node API, Daytona, Traefik, CodeIndexer, Milvus, OpenMetadata, and OpenSearch on the shared `fortisai-dev-net` network.

Helper-generated Dify and n8n runtimes also expose `FORTISAI_LLAMA_SERVER_BASE_URL` and `FORTISAI_LLAMA_OPENAI_BASE_URL`. The default is `http://host.docker.internal:8011/v1`; override `FORTISAI_LLAMA_SERVER_URL` or `FORTISAI_LLAMA_SERVER_BASE_URL` before running `.\fortisai-dev-helper.ps1 setup` when using a different local OpenAI-compatible model endpoint.

During `setup`, the helper also creates `~/fortisai-dev/oracle-wallet` with shell helpers for wallet-related local workflow setup.
The wallet directory includes `oracle-wallet-credentials.sh` for collecting DB inputs and optionally building `ewallet.p12` from separate certificate and private-key files.

- Start core services (excluding OpenClaw): `.\fortisai-dev-helper.ps1 up`
- Start full operator stack: `.\fortisai-dev-helper.ps1 all-up`
- Stop full operator stack: `.\fortisai-dev-helper.ps1 all-down`
- Start OpenClaw separately: `.\fortisai-dev-helper.ps1 openclaw-up`
- Start Hermes separately: `.\fortisai-dev-helper.ps1 hermes-up`
- Pre-pull Oracle DB image only: `.\fortisai-dev-helper.ps1 oracle-db-pull`
- Stream database logs: `.\fortisai-dev-helper.ps1 logs oracle-db`
- Default listener: `localhost:1521`
- Default PDB: `FREEPDB1`
- Default helper credentials: `pdbadmin` / `FortisAI26ai!2026`
- ORDS URL: `http://127.0.0.1:8181/ords/`
- ORDS logs: `.\fortisai-dev-helper.ps1 logs ords`
- ORDS readiness note: immediately after `up`, ORDS may briefly return empty responses before settling to expected redirects (`HTTP 302`).
- SQLcl sidecar logs: `.\fortisai-dev-helper.ps1 logs sqlcl`
- SQLcl interactive shell: `.\fortisai-dev-helper.ps1 sqlcl-shell`
- SQLcl MCP stdio server: `.\fortisai-dev-helper.ps1 sqlcl-mcp`
- SQLcl MCP smoke test: `.\fortisai-dev-helper.ps1 sqlcl-mcp-smoke`
- MCP OpenAPI bridge startup + end-to-end validation: `.\fortisai-dev-helper.ps1 mcp-up`
- MCP OpenAPI bridge shutdown: `.\fortisai-dev-helper.ps1 mcp-down`
- SQLcl MCP client config: `~/fortisai-dev/sqlcl-mcp/mcp.json`
- `mcp-up` starts `fortisai-mcp-openapi-sqlcl`, `fortisai-mcp-openapi-n8n`, `fortisai-mcp-openapi-dify`, `fortisai-mcp-openapi-codeindexer`, `fortisai-mcp-openapi-debug`, and optional Proxmox bridge containers when Proxmox config is present, validates OpenAPI readiness, runs debug/SQL/n8n/Dify/CodeIndexer and optional Proxmox `/livez` smoke checks, and verifies Dify API container reachability when `docker_api_1` is running.
- When Proxmox is enabled, `mcp-up` starts `fortisai-mcp-openapi-proxmox-upstream` and the local facade `fortisai-mcp-openapi-proxmox`; config can come from `Development_Environment\mcp\proxmox\proxmox-config.json`, `PROXMOX_*` environment variables, or Vault after helper sync.
- `mcp-up` auto-resolves Dify console admin routing context (`ADMIN_API_KEY` and `X-WORKSPACE-ID`) from running Dify/pgvector services when not explicitly set.
- `mcp-down` stops and removes bridge containers `fortisai-mcp-openapi-sqlcl`, `fortisai-mcp-openapi-n8n`, `fortisai-mcp-openapi-dify`, `fortisai-mcp-openapi-codeindexer`, `fortisai-mcp-openapi-debug`, `fortisai-mcp-openapi-proxmox`, and `fortisai-mcp-openapi-proxmox-upstream` when present.
- Appsmith URL: `http://localhost:18080`
- Appsmith logs: `.\fortisai-dev-helper.ps1 logs appsmith`
- MongoDB URL: `mongodb://127.0.0.1:27017/appsmith?replicaSet=rs0`
- MongoDB logs: `.\fortisai-dev-helper.ps1 logs mongodb`
- Appsmith helper wiring defaults to MongoDB via `APPSMITH_DB_URL` and `APPSMITH_MONGODB_URI`.
- Redis URL: `redis://127.0.0.1:6379`
- Redis logs: `.\fortisai-dev-helper.ps1 logs redis`
- RabbitMQ URL: `amqp://fortisai:fortisai@127.0.0.1:5672`
- RabbitMQ management URL: `http://127.0.0.1:15672`
- RabbitMQ logs: `.\fortisai-dev-helper.ps1 logs rabbitmq`
- Vault URL: `http://127.0.0.1:8200`
- Vault logs: `.\fortisai-dev-helper.ps1 logs vault`
- Vault first-time init: `.\fortisai-dev-helper.ps1 vault-init`
- Vault unseal after restart: `.\fortisai-dev-helper.ps1 vault-unseal`
- Vault operator read/write/delete: `.\fortisai-dev-helper.ps1 vault-read <path>`, `.\fortisai-dev-helper.ps1 vault-write <path> <value>`, and `.\fortisai-dev-helper.ps1 vault-del <path>` for paths relative to `secret/fortisai/dev/`. `vault-del` permanently removes metadata and all versions for that path.
- Helper `up` starts Vault and runs `vault-unseal` before the rest of the stack after first-time init has created the local key file.
- Helper startup syncs runtime passwords/API keys into Vault under `secret/fortisai/dev/*`, then verifies required paths before starting dependent services.
- Exported env values seed or rotate Vault; otherwise existing Vault values are used before local development defaults.
- Generated app compose/env files receive `VAULT_ADDR`, `FORTISAI_VAULT_ADDR`, and a helper-created read-only `VAULT_TOKEN`.
- Vault uses `docker.io/hashicorp/vault:latest` with persistent file storage under `~/fortisai-dev/vault/file`.
- Traefik entrypoint: `http://127.0.0.1:18000`
- Traefik dashboard: `http://127.0.0.1:18088/dashboard/`
- Traefik logs: `.\fortisai-dev-helper.ps1 logs traefik`
- CodeIndexer OpenAPI bridge: `http://127.0.0.1:8096/openapi.json`
- CodeIndexer logs: `.\fortisai-dev-helper.ps1 logs codeindexer`
- Milvus health: `http://127.0.0.1:19091/healthz`
- Milvus logs: `.\fortisai-dev-helper.ps1 logs milvus`
- OpenMetadata URL: `http://127.0.0.1:18585`
- OpenMetadata logs: `.\fortisai-dev-helper.ps1 logs openmetadata`
- OpenSearch URL: `http://127.0.0.1:9200`
- OpenSearch logs: `.\fortisai-dev-helper.ps1 logs opensearch`
- `codeindexer-up`, `openmetadata-up`, and `traefik-up` manage these standalone operator components individually; `all-up` runs the Linux-parity sequence: CodeIndexer, OpenMetadata, MCP OpenAPI bridges, OpenClaw, Hermes, Daytona, and Traefik.
- Firecrawl URL: `http://127.0.0.1:3002`
- Firecrawl logs: `.\fortisai-dev-helper.ps1 logs firecrawl`
- Firecrawl default API key: `fortisai-firecrawl-dev-api-key` (`FIRECRAWL_API_KEY`)
- Firecrawl is started/stopped by default helper lifecycle (`up` / `down`); dedicated `firecrawl-up` / `firecrawl-down` commands were removed.
- Firecrawl is wired to shared pgvector, RabbitMQ, and Redis (`NUQ_DATABASE_URL`, `NUQ_RABBITMQ_URL`, `REDIS_URL`, `REDIS_EVICT_URL`, `REDIS_RATE_LIMIT_URL`).
- Helper startup auto-creates Firecrawl DB (`FIRECRAWL_DB_NAME`, default `firecrawl`) and applies upstream NUQ schema before Firecrawl launch.
- Override NUQ schema source with `FIRECRAWL_NUQ_SQL_URL` when needed.
- pgvector endpoint: `127.0.0.1:5432`
- pgvector default DSN: `postgresql://fortisai:fortisai@127.0.0.1:5432/fortisai`
- pgvector logs: `.\fortisai-dev-helper.ps1 logs pgvector`
- Honcho URL: `http://127.0.0.1:8010`
- Honcho logs: `.\fortisai-dev-helper.ps1 logs honcho`
- Honcho uses shared pgvector and Redis (`DB_CONNECTION_URI`, `CACHE_URL`) and runs API + deriver services.
- Honcho uses dedicated database `honcho` on shared pgvector by default (`HONCHO_DB=honcho`).
- Helper startup auto-creates the Honcho database before Honcho services start.
- Honcho requires an LLM provider key; helper default is `HONCHO_LLM_OPENAI_API_KEY=lmstudio`.
- OpenClaw URL: `http://127.0.0.1:18789`
- OpenClaw logs: `.\fortisai-dev-helper.ps1 logs openclaw`
- OpenClaw shell: `.\fortisai-dev-helper.ps1 openclaw-shell`
- Start OpenClaw separately: `.\fortisai-dev-helper.ps1 openclaw-up`
- Stop OpenClaw separately: `.\fortisai-dev-helper.ps1 openclaw-down`
- OpenClaw gateway + bridge ports: `18789` and `18790`
- `openclaw-up` prepares only the OpenClaw runtime, starts Vault, and runs `vault-unseal` before launching OpenClaw.
- `openclaw-down` stops OpenClaw only; Vault remains available as a shared local service.
- OpenClaw uses helper-generated config at `~/fortisai-dev/claw-gateway/fortisai-claw-gateway.json`.
- OpenClaw is pre-wired to Honcho using `@honcho-ai/openclaw-honcho` plugin config.
- OpenClaw is pre-wired to the FortisAI proxy using OpenAI-compatible base URL `http://fortisai-mcp-openapi-dify:8093/v1` and model `fortisai`. Override `OPENCLAW_LMSTUDIO_BASE_URL` and `OPENCLAW_LMSTUDIO_MODEL` only when intentionally using LM Studio or another provider.
- OpenClaw helper-managed secrets use Vault paths under `secret/fortisai/dev/claw-gateway/`.
- OpenWebUI defaults to Hermes via `OPENAI_API_BASE_URL=http://fortisai-hermes.fortisai.local:8642/v1` when CoreDNS is active and `http://fortisai-hermes:8642/v1` otherwise.
- To route OpenWebUI to OpenClaw, set `OPENWEBUI_LLM_BACKEND=openclaw` before running helper commands.
- OpenWebUI shell: `.\fortisai-dev-helper.ps1 openwebui-shell`
- OpenVSCode per-user startup: `$env:OPENVSCODE_USERS="lester:13000 alice:13001"; .\fortisai-dev-helper.ps1 openvscode-up`
- OpenVSCode user/extension commands: `openvscode-users`, `openvscode-list-extensions [user]`, `openvscode-install-extension [user] <extension-id-or-vsix>`, and `openvscode-uninstall-extension [user] <extension-id>`.
- Helper validates OpenClaw host ports to avoid default-service conflicts before startup.
- Hermes URL: `http://127.0.0.1:8642`
- Hermes health endpoint: `http://127.0.0.1:8642/health`
- Hermes logs: `.\fortisai-dev-helper.ps1 logs hermes`
- Hermes shell: `.\fortisai-dev-helper.ps1 hermes-shell`
- Stop Hermes separately: `.\fortisai-dev-helper.ps1 hermes-down`
- Hermes dashboard can be enabled with `HERMES_DASHBOARD=1` (default dashboard port `9119`).
- Hermes uses image `nousresearch/hermes-agent:latest`, keeps the image entrypoint intact, and runs `gateway run`.
- Hermes receives Honcho context via `FORTISAI_HONCHO_BASE_URL`, `FORTISAI_HONCHO_WORKSPACE_ID`, and optional `FORTISAI_HONCHO_API_KEY`.
- Hermes receives Daytona context via `FORTISAI_DAYTONA_DASHBOARD_URL` and `FORTISAI_DAYTONA_API_URL`.
- Hermes receives OpenAI-compatible model access through the FortisAI proxy by default using `OPENAI_BASE_URL=http://fortisai-mcp-openapi-dify:8093/v1` and `OPENAI_MODEL=fortisai`.
- Qdrant URL: `http://127.0.0.1:6333`
- Qdrant logs: `.\fortisai-dev-helper.ps1 logs qdrant`
- Dify uses Qdrant as the default local vector store and starts with the `qdrant` profile.
- Dify uses shared services for database/cache (`fortisai-pgvector` and `fortisai-redis`) instead of internal PostgreSQL/Redis containers.
- Generated app compose/env files include shared Vault endpoint values (`VAULT_ADDR`, `FORTISAI_VAULT_ADDR`) alongside Redis, RabbitMQ, MongoDB, and pgvector wiring where applicable.
- OpenWebUI OpenAPI templates now include repo filesystem/memory/time servers plus MCP bridges for SQLcl, n8n, Dify, CodeIndexer, debug, and optional Proxmox (`repo-filesystem-server`, `repo-memory-server`, `repo-time-server`, `mcp-sqlcl-server`, `mcp-n8n-server`, `mcp-dify-server`, `mcp-codeindexer-server`, and `mcp-proxmox-server` when configured).
- Helper `up` imports OpenWebUI tool connections and skills for `repo-filesystem-server`, `repo-memory-server`, and `repo-time-server` after the repo OpenAPI servers start. Payloads live under `Development_Environment\mcp\repo-openapi\` and use `host.containers.internal` so the OpenWebUI container can reach the host-exposed repo server ports.
- `mcp-up` imports the CodeIndexer OpenWebUI tool/skill payloads when OpenWebUI admin access is available.
- Refresh OpenWebUI OpenAPI templates with `.\fortisai-dev-helper.ps1 setup`, then run `.\fortisai-dev-helper.ps1 mcp-up` before OpenWebUI tool import.
- Oracle Node API URL: `http://127.0.0.1:8090`
- Oracle Node API logs: `.\fortisai-dev-helper.ps1 logs oracle-node-api`
- Install APEX workflow (optional): `.\fortisai-dev-helper.ps1 apex-install`
- Check APEX status + endpoint: `.\fortisai-dev-helper.ps1 apex-check`
- Reset APEX runtime without uninstall: `.\fortisai-dev-helper.ps1 apex-reset`
- APEX URL after install: `http://127.0.0.1:8181/ords/apex`

If you pull the image for the first time, sign in to Oracle Container Registry before running the helper:

- https://container-registry.oracle.com/ords/ocr/ba/database/free

For token-based automated OCR login, set `OCR_USERNAME` and `OCR_AUTH_TOKEN` before running `oracle-db-pull` or `up`.

## Optional Daytona OSS (Self-Hosted)

Daytona is available as an optional local self-hosted stack.

- It runs as a separate compose project from Dify, n8n, and OpenWebUI.
- It is intentionally not started by the default `up` command.
- `.\fortisai-dev-helper.ps1 daytona-up` now prefers Docker Compose for runner stability and falls back to Podman compose only when Docker Compose is unavailable.
- Default dashboard URL is `http://localhost:3300` to avoid conflict with OpenWebUI on `3000`.
- Default dashboard login (Dex static user, defined in `$HOME\fortisai-dev\daytona\docker\dex\config.yaml`):
  - **Email:** `dev@daytona.io`
  - **Password:** `password`
  - To change credentials: `.\fortisai-dev-helper.ps1 daytona-set-admin-creds <new-email> <new-password>` then restart the stack.
- For preview URL wildcard routing, run Daytona DNS setup after repo initialization:
  - `cd $HOME\fortisai-dev\daytona`
  - `./scripts/setup-proxy-dns.sh`

## Runtime Fixes (2026-05-24)

- Shared network creation is now idempotent; existing `fortisai-dev-net` no longer fails setup/up.
- Firecrawl startup stabilization includes NUQ schema bootstrap and explicit shared Redis wiring.

## Local Config Templates

- `../templates/dify/app-template.yaml`
  Starter Dify app YAML for local customization.

- `../templates/n8n/workflow-template.json`
  Starter n8n workflow JSON for local customization.

## Recommended Reading Order

1. [WINDOWS_DEV_SETUP_DIFY_N8N_OPENWEBUI.md](WINDOWS_DEV_SETUP_DIFY_N8N_OPENWEBUI.md)
2. [LM_STUDIO_SETUP_WINDOWS.md](LM_STUDIO_SETUP_WINDOWS.md)
3. [GIT_IMPORT_EXPORT_DIFY_N8N_WINDOWS.md](GIT_IMPORT_EXPORT_DIFY_N8N_WINDOWS.md)
4. [fortisai-dev-helper.ps1](fortisai-dev-helper.ps1)

For Linux setup, see [../linux/README.md](../linux/README.md).

## Smoke-Test Checklist

Use this checklist on a Windows machine after first-time setup.

1. Open PowerShell and allow script execution for the current process:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

2. Move to helper directory:

```powershell
cd C:\Users\<your-user>\Desktop\FortisAI\Development_Environment\windows
```

3. Verify prerequisites are installed:

```powershell
podman version
podman compose version
git --version
oci --version
jq --version
```

4. Verify helper command discovery:

```powershell
.\fortisai-dev-helper.ps1 help
```

Expected result: usage output with commands like `setup`, `up`, `check`, and `validate-prod`.

5. Initialize local runtime artifacts:

```powershell
.\fortisai-dev-helper.ps1 setup
```

Expected result:

- Podman machine starts successfully
- n8n and OpenWebUI compose files are generated
- Dify repository is cloned to `$HOME\fortisai-dev\dify` (or existing clone is reused)

6. Start services and verify health:

```powershell
.\fortisai-dev-helper.ps1 up
.\fortisai-dev-helper.ps1 status
.\fortisai-dev-helper.ps1 check
```

Expected result:

- `fortisai-n8n` and `fortisai-openwebui` containers are running
- `fortisai-ords` and `fortisai-sqlcl` containers are running
- Dify stack containers are running from `$HOME\fortisai-dev\dify\docker`
- HTTP checks respond for localhost ports `5678`, `3000`, `18081`, and `8181`

7. Verify logs command per target:

```powershell
.\fortisai-dev-helper.ps1 logs n8n
```

Repeat for `openwebui` and `dify` and confirm logs stream without script errors.
Repeat for `ords` and `sqlcl` and confirm logs stream without script errors.

8. Verify APEX install/reset workflow:

```powershell
.\fortisai-dev-helper.ps1 apex-install
.\fortisai-dev-helper.ps1 apex-check
curl.exe -I http://127.0.0.1:8181/ords/apex
curl.exe -I "http://127.0.0.1:8181/ords/f?p=4550"
.\fortisai-dev-helper.ps1 apex-reset
.\fortisai-dev-helper.ps1 apex-check
```

Expected result:

- `apex-install` completes without script errors
- `apex-check` reports `apex install status: installed`
- APEX endpoints return redirect/OK responses (typically `HTTP 302`)
- `apex-reset` completes and APEX remains reachable after reset

9. Verify config-repo scaffolding:

```powershell
.\fortisai-dev-helper.ps1 scaffold-config-repos
```

Expected result:

- `$HOME\fortisai-dev\config-repos\dify-config` exists
- `$HOME\fortisai-dev\config-repos\n8n-config` exists
- both directories are initialized as Git repositories

10. Verify production template + validation flow:

```powershell
.\fortisai-dev-helper.ps1 prod-template
Copy-Item "$HOME\fortisai-dev\.prod-link.env.example" "$HOME\fortisai-dev\.prod-link.env"
.\fortisai-dev-helper.ps1 validate-prod
```

Expected result: validation fails with clear missing-value messages until required IDs and private IP values are filled.

11. Shutdown validation:

```powershell
.\fortisai-dev-helper.ps1 down
.\fortisai-dev-helper.ps1 status
```

Expected result: services stop cleanly and no target app containers remain running.
