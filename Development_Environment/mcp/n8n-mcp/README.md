# n8n MCP Bridge

This directory contains a local MCP server that lets an LLM manage n8n through the n8n API.

## Server

- Script: `n8n-mcp-server.py`
- Protocol: MCP over stdio
- Default base URL: `http://127.0.0.1:5678`

## Provided Tools

- `n8n_connection_info`
- `n8n_health`
- `n8n_api_request`
- `n8n_list_workflows`
- `n8n_get_workflow`
- `n8n_create_workflow`
- `n8n_update_workflow`
- `n8n_set_workflow_active`

## Authentication

Workflow management endpoints use n8n public API routes (`/api/v1/...`) and require an API key.

1. Open n8n UI.
2. Create an API key in n8n API settings.
3. Set `N8N_API_KEY` in MCP config.

Basic auth values are included for compatibility with deployments that still enforce basic auth at the HTTP layer, but API key is the primary auth for workflow operations.

## MCP Configuration

The existing MCP config at `~/fortisai-dev/sqlcl-mcp/mcp.json` now includes a `fortisai-n8n` server entry.

Environment values used by the n8n MCP server:

- `N8N_BASE_URL` (default `http://127.0.0.1:5678`)
- `N8N_API_KEY` (required for `/api/v1` workflow tools)
- `N8N_BASIC_AUTH_USER` (optional)
- `N8N_BASIC_AUTH_PASSWORD` (optional)
- `N8N_VERIFY_TLS` (default `true`)
- `N8N_TIMEOUT_SECONDS` (default `30`)

Additional values used by the n8n OpenAPI bridge for native n8n MCP endpoint access:

- `N8N_MCP_URL` (default `${N8N_BASE_URL}/mcp-server/http`)
- `N8N_MCP_BEARER_TOKEN` (required for `/n8n_mcp_*` bridge routes)

If `N8N_MCP_URL` is set to `localhost` or `127.0.0.1`, the bridge auto-normalizes it to the host from `N8N_BASE_URL` so containerized bridge calls route to n8n correctly.

Bridge routes for native MCP passthrough:

- `GET /n8n_mcp_connection_info`
- `POST /n8n_mcp_initialize`
- `POST /n8n_mcp_request`
- `POST /n8n_mcp_list_tools` (auto-initializes session when needed)
- `POST /n8n_mcp_call_tool` (auto-initializes session when needed)

These routes expose native n8n MCP tool discovery and tool execution, which allows newly created n8n workflows to become callable through MCP without bridge code changes.

Linux helper `mcp-up` resolves these from Vault when available:

- `secret/fortisai/dev/n8n/mcp_server_url`
- `secret/fortisai/dev/n8n/mcp_server_bearer_token`

## Packaged Workflows

- `workflows/openmetadata-daily-db-catalog-update.json` - daily 05:00 UTC workflow that calls the OpenMetadata bridge to trigger and check TradeEngine MongoDB and InfluxDB ingestion pipelines. It uses CoreDNS FQDN `fortisai-mcp-openapi-openmetadata.fortisai.local` so it continues to work across the FortisAI Calico network.

The workflow can be imported with the n8n bridge and activated after import. It expects the OpenMetadata ingestion pipelines to exist; creating those pipelines requires the OpenMetadata API token in Vault.
