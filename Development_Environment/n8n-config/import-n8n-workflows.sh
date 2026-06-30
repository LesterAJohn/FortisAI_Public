#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${N8N_WORKFLOW_CONFIG_DIR:-$SCRIPT_DIR/main/n8n/configurations}"
CONTAINER_NAME="${N8N_CONTAINER_NAME:-fortisai-n8n}"
API_URL="${N8N_API_URL:-http://127.0.0.1:5678/api/v1}"
ACTIVATION_METHOD="${N8N_ACTIVATION_METHOD:-auto}"
CONTAINER_IMPORT_DIR="${N8N_CONTAINER_IMPORT_DIR:-/tmp/fortisai-n8n-workflow-import}"
DRY_RUN=false
SKIP_ACTIVATE=false
INCLUDE_EMPTY=false
RESTART_AFTER_CLI_ACTIVATE="${N8N_RESTART_AFTER_CLI_ACTIVATE:-true}"

usage() {
  cat <<USAGE
Usage: $(basename "$0") [options]

Imports source-controlled FortisAI n8n workflows into a running n8n container.

Options:
  --config-dir DIR     Workflow JSON directory (default: Development_Environment/n8n-config/main/n8n/configurations)
  --container NAME     n8n container name (default: fortisai-n8n)
  --api-url URL        n8n public API base URL (default: http://127.0.0.1:5678/api/v1)
  --activation-method MODE
                      Activation method: auto, api, or cli (default: auto)
  --include-empty      Import workflows with zero nodes; skipped by default
  --skip-activate      Import only; do not activate active workflows
  --dry-run            Validate and list workflows without importing
  -h, --help           Show this help

Environment:
  N8N_API_KEY          Used for public API activation when available
  N8N_ACTIVATION_METHOD
                      Activation method override: auto, api, or cli
USAGE
}

log() { printf '[n8n-import] %s\n' "$*"; }
err() { printf '[n8n-import] ERROR: %s\n' "$*" >&2; }
require_cmd() { command -v "$1" >/dev/null 2>&1 || { err "Missing required command: $1"; exit 1; }; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config-dir) CONFIG_DIR="$2"; shift 2 ;;
    --container) CONTAINER_NAME="$2"; shift 2 ;;
    --api-url) API_URL="$2"; shift 2 ;;
    --activation-method) ACTIVATION_METHOD="$2"; shift 2 ;;
    --include-empty) INCLUDE_EMPTY=true; shift ;;
    --skip-activate) SKIP_ACTIVATE=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown option: $1"; usage; exit 1 ;;
  esac
done

case "$ACTIVATION_METHOD" in
  auto|api|cli) ;;
  *) err "Invalid activation method: $ACTIVATION_METHOD"; usage; exit 1 ;;
esac

require_cmd jq
require_cmd podman
require_cmd curl

if [[ ! -d "$CONFIG_DIR" ]]; then
  err "Workflow config directory not found: $CONFIG_DIR"
  exit 1
fi

mapfile -t workflow_files < <(find "$CONFIG_DIR" -maxdepth 1 -type f -name '*.json' | sort)
if [[ ${#workflow_files[@]} -eq 0 ]]; then
  log "No workflow JSON files found in $CONFIG_DIR"
  exit 0
fi

selected_files=()
active_ids=()
for file in "${workflow_files[@]}"; do
  jq empty "$file"
  name="$(jq -r '.name // empty' "$file")"
  id="$(jq -r '.id // empty' "$file")"
  nodes="$(jq -r 'if (.nodes|type)=="array" then (.nodes|length) else -1 end' "$file")"
  active="$(jq -r 'if .active == true then "true" else "false" end' "$file")"

  if [[ -z "$name" || -z "$id" || "$nodes" == "-1" ]]; then
    log "Skipping invalid workflow JSON: $file"
    continue
  fi
  if [[ "$nodes" == "0" && "$INCLUDE_EMPTY" != "true" ]]; then
    log "Skipping zero-node workflow: $name ($id)"
    continue
  fi

  log "Selected workflow: $name ($id), nodes=$nodes, active=$active"
  selected_files+=("$file")
  [[ "$active" == "true" ]] && active_ids+=("$id")
done

if [[ ${#selected_files[@]} -eq 0 ]]; then
  log "No importable workflow files selected"
  exit 0
fi

if [[ "$DRY_RUN" == "true" ]]; then
  log "Dry run complete; no workflows imported"
  exit 0
fi

if ! podman inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
  err "n8n container not found: $CONTAINER_NAME"
  exit 1
fi

work_dir="$(mktemp -d /tmp/fortisai-n8n-import.XXXXXX)"
cleanup() { rm -rf "$work_dir"; }
trap cleanup EXIT

for file in "${selected_files[@]}"; do
  jq 'del(.tags, .versionId)' "$file" > "$work_dir/$(basename "$file")"
done

podman exec "$CONTAINER_NAME" sh -lc "rm -rf '$CONTAINER_IMPORT_DIR' && mkdir -p '$CONTAINER_IMPORT_DIR'"
podman cp "$work_dir/." "$CONTAINER_NAME:$CONTAINER_IMPORT_DIR"
podman exec "$CONTAINER_NAME" n8n import:workflow --separate --input="$CONTAINER_IMPORT_DIR"

activate_with_api() {
  local id="$1"
  local response_file="$work_dir/activate-$id.json"
  local http_code active message

  http_code="$(curl -sS -o "$response_file" -w '%{http_code}' -X POST \
    -H "X-N8N-API-KEY: $N8N_API_KEY" \
    "$API_URL/workflows/$id/activate")"
  if [[ "$http_code" != 2* ]]; then
    message="$(jq -r '.message // .error // empty' "$response_file" 2>/dev/null || true)"
    log "Public API activation failed for $id (HTTP $http_code) ${message}"
    return 1
  fi

  active="$(curl -sS -H "X-N8N-API-KEY: $N8N_API_KEY" "$API_URL/workflows/$id" | jq -r '.active // false')"
  [[ "$active" == "true" ]]
}

activate_with_cli() {
  local id="$1"

  podman exec "$CONTAINER_NAME" n8n update:workflow --id="$id" --active=true >/dev/null 2>&1
  podman exec "$CONTAINER_NAME" n8n list:workflow --active=true --onlyId | grep -Fxq "$id"
}

restart_n8n_if_needed() {
  if [[ "$RESTART_AFTER_CLI_ACTIVATE" == "true" ]]; then
    log "Restarting n8n so CLI activation is loaded by the running server"
    podman restart "$CONTAINER_NAME" >/dev/null
  else
    log "CLI activation was used; restart n8n before relying on scheduled triggers"
  fi
}

if [[ "$SKIP_ACTIVATE" == "true" || ${#active_ids[@]} -eq 0 ]]; then
  log "Import complete"
  exit 0
fi

if [[ -z "${N8N_API_KEY:-}" ]]; then
  if [[ "$ACTIVATION_METHOD" == "api" ]]; then
    err "N8N_API_KEY is required when activation method is api"
    err "Set N8N_API_KEY or run through the FortisAI helper so it can be loaded from Vault"
    exit 1
  fi
  log "N8N_API_KEY is not set; using local n8n CLI activation"
fi

restart_required=false
for id in "${active_ids[@]}"; do
  activated=false

  if [[ "$ACTIVATION_METHOD" != "cli" && -n "${N8N_API_KEY:-}" ]]; then
    if activate_with_api "$id"; then
      activated=true
    elif [[ "$ACTIVATION_METHOD" == "api" ]]; then
      err "Failed to activate workflow $id through the public API"
      exit 1
    fi
  fi

  if [[ "$activated" != "true" ]]; then
    log "Activating workflow with local n8n CLI: $id"
    if ! activate_with_cli "$id"; then
      err "Failed to activate workflow $id through the local n8n CLI"
      exit 1
    fi
    restart_required=true
  fi

  log "Activated workflow: $id"
done

[[ "$restart_required" == "true" ]] && restart_n8n_if_needed

log "Import and activation complete"
