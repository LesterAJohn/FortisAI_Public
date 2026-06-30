# FortisAI Composio MCP Bridge

This directory contains the FortisAI OpenAPI bridge and OpenWebUI assets for Composio SaaS connector access.

The bridge exposes a restricted Composio session/tool execution surface through the existing FortisAI MCP bridge lifecycle. Use it for external SaaS applications that are not already covered by FortisAI-native MCP/OpenAPI bridges. Existing local integrations remain authoritative; the bridge blocks overlapping toolkit prefixes for Firecrawl, Daytona, SQLcl, n8n, Dify, CodeIndexer, Proxmox, and OpenMetadata.

## Runtime

- Local Composio MCP proxy container: `fortisai-composio-local`
- Local MCP proxy endpoint: `http://127.0.0.1:18190/mcp` on the host and `http://fortisai-composio-local.fortisai.local:8090/mcp` inside the FortisAI network
- FortisAI OpenAPI bridge container: `fortisai-mcp-openapi-composio`
- OpenAPI: `http://127.0.0.1:8099/openapi.json`
- Connection info: `http://127.0.0.1:8099/composio_connection_info`

## Configuration

The helper injects Vault access into the bridge. Configure these paths under `secret/fortisai/dev/` before expecting live Composio execution:

- `composio/api_key` (optional; not required when the local Composio SDK/container is already authenticated with `composio login` or equivalent local config)
- `composio/mcp_url` (defaults to the local proxy `http://fortisai-composio-local.fortisai.local:8090/mcp`)
- `composio/upstream_mcp_url` (optional hosted/session MCP URL for the local proxy to forward to)
- `composio/mcp_headers_json` (optional upstream MCP headers)
- `composio/user_id` (optional session user id; default `fortisai-openwebui`)
- `composio/toolkits` (optional comma-separated toolkit restriction)

The connection-info endpoint reports whether the API key and MCP URL are present without returning their values.

## OpenWebUI Assets

- `openwebui-composio-mcp-tools.import.json`
- `openwebui-composio-mcp-skill.create.json`
- `openwebui-composio-mcp-skill.content.md`

Helper `mcp-up` imports the tool connection and skill when OpenWebUI is available.

When no upstream MCP URL is supplied, the local proxy tries to create a Composio session with MCP enabled by using the local Composio SDK. A Vault `composio/api_key` is optional; the SDK can also use local authentication created by `composio login` or equivalent local Composio config. This keeps FortisAI pointed at a stable local pod while still supporting Composio's session-scoped MCP model.

## OpenWebUI user sessions

The FortisAI Composio bridge forwards the current OpenWebUI user identity to the local MCP proxy using `openwebui_user_id` request fields or OpenWebUI user headers. The local proxy creates or reuses a Composio MCP session per user with:

```python
from composio import Composio

composio = Composio()
session = composio.create(user_id=openwebui_user_id, mcp=True)
mcp_url = session.mcp.url
mcp_headers = session.mcp.headers
```

The proxy caches `mcp_url` and `mcp_headers` by OpenWebUI user id and forwards MCP JSON-RPC calls to that user-scoped session. Tool calls should include `openwebui_user_id` whenever OpenWebUI does not inject user headers automatically.
