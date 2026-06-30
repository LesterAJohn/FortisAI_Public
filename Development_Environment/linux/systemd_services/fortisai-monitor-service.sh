#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_BIN="${PYTHON_BIN:-${VIRTUAL_ENV:-$HOME/fortisai-dev/model-service-venv}/bin/python}"
SUPERVISE_INTERVAL_SECONDS="${FORTISAI_MONITOR_SUPERVISE_INTERVAL_SECONDS:-5}"
RESTART_DELAY_SECONDS="${FORTISAI_MONITOR_RESTART_DELAY_SECONDS:-15}"

COMPONENTS=(
  podman_monitor
  model_update
  llama_model_tests
)

declare -A COMPONENT_PIDS=()

log() {
  printf '[fortisai-monitor-service] %s\n' "$*"
}

start_component() {
  local name="$1"

  case "$name" in
    podman_monitor)
      log "starting podman_monitor.py"
      "$PYTHON_BIN" "$SCRIPT_DIR/podman_monitor.py" &
      ;;
    model_update)
      log "starting model_update.py scheduler"
      "$PYTHON_BIN" "$SCRIPT_DIR/model_update.py" &
      ;;
    llama_model_tests)
      log "starting test_llama_models.py scheduler"
      "$PYTHON_BIN" "$SCRIPT_DIR/test_llama_models.py" scheduler &
      ;;
    *)
      log "unknown component: $name"
      return 1
      ;;
  esac

  COMPONENT_PIDS["$name"]="$!"
  log "$name pid=${COMPONENT_PIDS[$name]}"
}

stop_components() {
  local name pid

  trap - TERM INT
  log "stopping child components"
  for name in "${COMPONENTS[@]}"; do
    pid="${COMPONENT_PIDS[$name]:-}"
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
    fi
  done

  for name in "${COMPONENTS[@]}"; do
    pid="${COMPONENT_PIDS[$name]:-}"
    if [[ -n "$pid" ]]; then
      wait "$pid" 2>/dev/null || true
    fi
  done
}

trap 'stop_components; exit 0' TERM INT

if [[ ! -x "$PYTHON_BIN" ]]; then
  log "python runtime is not executable: $PYTHON_BIN"
  exit 1
fi

for name in "${COMPONENTS[@]}"; do
  start_component "$name"
done

while true; do
  for name in "${COMPONENTS[@]}"; do
    pid="${COMPONENT_PIDS[$name]:-}"
    if [[ -z "$pid" ]] || ! kill -0 "$pid" 2>/dev/null; then
      set +e
      wait "$pid" 2>/dev/null
      exit_code="$?"
      set -e
      if [[ "$exit_code" == "0" ]]; then
        log "$name exited cleanly; leaving it stopped"
        COMPONENT_PIDS["$name"]=""
        continue
      fi
      log "$name exited with status $exit_code; restarting in ${RESTART_DELAY_SECONDS}s"
      sleep "$RESTART_DELAY_SECONDS"
      start_component "$name"
    fi
  done
  sleep "$SUPERVISE_INTERVAL_SECONDS"
done
