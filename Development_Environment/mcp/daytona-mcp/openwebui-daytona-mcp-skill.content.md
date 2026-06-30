# FortisAI Daytona Skill

Use this skill when OpenWebUI needs to manage Daytona sandboxes or run a command inside an already-created Daytona sandbox.

Required OpenWebUI tool server:
- `mcp-daytona-server`

Scope:
- Check Daytona API/proxy health.
- List, inspect, create, and delete Daytona sandboxes through the FortisAI Daytona API.
- Execute shell commands inside a Daytona sandbox through the toolbox proxy.

Execution guide:
1. Use `/daytona_connection_info` for diagnostics and to confirm the bridge has a Daytona API key.
2. Use `/daytona_list_sandboxes` before command execution when the sandbox id or name is unknown.
3. Use `/daytona_get_sandbox` to confirm state before running commands. If no snapshot is supplied when creating a sandbox, the bridge uses the helper-managed `fortisai-ubuntu-22.04` snapshot.
4. Use `/daytona_execute_command` only for commands intended to run inside the selected Daytona sandbox. If the named sandbox is missing, the bridge creates it with the helper-managed snapshot and waits for it to start before executing. Do not present it as host-shell execution.
5. Keep command timeouts explicit for long-running work; the bridge allows up to 1800 seconds.
6. Return the sandbox id, exit code, and concise output summary. Include the full output only when the user asks for it or it is short.
7. Do not expose API keys, Vault tokens, container environment values, or bearer headers.

Endpoint guide:
- `GET /daytona_connection_info`
- `POST /daytona_list_sandboxes`
- `POST /daytona_get_sandbox`
- `POST /daytona_create_sandbox`
- `POST /daytona_delete_sandbox`
- `POST /daytona_get_toolbox_proxy`
- `POST /daytona_execute_command`

Recommended request shapes:
```json
{"limit":10,"states":["STARTED"]}
```
```json
{"sandbox_id_or_name":"fortisai-smoke","command":"pwd && python3 --version","cwd":"/home/daytona/project","timeout_seconds":30}
```
```json
{"name":"fortisai-openwebui-smoke","target":"us","autoDeleteInterval":0,"labels":{"source":"openwebui"}}
```
