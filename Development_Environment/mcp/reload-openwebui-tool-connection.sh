#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

DEFAULT_IMPORT_JSON="$SCRIPT_DIR/dify-mcp/openwebui-dify-mcp-tools.import.json"
IMPORT_JSON_ARG="${1:-$DEFAULT_IMPORT_JSON}"
OPENWEBUI_CONTAINER="${OPENWEBUI_CONTAINER:-fortisai-openwebui}"
OPENWEBUI_VALIDATE_TOOL_URL="${OPENWEBUI_VALIDATE_TOOL_URL:-true}"

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

IMPORT_JSON="$(resolve_path "$IMPORT_JSON_ARG" || true)"
if [[ ! -f "$IMPORT_JSON" ]]; then
  echo "ERROR: Tool import payload not found: $IMPORT_JSON_ARG"
  exit 1
fi

if ! podman exec "$OPENWEBUI_CONTAINER" true >/dev/null 2>&1; then
  echo "ERROR: OpenWebUI container is not running: $OPENWEBUI_CONTAINER"
  exit 1
fi

read -r connection_name openapi_url < <(IMPORT_JSON="$IMPORT_JSON" python3 - <<'PY'
import json
import os
from pathlib import Path

payload = json.loads(Path(os.environ["IMPORT_JSON"]).read_text(encoding="utf-8"))
entry = payload[0] if isinstance(payload, list) and payload else payload
name = ((entry.get("info") or {}).get("name")) or entry.get("name") or ""
url = str(entry.get("url", "")).rstrip("/")
path = str(entry.get("path", "openapi.json")).lstrip("/")
openapi_url = str(entry.get("openapi_url") or (f"{url}/{path}" if url and path else ""))
print(name, openapi_url)
PY
)

if [[ -z "$connection_name" ]]; then
  echo "ERROR: Could not resolve connection name from payload: $IMPORT_JSON"
  exit 1
fi

payload_json="$(python3 - "$IMPORT_JSON" <<'PY'
import json
import sys
from pathlib import Path

payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
entry = payload[0] if isinstance(payload, list) and payload else payload
print(json.dumps(entry, separators=(",", ":")))
PY
)"

podman exec -i \
  -e OPENWEBUI_TOOL_PAYLOAD="$payload_json" \
  -e OPENWEBUI_TOOL_NAME="$connection_name" \
  "$OPENWEBUI_CONTAINER" python - <<'PY'
import json
import os
import sqlite3
import sys

payload = json.loads(os.environ["OPENWEBUI_TOOL_PAYLOAD"])
name = os.environ["OPENWEBUI_TOOL_NAME"]

con = sqlite3.connect("/app/backend/data/webui.db")
try:
    cur = con.cursor()
    row = cur.execute("SELECT id, data FROM config ORDER BY id DESC LIMIT 1").fetchone()
    if not row:
        print("ERROR: OpenWebUI config row not found", file=sys.stderr)
        raise SystemExit(1)

    config_id, config_json = row
    cfg = json.loads(config_json or "{}")
    conns = cfg.setdefault("tool_server", {}).setdefault("connections", [])

    replaced = False
    for idx, entry in enumerate(conns):
        if not isinstance(entry, dict):
            continue
        entry_name = ((entry.get("info") or {}).get("name")) or entry.get("name")
        if entry_name == name:
            conns[idx] = payload
            replaced = True
            break

    if not replaced:
        conns.append(payload)

    cur.execute("UPDATE config SET data = ? WHERE id = ?", (json.dumps(cfg), config_id))
    con.commit()

    verify_row = cur.execute("SELECT data FROM config WHERE id = ?", (config_id,)).fetchone()
    verify_cfg = json.loads((verify_row or ["{}"])[0] or "{}")
    verify_conns = verify_cfg.get("tool_server", {}).get("connections", [])
    if not any(isinstance(item, dict) and (((item.get("info") or {}).get("name")) or item.get("name")) == name for item in verify_conns):
        print(f"ERROR: Tool connection not found after update: {name}", file=sys.stderr)
        raise SystemExit(1)
finally:
    con.close()

print(f"tool_connection_reloaded={name}")
print(f"tool_connection_action={'updated' if replaced else 'created'}")
PY

if [[ "$OPENWEBUI_VALIDATE_TOOL_URL" == "true" && -n "$openapi_url" ]]; then
  validate_output="$(podman exec -i -e OPENWEBUI_TOOL_OPENAPI_URL="$openapi_url" "$OPENWEBUI_CONTAINER" python - <<'PY' 2>&1 || true
import os
import urllib.error
import urllib.request

url = os.environ["OPENWEBUI_TOOL_OPENAPI_URL"]
try:
    with urllib.request.urlopen(url, timeout=8) as response:
        print(f"tool_connection_openapi_http={getattr(response, 'status', 200)}")
except urllib.error.HTTPError as exc:
    print(f"tool_connection_openapi_http={exc.code}")
    raise SystemExit(1)
except Exception as exc:
    print(f"tool_connection_openapi_error={type(exc).__name__}")
    raise SystemExit(1)
PY
)"
  if [[ "$validate_output" == tool_connection_openapi_http=2* ]]; then
    printf '%s\n' "$validate_output"
  else
    printf '%s\n' "$validate_output"
    echo "WARNING: Tool connection was reloaded, but OpenWebUI container could not fetch the OpenAPI URL."
  fi
fi
