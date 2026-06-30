#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

OPENWEBUI_URL="${OPENWEBUI_URL:-http://127.0.0.1:3000}"
OPENWEBUI_CONTAINER="${OPENWEBUI_CONTAINER:-fortisai-openwebui}"
OPENWEBUI_API_USER="${OPENWEBUI_API_USER:-${FORTISAI_OPENWEBUI_DEFAULT_API_KEY_USER:-LesterAJohn@gmail.com}}"
DEFAULT_SKILL_JSON="$SCRIPT_DIR/dify-mcp/openwebui-dify-mcp-skill.create.json"
SKILL_JSON_ARG="${1:-$DEFAULT_SKILL_JSON}"

resolve_path() {
  local candidate="$1"

  if [[ "$candidate" = /* && -f "$candidate" ]]; then
    printf '%s\n' "$candidate"
    return 0
  fi
  if [[ -f "$candidate" ]]; then
    (cd "$(dirname "$candidate")" && printf '%s/%s\n' "$PWD" "$(basename "$candidate")")
    return 0
  fi
  if [[ -f "$SCRIPT_DIR/$candidate" ]]; then
    (cd "$(dirname "$SCRIPT_DIR/$candidate")" && printf '%s/%s\n' "$PWD" "$(basename "$candidate")")
    return 0
  fi
  if [[ -f "$REPO_ROOT/$candidate" ]]; then
    (cd "$(dirname "$REPO_ROOT/$candidate")" && printf '%s/%s\n' "$PWD" "$(basename "$candidate")")
    return 0
  fi

  printf '%s\n' "$candidate"
  return 1
}

SKILL_JSON="$(resolve_path "$SKILL_JSON_ARG" || true)"
if [[ ! -f "$SKILL_JSON" ]]; then
  echo "ERROR: Skill payload not found: $SKILL_JSON_ARG"
  exit 1
fi

if ! podman exec "$OPENWEBUI_CONTAINER" true >/dev/null 2>&1; then
  echo "ERROR: OpenWebUI container is not running: $OPENWEBUI_CONTAINER"
  exit 1
fi

openwebui_user_secret_segment() {
  local value="${1:-}"
  VALUE="$value" python3 - <<'PY'
import os
import re
print(re.sub(r"[^a-z0-9]+", "_", os.environ.get("VALUE", "").strip().lower()).strip("_"), end="")
PY
}

vault_openwebui_token() {
  local keys_file="${VAULT_KEYS_FILE:-$HOME/fortisai-dev/vault/vault-init.json}"
  local api_addr="${VAULT_API_ADDR:-http://127.0.0.1:8200}"
  local root_token payload user_segment

  [[ -f "$keys_file" ]] || return 0
  root_token="$(VAULT_KEYS_FILE="$keys_file" python3 - <<'PY' 2>/dev/null || true
import json
import os
from pathlib import Path

payload = json.loads(Path(os.environ["VAULT_KEYS_FILE"]).read_text(encoding="utf-8"))
print(payload.get("root_token", ""))
PY
)"
  [[ -n "$root_token" ]] || return 0

  user_segment="$(openwebui_user_secret_segment "$OPENWEBUI_API_USER")"
  if [[ -n "$user_segment" ]]; then
    payload="$(curl -fsS --max-time 10 \
      -H "X-Vault-Token: $root_token" \
      "$api_addr/v1/secret/data/fortisai/dev/openwebui/users/$user_segment/api_key" 2>/dev/null || true)"
    if [[ -n "$payload" ]]; then
      PAYLOAD="$payload" python3 - <<'PY' 2>/dev/null || true
import json
import os
payload = json.loads(os.environ["PAYLOAD"])
print(payload.get("data", {}).get("data", {}).get("value", ""), end="")
PY
      return 0
    fi
  fi

  return 0
}

vault_store_openwebui_token() {
  local token="$1"
  local keys_file="${VAULT_KEYS_FILE:-$HOME/fortisai-dev/vault/vault-init.json}"
  local api_addr="${VAULT_API_ADDR:-http://127.0.0.1:8200}"
  local root_token payload user_segment vault_path

  [[ -n "$token" && -f "$keys_file" ]] || return 0
  root_token="$(VAULT_KEYS_FILE="$keys_file" python3 - <<'PY' 2>/dev/null || true
import json
import os
from pathlib import Path

payload = json.loads(Path(os.environ["VAULT_KEYS_FILE"]).read_text(encoding="utf-8"))
print(payload.get("root_token", ""))
PY
)"
  [[ -n "$root_token" ]] || return 0

  payload="$(TOKEN_VALUE="$token" python3 - <<'PY'
import json
import os

print(json.dumps({"data": {"value": os.environ["TOKEN_VALUE"]}}))
PY
)"
  user_segment="$(openwebui_user_secret_segment "$OPENWEBUI_API_USER")"
  if [[ -n "$user_segment" ]]; then
    vault_path="openwebui/users/$user_segment/api_key"
  else
    echo "WARN: OPENWEBUI_API_USER is empty or invalid; not storing OpenWebUI token in Vault." >&2
    return 0
  fi
  curl -fsS --max-time 10 \
    -X POST \
    -H "X-Vault-Token: $root_token" \
    -H "Content-Type: application/json" \
    --data "$payload" \
    "$api_addr/v1/secret/data/fortisai/dev/$vault_path" >/dev/null 2>&1 || true
}

read -r skill_id skill_name < <(SKILL_JSON="$SKILL_JSON" python3 - <<'PY'
import json
import os
from pathlib import Path

payload = json.loads(Path(os.environ["SKILL_JSON"]).read_text(encoding="utf-8"))
print(str(payload.get("id", "")).strip(), str(payload.get("name", "")).strip())
PY
)

if [[ -z "$skill_id" ]]; then
  echo "ERROR: Skill payload does not include an id: $SKILL_JSON"
  exit 1
fi

OPENWEBUI_BEARER_TOKEN="${OPENWEBUI_BEARER_TOKEN:-${OPENWEBUI_API_KEY:-}}"
if [[ -z "$OPENWEBUI_BEARER_TOKEN" ]]; then
  OPENWEBUI_BEARER_TOKEN="$(vault_openwebui_token)"
  if [[ -n "$OPENWEBUI_BEARER_TOKEN" ]]; then
    echo "OPENWEBUI_BEARER_TOKEN was not set; using user-scoped token from FortisAI Vault for $OPENWEBUI_API_USER."
  fi
fi

if [[ -z "$OPENWEBUI_BEARER_TOKEN" ]]; then
  OPENWEBUI_BEARER_TOKEN="$(podman exec "$OPENWEBUI_CONTAINER" python - <<'PY' 2>/dev/null || true
import sqlite3

con = sqlite3.connect("/app/backend/data/webui.db")
try:
    cur = con.cursor()
    row = cur.execute("select key from api_key order by created_at desc limit 1").fetchone()
    print(row[0] if row else "")
finally:
    con.close()
PY
)"
  if [[ -n "$OPENWEBUI_BEARER_TOKEN" ]]; then
    echo "OPENWEBUI_BEARER_TOKEN was not set; using latest token from $OPENWEBUI_CONTAINER api_key table."
  else
    echo "ERROR: OPENWEBUI_BEARER_TOKEN is not set and no token was found in $OPENWEBUI_CONTAINER."
    echo "Set OPENWEBUI_BEARER_TOKEN/OPENWEBUI_API_KEY, or store a user key with: fortisai-dev-helper.sh openwebui-api <user email> <api key>."
    exit 1
  fi
fi

vault_store_openwebui_token "$OPENWEBUI_BEARER_TOKEN"

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/openwebui-skill.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

skills_json="$tmp_dir/skills.json"
list_code="$(curl -sS -o "$skills_json" -w '%{http_code}' \
  "$OPENWEBUI_URL/api/v1/skills/" \
  -H "Authorization: Bearer $OPENWEBUI_BEARER_TOKEN" || true)"

if [[ "$list_code" != 2* ]]; then
  echo "ERROR: Could not list OpenWebUI skills (HTTP $list_code)"
  sed -n '1,80p' "$skills_json" || true
  exit 1
fi

existing_id="$(SKILLS_JSON="$skills_json" SKILL_ID="$skill_id" python3 - <<'PY'
import json
import os
from pathlib import Path

payload = json.loads(Path(os.environ["SKILLS_JSON"]).read_text(encoding="utf-8") or "[]")
skills = payload if isinstance(payload, list) else payload.get("data", [])
skill_id = os.environ["SKILL_ID"]
print(next((str(item.get("id", "")) for item in skills if isinstance(item, dict) and item.get("id") == skill_id), ""))
PY
)"

if [[ -n "$existing_id" ]]; then
  delete_json="$tmp_dir/delete.json"
  delete_code="$(curl -sS -o "$delete_json" -w '%{http_code}' \
    -X DELETE "$OPENWEBUI_URL/api/v1/skills/id/$existing_id/delete" \
    -H "Authorization: Bearer $OPENWEBUI_BEARER_TOKEN" || true)"
  if [[ "$delete_code" != 2* ]]; then
    echo "ERROR: Could not delete existing OpenWebUI skill $existing_id (HTTP $delete_code)"
    sed -n '1,80p' "$delete_json" || true
    exit 1
  fi
  echo "skill_deleted=$existing_id"
fi

create_json="$tmp_dir/create.json"
create_code="$(curl -sS -o "$create_json" -w '%{http_code}' \
  -X POST "$OPENWEBUI_URL/api/v1/skills/create" \
  -H "Authorization: Bearer $OPENWEBUI_BEARER_TOKEN" \
  -H "Content-Type: application/json" \
  --data-binary @"$SKILL_JSON" || true)"

if [[ "$create_code" != 2* ]]; then
  echo "ERROR: Could not create OpenWebUI skill $skill_id (HTTP $create_code)"
  sed -n '1,120p' "$create_json" || true
  exit 1
fi

created_summary="$(CREATE_JSON="$create_json" python3 - <<'PY'
import json
import os
from pathlib import Path

payload = json.loads(Path(os.environ["CREATE_JSON"]).read_text(encoding="utf-8") or "{}")
print(f"skill_created={payload.get('id', '')} name={payload.get('name', '')}")
PY
)"
echo "$created_summary"

verify_json="$tmp_dir/verify.json"
verify_code="$(curl -sS -o "$verify_json" -w '%{http_code}' \
  "$OPENWEBUI_URL/api/v1/skills/" \
  -H "Authorization: Bearer $OPENWEBUI_BEARER_TOKEN" || true)"

if [[ "$verify_code" != 2* ]]; then
  echo "ERROR: Could not verify OpenWebUI skill list (HTTP $verify_code)"
  sed -n '1,80p' "$verify_json" || true
  exit 1
fi

verified="$(SKILLS_JSON="$verify_json" SKILL_ID="$skill_id" python3 - <<'PY'
import json
import os
from pathlib import Path

payload = json.loads(Path(os.environ["SKILLS_JSON"]).read_text(encoding="utf-8") or "[]")
skills = payload if isinstance(payload, list) else payload.get("data", [])
skill_id = os.environ["SKILL_ID"]
print("yes" if any(isinstance(item, dict) and item.get("id") == skill_id for item in skills) else "no")
PY
)"

if [[ "$verified" != "yes" ]]; then
  echo "ERROR: Skill was created but not found in OpenWebUI list: $skill_id"
  exit 1
fi

echo "skill_verified=$skill_id"
if [[ -n "$skill_name" ]]; then
  echo "skill_name=$skill_name"
fi
