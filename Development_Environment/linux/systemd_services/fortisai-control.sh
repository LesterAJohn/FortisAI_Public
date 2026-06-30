#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEV_ENV_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
HELPER="$DEV_ENV_DIR/linux/fortisai-dev-helper.sh"
CALICO_DEPLOY_SCRIPT="$DEV_ENV_DIR/linux/deploy-calico-network.sh"
WATCHDOG_DIR="${FORTISAI_WATCHDOG_DIR:-$HOME/fortisai-dev/watchdog}"
ACTIVE_HOSTS_SEED_FILE="${FORTISAI_ACTIVE_HOSTS_SEED_FILE:-$DEV_ENV_DIR/linux/active_host.json}"
ACTIVE_HOSTS_FILE="${ACTIVE_HOSTS_FILE:-${FORTISAI_ACTIVE_HOSTS_FILE:-$WATCHDOG_DIR/active_host.json}}"
WATCHDOWN_FILE="${FORTISAI_WATCHDOWN_FILE:-$WATCHDOG_DIR/watchdown.json}"
ALL_UP_LOG_DIR="${HOME}/fortisai-dev/logs"
ALL_UP_LOG_FILE="$ALL_UP_LOG_DIR/fortisai-all-up.log"
ALL_UP_PID_FILE="$ALL_UP_LOG_DIR/fortisai-all-up.pid"
COREDNS_CONTAINER_NAME="${FORTISAI_COREDNS_CONTAINER_NAME:-fortisai-coredns}"

ensure_watchdog_runtime_files() {
  mkdir -p "$WATCHDOG_DIR"

  if [[ ! -f "$ACTIVE_HOSTS_FILE" ]]; then
    if [[ ! -f "$ACTIVE_HOSTS_SEED_FILE" ]]; then
      echo "ERROR: Active host seed file is missing: $ACTIVE_HOSTS_SEED_FILE" >&2
      return 1
    fi
    cp "$ACTIVE_HOSTS_SEED_FILE" "$ACTIVE_HOSTS_FILE"
  fi

  if [[ ! -f "$WATCHDOWN_FILE" ]]; then
    printf '{\n  "activity": true\n}\n' > "$WATCHDOWN_FILE"
  fi
}

is_primary_system() {
  local active_hosts_file="$ACTIVE_HOSTS_FILE"
  ensure_watchdog_runtime_files
  [[ -f "$active_hosts_file" ]] || return 0

  python3 - "$active_hosts_file" <<'PY'
import json
import socket
import sys
from pathlib import Path

path = Path(sys.argv[1])
host = socket.gethostname().split(".", 1)[0].lower()
payload = json.loads(path.read_text())
for key, entry in (payload.get("hosts") or {}).items():
    entry = entry or {}
    names = {
        str(key).split(".", 1)[0].lower(),
        str(entry.get("hostname") or key).split(".", 1)[0].lower(),
    }
    if host in names:
        raise SystemExit(0 if entry.get("primary_system", True) else 1)
raise SystemExit(0)
PY
}

is_all_up_running() {
  local pid="$1"
  if [[ -z "$pid" ]]; then
    return 1
  fi
  if ! kill -0 "$pid" >/dev/null 2>&1; then
    return 1
  fi
  local cmdline
  cmdline="$(ps -p "$pid" -o args= 2>/dev/null || true)"
  [[ "$cmdline" == *"fortisai-dev-helper.sh all-up"* ]]
}

stop_all_up_background() {
  if [[ ! -f "$ALL_UP_PID_FILE" ]]; then
    return 0
  fi

  local pid
  pid="$(cat "$ALL_UP_PID_FILE" 2>/dev/null || true)"
  if is_all_up_running "$pid"; then
    kill "$pid" >/dev/null 2>&1 || true
    for _ in {1..20}; do
      if ! kill -0 "$pid" >/dev/null 2>&1; then
        break
      fi
      sleep 1
    done
    if kill -0 "$pid" >/dev/null 2>&1; then
      kill -9 "$pid" >/dev/null 2>&1 || true
    fi
  fi

  rm -f "$ALL_UP_PID_FILE"
}

bootstrap_coredns() {
  cd "$DEV_ENV_DIR"
  ensure_watchdog_runtime_files

  if [[ ! -x "$CALICO_DEPLOY_SCRIPT" ]]; then
    echo "ERROR: Calico/CoreDNS deploy script is missing or not executable: $CALICO_DEPLOY_SCRIPT" >&2
    return 1
  fi

  if is_primary_system; then
    if ACTIVE_HOSTS_FILE="$ACTIVE_HOSTS_FILE" FORTISAI_ACTIVE_HOSTS_FILE="$ACTIVE_HOSTS_FILE" FORTISAI_WATCHDOG_DIR="$WATCHDOG_DIR" "$CALICO_DEPLOY_SCRIPT" --no-test; then
      return 0
    fi

    echo "WARN: cluster CoreDNS bootstrap failed; attempting local CoreDNS bootstrap" >&2
  fi

  ACTIVE_HOSTS_FILE="$ACTIVE_HOSTS_FILE" FORTISAI_ACTIVE_HOSTS_FILE="$ACTIVE_HOSTS_FILE" FORTISAI_WATCHDOG_DIR="$WATCHDOG_DIR" "$CALICO_DEPLOY_SCRIPT" --local-only --no-test
}

cleanup_prestart() {
  local cid name pod_id

  while IFS= read -r cid; do
    [[ -n "$cid" ]] || continue
    name="$(podman inspect "$cid" --format '{{.Name}}' 2>/dev/null | sed 's#^/##')"
    if [[ "$name" == "$COREDNS_CONTAINER_NAME" ]]; then
      continue
    fi
    podman rm -f "$cid" >/dev/null 2>&1 || true
  done < <(podman ps -aq --filter name=fortisai- 2>/dev/null || true)

  while IFS= read -r cid; do
    [[ -n "$cid" ]] || continue
    podman rm -f "$cid" >/dev/null 2>&1 || true
  done < <(podman ps -aq --filter network=fortisai-dev-net 2>/dev/null || true)

  while IFS= read -r pod_id; do
    [[ -n "$pod_id" ]] || continue
    podman pod rm -f "$pod_id" >/dev/null 2>&1 || true
  done < <(podman pod ps -q --filter name=fortisai- 2>/dev/null || true)
}

if [[ ! -x "$HELPER" ]]; then
  echo "ERROR: helper script is missing or not executable: $HELPER" >&2
  exit 1
fi

case "${1:-}" in
  start)
    cd "$DEV_ENV_DIR"
    bootstrap_coredns
    if ! is_primary_system; then
      echo "This is not primary system; CoreDNS bootstrap completed."
      exit 0
    fi
    FORTISAI_WATCHDOG_DIR="$WATCHDOG_DIR" FORTISAI_ACTIVE_HOSTS_FILE="$ACTIVE_HOSTS_FILE" FORTISAI_WATCHDOWN_FILE="$WATCHDOWN_FILE" exec "$HELPER" all-up &
    ;;
  start-nowait)
    cd "$DEV_ENV_DIR"
    mkdir -p "$ALL_UP_LOG_DIR"
    if [[ -f "$ALL_UP_PID_FILE" ]]; then
      existing_pid="$(cat "$ALL_UP_PID_FILE" 2>/dev/null || true)"
      if is_all_up_running "$existing_pid"; then
        echo "all-up already running in background (pid=$existing_pid)"
        exit 0
      fi
      rm -f "$ALL_UP_PID_FILE"
    fi
    bootstrap_coredns
    if ! is_primary_system; then
      echo "This is not primary system; CoreDNS bootstrap completed."
      exit 0
    fi
    FORTISAI_WATCHDOG_DIR="$WATCHDOG_DIR" FORTISAI_ACTIVE_HOSTS_FILE="$ACTIVE_HOSTS_FILE" FORTISAI_WATCHDOWN_FILE="$WATCHDOWN_FILE" nohup "$HELPER" all-up >>"$ALL_UP_LOG_FILE" 2>&1 &
    echo "$!" > "$ALL_UP_PID_FILE"
    ;;
  stop)
    cd "$DEV_ENV_DIR"
    stop_all_up_background
    if ! is_primary_system; then
      echo "This is not primary system; leaving CoreDNS managed by bootstrap."
      exit 0
    fi
    FORTISAI_WATCHDOG_DIR="$WATCHDOG_DIR" FORTISAI_ACTIVE_HOSTS_FILE="$ACTIVE_HOSTS_FILE" FORTISAI_WATCHDOWN_FILE="$WATCHDOWN_FILE" exec "$HELPER" all-down
    ;;
  restart)
    cd "$DEV_ENV_DIR"
    if ! is_primary_system; then
      bootstrap_coredns
      echo "This is not primary system; CoreDNS bootstrap completed."
      exit 0
    fi
    FORTISAI_WATCHDOG_DIR="$WATCHDOG_DIR" FORTISAI_ACTIVE_HOSTS_FILE="$ACTIVE_HOSTS_FILE" FORTISAI_WATCHDOWN_FILE="$WATCHDOWN_FILE" "$HELPER" all-down
    cleanup_prestart
    bootstrap_coredns
    FORTISAI_WATCHDOG_DIR="$WATCHDOG_DIR" FORTISAI_ACTIVE_HOSTS_FILE="$ACTIVE_HOSTS_FILE" FORTISAI_WATCHDOWN_FILE="$WATCHDOWN_FILE" exec "$HELPER" all-up &
    ;;
  bootstrap-coredns)
    bootstrap_coredns
    ;;
  cleanup-prestart)
    cleanup_prestart
    ;;
  is-primary)
    is_primary_system
    ;;
  *)
    echo "Usage: $0 {start|start-nowait|stop|restart|bootstrap-coredns|cleanup-prestart|is-primary}" >&2
    exit 2
    ;;
esac
