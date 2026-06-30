# FortisAI CodeIndexer MCP Bridge

This directory contains the FortisAI OpenAPI bridge and OpenWebUI import assets for the `Indiejayk8s/CodeIndexer` MCP server.

The bridge exposes CodeIndexer's stdio MCP tools as HTTP/OpenAPI endpoints:

- `GET /healthz`
- `GET /openapi.json`
- `GET /codeindexer_connection_info`
- `GET /codeindexer_tools`
- `POST /codeindexer_index`
- `POST /codeindexer_search`
- `POST /codeindexer_clear`
- `POST /codeindexer_mcp_tool`
- `POST /codeindexer_clone_github_repository`
- `POST /codeindexer_pull_github_repository`
- `POST /codeindexer_index_github_repository`
- `POST /codeindexer_search_github_repository`
- `GET /codeindexer_list_github_repositories`

Linux helper `codeindexer-up` starts Milvus, clones/builds CodeIndexer, and configures it to use the FortisAI OpenAI-compatible embedding endpoint. Helper `mcp-up` starts `fortisai-mcp-openapi-codeindexer` on port `8096`, reloads the OpenWebUI tool connection, and attempts to import the CodeIndexer skill payload when OpenWebUI is running.

GitHub repository indexing uses a helper-managed cache volume mounted at `/codeindexer-github`. Set `CODEINDEXER_GITHUB_TOKEN` only when private repository access is required. Optional allowlists `CODEINDEXER_GITHUB_ALLOWED_HOSTS` and `CODEINDEXER_GITHUB_ALLOWED_ORGS` restrict clone/pull targets. Tokens are passed to Git as transient request headers rather than written into remote URLs.

OpenWebUI assets:

- `openwebui-codeindexer-mcp-tools.import.json`
- `openwebui-codeindexer-mcp-skill.create.json`
- `openwebui-codeindexer-mcp-skill.content.md`
- `openwebui-codeindexer-github-mcp-skill.create.json`
- `openwebui-codeindexer-github-mcp-skill.content.md`

Reload them with the shared MCP helper scripts after `mcp-up`:

```bash
bash Development_Environment/mcp/reload-openwebui-tool-connection.sh \
  Development_Environment/mcp/codeindexer-mcp/openwebui-codeindexer-mcp-tools.import.json

bash Development_Environment/mcp/create-openwebui-skill.sh \
  Development_Environment/mcp/codeindexer-mcp/openwebui-codeindexer-mcp-skill.create.json

bash Development_Environment/mcp/create-openwebui-skill.sh \
  Development_Environment/mcp/codeindexer-mcp/openwebui-codeindexer-github-mcp-skill.create.json
```
