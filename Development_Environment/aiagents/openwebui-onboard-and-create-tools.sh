#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

OPENWEBUI_URL="${OPENWEBUI_URL:-http://localhost:3000}"
HERMES_BASE_URL="${HERMES_BASE_URL:-}"
OPENCLAW_BASE_URL="${OPENCLAW_BASE_URL:-}"
HERMES_TOOL_ID="${HERMES_TOOL_ID:-fortisai_hermes_chat_tool}"
OPENCLAW_TOOL_ID="${OPENCLAW_TOOL_ID:-fortisai_openclaw_chat_tool}"
HERMES_SKILL_ID="${HERMES_SKILL_ID:-fortisai-hermes-tool-skill}"
OPENCLAW_SKILL_ID="${OPENCLAW_SKILL_ID:-fortisai-openclaw-tool-skill}"

HERMES_SCRIPT="$REPO_ROOT/Development_Environment/aiagents/openwebui-create-hermes-tool.sh"
OPENCLAW_SCRIPT="$REPO_ROOT/Development_Environment/aiagents/openwebui-create-openclaw-tool.sh"
HERMES_SKILL_SCRIPT="$REPO_ROOT/Development_Environment/aiagents/openwebui-create-hermes-skill.sh"
OPENCLAW_SKILL_SCRIPT="$REPO_ROOT/Development_Environment/aiagents/openwebui-create-openclaw-skill.sh"

if [[ -z "$HERMES_BASE_URL" || -z "$OPENCLAW_BASE_URL" ]]; then
  if command -v podman >/dev/null 2>&1 && \
    [[ "$(podman inspect fortisai-coredns --format '{{.State.Running}}' 2>/dev/null || true)" == "true" ]]; then
    HERMES_BASE_URL="${HERMES_BASE_URL:-http://fortisai-hermes.fortisai.local:8642/v1}"
    OPENCLAW_BASE_URL="${OPENCLAW_BASE_URL:-http://fortisai-claw-gateway.fortisai.local:18789/v1}"
  else
    HERMES_BASE_URL="${HERMES_BASE_URL:-http://fortisai-hermes:8642/v1}"
    OPENCLAW_BASE_URL="${OPENCLAW_BASE_URL:-http://fortisai-claw-gateway:18789/v1}"
  fi
fi

resource_exists() {
  local resource_type="$1"
  local resource_id="$2"

  OPENWEBUI_URL="$OPENWEBUI_URL" \
  OPENWEBUI_BEARER_TOKEN="$OPENWEBUI_BEARER_TOKEN" \
  RESOURCE_TYPE="$resource_type" \
  RESOURCE_ID="$resource_id" \
  python3 - <<'PY'
import json
import os
import urllib.request

base_url = os.environ["OPENWEBUI_URL"].rstrip("/")
token = os.environ["OPENWEBUI_BEARER_TOKEN"]
resource_type = os.environ["RESOURCE_TYPE"]
resource_id = os.environ["RESOURCE_ID"]

req = urllib.request.Request(
    f"{base_url}/api/v1/{resource_type}/",
    headers={"Authorization": f"Bearer {token}"},
)

with urllib.request.urlopen(req, timeout=30) as resp:
    data = json.load(resp)

items = data if isinstance(data, list) else data.get("items", data.get("data", []))
ids = [item.get("id") for item in items if isinstance(item, dict)]
raise SystemExit(0 if resource_id in ids else 1)
PY
}

echo "Step 1: Confirm OpenWebUI is reachable"
if ! curl -fsS "$OPENWEBUI_URL/api/version" >/dev/null; then
  echo "ERROR: OpenWebUI is not reachable at $OPENWEBUI_URL"
  echo "Tip: set OPENWEBUI_URL if OpenWebUI runs on a different host/port."
  exit 1
fi
echo "OK: OpenWebUI responded at $OPENWEBUI_URL"

echo
echo "Step 3: Confirm backend endpoints are configured and expected"
echo "Hermes base URL:   $HERMES_BASE_URL"
echo "OpenClaw base URL: $OPENCLAW_BASE_URL"
read -r -p "Have you verified these endpoints are reachable from OpenWebUI? [y/N]: " prereq3_ok
prereq3_ok_lc="$(printf '%s' "$prereq3_ok" | tr '[:upper:]' '[:lower:]')"
case "$prereq3_ok_lc" in
  y|yes)
    ;;
  *)
    echo "Aborting. Verify prerequisite 3, then rerun this helper."
    exit 1
    ;;
esac

echo
echo "Step 2: Capture OpenWebUI bearer token"
if [[ -z "${OPENWEBUI_BEARER_TOKEN:-}" ]]; then
  read -r -s -p "Enter OPENWEBUI_BEARER_TOKEN: " OPENWEBUI_BEARER_TOKEN
  echo
fi

if [[ -z "${OPENWEBUI_BEARER_TOKEN:-}" ]]; then
  echo "ERROR: OPENWEBUI_BEARER_TOKEN is required."
  exit 1
fi

export OPENWEBUI_URL
export OPENWEBUI_BEARER_TOKEN

if [[ ! -f "$HERMES_SCRIPT" ]]; then
  echo "ERROR: Missing script $HERMES_SCRIPT"
  exit 1
fi
if [[ ! -f "$OPENCLAW_SCRIPT" ]]; then
  echo "ERROR: Missing script $OPENCLAW_SCRIPT"
  exit 1
fi
if [[ ! -f "$HERMES_SKILL_SCRIPT" ]]; then
  echo "ERROR: Missing script $HERMES_SKILL_SCRIPT"
  exit 1
fi
if [[ ! -f "$OPENCLAW_SKILL_SCRIPT" ]]; then
  echo "ERROR: Missing script $OPENCLAW_SKILL_SCRIPT"
  exit 1
fi

echo
if resource_exists tools "$HERMES_TOOL_ID"; then
  echo "Hermes tool already exists: $HERMES_TOOL_ID"
else
  echo "Creating Hermes tool..."
  bash "$HERMES_SCRIPT"
fi

echo
if resource_exists tools "$OPENCLAW_TOOL_ID"; then
  echo "OpenClaw tool already exists: $OPENCLAW_TOOL_ID"
else
  echo "Creating OpenClaw tool..."
  bash < "$OPENCLAW_SCRIPT"
fi

echo
if resource_exists skills "$HERMES_SKILL_ID"; then
  echo "Hermes skill already exists: $HERMES_SKILL_ID"
else
  echo "Creating Hermes skill..."
  bash "$HERMES_SKILL_SCRIPT"
fi

echo
if resource_exists skills "$OPENCLAW_SKILL_ID"; then
  echo "OpenClaw skill already exists: $OPENCLAW_SKILL_ID"
else
  echo "Creating OpenClaw skill..."
  bash < "$OPENCLAW_SKILL_SCRIPT"
fi

echo
echo "Done. Listing tools and skills to verify IDs..."
OPENWEBUI_URL="$OPENWEBUI_URL" \
OPENWEBUI_BEARER_TOKEN="$OPENWEBUI_BEARER_TOKEN" \
HERMES_TOOL_ID="$HERMES_TOOL_ID" \
OPENCLAW_TOOL_ID="$OPENCLAW_TOOL_ID" \
HERMES_SKILL_ID="$HERMES_SKILL_ID" \
OPENCLAW_SKILL_ID="$OPENCLAW_SKILL_ID" \
python3 - <<'PY'
import json
import os
import urllib.request

base_url = os.environ["OPENWEBUI_URL"].rstrip("/")
token = os.environ["OPENWEBUI_BEARER_TOKEN"]

def fetch_ids(resource_type):
    req = urllib.request.Request(
        f"{base_url}/api/v1/{resource_type}/",
        headers={"Authorization": f"Bearer {token}"},
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        data = json.load(resp)
    items = data if isinstance(data, list) else data.get("items", data.get("data", []))
    return [item.get("id") for item in items if isinstance(item, dict)]

tool_ids = fetch_ids("tools")
skill_ids = fetch_ids("skills")

for label, resource_id, resource_ids in [
    ("hermes_tool", os.environ["HERMES_TOOL_ID"], tool_ids),
    ("openclaw_tool", os.environ["OPENCLAW_TOOL_ID"], tool_ids),
    ("hermes_skill", os.environ["HERMES_SKILL_ID"], skill_ids),
    ("openclaw_skill", os.environ["OPENCLAW_SKILL_ID"], skill_ids),
]:
    print(f"{label}={resource_id in resource_ids}")
PY
