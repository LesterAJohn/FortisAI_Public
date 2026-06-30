# Proxmox MCP (ProxmoxMCP-Plus)

This directory contains FortisAI wiring for ProxmoxMCP-Plus OpenAPI integration.

## What This Adds

- A helper-managed Proxmox OpenAPI bridge container:
  - Container: `fortisai-mcp-openapi-proxmox`
  - Local OpenAPI URL: `http://127.0.0.1:8095/openapi.json`
  - Local facade endpoints for individual VM/LXC statistics plus authenticated VM/LXC lifecycle and resource changes
- OpenWebUI tool import payload:
  - `openwebui-proxmox-mcp-tools.import.json`
- OpenWebUI skill payload:
  - `openwebui-proxmox-mcp-skill.create.json`

## Runtime Source

Bridge runtime uses the upstream container image from:

- `ghcr.io/rekklesna/proxmoxmcp-plus:latest`

## Configuration

The helper checks for Proxmox configuration in this order:

1. `PROXMOX_BRIDGE_ENABLED=true` (force enable)
2. Proxmox values already stored in Vault under `secret/fortisai/dev/proxmox/*`
3. `proxmox-config.json` in this directory
4. Required env vars:
   - `PROXMOX_HOST`
   - `PROXMOX_USER`
   - `PROXMOX_TOKEN_NAME`
   - `PROXMOX_TOKEN_VALUE`

If none are present and `PROXMOX_BRIDGE_ENABLED` is not forced to true, Proxmox bridge startup is skipped while the other MCP bridges still start.

Create local config from the template. Keep real Proxmox token values local and out of Git:

```bash
cp Development_Environment/mcp/proxmox/proxmox-config.json.example Development_Environment/mcp/proxmox/proxmox-config.json
```

On helper-managed startup, `mcp-up` starts and unseals Vault first, loads this local seed file or exported variables, writes Proxmox values into Vault, and launches `fortisai-mcp-openapi-proxmox` with resolved startup env plus `FORTISAI_VAULT_ADDR`, `VAULT_ADDR`, and a read-only `VAULT_TOKEN`.

Linux exposes Proxmox through a local FortisAI facade:

- `fortisai-mcp-openapi-proxmox-upstream` runs the upstream ProxmoxMCP-Plus OpenAPI service internally on port `8811` with the Vault-backed `PROXMOX_API_KEY`.
- `fortisai-mcp-openapi-proxmox` listens on port `8095`, proxies to the upstream service, and injects the bearer key internally.
- `curl http://127.0.0.1:8095/openapi.json` should return the OpenAPI schema without requiring the caller to print or know the Vault-managed key.
- OpenWebUI and Dify containers should use `http://fortisai-mcp-openapi-proxmox.fortisai.local:8095/openapi.json`.
- FortisAI adds read-only individual VM/LXC statistics endpoints and authenticated mutation protection on the local facade. VM/LXC resource changes, VM disk creation, and upstream lifecycle/change actions such as start, stop, shutdown, reset, restart, clone, delete, restore, rollback, download, execute, cancel, and retry require `X-FortisAI-Proxmox-Update-Key` or `Authorization: Bearer <key>`.

Primary Vault paths:

- `secret/fortisai/dev/proxmox/host`
- `secret/fortisai/dev/proxmox/user`
- `secret/fortisai/dev/proxmox/token_name`
- `secret/fortisai/dev/proxmox/token_value`
- `secret/fortisai/dev/proxmox/openapi_api_key`
- `secret/fortisai/dev/proxmox/openapi_update_key`

## Optional Env Vars

- `PROXMOX_PORT` (default `8006`)
- `PROXMOX_VERIFY_SSL` (default `true`)
- `PROXMOX_DEV_MODE` (set `true` only with self-signed certs + verify disabled)
- `PROXMOX_SERVICE` (default `PVE`)
- `LOG_LEVEL` (default `INFO`)
- `PROXMOX_API_KEY` (bridge bearer key)
- `PROXMOX_API_STRICT_AUTH` (default `false` in FortisAI helper wiring)

## Helper Lifecycle

The normal MCP helper flow starts this bridge only when configuration is present or `PROXMOX_BRIDGE_ENABLED=true` is exported:

```bash
./Development_Environment/mac/fortisai-dev-helper.sh mcp-up
./Development_Environment/windows/fortisai-dev-helper.ps1 mcp-up
./Development_Environment/linux/fortisai-dev-helper.sh mcp-up
```

Direct bridge launcher path from the repository root:

```bash
bash Development_Environment/mcp/start-mcp-openapi-bridges.sh
```

## Individual Guest Statistics

The FortisAI facade exposes read-only statistics endpoints for individual Proxmox QEMU VMs and LXC containers. These endpoints do not require the update key because they do not mutate Proxmox state. They return `status/current`, optional permanent config, and optional `rrddata` for `hour`, `day`, `week`, `month`, or `year`.

Get QEMU VM statistics:

```bash
curl -sS -X POST http://127.0.0.1:8095/get_vm_statistics \
  -H "Content-Type: application/json" \
  -d '{"node":"pve2","vmid":"124","timeframe":"hour","cf":"AVERAGE"}'
```

Get LXC container statistics by selector:

```bash
curl -sS -X POST http://127.0.0.1:8095/get_container_statistics \
  -H "Content-Type: application/json" \
  -d '{"selector":"pve:108","timeframe":"hour","cf":"AVERAGE"}'
```

Set `include_config=false` or `include_rrd=false` to reduce payload size when only current status counters are needed.

## Authenticated Update Endpoints

The FortisAI facade exposes resource update endpoints that are intentionally separate from the upstream read tools. They require the Vault-managed update key from `secret/fortisai/dev/proxmox/openapi_update_key`. The same key is also required for upstream mutating lifecycle and change tools that are proxied through the facade, including start/stop/shutdown/reset/restart, clone/delete/create, backup/restore/snapshot rollback, ISO download/delete, job cancel/retry, and VM command execution.

Use either header style:

```bash
-H "X-FortisAI-Proxmox-Update-Key: $PROXMOX_UPDATE_API_KEY"
-H "Authorization: Bearer $PROXMOX_UPDATE_API_KEY"
```

Update a QEMU VM and return before/after configuration:

```bash
curl -sS -X POST http://127.0.0.1:8095/update_vm_resources \
  -H "Content-Type: application/json" \
  -H "X-FortisAI-Proxmox-Update-Key: $PROXMOX_UPDATE_API_KEY" \
  -d '{"node":"pve2","vmid":"124","sockets":2,"cores":5,"memory":65536}'
```

Create and attach a new QEMU VM disk and return before/after configuration. `size_gib` is GiB, so `1024` creates a 1 TiB disk. The facade uses the Proxmox POST config API, which supports storage allocation and disk hotplug when the VM configuration allows it.

```bash
curl -sS -X POST http://127.0.0.1:8095/create_vm_disk \
  -H "Content-Type: application/json" \
  -H "X-FortisAI-Proxmox-Update-Key: $PROXMOX_UPDATE_API_KEY" \
  -d '{"node":"pve2","vmid":"124","disk":"scsi1","storage":"BootVolume","size_gib":1024,"cache":"writethrough","iothread":true}'
```

Update one or more LXC containers and return before/after configuration:

```bash
curl -sS -X POST http://127.0.0.1:8095/update_container_resources \
  -H "Content-Type: application/json" \
  -H "X-FortisAI-Proxmox-Update-Key: $PROXMOX_UPDATE_API_KEY" \
  -d '{"selector":"pve:108","cores":2,"memory":4096,"swap":1024}'
```

CPU and memory changes may require a guest reboot, VM restart, or container restart before the running guest sees the new resources. Newly attached disks still need guest-side partitioning, formatting, and mounting after Proxmox presents them to the VM.

## OpenWebUI Reload

```bash
bash Development_Environment/mcp/reload-openwebui-tool-connection.sh \
  Development_Environment/mcp/proxmox/openwebui-proxmox-mcp-tools.import.json

bash Development_Environment/mcp/create-openwebui-skill.sh \
  Development_Environment/mcp/proxmox/openwebui-proxmox-mcp-skill.create.json
```

## Safety

Use read-only discovery operations first (nodes, VMs, containers, storage) before mutating actions.
