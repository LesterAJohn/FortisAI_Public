#!/usr/bin/env bash
set -euo pipefail

OPENWEBUI_URL="${OPENWEBUI_URL:-http://localhost:3000}"
OPENWEBUI_BEARER_TOKEN="${OPENWEBUI_BEARER_TOKEN:-}"
SKILL_ID="${SKILL_ID:-fortisai-hermes-tool-skill}"
SKILL_NAME="${SKILL_NAME:-FortisAI Hermes Tool Skill}"
SKILL_DESCRIPTION="${SKILL_DESCRIPTION:-Guidance skill for using the FortisAI Hermes OpenWebUI tool.}"

if [[ -z "$OPENWEBUI_BEARER_TOKEN" ]]; then
  echo "ERROR: OPENWEBUI_BEARER_TOKEN is not set."
  echo "Set it first, for example:"
  echo "  export OPENWEBUI_BEARER_TOKEN='<token>'"
  exit 1
fi

read -r -d '' SKILL_CONTENT <<'SKILL' || true
Use this skill when the user wants agent-style chat reasoning delegated to the FortisAI Hermes tool inside OpenWebUI.

Required OpenWebUI tool:
- fortisai_hermes_chat_tool

Tool procedure:
1. Use the fortisai_hermes_chat_tool tool for requests that should be sent to Hermes.
2. Call the ask_hermes function with a single prompt string that contains the exact user task plus any needed formatting instruction.
3. Prefer short, direct prompts to Hermes and preserve user intent instead of paraphrasing aggressively.
4. If Hermes returns a useful final answer, present that result clearly and note when it came from Hermes.
5. If the tool call fails, report the failure concisely with the tool name, error, and next suggested step.

When to use Hermes:
- agent reasoning or orchestration tasks
- prompts that should run through the Hermes gateway
- requests where the user explicitly asks to use Hermes

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
        "tags": ["fortisai", "hermes", "openwebui", "tool", "agent"]
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