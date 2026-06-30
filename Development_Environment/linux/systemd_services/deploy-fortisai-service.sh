#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_NAME="fortisai.service"
MONITOR_SERVICE_NAME="fortisai_monitor.service"
DEPRECATED_SERVICE_NAMES=("fortisai_model.service")
SERVICE_SOURCE="$SCRIPT_DIR/$SERVICE_NAME"
MONITOR_SERVICE_SOURCE="$SCRIPT_DIR/$MONITOR_SERVICE_NAME"
CONTROL_SOURCE="$SCRIPT_DIR/fortisai-control.sh"
MONITOR_WRAPPER_SOURCE="$SCRIPT_DIR/fortisai-monitor-service.sh"
MODEL_UPDATE_SOURCE="$SCRIPT_DIR/model_update.py"
TEST_LLAMA_MODELS_SOURCE="$SCRIPT_DIR/test_llama_models.py"
DEPLOY_USER="${DEPLOY_USER:-${SUDO_USER:-$(id -un)}}"
DEPLOY_HOME="$(getent passwd "$DEPLOY_USER" | cut -d: -f6)"
DEPLOY_UID="$(id -u "$DEPLOY_USER" 2>/dev/null || getent passwd "$DEPLOY_USER" | cut -d: -f3)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ACTIVE_HOST="${FORTISAI_ACTIVE_HOST:-$(hostname -s | tr '[:upper:]' '[:lower:]')}"
MODEL_VENV_DIR="${MODEL_VENV_DIR:-$DEPLOY_HOME/fortisai-dev/model-service-venv}"
WATCHDOG_DIR="${FORTISAI_WATCHDOG_DIR:-$DEPLOY_HOME/fortisai-dev/watchdog}"
RUNTIME_ACTIVE_HOSTS_FILE="${FORTISAI_ACTIVE_HOSTS_FILE:-$WATCHDOG_DIR/active_host.json}"
WATCHDOWN_FILE="${FORTISAI_WATCHDOWN_FILE:-$WATCHDOG_DIR/watchdown.json}"
ACTIVE_HOSTS_SEED_FILE="$REPO_ROOT/Development_Environment/linux/active_host.json"
SYSTEMD_DIR="/etc/systemd/system"
ENABLE_SERVICE="${ENABLE_SERVICE:-0}"
ENABLE_MONITOR_SERVICE="${ENABLE_MONITOR_SERVICE:-0}"

sudo_if_needed() {
  if [[ $EUID -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

run_as_deploy_user() {
  if [[ $EUID -eq 0 ]]; then
    sudo -H -u "$DEPLOY_USER" "$@"
  else
    "$@"
  fi
}

if [[ ! -f "$SERVICE_SOURCE" ]]; then
  echo "ERROR: missing service file: $SERVICE_SOURCE" >&2
  exit 1
fi

if [[ ! -f "$CONTROL_SOURCE" ]]; then
  echo "ERROR: missing control script: $CONTROL_SOURCE" >&2
  exit 1
fi

if [[ ! -f "$MONITOR_SERVICE_SOURCE" ]]; then
  echo "ERROR: missing service file: $MONITOR_SERVICE_SOURCE" >&2
  exit 1
fi

if [[ ! -f "$MODEL_UPDATE_SOURCE" ]]; then
  echo "ERROR: missing model update script: $MODEL_UPDATE_SOURCE" >&2
  exit 1
fi

if [[ ! -f "$TEST_LLAMA_MODELS_SOURCE" ]]; then
  echo "ERROR: missing llama model test script: $TEST_LLAMA_MODELS_SOURCE" >&2
  exit 1
fi

if [[ ! -f "$MONITOR_WRAPPER_SOURCE" ]]; then
  echo "ERROR: missing monitor wrapper script: $MONITOR_WRAPPER_SOURCE" >&2
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  echo "ERROR: sudo is required to deploy $SERVICE_NAME" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: python3 is required to provision monitor/model maintenance runtime" >&2
  exit 1
fi

if [[ -z "$DEPLOY_HOME" ]]; then
  echo "ERROR: unable to resolve home directory for deploy user: $DEPLOY_USER" >&2
  exit 1
fi

if [[ -z "$DEPLOY_UID" ]]; then
  echo "ERROR: unable to resolve uid for deploy user: $DEPLOY_USER" >&2
  exit 1
fi

if [[ ! -f "$ACTIVE_HOSTS_SEED_FILE" ]]; then
  echo "ERROR: missing active host seed file: $ACTIVE_HOSTS_SEED_FILE" >&2
  exit 1
fi

render_unit() {
  local source="$1"
  local target="$2"
  python3 - "$source" "$target" "$DEPLOY_USER" "$DEPLOY_HOME" "$DEPLOY_UID" "$MODEL_VENV_DIR" "$REPO_ROOT" "$ACTIVE_HOST" "$WATCHDOG_DIR" "$RUNTIME_ACTIVE_HOSTS_FILE" "$WATCHDOWN_FILE" <<'PY'
import sys
from pathlib import Path

source, target, deploy_user, deploy_home, deploy_uid, model_venv, repo_root, active_host, watchdog_dir, runtime_active_hosts_file, watchdown_file = sys.argv[1:12]
text = Path(source).read_text()
replacements = {
    "@DEPLOY_USER@": deploy_user,
    "@DEPLOY_HOME@": deploy_home,
    "@DEPLOY_UID@": deploy_uid,
    "@MODEL_VENV_DIR@": model_venv,
    "@REPO_ROOT@": repo_root,
    "@ACTIVE_HOST@": active_host,
    "@WATCHDOG_DIR@": watchdog_dir,
    "@RUNTIME_ACTIVE_HOSTS_FILE@": runtime_active_hosts_file,
    "@WATCHDOWN_FILE@": watchdown_file,
}
for token, value in replacements.items():
    text = text.replace(token, value)
if "@" in text:
    unresolved = [token for token in replacements if token in text]
    if unresolved:
        raise SystemExit(f"Unresolved systemd template token(s) in {source}: {unresolved}")
Path(target).write_text(text)
PY
}

chmod 755 "$CONTROL_SOURCE"
chmod 755 "$MONITOR_WRAPPER_SOURCE"
chmod 755 "$MODEL_UPDATE_SOURCE"
chmod 755 "$TEST_LLAMA_MODELS_SOURCE"

run_as_deploy_user python3 - "$WATCHDOG_DIR" "$RUNTIME_ACTIVE_HOSTS_FILE" "$WATCHDOWN_FILE" "$ACTIVE_HOSTS_SEED_FILE" <<'PY'
import json
import shutil
import sys
from pathlib import Path

watchdog_dir, runtime_active_hosts, watchdown_file, active_hosts_seed = map(Path, sys.argv[1:5])
watchdog_dir.mkdir(parents=True, exist_ok=True)

if not runtime_active_hosts.exists():
    shutil.copy2(active_hosts_seed, runtime_active_hosts)

if not watchdown_file.exists():
    watchdown_file.write_text(json.dumps({"activity": True}, indent=2) + "\n", encoding="utf-8")
PY

MODEL_VENV_PARENT="$(dirname "$MODEL_VENV_DIR")"
if [[ $EUID -eq 0 ]]; then
  mkdir -p "$MODEL_VENV_PARENT"
  chown "$DEPLOY_USER":"$DEPLOY_USER" "$MODEL_VENV_PARENT"
  if [[ -d "$MODEL_VENV_DIR" ]]; then
    chown -R "$DEPLOY_USER":"$DEPLOY_USER" "$MODEL_VENV_DIR"
  fi
else
  mkdir -p "$MODEL_VENV_PARENT"
fi

if [[ ! -d "$MODEL_VENV_DIR" ]]; then
  run_as_deploy_user python3 -m venv "$MODEL_VENV_DIR"
fi

if ! run_as_deploy_user "$MODEL_VENV_DIR/bin/python" -m pip --version >/dev/null 2>&1; then
  run_as_deploy_user "$MODEL_VENV_DIR/bin/python" -m ensurepip --upgrade >/dev/null
fi

run_as_deploy_user "$MODEL_VENV_DIR/bin/python" -m pip install --upgrade pip setuptools wheel >/dev/null
run_as_deploy_user "$MODEL_VENV_DIR/bin/python" -m pip install --upgrade requests apscheduler huggingface_hub >/dev/null

SERVICE_RENDERED="$(mktemp)"
MONITOR_SERVICE_RENDERED="$(mktemp)"
trap 'rm -f "$SERVICE_RENDERED" "$MONITOR_SERVICE_RENDERED"' EXIT
render_unit "$SERVICE_SOURCE" "$SERVICE_RENDERED"
render_unit "$MONITOR_SERVICE_SOURCE" "$MONITOR_SERVICE_RENDERED"

sudo_if_needed install -m 644 "$SERVICE_RENDERED" "$SYSTEMD_DIR/$SERVICE_NAME"
sudo_if_needed install -m 644 "$MONITOR_SERVICE_RENDERED" "$SYSTEMD_DIR/$MONITOR_SERVICE_NAME"
sudo_if_needed systemctl daemon-reload

for deprecated_service in "${DEPRECATED_SERVICE_NAMES[@]}"; do
  sudo_if_needed systemctl disable --now "$deprecated_service" >/dev/null 2>&1 || true
done

if [[ "$ENABLE_SERVICE" == "1" ]]; then
  sudo_if_needed systemctl enable "$SERVICE_NAME"
fi

if [[ "$ENABLE_MONITOR_SERVICE" == "1" ]]; then
  sudo_if_needed systemctl enable "$MONITOR_SERVICE_NAME"
fi

echo "Installed $SERVICE_NAME to $SYSTEMD_DIR/$SERVICE_NAME"
echo "Installed $MONITOR_SERVICE_NAME to $SYSTEMD_DIR/$MONITOR_SERVICE_NAME"
for deprecated_service in "${DEPRECATED_SERVICE_NAMES[@]}"; do
  echo "Deprecated inactive service disabled if present: $deprecated_service"
done
echo "Control script permissions set to 755: $CONTROL_SOURCE"
echo "Monitor wrapper permissions set to 755: $MONITOR_WRAPPER_SOURCE"
echo "Model updater script permissions set to 755: $MODEL_UPDATE_SOURCE"
echo "Llama model test script permissions set to 755: $TEST_LLAMA_MODELS_SOURCE"
echo "Model service venv ready: $MODEL_VENV_DIR"
echo "Rendered service user: $DEPLOY_USER ($DEPLOY_UID)"
echo "Rendered repository root: $REPO_ROOT"
echo "Rendered active host: $ACTIVE_HOST"
echo "Runtime watchdog directory: $WATCHDOG_DIR"
echo "Runtime active host inventory: $RUNTIME_ACTIVE_HOSTS_FILE"
echo "Watchdog activity control: $WATCHDOWN_FILE"
if [[ "$ENABLE_SERVICE" == "1" ]]; then
  echo "Service enabled"
else
  echo "Service not enabled. Set ENABLE_SERVICE=1 to enable during deployment."
fi

if [[ "$ENABLE_MONITOR_SERVICE" == "1" ]]; then
  echo "Monitor service enabled"
else
  echo "Monitor service not enabled. Set ENABLE_MONITOR_SERVICE=1 to enable during deployment."
fi
