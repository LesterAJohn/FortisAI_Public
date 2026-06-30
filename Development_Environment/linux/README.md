# Linux Development Environment

This folder contains Linux-specific setup and operator workflows for the FortisAI local stack.

## Documents

- [LINUX_DEV_SETUP_DIFY_N8N_OPENWEBUI.md](LINUX_DEV_SETUP_DIFY_N8N_OPENWEBUI.md)
  End-to-end Linux setup for Dify, Honcho, Firecrawl, n8n, OpenWebUI, and shared services.

- [LM_STUDIO_SETUP_LINUX.md](LM_STUDIO_SETUP_LINUX.md)
  Linux setup flow for LM Studio and helper wiring.

- [GIT_IMPORT_EXPORT_DIFY_N8N_LINUX.md](GIT_IMPORT_EXPORT_DIFY_N8N_LINUX.md)
  Git workflow for exporting Dify YAML and n8n JSON artifacts on Linux.

- [ORACLE_TOOLS_ORAS_ORDS_SQLCL_APEX_LINUX.md](ORACLE_TOOLS_ORAS_ORDS_SQLCL_APEX_LINUX.md)
  Linux workflows for ORAS and ORDS plus SQLcl, Oracle Node API, and APEX helper operations.

- [AppSmith.md](AppSmith.md)
  Appsmith integration notes for the FortisAI shared local network.

- [setup-aiuser-fortisai-repo.sh](setup-aiuser-fortisai-repo.sh)
  Clones or updates FortisAI at `/opt/home/aiuser/FortisAI` and applies host-local git excludes for `/tmp` and `/Development_Environment/llm_directory`.

## Helper Script

- [fortisai-dev-helper.sh](fortisai-dev-helper.sh)

Run the commands below from the `Development_Environment` directory.

Core commands:

```bash
./linux/fortisai-dev-helper.sh setup
./linux/fortisai-dev-helper.sh oracle-db-pull
./linux/fortisai-dev-helper.sh vault-up
./linux/fortisai-dev-helper.sh vault-init
./linux/fortisai-dev-helper.sh vault-unseal
./linux/fortisai-dev-helper.sh vault-status
./linux/fortisai-dev-helper.sh vault-read <path>
./linux/fortisai-dev-helper.sh vault-write <path> <value>
./linux/fortisai-dev-helper.sh vault-del <path>
./linux/fortisai-dev-helper.sh host add <hostname> <userid> <password|->
./linux/fortisai-dev-helper.sh host del <hostname>
./linux/fortisai-dev-helper.sh host app-service [service]
./linux/fortisai-dev-helper.sh host app-move <service> <source_host> <destination_host>
./linux/fortisai-dev-helper.sh app-config
./linux/fortisai-dev-helper.sh calico-up --test
./linux/fortisai-dev-helper.sh calico-check
./linux/fortisai-dev-helper.sh vault-down
./linux/fortisai-dev-helper.sh up
./linux/fortisai-dev-helper.sh down
./linux/fortisai-dev-helper.sh openclaw-up
./linux/fortisai-dev-helper.sh openclaw-down
./linux/fortisai-dev-helper.sh openclaw-shell
./linux/fortisai-dev-helper.sh openwebui-shell
./linux/fortisai-dev-helper.sh openvscode-up
./linux/fortisai-dev-helper.sh openvscode-down
./linux/fortisai-dev-helper.sh openvscode-users
./linux/fortisai-dev-helper.sh openvscode-token [user]
./linux/fortisai-dev-helper.sh openvscode-shell
./linux/fortisai-dev-helper.sh openvscode-list-extensions [user]
./linux/fortisai-dev-helper.sh openvscode-install-extension [user] <extension-id-or-vsix>
./linux/fortisai-dev-helper.sh openvscode-uninstall-extension [user] <extension-id>
./linux/fortisai-dev-helper.sh hermes-up
./linux/fortisai-dev-helper.sh hermes-down
./linux/fortisai-dev-helper.sh hermes-shell
./linux/fortisai-dev-helper.sh traefik-up
./linux/fortisai-dev-helper.sh traefik-down
./linux/fortisai-dev-helper.sh traefik-check
./linux/fortisai-dev-helper.sh codeindexer-up
./linux/fortisai-dev-helper.sh codeindexer-down
./linux/fortisai-dev-helper.sh codeindexer-check
./linux/fortisai-dev-helper.sh milvus-up
./linux/fortisai-dev-helper.sh milvus-down
./linux/fortisai-dev-helper.sh opensearch-up
./linux/fortisai-dev-helper.sh opensearch-down
./linux/fortisai-dev-helper.sh openmetadata-up
./linux/fortisai-dev-helper.sh openmetadata-down
./linux/fortisai-dev-helper.sh openmetadata-check
./linux/fortisai-dev-helper.sh llama-router-up
./linux/fortisai-dev-helper.sh llama-router-up claude/Negentropy-claude-opus-4.7-9B-Q4_K_M.gguf
./linux/fortisai-dev-helper.sh llama-router-switch mistral/Devstral-Small-2507-Q8_0.gguf
./linux/fortisai-dev-helper.sh llama-router-models
./linux/fortisai-dev-helper.sh llama-router-status
./linux/fortisai-dev-helper.sh llama-router-shell
./linux/fortisai-dev-helper.sh llama-router-logs
./linux/fortisai-dev-helper.sh llama-router-down
./linux/fortisai-dev-helper.sh llama-secondary-up
./linux/fortisai-dev-helper.sh llama-secondary-switch mistral/Devstral-Small-2507-Q8_0.gguf
./linux/fortisai-dev-helper.sh llama-secondary-status
./linux/fortisai-dev-helper.sh llama-secondary-logs
./linux/fortisai-dev-helper.sh llama-secondary-down
./linux/fortisai-dev-helper.sh status
./linux/fortisai-dev-helper.sh check
./linux/fortisai-dev-helper.sh sqlcl-shell
./linux/fortisai-dev-helper.sh sqlcl-mcp
./linux/fortisai-dev-helper.sh sqlcl-mcp-smoke
./linux/fortisai-dev-helper.sh mcp-up
./linux/fortisai-dev-helper.sh mcp-down
./linux/fortisai-dev-helper.sh apex-install
./linux/fortisai-dev-helper.sh apex-check
./linux/fortisai-dev-helper.sh apex-reset
./linux/fortisai-dev-helper.sh scaffold-config-repos
./linux/fortisai-dev-helper.sh scaffold-templates all
./linux/fortisai-dev-helper.sh scaffold-templates dify my-app
./linux/fortisai-dev-helper.sh scaffold-templates n8n my-workflow
./linux/fortisai-dev-helper.sh lmstudio-setup
./linux/fortisai-dev-helper.sh lmstudio-start
./linux/fortisai-dev-helper.sh lmstudio-check
./linux/fortisai-dev-helper.sh daytona-setup
./linux/fortisai-dev-helper.sh daytona-up
./linux/fortisai-dev-helper.sh daytona-sandbox-smoke
./linux/fortisai-dev-helper.sh daytona-check
./linux/fortisai-dev-helper.sh daytona-down
./linux/fortisai-dev-helper.sh logs oracle-db
./linux/fortisai-dev-helper.sh logs mongodb
./linux/fortisai-dev-helper.sh logs redis
./linux/fortisai-dev-helper.sh logs rabbitmq
./linux/fortisai-dev-helper.sh logs vault
./linux/fortisai-dev-helper.sh logs firecrawl
./linux/fortisai-dev-helper.sh logs pgvector
./linux/fortisai-dev-helper.sh logs honcho
./linux/fortisai-dev-helper.sh logs openclaw
./linux/fortisai-dev-helper.sh logs hermes
./linux/fortisai-dev-helper.sh logs traefik
./linux/fortisai-dev-helper.sh logs codeindexer
./linux/fortisai-dev-helper.sh logs milvus
./linux/fortisai-dev-helper.sh logs openmetadata
./linux/fortisai-dev-helper.sh logs opensearch
./linux/fortisai-dev-helper.sh logs qdrant
./linux/fortisai-dev-helper.sh logs appsmith
./linux/fortisai-dev-helper.sh logs oracle-node-api
./linux/fortisai-dev-helper.sh logs ords
./linux/fortisai-dev-helper.sh logs sqlcl
./linux/fortisai-dev-helper.sh daytona-set-admin-creds <email> <password>
./linux/fortisai-dev-helper.sh prod-template
./linux/fortisai-dev-helper.sh validate-prod
./linux/fortisai-dev-helper.sh link-prod
```

Notes:

- Firecrawl is managed by default lifecycle commands (`up` / `down`).
- Firecrawl default API key is `fortisai-firecrawl-dev-api-key` via `FIRECRAWL_API_KEY`.
- OpenClaw and Hermes are managed by dedicated lifecycle commands.
- `all-up` now starts the full Linux operator stack in this order: primary llama router, secondary llama router, shared services, CodeIndexer/Milvus, OpenMetadata/OpenSearch, MCP OpenAPI bridges, OpenClaw, Hermes, Daytona, and Traefik.
- `all-down` stops the same expanded stack in reverse order.
- Core `up` starts the OpenAPI tool-server trio `repo_filesystem-server_1`, `repo_memory-server_1`, and `repo_time-server_1`. The helper verifies each `/openapi.json` endpoint and rebuilds the time-server image if a stale image is missing Python time dependencies such as `pytz`.
- Traefik is managed by `traefik-up`, `traefik-down`, and `traefik-check`. It exposes the web entrypoint on `http://127.0.0.1:18000` and the dashboard on `http://127.0.0.1:18088/dashboard/`.
- CodeIndexer is managed by `codeindexer-up`, `codeindexer-down`, and `codeindexer-check`. The helper clones `Indiejayk8s/CodeIndexer`, patches it for FortisAI OpenAI-compatible embeddings, builds the MCP package in a Node 20 container, starts Milvus, and exposes the OpenAPI bridge through `mcp-up` at `http://127.0.0.1:8096/openapi.json`.
- OpenMetadata is managed by `openmetadata-up`, `openmetadata-down`, and `openmetadata-check`. It reuses shared pgvector for Postgres, adds OpenSearch as its search backend, and uses the no-op pipeline client for local development.
- Helper-generated OpenSearch compose uses `DISABLE_SECURITY_PLUGIN=true` only; do not also add `plugins.security.disabled=true`, because OpenSearch exits when the same setting is supplied twice.
- `fortisai_monitor.service` watches the stable container set from the current host entry in the runtime inventory at `~/fortisai-dev/watchdog/active_host.json`, including Traefik, MCP OpenAPI bridges, CodeIndexer/Milvus, OpenSearch/OpenMetadata, Daytona, Dify, the primary and secondary llama routers, CoreDNS, and the OpenAPI tool-server trio. The repository file `Development_Environment/linux/active_host.json` is the seed/template; the runtime copy is the active setup file. The current Linux inventory lists 57 stable required containers on `aiengine000` and 4 on `aiengine001`; runtime-generated `*-infra` containers are intentionally excluded.
- Helper `setup` now generates `~/fortisai-dev/dify/docker/docker-compose.podman.yaml` for Podman-based Dify lifecycle and validation on Linux.
- Helper `setup` also seeds missing Dify runtime env files under `~/fortisai-dev/dify/docker/envs/` from the shipped `*.env.example` templates so Podman Dify startup does not fail on missing `web.env`-style files.
- Helper-generated Dify Podman compose now pins nginx to `docker.io/nginx:latest` to avoid short-name resolution failures on hosts with unqualified registries disabled.
- Helper-generated Dify Podman compose disables API and sandbox container healthchecks because failed container-level exec checks can hold rootless Podman runtime locks. Use `./linux/fortisai-dev-helper.sh check`, direct HTTP checks, and Dify container logs for validation.
- OpenWebUI interactive shell is available with `./linux/fortisai-dev-helper.sh openwebui-shell`.
- OpenVSCode interactive shell is available with `./linux/fortisai-dev-helper.sh openvscode-shell [user]`.
- OpenVSCode user instances are configured with `OPENVSCODE_USERS`, using comma or space separated entries in the form `user[:port[:token[:workspace]]]`. The first user remains `fortisai-openvscode` on port `13000`; additional users run as `fortisai-openvscode-<user>` on their configured or incremented ports.
- Each OpenVSCode user gets a separate token file, user-data volume, extension volume, and persistent home volume. Token files are written under `~/fortisai-dev/openvscode/users/<user>/connection-token`; extension installs can use marketplace IDs or host VSIX paths.
- Use `./linux/fortisai-dev-helper.sh openvscode-token [user]` to print the browser URL with the user's connection token. A bare URL such as `http://aiengine000:13000/` returns `403 Forbidden` because OpenVSCode requires the `?tkn=...` token to set the browser session cookie.
- Linux OpenVSCode defaults each user's mounted workspace to `~/openvscode/<user>/workspace`; for example, `aiuser` mounts `~/openvscode/aiuser/workspace` as `/workspace`. The helper creates the directory and prepares it with rootless Podman ownership so Cline, Continue, and other extensions can write there without scanning private runtime paths such as `~/fortisai-dev/vault`, `~/.ssh`, or `~/.config`. Set the per-user workspace field in `OPENVSCODE_USERS`, `OPENVSCODE_WORKSPACE_DIR`, or `OPENVSCODE_WORKSPACE_ROOT` only when intentionally changing this layout.
- OpenVSCode now mounts a per-user persistent container home at `OPENVSCODE_HOME_DIR` (`/home/workspace` by default) and sets `HOME`, `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`, and `XDG_DATA_HOME` there. This keeps Cline and Continue settings such as `.cline`, `.continue`, and XDG state writable and durable across helper-managed restarts.
- Cline, Continue, and other webview-based extensions need a browser secure context. Direct `http://aiengine000:13000` access can load OpenVSCode but may log `crypto.subtle is not available so webviews will not work`; use a localhost SSH tunnel with `OPENVSCODE_PUBLIC_HOST=localhost ./linux/fortisai-dev-helper.sh openvscode-token <user>` or an HTTPS route when webview panels are required.
- Linux OpenVSCode startup uses direct Podman container lifecycle control for predictable up/down behavior on rootless Podman; the helper still writes `~/fortisai-dev/openvscode/docker-compose.yml` for inspection and parity with the generated configuration.
- Validation on `aiengine000` confirmed two helper-managed users (`aiuser:13000` and a temporary test user on `13001`), token-enforced HTTP responses, explicit OpenVSCode entrypoint usage, per-user extension directory wiring, and isolated VSIX installation for the selected user.
- Vault uses `docker.io/hashicorp/vault:latest` with persistent file storage under `~/fortisai-dev/vault/file`, config under `~/fortisai-dev/vault/config`, and init credentials under `~/fortisai-dev/vault/vault-init.json`.
- Helper `up` and `all-up` start Vault first, initialize it on first run when needed, run `vault-unseal` from the saved init JSON, sync `secret/fortisai/dev/*`, and then launch dependent services.
- `openclaw-up` and `hermes-up` run the same Vault preparation before launching their dedicated components. `openclaw-down` and `hermes-down` stop only those components and leave shared Vault available.
- Vault logs are available with `./linux/fortisai-dev-helper.sh logs vault`; health and seal state are available with `./linux/fortisai-dev-helper.sh vault-status`.
- Vault operator secrets can be read, written, and deleted with `./linux/fortisai-dev-helper.sh vault-read <path>`, `./linux/fortisai-dev-helper.sh vault-write <path> <value>`, and `./linux/fortisai-dev-helper.sh vault-del <path>`, where `<path>` is relative to `secret/fortisai/dev/`. `vault-del` permanently removes metadata and all versions for that path.
- Active FortisAI hosts are tracked in the runtime inventory `~/fortisai-dev/watchdog/active_host.json`. Use `./linux/fortisai-dev-helper.sh host add <hostname> <userid> <password|->` to add or update a host; pass `-` to enter the password without putting it in shell history. The password is used only to bootstrap SSH key access from the primary host to the target host when key-based access is not already working. The runtime JSON file stores connectivity metadata, the Podman SSH URI, the helper-created SSH identity path, the `primary_system` guard, model maintenance flags (`model_update` and `test_llama_models`), and the host's `required_containers`; host passwords are not stored in JSON or Vault. The `required_containers` list should contain only stable container names that are expected to be running on that host. Use `host del <hostname>` to remove the JSON entry and Podman remote connection.
- Only the host with `primary_system: true` can run the Linux helper directly. On all other hosts, normal helper commands terminate with `This is not primary system`; `help` remains available for reference. `aiengine000` is the primary system, and secondary hosts such as `aiengine001` stay non-primary. Helper startup validates that `active_host.json` has exactly one `primary_system: true` host and refuses to run if the inventory is misconfigured. The primary helper can dispatch component commands to non-primary hosts through SSH with an internal `FORTISAI_REMOTE_DISPATCH=true` guard when the target host owns one of the command's `required_containers`.
- Services are mapped to their stable containers and runtime directories in `~/fortisai-dev/watchdog/service_map.json`. Helper startup merges new built-in service definitions into this runtime map so older hosts learn newer MCP containers such as Websearch, Daytona, Composio, OpenMetadata, and AOL IMAP without losing custom service entries. Use `host app-service [service]` from the primary host to list service-to-host assignments from the runtime map and active host inventory. Use `host app-scan [--dry-run]` to scan running Podman containers on every active host and update `active_host.json` for service containers already known in `service_map.json`; generated `*-infra` containers and unmapped running containers are reported but not added. Add `--prune-stopped` only when stopped known service containers should be removed from the expected inventory. Use `host app-move <service> <source_host> <destination_host>` from the primary host to move a whole service group. The helper pauses the watchdog through `watchdown.json`, updates `~/fortisai-dev/watchdog/active_host.json` on every active host, copies mapped runtime directories to the destination host, uses `podman generate kube` and `podman kube play` to recreate the mapped containers or their owning pods on the destination, removes non-portable Podman runtime and health-check annotations plus invalid multi-slash annotation keys from generated manifests, reconciles generated `*-pod` wrappers for bare-container moves, restores stable FortisAI container names after kube play, removes the moved workloads from the source, refreshes CoreDNS, and restores the watchdog to its prior state. When moving CUDA-backed workloads, the helper patches generated kube manifests with a CDI GPU selector when the destination host exposes NVIDIA CDI. If a move fails before completion, the helper rolls the runtime host inventory and watchdog setting back to the pre-move state. Use `app-config` after a successful runtime move or inventory scan to copy the runtime `active_host.json` back into `Development_Environment/linux/active_host.json`, commit it, and push it to Git. Validation on June 22, 2026 confirmed two repeated `traefik` round trips between `aiengine000` and `aiengine001`, including manifest sanitization, stable container rename, Calico attachment, CoreDNS registration, watchdog restoration, and HTTP reachability from both hosts after each move.
- `calico-up` runs `linux/deploy-calico-network.sh` for every host in the runtime `active_host.json`, creates or refreshes the FortisAI Calico/CoreDNS network named `fortisai-calico-net`, starts `fortisai-coredns` at the host subnet `.53` address, configures the Podman network DNS forwarder, installs the user-level Podman DNS registration watcher, and writes `~/fortisai-dev/calico/calico-network.env`. Use `calico-up --test` to run the registration smoke test, `calico-check` to show the selected shared network plus the generated CoreDNS hosts file, and `calico-reconcile` to attach running required-container holdouts to the selected shared network without a full stack restart.
- `fortisai.service` now treats CoreDNS as platform control-plane startup. During service start it runs `fortisai-control.sh cleanup-prestart`, preserving `fortisai-coredns`, then runs `fortisai-control.sh bootstrap-coredns` before the full `all-up` sequence. On the primary host this bootstraps Calico/CoreDNS across the runtime `active_host.json`; on non-primary hosts it bootstraps CoreDNS and exits with `This is not primary system` instead of starting application containers.
- `deploy-calico-network.sh` also publishes shared CoreDNS records and persistent route/sysctl state back to every active host. Local container records live in `~/fortisai-dev/coredns/fortisai.local.hosts`; host-reachable cluster records live in `~/fortisai-dev/coredns/fortisai.cluster.hosts`; CoreDNS serves the merged `~/fortisai-dev/coredns/fortisai.hosts`. On the primary host, `fortisai-calico-sync-dns.timer` runs `deploy-calico-network.sh --sync-dns-only` every minute to redistribute changed service records.
- Watchdog runtime files live in `~/fortisai-dev/watchdog`. `active_host.json` is the active environment setup file used by the helper, Calico/CoreDNS, `podman_monitor.py`, `model_update.py`, and `test_llama_models.py`. `service_map.json` maps a FortisAI service name to all containers and runtime directories that should move together. `watchdown.json` contains `{"activity": true}` by default; set `"activity": false` to pause Podman watchdog checks until the next scheduled cycle, then restore `true` to resume.
- The shared CoreDNS record publish path is strict, but route-service refresh during cluster sync is best-effort. This prevents a non-interactive reboot start from failing CoreDNS bootstrap only because an already-installed route service could not refresh through sudo.
- Before starting containers, the helper verifies whether Calico/CoreDNS is present on that host. If `fortisai-calico-net` or the Calico marker exists, the helper starts CoreDNS and uses `fortisai-calico-net`; otherwise it falls back to the default Podman `fortisai-dev-net`. After shared-stack startup, the helper scans the current host's `required_containers`, attaches any running holdout to the selected shared network, and refreshes CoreDNS registration.
- Rootless Podman bridge networks are host-local. For same-host lookups, CoreDNS returns local container IP records. For cross-host lookups, the shared cluster file advertises only containers with LAN-reachable published ports and resolves those service names to the owning host's LAN IP; for example, a container on `aiengine001` resolves `fortisai-llama-server.fortisai.local` to `192.168.20.77` and reaches the primary llama endpoint through port `8011`. Containers without published host ports are not reachable from peer hosts by container IP; publish a port or move the component assignment in the runtime `active_host.json`.
- Helper-generated runtime configs expose `FORTISAI_VAULT_ADDR`, `VAULT_ADDR`, and the helper-created read-only `VAULT_TOKEN` to services that need local development secrets, including Oracle/ORDS/SQLcl, n8n, OpenWebUI, OpenVSCode, RabbitMQ, pgvector, Firecrawl, Honcho, Dify, Qdrant, OpenClaw, and Hermes.
- On rootless Podman hosts, the helper repairs shifted ownership for Vault config/log directories and Hermes runtime directories before container startup. Hermes data remains owned for the container runtime uid/gid (`HERMES_DATA_UID` / `HERMES_DATA_GID`, default `10000:10000`) after compose files are written so the gateway can update `/opt/data`, logs, and SQLite lock files after restart.
- On aiengine000, rootless Podman depends on persistent `aiuser` limits in `/etc/systemd/system/user@1001.service.d/90-fortisai-limits.conf`, `/etc/systemd/user.conf.d/90-fortisai-limits.conf`, and `/etc/security/limits.d/90-fortisai-aiuser.conf`. These set `TasksMax`, `LimitNPROC`, and `LimitNOFILE` high enough for container execs and compose reconciliation after reboot.
- The Linux helper clears stale `podman healthcheck run` helper processes before readiness checks so a wedged healthcheck cannot pin Podman state locks and block startup.
- Core `up` starts MongoDB and initializes replica set `rs0`, then starts Redis and pgvector before Appsmith. The latest Appsmith backend needs Redis resolution during Spring startup, and starting Appsmith before Redis can leave the UI shell reachable while `/api/v1/*` returns `502`.
- Helper-generated Appsmith compose mounts `/tmp` as container tmpfs to avoid stale overlay state breaking certificate refresh or Caddy socket files after repeated restarts.
- Appsmith compose sets defensive Mongock transaction-disable variables, and MongoDB also raises the transaction lifetime because Appsmith v2.1 may still run long first-run Mongock migrations transactionally.
- MongoDB is started with `transactionLifetimeLimitSeconds=3600` so Appsmith's long first-run Mongock migrations are not aborted by the default 60-second transaction lifetime.
- If Appsmith logs show a MongoDB `IndexOptionsConflict` for `appsmith.passwordResetToken` indexes `createdAt` or `email`, drop only the stale password-reset index named in the error and restart Appsmith; do not remove the Appsmith data volume.
- If Appsmith migration `updateS3DatasourceConfigurationAndLabel` fails because the S3 plugin row is missing, recreate only the `plugin` metadata row for package `amazons3-plugin` with name `Amazon S3` so the migration can rename it to `S3`; do not delete datasource or application records.
- If a later Appsmith migration reports a duplicate `appsmith.config` key for `name: "instance-id"` or `name: "appsmith_registered"`, remove only that partial config row and restart Appsmith so the migration can recreate it cleanly.
- Oracle DB compose grants `SYS_NICE` so the local database can start cleanly under Podman.
- Oracle DB container healthchecks are disabled under rootless Podman; helper SQL and container status checks are the supported validation path.
- For browser access on aiengine000 without Traefik, use direct host ports (for example `http://aiengine000:5678`, `http://aiengine000:3000`, and `http://aiengine000:3300`).
- Helper-generated n8n compose sets `N8N_HOST=aiengine000`, `N8N_PATH=/`, `N8N_SECURE_COOKIE=false`, `N8N_EDITOR_BASE_URL=http://localhost:5678`, `WEBHOOK_URL=http://localhost:5678`, and `N8N_SKIP_AUTH_ON_OAUTH_CALLBACK=true` for direct-port access and local OAuth credential callbacks on Linux hosts.
- Helper-generated OpenWebUI, n8n, and Dify compose configs map `aiengine000` to `host-gateway`, allowing in-container access to the llama router at `http://aiengine000:8011/v1`.
- `llama-router-up` also attaches the primary Llama pod to the selected shared network (`fortisai-calico-net` when present, otherwise `fortisai-dev-net`) with the alias `fortisai-llama-server`. The FortisAI proxy/Dify router path uses the CoreDNS FQDN `http://fortisai-llama-server.fortisai.local:8011/v1` so it continues to work when the llama service is moved to another active host. Hermes and OpenClaw call the FortisAI proxy at `http://fortisai-mcp-openapi-dify.fortisai.local:8093/v1` instead of calling the primary llama router directly.
- Helper-generated Dify and n8n runtimes expose `FORTISAI_LLAMA_SERVER_BASE_URL=http://fortisai-llama-server.fortisai.local:8011/v1` and `FORTISAI_LLAMA_OPENAI_API_KEY=local-llama` so apps and workflows have a stable OpenAI-compatible model endpoint.
  - Helper `write_n8n_compose` now explicitly closes its generated YAML/function block before `write_openwebui_compose` to prevent `openwebui_openai_base_url: unbound variable` failures.
- aiengine runtime path note: n8n service compose file is `~/fortisai-dev/n8n/docker-compose.yml`; after env changes, run `./fortisai-dev-helper.sh n8n-up` and verify with `podman exec fortisai-n8n env | grep -E 'N8N_SECURE_COOKIE|N8N_EDITOR_BASE_URL|WEBHOOK_URL|N8N_SKIP_AUTH_ON_OAUTH_CALLBACK'`.
- Dify keeps its native app redirect (`/dify` -> `/apps`) on direct service access.
- Shared network bootstrap is idempotent. Linux uses `fortisai-calico-net` when the Calico/CoreDNS marker or network exists and falls back to `fortisai-dev-net` otherwise. The Calico/CoreDNS deploy script waits for fresh-container DNS resolution before it reports completion.
- 2026-06-22 validation on `aiengine000` completed a clean helper `all-down` followed by a clean helper `all-up`. `all-down` stopped application containers while leaving `fortisai-coredns` running on both `aiengine000` and `aiengine001`; `all-up` restored all 54 required containers on `aiengine000`, left the required `fortisai-coredns` container running on `aiengine001`, and verified zero required containers missing from `fortisai-calico-net`.
- 2026-06-22 CoreDNS validation confirmed fresh containers on both hosts resolve `fortisai-coredns.fortisai.local`; `aiengine001` resolves `fortisai-llama-server.fortisai.local` to the primary host's LAN-reachable address and can retrieve `/v1/models` from port `8011`. Endpoint checks returned HTTP `200` for Vault, primary llama-server, secondary llama-server, FortisAI proxy, Honcho, and Hermes; Traefik dashboard returned the expected auth challenge HTTP `401`; OpenClaw was running with ports `18789` and `18790` published.
- Firecrawl startup includes DB bootstrap and NUQ schema application.
- MCP bridge bootstrap is available with `./linux/fortisai-dev-helper.sh mcp-up`.
- MCP bridge shutdown is available with `./linux/fortisai-dev-helper.sh mcp-down`.
- `mcp-up` starts SQLcl, n8n, Dify, debug, CodeIndexer, Websearch, Daytona, Composio, OpenMetadata, AOL IMAP, and optional Proxmox OpenAPI bridge containers (`fortisai-mcp-openapi-sqlcl`, `fortisai-mcp-openapi-n8n`, `fortisai-mcp-openapi-dify`, `fortisai-mcp-openapi-debug`, `fortisai-mcp-openapi-codeindexer`, `fortisai-mcp-openapi-websearch`, `fortisai-mcp-openapi-daytona`, `fortisai-mcp-openapi-composio`, `fortisai-mcp-openapi-openmetadata`, `fortisai-mcp-openapi-aol-imap`, `fortisai-mcp-openapi-proxmox`, and the internal `fortisai-mcp-openapi-proxmox-upstream` when Proxmox is enabled).
- `mcp-up` runs Vault preparation first, then injects `FORTISAI_VAULT_ADDR`, `VAULT_ADDR`, and the helper-created read-only `VAULT_TOKEN` into every OpenAPI bridge container.
- `mcp-up` also injects Honcho memory settings into `fortisai-mcp-openapi-dify`. The FortisAI `/v1` facade requires Honcho for chat/completion/responses, looks up memory before routing, and writes the user/assistant exchange back after the selected llama-server model responds.
- `mcp-up` enables the Dify tool execution bridge by default. Direct `/v1/chat/completions` requests that emit OpenAI tool calls, JSON tool-call blocks, XML-style `<tool_call>...` text, or clear tool-backed planning output are mediated through imported OpenWebUI skill/tool-server OpenAPI endpoints before the final model answer. The bridge discovers callable tools from OpenWebUI skills, stores tool metadata in Qdrant for fallback recall, preflights obvious read-only and explicit web requests, and uses CoreDNS FQDNs between bridge containers. Explicit web/current/real-data prompts use Websearch before the generic Qdrant tool-memory fallback, while CodeIndexer GitHub indexing, Dify app listing, and Daytona code execution keep specialized precedence. OpenWebUI-generated Code Interpreter/Pyodide instruction blocks are stripped from the bridge's tool-selection and routing heuristics, so advertised automatic tools do not trigger Daytona or `agentic_tool_use` unless the user actually asks for code execution or forces a tool call.
- `mcp-up` also refreshes the OpenMetadata API token when `openmetadata/admin_email` and `openmetadata/admin_password` are present in Vault, stores the resulting token at `openmetadata/api_token`, and ensures the helper-managed Daytona sandbox `FORTISAI_DAYTONA_DEFAULT_SANDBOX` exists for OpenWebUI code-execution prompts. Dify bridge tool execution and preflight final-answer timeouts default to 300 seconds.
- `mcp-up` starts `fortisai-mcp-openapi-aol-imap` on `http://127.0.0.1:8101/openapi.json` and the CoreDNS FQDN `http://fortisai-mcp-openapi-aol-imap.fortisai.local:8101/openapi.json`. The bridge reads AOL app passwords from `secret/fortisai/dev/aol/imap/*/password` and is used by the `Hourly AOL Spam Filter` n8n workflow for Spam-folder learning plus Inbox-to-Spam moves.
- Non-CodeIndexer bridge health endpoints are hidden from OpenWebUI tool import, while helper smoke checks continue to call runtime health URLs directly.
- Hermes uses `api_mode: anthropic_messages` against `http://fortisai-mcp-openapi-dify.fortisai.local:8093/v1`; the FortisAI bridge accepts `/v1/messages` and the Hermes-generated `/v1/v1/messages` compatibility path, then routes through the same Honcho memory and model-classification flow.
- Hermes bind-mounted runtime state under `~/fortisai-dev/hermes-agent` is prepared for container uid/gid `10000` with `podman unshare` during `hermes-up`, so gateway state, kanban locks, and platform locks remain writable inside `/opt/data`. The helper keeps only the Hermes directory traversal and `docker-compose.yml` host-readable so `hermes-up` and `hermes-down` continue to work after container-side permission repair.
- Linux Honcho defaults to the secondary local llama-server endpoint `http://fortisai-llama-server-secondary.fortisai.local:8012/v1` and `FORTISAI_HONCHO_MODEL=qwen__Qwen_Qwen2.5-1.5B-Instruct-GGUF__qwen2.5-1.5b-instruct-q4_0`; override `FORTISAI_HONCHO_MODEL`, `FORTISAI_HONCHO_WORKSPACE_ID`, or `FORTISAI_HONCHO_REQUIRED` only when intentionally changing proxy memory behavior. FortisAI proxy memory is user-scoped by default with `FORTISAI_HONCHO_SESSION_SCOPE=user`, so every chat from the same user shares the same Honcho session. Set `FORTISAI_HONCHO_SESSION_SCOPE=conversation` only when per-chat isolation is required.
- Honcho message embeddings are enabled by default through `HONCHO_EMBED_MESSAGES=true`. The helper configures Honcho's OpenAI embedding client to use the secondary llama `/v1/embeddings` endpoint, the same lightweight Qwen support model, and 1536-dimensional pgvector storage in the `message_embeddings` table.
- Use `./linux/fortisai-dev-helper.sh honcho-up` to regenerate Honcho `.env`, ensure Redis/pgvector dependencies are present, and restart only the Honcho API/deriver services after changing Honcho model or embedding settings.
- Composio and OpenMetadata MCP bridges are imported into OpenWebUI by `mcp-up` when OpenWebUI is available. Composio runs a local proxy container named `fortisai-composio-local` and the OpenAPI bridge points to it by CoreDNS FQDN. Live SaaS execution still requires `secret/fortisai/dev/composio/api_key` for SDK-created sessions, or `secret/fortisai/dev/composio/upstream_mcp_url` plus optional headers for a pre-created session. OpenMetadata read-only checks work against the local OpenMetadata runtime; source creation and ingestion pipeline actions require `secret/fortisai/dev/openmetadata/api_token`.
- CodeIndexer GitHub repository support is available through the CodeIndexer bridge and the OpenWebUI GitHub skill. It stores clones in the helper-managed bridge volume at `/codeindexer-github`, supports optional GitHub token and allowlist settings, and passes private-repo tokens as transient Git request headers.
- The packaged n8n workflow `Development_Environment/mcp/n8n-mcp/workflows/openmetadata-daily-db-catalog-update.json` runs daily at 05:00 UTC and calls the OpenMetadata bridge by CoreDNS FQDN to trigger/status TradeEngine MongoDB and InfluxDB catalog ingestion.
- `mcp-up` starts `fortisai-mcp-openapi-proxmox` when Proxmox config is detected (`Development_Environment/mcp/proxmox/proxmox-config.json`), Proxmox env vars are set, or Proxmox values already exist in Vault.
- Proxmox bridge values are synced under `secret/fortisai/dev/proxmox/*`; `Development_Environment/mcp/proxmox/proxmox-config.json` is treated as a local seed file and is ignored by Git.
- Linux runs the `LesterAJohn/ProxmoxMCP-Plus` fork behind a FortisAI local facade: `fortisai-mcp-openapi-proxmox-upstream` keeps the bearer-protected service internal, while `fortisai-mcp-openapi-proxmox` exposes `http://127.0.0.1:8095/openapi.json` and `http://fortisai-mcp-openapi-proxmox.fortisai.local:8095/openapi.json` for local curl/OpenWebUI use. The helper builds the fork into `localhost/fortisai-proxmoxmcp-plus:latest` when the image is missing, using `PROXMOX_UPSTREAM_BUILD_REPO` and `PROXMOX_UPSTREAM_BUILD_REF`. The facade includes read-only `/get_vm_statistics` and `/get_container_statistics`, authenticated `/create_vm_disk`, VM/LXC resource updates, and update-key protection for all proxied lifecycle/change actions.
- Proxmox runtime cluster selection is supported on every bridge endpoint. Use `environment` or `proxmox_environment` in JSON bodies, `environment` in query strings, or `X-FortisAI-Proxmox-Environment` as a header. When omitted, the bridge uses `default_environment` from `Development_Environment/mcp/proxmox/proxmox-config.json` or `PROXMOX_DEFAULT_ENVIRONMENT`.
- `mcp-up` auto-loads `N8N_API_KEY` from env, Vault, or `~/fortisai-dev/sqlcl-mcp/mcp.json` (`mcpServers.fortisai-n8n.env.N8N_API_KEY`).
- `mcp-up` can also load native n8n MCP endpoint values from Vault (`n8n/mcp_server_url`, `n8n/mcp_server_bearer_token`) and passes them to the n8n OpenAPI bridge for `/n8n_mcp_*` passthrough routes.
- The Websearch bridge exposes Firecrawl-backed search at `http://127.0.0.1:8097/openapi.json` and `http://fortisai-mcp-openapi-websearch.fortisai.local:8097/openapi.json`; its OpenWebUI payloads live under `Development_Environment/mcp/websearch-mcp/`, and `Development_Environment/mcp/daytona-mcp/`.
- `mcp-up` validates: OpenAPI endpoints, debug bridge status smoke, SQL query smoke (`select 1 as ok from dual`), n8n workflow-list smoke, CodeIndexer connection info, Websearch connection/search checks, Daytona connection-info checks, optional Proxmox `/livez`, and Dify API container reachability when `docker_api_1` is running.
- SQL bridge smoke is auto-skipped (warning-only) when Oracle DB backend host resolution/connectivity is unavailable in the current environment.
- n8n workflow-list smoke is auto-skipped (warning-only) when n8n backend auth/connectivity is unavailable in the current environment.
- Dify API in-container bridge reachability smoke is auto-skipped (warning-only) when backend auth/connectivity is unavailable in the current environment.
- Dify API in-container bridge reachability smoke is also warning-only when Podman cannot run the probe because of container `exec` runtime limits such as `RLIMIT_NPROC`; host-side OpenAPI bridge checks still remain required.
- Debug bridge OpenAPI/status smoke checks are auto-skipped (warning-only) when debug backend connectivity is unavailable in the current environment.
- `mcp-up` auto-resolves Dify console admin routing context (`ADMIN_API_KEY` and `X-WORKSPACE-ID`) from running Dify/pgvector services when not explicitly set.
- `mcp-down` stops and removes bridge containers `fortisai-mcp-openapi-sqlcl`, `fortisai-mcp-openapi-n8n`, `fortisai-mcp-openapi-dify`, `fortisai-mcp-openapi-debug`, `fortisai-mcp-openapi-codeindexer`, `fortisai-mcp-openapi-websearch`, `fortisai-mcp-openapi-daytona`, and `fortisai-mcp-openapi-proxmox`.
- OpenWebUI OpenAPI templates now include MCP bridges (`mcp-sqlcl-server`, `mcp-n8n-server`, `mcp-dify-server`, `mcp-codeindexer-server`, `mcp-websearch-server`, `mcp-daytona-server`, `mcp-proxmox-server`) in addition to repo filesystem/memory/time. Helper-generated OpenWebUI startup sets an unlimited upstream client timeout and SQLite WAL/busy-timeout pragmas so longer tool-mediated responses are less likely to be interrupted by timeout or transient database lock failures.
- OpenWebUI API keys are stored per user in Vault with `./linux/fortisai-dev-helper.sh openwebui-api <user email> <api key>`, under `secret/fortisai/dev/openwebui/users/<normalized-user>/api_key`. During `mcp-up`, the Dify/FortisAI bridge resolves the current OpenWebUI user from request headers or OpenAI user metadata, uses that key to call `GET /api/v1/skills/export`, and discovers callable MCP/OpenAPI tools from installed skill text.
- Helper `up` imports OpenWebUI tool connections and skills for `repo-filesystem-server`, `repo-memory-server`, and `repo-time-server` after the repo OpenAPI servers are healthy. Payloads live under `Development_Environment/mcp/repo-openapi/` and use `host.containers.internal` so the OpenWebUI container can reach the host-exposed repo server ports.
- `mcp-up` reloads the CodeIndexer, Websearch, and Daytona OpenWebUI tool connections and attempts to import those skill payloads. Manual import payloads live under `Development_Environment/mcp/codeindexer-mcp/`, `Development_Environment/mcp/websearch-mcp/`, and `Development_Environment/mcp/daytona-mcp/`.
- OpenWebUI tool/skill reload during `mcp-up` is warning-only when the OpenWebUI container or its `podman exec` path is unavailable; bridge startup and host-side OpenAPI validation still complete, and payloads can be reloaded later.
- Refresh OpenWebUI OpenAPI templates with `./linux/fortisai-dev-helper.sh setup`, then run `./linux/fortisai-dev-helper.sh mcp-up` before OpenWebUI tool import.
- Primary llama router mode is managed with `llama-router-up` / `llama-router-switch` / `llama-router-down`.
- Secondary llama router mode is managed with `llama-secondary-up` / `llama-secondary-switch` / `llama-secondary-down`.
- The primary llama router mounts `LLAMA_MODELS_DIR` (default `/db/AI/llm_directory` on Linux when present, otherwise `Development_Environment/llm_directory`) and exposes the FortisAI proxy backend on `LLAMA_SERVER_URL` (default `http://127.0.0.1:8011`).
- The secondary llama router uses the same `LLAMA_MODELS_DIR`, defaults its active hint to `qwen/Qwen_Qwen2.5-1.5B-Instruct-GGUF/qwen2.5-1.5b-instruct-q4_0.gguf`, and exposes direct support-tool LLM access on `LLAMA_SECONDARY_SERVER_URL` (default `http://127.0.0.1:8012`).
- The primary router uses the CoreDNS endpoint `http://fortisai-llama-server.fortisai.local:8011/v1`; the secondary router uses `http://fortisai-llama-server-secondary.fortisai.local:8012/v1`.
- Both Linux llama routers mount `LLAMA_MODELS_DIR` directly; on `aiengine000` this is `/db/AI/llm_directory`. The helper generates `LLAMA_ROUTER_MODELS_PRESET_FILE` (`~/fortisai-dev/llama-router/models.ini`) with direct paths to every runnable `*.gguf` under that directory and starts llama-server with `--models-preset`; the retired `~/fortisai-dev/llama-router/model-catalog` symlink directory is not used. Split GGUF sets are represented only by shard `00001`; later `00002+` shards remain on disk for llama.cpp to read but are not exposed as standalone `/v1/models` entries.
- Default primary llama-server runtime args include `--parallel 8`, `--models-max 2`, `--batch-size 768`, `--ubatch-size 768`, `--cache-ram 0`, `--no-cache-idle-slots`, `--reasoning auto`, `--reasoning-budget 512`, `--embeddings`, and `--pooling mean` through `LLAMA_SERVER_EXTRA_ARGS`. The primary prompt-cache RAM path is disabled by default because SWA/hybrid routed models were saving and evicting prompt checkpoints, then forcing full prompt reprocessing. Primary reasoning is limited by default so OpenWebUI can receive concise reasoning-aware answers or tool calls without long exposed thinking/planning traces. The secondary llama-server defaults to the same router behavior except `LLAMA_SECONDARY_SERVER_EXTRA_ARGS` also uses `--parallel 8`, `--models-max 2`, `--ctx-size 8192`, `--batch-size 4096`, and `--ubatch-size 4096`; this gives each loaded support model up to eight active slots while allowing two models to remain warm.
- Monthly model validation starts by restoring existing `.gguf.disable...` files by default through `LLAMA_RESTORE_DISABLED_BEFORE_TESTS=true`, then refreshes llama-server so previously disabled normal models and split sets can be tested again. Models that still fail to answer within `LLAMA_TEST_TIMEOUT_SECONDS` (default 300 seconds) are disabled again by default through `LLAMA_DISABLE_TIMEOUTS=true`, renamed with a `.disable...` suffix, recorded in `LLAMA_DISABLED_MODELS_FILE` or `llm_directory/disabled_models.json`, and excluded by both the restarted llama router and the Dify/n8n classifier. Split GGUF validation tests only shard `00001`: if shard `00001` fails, the whole split set is disabled; if shard `00001` passes, later shards stay enabled on disk and are skipped as separate test targets.
- Honcho message embeddings default to `HONCHO_EMBEDDING_MAX_INPUT_TOKENS=2048`. The secondary llama-server uses a 4096-token physical batch so support-tool embeddings and RAG web-result chunks above 2048 tokens can be handled without the local Qwen support model rejecting them for batch-size overflow.
- The Linux primary llama-server container has a default Podman memory cap of `28g` via `LLAMA_SERVER_MEMORY_LIMIT`; the secondary defaults to the same cap through `LLAMA_SECONDARY_SERVER_MEMORY_LIMIT`. Swap limits default to the same values so swap does not expand the containers beyond that envelope.
- Model selection is request-driven through the OpenAI-compatible `model` field using IDs returned by `/v1/models`.
- FortisAI proxy/Dify routing uses the primary llama router only. Hermes and OpenClaw default to the FortisAI proxy endpoint `http://fortisai-mcp-openapi-dify.fortisai.local:8093/v1` with model `fortisai`. Honcho and CodeIndexer default to the secondary llama router for direct LLM or embedding access; their default support model is the lightweight Qwen 1.5B Q4 model to avoid loading the 24B router/classifier model on the secondary.
- Hermes is configured as a custom FortisAI provider, not OpenRouter. The helper writes `~/fortisai-dev/hermes-agent/config.yaml` with `provider: custom`, `default: fortisai`, `base_url: http://fortisai-mcp-openapi-dify.fortisai.local:8093/v1`, and `api_mode: anthropic_messages`; it also clears OpenRouter env values and does not export generic `OPENAI_API_KEY` into the Hermes container, because Hermes treats that variable as an OpenRouter auto-provider hint. WhatsApp gateway startup is disabled by default with `HERMES_WHATSAPP_ENABLED=false` / `WHATSAPP_ENABLED=false`; `hermes-up` also rewrites the persisted Hermes `.env` to keep old paired WhatsApp sessions ignored unless `HERMES_WHATSAPP_ENABLED=true` is set intentionally.
- Core `up` / `down` manage the shared FortisAI stack only; standalone llama routers remain under `llama-router-*` and `llama-secondary-*`. Full `all-up` / `all-down` starts and stops both routers around the shared stack.
- Core startup now waits out or force-clears a stale Podman `Removing` container before reusing a compose-managed service name on the next `up` run.
- Core shutdown now uses timeout-guarded compose teardown (including OpenWebUI/OpenVSCode paths) so `down` continues even if a compose provider call stalls.
- `hermes-up` performs first-deploy bootstrap inside the Hermes venv and auto-installs `PyYAML` if missing. It also repairs `/opt/data` ownership for the container `hermes` user (`10000:10000`) so `config.yaml`, `auth.json`, gateway state, and session files remain readable after restarts.
- `daytona-up` waits for `daytona_proxy_1` health and performs one automatic proxy restart if health does not converge.
- Daytona no longer starts duplicate local PostgreSQL, Redis, or pgAdmin services in the FortisAI runtime compose. `daytona-up` starts shared `fortisai-redis` and `fortisai-pgvector`, creates the dedicated `daytona` database if needed, and wires the Daytona API/proxy to those shared services on the shared FortisAI container network using CoreDNS FQDNs such as `fortisai-pgvector.fortisai.local` and `fortisai-redis.fortisai.local`.
- The helper rewrites Daytona internal URLs to stable hyphenated network aliases such as `daytona-api`, `daytona-runner`, `daytona-minio`, and `daytona-registry` to avoid stale generic Podman DNS aliases after restarts and keep S3 hostnames valid.
- The Linux podman monitor reads `required_containers` from `~/fortisai-dev/watchdog/active_host.json`; Daytona entries should include only Daytona-owned containers because shared `fortisai-redis` and `fortisai-pgvector` cover Daytona's Redis/PostgreSQL requirements.
- Under Podman fallback, `daytona-up` stages Daytona-owned services with minio first, then reconciles api/proxy startup for more reliable initial bring-up.
- Daytona telemetry is disabled in the helper-generated local runtime unless an OTEL collector is explicitly added. Daytona API, proxy, dex, and runner container healthchecks are also disabled under rootless Podman; `daytona-up` validates the API and proxy through HTTP health checks instead.
- `daytona-up` and `mcp-up` create the Vault-backed `fortisai-openwebui-daytona` API key when it is missing and store `DAYTONA_API_KEY` plus `DAYTONA_ORG_ID` under `secret/fortisai/dev/daytona/`. They also raise zeroed local organization and region sandbox quotas, adapt the helper-managed `fortisai-ubuntu-22.04` default snapshot to CPU or GPU-only runners, and wait for that snapshot to become active for bridge-created sandboxes.
- `daytona-sandbox-smoke` performs an authenticated create/get/delete sandbox lifecycle test to validate Daytona runtime operations end-to-end.
- `daytona-up` auto-enables NVIDIA GPUs when `nvidia-smi`, `/dev/nvidiactl`, and required NVIDIA driver libraries are present. The helper writes `docker/fortisai-nvidia`, `docker/nvidia-cdi.yaml`, runner `GPU_ENABLED=true`, and `DEFAULT_SNAPSHOT=daytonaio/sandbox-gpu:latest` into the generated Daytona runtime compose.
- `daytona-gpu-check` validates host GPU detection, runner `nvidia-smi`, and nested Docker CDI pass-through with `--device nvidia.com/gpu=0`.

## Llama Router Quick Test

```bash
./linux/fortisai-dev-helper.sh llama-router-up
curl -s http://127.0.0.1:8011/v1/models | jq -r '.data[].id'

./linux/fortisai-dev-helper.sh llama-secondary-up
curl -s http://127.0.0.1:8012/v1/models | jq -r '.data[].id'

curl -s http://127.0.0.1:8011/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "claude__Negentropy-claude-opus-4.7-9B-Q4_K_M",
    "messages": [{"role":"user","content":"Hello from FortisAI router"}],
    "max_tokens": 64
  }'
```

## Llama Model Smoke Test

Run the per-model smoke test against the live router after startup:

```bash
./linux/test-llama-models.sh
```

The script enumerates `/v1/models`, verifies the running llama container has NVIDIA device nodes mapped in, and sends one chat-completion request to each model ID it finds.

For canonical URLs and default credentials, see [../development_env_url.md](../development_env_url.md).

## aiengine000 Repo Bootstrap

Run this script as `aiuser` on aiengine000 to link `/opt/home/aiuser/FortisAI` to the FortisAI git repository and keep host-local symlink paths ignored by git:

```bash
bash Development_Environment/linux/setup-aiuser-fortisai-repo.sh <git_repo_url>
```

Example:

```bash
bash Development_Environment/linux/setup-aiuser-fortisai-repo.sh git@github.com:LesterAJohn/FortisAI.git
```

## Service Endpoint Validation (aiengine000)

Use this smoke check to verify direct service endpoints on the host ports used by the Linux helper.

```bash
python3 - <<'PY'
import subprocess
endpoints=[
  ('n8n','http://127.0.0.1:5678/'),
  ('dify','http://127.0.0.1:18081/'),
  ('openwebui','http://127.0.0.1:3000/'),
  ('openvscode','http://127.0.0.1:13000/'),
  ('appsmith','http://127.0.0.1:18080/'),
  ('ords','http://127.0.0.1:8181/ords/'),
  ('vault-health','http://127.0.0.1:8200/v1/sys/health'),
]
for name, url in endpoints:
  cmd=['curl','-sS','-o','/tmp/fortisai-service-body.bin','-w','%{http_code}',url]
  p=subprocess.run(cmd,text=True,capture_output=True,check=False)
  code=p.stdout.strip() or '000'
  print(f"{name}: {url} -> HTTP {code}")
PY
```

Validation guidance:

- Core endpoints should return HTTP `200` or an app-specific redirect/login response (`30x`/`401`) depending on service state.
- Vault health should return `200`, `429`, `472`, or `473` after initialization depending on seal/standby state. Before first-time initialization it returns `501`; while sealed it returns `503`.
- The 2026-06-21 multi-host Calico/CoreDNS validation ran `linux/deploy-calico-network.sh --no-test` from `aiengine000` across `aiengine000` and `aiengine001`. Fresh containers on both hosts resolved `fortisai-llama-server.fortisai.local`; `aiengine001` reached `http://fortisai-llama-server.fortisai.local:8011/v1/models` through the shared CoreDNS host-reachable record. Variable `*-infra` containers remain excluded from the required set.
- The 2026-06-22 FQDN refresh validated OpenWebUI, Honcho, the Dify OpenAPI bridge, Oracle Node API, Dify runtime `.env`, and repo OpenWebUI tool imports against `*.fortisai.local` service names. The bridge resolved primary/secondary llama, Honcho, Qdrant, and Firecrawl through CoreDNS, and the FortisAI Dify OpenAPI facade returned HTTP `200` from `/v1/models`.
