# FortisAI Development Environment URLs

This document lists all URLs started by the FortisAI development environment for macOS, Windows, and Linux, as provisioned by the helper scripts. macOS and Windows services run on the shared `fortisai-dev-net` network unless otherwise noted. Linux services use `fortisai-calico-net` when the Calico/CoreDNS deployment is present and otherwise fall back to `fortisai-dev-net`.

Helper command examples are shown relative to their platform directories: `Development_Environment/mac`, `Development_Environment/windows`, or `Development_Environment/linux`.

Linux multi-host service names use CoreDNS on `fortisai-calico-net` after `linux/deploy-calico-network.sh` or `./linux/fortisai-dev-helper.sh calico-up`. Same-host lookups return local container IPs. Cross-host lookups return the owning host's LAN IP for containers with LAN-reachable published ports, so services can use names such as `http://fortisai-llama-server.fortisai.local:8011/v1` from another active host. Rootless Podman container IPs are not directly routed across hosts.

---

## Core Service URLs

| Service         | URL                                 | Description                        |
|-----------------|--------------------------------------|------------------------------------|
| Dify            | http://localhost:18081/             | Dify web UI                        |
| Traefik | http://127.0.0.1:18000/            | FortisAI load-balanced web entrypoint |
| Traefik Dashboard | http://127.0.0.1:18088/dashboard/ | Traefik dashboard/API with helper-managed basic auth |
| OpenAPI Filesystem | http://127.0.0.1:8081/           | OpenAPI tool server (filesystem)   |
| OpenAPI Memory  | http://127.0.0.1:8082/             | OpenAPI tool server (memory)       |
| OpenAPI Time    | http://127.0.0.1:8083/             | OpenAPI tool server (time)         |
| FortisAI LLM Proxy | http://127.0.0.1:8093/v1        | OpenAI-compatible `fortisai` endpoint with Honcho memory lookup/writeback; Hermes also uses its Anthropic Messages compatibility route |
| Proxmox MCP OpenAPI (opt) | http://127.0.0.1:8095/openapi.json | FortisAI ProxmoxMCP-Plus local facade |
| CodeIndexer MCP OpenAPI | http://127.0.0.1:8096/openapi.json | FortisAI CodeIndexer semantic code-search bridge |
| Websearch MCP OpenAPI | http://127.0.0.1:8097/openapi.json | FortisAI Firecrawl web search bridge |
| Honcho          | http://127.0.0.1:8010/              | Honcho memory API (`/health`, `/docs`) |
| OpenClaw        | http://127.0.0.1:18789/             | OpenClaw gateway/control UI endpoint |
| Hermes Agent    | http://127.0.0.1:8642/              | Hermes gateway API (`/health`) |
| Llama Server Primary (Linux) | http://127.0.0.1:8011/    | OpenAI-compatible llama.cpp router used by the FortisAI proxy |
| Llama Server Secondary (Linux) | http://127.0.0.1:8012/  | Direct OpenAI-compatible support-tool endpoint for Honcho and CodeIndexer |
| Firecrawl       | http://127.0.0.1:3002/              | Firecrawl crawling/scraping API (`/v0/health/liveness`, `/v0/health/readiness`) |
| Redis           | redis://127.0.0.1:6379             | Shared cache/pubsub service        |
| RabbitMQ        | amqp://fortisai:fortisai@127.0.0.1:5672 | Shared message broker service      |
| RabbitMQ Mgmt   | http://127.0.0.1:15672/            | RabbitMQ management UI/API         |
| HashiCorp Vault | http://127.0.0.1:8200/             | Persistent local secret store      |
| pgvector        | postgresql://fortisai:fortisai@127.0.0.1:5432/fortisai | Shared PostgreSQL + vector extension service |
| Qdrant          | http://127.0.0.1:6333/             | Shared vector database for Dify and n8n |
| Milvus          | http://127.0.0.1:19091/healthz     | CodeIndexer vector database health endpoint |
| OpenMetadata    | http://127.0.0.1:18585/            | OpenMetadata UI/API |
| OpenSearch      | http://127.0.0.1:9200/             | OpenMetadata search backend |
| n8n             | http://localhost:5678/              | n8n workflow automation            |
| OpenWebUI       | http://localhost:3000/              | OpenWebUI chat interface           |
| OpenVSCode      | http://localhost:13000/             | OpenVSCode Server browser IDE; each platform helper supports one instance per configured user. On Linux, use `./linux/fortisai-dev-helper.sh openvscode-token [user]` to print the tokenized browser URL. Cline/Continue settings are stored under the helper-managed persistent OpenVSCode home volume. |
| Appsmith        | http://localhost:18080/             | Appsmith low-code UI builder       |
| MongoDB         | mongodb://127.0.0.1:27017/appsmith?replicaSet=rs0 | Shared MongoDB service (Appsmith primary DB) |
| Oracle Node API | http://127.0.0.1:8090/              | Node.js REST/WS Oracle tooling API |
| Oracle ORDS     | http://127.0.0.1:8181/ords/         | Oracle REST Data Services (ORDS)   |
| Oracle APEX (opt) | http://127.0.0.1:8181/ords/apex   | APEX app builder and runtime (after `apex-install`) |
| Oracle DB       | localhost:1521                      | Oracle DB listener (SQL*Net)       |
| Daytona (opt)   | http://localhost:3300/              | Daytona OSS dashboard (optional)   |

Firecrawl exposes public liveness/readiness at `/v0/health/liveness` and `/v0/health/readiness`; the current image does not expose a public `/health` route.


---

## Oracle Database Details

- **Default PDB:** `FREEPDB1`
- **Default credentials:** `pdbadmin` / `FortisAI26ai!2026`
- **SQLcl shell:**
  - macOS: `./fortisai-dev-helper.sh sqlcl-shell`
  - Windows: `.\fortisai-dev-helper.ps1 sqlcl-shell`
  - Linux: `./fortisai-dev-helper.sh sqlcl-shell`
- **SQLcl MCP server:**
  - macOS: `./fortisai-dev-helper.sh sqlcl-mcp`
  - Windows: `.\fortisai-dev-helper.ps1 sqlcl-mcp`
  - Linux: `./fortisai-dev-helper.sh sqlcl-mcp`
  - macOS smoke: `./fortisai-dev-helper.sh sqlcl-mcp-smoke`
  - Windows smoke: `.\fortisai-dev-helper.ps1 sqlcl-mcp-smoke`
  - Linux smoke: `./fortisai-dev-helper.sh sqlcl-mcp-smoke`
  - Generated MCP config: `~/fortisai-dev/sqlcl-mcp/mcp.json`
- **APEX helper workflow:**
  - macOS install: `./fortisai-dev-helper.sh apex-install`
  - Windows install: `.\fortisai-dev-helper.ps1 apex-install`
  - Linux install: `./fortisai-dev-helper.sh apex-install`
  - macOS check: `./fortisai-dev-helper.sh apex-check`
  - Windows check: `.\fortisai-dev-helper.ps1 apex-check`
  - Linux check: `./fortisai-dev-helper.sh apex-check`
  - macOS reset: `./fortisai-dev-helper.sh apex-reset`
  - Windows reset: `.\fortisai-dev-helper.ps1 apex-reset`
  - Linux reset: `./fortisai-dev-helper.sh apex-reset`

---

## Default Credentials and Passwords

This section lists the defaults used to seed helper-generated local services. After the first Vault-backed startup, helper-managed passwords and API keys are resolved from `secret/fortisai/dev/*`; exported environment values seed or rotate Vault, and missing values fall back to these local development defaults.

| Component | Username / Identity | Default Password / Key | Notes |
|-----------|----------------------|-------------------------|-------|
| Oracle DB (PDB) | `pdbadmin` | `FortisAI26ai!2026` | Derived from `ORACLE_DB_USER` / `ORACLE_DB_PASSWORD` defaults. |
| APEX Admin | `ADMIN` | `FortisAI26ai!2026` | Defaults to `APEX_ADMIN_PASSWORD`, which defaults to `ORACLE_DB_PASSWORD`. |
| ORDS DB User | `ORDS_PUBLIC_USER` | `FortisAI26ai!2026` | Defaults to `ORDS_DB_PASSWORD`, which defaults to `ORACLE_DB_PASSWORD`. |
| n8n Basic Auth | `admin` | `change-me-n8n` | Helper-generated n8n compose default. |
| Qdrant API | `api-key` header | `difyai123456` | Used by Dify and available for n8n workflows. |
| Shared pgvector | `fortisai` | `fortisai` | Defaults from `PGVECTOR_USER` / `PGVECTOR_PASSWORD`. |
| Honcho DB (inside shared pgvector) | `honcho` | n/a | Dedicated database name defaults from `HONCHO_DB` and is auto-created by helper startup. |
| Shared Redis | n/a | none by default | Helper-managed shared Redis does not set a password by default. |
| Shared RabbitMQ | `fortisai` | `fortisai` | Helper-managed shared RabbitMQ defaults (`RABBITMQ_DEFAULT_USER` / `RABBITMQ_DEFAULT_PASSWORD`). |
| HashiCorp Vault | root token + unseal key | generated by `vault-init` | Stored locally at `~/fortisai-dev/vault/vault-init.json`; do not commit or reuse outside local development. |
| Honcho LLM and embeddings provider | `LLM_OPENAI_API_KEY` | `lmstudio` | Set from helper variable `HONCHO_LLM_OPENAI_API_KEY`; on Linux Honcho defaults to local model `qwen__Qwen_Qwen2.5-1.5B-Instruct-GGUF__qwen2.5-1.5b-instruct-q4_0` through the secondary llama-server `/v1` endpoint. Message embeddings are enabled by default and use the same secondary `/v1/embeddings` endpoint with 1536-dimensional vectors. |
| OpenClaw gateway auth | token | `fortisai-claw-gateway-dev-token` | Set from helper variable `OPENCLAW_GATEWAY_TOKEN`; used by OpenWebUI OpenAI-compatible integration. |
| OpenClaw model provider | `OPENAI_API_KEY` | `local-llama` | Helper-generated OpenClaw config points to the FortisAI proxy `http://fortisai-mcp-openapi-dify.fortisai.local:8093/v1` and model `fortisai` by default. |
| Dify/n8n Llama endpoint | `FORTISAI_LLAMA_OPENAI_API_KEY` | `local-llama` | Helper-generated Dify and n8n runtime env for the primary local OpenAI-compatible llama endpoint used by the FortisAI proxy/router path. |
| Traefik Dashboard | `fortisai` | generated/stored in Vault | Basic auth password lives at `secret/fortisai/dev/traefik/dashboard_password`. |
| CodeIndexer embeddings | `CODEINDEXER_OPENAI_API_KEY` | `local-llama` | On Linux CodeIndexer uses the secondary llama-server OpenAI-compatible embedding endpoint and Milvus. |
| Milvus MinIO | `minioadmin` | `minioadmin` unless rotated | Helper stores the MinIO password in Vault for local CodeIndexer storage. |
| OpenMetadata Fernet key | n/a | generated/stored in Vault | Used by OpenMetadata and stored under `secret/fortisai/dev/openmetadata/fernet_key`. |
| Firecrawl API | `FIRECRAWL_API_KEY` | `fortisai-firecrawl-dev-api-key` | Used by helper-generated Firecrawl container and passed to OpenClaw/Hermes runtime env. |
| Hermes API server | `API_SERVER_KEY` | `fortisai-hermes-dev-api-key` | Set from helper variable `HERMES_API_SERVER_KEY`; local-dev default only. |
| Dify Console | created at first login | no fixed default | Create admin account on first run; Dify data/cache backends use shared pgvector/Redis defaults above. |
| OpenWebUI | created at first login | no fixed default | `ENABLE_SIGNUP=true` by default. |
| OpenVSCode Server | connection token | `fortisai-openvscode-dev-token` | Override via `OPENVSCODE_CONNECTION_TOKEN`; platform helpers store per-user token files under `~/fortisai-dev/openvscode/users/<user>/connection-token`. Linux can print a usable URL with `openvscode-token [user]`, defaults each user workspace to `~/openvscode/<user>/workspace`, and mounts a persistent per-user container home at `/home/workspace` so Cline/Continue settings remain writable and survive restarts. Use a localhost tunnel or HTTPS route for Cline/Continue webview settings panels; direct remote HTTP may not provide a secure browser context. |
| Appsmith | created at first login | no fixed default | First-run account is set in UI. |
| Daytona Dashboard (optional) | `dev@daytona.io` | `password` | Dex static user default; configurable via helper command. |
| OCI OCR login (optional) | `OCR_USERNAME` | `OCR_AUTH_TOKEN` | No default value; required only for token-based OCR authentication flow. |

Security note: all defaults above are for local development only. Rotate or override these values before using any shared or non-local environment.

---

## Vault-Managed Runtime Secrets

Helper commands start and unseal Vault before component startup, then sync and verify the required runtime secrets. Components receive `VAULT_ADDR`, `FORTISAI_VAULT_ADDR`, and a helper-created read-only `VAULT_TOKEN` for `secret/fortisai/dev/*`.

Primary local paths include:

- `secret/fortisai/dev/n8n/basic_auth_password`
- `secret/fortisai/dev/oracle/db_password`, `oracle/ords_db_password`, and `oracle/apex_admin_password`
- `secret/fortisai/dev/rabbitmq/default_password`
- `secret/fortisai/dev/pgvector/password`
- `secret/fortisai/dev/qdrant/api_key`
- `secret/fortisai/dev/openvscode/connection_token`
- `secret/fortisai/dev/appsmith/betterbugs_api_key`
- `secret/fortisai/dev/honcho/llm_openai_api_key`
- `secret/fortisai/dev/claw-gateway/gateway_token` and `claw-gateway/openai_api_key`
- `secret/fortisai/dev/hermes/api_server_key`
- `secret/fortisai/dev/firecrawl/api_key`
- `secret/fortisai/dev/dify/app_api_key`, `dify/knowledge_api_key`, and `dify/api_key`
- `secret/fortisai/dev/dify/admin_api_key` and `dify/console_access_token` when operator-provided
- `secret/fortisai/dev/n8n/api_key` when operator-provided or loaded from helper MCP config
- `secret/fortisai/dev/proxmox/host`, `proxmox/user`, `proxmox/token_name`, `proxmox/token_value`, `proxmox/openapi_api_key`, and `proxmox/openapi_update_key` when Proxmox MCP is configured
- `secret/fortisai/dev/traefik/dashboard_password`
- `secret/fortisai/dev/codeindexer/openai_api_key` and `codeindexer/milvus_token`
- `secret/fortisai/dev/milvus/minio_root_password`
- `secret/fortisai/dev/openmetadata/fernet_key`
- `secret/fortisai/dev/vault/service_token`

Optional operator-provided values such as `N8N_API_KEY`, `OPENWEBUI_BEARER_TOKEN`, `OCR_AUTH_TOKEN`, `DAYTONA_API_KEY`, `DIFY_ADMIN_API_KEY`, `DIFY_CONSOLE_ACCESS_TOKEN`, and Proxmox MCP token values are stored when exported, but are not generated by default. The n8n workflow importer reads `N8N_API_KEY` from `secret/fortisai/dev/n8n/api_key` for public API activation and falls back to local n8n CLI activation if API activation is unavailable.

### Manipulating Keys and Secrets

Use the helper workflow for normal local development changes. Export the value you want to seed or rotate, then run the helper startup command for your platform from its platform directory. The helper starts and unseals Vault, writes exported values into `secret/fortisai/dev/*`, reloads existing Vault values for anything not exported, and verifies required paths before dependent services start.

macOS/Linux example:

```bash
export FIRECRAWL_API_KEY='replace-with-local-value'
export HERMES_API_SERVER_KEY='replace-with-local-value'
./fortisai-dev-helper.sh up
```

Windows PowerShell example:

```powershell
$env:FIRECRAWL_API_KEY = 'replace-with-local-value'
$env:HERMES_API_SERVER_KEY = 'replace-with-local-value'
.\fortisai-dev-helper.ps1 up
```

For direct Vault operations, use the local root token from `~/fortisai-dev/vault/vault-init.json`. Do not paste token values into docs, tickets, chat, or shell output.

List local development secret folders:

```bash
ROOT_TOKEN="$(python3 -c 'import json, os; print(json.load(open(os.path.expanduser("~/fortisai-dev/vault/vault-init.json"))).get("root_token", ""))')"
podman exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN="$ROOT_TOKEN" \
  fortisai-vault vault kv list secret/fortisai/dev
```

Read one value:

```bash
podman exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN="$ROOT_TOKEN" \
  fortisai-vault vault kv get -field=value secret/fortisai/dev/hermes/api_server_key
```

Write or rotate one value:

```bash
read -rsp "New value: " SECRET_VALUE; echo
podman exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN="$ROOT_TOKEN" \
  fortisai-vault vault kv put secret/fortisai/dev/hermes/api_server_key value="$SECRET_VALUE"
unset SECRET_VALUE
```

Delete the current version of one secret:

```bash
podman exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN="$ROOT_TOKEN" \
  fortisai-vault vault kv delete secret/fortisai/dev/hermes/api_server_key
```

Permanently remove all versions and metadata for one secret:

```bash
podman exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN="$ROOT_TOKEN" \
  fortisai-vault vault kv metadata delete secret/fortisai/dev/hermes/api_server_key
```

PowerShell direct-operation pattern:

```powershell
$init = Get-Content "$HOME\fortisai-dev\vault\vault-init.json" | ConvertFrom-Json
podman exec -e "VAULT_ADDR=http://127.0.0.1:8200" -e "VAULT_TOKEN=$($init.root_token)" `
  fortisai-vault vault kv list secret/fortisai/dev
```

After changing a secret directly in Vault, run the appropriate helper startup command again so generated compose/env files and running containers pick up the value. Some database passwords are also stored inside the database engine after first initialization; changing only the Vault value does not change an already-initialized database user's password.

For direct helper-managed secret changes, use `vault-read`, `vault-write`, and `vault-del` with paths relative to `secret/fortisai/dev/`. The helper starts Vault if needed, unseals it from the saved local init JSON, and changes only the requested path. `vault-del` permanently removes the secret metadata and all versions for that path.

macOS/Linux examples:

```bash
./fortisai-dev-helper.sh vault-write hermes/api_server_key "$SECRET_VALUE"
./fortisai-dev-helper.sh vault-read hermes/api_server_key
printf '%s' "$SECRET_VALUE" | ./fortisai-dev-helper.sh vault-write hermes/api_server_key
./fortisai-dev-helper.sh vault-del hermes/api_server_key
```

Windows PowerShell examples:

```powershell
.\fortisai-dev-helper.ps1 vault-write hermes/api_server_key $env:SECRET_VALUE
.\fortisai-dev-helper.ps1 vault-read hermes/api_server_key
$env:SECRET_VALUE | .\fortisai-dev-helper.ps1 vault-write hermes/api_server_key
.\fortisai-dev-helper.ps1 vault-del hermes/api_server_key
```

Root and unseal keys are different from application secrets. They are stored in `~/fortisai-dev/vault/vault-init.json` for local development only. Rotate them with Vault operator commands if needed; do not edit that file by hand.

---

## Linux Service Cycle Validation

The Linux systemd service path on `aiengine000` was validated with `sudo systemctl restart fortisai.service`; the Calico/CoreDNS network path was refreshed on 2026-06-21.

- The service completed its configured `all-down` and `all-up` path.
- Vault started and unsealed before dependent services.
- The monitor reads stable required containers from `linux/active_host.json`.
- The Calico/CoreDNS inventory is driven by `linux/active_host.json`; generated `*-infra` containers are excluded.
- Fresh-container DNS was validated on both `aiengine000` and `aiengine001`. From `aiengine001`, `fortisai-llama-server.fortisai.local` resolves to the primary host service address and reaches `/v1/models` on port `8011`.
- Final endpoint checks returned HTTP `200` for Vault, primary llama-server, secondary llama-server, FortisAI proxy, Honcho, OpenClaw, and Hermes.
- Honcho memory writeback was validated through the FortisAI proxy by writing and reading back a unique marker in Honcho `messages/list` and session `context`.

## Service Logs (Helper Commands)

| Service     | macOS Command                        | Windows Command                        | Linux Command                         |
|-------------|--------------------------------------|----------------------------------------|---------------------------------------|
| Oracle DB   | ./fortisai-dev-helper.sh logs oracle-db | .\fortisai-dev-helper.ps1 logs oracle-db | ./fortisai-dev-helper.sh logs oracle-db |
| Redis       | ./fortisai-dev-helper.sh logs redis     | .\fortisai-dev-helper.ps1 logs redis     | ./fortisai-dev-helper.sh logs redis     |
| RabbitMQ    | ./fortisai-dev-helper.sh logs rabbitmq  | .\fortisai-dev-helper.ps1 logs rabbitmq  | ./fortisai-dev-helper.sh logs rabbitmq  |
| HashiCorp Vault | ./fortisai-dev-helper.sh logs vault | .\fortisai-dev-helper.ps1 logs vault | ./fortisai-dev-helper.sh logs vault |
| Firecrawl   | ./fortisai-dev-helper.sh logs firecrawl | .\fortisai-dev-helper.ps1 logs firecrawl | ./fortisai-dev-helper.sh logs firecrawl |
| pgvector    | ./fortisai-dev-helper.sh logs pgvector  | .\fortisai-dev-helper.ps1 logs pgvector  | ./fortisai-dev-helper.sh logs pgvector  |
| Honcho      | ./fortisai-dev-helper.sh logs honcho    | .\fortisai-dev-helper.ps1 logs honcho    | ./fortisai-dev-helper.sh logs honcho    |
| OpenClaw    | ./fortisai-dev-helper.sh logs openclaw  | .\fortisai-dev-helper.ps1 logs openclaw  | ./fortisai-dev-helper.sh logs openclaw  |
| Hermes Agent| ./fortisai-dev-helper.sh logs hermes    | .\fortisai-dev-helper.ps1 logs hermes    | ./fortisai-dev-helper.sh logs hermes    |
| Llama Server | ./fortisai-dev-helper.sh logs llama-server | n/a | ./fortisai-dev-helper.sh logs llama-server |
| Llama Server Secondary | n/a | n/a | ./fortisai-dev-helper.sh logs llama-server-secondary |
| OpenVSCode  | ./fortisai-dev-helper.sh logs openvscode [user] | .\fortisai-dev-helper.ps1 logs openvscode [user] | ./fortisai-dev-helper.sh logs openvscode [user] |
| Appsmith    | ./fortisai-dev-helper.sh logs appsmith  | .\fortisai-dev-helper.ps1 logs appsmith  | ./fortisai-dev-helper.sh logs appsmith  |
| MongoDB     | ./fortisai-dev-helper.sh logs mongodb   | .\fortisai-dev-helper.ps1 logs mongodb   | ./fortisai-dev-helper.sh logs mongodb   |
| Qdrant      | ./fortisai-dev-helper.sh logs qdrant    | .\fortisai-dev-helper.ps1 logs qdrant    | ./fortisai-dev-helper.sh logs qdrant    |
| ORDS        | ./fortisai-dev-helper.sh logs ords      | .\fortisai-dev-helper.ps1 logs ords      | ./fortisai-dev-helper.sh logs ords      |
| SQLcl       | ./fortisai-dev-helper.sh logs sqlcl     | .\fortisai-dev-helper.ps1 logs sqlcl     | ./fortisai-dev-helper.sh logs sqlcl     |
| Oracle Node API | ./fortisai-dev-helper.sh logs oracle-node-api | .\fortisai-dev-helper.ps1 logs oracle-node-api | ./fortisai-dev-helper.sh logs oracle-node-api |
| Traefik | ./fortisai-dev-helper.sh logs traefik | .\fortisai-dev-helper.ps1 logs traefik | ./fortisai-dev-helper.sh logs traefik |
| CodeIndexer Bridge | ./fortisai-dev-helper.sh logs codeindexer | .\fortisai-dev-helper.ps1 logs codeindexer | ./fortisai-dev-helper.sh logs codeindexer |
| Websearch Bridge | podman logs fortisai-mcp-openapi-websearch | podman logs fortisai-mcp-openapi-websearch | podman logs fortisai-mcp-openapi-websearch |
| Milvus | ./fortisai-dev-helper.sh logs milvus | .\fortisai-dev-helper.ps1 logs milvus | ./fortisai-dev-helper.sh logs milvus |
| OpenMetadata | ./fortisai-dev-helper.sh logs openmetadata | .\fortisai-dev-helper.ps1 logs openmetadata | ./fortisai-dev-helper.sh logs openmetadata |
| OpenSearch | ./fortisai-dev-helper.sh logs opensearch | .\fortisai-dev-helper.ps1 logs opensearch | ./fortisai-dev-helper.sh logs opensearch |

---

## Container Registry (Oracle Images)

- https://container-registry.oracle.com/ords/ocr/ba/database/free

---

## Daytona OSS (Optional)

- **Dashboard:** http://localhost:3300/
- **Default login:**
  - Email: `dev@daytona.io`
  - Password: `password`
- Linux Daytona service sharing:
  - The helper-generated Linux Daytona runtime compose reuses shared `fortisai-redis` and `fortisai-pgvector` on the shared FortisAI container network through CoreDNS FQDNs instead of starting duplicate Daytona Redis/PostgreSQL/pgAdmin containers.
  - `daytona-up` creates a dedicated `daytona` database inside shared pgvector if it does not already exist.
  - `daytona-up` and `mcp-up` create the Vault-backed `fortisai-openwebui-daytona` API key when missing and store it under `secret/fortisai/dev/daytona/`; they also initialize local organization/region sandbox quotas and the GPU-aware `fortisai-ubuntu-22.04` default snapshot.
  - Daytona internal URLs use stable hyphenated network aliases such as `daytona-api`, `daytona-runner`, and `daytona-minio` to avoid stale generic Podman DNS aliases after container restarts and keep S3 hostnames valid.
  - The Linux watchdog required container list tracks Daytona-owned containers only; `daytona_db_1` and `daytona_redis_1` are intentionally absent because the shared services satisfy those roles.
  - Daytona-owned services remain separate: Dex, runner, proxy, SSH gateway, registry, MinIO, MailDev, and optional tracing components.
- GPU validation:
  - Linux: `./fortisai-dev-helper.sh daytona-gpu-check` validates NVIDIA host detection, runner `nvidia-smi`, and nested Docker CDI GPU pass-through.
  - Linux `daytona-setup` and `daytona-up` also apply the FortisAI Daytona GPU type patch; `NVIDIA GeForce GTX 1070` is normalized to `GTX-1070` so the Daytona API does not emit repeated unrecognized GPU type warnings.
  - macOS: `./fortisai-dev-helper.sh daytona-gpu-check` reports Apple Silicon GPU/Metal details and confirms Daytona containers are CPU-only.
- To change credentials:
  - macOS: `./fortisai-dev-helper.sh daytona-set-admin-creds <email> <password>`
  - Windows: `.\fortisai-dev-helper.ps1 daytona-set-admin-creds <email> <password>`
  - Linux: `./fortisai-dev-helper.sh daytona-set-admin-creds <email> <password>`

---

## Notes
- Most core URLs are accessible after running the default `up` command. OpenClaw, Hermes Agent, Daytona, and the full MCP bridge set are available through `all-up` or their dedicated lifecycle commands.
- Qdrant is started by the Dify compose stack and exposed on host ports `6333` and `6334` for local clients.
- Redis, RabbitMQ, and pgvector are started by helper `up` and stopped by helper `down`.
- HashiCorp Vault is started and unsealed before other services by helper `up`, then stopped by helper `down`. Platform helper directories (`mac/`, `windows/`, and `linux/`) are the supported operator entry points.
- Vault uses `docker.io/hashicorp/vault:latest` and persistent file storage under `~/fortisai-dev/vault/file`.
- Initialize Vault once with `vault-init`; helper commands save the local root token and unseal key to `~/fortisai-dev/vault/vault-init.json`.
- After restarting Vault separately, run `vault-unseal` to unseal it from the saved local init JSON. Full helper `up` runs this unseal step automatically after first-time init.
- Vault health returns HTTP `501` before first-time init and HTTP `503` while sealed; both indicate the Vault server is reachable.
- Containers receive `VAULT_ADDR=http://fortisai-vault.fortisai.local:8200`, `FORTISAI_VAULT_ADDR=http://fortisai-vault.fortisai.local:8200`, and the helper-created read-only `VAULT_TOKEN` during Vault-backed startup. Set `VAULT_TOKEN` yourself only when intentionally overriding the local helper token.
- Platform `mcp-up` exposes ProxmoxMCP-Plus through `http://127.0.0.1:8095/openapi.json` when configured; the helper keeps the upstream bearer-protected service internal and injects the Vault-backed Proxmox OpenAPI key from the local facade. The facade adds read-only individual VM/LXC statistics endpoints and requires the Vault-backed Proxmox update key for resource, disk, lifecycle, and other mutating actions.
- Platform helper `up` starts and verifies the OpenAPI filesystem, memory, and time tool servers as a trio. If the time server fails because a stale local image is missing Python time dependencies, the Linux helper rebuilds and recreates only `time-server`.
- Platform helper `up` also imports OpenWebUI tool connections and skills for `repo-filesystem-server`, `repo-memory-server`, and `repo-time-server`. When CoreDNS is active, OpenWebUI payloads use `*.fortisai.local` endpoints such as `http://filesystem-server.fortisai.local:8000`; when CoreDNS is inactive, the helper rewrites payloads to short service names such as `http://filesystem-server:8000`.
- Firecrawl is started by helper `up` and stopped by helper `down`.
- Dedicated `firecrawl-up`/`firecrawl-down` helper commands were removed; use default lifecycle commands.
- Firecrawl is wired to shared pgvector, RabbitMQ, and Redis on the selected shared network.
- Firecrawl startup ensures DB bootstrap (`FIRECRAWL_DB_NAME`, default `firecrawl`) and applies upstream NUQ schema from `FIRECRAWL_NUQ_SQL_URL`.
- Firecrawl Redis overrides: `FIRECRAWL_REDIS_URL`, `FIRECRAWL_REDIS_EVICT_URL`, `FIRECRAWL_REDIS_RATE_LIMIT_URL`.
- Honcho (`api` + `deriver`) is started by helper `up` and stopped by helper `down`.
- Honcho is wired to shared pgvector and Redis (`DB_CONNECTION_URI`, `CACHE_URL`) on the selected shared network.
- Honcho uses a dedicated database (`HONCHO_DB`, default `honcho`) within the shared pgvector service to avoid migration-history collisions.
- Helper startup ensures the dedicated Honcho database exists before Honcho services are started.
- Dedicated `honcho-up` and `honcho-down` commands are available when only the Honcho API/deriver pair needs to be regenerated or restarted.
- The FortisAI LLM proxy at `http://127.0.0.1:8093/v1` requires Honcho for chat/completion/responses requests. Flow is `client -> FortisAI proxy -> Honcho memory lookup -> model classification/routing -> selected llama-server model -> Honcho writeback`.
- The proxy identifies users from the OpenAI `user` field, metadata fields, `X-FortisAI-User`, `X-User-ID`, OpenWebUI user headers, or a hashed authorization identity. Missing identity falls back to `fortisai_default_user`.
- Honcho memory for the proxy uses workspace `fortisai`, assistant peer `assistant_fortisai_proxy`, and default memory model `qwen__Qwen_Qwen2.5-1.5B-Instruct-GGUF__qwen2.5-1.5b-instruct-q4_0`.
- Honcho message embeddings are enabled by default (`HONCHO_EMBED_MESSAGES=true`). The helper sets the embedding provider to the secondary llama-server OpenAI-compatible endpoint, uses `HONCHO_EMBEDDING_MODEL` (default `FORTISAI_HONCHO_MODEL`), writes 1536-dimensional vectors, and stores message embeddings in Honcho's `message_embeddings` table.
- OpenClaw is managed by dedicated helper commands and is not part of default `up`/`down`; `openclaw-up` still starts and unseals Vault before launching OpenClaw.
  - macOS: `./fortisai-dev-helper.sh openclaw-up` and `./fortisai-dev-helper.sh openclaw-down`
  - Windows: `.\fortisai-dev-helper.ps1 openclaw-up` and `.\fortisai-dev-helper.ps1 openclaw-down`
  - Linux: `./fortisai-dev-helper.sh openclaw-up` and `./fortisai-dev-helper.sh openclaw-down`
- `openclaw-up` uses an OpenClaw-only setup path, starts Vault, and runs `vault-unseal` before launching OpenClaw.
- `openclaw-down` stops OpenClaw only; it does not stop shared Vault.
- OpenClaw uses host ports `18789` (gateway) and `18790` (bridge) by default and validates they do not collide with other default service ports.
- Llama router uses `llama-router-up`, `llama-router-switch`, and `llama-router-down` on Linux helper; it mounts `LLAMA_MODELS_DIR`, defaulting to `/db/AI/llm_directory` on Linux when present and otherwise `Development_Environment/llm_directory`, and serves the primary OpenAI-compatible endpoint on `http://127.0.0.1:8011`.
- Secondary llama router uses `llama-secondary-up`, `llama-secondary-switch`, and `llama-secondary-down`; it serves the direct support-tool OpenAI-compatible endpoint on `http://127.0.0.1:8012` and now defaults to `--parallel 1`, `--models-max 2`, `--ctx-size 8192`, `--batch-size 4096`, and `--ubatch-size 4096` so Honcho/support-tool embeddings and RAG web-result chunks have a larger physical batch window.
- Honcho message embeddings default to `HONCHO_EMBEDDING_MAX_INPUT_TOKENS=2048` so Hermes-triggered memory writes stay inside the secondary llama-server physical batch limit.
- FortisAI OpenAI facade chat/completion flow is Honcho personal memory, Qdrant general-knowledge vector retrieval, Firecrawl web search, then the selected LLM. Public `fortisai` embedding requests use the generated monthly `embeddings` request type unless `FORTISAI_OPENAI_EMBEDDING_MODEL` is intentionally set, and Qdrant collections use exact dimension-suffixed names such as `gmail_spam_memory_d1536`. Firecrawl is attempted on every request, web results are injected into context, and usable results are queued by default for background upsert into Qdrant collections named from `FORTISAI_RAG_QDRANT_COLLECTION` with an embedding-dimension suffix. The helper sets `FORTISAI_OPENAI_ROUTER_DEFAULT_MAX_TOKENS=1536` for clients that omit output caps, and FortisAI response metadata includes stage timings plus `web_upsert_status` for diagnosis.
- Linux `fortisai-llama-server` starts with a default Podman memory and swap limit of `28g`; the secondary defaults to the same limit. The primary default `LLAMA_SERVER_EXTRA_ARGS` disables llama.cpp prompt-cache RAM with `--cache-ram 0 --no-cache-idle-slots` to avoid repeated SWA/hybrid checkpoint eviction warnings and full prompt reprocessing, and limits primary reasoning with `--reasoning auto --reasoning-budget 512` so tool-capable clients can reason briefly without long planning traces. Override `LLAMA_SERVER_EXTRA_ARGS`, `LLAMA_SERVER_MEMORY_LIMIT`, `LLAMA_SERVER_MEMORY_SWAP_LIMIT`, `LLAMA_SECONDARY_SERVER_MEMORY_LIMIT`, or `LLAMA_SECONDARY_SERVER_MEMORY_SWAP_LIMIT` only when intentionally changing the Linux runtime envelope.
- Linux model maintenance runs in `fortisai_monitor.service`: `model_update.py run-once` can be used for an immediate monthly download pass, using one Hugging Face worker, excluding `mmproj`/`BF16`/`FP16` artifacts by default, and timing out stuck provider downloads after 900 seconds; `test_llama_models.py` validates the refreshed direct `LLAMA_MODELS_DIR` model list with a slow-load retry and hard wall-clock request timeout, quarantines unloadable/support/high-precision models by renaming `.gguf` files to `.gguf.disable...`, writes `disabled_models.json` in the selected `LLAMA_MODELS_DIR`, and restarts the llama router so `/v1/models` reflects disabled files. Manual validation can resume from a known model with `LLAMA_START_AT_MODEL=<model-id>`.
- OpenClaw defaults to the FortisAI proxy backend `http://fortisai-mcp-openapi-dify.fortisai.local:8093/v1` with model `fortisai`. Override `OPENCLAW_LMSTUDIO_BASE_URL` and `OPENCLAW_LMSTUDIO_MODEL` only when intentionally pointing OpenClaw to LM Studio or another OpenAI-compatible provider.
- Honcho defaults to the secondary llama-server endpoint and the selected `FORTISAI_HONCHO_MODEL`; the Linux default is the lightweight Qwen 1.5B Q4 model so support-tool memory and embedding calls do not contend with the primary router or cold-load large models.
- Dify and n8n receive `FORTISAI_LLAMA_SERVER_BASE_URL` / `FORTISAI_LLAMA_OPENAI_BASE_URL` for local model calls. Linux uses `http://fortisai-llama-server.fortisai.local:8011/v1`; macOS and Windows use `http://host.docker.internal:8011/v1` by default and can override either variable before helper setup.
- macOS full `all-up` validation requires more than the default small Podman VM on Apple Silicon. Use 24 GB memory when host RAM permits: `podman machine stop podman-machine-default`, `podman machine set --memory 24576 podman-machine-default`, then `podman machine start podman-machine-default`.
- On Linux with Podman, Dify validation and startup use helper-generated `~/fortisai-dev/dify/docker/docker-compose.podman.yaml` so podman-compose 1.0.6 gets explicit network and named-volume definitions.
- On Linux rootless Podman hosts, Dify API/sandbox, Daytona API/proxy/dex/runner, and Oracle DB container-level healthchecks are disabled intentionally. The helper uses bounded Podman readiness, direct HTTP probes, and Oracle-specific validation instead; this avoids stale `podman healthcheck run` processes holding runtime locks.
- aiengine000 requires persistent `aiuser` user-manager limits for rootless Podman: `TasksMax=infinity`, `LimitNPROC=infinity`, and `LimitNOFILE=1048576` through systemd/PAM drop-ins. If `/var/log/syslog` shows `setrlimit 'RLIMIT_NPROC': Operation not permitted`, reapply those drop-ins and restart the `aiuser` user manager or host.
- Linux OpenSearch uses the image-supported `DISABLE_SECURITY_PLUGIN=true` setting only. Adding `plugins.security.disabled=true` as a second setting causes OpenSearch to exit during startup.
- Daytona local telemetry is disabled in the helper-generated Linux runtime (`OTEL_ENABLED=false`) unless a matching OTEL collector service is added.
- OpenClaw is wired to Honcho through `@honcho-ai/openclaw-honcho` plugin config with default base URL `http://fortisai-honcho-api.fortisai.local:8000`.
- OpenClaw receives Firecrawl integration env values via `FIRECRAWL_BASE_URL` and `FIRECRAWL_API_KEY`.
- OpenWebUI defaults to Hermes using `OPENAI_API_BASE_URL=http://fortisai-hermes.fortisai.local:8642/v1` and `OPENAI_API_KEY=$HERMES_API_SERVER_KEY`.
- OpenWebUI backend selection is controlled by `OPENWEBUI_LLM_BACKEND` (`hermes` by default, `openclaw` optional override).
- To route OpenWebUI to OpenClaw instead, set `OPENWEBUI_LLM_BACKEND=openclaw`.
- Hermes Agent is managed by dedicated helper commands and is not part of default `up`/`down`.
  - macOS: `./fortisai-dev-helper.sh hermes-up` and `./fortisai-dev-helper.sh hermes-down`
  - Windows: `.\fortisai-dev-helper.ps1 hermes-up` and `.\fortisai-dev-helper.ps1 hermes-down`
  - Linux: `./fortisai-dev-helper.sh hermes-up` and `./fortisai-dev-helper.sh hermes-down`
- Hermes uses host port `8642` for gateway API and `9119` for optional dashboard.
- Hermes dashboard is enabled by setting `HERMES_DASHBOARD=1`.
- Hermes runtime uses image `nousresearch/hermes-agent:latest` with command `gateway run`; WhatsApp startup is disabled by default through `HERMES_WHATSAPP_ENABLED=false` / `WHATSAPP_ENABLED=false`, and `hermes-up` rewrites the persisted Hermes `.env` so old paired sessions do not re-enable the adapter.
- Hermes runtime is forced to the FortisAI custom provider. Helper-generated `config.yaml` uses `provider: custom`, model `fortisai`, `base_url: http://fortisai-mcp-openapi-dify.fortisai.local:8093/v1`, and `api_mode: anthropic_messages`; the container also receives current helper-generated `OPENAI_API_KEY`, `OPENAI_BASE_URL`, and `OPENAI_API_BASE_URL` values so Hermes fallback/client-rebuild paths stay on the FortisAI proxy instead of failing with a missing API key.
- Linux Hermes defaults `HERMES_STREAM_STALE_TIMEOUT=900` so slow local model prefill/routed requests do not trigger false stale-stream reconnect loops. `hermes-up` removes stale persisted `.env` LLM/OpenRouter keys before writing the current runtime config.
- `hermes-up` rewrites the Hermes runtime config/auth store, repairs `/opt/data` permissions for the container `hermes` user (`10000:10000`), and `hermes-down` restores host read access to the generated Hermes compose and `.env` files before compose shutdown.
- Hermes runtime receives Honcho context via `FORTISAI_HONCHO_BASE_URL`, `FORTISAI_HONCHO_WORKSPACE_ID`, and optional `FORTISAI_HONCHO_API_KEY`.
- Hermes runtime receives Daytona context via `FORTISAI_DAYTONA_DASHBOARD_URL` and `FORTISAI_DAYTONA_API_URL`.
- Hermes runtime receives Firecrawl context via `FORTISAI_FIRECRAWL_BASE_URL` and `FORTISAI_FIRECRAWL_API_KEY`.
- For LM Studio with containerized Honcho, use `http://host.docker.internal:1234/v1` as `MODEL_CONFIG__OVERRIDES__BASE_URL`.
- For host-native Honcho, use `http://localhost:1234/v1` as `MODEL_CONFIG__OVERRIDES__BASE_URL`.
- Dify uses shared `fortisai-redis` and `fortisai-pgvector` services for cache/database connectivity, while `qdrant` remains the active vector profile.
- Oracle Node API is included in helper `up` and `down`, and can also run independently using `Development_Environment/oracle-node-api/docker-compose.yml`.
- Oracle Node API SQL endpoints (`/exec`, `/script`, `/ddl`, `/format`) require SQLcl sidecar availability and Podman socket access from the Oracle Node API container.
- Option 3 local runtime currently uses elevated compose settings (`privileged: true`, `security_opt: label=disable`) to allow Oracle Node API -> SQLcl stdio execution.
- ORDS is mapped to 127.0.0.1:8181 for reliability (use this instead of localhost if you encounter issues).
- ORDS may return transient `HTTP 000` or empty response during warm-up immediately after `up`; retrying after initialization should return `HTTP 302` on `/ords/` and `/ords/apex`.
- Daytona is not started by default; run the `daytona-up` command to enable.
- Appsmith is started by default with helper `up` and stopped by helper `down`.
- MongoDB is started by default with helper `up` and stopped by helper `down`.
- Helper startup initializes MongoDB replica set `rs0` before Appsmith startup.
- Helper startup starts Redis and pgvector before Appsmith so the latest Appsmith backend can resolve required cache and database services during Spring startup.
- Helper-generated Appsmith compose mounts `/tmp` as container tmpfs so Appsmith's certificate refresh and Caddy socket files do not inherit stale or broken overlay state after repeated restarts.
- Helper-generated Appsmith compose sets defensive Mongock transaction-disable variables, and MongoDB also raises the transaction lifetime because Appsmith v2.1 may still run long first-run Mongock migrations transactionally.
- Helper-generated MongoDB compose sets `transactionLifetimeLimitSeconds=3600` so Appsmith's long first-run Mongock migrations can complete without hitting MongoDB's default 60-second transaction lifetime.
- Appsmith helper wiring now sets `APPSMITH_DB_URL` and `APPSMITH_MONGODB_URI` to the shared MongoDB service by default.
- If Appsmith returns the frontend shell or "Appsmith is starting" page while `/api/v1/*` returns `502`, check `./fortisai-dev-helper.sh logs appsmith`. A `passwordResetToken.createdAt` or `passwordResetToken.email` `IndexOptionsConflict` means an older password-reset index must be dropped before the latest Appsmith migration can recreate the expected index; do not delete Appsmith data volumes.
- If Appsmith migration `updateS3DatasourceConfigurationAndLabel` fails with an empty S3 plugin lookup, recreate only the `plugin` metadata row for package `amazons3-plugin` and name `Amazon S3`; the migration will rename it to `S3` on the next start.
- If Appsmith then reports a duplicate `appsmith.config` key for `name: "instance-id"` or `name: "appsmith_registered"`, remove only that partial `config` row and restart Appsmith so the same migration can recreate it.
- Shared network bootstrap is idempotent on all helpers; existing `fortisai-dev-net` does not fail macOS/Windows startup, and Linux first verifies Calico/CoreDNS. When the Calico marker or `fortisai-calico-net` exists, CoreDNS is started and containers use `fortisai-calico-net`; otherwise Linux falls back to `fortisai-dev-net`. Linux shared-stack startup also connects any running required-container holdout to the selected shared network and refreshes CoreDNS. The Calico/CoreDNS deploy script waits for fresh-container DNS readiness before reporting completion.
- For more details, see the platform-specific README files in `mac/`, `windows/`, and `linux/`.
