#!/usr/bin/env python3
import requests
import json
import os
import socket
import shutil
from pathlib import Path
import subprocess
import sys
from importlib.util import find_spec
from datetime import datetime, timezone

def default_models_dir():
    storage_dir = "/db/AI/llm_directory"
    if os.path.isdir(storage_dir):
        return storage_dir
    return os.path.expanduser("~/FortisAI/Development_Environment/llm_directory")


BASE_DIR = os.path.abspath(os.path.expanduser(os.environ.get("LLAMA_MODELS_DIR", default_models_dir())))
STATE_FILE = os.path.join(BASE_DIR, "model_state.json")
DEFAULT_DOWNLOAD_EXCLUDES = (
    "*mmproj*.gguf",
    "*MMProj*.gguf",
    "*BF16*.gguf",
    "*bf16*.gguf",
    "*FP16*.gguf",
    "*fp16*.gguf",
)
ACTIVE_HOSTS_FILE = Path(
    os.environ.get(
        "FORTISAI_ACTIVE_HOSTS_FILE",
        Path(os.environ.get("FORTISAI_WATCHDOG_DIR", Path.home() / "fortisai-dev" / "watchdog")) / "active_host.json",
    )
).expanduser()
ACTIVE_HOSTS_SEED_FILE = Path(
    os.environ.get(
        "FORTISAI_ACTIVE_HOSTS_SEED_FILE",
        Path(__file__).resolve().parents[1] / "active_host.json",
    )
).expanduser()

os.makedirs(BASE_DIR, exist_ok=True)

PROVIDERS = {
    "meta": "meta-llama",
    "qwen": "Qwen",
    "mistral": "mistralai",
    "deepseek": "deepseek-ai",
    "microsoft": "microsoft",
    "google": "google"
}


def active_host_name():
    configured = os.environ.get("FORTISAI_ACTIVE_HOST", "").strip()
    if configured:
        return configured.lower().split(".", 1)[0]
    return socket.gethostname().strip().lower().split(".", 1)[0]


def active_host_entry(hostname=None):
    host_name = (hostname or active_host_name()).strip().lower().split(".", 1)[0]
    if not ACTIVE_HOSTS_FILE.exists() and ACTIVE_HOSTS_SEED_FILE.exists():
        ACTIVE_HOSTS_FILE.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ACTIVE_HOSTS_SEED_FILE, ACTIVE_HOSTS_FILE)
    if not ACTIVE_HOSTS_FILE.exists():
        raise FileNotFoundError(f"Active host inventory not found: {ACTIVE_HOSTS_FILE}")
    with ACTIVE_HOSTS_FILE.open(encoding="utf-8") as config_file:
        data = json.load(config_file)
    hosts = data.get("hosts", {})
    if not isinstance(hosts, dict):
        raise ValueError("active_host.json hosts must be a JSON object")
    for key, value in hosts.items():
        if not isinstance(value, dict):
            continue
        names = {
            str(key).strip().lower().split(".", 1)[0],
            str(value.get("hostname", "")).strip().lower().split(".", 1)[0],
        }
        if host_name in names:
            return host_name, value
    available = ", ".join(sorted(str(key) for key in hosts)) or "<none>"
    raise ValueError(f"Host '{host_name}' not found in {ACTIVE_HOSTS_FILE}; available hosts: {available}")


def active_host_bool(flag_name, default=False):
    host_name, host = active_host_entry()
    value = host.get(flag_name, default)
    if isinstance(value, bool):
        return host_name, value
    if isinstance(value, str):
        normalized = value.strip().lower()
        if normalized in {"1", "true", "yes", "on"}:
            return host_name, True
        if normalized in {"0", "false", "no", "off"}:
            return host_name, False
    raise ValueError(f"{flag_name} must be a boolean for host '{host_name}' in {ACTIVE_HOSTS_FILE}")


def should_run_for_active_host(flag_name):
    host_name, enabled = active_host_bool(flag_name, default=False)
    if enabled:
        print(f"{flag_name}=true for active host {host_name}; continuing.")
        return True
    print(f"{flag_name}=false for active host {host_name}; exiting without work.")
    return False

# ---------------------------------------------------------
# 1. Ensure huggingface_hub + hf CLI are installed
# ---------------------------------------------------------
def require_python_package(import_name, package_name=None):
    pkg = package_name or import_name
    if find_spec(import_name) is None:
        raise RuntimeError(
            f"Missing required Python package '{pkg}'. "
            "Run ./linux/systemd_services/deploy-fortisai-service.sh to provision the model service venv."
        )


def ensure_huggingface_cli():
    print("Checking for huggingface_hub...")
    require_python_package("huggingface_hub")
    print("huggingface_hub already installed.")

    if not huggingface_cli_path():
        raise RuntimeError("hf CLI not found in PATH. Re-run deploy-fortisai-service.sh to provision model service dependencies.")

    print("huggingface_hub and hf CLI ready.\n")


def huggingface_cli_path():
    override = os.environ.get("HF_CLI")
    candidates = [
        override,
        shutil.which("hf"),
        shutil.which("huggingface-cli"),
        os.path.expanduser("~/.local/bin/hf"),
        os.path.expanduser("~/.local/bin/huggingface-cli"),
        os.path.join(os.path.dirname(sys.executable), "hf"),
        os.path.join(os.path.dirname(sys.executable), "huggingface-cli"),
    ]
    for candidate in candidates:
        if candidate and os.path.isfile(candidate) and os.access(candidate, os.X_OK):
            return candidate
    return None

# ---------------------------------------------------------
# 2. State management
# ---------------------------------------------------------
def load_state():
    if not os.path.exists(STATE_FILE):
        return {}
    with open(STATE_FILE) as f:
        return json.load(f)

def save_state(state):
    with open(STATE_FILE, "w") as f:
        json.dump(state, f, indent=2)

# ---------------------------------------------------------
# 3. Hugging Face search + GGUF detection
# ---------------------------------------------------------
def hf_search(org):
    url = f"https://huggingface.co/api/models?author={org}"
    r = requests.get(url, timeout=15)
    r.raise_for_status()
    return r.json()

def find_latest_gguf(models):
    gguf_models = [
        m for m in models
        if "gguf" in json.dumps(m).lower()
    ]
    if not gguf_models:
        return None
    gguf_models.sort(key=lambda x: x.get("lastModified", ""), reverse=True)
    return gguf_models[0]["modelId"]

# ---------------------------------------------------------
# 4. Download model using hf CLI
# ---------------------------------------------------------
def download_model(provider, model_id):
    target_dir = os.path.join(BASE_DIR, provider, model_id.replace("/", "_"))
    os.makedirs(target_dir, exist_ok=True)

    print(f"Downloading {provider}: {model_id}")
    cmd = [
        huggingface_cli_path(), "download", model_id,
        "--include", "*.gguf",
        "--local-dir", target_dir,
        "--max-workers", os.environ.get("HF_DOWNLOAD_MAX_WORKERS", "1"),
    ]
    for pattern in download_excludes():
        cmd.extend(["--exclude", pattern])
    subprocess.run(cmd, check=True, timeout=int(os.environ.get("HF_DOWNLOAD_TIMEOUT_SECONDS", "900")))


def download_excludes():
    raw = os.environ.get("HF_DOWNLOAD_EXCLUDE_GLOBS")
    if raw is None:
        return list(DEFAULT_DOWNLOAD_EXCLUDES)
    return [item.strip() for item in raw.split(",") if item.strip()]

# ---------------------------------------------------------
# 5. Provider update logic
# ---------------------------------------------------------
def update_provider(provider, org):
    print(f"\nChecking provider: {provider}")
    state = load_state()
    models = hf_search(org)
    latest = find_latest_gguf(models)

    if not latest:
        print(f"No GGUF models found for {provider}")
        return None

    if state.get(provider) != latest:
        download_model(provider, latest)
    else:
        print(f"{provider} already current: {latest}")

    return latest

# ---------------------------------------------------------
# 6. Run updates
# ---------------------------------------------------------
def run_updates():
    if not should_run_for_active_host("model_update"):
        return

    previous_state = load_state()
    errors = {}
    new_state = {
        "timestamp": datetime.now(timezone.utc).isoformat()
    }

    for provider, org in PROVIDERS.items():
        try:
            latest = update_provider(provider, org)
        except Exception as exc:
            latest = previous_state.get(provider)
            errors[provider] = str(exc)
            print(f"ERROR: provider update failed for {provider}: {exc}")
        new_state[provider] = latest

    if errors:
        new_state["errors"] = errors

    save_state(new_state)

    print("\nModel update complete.")
    print(json.dumps(new_state, indent=2))

# ---------------------------------------------------------
# 7. scheduler
# ---------------------------------------------------------
def ensure_runtime_dependencies(include_scheduler=False):
    require_python_package("requests")
    ensure_huggingface_cli()
    if include_scheduler:
        require_python_package("apscheduler")


def scheduler_main():
    if not should_run_for_active_host("model_update"):
        return

    ensure_runtime_dependencies(include_scheduler=True)

    try:
        from apscheduler.schedulers.blocking import BlockingScheduler

        scheduler = BlockingScheduler(timezone="America/New_York")
        scheduler.add_job(
            run_updates,
            "cron",
            day=1,
            hour=12,
            minute=0,
            id="monthly_model_update_1200_eastern_day_1",
            replace_existing=True,
        )
        scheduler.start()
    except Exception as e:
        print(f"APScheduler error: {e}")
        raise


def main():
    if not should_run_for_active_host("model_update"):
        return

    if len(sys.argv) > 1 and sys.argv[1] in {"run-once", "once", "update-now"}:
        ensure_runtime_dependencies(include_scheduler=False)
        run_updates()
        return
    scheduler_main()


if __name__ == "__main__":
    main()
