#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import os
import shutil
import socket
import subprocess
import sys
import time
from collections.abc import Iterable, Mapping
from pathlib import Path
from typing import Any, TypeAlias

try:
    from apscheduler.schedulers.blocking import BlockingScheduler
except ImportError as exc:  # pragma: no cover - runtime dependency error
    raise SystemExit(
        "Missing dependency 'apscheduler'. Install dependencies via "
        "Development_Environment/linux/systemd_services/deploy-fortisai-service.sh."
    ) from exc


ACTIVE_HOSTS_FILE = Path(
    os.environ.get(
        "FORTISAI_ACTIVE_HOSTS_FILE",
        Path(os.environ.get("FORTISAI_WATCHDOG_DIR", Path.home() / "fortisai-dev" / "watchdog")) / "active_host.json",
    )
).expanduser()
WATCHDOG_DIR = Path(os.environ.get("FORTISAI_WATCHDOG_DIR", ACTIVE_HOSTS_FILE.parent)).expanduser()
WATCHDOWN_FILE = Path(os.environ.get("FORTISAI_WATCHDOWN_FILE", WATCHDOG_DIR / "watchdown.json")).expanduser()
ACTIVE_HOSTS_SEED_FILE = Path(
    os.environ.get(
        "FORTISAI_ACTIVE_HOSTS_SEED_FILE",
        Path(__file__).resolve().parents[1] / "active_host.json",
    )
).expanduser()
DEFAULT_UPDATE_SCHEDULE = {"day_of_week": "sun", "hour": 3, "minute": 0}
DEFAULT_CPU_STALL_MINUTES = 10
DEFAULT_MEMORY_LIMIT_MB = 0
DEFAULT_INTERVAL_HOURS = 3
PODMAN_TIMEOUT_SECONDS = 60

JsonObject: TypeAlias = dict[str, Any]
CPU_HISTORY: dict[str, float] = {}


def ensure_runtime_files() -> None:
    WATCHDOG_DIR.mkdir(parents=True, exist_ok=True)
    if not ACTIVE_HOSTS_FILE.exists():
        if not ACTIVE_HOSTS_SEED_FILE.exists():
            raise FileNotFoundError(f"Active host seed file not found: {ACTIVE_HOSTS_SEED_FILE}")
        shutil.copy2(ACTIVE_HOSTS_SEED_FILE, ACTIVE_HOSTS_FILE)
    if not WATCHDOWN_FILE.exists():
        WATCHDOWN_FILE.write_text(json.dumps({"activity": True}, indent=2) + "\n", encoding="utf-8")


def watchdog_activity_enabled() -> bool:
    ensure_runtime_files()
    try:
        payload = json.loads(WATCHDOWN_FILE.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"Invalid JSON in {WATCHDOWN_FILE}: {exc}") from exc
    if not isinstance(payload, dict):
        raise ValueError(f"{WATCHDOWN_FILE} root must be a JSON object")
    value = payload.get("activity", True)
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        normalized = value.strip().lower()
        if normalized in {"1", "true", "yes", "on"}:
            return True
        if normalized in {"0", "false", "no", "off"}:
            return False
    raise ValueError(f"activity must be a boolean in {WATCHDOWN_FILE}")


def _default_host_name() -> str:
    configured = os.environ.get("FORTISAI_ACTIVE_HOST", "").strip()
    if configured:
        return configured.lower().split(".", 1)[0]
    return socket.gethostname().strip().lower().split(".", 1)[0]


def _load_active_host(hostname: str) -> JsonObject:
    """Load the current host's watchdog settings from active_host.json."""

    ensure_runtime_files()
    if not ACTIVE_HOSTS_FILE.exists():
        raise FileNotFoundError(f"Active host inventory not found: {ACTIVE_HOSTS_FILE}")

    try:
        with ACTIVE_HOSTS_FILE.open(encoding="utf-8") as config_file:
            data = json.load(config_file)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"Invalid JSON in {ACTIVE_HOSTS_FILE}: {exc}") from exc

    if not isinstance(data, dict):
        raise ValueError("Active host inventory root must be a JSON object")

    hosts = data.get("hosts", {})
    if not isinstance(hosts, dict):
        raise ValueError("active_host.json hosts must be a JSON object")

    normalized = hostname.strip().lower().split(".", 1)[0]
    for key, value in hosts.items():
        if not isinstance(value, dict):
            continue
        names = {
            str(key).strip().lower().split(".", 1)[0],
            str(value.get("hostname", "")).strip().lower().split(".", 1)[0],
        }
        if normalized in names:
            return value

    available = ", ".join(sorted(str(key) for key in hosts)) or "<none>"
    raise ValueError(f"Host '{hostname}' not found in {ACTIVE_HOSTS_FILE}; available hosts: {available}")


def load_config(hostname: str | None = None) -> tuple[list[str], int, int, int, dict[str, int | str]]:
    """Load and validate the current host's watchdog settings from active_host.json."""

    data = _load_active_host(hostname or _default_host_name())

    containers = data.get("required_containers", [])
    if not isinstance(containers, list) or not all(isinstance(name, str) and name.strip() for name in containers):
        raise ValueError("required_containers must be a list of non-empty strings")
    containers = [name.strip() for name in containers if name.strip()]

    cpu_stall = _read_non_negative_int(data.get("cpu_stall_minutes", DEFAULT_CPU_STALL_MINUTES), "cpu_stall_minutes")
    memory_limit = _read_non_negative_int(data.get("memory_limit_mb", DEFAULT_MEMORY_LIMIT_MB), "memory_limit_mb")
    interval_hours = _read_positive_int(data.get("interval_hours", DEFAULT_INTERVAL_HOURS), "interval_hours")

    update_schedule = data.get("update_schedule", DEFAULT_UPDATE_SCHEDULE)
    if not isinstance(update_schedule, dict):
        raise ValueError("update_schedule must be a JSON object")

    schedule = {
        "day_of_week": _read_schedule_day(update_schedule.get("day_of_week", DEFAULT_UPDATE_SCHEDULE["day_of_week"])),
        "hour": _read_bounded_int(update_schedule.get("hour", DEFAULT_UPDATE_SCHEDULE["hour"]), "update_schedule.hour", 0, 23),
        "minute": _read_bounded_int(update_schedule.get("minute", DEFAULT_UPDATE_SCHEDULE["minute"]), "update_schedule.minute", 0, 59),
    }

    return containers, cpu_stall, memory_limit, interval_hours, schedule


def _read_non_negative_int(value: Any, field_name: str) -> int:
    number = _read_int(value, field_name)
    if number < 0:
        raise ValueError(f"{field_name} must be >= 0")
    return number


def _read_positive_int(value: Any, field_name: str) -> int:
    number = _read_int(value, field_name)
    if number <= 0:
        raise ValueError(f"{field_name} must be > 0")
    return number


def _read_bounded_int(value: Any, field_name: str, lower: int, upper: int) -> int:
    number = _read_int(value, field_name)
    if number < lower or number > upper:
        raise ValueError(f"{field_name} must be between {lower} and {upper}")
    return number


def _read_int(value: Any, field_name: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int):
        raise ValueError(f"{field_name} must be an integer")
    return value


def _read_schedule_day(value: Any) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ValueError("update_schedule.day_of_week must be a non-empty string")
    return value.strip().lower()


def run_podman_json(args: list[str], description: str) -> list[JsonObject]:
    try:
        result = subprocess.run(
            args,
            capture_output=True,
            text=True,
            check=True,
            timeout=PODMAN_TIMEOUT_SECONDS,
        )
    except subprocess.TimeoutExpired as exc:
        raise RuntimeError(f"{description} timed out after {PODMAN_TIMEOUT_SECONDS}s") from exc
    except subprocess.CalledProcessError as exc:
        stderr = (exc.stderr or exc.stdout or "").strip()
        raise RuntimeError(f"{description} failed: {stderr or exc}") from exc

    try:
        payload = json.loads(result.stdout or "[]")
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"{description} returned invalid JSON: {exc}") from exc

    if not isinstance(payload, list):
        raise RuntimeError(f"{description} did not return a JSON array")

    return [item for item in payload if isinstance(item, dict)]


def get_running_containers() -> set[str]:
    containers = run_podman_json(["podman", "ps", "--format", "json"], "podman ps")
    return {name for container in containers for name in _container_names(container)}


def get_all_containers() -> list[JsonObject]:
    return run_podman_json(["podman", "ps", "-a", "--format", "json"], "podman ps -a")


def get_stats() -> list[JsonObject]:
    return run_podman_json(["podman", "stats", "--no-stream", "--format", "json"], "podman stats")


def _container_names(container: Mapping[str, Any]) -> Iterable[str]:
    names = container.get("Names", [])
    if not isinstance(names, list):
        return []
    return [name for name in names if isinstance(name, str) and name.strip()]


def _container_name(container: Mapping[str, Any]) -> str:
    names = list(_container_names(container))
    if not names:
        raise ValueError("Container entry is missing a name")
    return names[0]


def _container_state(container: Mapping[str, Any]) -> str:
    state = container.get("State", "")
    if not isinstance(state, str):
        return ""
    return state


def start_container(name: str) -> None:
    print(f"[WATCHDOG] Starting container: {name}")
    subprocess.run(["podman", "start", name], check=True, timeout=PODMAN_TIMEOUT_SECONDS)
    print(f"[WATCHDOG] Started: {name}")


def restart_container(name: str, reason: str) -> None:
    print(f"[WATCHDOG] Restarting {name} due to: {reason}")
    subprocess.run(["podman", "restart", name], check=True, timeout=PODMAN_TIMEOUT_SECONDS)
    print(f"[WATCHDOG] Restarted: {name}")


def update_container_if_needed(name: str) -> None:
    print(f"[UPDATE] Checking for updates: {name}")

    inspect = run_podman_json(["podman", "inspect", name], f"podman inspect {name}")
    if not inspect:
        raise RuntimeError(f"Could not inspect container: {name}")

    info = inspect[0]
    image_name = info.get("ImageName")
    current_image_id = info.get("Image")
    if not isinstance(image_name, str) or not image_name.strip():
        raise RuntimeError(f"Container {name} is missing ImageName metadata")
    if not isinstance(current_image_id, str) or not current_image_id.strip():
        raise RuntimeError(f"Container {name} is missing Image metadata")

    print(f"[UPDATE] Pulling latest image for {image_name}...")
    subprocess.run(["podman", "pull", image_name], check=True, timeout=PODMAN_TIMEOUT_SECONDS)

    images = run_podman_json(["podman", "images", "--format", "json"], "podman images")
    latest = next(
        (
            image
            for image in images
            if image.get("Repository") == image_name or image.get("Id") == current_image_id
        ),
        None,
    )

    if not latest:
        raise RuntimeError(f"Could not find updated image for {image_name}")

    latest_id = latest.get("Id")
    if latest_id == current_image_id:
        print(f"[UPDATE] {name} is already up to date.")
        return

    print(f"[UPDATE] Updating {name} to latest image...")

    config = info.get("Config", {})
    host_config = info.get("HostConfig", {})
    run_args = config.get("Cmd") or []
    env = config.get("Env") or []
    ports = host_config.get("PortBindings") or {}

    if not isinstance(run_args, list) or not all(isinstance(arg, str) for arg in run_args):
        raise RuntimeError(f"Container {name} has unsupported Cmd metadata")
    if not isinstance(env, list) or not all(isinstance(entry, str) for entry in env):
        raise RuntimeError(f"Container {name} has unsupported Env metadata")
    if not isinstance(ports, dict):
        raise RuntimeError(f"Container {name} has unsupported PortBindings metadata")

    subprocess.run(["podman", "stop", name], check=False, timeout=PODMAN_TIMEOUT_SECONDS)
    subprocess.run(["podman", "rm", name], check=False, timeout=PODMAN_TIMEOUT_SECONDS)

    cmd = ["podman", "run", "-d", "--name", name]
    for entry in env:
        cmd.extend(["-e", entry])

    for port, bindings in ports.items():
        if not isinstance(port, str) or not port.strip():
            continue
        if not isinstance(bindings, list) or not bindings:
            continue
        first_binding = bindings[0]
        if not isinstance(first_binding, dict):
            continue
        host_port = first_binding.get("HostPort")
        if not isinstance(host_port, str) or not host_port.strip():
            continue
        cmd.extend(["-p", f"{host_port}:{port.split('/')[0]}"])

    cmd.append(image_name)
    cmd.extend(run_args)

    print(f"[UPDATE] Recreating container: {' '.join(cmd)}")
    subprocess.run(cmd, check=True, timeout=PODMAN_TIMEOUT_SECONDS)
    print(f"[UPDATE] Updated container: {name}")


def _extract_cpu_percent(stat: Mapping[str, Any]) -> float:
    raw_cpu = stat.get("CPU", "0")
    if isinstance(raw_cpu, (int, float)):
        return float(raw_cpu)
    if not isinstance(raw_cpu, str):
        return 0.0
    return float(raw_cpu.replace("%", "") or 0)


def _extract_memory_mb(stat: Mapping[str, Any]) -> float:
    raw_mem = stat.get("MemUsage", "0")
    if not isinstance(raw_mem, str):
        return 0.0
    mem_value = raw_mem.split()[0]
    return float(mem_value or 0)


def check_health(container: Mapping[str, Any], stats: list[JsonObject], cpu_stall_minutes: int, memory_limit_mb: int) -> None:
    name = _container_name(container)

    health = container.get("Health", {})
    health_status = health.get("Status") if isinstance(health, dict) else None
    if isinstance(health_status, str) and health_status != "healthy":
        restart_container(name, f"unhealthy status: {health_status}")
        return

    stat = next((entry for entry in stats if entry.get("Name") == name), None)
    if not stat:
        print(f"[WATCHDOG] Stats unavailable for running container: {name}; skipping CPU/memory checks.")
        return

    cpu_percent = _extract_cpu_percent(stat)
    now = time.time()
    last_active = CPU_HISTORY.get(name, now)

    if cpu_percent > 0:
        CPU_HISTORY[name] = now
    else:
        stall_minutes = (now - last_active) / 60
        if stall_minutes >= cpu_stall_minutes:
            restart_container(name, f"CPU stall for {stall_minutes:.1f} minutes")
            CPU_HISTORY[name] = now
            return

    if memory_limit_mb > 0:
        mem_mb = _extract_memory_mb(stat)
        if mem_mb > memory_limit_mb:
            restart_container(name, f"memory usage {mem_mb}MB > limit {memory_limit_mb}MB")


def monitor_containers() -> None:
    print("\n[WATCHDOG] Running Podman container health check...")

    if not watchdog_activity_enabled():
        print(f"[WATCHDOG] activity=false in {WATCHDOWN_FILE}; pausing until next cycle.")
        return

    required, cpu_stall_minutes, memory_limit_mb, _, _ = load_config()
    if not required:
        print("[WATCHDOG] No required containers configured for this host; skipping Podman checks.")
        return

    all_containers = get_all_containers()
    stats = get_stats()

    running = {_container_name(container) for container in all_containers if _container_state(container) == "running"}
    all_names = {_container_name(container) for container in all_containers}

    for name in required:
        if name not in all_names:
            raise RuntimeError(f"Required container is missing: {name}")

        if name not in running:
            print(f"[WATCHDOG] Not running: {name}")
            start_container(name)
            continue

        container = next(container for container in all_containers if _container_name(container) == name)
        check_health(container, stats, cpu_stall_minutes, memory_limit_mb)

    print("[WATCHDOG] Health check complete.")


def update_all_containers() -> None:
    print("\n[UPDATE] Weekly container update check running...")

    if not watchdog_activity_enabled():
        print(f"[UPDATE] activity=false in {WATCHDOWN_FILE}; pausing until next cycle.")
        return

    required, _, _, _, _ = load_config()
    if not required:
        print("[UPDATE] No required containers configured for this host; skipping container updates.")
        return

    for name in required:
        update_container_if_needed(name)

    print("[UPDATE] Weekly update check complete.")


def main() -> int:
    parser = argparse.ArgumentParser(description="Podman Watchdog")
    parser.add_argument("--run-now", action="store_true", help="Run immediately on startup")
    parser.add_argument("--host", default=None, help="Active host inventory key to monitor")
    args = parser.parse_args()

    if args.host:
        os.environ["FORTISAI_ACTIVE_HOST"] = args.host

    ensure_runtime_files()
    host_name = _default_host_name()
    required, _, _, interval_hours, update_schedule = load_config(host_name)
    monitored = ", ".join(required) if required else "<none>"
    print(f"[WATCHDOG] Active host: {host_name}")
    print(f"[WATCHDOG] Active host inventory: {ACTIVE_HOSTS_FILE}")
    print(f"[WATCHDOG] Activity control: {WATCHDOWN_FILE}")
    print(f"[WATCHDOG] Monitoring containers: {monitored}")

    scheduler = BlockingScheduler()
    scheduler.add_job(monitor_containers, "interval", hours=interval_hours, id="podman-health-check", replace_existing=True)
    
    #scheduler.add_job(
    #    update_all_containers,
    #    "cron",
    #    day_of_week=update_schedule["day_of_week"],
    #    hour=update_schedule["hour"],
    #    minute=update_schedule["minute"],
    #    id="podman-update-check",
    #    replace_existing=True,
    #)
    
    if args.run_now:
        monitor_containers()
    else:
        print(f"[WATCHDOG] First health check in {interval_hours} hours.")
        scheduler.start()
        return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"[WATCHDOG] Fatal error: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
