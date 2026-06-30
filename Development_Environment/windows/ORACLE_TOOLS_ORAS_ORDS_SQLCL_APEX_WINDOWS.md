# Oracle Tools on Windows: ORAS, ORDS, SQLcl, APEX, and Oracle Node API

This guide covers practical local workflows for Oracle tooling in the FortisAI Windows development environment.

## Scope

- ORAS CLI for OCI Registry artifact/image workflows
- ORDS endpoint and logs for local database REST access
- SQLcl access through the FortisAI SQLcl sidecar
- APEX install/check/reset through helper commands
- Oracle Node API local REST and websocket endpoints

## Prerequisites

1. Podman is installed and running.
2. FortisAI helper setup has been executed:

```powershell
cd C:\Users\<your-user>\Desktop\FortisAI\Development_Environment\windows
.\fortisai-dev-helper.ps1 setup
```

3. Oracle DB local stack is running when using SQLcl/APEX:

```powershell
.\fortisai-dev-helper.ps1 up
```

## Credential and Password Reference

The FortisAI helper uses environment variables for credential management. If a variable is not set, the helper applies defaults.

### Default Local Credentials

1. Oracle DB PDB admin user: `pdbadmin`
2. Oracle DB password default: `FortisAI26ai!2026` (`ORACLE_DB_PASSWORD`)
3. ORDS DB user default: `ORDS_PUBLIC_USER` (`ORDS_DB_USER`)
4. ORDS DB password default: same as `ORACLE_DB_PASSWORD` unless `ORDS_DB_PASSWORD` is set
5. APEX admin username: `ADMIN`
6. APEX admin password default: same as `ORACLE_DB_PASSWORD` unless `APEX_ADMIN_PASSWORD` is set

### Password Source Rules

1. `ORACLE_DB_PASSWORD` is the primary default for local Oracle services.
2. `ORDS_DB_PASSWORD` overrides ORDS-specific password when explicitly set.
3. `APEX_ADMIN_PASSWORD` overrides APEX admin password when explicitly set.
4. `apex-install` and `apex-reset` both enforce APEX ADMIN credentials through a deterministic API call.

### Recommended Override Pattern

Set these before running `setup`, `up`, `apex-install`, or `apex-reset`:

```powershell
$env:ORACLE_DB_PASSWORD = 'your-strong-db-password'
$env:ORDS_DB_PASSWORD = 'your-strong-ords-password'
$env:APEX_ADMIN_PASSWORD = 'your-strong-apex-admin-password'
.\fortisai-dev-helper.ps1 apex-reset
```

### Verify Current Runtime State

```powershell
.\fortisai-dev-helper.ps1 apex-check
.\fortisai-dev-helper.ps1 logs ords | Select-Object -First 120
```

APEX Administration login endpoint:

`http://127.0.0.1:8181/ords/r/apex/workspace-sign-in/administration-sign-in`

## ORAS (Oracle Registry Artifact CLI)

The helper script does not currently wrap ORAS commands. Install and run ORAS directly.

### Install ORAS

```powershell
winget install ORAS.Project
oras version
```

### Login to Oracle Container Registry

```powershell
$env:OCR_REGISTRY = "container-registry.oracle.com"
oras login $env:OCR_REGISTRY -u $env:OCR_USERNAME -p $env:OCR_AUTH_TOKEN
```

### Pull Example Oracle Artifact/Image Manifest

```powershell
oras repo tags container-registry.oracle.com/database/free | Select-Object -First 20
```

Use helper commands for actual image pre-pull and lifecycle:

```powershell
.\fortisai-dev-helper.ps1 oracle-db-pull
.\fortisai-dev-helper.ps1 logs oracle-db
```

## SQLcl Workflows

The helper runs SQLcl in the bundled SQLcl sidecar container.

### Open Interactive SQLcl Shell

```powershell
.\fortisai-dev-helper.ps1 sqlcl-shell
```

### Run SQLcl MCP Server

```powershell
.\fortisai-dev-helper.ps1 sqlcl-mcp
```

### Validate SQLcl MCP Handshake

```powershell
.\fortisai-dev-helper.ps1 sqlcl-mcp-smoke
```

Generated MCP config path:

`~/fortisai-dev/sqlcl-mcp/mcp.json`

## ORDS Workflows

ORDS is bundled with the local Oracle stack and provides REST and APEX endpoints.

### Check ORDS URL

`http://127.0.0.1:8181/ords/`

### Stream ORDS Logs

```powershell
.\fortisai-dev-helper.ps1 logs ords
```

### Validate ORDS Endpoint

```powershell
curl.exe -I http://127.0.0.1:8181/ords/
```

## Oracle Node API Workflows

Oracle Node API is included in the helper-managed `up` and `down` lifecycle.

### Runtime Requirements (SQLcl Stdio, Option 3)

`POST /exec`, `POST /script`, `POST /ddl`, and `POST /format` run inside the SQLcl sidecar through stdio (`podman exec -i fortisai-sqlcl ...`).

Required for successful execution:

- `fortisai-sqlcl` container is running.
- Oracle Node API container has Podman CLI installed.
- Podman socket is mounted to `/tmp/podman.sock` and `CONTAINER_HOST=unix:///tmp/podman.sock` is set.
- Option 3 compose settings are enabled (`privileged: true`, `security_opt: label=disable`).

### Base URL

`http://127.0.0.1:8090`

### Exposed Endpoints

- `POST /exec`
- `POST /script`
- `POST /ddl`
- `POST /format`
- `POST /mcp` (returns HTTP 426 Upgrade Required; use websocket)
- `WS /mcp`
- `GET /health`
- `GET /version`

### Check API Health and Version

```powershell
curl.exe -s http://127.0.0.1:8090/health
curl.exe -s http://127.0.0.1:8090/version
```

### Test Core REST Endpoints

```powershell
curl.exe -s -X POST http://127.0.0.1:8090/exec -H "Content-Type: application/json" -d '{"statement":"select 1 from dual"}'
curl.exe -s -X POST http://127.0.0.1:8090/script -H "Content-Type: application/json" -d '{"script":"select 1 from dual; select 2 from dual;"}'
curl.exe -s -X POST http://127.0.0.1:8090/ddl -H "Content-Type: application/json" -d '{"ddl":"create table demo_table(id number)"}'
curl.exe -s -X POST http://127.0.0.1:8090/format -H "Content-Type: application/json" -d '{"sql":"select * from demo_table where id = 1"}'
```

### Stream Oracle Node API Logs

```powershell
.\fortisai-dev-helper.ps1 logs oracle-node-api
```

## APEX Workflows

APEX is optional and runs through ORDS after installation.

### Install APEX

```powershell
.\fortisai-dev-helper.ps1 apex-install
```

APEX Administration sign-in uses:

1. Username: `ADMIN`
2. Password: value of `APEX_ADMIN_PASSWORD` (or `ORACLE_DB_PASSWORD` if not set)

### Check APEX Status and Endpoint

```powershell
.\fortisai-dev-helper.ps1 apex-check
curl.exe -I http://127.0.0.1:8181/ords/apex
```

### Reset APEX Runtime

```powershell
.\fortisai-dev-helper.ps1 apex-reset
.\fortisai-dev-helper.ps1 apex-check
```

Use `apex-reset` whenever you change `APEX_ADMIN_PASSWORD` to enforce the new password.

Default APEX URL after install:

`http://127.0.0.1:8181/ords/apex`

## Quick Troubleshooting

### ORAS auth fails

1. Verify OCR credentials are set.
2. Re-run `oras login`.
3. Confirm account access to Oracle registry terms/subscription.

### SQLcl/APEX commands fail

1. Confirm containers are up: `.\fortisai-dev-helper.ps1 status`
2. Check logs:
   - `.\fortisai-dev-helper.ps1 logs oracle-db`
   - `.\fortisai-dev-helper.ps1 logs ords`
   - `.\fortisai-dev-helper.ps1 logs sqlcl`

### Oracle Node API endpoint fails

1. Confirm services are up: `.\fortisai-dev-helper.ps1 status`
2. Check API logs: `.\fortisai-dev-helper.ps1 logs oracle-node-api`
3. Validate health endpoint: `curl.exe -I http://127.0.0.1:8090/health`
4. If SQL endpoints fail but health is OK, verify SQLcl sidecar is running and Podman socket mapping is valid for your machine.

### Oracle Node API security posture (Option 3)

Current compose runtime uses elevated local settings (`privileged` and SELinux label disable) to support container-to-container SQLcl stdio execution. Treat this as local/dev-only unless hardened.

### APEX endpoint not reachable

1. Run `.\fortisai-dev-helper.ps1 apex-check`
2. Validate ORDS endpoint: `curl.exe -I http://127.0.0.1:8181/ords/`
3. Re-run `apex-install` if status is not installed.

### APEX admin login fails

1. Re-apply credentials: `.\fortisai-dev-helper.ps1 apex-reset`
2. Wait 10-15 seconds for ORDS to fully restart.
3. Retry the Administration sign-in page.

## Security Notes

- Do not commit OCR tokens or database passwords into Git-tracked files.
- Prefer environment variables and secret managers for credentials.
- Rotate OCR and OCI auth tokens periodically.
