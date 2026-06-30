#!/usr/bin/env bash
set -euo pipefail

OPENWEBUI_URL="${OPENWEBUI_URL:-http://localhost:3000}"
OPENWEBUI_BEARER_TOKEN="${OPENWEBUI_BEARER_TOKEN:-}"
SKILL_ID="${SKILL_ID:-fortisai-openclaw-tool-skill}"
SKILL_NAME="${SKILL_NAME:-FortisAI OpenClaw Tool Skill}"
SKILL_DESCRIPTION="${SKILL_DESCRIPTION:-Guidance skill for using the FortisAI OpenClaw OpenWebUI tool.}"

if [[ -z "$OPENWEBUI_BEARER_TOKEN" ]]; then
  echo "ERROR: OPENWEBUI_BEARER_TOKEN is not set."
  echo "Set it first, for example:"
  echo "  export OPENWEBUI_BEARER_TOKEN='<token>'"
  exit 1
fi

read -r -d '' SKILL_CONTENT <<'SKILL' || true
Use this skill when the user wants requests delegated to the FortisAI OpenClaw tool inside OpenWebUI.

Required OpenWebUI tool:
- fortisai_openclaw_chat_tool

Tool procedure:
1. Use the fortisai_openclaw_chat_tool tool for requests that should be sent to OpenClaw.
2. Call the ask_openclaw function with a single prompt string that preserves the exact user task and any response-format requirements.
3. Prefer concise prompts and return the OpenClaw result directly when it satisfies the request.
4. If the tool result is partial or ambiguous, summarize the limitation and suggest the next useful refinement.
5. If the tool call fails, report the failure concisely with the tool name, error, and next suggested step.

When to use OpenClaw:
- local-model or gateway-routed chat tasks
- prompts that should run through the OpenClaw gateway
- requests where the user explicitly asks to use OpenClaw

Safety constraints:
- Do not expose API keys, bearer tokens, or internal credentials.
- Do not fabricate tool outputs; if the tool fails, say so.
- Ask for confirmation before destructive downstream actions.
SKILL

OPENWEBUI_URL="$OPENWEBUI_URL" \
OPENWEBUI_BEARER_TOKEN="$OPENWEBUI_BEARER_TOKEN" \
SKILL_ID="$SKILL_ID" \
SKILL_NAME="$SKILL_NAME" \
SKILL_DESCRIPTION="$SKILL_DESCRIPTION" \
SKILL_CONTENT="$SKILL_CONTENT" \
python3 - <<'PY'
import json
import os
import urllib.error
import urllib.request

base_url = os.environ["OPENWEBUI_URL"].rstrip("/")
token = os.environ["OPENWEBUI_BEARER_TOKEN"]
payload = {
    "id": os.environ["SKILL_ID"],
    "name": os.environ["SKILL_NAME"],
    "description": os.environ["SKILL_DESCRIPTION"],
    "content": os.environ["SKILL_CONTENT"],
    "meta": {
        "tags": ["fortisai", "openclaw", "openwebui", "tool", "agent"]
    },
    "is_active": True,
}

req = urllib.request.Request(
    f"{base_url}/api/v1/skills/create",
    data=json.dumps(payload).encode("utf-8"),
    headers={
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    },
    method="POST",
)

try:
    with urllib.request.urlopen(req, timeout=30) as resp:
        body = resp.read().decode("utf-8", "replace")
        print(f"create_http_code={resp.status}")
        print(body)
except urllib.error.HTTPError as exc:
    body = exc.read().decode("utf-8", "replace")
    print(f"create_http_code={exc.code}")
    print(body)
    raise SystemExit(1)
PY