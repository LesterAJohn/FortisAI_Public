#!/usr/bin/env python3
"""
test_llama_models.py

Test/validation utility for Llama server models.
Verifies that Llama models are properly loaded, responsive, and generating valid responses.

This script can be run manually or scheduled via APScheduler to execute
automatically on the 1st day of each month at 3:00 PM (Eastern Time).
"""

import os
import re
import shutil
import signal
import sys
import json
import socket
import subprocess
import time
import urllib.request
import urllib.error
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional, List, Tuple

# ============================================================================
# Configuration
# ============================================================================

# Default environment variables
DEFAULT_CONTAINER_NAME = "fortisai-llama-server"
DEFAULT_LLAMA_URL = "http://127.0.0.1:8011"
DEFAULT_TEST_PROMPT = "Reply with a short sentence about this model and include the model name."
DEFAULT_DISABLE_FAILED = True
DEFAULT_RESET_BEFORE_TESTS = True
DEFAULT_RESET_AFTER_TESTS = True
DEFAULT_RESET_AFTER_DISABLE = True
DEFAULT_RESET_WAIT_SECONDS = 180
DEFAULT_TEST_MAX_TOKENS = 64
DEFAULT_TEST_TIMEOUT_SECONDS = 300
DEFAULT_TIMEOUT_RETRY_SECONDS = 600
DEFAULT_TIMEOUT_RETRY_DELAY_SECONDS = 10
DEFAULT_DISABLE_TIMEOUTS = True
DEFAULT_RESTORE_DISABLED_BEFORE_TESTS = True
SPLIT_SHARD_RE = re.compile(r"^(?P<prefix>.+)-(?P<index>\d{5})-of-(?P<count>\d{5})\.gguf$", re.IGNORECASE)
def default_llama_models_dir() -> str:
    storage_dir = "/db/AI/llm_directory"
    if os.path.isdir(storage_dir):
        return storage_dir
    return os.path.abspath(
        os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "llm_directory")
    )


DEFAULT_LLAMA_MODELS_DIR = default_llama_models_dir()
DEFAULT_LLAMA_ROUTER_ACTIVE_MODEL_FILE = os.path.expanduser("~/fortisai-dev/llama-router/active-model.path")
DEFAULT_DISABLED_MODELS_FILE = os.path.join(DEFAULT_LLAMA_MODELS_DIR, "disabled_models.json")
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

# ============================================================================
# Helper Functions
# ============================================================================

def active_host_name() -> str:
    configured = os.environ.get("FORTISAI_ACTIVE_HOST", "").strip()
    if configured:
        return configured.lower().split(".", 1)[0]
    return socket.gethostname().strip().lower().split(".", 1)[0]


def active_host_entry(hostname: Optional[str] = None) -> Tuple[str, dict]:
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


def active_host_bool(flag_name: str, default: bool = False) -> Tuple[str, bool]:
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


def should_run_for_active_host(flag_name: str) -> bool:
    host_name, enabled = active_host_bool(flag_name, default=False)
    if enabled:
        print(f"{flag_name}=true for active host {host_name}; continuing.")
        return True
    print(f"{flag_name}=false for active host {host_name}; exiting without work.")
    return False


def get_script_directory() -> str:
    """Get the directory containing this script."""
    return os.path.dirname(os.path.abspath(__file__))


def load_config() -> dict:
    """Load configuration from environment variables or use defaults."""
    disable_failed = env_bool("LLAMA_DISABLE_FAILED", DEFAULT_DISABLE_FAILED)
    legacy_delete_failed = env_bool("LLAMA_DELETE_FAILED", False)
    return {
        "container_name": os.environ.get("LLAMA_SERVER_CONTAINER_NAME", DEFAULT_CONTAINER_NAME),
        "llama_url": os.environ.get("LLAMA_SERVER_URL", DEFAULT_LLAMA_URL),
        "test_prompt": os.environ.get("LLAMA_TEST_PROMPT", DEFAULT_TEST_PROMPT),
        "test_max_tokens": int(os.environ.get("LLAMA_TEST_MAX_TOKENS", str(DEFAULT_TEST_MAX_TOKENS))),
        "test_timeout_seconds": int(os.environ.get("LLAMA_TEST_TIMEOUT_SECONDS", str(DEFAULT_TEST_TIMEOUT_SECONDS))),
        "timeout_retry_seconds": int(os.environ.get("LLAMA_TIMEOUT_RETRY_SECONDS", str(DEFAULT_TIMEOUT_RETRY_SECONDS))),
        "timeout_retry_delay_seconds": int(
            os.environ.get("LLAMA_TIMEOUT_RETRY_DELAY_SECONDS", str(DEFAULT_TIMEOUT_RETRY_DELAY_SECONDS))
        ),
        "disable_timeouts": env_bool("LLAMA_DISABLE_TIMEOUTS", DEFAULT_DISABLE_TIMEOUTS),
        "restore_disabled_before_tests": env_bool(
            "LLAMA_RESTORE_DISABLED_BEFORE_TESTS",
            DEFAULT_RESTORE_DISABLED_BEFORE_TESTS,
        ),
        "start_at_model": os.environ.get("LLAMA_START_AT_MODEL", "").strip(),
        "disable_failed": disable_failed or legacy_delete_failed,
        "legacy_delete_failed": legacy_delete_failed,
        "reset_before_tests": env_bool("LLAMA_RESET_BEFORE_TESTS", DEFAULT_RESET_BEFORE_TESTS),
        "reset_after_tests": env_bool("LLAMA_RESET_AFTER_TESTS", DEFAULT_RESET_AFTER_TESTS),
        "reset_after_disable": env_bool("LLAMA_RESET_AFTER_DISABLE", DEFAULT_RESET_AFTER_DISABLE),
        "reset_wait_seconds": int(os.environ.get("LLAMA_RESET_WAIT_SECONDS", str(DEFAULT_RESET_WAIT_SECONDS))),
        "models_dir": os.path.abspath(os.path.expanduser(os.environ.get("LLAMA_MODELS_DIR", DEFAULT_LLAMA_MODELS_DIR))),
        "active_model_file": os.path.abspath(
            os.path.expanduser(os.environ.get("LLAMA_ROUTER_ACTIVE_MODEL_FILE", DEFAULT_LLAMA_ROUTER_ACTIVE_MODEL_FILE))
        ),
        "disabled_models_file": os.path.abspath(
            os.path.expanduser(os.environ.get("LLAMA_DISABLED_MODELS_FILE", DEFAULT_DISABLED_MODELS_FILE))
        ),
    }


def get_helper_path(config: dict) -> str:
    """Get the path to the fortisai-dev-helper.sh script."""
    script_dir = get_script_directory()
    return os.path.abspath(os.path.join(script_dir, "..", "fortisai-dev-helper.sh"))


def get_controllers() -> dict:
    """Get the paths to the control scripts."""
    script_dir = get_script_directory()
    return {
        "control": os.path.join(script_dir, "fortisai-control.sh"),
        "model_update": os.path.join(script_dir, "model_update.py"),
        "monitor": os.path.join(script_dir, "podman_monitor.py"),
    }


def run_command(cmd: List[str], check: bool = True,
                capture_output: bool = True, timeout: int = 30) -> Tuple[int, Optional[str], Optional[str]]:
    """
    Run a shell command and return (return_code, stdout, stderr).
    
    Args:
        cmd: Command to execute (list of arguments)
        check: If True, raise exception on non-zero exit
        capture_output: If True, capture stdout and stderr
        timeout: Timeout in seconds
    
    Returns:
        Tuple of (return_code, stdout, stderr)
    """
    try:
        result = subprocess.run(
            cmd,
            check=check,
            capture_output=capture_output,
            text=True,
            timeout=timeout,
        )
        return (result.returncode, result.stdout, result.stderr)
    except subprocess.TimeoutExpired as e:
        return (1, None, f"Command timed out after {timeout}s: {e}")
    except FileNotFoundError as e:
        return (127, None, f"Command not found: {e}")
    except Exception as e:
        return (1, None, str(e))


def check_command_exists(cmd: str) -> bool:
    """Check if a command exists in PATH."""
    return run_command([cmd, "--version"], capture_output=True)[0] == 0


def env_bool(name: str, default: bool = False) -> bool:
    """Read common truthy/falsy environment values."""
    value = os.environ.get(name)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


def ensure_dependency(name: str, required: bool = True) -> bool:
    """Check if a required dependency exists."""
    if name == "curl":
        return check_command_exists("curl")
    elif name == "python3":
        return check_command_exists("python3")
    elif name == "podman":
        return check_command_exists("podman")
    elif name == "hf":
        return check_command_exists("hf")
    return False


# ============================================================================
# Llama Server Functions
# ============================================================================

def fetch_models(config: dict) -> Optional[List[str]]:
    """
    Fetch list of available models from the Llama server.
    
    Args:
        config: Configuration dictionary
    
    Returns:
        List of model IDs, or None on failure
    """
    try:
        url = f"{config['llama_url']}/v1/models"
        req = urllib.request.Request(
            url,
            headers={"Accept": "application/json"},
        )
        with urllib.request.urlopen(req, timeout=10) as response:
            if response.status != 200:
                print(f"ERROR: Failed to fetch models: HTTP {response.status}")
                return None
            data = json.loads(response.read().decode("utf-8"))
            models = [
                entry["id"]
                for entry in data.get("data", [])
                if entry.get("id")
            ]
            return models if models else None
    except urllib.error.URLError as e:
        print(f"ERROR: Failed to fetch models: {e}")
        return None
    except json.JSONDecodeError as e:
        print(f"ERROR: Invalid JSON response: {e}")
        return None


def _http_error_message(error: urllib.error.HTTPError) -> str:
    try:
        body = error.read().decode("utf-8", errors="replace")
    except Exception:
        body = ""
    if body:
        try:
            parsed = json.loads(body)
            message = parsed.get("error", {}).get("message") or parsed.get("message")
            if message:
                return f"HTTP {error.code}: {message}"
        except json.JSONDecodeError:
            pass
        return f"HTTP {error.code}: {body[:500]}"
    return f"HTTP {error.code}: {error.reason}"


def _request_timeout_handler(signum, frame):
    raise TimeoutError("request exceeded wall-clock timeout")


def invoke_model(config: dict, model_id: str, timeout_seconds: Optional[int] = None) -> Tuple[Optional[str], bool, str]:
    """
    Invoke a model with a test prompt.
    
    Args:
        config: Configuration dictionary
        model_id: Model identifier
    
    Returns:
        Tuple of (response_content, success, reason)
    """
    try:
        url = f"{config['llama_url']}/v1/chat/completions"
        payload = {
            "model": model_id,
            "messages": [{"role": "user", "content": config["test_prompt"]}],
            "max_tokens": config["test_max_tokens"],
            "temperature": 0,
        }
        body = json.dumps(payload).encode("utf-8")
        req = urllib.request.Request(
            url,
            data=body,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        request_timeout = timeout_seconds or config["test_timeout_seconds"]
        old_handler = None
        timer_enabled = hasattr(signal, "SIGALRM")
        if timer_enabled:
            old_handler = signal.signal(signal.SIGALRM, _request_timeout_handler)
            signal.setitimer(signal.ITIMER_REAL, request_timeout)
        try:
            with urllib.request.urlopen(req, timeout=request_timeout) as response:
                if response.status != 200:
                    reason = f"HTTP {response.status}"
                    print(f"ERROR: Model invocation failed: {reason}")
                    return (None, False, reason)
                data = json.loads(response.read().decode("utf-8"))
        finally:
            if timer_enabled:
                signal.setitimer(signal.ITIMER_REAL, 0)
                signal.signal(signal.SIGALRM, old_handler)
        choices = data.get("choices") or []
        if not choices:
            reason = "empty choices in response"
            print(f"ERROR: {reason}")
            return (None, False, reason)
        message = choices[0].get("message") or {}
        content = message.get("content") or ""
        return (content.strip(), True, "")
    except (TimeoutError, socket.timeout):
        request_timeout = timeout_seconds or config["test_timeout_seconds"]
        reason = f"timed out after {request_timeout}s"
        print(f"ERROR: Failed to invoke model: {reason}")
        return (None, False, reason)
    except urllib.error.HTTPError as e:
        reason = _http_error_message(e)
        print(f"ERROR: Failed to invoke model: {reason}")
        return (None, False, reason)
    except urllib.error.URLError as e:
        reason = str(e)
        print(f"ERROR: Failed to invoke model: {reason}")
        return (None, False, reason)
    except json.JSONDecodeError as e:
        reason = f"invalid JSON response: {e}"
        print(f"ERROR: {reason}")
        return (None, False, reason)
    except Exception as e:
        reason = f"unexpected error invoking model: {e}"
        print(f"ERROR: {reason}")
        return (None, False, reason)


def is_timeout_reason(reason: str) -> bool:
    return "timed out" in reason.lower() or "timeout" in reason.lower()


def invoke_model_with_retry(config: dict, model_id: str) -> Tuple[Optional[str], bool, str]:
    """Invoke a model, optionally giving slow first loads a longer retry window."""
    content, success, reason = invoke_model(config, model_id)
    if success or not is_timeout_reason(reason):
        return (content, success, reason)

    if config.get("disable_timeouts", DEFAULT_DISABLE_TIMEOUTS):
        return (content, False, f"{reason}; exceeded {config['test_timeout_seconds']}s responsiveness SLA")

    retry_seconds = config.get("timeout_retry_seconds", 0)
    if retry_seconds <= config["test_timeout_seconds"]:
        return (content, success, reason)

    delay_seconds = max(config.get("timeout_retry_delay_seconds", 0), 0)
    print(
        f"WARNING: {model_id} timed out during first validation request; "
        f"retrying once with {retry_seconds}s timeout after {delay_seconds}s"
    )
    if delay_seconds:
        time.sleep(delay_seconds)

    retry_content, retry_success, retry_reason = invoke_model(config, model_id, retry_seconds)
    if retry_success:
        return (retry_content, True, "")
    if is_timeout_reason(retry_reason):
        retry_reason = f"timed out after retry ({retry_seconds}s)"
    return (retry_content, False, retry_reason)


def is_hard_load_failure(reason: str) -> bool:
    """Return True when the failure points at an unloadable model file."""
    lower = reason.lower()
    hard_markers = (
        "not within file bounds",
        "failed to load",
        "error loading model",
        "unable to load model",
        "invalid model",
        "invalid gguf",
        "failed to allocate",
        "out of memory",
        "cuda error",
        "unsupported tensor",
        "unknown tensor",
        "tensor ",
        "timed out after retry",
    )
    return any(marker in lower for marker in hard_markers)


def is_disable_worthy_failure(config: dict, reason: str) -> bool:
    """Return True when validation should disable the local GGUF file."""
    if config.get("disable_timeouts", DEFAULT_DISABLE_TIMEOUTS) and is_timeout_reason(reason):
        return True
    return is_hard_load_failure(reason)


def split_shard_info(model_file: Path) -> Optional[dict]:
    match = SPLIT_SHARD_RE.match(model_file.name)
    if not match:
        return None
    try:
        return {
            "prefix": match.group("prefix"),
            "index": int(match.group("index")),
            "count": int(match.group("count")),
            "count_text": match.group("count"),
        }
    except ValueError:
        return None


def is_nonfirst_split_shard(model_file: Path) -> bool:
    info = split_shard_info(model_file)
    return bool(info and info["index"] != 1)


def split_first_shard_file(model_file: Path) -> Path:
    info = split_shard_info(model_file)
    if not info:
        return model_file
    return model_file.with_name(f"{info['prefix']}-00001-of-{info['count_text']}.gguf")


def split_enabled_shard_files(model_file: Path) -> List[Path]:
    info = split_shard_info(model_file)
    if not info:
        return [model_file]
    pattern = f"{info['prefix']}-?????-of-{info['count_text']}.gguf"
    return sorted(
        candidate
        for candidate in model_file.parent.glob(pattern)
        if candidate.is_file() and split_shard_info(candidate)
    )


def model_id_for_file(config: dict, model_file: Path) -> str:
    models_dir = Path(os.path.realpath(config["models_dir"]))
    try:
        rel_path = Path(os.path.realpath(model_file)).relative_to(models_dir)
        return str(rel_path.with_suffix("")).replace(os.sep, "__")
    except ValueError:
        return str(model_file.with_suffix(""))


def _is_path_inside(child: str, parent: str) -> bool:
    try:
        return os.path.commonpath([os.path.realpath(child), os.path.realpath(parent)]) == os.path.realpath(parent)
    except ValueError:
        return False


def resolve_model_file(config: dict, model_id: str) -> Optional[Path]:
    """
    Resolve a Llama server model ID to the backing GGUF file under LLAMA_MODELS_DIR.

    The router now points llama-server directly at the real model directory, so
    IDs may be absolute paths, relative paths, or relative paths with the `.gguf`
    suffix omitted by the OpenAI-compatible model list.

    Args:
        config: Configuration dictionary
        model_id: Model identifier

    Returns:
        Backing GGUF file path, or None when no safe local file can be found
    """
    models_dir = os.path.realpath(config["models_dir"])
    candidates = []
    seen = set()

    def add_candidate(path: Path) -> None:
        key = str(path)
        if key not in seen:
            seen.add(key)
            candidates.append(path)

    model_path = Path(model_id)
    if model_path.is_absolute():
        add_candidate(model_path)
    else:
        add_candidate(Path(models_dir) / model_id)
        if not model_id.endswith(".gguf"):
            add_candidate(Path(models_dir) / f"{model_id}.gguf")

        # Backwards-compatible lookup for any stale encoded IDs emitted by older
        # catalog-based runs while generated router config catches up.
        if "__" in model_id:
            decoded_id = model_id.replace("__", "/")
            add_candidate(Path(models_dir) / decoded_id)
            if not decoded_id.endswith(".gguf"):
                add_candidate(Path(models_dir) / f"{decoded_id}.gguf")

    for candidate in candidates:
        if candidate.exists():
            resolved = Path(os.path.realpath(candidate))
            if resolved.is_file() and resolved.name.endswith(".gguf") and _is_path_inside(str(resolved), models_dir):
                return resolved

    name = model_path.name
    if not name.endswith(".gguf"):
        name = f"{name}.gguf"
    matches = sorted(Path(models_dir).rglob(name))
    safe_matches = [
        Path(os.path.realpath(match)) for match in matches
        if match.is_file() and _is_path_inside(str(match), models_dir)
    ]
    if len(safe_matches) == 1:
        return safe_matches[0]
    if len(safe_matches) > 1:
        print(f"ERROR: Model ID {model_id} matched multiple local GGUF files; use a relative path")
        return None

    print(f"ERROR: Could not resolve model file for {model_id}")
    return None


def read_disabled_manifest(config: dict) -> dict:
    manifest_file = Path(config["disabled_models_file"])
    if not manifest_file.exists():
        return {"disabled_models": []}
    try:
        data = json.loads(manifest_file.read_text(encoding="utf-8"))
        if isinstance(data, dict) and isinstance(data.get("disabled_models"), list):
            return data
    except Exception:
        pass
    return {"disabled_models": []}


def write_disabled_manifest(config: dict, manifest: dict) -> None:
    manifest_file = Path(config["disabled_models_file"])
    manifest_file.parent.mkdir(parents=True, exist_ok=True)
    manifest_file.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def record_disabled_model(config: dict, model_id: str, model_file: Path, disabled_file: Path, reason: str) -> None:
    manifest = read_disabled_manifest(config)
    records = [
        item for item in manifest.get("disabled_models", [])
        if item.get("model_id") != model_id and item.get("original_path") != str(model_file)
    ]
    records.append({
        "disabled_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "model_id": model_id,
        "original_path": str(model_file),
        "disabled_path": str(disabled_file),
        "reason": reason,
    })
    manifest["disabled_models"] = records
    write_disabled_manifest(config, manifest)


def remove_disabled_manifest_records(config: dict, original_paths: set, disabled_paths: set) -> None:
    if not original_paths and not disabled_paths:
        return
    manifest = read_disabled_manifest(config)
    records = [
        item for item in manifest.get("disabled_models", [])
        if item.get("original_path") not in original_paths and item.get("disabled_path") not in disabled_paths
    ]
    if len(records) != len(manifest.get("disabled_models", [])):
        manifest["disabled_models"] = records
        write_disabled_manifest(config, manifest)


def original_path_for_disabled_file(disabled_file: Path) -> Optional[Path]:
    name = disabled_file.name
    marker = ".gguf.disable"
    index = name.lower().find(marker)
    if index < 0:
        return None
    return disabled_file.with_name(name[: index + len(".gguf")])


def restore_disabled_models_for_retest(config: dict) -> int:
    """Re-enable disabled GGUF files so each validation run starts from the full local set."""
    if not config.get("restore_disabled_before_tests", DEFAULT_RESTORE_DISABLED_BEFORE_TESTS):
        print("Skipping disabled-model restore because LLAMA_RESTORE_DISABLED_BEFORE_TESTS is disabled")
        return 0

    models_dir = Path(config["models_dir"])
    if not models_dir.is_dir():
        return 0

    restored_originals = set()
    restored_disabled = set()
    restored_count = 0
    for disabled_file in sorted(models_dir.rglob("*.gguf.disable*")):
        if not disabled_file.is_file():
            continue
        original_file = original_path_for_disabled_file(disabled_file)
        if original_file is None:
            continue
        if original_file.exists():
            restored_originals.add(str(original_file))
            restored_disabled.add(str(disabled_file))
            print(f"Disabled backup already has an enabled original; leaving backup in place: {disabled_file}")
            continue
        try:
            disabled_file.rename(original_file)
        except OSError as exc:
            print(f"WARNING: Could not restore disabled model {disabled_file}: {exc}")
            continue
        restored_count += 1
        restored_originals.add(str(original_file))
        restored_disabled.add(str(disabled_file))
        print(f"Restored disabled model for retest: {disabled_file} -> {original_file}")

    remove_disabled_manifest_records(config, restored_originals, restored_disabled)
    return restored_count


def is_non_runnable_support_asset(model_id: str, model_file: Path) -> bool:
    text = f"{model_id} {model_file.name}".lower()
    excluded_markers = (
        "mmproj",
        "projection",
        "bf16",
        "fp16",
        "bitnet-b1.58",
        "ggml-model-i2_s",
    )
    return any(marker in text for marker in excluded_markers)


def disable_model_file(config: dict, model_id: str, model_file: Path, reason: str) -> bool:
    disabled_file = model_file.with_name(f"{model_file.name}.disable")
    if disabled_file.exists():
        timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        disabled_file = model_file.with_name(f"{model_file.name}.disable.{timestamp}")

    try:
        model_file.rename(disabled_file)
    except Exception as e:
        print(f"ERROR: Failed to disable model {model_id}: {e}")
        return False

    record_disabled_model(config, model_id, model_file, disabled_file, reason)
    print(f"Disabled failed model file: {model_file} -> {disabled_file}")
    return True


def disable_model(config: dict, model_id: str, reason: str = "model validation failed") -> int:
    """
    Disable a failed model by renaming its backing GGUF file with `.disable`.

    Args:
        config: Configuration dictionary
        model_id: Model identifier

    Returns:
        Number of model files disabled.
    """
    model_file = resolve_model_file(config, model_id)
    if model_file is None:
        return 0

    split_info = split_shard_info(model_file)
    if split_info:
        first_file = split_first_shard_file(model_file)
        if model_file != first_file:
            print(f"Skipping disable of non-first split shard {model_file}; first shard controls the split set")
            return 0
        disabled = 0
        for shard_file in split_enabled_shard_files(model_file):
            shard_model_id = model_id_for_file(config, shard_file)
            shard_reason = reason if shard_file == model_file else f"{reason}; split sibling disabled with first shard"
            if disable_model_file(config, shard_model_id, shard_file, shard_reason):
                disabled += 1
        return disabled

    return 1 if disable_model_file(config, model_id, model_file, reason) else 0


# ============================================================================
# GPU Validation Functions
# ============================================================================

def validate_gpu(config: dict) -> bool:
    """
    Validate that the llama-server container has GPU device mappings.
    
    Args:
        config: Configuration dictionary
    
    Returns:
        True if GPU validation passes, False otherwise
    """
    try:
        result = run_command(
            ["podman", "inspect", config["container_name"],
             "--format",
             "{{range .HostConfig.Devices}}{{.PathOnHost}}{{\"\\n\"}}{{end}}"],
            capture_output=True,
        )
        return_code, stdout, stderr = result
        if return_code != 0:
            print(f"WARNING: Could not inspect container: {stderr}")
            return False
        gpu_devices = (stdout or "").strip()
        if not gpu_devices:
            print("ERROR: llama-server container is not configured with GPU device mappings")
            return False
        if not any(line.startswith("/dev/nvidia") for line in gpu_devices.split("\n")):
            print("ERROR: llama-server container does not expose NVIDIA device nodes")
            return False
        print(f"GPU device nodes mapped into {config['container_name']}")
        return True
    except Exception as e:
        print(f"ERROR: GPU validation failed: {e}")
        return False


# ============================================================================
# Main Functions
# ============================================================================

def start_server_if_needed(config: dict, helper_path: str) -> bool:
    """
    Start llama-router via helper if server is not running.
    
    Args:
        config: Configuration dictionary
        helper_path: Path to helper script
    
    Returns:
        True if server is running (or started successfully), False otherwise
    """
    # Check if server is responding
    try:
        url = f"{config['llama_url']}/v1/models"
        req = urllib.request.Request(url, headers={"Accept": "application/json"})
        with urllib.request.urlopen(req, timeout=5) as response:
            if response.status == 200:
                print("Llama server is already running")
                return True
    except urllib.error.URLError:
        pass
    
    # Try to start server
    if not os.path.exists(helper_path):
        print(f"ERROR: Helper script not found: {helper_path}")
        return False
    
    result = run_command([helper_path, "llama-router-up"], capture_output=True)
    return_code, _, stderr = result
    if return_code != 0:
        print(f"WARNING: Failed to start llama-router: {stderr}")
        print("Continuing anyway - server may already be running")
        return True
    print("Started llama-router with the helper")
    return True


def wait_for_llama_server(config: dict, timeout_seconds: int) -> bool:
    """Wait for the OpenAI-compatible model list endpoint to respond."""
    deadline = datetime.now().timestamp() + timeout_seconds
    url = f"{config['llama_url']}/v1/models"
    while datetime.now().timestamp() < deadline:
        try:
            req = urllib.request.Request(url, headers={"Accept": "application/json"})
            with urllib.request.urlopen(req, timeout=5) as response:
                if response.status == 200:
                    return True
        except urllib.error.URLError:
            pass
        except Exception:
            pass
    return False


def clear_missing_active_model(config: dict) -> None:
    """Remove the active-model hint if it points at a disabled or missing file."""
    active_file = Path(config["active_model_file"])
    if not active_file.exists():
        return
    try:
        active_model = active_file.read_text(encoding="utf-8").strip()
    except Exception:
        return
    if not active_model:
        return
    active_path = Path(active_model).expanduser()
    if not active_path.exists():
        try:
            active_file.unlink()
            print(f"Removed stale llama active-model hint: {active_file}")
        except OSError as exc:
            print(f"WARNING: Could not remove stale active-model hint {active_file}: {exc}")


def reset_llama_server(config: dict, helper_path: str) -> bool:
    """
    Restart llama-server after model validation so disabled models leave /v1/models.
    """
    if not config.get("reset_after_tests", True):
        print("Skipping llama-server reset because LLAMA_RESET_AFTER_TESTS is disabled")
        return True
    if not os.path.exists(helper_path):
        print(f"ERROR: Helper script not found for llama-server reset: {helper_path}")
        return False

    print("\nResetting fortisai-llama-server so /v1/models matches validation results...")
    down_code, _, down_err = run_command([helper_path, "llama-router-down"], check=False, timeout=120)
    if down_code != 0:
        print(f"WARNING: llama-router-down returned {down_code}: {down_err}")

    clear_missing_active_model(config)

    up_code, _, up_err = run_command([helper_path, "llama-router-up"], check=False, timeout=300)
    if up_code != 0:
        print(f"ERROR: llama-router-up failed during reset: {up_err}")
        return False

    if not wait_for_llama_server(config, config["reset_wait_seconds"]):
        print(f"ERROR: llama-server did not answer /v1/models within {config['reset_wait_seconds']} seconds")
        return False

    print("fortisai-llama-server reset complete")
    return True


def refresh_llama_models_before_tests(config: dict, helper_path: str) -> bool:
    """Restart llama-server before validation so new downloads enter /v1/models."""
    if not config.get("reset_before_tests", True):
        print("Skipping pre-test llama-server refresh because LLAMA_RESET_BEFORE_TESTS is disabled")
        return True
    if not os.path.exists(helper_path):
        print(f"ERROR: Helper script not found for llama-server refresh: {helper_path}")
        return False

    print("\nRefreshing fortisai-llama-server before model validation...")
    clear_missing_active_model(config)
    up_code, _, up_err = run_command([helper_path, "llama-router-up"], check=False, timeout=300)
    if up_code != 0:
        print(f"ERROR: llama-router-up failed during pre-test refresh: {up_err}")
        return False

    if not wait_for_llama_server(config, config["reset_wait_seconds"]):
        print(f"ERROR: llama-server did not answer /v1/models within {config['reset_wait_seconds']} seconds")
        return False

    print("fortisai-llama-server pre-test refresh complete")
    return True


def run_tests(config: dict) -> int:
    """
    Run model tests and return exit code.
    
    Args:
        config: Configuration dictionary
    
    Returns:
        Exit code (0 for success, 1 for failure)
    """
    # Load configuration
    config = load_config()
    controllers = get_controllers()
    
    # Print configuration
    print("=" * 70)
    print("test_llama_models.py - Llama Model Validation Script")
    print("=" * 70)
    print(f"Container Name:   {config['container_name']}")
    print(f"Llama URL:        {config['llama_url']}")
    print(f"Test Prompt:      {config['test_prompt'][:50]}...")
    print(f"Max Tokens:       {config['test_max_tokens']}")
    print(f"Timeout Seconds:  {config['test_timeout_seconds']}")
    print(f"Retry Timeout:    {config['timeout_retry_seconds']}")
    print(f"Retry Delay:      {config['timeout_retry_delay_seconds']}")
    print(f"Disable Timeouts: {config['disable_timeouts']}")
    print(f"Restore Disabled:{config['restore_disabled_before_tests']}")
    print(f"Start At Model:   {config['start_at_model'] or '<beginning>'}")
    print(f"Disable Failed:   {config['disable_failed']}")
    print(f"Reset Before Test:{config['reset_before_tests']}")
    print(f"Reset After Test: {config['reset_after_tests']}")
    print(f"Reset After Fail: {config['reset_after_disable']}")
    if config.get("legacy_delete_failed"):
        print("NOTE: LLAMA_DELETE_FAILED is deprecated; failed models are disabled, not deleted.")
    print(f"Models Dir:       {config['models_dir']}")
    print(f"Disabled Manifest:{config['disabled_models_file']}")
    print("=" * 70)
    
    # Check dependencies
    dependencies = ["curl", "python3", "podman"]
    for dep in dependencies:
        if not ensure_dependency(dep):
            print(f"ERROR: Required dependency not found: {dep}")
            return 1

    restored_disabled_models = restore_disabled_models_for_retest(config)
    if restored_disabled_models:
        print(f"Restored {restored_disabled_models} disabled model file(s) before llama-server refresh")
    
    # Start server if needed
    helper_path = get_helper_path(config)
    if not start_server_if_needed(config, helper_path):
        print("ERROR: Failed to start server")
        return 1

    if not refresh_llama_models_before_tests(config, helper_path):
        print("ERROR: Failed to refresh llama-server before tests")
        return 1
    
    # Fetch models
    print("\nFetching available models...")
    models = fetch_models(config)
    if not models:
        print("ERROR: llama-server returned no models")
        return 1
    print(f"Found {len(models)} model(s):")
    for model in models:
        print(f"  - {model}")
    
    # Validate GPU (optional)
    # if config['validate_gpu']:
    #     if not validate_gpu(config):
    #         return 1
    
    # Test each model
    failures = 0
    disabled_count = 0
    unresolved_failures = 0
    warning_count = 0
    skipped_count = 0
    print(f"\nTesting {len(models)} model(s)...")
    print("-" * 70)
    
    start_at_model = config.get("start_at_model") or ""
    waiting_for_start = bool(start_at_model)

    for model_id in models:
        if waiting_for_start and model_id != start_at_model:
            print(f"\n=== {model_id} ===")
            print(f"Skipping before requested resume point: {start_at_model}")
            skipped_count += 1
            continue
        if waiting_for_start and model_id == start_at_model:
            waiting_for_start = False

        print(f"\n=== {model_id} ===")
        model_file = resolve_model_file(config, model_id)
        if model_file is None:
            print(f"Skipping stale model entry without a local GGUF file: {model_id}")
            skipped_count += 1
            continue

        if is_nonfirst_split_shard(model_file):
            print(f"Skipping non-first split shard; first shard represents this split set: {model_file.name}")
            skipped_count += 1
            continue

        if is_non_runnable_support_asset(model_id, model_file):
            reason = "non-runnable GGUF support/projection or high-precision asset"
            print(f"Excluding non-runnable support asset {model_id}...")
            if config["disable_failed"]:
                disabled_now = disable_model(config, model_id, reason)
                if disabled_now:
                    disabled_count += disabled_now
                else:
                    unresolved_failures += 1
            else:
                unresolved_failures += 1
            skipped_count += 1
            continue

        content, success, reason = invoke_model_with_retry(config, model_id)

        if not success:
            if config['disable_failed'] and is_disable_worthy_failure(config, reason):
                print(f"Disabling failed model {model_id}...")
                disabled_now = disable_model(config, model_id, reason)
                if disabled_now:
                    disabled_count += disabled_now
                    if config.get("reset_after_disable", DEFAULT_RESET_AFTER_DISABLE):
                        if not reset_llama_server(config, helper_path):
                            unresolved_failures += 1
                else:
                    unresolved_failures += 1
            else:
                print(f"WARNING: leaving {model_id} enabled because failure was not a hard load failure: {reason}")
                unresolved_failures += 1
            print(f"ERROR: model invocation failed for {model_id}")
            failures += 1
            continue

        if not content:
            print(f"WARNING: empty response for {model_id}; model loaded but did not return visible text")
            warning_count += 1
            continue
        
        print(f"Response: {content[:100]}...")
    
    print("-" * 70)
    print(f"\nTest complete. Failures: {failures}/{len(models)}")
    print(f"Warnings: {warning_count}")
    print(f"Disabled/Excluded: {disabled_count}")
    print(f"Skipped stale entries: {skipped_count}")
    print(f"Unresolved failures: {unresolved_failures}")

    reset_ok = reset_llama_server(config, helper_path)
    if not reset_ok:
        print("ERROR: llama-server reset failed after model validation")

    return 1 if unresolved_failures > 0 or not reset_ok else 0


def main() -> int:
    """
    Main entry point for the test_llama_models script.
    
    Returns:
        Exit code (0 for success, 1 for failure)
    """
    if not should_run_for_active_host("test_llama_models"):
        return 0

    # Run tests
    exit_code = run_tests(load_config())
    return exit_code


# ============================================================================
# Scheduler (APScheduler)
# ============================================================================

def scheduled_main() -> None:
    """
    Entry point for scheduled execution via APScheduler.
    
    This function runs the tests and then exits.
    APScheduler manages the scheduling and restarts this process as needed.
    """
    if not should_run_for_active_host("test_llama_models"):
        sys.exit(0)

    # Run tests once and exit
    exit_code = run_tests(load_config())
    sys.exit(exit_code)


def scheduler_main() -> None:
    """
    Main entry point for the scheduler.
    
    This function runs the APScheduler which manages scheduled test execution.
    """
    if not should_run_for_active_host("test_llama_models"):
        return

    # Ensure required packages are installed
    try:
        from apscheduler.schedulers.blocking import BlockingScheduler
    except ImportError:
        print("ERROR: APScheduler not installed.")
        print("Install it with: pip install apscheduler")
        sys.exit(1)
    
    # Create scheduler with Eastern Time timezone
    scheduler = BlockingScheduler(timezone="America/New_York")
    
    # Add scheduled job: 3:00 PM on the 1st day of each month
    scheduler.add_job(
        scheduled_main,
        "cron",
        day=1,
        hour=15,
        minute=0,
        id="monthly_llama_test_1500_eastern_day_1",
        replace_existing=True,
        misfire_grace_time=3600,  # Allow 1 hour grace time if job is delayed
        coalesce="REPLACE",       # Replace missed executions
        max_instances=1,          # Ensure only one execution at a time
    )
    
    try:
        scheduler.start()
    except (KeyboardInterrupt, SystemExit):
        scheduler.shutdown(wait=False)


def main_entry() -> None:
    """
    Main entry point - dispatches to appropriate function based on usage.
    
    For scheduled execution, use: python3 test_llama_models.py scheduler
    """
    if len(sys.argv) > 1 and sys.argv[1] == "scheduler":
        scheduler_main()
    else:
        # Run tests immediately
        sys.exit(main())


if __name__ == "__main__":
    main_entry()
