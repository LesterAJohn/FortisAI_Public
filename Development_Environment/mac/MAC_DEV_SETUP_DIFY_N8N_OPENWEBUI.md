# Mac Development Environment: Dify, Honcho, OpenClaw, Hermes Agent, MongoDB, Redis, pgvector, n8n, and OpenWebUI

This guide sets up a local development environment on macOS for:

- Dify
- Honcho
- OpenClaw
- Hermes Agent
- MongoDB
- Redis
- pgvector
- Qdrant
- n8n
- OpenWebUI

It uses Podman for consistent local runtime behavior on macOS.

Documentation index for this folder: [Development_Environment/README.md](../README.md).
Default credentials/passwords for all local components are documented in [Development_Environment/development_env_url.md](../development_env_url.md) under **Default Credentials and Passwords**.

## Quick Start with Helper App

Use the helper app to automate setup and lifecycle management:

```bash
cd /path/to/FortisAI/Development_Environment/mac
./fortisai-dev-helper.sh up
./fortisai-dev-helper.sh check
```

Common commands:

```bash
./fortisai-dev-helper.sh setup
./fortisai-dev-helper.sh up
./fortisai-dev-helper.sh down
./fortisai-dev-helper.sh openclaw-up
./fortisai-dev-helper.sh openclaw-down
./fortisai-dev-helper.sh openclaw-shell
./fortisai-dev-helper.sh hermes-up
./fortisai-dev-helper.sh hermes-down
./fortisai-dev-helper.sh hermes-shell
./fortisai-dev-helper.sh status
./fortisai-dev-helper.sh scaffold-config-repos
./fortisai-dev-helper.sh lmstudio-setup
./fortisai-dev-helper.sh lmstudio-start
./fortisai-dev-helper.sh lmstudio-check
./fortisai-dev-helper.sh validate-prod
./fortisai-dev-helper.sh logs n8n
./fortisai-dev-helper.sh logs openwebui
./fortisai-dev-helper.sh logs mongodb
./fortisai-dev-helper.sh logs redis
./fortisai-dev-helper.sh logs firecrawl
./fortisai-dev-helper.sh logs pgvector
./fortisai-dev-helper.sh logs honcho
./fortisai-dev-helper.sh logs openclaw
./fortisai-dev-helper.sh logs hermes
./fortisai-dev-helper.sh logs qdrant
./fortisai-dev-helper.sh logs dify
```

Git workflow instructions for exporting from Dify and n8n into Git-managed YAML and JSON repositories are in [GIT_IMPORT_EXPORT_DIFY_N8N.md](GIT_IMPORT_EXPORT_DIFY_N8N.md).

## 1) Prerequisites

Install tools:

```bash
brew update
brew install podman pipx git jq httpd
pipx ensurepath
```

> **Note**: Do **not** install `podman-compose` via Homebrew. Homebrew currently ships
> `podman-compose` 1.5.x, which has known incompatibilities with Dify (strict network
> validation and broken profile/depends_on resolution). Install 1.4.x via `pipx` instead:

```bash
pipx install 'podman-compose<1.5'
```

Verify:

```bash
podman-compose version   # should print 1.4.x
```

Start container runtime:

```bash
podman machine init --cpus 6 --memory 12288 --disk-size 80
podman machine start
```

Verify Podman is ready:

```bash
podman version
podman compose version
```

## 2) Create a Working Folder

```bash
mkdir -p ~/fortisai-dev
cd ~/fortisai-dev
```

## 3) Deploy n8n (Local)

Create folder and compose file:

```bash
mkdir -p ~/fortisai-dev/n8n
cat > ~/fortisai-dev/n8n/docker-compose.yml <<'YAML'
services:
  n8n:
    image: n8nio/n8n:latest
    container_name: fortisai-n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - N8N_HOST=localhost
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - NODE_ENV=development
      - GENERIC_TIMEZONE=UTC
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=change-me-n8n
    volumes:
      - n8n_data:/home/node/.n8n
volumes:
  n8n_data:
YAML
```

Start n8n:

```bash
podman compose -f ~/fortisai-dev/n8n/docker-compose.yml up -d
```

Access:
- URL: http://localhost:5678
- Username: admin
- Password: change-me-n8n

## 4) Deploy OpenWebUI (Local)

Create folder and compose file:

```bash
mkdir -p ~/fortisai-dev/openwebui
cat > ~/fortisai-dev/openwebui/docker-compose.yml <<'YAML'
services:
  openwebui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: fortisai-openwebui
    restart: unless-stopped
    ports:
      - "3000:8080"
    environment:
      - WEBUI_AUTH=true
      - ENABLE_SIGNUP=true
    volumes:
      - openwebui_data:/app/backend/data
volumes:
  openwebui_data:
YAML
```

Start OpenWebUI:

```bash
podman compose -f ~/fortisai-dev/openwebui/docker-compose.yml up -d
```

Access:
- URL: http://localhost:3000

## 5) Deploy Dify (Local)

Use Dify official container deployment from the upstream repository.

```bash
cd ~/fortisai-dev
git clone https://github.com/langgenius/dify.git
cd dify/docker
cp .env.example .env
```

Recommended local edits in .env:

- Set `EXPOSE_NGINX_PORT=18081` to avoid conflicts with OpenAPI filesystem service on port 8081.
- Set `VECTOR_STORE=qdrant` to use the local Qdrant container.
- Set database/cache variables to shared services when using FortisAI helper-managed shared components:
  - `DB_HOST=fortisai-pgvector`
  - `DB_PORT=5432`
  - `DB_DATABASE=fortisai`
  - `DB_USERNAME=fortisai`
  - `DB_PASSWORD=fortisai`
  - `REDIS_HOST=fortisai-redis`
  - `REDIS_PORT=6379`

When using `./fortisai-dev-helper.sh up`, these values are applied automatically and Dify is started with the `qdrant` profile while database/cache use shared pgvector/Redis services.

Start Dify:

```bash
podman compose up -d
```

Access:
- URL: http://localhost:18081

## 5.1) Qdrant Vector Store

The helper wires Qdrant into the Dify stack and exposes it for local host access and n8n workflows.

- URL: http://127.0.0.1:6333
- Default API key: `difyai123456`
- n8n env: `QDRANT_URL`, `QDRANT_API_KEY`, `FORTISAI_QDRANT_URL`

## 5.2) Redis and pgvector Shared Services

The helper starts shared Redis and pgvector services for Dify, n8n, OpenWebUI, and Appsmith.

MongoDB is also started by default helper lifecycle and used as Appsmith primary DB.

- MongoDB URL: `mongodb://127.0.0.1:27017/appsmith?replicaSet=rs0`
- MongoDB logs: `./fortisai-dev-helper.sh logs mongodb`

- Redis URL: `redis://127.0.0.1:6379`
- pgvector DSN: `postgresql://fortisai:fortisai@127.0.0.1:5432/fortisai`
- Redis logs: `./fortisai-dev-helper.sh logs redis`
- pgvector logs: `./fortisai-dev-helper.sh logs pgvector`

## 5.2.1) Firecrawl Service

The helper starts Firecrawl as part of default `up`/`down`.

- URL: `http://127.0.0.1:3002`
- Health endpoint: `http://127.0.0.1:3002/health`
- Logs: `./fortisai-dev-helper.sh logs firecrawl`
- Firecrawl uses shared pgvector/RabbitMQ/Redis via `NUQ_DATABASE_URL`, `NUQ_RABBITMQ_URL`, and Redis URL envs.
- Helper startup auto-creates Firecrawl DB (`FIRECRAWL_DB_NAME`, default `firecrawl`) and applies upstream NUQ schema before Firecrawl launch.
- Override NUQ schema source using `FIRECRAWL_NUQ_SQL_URL` if you need a pinned SQL source.

## 5.3) OpenClaw Gateway (Honcho + LM Studio)

OpenClaw is managed by dedicated lifecycle commands and pre-wired to Honcho and LM Studio.

- Start: `./fortisai-dev-helper.sh openclaw-up`
- Stop: `./fortisai-dev-helper.sh openclaw-down`
- OpenClaw is not started/stopped by default `up`/`down`.

- Gateway URL: `http://127.0.0.1:18789`
- Health endpoint: `http://127.0.0.1:18789/health`
- Logs: `./fortisai-dev-helper.sh logs openclaw`
- Shell: `./fortisai-dev-helper.sh openclaw-shell`
- OpenWebUI override wiring: set `OPENWEBUI_LLM_BACKEND=openclaw`; the helper uses `OPENAI_API_BASE_URL=http://fortisai-claw-gateway.fortisai.local:18789/v1` when CoreDNS is active and `http://fortisai-claw-gateway:18789/v1` otherwise
- OpenClaw plugin wiring: `@honcho-ai/openclaw-honcho` points to `http://fortisai-honcho-api:8000`
- LM Studio wiring: OpenClaw uses `http://host.docker.internal:1234/v1`
- Default gateway token: `fortisai-claw-gateway-dev-token` (override with `OPENCLAW_GATEWAY_TOKEN`)

## 5.4) Hermes Agent Gateway

Hermes Agent is managed by dedicated lifecycle commands.

- Start: `./fortisai-dev-helper.sh hermes-up`
- Stop: `./fortisai-dev-helper.sh hermes-down`
- Hermes is not started/stopped by default `up`/`down`.
- Gateway URL: `http://127.0.0.1:8642`
- Health endpoint: `http://127.0.0.1:8642/health`
- Logs: `./fortisai-dev-helper.sh logs hermes`
- Shell: `./fortisai-dev-helper.sh hermes-shell`
- OpenWebUI default wiring: `OPENAI_API_BASE_URL=http://fortisai-hermes.fortisai.local:8642/v1` when CoreDNS is active and `http://fortisai-hermes:8642/v1` otherwise
- Optional dashboard port: `9119` (enable with `HERMES_DASHBOARD=1`)
- Runtime image: `nousresearch/hermes-agent:latest`
- Runtime command: `gateway run`
- Honcho context envs: `FORTISAI_HONCHO_BASE_URL`, `FORTISAI_HONCHO_WORKSPACE_ID`, `FORTISAI_HONCHO_API_KEY`
- Daytona context envs: `FORTISAI_DAYTONA_DASHBOARD_URL`, `FORTISAI_DAYTONA_API_URL`

### OpenWebUI Custom Tool for Hermes

If you want OpenWebUI to call Hermes through a custom tool instead of only using Hermes as the chat backend, paste this Python tool into OpenWebUI's custom tools editor.

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
      default="http://fortisai-hermes.fortisai.local:8642/v1",  # CoreDNS active; use http://fortisai-hermes:8642/v1 without CoreDNS
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

For this environment, use:

- `hermes_base_url = http://fortisai-hermes.fortisai.local:8642/v1` when CoreDNS is active, or `http://fortisai-hermes:8642/v1` otherwise
- `hermes_api_key = fortisai-hermes-dev-api-key`
- `hermes_model = your Hermes model name`

## 5.5) Honcho Shared Memory Service

The helper starts Honcho as two services (`api` and `deriver`) and wires both to shared pgvector and Redis.

- URL: `http://127.0.0.1:8010`
- Health endpoint: `http://127.0.0.1:8010/health`
- Logs: `./fortisai-dev-helper.sh logs honcho`
- Shared DB service with dedicated Honcho DB: `postgresql+psycopg://fortisai:fortisai@fortisai-pgvector:5432/honcho`
- Shared cache: `redis://fortisai-redis:6379/0?suppress=true`
- LLM key override variable: `HONCHO_LLM_OPENAI_API_KEY`
- Honcho DB override variable: `HONCHO_DB` (default: `honcho`)
- Helper startup auto-creates Honcho DB if missing.

### Honcho + LM Studio

Honcho can use LM Studio through the OpenAI-compatible API.

Recommended local Honcho `.env` settings when running Honcho in containers:

- `LLM_OPENAI_API_KEY=lmstudio`
- `DERIVER_MODEL_CONFIG__TRANSPORT=openai`
- `DERIVER_MODEL_CONFIG__MODEL=<your-loaded-lmstudio-model>`
- `DERIVER_MODEL_CONFIG__OVERRIDES__BASE_URL=http://host.docker.internal:1234/v1`

If Honcho is running directly on host (not in containers), use:

- `DERIVER_MODEL_CONFIG__OVERRIDES__BASE_URL=http://localhost:1234/v1`

Apply the same `MODEL_CONFIG__OVERRIDES__BASE_URL` pattern to Summary, Dialectic levels, Dream, and Embeddings if you want all Honcho subsystems to use LM Studio.

Important: use models that support tool calling. Honcho reasoning agents rely on tool-use capable models.

## 5.6) Deploy Oracle AI Database Free (Local)

The helper script can generate and start an Oracle AI Database Free container on the shared `fortisai-dev-net` network.

```bash
cd /path/to/FortisAI/Development_Environment/mac
./fortisai-dev-helper.sh oracle-db-pull
./fortisai-dev-helper.sh logs oracle-db
```

Default connection details:

- Listener: `localhost:1521`
- PDB: `FREEPDB1`
- Credentials: `pdbadmin` / `FortisAI26ai!2026`

The helper also creates `~/fortisai-dev/oracle-wallet` during `setup`, including `oracle-wallet-credentials.sh` for collecting wallet-related DB inputs and optionally building `ewallet.p12` from separate certificate and private-key files.
It also generates `~/fortisai-dev/sqlcl-mcp/mcp.json` and supports `./fortisai-dev-helper.sh sqlcl-mcp` for MCP-capable clients that should talk to the running SQLcl sidecar.

If this is your first pull, sign in to Oracle Container Registry before starting the helper.

For token-based OCR login automation, set `OCR_USERNAME` and `OCR_AUTH_TOKEN` before running `oracle-db-pull` or `up`.

## 5.7) OpenWebUI MCP Setup (SQLcl, n8n, Dify, Debug, Proxmox)

Use this sequence to configure and validate OpenWebUI MCP bridges.

1. Ensure helper templates and the generated local Dify bridge key cache are refreshed. Vault remains the runtime source of truth after helper sync; the cache lives at `Development_Environment/mcp/dify-mcp/dify-api-key.json` when needed:

```bash
cd /path/to/FortisAI/Development_Environment/mac
./fortisai-dev-helper.sh setup
```

2. Regenerate local templates and helper files:

```bash
./fortisai-dev-helper.sh setup
```

3. Start and validate MCP OpenAPI bridges:

```bash
./fortisai-dev-helper.sh mcp-up
```

To stop MCP OpenAPI bridges later:

```bash
./fortisai-dev-helper.sh mcp-down
```

`mcp-up` starts and validates:

- `fortisai-mcp-openapi-sqlcl` (`http://127.0.0.1:8091/openapi.json`)
- `fortisai-mcp-openapi-n8n` (`http://127.0.0.1:8092/openapi.json`)
- `fortisai-mcp-openapi-dify` (`http://127.0.0.1:8093/openapi.json`)
- `fortisai-mcp-openapi-debug` (`http://127.0.0.1:8094/openapi.json`)
- `fortisai-mcp-openapi-proxmox` (`http://127.0.0.1:8095/openapi.json`) when Proxmox config is present

When Proxmox is enabled, `mcp-up` starts `fortisai-mcp-openapi-proxmox-upstream` for ProxmoxMCP-Plus and `fortisai-mcp-openapi-proxmox` as the local OpenAPI facade. Proxmox values can come from `Development_Environment/mcp/proxmox/proxmox-config.json`, `PROXMOX_*` environment variables, or Vault after helper sync.

It also smoke-tests bridge endpoints, including Proxmox `/livez` when enabled, and upserts OpenWebUI `tool_server.connections` for `mcp-dify-server`.

4. Optional OpenWebUI tool import payload for Dify bridge:

```text
Development_Environment/mcp/dify-mcp/openwebui-dify-mcp-tools.import.json
```

5. Quick host-side verification:

```bash
curl -sS http://127.0.0.1:8093/dify_connection_info
curl -sS http://127.0.0.1:8093/healthz
curl -sS http://127.0.0.1:8093/openapi.json | jq -r '.info.title'
```

6. OpenWebUI shell access (for container-local checks):

```bash
./fortisai-dev-helper.sh openwebui-shell
```

## 6) Validate All Services

Check containers:

```bash
podman ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
```

Quick endpoint checks:

```bash
curl -I http://localhost:5678
curl -H 'api-key: difyai123456' http://127.0.0.1:6333/collections
curl -I http://localhost:3000
curl -I http://localhost:18081
```

## 7) Deploy LM Studio (Local)

Use helper commands:

```bash
cd /path/to/FortisAI/Development_Environment/mac
./fortisai-dev-helper.sh lmstudio-setup
./fortisai-dev-helper.sh lmstudio-start
./fortisai-dev-helper.sh lmstudio-check
```

After LM Studio opens, load a model and enable the Local Server on port `1234`.
For detailed steps, see [LM_STUDIO_SETUP_MAC.md](LM_STUDIO_SETUP_MAC.md).

## Dify LLM Provider Requirement for LM Studio

When configuring models in Dify for local LM Studio inference:

- Use the compatible-openai-llm module (OpenAI API Compatible provider).
- Do not use the LM Studio plugin in Dify. It is currently unreliable in this setup and can cause runtime failures.

Recommended Dify configuration:

- Provider: `langgenius/openai_api_compatible/openai_api_compatible`
- Endpoint base URL: `http://host.containers.internal:1234/v1` (inside containers) or `http://localhost:1234/v1` (host process)
- API key: any non-empty placeholder value if your LM Studio server does not enforce auth

This is also reflected in the local Dify template under [Development_Environment/templates/dify/app-template.yaml](../templates/dify/app-template.yaml).

## 8) Day-2 Operations

Start all apps:

```bash
podman compose -f ~/fortisai-dev/n8n/docker-compose.yml up -d
podman compose -f ~/fortisai-dev/openwebui/docker-compose.yml up -d
podman compose -f ~/fortisai-dev/oracle-db/docker-compose.yml up -d
cd ~/fortisai-dev/dify/docker && podman compose up -d
```

Stop all apps:

```bash
podman compose -f ~/fortisai-dev/n8n/docker-compose.yml down
podman compose -f ~/fortisai-dev/openwebui/docker-compose.yml down
podman compose -f ~/fortisai-dev/oracle-db/docker-compose.yml down
cd ~/fortisai-dev/dify/docker && podman compose down
```

View logs:

```bash
podman logs -f fortisai-n8n
podman logs -f fortisai-openwebui
cd ~/fortisai-dev/dify/docker && podman compose logs -f
```

## 8.1) Optional Daytona OSS (Self-Hosted)

Daytona can be deployed as an additional local container stack when self-hosted.

Prerequisites:

- Docker Compose-compatible runtime (`podman compose`, `podman-compose`, or `docker compose`)
- Git
- Optional for full preview URL behavior: local wildcard DNS setup from Daytona repo

Helper commands:

```bash
./fortisai-dev-helper.sh daytona-setup
./fortisai-dev-helper.sh daytona-up
./fortisai-dev-helper.sh daytona-check
./fortisai-dev-helper.sh daytona-down
```

Default port conflict protections:

- Daytona dashboard remapped to `http://localhost:3300` (avoids OpenWebUI on `3000`)
- Apple Silicon GPU status is reported by `./fortisai-dev-helper.sh daytona-gpu-check`; Daytona Linux containers remain CPU-only on macOS because Metal/MPS is not exposed to Docker/Podman Linux containers.
- Daytona proxy remapped to `4400`
- Daytona SSH gateway remapped to `2223`
- Auxiliary Daytona UI ports are also remapped by helper defaults

If you need Daytona preview wildcard URLs (`*.proxy.localhost`), run:

```bash
cd ~/fortisai-dev/daytona
./scripts/setup-proxy-dns.sh
```

## 9) Recommended Next Hardening Steps

- Replace all default local passwords.
- Disable signup on OpenWebUI if not needed.
- Configure HTTPS locally with a reverse proxy and local certificates.
- Store secrets in a local secrets manager and avoid committing .env files.

## 10) Troubleshooting

If Podman commands fail after reboot:

```bash
podman machine stop
podman machine start
```

If ports are in use:

```bash
lsof -nP -iTCP:5678 -sTCP:LISTEN
lsof -nP -iTCP:3000 -sTCP:LISTEN
lsof -nP -iTCP:18081 -sTCP:LISTEN
```

If Dify fails with `KeyError: 'db_postgres'`, `KeyError: 'seekdb'`, or similar errors:

All versions of `podman-compose` ignore `required: false` on profile-gated
`depends_on` entries.  Dify 1.14+ uses compose profiles to select the database
backend, so the active services (`api`, `worker`, `worker_beat`, `plugin_daemon`)
list several profile-gated database services as soft dependencies — which
podman-compose treats as hard dependencies and raises a `KeyError`.

**`./fortisai-dev-helper.sh setup` handles this automatically** — it patches
`docker-compose.yaml` in-place (saving the original as `docker-compose.yaml.orig`)
and always starts Dify with `--profile postgresql`.

If you need to re-apply the patch after pulling a Dify update:

```bash
cd ~/fortisai-dev/dify/docker
rm -f docker-compose.yaml.orig    # remove backup so the helper re-patches
./fortisai-dev-helper.sh setup
```

Or apply manually and start with the postgresql profile:

```bash
cd ~/fortisai-dev/dify/docker
podman-compose --profile postgresql up -d
```

If Dify fails to start fully, inspect service health in its stack:

```bash
cd ~/fortisai-dev/dify/docker
podman compose ps
podman compose logs -f --tail=200
```

## 11) Link Local Environment to Production via Bastion

This section connects your local environment to production GitHub, GenAI, and Llama endpoints through OCI Bastion port-forward sessions.

### 10.1 Generate Production Link Template

```bash
cd /path/to/FortisAI/Development_Environment/mac
./fortisai-dev-helper.sh prod-template
cp ~/fortisai-dev/.prod-link.env.example ~/fortisai-dev/.prod-link.env
```

### 10.2 Get Bastion Service IDs

Run from repo root:

```bash
terraform -chdir=landing-zone/network output bastion_service_id
terraform -chdir=landing-zone/network output bastion_target_subnet_id
```

Set these values in `~/fortisai-dev/.prod-link.env`:

- `BASTION_SERVICE_ID`
- `BASTION_TARGET_SUBNET_ID`
- `BASTION_SSH_PUBLIC_KEY_PATH`

### 10.3 Get OCI GitHub Credentials Secret IDs

These IDs are produced by the pipeline stack:

```bash
terraform -chdir=pipeline output devops_git_username_secret_id
terraform -chdir=pipeline output devops_git_token_secret_id
```

Set these in `~/fortisai-dev/.prod-link.env`:

- `OCI_DEVOPS_GIT_USERNAME_SECRET_ID`
- `OCI_DEVOPS_GIT_TOKEN_SECRET_ID`

Optional: if your production GitHub is private GitHub Enterprise, also set:

- `PROD_GITHUB_PRIVATE_IP`
- `PROD_GITHUB_PORT`

If you use public github.com, keep GitHub private IP empty and the helper will skip GitHub bastion session creation.

### 10.4 Get GenAI Credential Secret ID

```bash
terraform -chdir=landing-zone output genai_oci_credentials_secret_id
```

Set in `~/fortisai-dev/.prod-link.env`:

- `GENAI_OCI_CREDENTIALS_SECRET_ID`

### 10.5 Set Production Target Private IPs

Update these in `~/fortisai-dev/.prod-link.env`:

- `PROD_GENAI_PRIVATE_IP` and `PROD_GENAI_PORT`
- `PROD_LLAMA_PRIVATE_IP` and `PROD_LLAMA_PORT`

Use internal/private addresses reachable from the bastion target subnet.

### 10.6 Create Bastion Port-Forward Sessions

Validate your production settings first:

```bash
cd /path/to/FortisAI/Development_Environment/mac
./fortisai-dev-helper.sh validate-prod
```

Then create the sessions:

```bash
cd /path/to/FortisAI/Development_Environment/mac
./fortisai-dev-helper.sh link-prod
```

The helper prints per-service `session_id` and `ssh_command`. Run each `ssh_command` in a separate terminal to keep the tunnel open.

### 10.7 Retrieve OCI GitHub Credentials from Vault

```bash
source ~/fortisai-dev/.prod-link.env

export OCI_GIT_USERNAME=$(oci secrets secret-bundle get \
  --secret-id "$OCI_DEVOPS_GIT_USERNAME_SECRET_ID" \
  --query 'data."secret-bundle-content".content' --raw-output | base64 --decode)

export OCI_GIT_TOKEN=$(oci secrets secret-bundle get \
  --secret-id "$OCI_DEVOPS_GIT_TOKEN_SECRET_ID" \
  --query 'data."secret-bundle-content".content' --raw-output | base64 --decode)
```

Use these for Git operations against OCI DevOps repositories:

```bash
git -c credential.helper='!f() { echo username=$OCI_GIT_USERNAME; echo password=$OCI_GIT_TOKEN; }; f' ls-remote <oci_devops_repo_url>
```

### 10.8 Verify Linked Connectivity

1. Confirm tunnels are active in terminal windows running the bastion `ssh_command`.
2. Test GenAI and Llama API access through the forwarded local ports from your local tools.
3. Confirm Git access works with the retrieved OCI Git credentials.
