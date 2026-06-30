# Oracle Node API Container

This container provides a local Node.js REST/WS surface for Oracle tool-style operations.

`/exec`, `/script`, `/ddl`, and `/format` are wired to the SQLcl container via stdio using container exec (`podman exec -i <sqlcl-container> ...`).

## Exposed Endpoints

- `POST /exec`
- `POST /script`
- `POST /ddl`
- `POST /format`
- `POST /mcp` (returns HTTP 426; use WS upgrade)
- `WS /mcp`
- `GET /health`
- `GET /version`

## Run with Podman or Docker Compose

```bash
cd Development_Environment/oracle-node-api
podman compose up -d --build
```

The SQLcl sidecar container must already be running (for example through the FortisAI helper `up` flow).

## Requirements for SQLcl Stdio Execution

`/exec`, `/script`, `/ddl`, and `/format` depend on `podman exec -i` into the SQLcl sidecar.

Minimum runtime requirements:

- SQLcl sidecar container is running and reachable by name (default `fortisai-sqlcl`).
- Podman CLI is installed in Oracle Node API image.
- Podman socket is mounted and reachable at `/tmp/podman.sock`.
- `CONTAINER_HOST=unix:///tmp/podman.sock` is set for the Oracle Node API container.
- Compose is running with Option 3 local policy (`privileged: true` and `security_opt: label=disable`).

Optional environment variables:

- `SQLCL_RUNTIME_BIN` (default: `podman`)
- `SQLCL_CONTAINER_NAME` (default: `fortisai-sqlcl`)
- `SQLCL_TIMEOUT_MS` (default: `30000`)
- `CONTAINER_HOST` (default: `unix:///tmp/podman.sock`)
- `PODMAN_SOCKET_PATH` (Podman machine socket path on the host)

The compose file mounts the Podman socket:

- `${PODMAN_SOCKET_PATH:-/run/user/1001/podman/podman.sock}:/tmp/podman.sock`

The macOS and Windows FortisAI helpers resolve `PODMAN_SOCKET_PATH` from the active Podman machine before starting this service. If you run this compose file manually, set `PODMAN_SOCKET_PATH` to the active Podman machine socket path first.

## Security Caveat

Current Option 3 settings are intended for local development and troubleshooting. Do not reuse this posture as-is for production workloads without hardening runtime permissions.

Stop:

```bash
podman compose down
```

## Quick Test

```bash
curl -s http://127.0.0.1:8090/health
curl -s http://127.0.0.1:8090/version
curl -s -X POST http://127.0.0.1:8090/exec -H "Content-Type: application/json" -d '{"statement":"select 1 from dual"}'
curl -s -X POST http://127.0.0.1:8090/script -H "Content-Type: application/json" -d '{"script":"select 1 from dual; select 2 from dual;"}'
curl -s -X POST http://127.0.0.1:8090/ddl -H "Content-Type: application/json" -d '{"ddl":"create table demo_table(id number)"}'
curl -s -X POST http://127.0.0.1:8090/format -H "Content-Type: application/json" -d '{"sql":"select * from my_table where id = 1"}'
```

For websocket `/mcp` testing, use any WS client (for example `wscat`) against `ws://127.0.0.1:8090/mcp`.
