#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
HELPER="$ROOT_DIR/Development_Environment/mac/fortisai-dev-helper.sh"
TS="$(date +%Y%m%d-%H%M%S)"
REPORT_DIR="${FORTISAI_REPORT_DIR:-$HOME/fortisai-item2-reports}"
REPORT_FILE="$REPORT_DIR/item2-longlived-$TS.log"

mkdir -p "$REPORT_DIR"

log() {
  echo "[$(date +%H:%M:%S)] $*" | tee -a "$REPORT_FILE"
}

run_and_log() {
  local title="$1"
  shift
  log "----- $title -----"
  {
    echo "$ $*"
    "$@"
  } >> "$REPORT_FILE" 2>&1
}

log "Item 2 external long-lived validation started"
log "Workspace root: $ROOT_DIR"
log "Helper: $HELPER"
log "Report: $REPORT_FILE"

if [[ ! -x "$HELPER" ]]; then
  log "ERROR: helper not found or not executable: $HELPER"
  exit 1
fi

run_and_log "Helper version and help" "$HELPER" help

log "Starting full stack"
run_and_log "Helper up" "$HELPER" up

log "Running health checks"
run_and_log "Helper check" "$HELPER" check

log "Collecting status"
run_and_log "Helper status" "$HELPER" status

log "Collecting key endpoint checks"
run_and_log "curl n8n" curl -sS -o /dev/null -w "n8n HTTP %{http_code}\n" http://localhost:5678
run_and_log "curl openwebui" curl -sS -o /dev/null -w "openwebui HTTP %{http_code}\n" http://localhost:3000
run_and_log "curl dify" curl -sS -o /dev/null -w "dify HTTP %{http_code}\n" http://localhost:8081
run_and_log "curl honcho health" curl -sS -o /dev/null -w "honcho HTTP %{http_code}\n" http://127.0.0.1:8010/health
run_and_log "curl openclaw health" curl -sS -o /dev/null -w "openclaw HTTP %{http_code}\n" http://127.0.0.1:18789/health
run_and_log "curl qdrant collections" curl -sS -H "api-key: difyai123456" -o /dev/null -w "qdrant HTTP %{http_code}\n" http://127.0.0.1:6333/collections
run_and_log "curl ords" curl -sS -o /dev/null -w "ords HTTP %{http_code}\n" http://127.0.0.1:8181/ords/
run_and_log "curl oracle node api" curl -sS -o /dev/null -w "oracle-node-api HTTP %{http_code}\n" http://127.0.0.1:8090/health

log "Collecting container snapshot"
run_and_log "podman ps" podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

log "Collecting listener snapshot"
run_and_log "lsof listeners" lsof -nP -iTCP -sTCP:LISTEN

log "Capturing service log tails"
run_and_log "podman logs honcho api" podman logs --tail 200 fortisai-honcho-api
run_and_log "podman logs honcho deriver" podman logs --tail 200 fortisai-honcho-deriver
run_and_log "podman logs openclaw" podman logs --tail 200 fortisai-openclaw
run_and_log "podman logs ords" podman logs --tail 200 fortisai-ords

log "Validation completed"
log "Report written to: $REPORT_FILE"

echo "$REPORT_FILE"
