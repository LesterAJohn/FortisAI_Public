# Linux Development Environment: Dify, Honcho, OpenClaw, Hermes, Firecrawl, MongoDB, n8n, and OpenWebUI

This guide sets up the FortisAI local stack on Linux using Podman.

Documentation index for this folder: [README.md](README.md).
Canonical URLs and default credentials: [../development_env_url.md](../development_env_url.md).

## Quick Start

```bash
cd /path/to/FortisAI/Development_Environment
./linux/fortisai-dev-helper.sh setup
./linux/fortisai-dev-helper.sh up
./linux/fortisai-dev-helper.sh check
```

## Prerequisites

Install required tooling (package names vary by distro):

- podman
- podman-compose (optional if `podman compose` plugin is available)
- docker compose plugin (optional fallback)
- git
- jq
- python3 + pip (for `podman-compose<1.5` fallback if required)

Verify:

```bash
podman version
podman compose version || true
podman-compose version || true
docker compose version || true
```

## Runtime Notes

- On Linux, Podman usually runs natively and does not require `podman machine`.
- The helper first checks native Podman readiness and only falls back to `podman machine` if needed.
- Shared network creation is idempotent. Linux uses `fortisai-calico-net` when the Calico/CoreDNS deployment marker or network exists and otherwise falls back to `fortisai-dev-net`.
- Vault uses persistent local file storage and is prepared before dependent containers. The helper starts Vault, initializes it on first run when needed, unseals it from `~/fortisai-dev/vault/vault-init.json`, syncs `secret/fortisai/dev/*`, and then starts the rest of the stack.

## Service Lifecycle Model

Default lifecycle (`up` / `down`) includes:

- HashiCorp Vault
- Oracle DB + ORDS + SQLcl
- MongoDB
- Redis
- RabbitMQ
- pgvector
- Honcho
- Firecrawl
- Dify
- n8n
- OpenWebUI
- Appsmith

Dedicated lifecycle (not part of default `up` / `down`):

- OpenClaw: `openclaw-up`, `openclaw-down`
- Hermes: `hermes-up`, `hermes-down`
- Primary llama router: `llama-router-up`, `llama-router-down`
- Secondary llama router: `llama-secondary-up`, `llama-secondary-down`
- Daytona: `daytona-up`, `daytona-down`, `daytona-gpu-check`
  - On NVIDIA hosts, `daytona-up` auto-generates the NVIDIA payload/CDI wiring and enables Daytona GPU sandboxes through the runner.

`openclaw-up` and `hermes-up` also run the Vault preparation sequence first so those components receive the same `VAULT_ADDR`, `FORTISAI_VAULT_ADDR`, and read-only `VAULT_TOKEN` wiring as the default stack.

On Linux, `llama-router-up` creates the primary Llama pod on the selected shared network (`fortisai-calico-net` when present, otherwise `fortisai-dev-net`) and publishes the FortisAI proxy backend on both `http://127.0.0.1:8011/v1` from the host and `http://fortisai-llama-server.fortisai.local:8011/v1` from shared-network containers. `llama-secondary-up` creates the secondary Llama pod and publishes support-tool direct LLM access on `http://127.0.0.1:8012/v1` from the host and `http://fortisai-llama-server-secondary.fortisai.local:8012/v1` from shared-network containers. `all-up` starts both llama servers, starts the FortisAI proxy bridge at `http://fortisai-mcp-openapi-dify.fortisai.local:8093/v1`, then starts OpenClaw and Hermes against that proxy endpoint.

## Firecrawl Wiring

Firecrawl is wired to shared services by default:

- PostgreSQL (shared pgvector) via `NUQ_DATABASE_URL`
- RabbitMQ (shared) via `NUQ_RABBITMQ_URL`
- Redis (shared) via `REDIS_URL`, `REDIS_EVICT_URL`, `REDIS_RATE_LIMIT_URL`

Startup bootstrap:

- Helper auto-creates Firecrawl DB (`FIRECRAWL_DB_NAME`, default `firecrawl`)
- Helper applies upstream NUQ schema before Firecrawl start
- NUQ source override: `FIRECRAWL_NUQ_SQL_URL`

## Common Commands

```bash
./linux/fortisai-dev-helper.sh status
./linux/fortisai-dev-helper.sh vault-status
./linux/fortisai-dev-helper.sh logs firecrawl
./linux/fortisai-dev-helper.sh logs mongodb
./linux/fortisai-dev-helper.sh logs rabbitmq
./linux/fortisai-dev-helper.sh logs pgvector
./linux/fortisai-dev-helper.sh logs redis
./linux/fortisai-dev-helper.sh logs dify
./linux/fortisai-dev-helper.sh logs n8n
./linux/fortisai-dev-helper.sh logs openwebui
```

## Optional: Excluding OpenClaw from Startup Checks

```bash
./linux/fortisai-dev-helper.sh up --no-openclaw
./linux/fortisai-dev-helper.sh check --no-openclaw
```

## Troubleshooting

- If compose resolution fails with `podman-compose 1.5.x` profile/depends_on issues, install a compatible compose runtime:
  - install Docker Compose plugin, or
  - `pip3 install --user 'podman-compose<1.5'`
- If helper commands are killed by the host shell, inspect host resource controls and endpoint security policies.
- If Firecrawl restarts, verify:
  - `fortisai-pgvector`, `fortisai-rabbitmq`, and `fortisai-redis` are running
  - NUQ tables exist in Firecrawl DB
  - Firecrawl container env includes shared Redis/NUQ values
