# Windows Development Environment: Dify, Honcho, OpenClaw, Hermes Agent, MongoDB, Redis, pgvector, n8n, and OpenWebUI

This guide sets up a local development environment on Windows for:

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

It uses Podman and PowerShell.

Documentation index for this folder: [README.md](README.md).
Default credentials/passwords for all local components are documented in [Development_Environment/development_env_url.md](../development_env_url.md) under **Default Credentials and Passwords**.

## Quick Start with Helper Script

```powershell
cd C:\Users\<your-user>\Desktop\FortisAI\Development_Environment\windows
.\fortisai-dev-helper.ps1 up
.\fortisai-dev-helper.ps1 check
```

Common commands:

```powershell
.\fortisai-dev-helper.ps1 setup
.\fortisai-dev-helper.ps1 up
.\fortisai-dev-helper.ps1 down
.\fortisai-dev-helper.ps1 openclaw-up
.\fortisai-dev-helper.ps1 openclaw-down
.\fortisai-dev-helper.ps1 openclaw-shell
.\fortisai-dev-helper.ps1 hermes-up
.\fortisai-dev-helper.ps1 hermes-down
.\fortisai-dev-helper.ps1 hermes-shell
.\fortisai-dev-helper.ps1 status
.\fortisai-dev-helper.ps1 scaffold-config-repos
.\fortisai-dev-helper.ps1 lmstudio-setup
.\fortisai-dev-helper.ps1 lmstudio-start
.\fortisai-dev-helper.ps1 lmstudio-check
.\fortisai-dev-helper.ps1 validate-prod
.\fortisai-dev-helper.ps1 logs n8n
.\fortisai-dev-helper.ps1 logs openwebui
.\fortisai-dev-helper.ps1 logs mongodb
.\fortisai-dev-helper.ps1 logs redis
.\fortisai-dev-helper.ps1 logs firecrawl
.\fortisai-dev-helper.ps1 logs pgvector
.\fortisai-dev-helper.ps1 logs honcho
.\fortisai-dev-helper.ps1 logs openclaw
.\fortisai-dev-helper.ps1 logs hermes
.\fortisai-dev-helper.ps1 logs qdrant
.\fortisai-dev-helper.ps1 logs dify
```

## 1) Prerequisites

Install:

- Podman Desktop or Podman CLI
- Git
- OCI CLI
- jq
- `htpasswd` — included with Git for Windows (Git Bash). If using WSL, install via `sudo apt install apache2-utils`.

If Podman compose plugin is missing, install `podman-compose`.

## 2) Start Podman Machine

```powershell
podman machine init --cpus 6 --memory 12288 --disk-size 80
podman machine start
podman version
podman compose version
```

## 3) Deploy n8n (Local)

```powershell
.\fortisai-dev-helper.ps1 setup
.\fortisai-dev-helper.ps1 up
```

n8n URL:
- http://localhost:5678

Default auth from generated compose:
- Username: admin
- Password: change-me-n8n

## 4) Deploy OpenWebUI (Local)

OpenWebUI URL:
- http://localhost:3000

## 5) Deploy Dify (Local)

Dify URL:
- http://localhost:18081

The helper script clones Dify, generates `.env` from `.env.example`, sets `EXPOSE_NGINX_PORT=18081` (to avoid conflict with OpenAPI filesystem on 8081), and configures `VECTOR_STORE=qdrant`.

When using `.\fortisai-dev-helper.ps1 up`, Dify database/cache settings are also wired to shared services automatically:

- `DB_HOST=fortisai-pgvector`
- `DB_PORT=5432`
- `DB_DATABASE=fortisai`
- `DB_USERNAME=fortisai`
- `DB_PASSWORD=fortisai`
- `REDIS_HOST=fortisai-redis`
- `REDIS_PORT=6379`

Dify is started with the `qdrant` profile while database/cache use shared pgvector/Redis services.

## 5.1) Qdrant Vector Store

The helper wires Qdrant into the Dify stack and exposes it for local host access and n8n workflows.

- URL: http://127.0.0.1:6333
- Default API key: `difyai123456`
- n8n env: `QDRANT_URL`, `QDRANT_API_KEY`, `FORTISAI_QDRANT_URL`

## 5.2) Redis and pgvector Shared Services

The helper starts shared Redis and pgvector services for Dify, n8n, OpenWebUI, and Appsmith.

MongoDB is also started by default helper lifecycle and used as Appsmith primary DB.

- MongoDB URL: `mongodb://127.0.0.1:27017/appsmith?replicaSet=rs0`
- MongoDB logs: `.\fortisai-dev-helper.ps1 logs mongodb`

- Redis URL: `redis://127.0.0.1:6379`
- pgvector DSN: `postgresql://fortisai:fortisai@127.0.0.1:5432/fortisai`
- Redis logs: `.\fortisai-dev-helper.ps1 logs redis`
- pgvector logs: `.\fortisai-dev-helper.ps1 logs pgvector`

## 5.2.1) Firecrawl Service

The helper starts Firecrawl as part of default `up`/`down`.

- URL: `http://127.0.0.1:3002`
- Health endpoint: `http://127.0.0.1:3002/health`
- Logs: `.\fortisai-dev-helper.ps1 logs firecrawl`
- Firecrawl uses shared pgvector/RabbitMQ/Redis via `NUQ_DATABASE_URL`, `NUQ_RABBITMQ_URL`, and Redis URL envs.
- Helper startup auto-creates Firecrawl DB (`FIRECRAWL_DB_NAME`, default `firecrawl`) and applies upstream NUQ schema before Firecrawl launch.
- Override NUQ schema source using `FIRECRAWL_NUQ_SQL_URL` if you need a pinned SQL source.

## 5.3) Honcho Shared Memory Service

The helper starts Honcho as two services (`api` and `deriver`) and wires both to shared pgvector and Redis.

- URL: `http://127.0.0.1:8010`
- Health endpoint: `http://127.0.0.1:8010/health`
- Logs: `.\fortisai-dev-helper.ps1 logs honcho`
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

## 5.4) OpenClaw Gateway (Honcho + LM Studio)

OpenClaw is managed by dedicated lifecycle commands and pre-wired to Honcho and LM Studio.

- Start: `.\fortisai-dev-helper.ps1 openclaw-up`
- Stop: `.\fortisai-dev-helper.ps1 openclaw-down`
- OpenClaw is not started/stopped by default `up`/`down`.

- Gateway URL: `http://127.0.0.1:18789`
- Health endpoint: `http://127.0.0.1:18789/health`
- Logs: `.\fortisai-dev-helper.ps1 logs openclaw`
- Shell: `.\fortisai-dev-helper.ps1 openclaw-shell`
- OpenWebUI override wiring: set `OPENWEBUI_LLM_BACKEND=openclaw`; the helper uses `OPENAI_API_BASE_URL=http://fortisai-claw-gateway.fortisai.local:18789/v1` when CoreDNS is active and `http://fortisai-claw-gateway:18789/v1` otherwise
- OpenClaw plugin wiring: `@honcho-ai/openclaw-honcho` points to `http://fortisai-honcho-api:8000`
- LM Studio wiring: OpenClaw uses `http://host.docker.internal:1234/v1`
- Default gateway token: `fortisai-claw-gateway-dev-token` (override with `OPENCLAW_GATEWAY_TOKEN`)

## 5.5) Hermes Agent Gateway

Hermes Agent is managed by dedicated lifecycle commands.

- Start: `.\fortisai-dev-helper.ps1 hermes-up`
- Stop: `.\fortisai-dev-helper.ps1 hermes-down`
- Hermes is not started/stopped by default `up`/`down`.
- Gateway URL: `http://127.0.0.1:8642`
- Health endpoint: `http://127.0.0.1:8642/health`
- Logs: `.\fortisai-dev-helper.ps1 logs hermes`
- Shell: `.\fortisai-dev-helper.ps1 hermes-shell`
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

## 5.6) Deploy Oracle AI Database Free (Local)

The helper script also generates and starts an Oracle AI Database Free container on the shared `fortisai-dev-net` network.

```powershell
.\fortisai-dev-helper.ps1 oracle-db-pull
.\fortisai-dev-helper.ps1 logs oracle-db
```

Default connection details:

- Listener: `localhost:1521`
- PDB: `FREEPDB1`
- Credentials: `pdbadmin` / `FortisAI26ai!2026`

The helper also creates `~/fortisai-dev/oracle-wallet` during `setup`, including `oracle-wallet-credentials.sh` for collecting wallet-related DB inputs and optionally building `ewallet.p12` from separate certificate and private-key files.
It also generates `~/fortisai-dev/sqlcl-mcp/mcp.json` and supports `.\fortisai-dev-helper.ps1 sqlcl-mcp` for MCP-capable clients that should talk to the running SQLcl sidecar.

The helper also supports OpenWebUI MCP OpenAPI bridges with `.\fortisai-dev-helper.ps1 mcp-up` and `.\fortisai-dev-helper.ps1 mcp-down`. When Proxmox is configured through `Development_Environment\mcp\proxmox\proxmox-config.json`, `PROXMOX_*` environment variables, or Vault after helper sync, `mcp-up` starts `fortisai-mcp-openapi-proxmox-upstream` plus the local facade `fortisai-mcp-openapi-proxmox` at `http://127.0.0.1:8095/openapi.json`.

If this is your first pull, sign in to Oracle Container Registry before running the helper.

For token-based OCR login automation, set `OCR_USERNAME` and `OCR_AUTH_TOKEN` before running `oracle-db-pull` or `up`.

## 6) Validate All Services

```powershell
.\fortisai-dev-helper.ps1 status
.\fortisai-dev-helper.ps1 check
curl.exe -H "api-key: difyai123456" http://127.0.0.1:6333/collections
```

## 7) Deploy LM Studio (Local)

```powershell
cd C:\Users\<your-user>\Desktop\FortisAI\Development_Environment\windows
.\fortisai-dev-helper.ps1 lmstudio-setup
.\fortisai-dev-helper.ps1 lmstudio-start
.\fortisai-dev-helper.ps1 lmstudio-check
```

After LM Studio opens, load a model and start the Local Server on port `1234`.
For detailed steps, see [LM_STUDIO_SETUP_WINDOWS.md](LM_STUDIO_SETUP_WINDOWS.md).

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

```powershell
.\fortisai-dev-helper.ps1 up
.\fortisai-dev-helper.ps1 down
.\fortisai-dev-helper.ps1 logs oracle-db
.\fortisai-dev-helper.ps1 logs n8n
.\fortisai-dev-helper.ps1 logs openwebui
.\fortisai-dev-helper.ps1 logs qdrant
.\fortisai-dev-helper.ps1 logs dify
```

## 8.1) Optional Daytona OSS (Self-Hosted)

Daytona can be deployed as an additional local container stack when self-hosted.

Prerequisites:

- Docker Compose-compatible runtime (`podman compose`, `podman-compose`, or `docker compose`)
- Git
- Optional for full preview URL behavior: local wildcard DNS setup from Daytona repo

Helper commands:

```powershell
.\fortisai-dev-helper.ps1 daytona-setup
.\fortisai-dev-helper.ps1 daytona-up
.\fortisai-dev-helper.ps1 daytona-check
.\fortisai-dev-helper.ps1 daytona-down
```

Default port conflict protections:

- Daytona dashboard remapped to `http://localhost:3300` (avoids OpenWebUI on `3000`)
- Daytona proxy remapped to `4400`
- Daytona SSH gateway remapped to `2223`
- Auxiliary Daytona UI ports are also remapped by helper defaults

If you need Daytona preview wildcard URLs (`*.proxy.localhost`), run:

```powershell
cd $HOME\fortisai-dev\daytona
./scripts/setup-proxy-dns.sh
```

## 9) Scaffold Config Repositories

```powershell
.\fortisai-dev-helper.ps1 scaffold-config-repos
```

Creates local repositories under:

- `$HOME\fortisai-dev\config-repos\dify-config`
- `$HOME\fortisai-dev\config-repos\n8n-config`

Git workflow details: [GIT_IMPORT_EXPORT_DIFY_N8N_WINDOWS.md](GIT_IMPORT_EXPORT_DIFY_N8N_WINDOWS.md).

## 10) Link Local Environment to Production via Bastion

### 9.1 Create production template

```powershell
.\fortisai-dev-helper.ps1 prod-template
Copy-Item "$HOME\fortisai-dev\.prod-link.env.example" "$HOME\fortisai-dev\.prod-link.env"
```

### 9.2 Get Bastion and secret IDs

From repo root:

```powershell
terraform -chdir=landing-zone/network output bastion_service_id
terraform -chdir=landing-zone/network output bastion_target_subnet_id
terraform -chdir=pipeline output devops_git_username_secret_id
terraform -chdir=pipeline output devops_git_token_secret_id
terraform -chdir=landing-zone output genai_oci_credentials_secret_id
```

Populate `$HOME\fortisai-dev\.prod-link.env` with:

- BASTION_SERVICE_ID
- BASTION_TARGET_SUBNET_ID
- BASTION_SSH_PUBLIC_KEY_PATH
- OCI_DEVOPS_GIT_USERNAME_SECRET_ID
- OCI_DEVOPS_GIT_TOKEN_SECRET_ID
- GENAI_OCI_CREDENTIALS_SECRET_ID
- PROD_GENAI_PRIVATE_IP / PROD_GENAI_PORT
- PROD_LLAMA_PRIVATE_IP / PROD_LLAMA_PORT
- optional PROD_GITHUB_PRIVATE_IP / PROD_GITHUB_PORT

### 9.3 Validate and create bastion sessions

```powershell
.\fortisai-dev-helper.ps1 validate-prod
.\fortisai-dev-helper.ps1 link-prod
```

The script prints per-session `session_id` and `ssh_command`.
Run each generated `ssh_command` in separate terminals to keep tunnels active.

## 11) OCI Git Credentials Retrieval

```powershell
$prod = Get-Content "$HOME\fortisai-dev\.prod-link.env" | Where-Object { $_ -and -not $_.StartsWith('#') }
$map = @{}
$prod | ForEach-Object {
  $k, $v = $_.Split('=', 2)
  $map[$k.Trim()] = $v.Trim()
}

$OCI_GIT_USERNAME = oci secrets secret-bundle get --secret-id $map['OCI_DEVOPS_GIT_USERNAME_SECRET_ID'] --query 'data."secret-bundle-content".content' --raw-output
$OCI_GIT_USERNAME = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($OCI_GIT_USERNAME))

$OCI_GIT_TOKEN = oci secrets secret-bundle get --secret-id $map['OCI_DEVOPS_GIT_TOKEN_SECRET_ID'] --query 'data."secret-bundle-content".content' --raw-output
$OCI_GIT_TOKEN = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($OCI_GIT_TOKEN))
```

Use with git credential helper:

```powershell
git -c credential.helper='!f() { echo username=$OCI_GIT_USERNAME; echo password=$OCI_GIT_TOKEN; }; f' ls-remote <oci_devops_repo_url>
```
