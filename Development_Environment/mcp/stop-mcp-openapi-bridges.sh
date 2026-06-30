#!/usr/bin/env bash
set -euo pipefail

SQLCL_BRIDGE_CONTAINER="${SQLCL_BRIDGE_CONTAINER:-fortisai-mcp-openapi-sqlcl}"
N8N_BRIDGE_CONTAINER="${N8N_BRIDGE_CONTAINER:-fortisai-mcp-openapi-n8n}"
DIFY_BRIDGE_CONTAINER="${DIFY_BRIDGE_CONTAINER:-fortisai-mcp-openapi-dify}"
DEBUG_BRIDGE_CONTAINER="${DEBUG_BRIDGE_CONTAINER:-fortisai-mcp-openapi-debug}"
CODEINDEXER_BRIDGE_CONTAINER="${CODEINDEXER_BRIDGE_CONTAINER:-fortisai-mcp-openapi-codeindexer}"
WEBSEARCH_BRIDGE_CONTAINER="${WEBSEARCH_BRIDGE_CONTAINER:-fortisai-mcp-openapi-websearch}"
DAYTONA_BRIDGE_CONTAINER="${DAYTONA_BRIDGE_CONTAINER:-fortisai-mcp-openapi-daytona}"
COMPOSIO_LOCAL_CONTAINER="${COMPOSIO_LOCAL_CONTAINER:-fortisai-composio-local}"
COMPOSIO_BRIDGE_CONTAINER="${COMPOSIO_BRIDGE_CONTAINER:-fortisai-mcp-openapi-composio}"
OPENMETADATA_BRIDGE_CONTAINER="${OPENMETADATA_BRIDGE_CONTAINER:-fortisai-mcp-openapi-openmetadata}"
AOL_IMAP_BRIDGE_CONTAINER="${AOL_IMAP_BRIDGE_CONTAINER:-fortisai-mcp-openapi-aol-imap}"
PROXMOX_BRIDGE_CONTAINER="${PROXMOX_BRIDGE_CONTAINER:-fortisai-mcp-openapi-proxmox}"
PROXMOX_UPSTREAM_CONTAINER="${PROXMOX_UPSTREAM_CONTAINER:-${PROXMOX_BRIDGE_CONTAINER}-upstream}"

stop_container() {
  local name="$1"
  if podman container exists "$name" >/dev/null 2>&1; then
    podman rm -f "$name" >/dev/null 2>&1 || true
    echo "Stopped $name"
  else
    echo "Skipped $name (not found)"
  fi
}

stop_container "$SQLCL_BRIDGE_CONTAINER"
stop_container "$N8N_BRIDGE_CONTAINER"
stop_container "$DIFY_BRIDGE_CONTAINER"
stop_container "$DEBUG_BRIDGE_CONTAINER"
stop_container "$CODEINDEXER_BRIDGE_CONTAINER"
stop_container "$WEBSEARCH_BRIDGE_CONTAINER"
stop_container "$DAYTONA_BRIDGE_CONTAINER"
stop_container "$COMPOSIO_BRIDGE_CONTAINER"
stop_container "$COMPOSIO_LOCAL_CONTAINER"
stop_container "$OPENMETADATA_BRIDGE_CONTAINER"
stop_container "$AOL_IMAP_BRIDGE_CONTAINER"
stop_container "$PROXMOX_BRIDGE_CONTAINER"
stop_container "$PROXMOX_UPSTREAM_CONTAINER"

echo "MCP OpenAPI bridges stopped."
