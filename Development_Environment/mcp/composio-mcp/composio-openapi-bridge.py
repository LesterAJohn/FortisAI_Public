#!/usr/bin/env python3
"""FortisAI OpenAPI bridge for a restricted Composio MCP endpoint."""

from __future__ import annotations

import json
import os
from typing import Any, Dict, Optional

import requests
from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel, Field


APP = FastAPI(title="fortisai-composio-openapi-bridge", version="1.0.0")

COMPOSIO_MCP_URL = os.getenv("COMPOSIO_MCP_URL", "").strip()
COMPOSIO_API_KEY = os.getenv("COMPOSIO_API_KEY", "").strip()
COMPOSIO_ALLOWED_TOOLKITS = [
    item.strip()
    for item in os.getenv("COMPOSIO_ALLOWED_TOOLKITS", "").split(",")
    if item.strip()
]
COMPOSIO_BLOCKED_TOOL_PREFIXES = [
    item.strip().lower()
    for item in os.getenv(
        "COMPOSIO_BLOCKED_TOOL_PREFIXES",
        "firecrawl,daytona,sqlcl,n8n,dify,codeindexer,proxmox,openmetadata",
    ).split(",")
    if item.strip()
]
VAULT_ADDR = os.getenv("FORTISAI_VAULT_ADDR") or os.getenv("VAULT_ADDR") or ""
VAULT_TOKEN = os.getenv("VAULT_TOKEN", "").strip()


def _vault_read(path: str) -> Optional[str]:
    if not VAULT_ADDR or not VAULT_TOKEN:
        return None
    url = f"{VAULT_ADDR.rstrip('/')}/v1/secret/data/fortisai/dev/{path.strip('/')}"
    try:
        response = requests.get(url, headers={"X-Vault-Token": VAULT_TOKEN}, timeout=8)
        if response.status_code == 404:
            return None
        response.raise_for_status()
        data = response.json().get("data", {}).get("data", {})
        value = data.get("value")
        if value is None and len(data) == 1:
            value = next(iter(data.values()))
        return str(value) if value is not None else None
    except Exception:
        return None


def _resolved_mcp_url() -> str:
    return COMPOSIO_MCP_URL or _vault_read("composio/mcp_url") or ""


def _resolved_api_key() -> str:
    return COMPOSIO_API_KEY or _vault_read("composio/api_key") or ""


def _headers(openwebui_user_id: str = "") -> Dict[str, str]:
    headers = {"Content-Type": "application/json"}
    if openwebui_user_id:
        headers["X-FortisAI-OpenWebUI-User"] = openwebui_user_id
        headers["X-OpenWebUI-User-Name"] = openwebui_user_id
    api_key = _resolved_api_key()
    if api_key:
        headers["Authorization"] = f"Bearer {api_key}"
    raw_headers = _vault_read("composio/mcp_headers_json")
    if raw_headers:
        try:
            extra = json.loads(raw_headers)
            if isinstance(extra, dict):
                headers.update({str(k): str(v) for k, v in extra.items()})
        except json.JSONDecodeError:
            pass
    return headers


def _tool_allowed(name: str) -> bool:
    normalized = name.lower().replace("-", "_")
    if any(normalized.startswith(prefix) for prefix in COMPOSIO_BLOCKED_TOOL_PREFIXES):
        return False
    if not COMPOSIO_ALLOWED_TOOLKITS:
        return True
    toolkit = normalized.split("_", 1)[0]
    return toolkit in {item.lower() for item in COMPOSIO_ALLOWED_TOOLKITS}


def _header_value(request: Request, *names: str) -> str:
    for name in names:
        value = request.headers.get(name)
        if value:
            return value.strip()
    return ""


def _clean_user_id(value: Any) -> str:
    text = str(value or "").strip()
    if not text:
        return ""
    return "".join(ch if ch.isalnum() or ch in "@._:-" else "_" for ch in text)[:160]


def _extract_openwebui_user(request: Request, payload: Any = None) -> str:
    candidates = []
    if isinstance(payload, BaseModel):
        payload = payload.model_dump() if hasattr(payload, "model_dump") else payload.dict()
    if isinstance(payload, dict):
        candidates.extend([
            payload.get("openwebui_user_id"),
            payload.get("openwebui_username"),
            payload.get("user_id"),
            payload.get("username"),
            payload.get("user"),
        ])
        nested_user = payload.get("__user__") or payload.get("openwebui_user")
        if isinstance(nested_user, dict):
            candidates.extend([
                nested_user.get("id"),
                nested_user.get("email"),
                nested_user.get("username"),
                nested_user.get("name"),
            ])
    candidates.extend([
        _header_value(request, "x-openwebui-user-id", "x-openwebui-user-email", "x-openwebui-user-name"),
        _header_value(request, "x-fortisai-openwebui-user", "x-fortisai-user", "x-user-id"),
    ])
    for candidate in candidates:
        cleaned = _clean_user_id(candidate)
        if cleaned:
            return cleaned
    return "fortisai-openwebui"


def _mcp_request(method: str, params: Dict[str, Any], openwebui_user_id: str = "") -> Dict[str, Any]:
    mcp_url = _resolved_mcp_url()
    if not mcp_url:
        raise HTTPException(
            status_code=503,
            detail="Composio MCP URL is not configured. Store composio/mcp_url in Vault or set COMPOSIO_MCP_URL.",
        )
    payload = {"jsonrpc": "2.0", "id": 1, "method": method, "params": params}
    if openwebui_user_id:
        payload.setdefault("params", {})["_fortisai_openwebui_user_id"] = openwebui_user_id
    response = requests.post(mcp_url, headers=_headers(openwebui_user_id), json=payload, timeout=120)
    try:
        body = response.json()
    except Exception:
        body = {"raw": response.text[:4000]}
    if response.status_code >= 400:
        raise HTTPException(status_code=response.status_code, detail=body)
    return body


class OpenWebUIUserContext(BaseModel):
    openwebui_user_id: Optional[str] = Field(default=None, description="OpenWebUI user id, username, or email used as the Composio session user_id.")
    openwebui_username: Optional[str] = Field(default=None, description="OpenWebUI username fallback for Composio session user_id.")
    user_id: Optional[str] = Field(default=None, description="Generic user id fallback.")
    username: Optional[str] = Field(default=None, description="Generic username fallback.")
    user: Optional[str] = Field(default=None, description="Generic user fallback.")
    openwebui_user: Dict[str, Any] = Field(default_factory=dict, description="Optional OpenWebUI user object with id/email/name fields.")


class SearchToolsRequest(OpenWebUIUserContext):
    pass


class ExecuteToolRequest(OpenWebUIUserContext):
    name: str
    arguments: Dict[str, Any] = Field(default_factory=dict)


class McpRequest(OpenWebUIUserContext):
    method: str
    params: Dict[str, Any] = Field(default_factory=dict)


@APP.get("/composio_connection_info")
def connection_info(request: Request) -> Dict[str, Any]:
    openwebui_user_id = _extract_openwebui_user(request)
    return {
        "ok": True,
        "has_api_key": bool(_resolved_api_key()),
        "has_mcp_url": bool(_resolved_mcp_url()),
        "allowed_toolkits": COMPOSIO_ALLOWED_TOOLKITS,
        "blocked_tool_prefixes": COMPOSIO_BLOCKED_TOOL_PREFIXES,
        "openwebui_user_id": openwebui_user_id,
    }


@APP.get("/composio_list_allowed_toolkits")
def list_allowed_toolkits() -> Dict[str, Any]:
    return {"allowed_toolkits": COMPOSIO_ALLOWED_TOOLKITS}


@APP.post("/composio_search_tools")
def search_tools(http_request: Request, request: Optional[SearchToolsRequest] = None) -> Dict[str, Any]:
    request = request or SearchToolsRequest()
    openwebui_user_id = _extract_openwebui_user(http_request, request)
    result = _mcp_request("tools/list", {}, openwebui_user_id)
    tools = result.get("result", {}).get("tools", [])
    if isinstance(tools, list):
        result["result"]["tools"] = [
            tool for tool in tools if _tool_allowed(str(tool.get("name", "")))
        ]
    return result


@APP.post("/composio_execute_tool")
def execute_tool(http_request: Request, request: ExecuteToolRequest) -> Dict[str, Any]:
    openwebui_user_id = _extract_openwebui_user(http_request, request)
    if not _tool_allowed(request.name):
        raise HTTPException(status_code=403, detail=f"Composio tool is blocked by FortisAI policy: {request.name}")
    return _mcp_request("tools/call", {"name": request.name, "arguments": request.arguments}, openwebui_user_id)


@APP.post("/composio_mcp_request")
def mcp_request(http_request: Request, request: McpRequest) -> Dict[str, Any]:
    openwebui_user_id = _extract_openwebui_user(http_request, request)
    if request.method == "tools/call":
        tool_name = str(request.params.get("name", ""))
        if not _tool_allowed(tool_name):
            raise HTTPException(status_code=403, detail=f"Composio tool is blocked by FortisAI policy: {tool_name}")
    return _mcp_request(request.method, request.params, openwebui_user_id)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(APP, host="0.0.0.0", port=int(os.getenv("COMPOSIO_BRIDGE_PORT", "8099")))
