# FortisAI Systemd Services

Complete documentation for the FortisAI Linux development stack systemd services.

## 📋 Directory Overview

| File | Description |
|------|-------------|
| `fortisai.service` | Main systemd service for the FortisAI development stack |
| `fortisai-control.sh` | Control script to start/stop/restart the stack |
| `deploy-fortisai-service.sh` | Installs and configures the active systemd services |
| `test_llama_models.py` | Python test/validation utility for Llama server models |
| `test-llama-models.sh` | Legacy shell wrapper for test_llama_models.py |
| `model_update.py` | Python script for automatic model updates via Hugging Face |
| `fortisai_monitor.service` | Combined monitoring, model update, and llama validation service |
| `fortisai-monitor-service.sh` | Supervisor wrapper used by `fortisai_monitor.service` |
| `podman_monitor.py` | Podman watchdog script |
| `vfs_to_overlay_migration.sh` | Migration script for VFS to Overlay filesystem |

## 🎯 Script Details

## Rootless Podman Host Limits

On aiengine000, the FortisAI stack runs as rootless Podman under `aiuser`. The host must keep generous user-manager limits so container execs, compose reconciliation, and helper validation do not fail with `setrlimit 'RLIMIT_NPROC': Operation not permitted`.

Persistent limit drop-ins:

```ini
# /etc/systemd/system/user@1001.service.d/90-fortisai-limits.conf
[Service]
TasksMax=infinity
LimitNPROC=infinity
LimitNOFILE=1048576
```

```ini
# /etc/systemd/user.conf.d/90-fortisai-limits.conf
[Manager]
DefaultTasksMax=infinity
DefaultLimitNPROC=infinity
DefaultLimitNOFILE=1048576
```

```text
# /etc/security/limits.d/90-fortisai-aiuser.conf
aiuser soft nproc unlimited
aiuser hard nproc unlimited
aiuser soft nofile 1048576
aiuser hard nofile 1048576
```

After changing these files, run `sudo systemctl daemon-reload` and restart the `aiuser` user manager or reboot during a maintenance window. The Linux helper also drains stale `podman healthcheck run` processes during startup checks, and helper-generated Oracle, Dify, and Daytona Podman compose files disable container-level healthchecks where they have caused rootless runtime locks. Use helper `check`, component HTTP checks, and service logs as the supported validation path.

### 1. `fortisai.service`

Main systemd service unit that orchestrates the FortisAI development stack.

**Purpose:** Provides a unified entry point to start, stop, and manage all FortisAI components.

**Key Features:**
- Aggressive pre-start cleanup to ensure clean state
- Graceful shutdown with timeout protection
- Automatic cleanup of stale containers and pods
- Starts through `linux/fortisai-dev-helper.sh all-up`, so n8n and Dify config mounts follow the helper-managed paths under `Development_Environment/n8n-config` and `Development_Environment/dify-config`.

**Usage:**
```bash
sudo systemctl status fortisai.service
sudo journalctl -u fortisai.service -f
```

---

### 2. `fortisai-control.sh`

Control script that manages the background `all-up` process.

**Purpose:** Provides fine-grained control over the FortisAI startup process.

**Commands:**
- `start` — Starts the background process
- `start-nowait` — Starts without waiting (returns immediately)
- `stop` — Stops the process and runs `all-down`
- `restart` — Restarts the process

**Usage:**
```bash
./fortisai-control.sh start
./fortisai-control.sh stop
./fortisai-control.sh restart
```

---

### 3. `deploy-fortisai-service.sh`

Deployment script that installs the active FortisAI systemd services.

**Purpose:** Automated installation and configuration of `fortisai.service` and `fortisai_monitor.service`.

**Features:**
- Creates isolated Python venv for monitor/model maintenance runtime as `DEPLOY_USER`
- Repairs a partially-created or root-owned monitor/model maintenance venv before installing Python packages
- Installs required dependencies (requests, apscheduler, huggingface_hub)
- Handles sudo execution automatically
- Supports selective enabling of active services
- Disables the retired standalone `fortisai_model.service` if it is still present

**Host Prerequisite:**
- Fresh Linux hosts must have the distribution Python venv package installed before deployment. For Ubuntu 25.10 / Python 3.13 hosts such as `aiengine001`, install `python3.13-venv`.

**Usage:**
```bash
# Install with automatic enabling
ENABLE_SERVICE=1 ENABLE_MONITOR_SERVICE=1 \
  ./deploy-fortisai-service.sh

# Install with custom settings
DEPLOY_USER=aiuser \
  FORTISAI_ACTIVE_HOST=$(hostname -s) \
  ./deploy-fortisai-service.sh
```

**Post-Installation Commands:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable fortisai.service
sudo systemctl enable fortisai_monitor.service
```

---

### 4. `test_llama_models.py` ⭐

**Primary Python implementation** for Llama server model testing and validation.

**Purpose:** Verifies that Llama models are properly loaded, responsive, and generating valid responses.

**Features:**
- ✅ Auto-starts llama-router if server is not running
- ✅ Fetches all available models from the server
- ✅ Tests each model with a configurable prompt
- ✅ Reports test results with failure counts
- ✅ Configurable model disabling on failure by renaming the backing `.gguf` file to `.gguf.disable`
- ✅ **APScheduler integration** for scheduled monthly testing
- ✅ Dual entry points: manual execution and scheduler mode

**Supported Python Features:**
- Type hints for better code documentation
- Comprehensive error handling
- Modern Python 3 syntax with f-strings
- Structured code organization with clear sections
- Cross-platform compatibility

**Configuration Variables:**
| Variable | Default | Description |
|----------|---------|-------------|
| `LLAMA_SERVER_CONTAINER_NAME` | `fortisai-llama-server` | Container name to use |
| `LLAMA_SERVER_URL` | `http://127.0.0.1:8011` | Server URL |
| `LLAMA_TEST_PROMPT` | `"Reply with a short sentence about this model and include the model name."` | Test prompt |
| `LLAMA_DISABLE_FAILED` | `true` | Rename failing model files with a `.disable` suffix |
| `LLAMA_MODELS_DIR` | `/db/AI/llm_directory` when present, otherwise `../../llm_directory` from this script | GGUF model source directory |
| `LLAMA_RESET_AFTER_TESTS` | `true` | Restart `fortisai-llama-server` after validation so disabled model changes are picked up |
| `LLAMA_RESET_WAIT_SECONDS` | `180` | Time to wait for `/v1/models` after the restart |
| `LLAMA_ROUTER_MODELS_PRESET_FILE` | `~/fortisai-dev/llama-router/models.ini` | Helper-generated llama-server preset with direct `LLAMA_MODELS_DIR` GGUF paths |
| `LLAMA_ROUTER_ACTIVE_MODEL_FILE` | `~/fortisai-dev/llama-router/active-model.path` | Helper-managed active model hint cleared when it points to a disabled or missing file |

**Usage Examples:**

**Manual execution:**
```bash
# Basic test
python3 test_llama_models.py

# Test with custom prompt
LLAMA_TEST_PROMPT="Hello model, who are you?" python3 test_llama_models.py

# Test with automatic disabling of failing models
LLAMA_DISABLE_FAILED=true python3 test_llama_models.py

# Test specific server URL
LLAMA_SERVER_URL=http://localhost:8011 python3 test_llama_models.py
```

**Scheduler mode:**
```bash
# Run the scheduler (for continuous scheduled execution)
python3 test_llama_models.py scheduler

# Install required package
pip install apscheduler
```

**Scheduled Execution:**
- **Schedule:** 3:00 PM on the 1st day of each month
- **Timezone:** America/New_York (Eastern Time)
- **Job ID:** `monthly_llama_test_1500_eastern_day_1`

**Failed Model Handling:**
- Failed models are never deleted by this script.
- When `LLAMA_DISABLE_FAILED=true`, the script resolves the model ID directly under `LLAMA_MODELS_DIR` and renames the backing source file from `*.gguf` to `*.gguf.disable`.
- `fortisai_monitor.service` sets `LLAMA_DISABLE_FAILED=true` for the scheduled production validation run.
- Set `LLAMA_DISABLE_FAILED=false` for report-only troubleshooting.
- The legacy `LLAMA_DELETE_FAILED=true` flag is treated as a backwards-compatible alias for disabling, not deletion.
- The next `llama-router-up` excludes disabled files because the helper regenerates `LLAMA_ROUTER_MODELS_PRESET_FILE` from direct `LLAMA_MODELS_DIR` paths and only includes files ending in `.gguf`.

**Post-Test Server Reset:**
- By default, the script finishes by resetting `fortisai-llama-server` through the Linux helper (`llama-router-down` then `llama-router-up`).
- Before restart, it clears a stale active-model hint when that hint points at a model file that has been disabled or no longer exists.
- The script waits for the local OpenAI-compatible `/v1/models` endpoint to come back before reporting success.
- Set `LLAMA_RESET_AFTER_TESTS=false` only for isolated troubleshooting where you do not want the live server restarted.

**Exit Codes:**
- `0` — All models responded successfully
- `1` — One or more models failed

**Implementation Details:**
- Uses `urllib` for HTTP requests (no external dependencies)
- Python-based JSON parsing for reliable model invocation
- Configurable timeout and temperature parameters
- Supports parallel execution via the helper script
- APScheduler integration for automated monthly testing

---

### 5. `test-llama-models.sh`

**Legacy shell wrapper** for `test_llama_models.py`. Maintains backward compatibility.

**Purpose:** Provide a shell-based entry point for users who prefer bash scripts.

**Usage:**
```bash
./test-llama-models.sh
```

**Note:** The Python implementation (`test_llama_models.py`) is the primary and recommended script to use.

---

### 6. `model_update.py`

Python script for automatic model updates via Hugging Face.

**Purpose:** Scheduled updates of Llama models from Hugging Face Hub using APScheduler.

**Features:**
- ✅ Searches for latest GGUF models from multiple providers
- ✅ Downloads models using the `hf` CLI
- ✅ Maintains state in `model_state.json`
- ✅ **Uses APScheduler instead of cron** for scheduled execution

**Supported Providers:**
| Provider | HF Organization |
|----------|-----------------|
| meta | meta-llama |
| qwen | Qwen |
| mistral | mistralai |
| deepseek | deepseek-ai |
| microsoft | microsoft |
| google | google |

**Usage:**
```bash
# Run manual update
python3 model_update.py

# Check status
python3 -c "import json; print(json.load(open('model_state.json')))"
```

**APScheduler Configuration:**
The script is configured to run on the 1st day of each month at 12:00 PM Eastern Time. This can be customized in the script by modifying the cron schedule:

```python
scheduler.add_job(
    run_updates,
    "cron",
    day=1,
    hour=12,
    minute=0,
    id="monthly_model_update_1200_eastern_day_1",
    replace_existing=True,
)
```

---

## Production Model Refresh Sequence

`fortisai_monitor.service` keeps the model maintenance flow in one supervisor process. The expected end-to-end production chain is:

1. `model_update.py` first reads the current host entry in `~/fortisai-dev/watchdog/active_host.json`; when `model_update` is `true`, it runs on the 1st day of each month at 12:00 PM Eastern and downloads new matching GGUF models. When the flag is `false`, it exits cleanly without work.
2. `test_llama_models.py scheduler` first reads the current host entry in `~/fortisai-dev/watchdog/active_host.json`; when `test_llama_models` is `true`, it runs on the 1st day of each month at 3:00 PM Eastern, tests the local OpenAI-compatible endpoint, and marks GPU-incompatible model files with `.disable`. When the flag is `false`, it exits cleanly without work.
3. `test_llama_models.py` resets `fortisai-llama-server` after validation so the running `/v1/models` list reflects disabled models from the direct `LLAMA_MODELS_DIR`.
4. The n8n monthly local LLM router workflow runs on the 1st day of each month at 6:00 PM Eastern. It classifies the available local models, regenerates Dify router YAML under `Development_Environment/dify-config`, and writes the generated Dify model setup and router import scripts.
5. The n8n workflow then runs the generated Dify OpenAI-compatible model setup script to configure all runnable local models for the router.
6. The n8n workflow finally imports and publishes the generated `local-openai-compatible-router` Dify app.

Manual recovery uses the same order: run the model update, run `test_llama_models.py`, run the n8n classifier workflow or runner endpoint, run the generated Dify model setup script, then run the generated Dify router import script.

---

### 7. `fortisai_monitor.service`

Systemd service unit for the FortisAI monitoring supervisor.

**Purpose:** Runs the Podman watchdog plus the scheduled model update and llama validation scripts under one systemd service.

**Features:**
- Continuous container health monitoring
- Automatic restart of failed containers
- Monthly model update scheduler via `model_update.py`, gated by the active host's `model_update` flag
- Monthly llama model validation scheduler via `test_llama_models.py scheduler`, gated by the active host's `test_llama_models` flag
- Runtime configuration from `~/fortisai-dev/watchdog/active_host.json`
- Podman watchdog pause control from `~/fortisai-dev/watchdog/watchdown.json`
- Scheduled llama validation disables failed models with `.disable` and resets `fortisai-llama-server`
- Child process supervision through `fortisai-monitor-service.sh`
- Health check reporting

**Usage:**
```bash
# Check service status
sudo systemctl status fortisai_monitor.service

# View logs
sudo journalctl -u fortisai_monitor.service -f
```

---

### 8. Runtime Watchdog Files

Host inventory used by the Podman watchdog process started by `fortisai_monitor.service`.

**Purpose:** `~/fortisai-dev/watchdog/active_host.json` defines each active FortisAI host, its Podman connectivity metadata, primary-helper guard, model maintenance flags, and the stable container names in that host's `required_containers` list. Runtime-generated infra containers are intentionally excluded because their names change. `Development_Environment/linux/active_host.json` is kept as the repository seed/template; the runtime copy is the active environment setup file used by helpers and services.

`~/fortisai-dev/watchdog/service_map.json` maps a service name to every container and runtime directory that should move together. The primary helper command:

```bash
./Development_Environment/linux/fortisai-dev-helper.sh host app-service [service]
```

lists service-to-host assignments from the runtime `service_map.json` and `active_host.json`. Use it before and after moving a service to confirm which host owns the mapped containers.

The primary helper command:

```bash
./Development_Environment/linux/fortisai-dev-helper.sh host app-move <service> <source_host> <destination_host>
```

pauses the watchdog, updates the runtime `active_host.json` on all active hosts, copies mapped runtime directories, recreates the mapped containers or their owning pods on the destination with `podman generate kube` and `podman kube play`, removes non-portable Podman runtime and health-check annotations plus invalid multi-slash annotation keys from generated manifests, reconciles generated `*-pod` wrappers for bare-container moves, restores stable FortisAI container names after kube play, removes the moved workloads from the source host, refreshes CoreDNS, and restores the watchdog to its prior state. CUDA-backed workloads get a generated CDI GPU selector when the destination host exposes NVIDIA CDI. If a move fails before completion, the helper rolls the runtime host inventory and watchdog setting back to the pre-move state. Validation on June 22, 2026 confirmed two repeated `traefik` round trips between `aiengine000` and `aiengine001`, including manifest sanitization, stable container rename, Calico attachment, CoreDNS registration, watchdog restoration, and HTTP reachability from both hosts after each move.

After a runtime service move is confirmed, persist the runtime inventory back to Git with:

```bash
./Development_Environment/linux/fortisai-dev-helper.sh app-config
```

That command copies `~/fortisai-dev/watchdog/active_host.json` back to `Development_Environment/linux/active_host.json`, commits the change, and pushes it from the primary host.

`~/fortisai-dev/watchdog/watchdown.json` contains:

```json
{
  "activity": true
}
```

When `activity` is `false`, `podman_monitor.py` logs the pause and waits until the next scheduled cycle without restarting or checking containers. Restore `activity` to `true` to resume watchdog action.

**Current component coverage includes:**
- Core FortisAI services: Vault, Oracle DB, ORDS, SQLcl, n8n, OpenWebUI, OpenVSCode, Appsmith, MongoDB, Redis, RabbitMQ, pgvector, Firecrawl, Honcho, Dify, Qdrant, OpenClaw, Hermes, llama-server, Daytona, and OpenAPI tool servers.
- MCP/OpenAPI bridges: SQLcl, n8n, Dify, debug, Proxmox upstream/facade, and CodeIndexer.
- New local platform components: Traefik, Milvus (`fortisai-milvus`, `fortisai-milvus-etcd`, `fortisai-milvus-minio`), OpenSearch, and OpenMetadata.

**Operational notes:**
- Exactly one Linux host should have `primary_system: true`. The Linux helper exits with `This is not primary system` on hosts where this flag is missing or `false`; `aiengine000` is the current primary host.
- `model_update` and `test_llama_models` are host-local scheduler controls. `aiengine000` keeps both enabled; `aiengine001` keeps both disabled until model maintenance is intentionally assigned there.
- Rootless Podman bridge networks are local to each host. Linux hosts that have run `../deploy-calico-network.sh` use the FortisAI Calico/CoreDNS network name `fortisai-calico-net` locally. Same-host lookups resolve to local container IPs, while cross-host service lookups resolve to the owning host's LAN IP only when that container has a LAN-reachable published port. Do not expect one rootless Podman bridge subnet to span `aiengine000` and `aiengine001`.
- `../deploy-calico-network.sh` installs `fortisai-calico-routes.service` for route/sysctl persistence on each host and `fortisai-calico-sync-dns.timer` on the primary host to refresh shared CoreDNS records from the runtime `active_host.json` every minute.
- `fortisai.service` bootstraps CoreDNS before the main stack. Its rendered unit runs `fortisai-control.sh cleanup-prestart`, then `fortisai-control.sh bootstrap-coredns`, then `fortisai-control.sh start`. The cleanup step preserves `fortisai-coredns`; the bootstrap step runs Calico/CoreDNS setup before Vault or application containers start.
- On hosts where `primary_system` is `false`, `fortisai-control.sh start` bootstraps CoreDNS and exits cleanly with `This is not primary system`; only the primary host continues into the full `all-up` stack.
- The 2026-06-19 inventory refresh records 54 stable required containers on `aiengine000` and `fortisai-coredns` on `aiengine001`. Keep `required_containers` aligned with `podman ps` stable names and continue excluding generated `*-infra` containers.
- Use service-level `host app-move` instead of editing `required_containers` by hand. The removed `host app-add` and `host app-del` commands are intentionally no longer supported.
- After changing `~/fortisai-dev/watchdog/active_host.json`, restart the monitor service:
  ```bash
  sudo systemctl restart fortisai_monitor.service
  ```
- Validate the active service loaded the host-specific list:
  ```bash
  sudo journalctl -u fortisai_monitor.service -n 40 --no-pager
  ```
- Run an immediate watchdog pass for troubleshooting:
  ```bash
  PYTHONUNBUFFERED=1 timeout 120 \
    ~/fortisai-dev/model-service-venv/bin/python \
    ~/FortisAI/Development_Environment/linux/systemd_services/podman_monitor.py --run-now --host "$(hostname -s)"
  ```
- `podman_monitor.py` starts missing/stopped required containers when Podman knows the container. If Podman omits a running container from `podman stats`, the watchdog logs the omission and skips only CPU/memory checks for that container instead of failing the whole run.

---

## 🚀 Deployment

### Quick Start
```bash
# 1. Install active services
./deploy-fortisai-service.sh

# 2. Enable services
sudo systemctl daemon-reload
sudo systemctl enable fortisai.service fortisai_monitor.service

# 3. Start services
sudo systemctl start fortisai.service

# 4. Verify status
sudo systemctl status fortisai.service
sudo systemctl status fortisai_monitor.service
```

### Enable during Deployment
```bash
ENABLE_SERVICE=1 ENABLE_MONITOR_SERVICE=1 \
  ./deploy-fortisai-service.sh
```

---

## 📊 Monitoring & Troubleshooting

### Check Service Status
```bash
# Main stack
sudo systemctl status fortisai.service

# Monitor service
sudo systemctl status fortisai_monitor.service
```

### View Logs
```bash
# Main stack logs
sudo journalctl -u fortisai.service -f

# Monitor service logs
sudo journalctl -u fortisai_monitor.service -f
```

### Common Issues
- **Service won't start:** Check dependencies with `sudo systemctl list-dependencies fortisai.service`
- **Model updates failing:** Check `model_state.json` and Hugging Face API keys
- **Container crashes:** Review `fortisai-all-up.log` in `~/fortisai-dev/logs/`

---

## 🔧 Maintenance

### Manual Model Update
```bash
python3 model_update.py
```

### Manual Stack Restart
```bash
sudo systemctl restart fortisai.service
```

### Cycle Validation

The FortisAI helper cycle was validated on `aiengine000` on 2026-06-22 with `fortisai_monitor.service` stopped during shutdown validation and restarted after successful startup.

- `./Development_Environment/linux/fortisai-dev-helper.sh all-down` completed successfully. Application containers stopped according to ownership, while `fortisai-coredns` remained running on both `aiengine000` and `aiengine001`.
- `./Development_Environment/linux/fortisai-dev-helper.sh all-up` completed successfully. Vault started and unsealed before dependent services came up; MCP bridge smoke checks and OpenWebUI CodeIndexer skill import completed successfully.
- Required-container audit passed after startup: `aiengine000` reported 54 required containers running, zero stopped, zero missing, and zero missing from `fortisai-calico-net`; `aiengine001` reported its required `fortisai-coredns` container running on `fortisai-calico-net`.
- Fresh-container DNS was validated on both hosts. `aiengine001` resolves `fortisai-llama-server.fortisai.local` to the primary host's LAN-reachable service address and can reach `/v1/models` on port `8011`.
- Runtime endpoint checks returned HTTP `200` for Vault, primary llama-server, secondary llama-server, FortisAI proxy, Honcho, and Hermes. Traefik dashboard returned the expected HTTP `401` auth challenge. OpenClaw was running with ports `18789` and `18790` published.
- Permanent fixes from this validation: `hermes_down` falls back to direct container removal when compose cannot read the container-owned `.env`; `fortisai.service` now runs CoreDNS bootstrap before the full stack and preserves `fortisai-coredns` during cleanup; Calico shared DNS publish no longer fails only because a route-service refresh cannot use sudo in a non-interactive boot.
- `fortisai.service` and `fortisai_monitor.service` are enabled on `aiengine000`, and `fortisai_monitor.service` was restarted after validation. The same services are enabled on `aiengine001`; because `aiengine001` has `primary_system: false`, `fortisai.service` acts as a CoreDNS-only bootstrap participant there and does not start application containers.

### View Model State
```bash
cat ~/FortisAI/Development_Environment/model_state.json
```

### Run Llama Model Tests
```bash
# Run tests manually
python3 test_llama_models.py

# Run scheduler for monthly testing
python3 test_llama_models.py scheduler
```

---

## 📚 Additional Resources

- [FortisAI Architecture Documentation](../ARCHITECTURE.md)
- [Deployment Guide](../DEPLOYMENT_INCIDENT_TEMPLATE.md)
- [Cost Estimates](../CostEstimates/README.md)

## 📝 Version History

- **v3.4:** Added runtime `~/fortisai-dev/watchdog` active-host inventory and `watchdown.json` activity pause control
- **v3.3:** Documented 2026-06-22 helper all-down/all-up validation and CoreDNS bootstrap through `fortisai.service`
- **v3.2:** Documented full `fortisai.service` down/up cycle validation and Honcho memory writeback verification
- **v3.1:** Moved model update and llama validation schedulers under `fortisai_monitor.service`
- **v3.0:** Added `test_llama_models.py` with APScheduler integration for monthly automated testing
- **v2.0:** Added `test-llama-models.sh` (legacy wrapper) and model validation utilities
- **v1.5:** Added `model_update.py` for automatic model updates
- **v1.0:** Initial release with basic service management
