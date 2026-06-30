# Appsmith in FortisAI (Windows)

This document describes how Appsmith is deployed in the FortisAI local development platform on Windows, how it is wired into the shared runtime, and how to use it.

## What Appsmith Is Used For

Appsmith provides a low-code UI builder for internal tools and operator dashboards.

Within FortisAI local development, Appsmith is intended for:

- Building internal UI pages that call local APIs (for example Oracle Node API).
- Prototyping data workflows that read and write to local services.
- Rapidly validating UI + API patterns before promoting designs to production stacks.

## Deployment Model in FortisAI

Appsmith is started by the Windows helper as part of the default local stack.

- Compose file path: `$HOME\fortisai-dev\appsmith\docker-compose.yml`
- Container name (default): `fortisai-appsmith`
- Image (default): `appsmith/appsmith-ce:latest`
- Host URL (default): `http://localhost:18080`
- Internal container port: `80`

The helper command flow:

1. `.\fortisai-dev-helper.ps1 setup` writes the Appsmith compose file.
2. `.\fortisai-dev-helper.ps1 up` starts MongoDB and initializes replica set `rs0` before Appsmith startup.
3. `.\fortisai-dev-helper.ps1 down` stops Appsmith with the rest of the local stack.
4. `.\fortisai-dev-helper.ps1 check` validates Appsmith HTTP reachability.

## Wiring Into the FortisAI Platform

Appsmith is wired into FortisAI through the shared Podman network and service lifecycle.

### Network wiring

- Shared network: `fortisai-dev-net`
- Appsmith is attached to that same network as:
  - MongoDB (`fortisai-mongodb`)
  - Oracle AI Database Free (`fortisai-oracle-db`)
  - ORDS (`fortisai-ords`)
  - SQLcl sidecar (`fortisai-sqlcl`)
  - Oracle Node API (`fortisai-oracle-node-api`)
  - n8n and OpenWebUI
  - Dify runtime containers

This lets Appsmith connect to local services by service name when needed (for example through API/data connectors configured in Appsmith).

### Lifecycle wiring

Appsmith is included in the same helper lifecycle used by FortisAI local services:

- `setup`: writes compose definition
- `up`: starts container
- `status`: visible via `podman ps`
- `logs appsmith`: follows Appsmith logs
- `check`: probes the Appsmith URL
- `down`: stops container

### Database wiring

Appsmith is wired by helper-generated compose to use local MongoDB by default:

- `APPSMITH_DB_URL=mongodb://fortisai-mongodb:27017/appsmith?replicaSet=rs0`
- `APPSMITH_MONGODB_URI=mongodb://fortisai-mongodb:27017/appsmith?replicaSet=rs0`
- Redis runtime wiring remains `APPSMITH_REDIS_URL=redis://fortisai-redis:6379`

### Integration boundaries

Appsmith is not pre-seeded with FortisAI application schemas or dashboards by default.

It is available as a local UI runtime that you configure to consume FortisAI local endpoints, such as:

- Oracle Node API: `http://127.0.0.1:8090`
- ORDS base endpoint: `http://127.0.0.1:8181/ords/`

## Usage

## 1) Start stack

```powershell
.\fortisai-dev-helper.ps1 up
```

## 2) Open Appsmith

- Browser URL: `http://localhost:18080`

## 3) Verify health

```powershell
.\fortisai-dev-helper.ps1 check
```

Expected line includes:

- `appsmith HTTP 200`

## 4) View logs

```powershell
.\fortisai-dev-helper.ps1 logs appsmith
```

## 5) Stop stack

```powershell
.\fortisai-dev-helper.ps1 down
```

## Environment Overrides

You can customize Appsmith behavior through helper environment variables:

- `APPSMITH_URL` (health-check target; default `http://localhost:18080`)
- `APPSMITH_CONTAINER_NAME` (default `fortisai-appsmith`)
- `APPSMITH_IMAGE` (default `appsmith/appsmith-ce:latest`)
- `APPSMITH_HOST_PORT` (default `18080`)
- `APPSMITH_DB_URL` (default `mongodb://fortisai-mongodb:27017/appsmith?replicaSet=rs0`)
- `MONGODB_CONTAINER_NAME` (default `fortisai-mongodb`)
- `MONGODB_HOST_PORT` (default `27017`)
- `MONGODB_DB` (default `appsmith`)
- `MONGODB_REPLICA_SET` (default `rs0`)

Example:

```powershell
$env:APPSMITH_HOST_PORT = "28080"
$env:APPSMITH_URL = "http://localhost:28080"
.\fortisai-dev-helper.ps1 up
```

## Troubleshooting

## Appsmith page does not load

1. Check container status:

```powershell
podman ps --format "table {{.Names}}`t{{.Status}}`t{{.Ports}}" | Select-String appsmith
```

2. Stream logs:

```powershell
.\fortisai-dev-helper.ps1 logs appsmith
```

3. Confirm port availability (default 18080):

```powershell
netstat -ano | findstr :18080
```

## Helper `up` stops before Appsmith starts

If another service fails earlier in startup, run:

```powershell
.\fortisai-dev-helper.ps1 down
.\fortisai-dev-helper.ps1 up
```

Then re-check Appsmith with `.\fortisai-dev-helper.ps1 check`.

## Appsmith starts but DB init fails

1. Check MongoDB logs:

```powershell
.\fortisai-dev-helper.ps1 logs mongodb
```

2. Verify MongoDB responds in helper check output:

```powershell
.\fortisai-dev-helper.ps1 check
```

Expected line includes `mongodb ping passed`.
