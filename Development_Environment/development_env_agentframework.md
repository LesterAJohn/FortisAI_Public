# Development Environment Agent Framework

This document describes how Honcho, OpenClaw, and Hermes are deployed in the FortisAI local development environment and how other services are wired to shared components that support agent and workflow memory patterns.

## Scope

The local helper scripts now include Honcho as part of default `up` and `down` lifecycle operations:

- macOS: `Development_Environment/mac/fortisai-dev-helper.sh`
- Windows: `Development_Environment/windows/fortisai-dev-helper.ps1`
- Linux: `Development_Environment/linux/fortisai-dev-helper.sh`

Honcho runs as two services:

- `fortisai-honcho-api`
- `fortisai-honcho-deriver`

Default API endpoint:

- `http://127.0.0.1:8010`

OpenClaw runs as one service:

- `fortisai-claw-gateway`

Default gateway endpoint:

- `http://127.0.0.1:18789`

Hermes runs as one service:

- `fortisai-hermes`

Default gateway endpoint:

- `http://127.0.0.1:8642`

## Shared Service Model

All major components attach to the platform shared network. macOS and Windows use `fortisai-dev-net`; Linux uses `fortisai-calico-net` when the Calico/CoreDNS deployment is present and otherwise falls back to `fortisai-dev-net`.

Core shared data services:

- HashiCorp Vault: `fortisai-vault` (`http://fortisai-vault.fortisai.local:8200` inside the shared network)
- MongoDB: `fortisai-mongodb` (`mongodb://fortisai-mongodb.fortisai.local:27017/appsmith?replicaSet=rs0`)
- Redis: `fortisai-redis` (`redis://fortisai-redis.fortisai.local:6379`)
- RabbitMQ: `fortisai-rabbitmq` (`amqp://fortisai:fortisai@fortisai-rabbitmq.fortisai.local:5672`)
- pgvector (PostgreSQL): `fortisai-pgvector` (`postgresql://fortisai:fortisai@fortisai-pgvector.fortisai.local:5432/fortisai`)

Helper startup starts and unseals Vault before dependent services start, syncs helper-managed runtime secrets under `secret/fortisai/dev/*`, and injects `VAULT_ADDR`, `FORTISAI_VAULT_ADDR`, and a read-only `VAULT_TOKEN` into generated component runtime files.

Honcho bindings:

- `DB_CONNECTION_URI=postgresql+psycopg://fortisai:fortisai@fortisai-pgvector.fortisai.local:5432/honcho`
- `CACHE_URL=redis://fortisai-redis.fortisai.local:6379/0?suppress=true`
- `CACHE_ENABLED=true`
- `VECTOR_STORE_TYPE=pgvector`
- `HONCHO_DB=honcho` (default; helper ensures DB exists before Honcho start)

OpenClaw bindings:

- Gateway auth token defaults to helper-managed `OPENCLAW_GATEWAY_TOKEN`, synced through Vault path `secret/fortisai/dev/claw-gateway/gateway_token`.
- Helper-managed OpenClaw config includes an OpenAI-compatible provider that points to the FortisAI proxy base URL `http://fortisai-mcp-openapi-dify.fortisai.local:8093/v1` with model `fortisai`.
- Helper-managed OpenClaw config enables plugin `@honcho-ai/openclaw-honcho` with local Honcho base URL `http://fortisai-honcho-api.fortisai.local:8000`.
- OpenWebUI can be wired to OpenClaw with `OPENWEBUI_LLM_BACKEND=openclaw`.
- When routed to OpenClaw, OpenWebUI uses `OPENAI_API_BASE_URL=http://fortisai-claw-gateway.fortisai.local:18789/v1`.

Hermes bindings:

- Hermes API auth token defaults to helper-managed `HERMES_API_SERVER_KEY`, synced through Vault path `secret/fortisai/dev/hermes/api_server_key`.
- Hermes runtime includes Honcho context env wiring:
  - `FORTISAI_HONCHO_BASE_URL=http://fortisai-honcho-api.fortisai.local:8000`
  - `FORTISAI_HONCHO_WORKSPACE_ID=hermes`
  - `FORTISAI_HONCHO_API_KEY` (optional)
- Hermes runtime includes Daytona context env wiring:
  - `FORTISAI_DAYTONA_DASHBOARD_URL=http://host.containers.internal:${DAYTONA_DASHBOARD_HOST_PORT:-3300}`
  - `FORTISAI_DAYTONA_API_URL=http://host.containers.internal:${DAYTONA_API_HOST_PORT:-3300}/api`
- OpenWebUI defaults to Hermes and uses:
  - `OPENAI_API_BASE_URL=http://fortisai-hermes.fortisai.local:8642/v1`
  - `OPENAI_API_KEY=$HERMES_API_SERVER_KEY`

LLM key input:

- `HONCHO_LLM_OPENAI_API_KEY` (helper default: `lmstudio`)

LLM integration model:

- On Linux, Honcho uses `transport=openai` and points feature-specific base URL overrides to the secondary helper-managed llama endpoint: `http://fortisai-llama-server-secondary.fortisai.local:8012/v1`.
- LM Studio can still be used by overriding the feature-specific base URL values to `http://host.docker.internal:1234/v1` for containers or `http://localhost:1234/v1` for host-native runtime.
- Minimum required for starter path is usually Deriver settings:
  - `DERIVER_MODEL_CONFIG__TRANSPORT=openai`
  - `DERIVER_MODEL_CONFIG__MODEL=<local-model-name>`
  - `DERIVER_MODEL_CONFIG__OVERRIDES__BASE_URL=http://fortisai-llama-server-secondary.fortisai.local:8012/v1`

## Components Wired Around Shared Services

These components are deployed with shared-service awareness in the helper-generated runtime:

- Honcho
- OpenClaw
- Hermes Agent
- Dify
- n8n
- OpenWebUI
- Appsmith
- Oracle Node API
- ORDS
- SQLcl sidecar
- Oracle AI Database Free
- Qdrant (for Dify vector profile)

## Wiring Notes by Component

1. Honcho
- Uses shared pgvector and Redis directly.
- Uses a dedicated database name (`honcho` by default) on shared pgvector.
- Exposes API on host port `8010`.
- Background reasoning runs in `deriver` service.
- Uses the secondary Linux llama router for local derivation and memory model calls by default; can run with LM Studio as OpenAI-compatible inference backend using per-feature `MODEL_CONFIG__OVERRIDES__BASE_URL` overrides.

2. Dify
- Starts with `qdrant` profile.
- Uses shared pgvector for DB and shared Redis for cache/broker/event bus.
- Internal Dify Redis service is patched out during helper setup.

3. n8n
- Receives shared env values for Redis, pgvector DSN, and Qdrant URL/API key.
- Runs on `http://localhost:5678`.

4. OpenWebUI
- Receives shared env values for Redis and pgvector DSN.
- Defaults to Hermes OpenAI-compatible endpoint and API server key for LLM calls.
- Can be switched to OpenClaw by setting `OPENWEBUI_LLM_BACKEND=openclaw`.
- Runs on `http://localhost:3000`.

5. Appsmith
- Receives shared env values for MongoDB, Redis, and pgvector DSN.
- Primary helper DB wiring uses `APPSMITH_DB_URL` and `APPSMITH_MONGODB_URI` against `fortisai-mongodb`.
- Runs on `http://localhost:18080`.

6. Oracle services
- Oracle DB, ORDS, SQLcl, and Oracle Node API are on the same shared network.
- These services support SQL and REST operations for local integration workflows.

7. Qdrant
- Exposed for Dify and n8n usage.
- Runs at `http://127.0.0.1:6333` with API key `difyai123456` by default.

8. OpenClaw
- Runs as helper-managed gateway service on port `18789` (plus bridge `18790`).
- Uses helper-generated config file to bind the FortisAI proxy as its OpenAI-compatible provider (`http://fortisai-mcp-openapi-dify.fortisai.local:8093/v1`, model `fortisai`) and Honcho plugin integration.
- Validated at helper setup/startup time for host-port conflicts against known default service ports.

9. Hermes Agent
- Runs as helper-managed gateway service on port `8642` (plus optional dashboard `9119`).
- Uses image `nousresearch/hermes-agent:latest` with command `gateway run`.
- Receives helper-wired Honcho and Daytona context environment values at runtime.
- On Linux, Hermes receives FortisAI proxy OpenAI-compatible env vars (`OPENAI_BASE_URL=http://fortisai-mcp-openapi-dify.fortisai.local:8093/v1`, `OPENAI_MODEL=fortisai`). Support tools that need direct LLM access, such as Honcho and CodeIndexer, use the secondary helper-managed llama router at `http://fortisai-llama-server-secondary.fortisai.local:8012/v1` when `llama-secondary-up` or `all-up` has started it. The primary `http://fortisai-llama-server.fortisai.local:8011/v1` endpoint remains dedicated to the FortisAI proxy/Dify router path.
- Validated at helper setup/startup time for host-port conflicts against known default service ports.

## Operational Flow

Default helper `up` sequence (simplified):

1. Start Vault and run the saved-key unseal step when local init material exists.
2. Sync helper-managed runtime secrets into Vault and verify required secret paths.
3. Start shared data services: MongoDB, Redis, RabbitMQ, and pgvector.
4. Start Oracle DB, ORDS, SQLcl sidecar, and Oracle Node API.
5. Start Appsmith, OpenVSCode Server, n8n, OpenWebUI, Honcho, Firecrawl, and Dify with the `qdrant` profile.
6. Keep optional MCP bridges, OpenClaw, Hermes, Daytona, and the Linux llama router under their dedicated lifecycle commands.

Linux `all-up` wraps the full agent/operator path: primary llama router, secondary llama router, core `up`, CodeIndexer, OpenMetadata, MCP OpenAPI bridges, OpenClaw, Hermes, Daytona, and Traefik. In that sequence MCP starts before OpenClaw and Hermes so the FortisAI proxy endpoint is available when those agent gateways come up.

`openclaw-up` and `hermes-up` also start/unseal Vault first and prepare their own Vault-backed runtime secrets before launching the component.

Default helper `down` stops the core stack, including Vault-backed shared services and Honcho. OpenClaw, Hermes, Daytona, MCP bridges, and the Linux llama router are stopped with their dedicated commands.

## Validation and Logs

Health checks and logs:

- Honcho health: `http://127.0.0.1:8010/health`
- OpenClaw health: `http://127.0.0.1:18789/health`
- Hermes health: `http://127.0.0.1:8642/health`
- FortisAI proxy models: `http://127.0.0.1:8093/v1/models`
- Honcho memory writeback validation: send a request through the FortisAI proxy with `X-FortisAI-User` and `X-FortisAI-Session`, then verify the generated session under Honcho `/v3/workspaces/fortisai/sessions/{session_id}/messages/list` or `/context`.
- Honcho logs:
  - macOS: `./fortisai-dev-helper.sh logs honcho`
  - Windows: `.\fortisai-dev-helper.ps1 logs honcho`
  - Linux: `./fortisai-dev-helper.sh logs honcho`
- OpenClaw logs:
  - macOS: `./fortisai-dev-helper.sh logs openclaw`
  - Windows: `.\fortisai-dev-helper.ps1 logs openclaw`
  - Linux: `./fortisai-dev-helper.sh logs openclaw`
- Hermes logs:
  - macOS: `./fortisai-dev-helper.sh logs hermes`
  - Windows: `.\fortisai-dev-helper.ps1 logs hermes`
  - Linux: `./fortisai-dev-helper.sh logs hermes`

Canonical URL and credentials index:

- `Development_Environment/development_env_url.md`

## Security Note

Defaults in local helper-generated configs are for development only.

Before sharing environments or moving beyond local machine scope:

- Replace `HONCHO_LLM_OPENAI_API_KEY`
- Rotate default DB/service passwords and helper-managed Vault secrets
- Disable open signup where applicable
- Enable authentication controls for exposed services
