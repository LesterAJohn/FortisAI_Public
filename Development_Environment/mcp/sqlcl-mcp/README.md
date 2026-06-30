# SQLcl MCP Bridge

This directory contains Oracle SQLcl MCP and OpenAPI bridge assets for FortisAI.

## Server

- MCP server: `sqlcl-mcp-server.py`
- OpenAPI bridge: `sqlcl-openapi-bridge.py`

## OpenWebUI Assets

- Tool import payload: `openwebui-sqlcl-mcp-tools.import.json`
- Skill payload: `openwebui-sqlcl-mcp-skill.create.json`

## OpenWebUI Tool + Skill Reload

When OpenWebUI MCP payloads change, use the MCP helper scripts:

```bash
# Global reload (all MCP components under Development_Environment/mcp)
bash Development_Environment/mcp/reload-openwebui-tool-connection.sh
bash Development_Environment/mcp/create-openwebui-skill.sh

# Optional: SQLcl-only reload
bash Development_Environment/mcp/reload-openwebui-tool-connection.sh \
	Development_Environment/mcp/sqlcl-mcp/openwebui-sqlcl-mcp-tools.import.json
bash Development_Environment/mcp/create-openwebui-skill.sh \
	Development_Environment/mcp/sqlcl-mcp/openwebui-sqlcl-mcp-skill.create.json
```

## Runtime Notes

- SQLcl MCP/OpenAPI assets are started by helper-managed MCP bridge lifecycle (`mcp-up` / `mcp-down`).
- Keep Oracle credentials and runtime keys out of docs, logs, and screenshots.
