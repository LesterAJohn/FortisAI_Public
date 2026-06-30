# AI Agent Scripts for OpenWebUI

This folder contains scripts that create OpenWebUI custom tools and skills for FortisAI agent backends.

## Files

- `openwebui-onboard-and-create-tools.sh` runs a guided flow: checks prerequisite 1, confirms prerequisite 3, prompts for step 2 bearer token, then creates or verifies both tools and both skills.
- `openwebui-create-hermes-tool.sh` creates a custom tool that forwards chat prompts to Hermes.
- `openwebui-create-openclaw-tool.sh` creates a custom tool that forwards chat prompts to OpenClaw.
- `openwebui-create-hermes-skill.sh` creates an OpenWebUI skill that tells agents when and how to use the Hermes tool.
- `openwebui-create-openclaw-skill.sh` creates an OpenWebUI skill that tells agents when and how to use the OpenClaw tool.

## Preferred Guided Flow

Use the focused helper to run the full sequence in one command:

```bash
cd /path/to/FortisAI
bash Development_Environment/aiagents/openwebui-onboard-and-create-tools.sh
```

What it enforces:

1. Confirms OpenWebUI is reachable.
2. Prompts for `OPENWEBUI_BEARER_TOKEN` (hidden input) if not already exported.
3. Requires confirmation that Hermes/OpenClaw endpoints are reachable from OpenWebUI.
4. Runs or skips Hermes/OpenClaw tool creation based on whether they already exist.
5. Runs or skips Hermes/OpenClaw skill creation based on whether they already exist.
6. Verifies the expected tool and skill ids are present.

## Prerequisites

1. OpenWebUI must be running and reachable.
2. You need an OpenWebUI bearer token with permission to create tools.
3. Hermes and/or OpenClaw service endpoints should be reachable from OpenWebUI.

Default local OpenWebUI URL used by scripts:

- `http://localhost:3000`

## Enable OpenWebUI API Access for These Scripts

1. Sign in to OpenWebUI.
2. Create or copy an API token/JWT suitable for API requests.
3. Export the token in your shell:

```bash
export OPENWEBUI_BEARER_TOKEN="<your_token_here>"
```

4. Optional: override OpenWebUI URL if not using localhost:3000:

```bash
export OPENWEBUI_URL="http://<host>:<port>"
```

## Create the Hermes Tool

```bash
cd /path/to/FortisAI
bash Development_Environment/aiagents/openwebui-create-hermes-tool.sh
```

Defaults in generated OpenWebUI tool content:

- base URL: `http://fortisai-hermes.fortisai.local:8642/v1` when CoreDNS is active, otherwise `http://fortisai-hermes:8642/v1`
- API key: `fortisai-hermes-dev-api-key`
- model: `default`

## Create the OpenClaw Tool

```bash
cd /path/to/FortisAI
bash Development_Environment/aiagents/openwebui-create-openclaw-tool.sh
```

Defaults in generated OpenWebUI tool content:

- base URL: `http://fortisai-claw-gateway.fortisai.local:18789/v1` when CoreDNS is active, otherwise `http://fortisai-claw-gateway:18789/v1`
- API key: `fortisai-claw-gateway-dev-token`
- model: `local-model`

## Create the Hermes Skill

```bash
cd /path/to/FortisAI
bash Development_Environment/aiagents/openwebui-create-hermes-skill.sh
```

Default skill id:

- `fortisai-hermes-tool-skill`

## Create the OpenClaw Skill

```bash
cd /path/to/FortisAI
bash Development_Environment/aiagents/openwebui-create-openclaw-skill.sh
```

Default skill id:

- `fortisai-openclaw-tool-skill`

## Verify Tool and Skill Creation via OpenWebUI API

List tools:

```bash
curl -sS "$OPENWEBUI_URL/api/v1/tools/" \
  -H "Authorization: Bearer $OPENWEBUI_BEARER_TOKEN"
```

Expected tool ids:

- `fortisai_hermes_chat_tool`
- `fortisai_openclaw_chat_tool`

List skills:

```bash
curl -sS "$OPENWEBUI_URL/api/v1/skills/" \
  -H "Authorization: Bearer $OPENWEBUI_BEARER_TOKEN"
```

Expected skill ids:

- `fortisai-hermes-tool-skill`
- `fortisai-openclaw-tool-skill`

## Troubleshooting

- HTTP 401/403: token missing, expired, or insufficient permission.
- HTTP 400/409: tool id may already exist, or payload shape differs by OpenWebUI version.
- Connection errors to Hermes/OpenClaw from tool runtime: verify container/network routing and endpoint URLs.
- If OpenWebUI runs in containers, ensure the tool URLs use container-reachable hostnames. Use `.fortisai.local` names when CoreDNS is active and short service names when it is not.

## Notes

- These scripts call `POST /api/v1/tools/create` directly.
- Skill convention: prefer referencing OpenWebUI tool ids/functions (for portability), and do not reference MCP server names here unless a skill is explicitly bridge-specific.
- Script defaults can be overridden via environment variables:
  - `OPENWEBUI_URL`
  - `OPENWEBUI_BEARER_TOKEN`
  - `TOOL_ID`
  - `TOOL_NAME`
  - `TOOL_DESCRIPTION`
