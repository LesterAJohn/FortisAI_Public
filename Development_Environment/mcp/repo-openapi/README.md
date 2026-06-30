# FortisAI Repo OpenAPI Tools

This directory contains OpenWebUI tool import and skill payloads for the local repo OpenAPI server trio started by the Linux helper:

- `repo_filesystem-server_1` on port `8081`
- `repo_memory-server_1` on port `8082`
- `repo_time-server_1` on port `8083`

OpenWebUI runs in a container, so helper imports rewrite payload endpoints for the active network mode. With CoreDNS active they use `*.fortisai.local` names such as `http://filesystem-server.fortisai.local:8000`; without CoreDNS they use short service names such as `http://filesystem-server:8000`.

## OpenWebUI Reload

The Linux helper imports these payloads automatically after `up` starts OpenWebUI and the repo OpenAPI servers.

Manual reload:

```bash
bash Development_Environment/mcp/reload-openwebui-tool-connection.sh \
  Development_Environment/mcp/repo-openapi/openwebui-repo-filesystem-tools.import.json
bash Development_Environment/mcp/create-openwebui-skill.sh \
  Development_Environment/mcp/repo-openapi/openwebui-repo-filesystem-skill.create.json
```

Repeat with the memory and time payloads when testing manually.
