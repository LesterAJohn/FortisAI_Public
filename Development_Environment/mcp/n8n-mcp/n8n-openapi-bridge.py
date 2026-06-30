#!/usr/bin/env python3
from __future__ import annotations

import base64
import json
import os
import re
import ssl
import urllib.error
import urllib.parse
import urllib.request
from typing import Any, Dict, Optional

import uvicorn
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

N8N_BASE_URL = os.environ.get("N8N_BASE_URL", "http://127.0.0.1:5678").rstrip("/")
N8N_API_KEY = os.environ.get("N8N_API_KEY", "").strip()
N8N_BASIC_AUTH_USER = os.environ.get("N8N_BASIC_AUTH_USER", "").strip()
N8N_BASIC_AUTH_PASSWORD = os.environ.get("N8N_BASIC_AUTH_PASSWORD", "").strip()
N8N_MCP_URL = os.environ.get("N8N_MCP_URL", f"{N8N_BASE_URL}/mcp-server/http").strip()
N8N_MCP_BEARER_TOKEN = os.environ.get("N8N_MCP_BEARER_TOKEN", "").strip()
N8N_INTERNAL_HOST = os.environ.get("N8N_INTERNAL_HOST", "n8n").strip() or "n8n"
N8N_VERIFY_TLS = os.environ.get("N8N_VERIFY_TLS", "true").strip().lower() in {"1", "true", "yes", "on"}
N8N_TIMEOUT_SECONDS = int(os.environ.get("N8N_TIMEOUT_SECONDS", "30"))


def normalize_mcp_url(url: str) -> str:
    if not url:
        return url

    parsed = urllib.parse.urlparse(url)
    if parsed.hostname not in {"localhost", "127.0.0.1"}:
        return url

    base = urllib.parse.urlparse(N8N_BASE_URL)

    host = N8N_INTERNAL_HOST
    if not host:
        if base.hostname in {None, "", "localhost", "127.0.0.1"}:
            return url
        host = base.hostname

    scheme = base.scheme or parsed.scheme or "http"
    port = parsed.port or base.port
    netloc = host if not port else f"{host}:{port}"
    path = parsed.path or "/mcp-server/http"
    return urllib.parse.urlunparse((scheme, netloc, path, "", "", ""))


N8N_MCP_URL = normalize_mcp_url(N8N_MCP_URL)

app = FastAPI(title="fortisai-n8n-openapi-bridge", version="1.0.0")


class ApiRequest(BaseModel):
    method: str
    path: str
    query: Optional[Dict[str, Any]] = None
    body: Optional[Dict[str, Any]] = None
    requireApiKey: bool = True


class WorkflowRequest(BaseModel):
    workflow: Dict[str, Any]


class WorkflowUpdateRequest(BaseModel):
    id: str
    workflow: Dict[str, Any]


class WorkflowActiveRequest(BaseModel):
    id: str
    active: bool


class MpcProxyRequest(BaseModel):
    payload: Dict[str, Any]
    sessionId: Optional[str] = None


class MpcInitializeRequest(BaseModel):
    protocolVersion: str = "2024-11-05"
    capabilities: Dict[str, Any] = {}
    clientInfo: Dict[str, Any] = {"name": "fortisai-n8n-openapi-bridge", "version": "1.0.0"}


class MpcToolsListRequest(BaseModel):
    sessionId: Optional[str] = None


class MpcToolCallRequest(BaseModel):
    name: str
    arguments: Dict[str, Any] = {}
    sessionId: Optional[str] = None


def headers(require_api_key: bool) -> Dict[str, str]:
    result = {"Accept": "application/json"}
    if N8N_API_KEY:
        result["X-N8N-API-KEY"] = N8N_API_KEY
    elif require_api_key:
        raise ValueError("N8N_API_KEY is not set")

    if N8N_BASIC_AUTH_USER and N8N_BASIC_AUTH_PASSWORD:
        encoded = base64.b64encode(f"{N8N_BASIC_AUTH_USER}:{N8N_BASIC_AUTH_PASSWORD}".encode("utf-8")).decode("ascii")
        result["Authorization"] = f"Basic {encoded}"

    return result


def n8n_request(
    method: str,
    path: str,
    query: Optional[Dict[str, Any]] = None,
    body: Optional[Dict[str, Any]] = None,
    require_api_key: bool = False,
) -> Dict[str, Any]:
    clean_path = path if path.startswith("/") else f"/{path}"
    url = f"{N8N_BASE_URL}{clean_path}"

    if query:
        query_items = []
        for key, value in query.items():
            if value is None:
                continue
            if isinstance(value, (list, tuple)):
                for item in value:
                    query_items.append((key, str(item)))
            else:
                query_items.append((key, str(value)))
        if query_items:
            url = f"{url}?{urllib.parse.urlencode(query_items)}"

    data_bytes = None
    req_headers = headers(require_api_key=require_api_key)
    if body is not None:
        data_bytes = json.dumps(body).encode("utf-8")
        req_headers["Content-Type"] = "application/json"

    request = urllib.request.Request(url=url, data=data_bytes, headers=req_headers, method=method.upper())
    context = None
    if not N8N_VERIFY_TLS and url.startswith("https://"):
        context = ssl._create_unverified_context()

    try:
        with urllib.request.urlopen(request, timeout=N8N_TIMEOUT_SECONDS, context=context) as response:
            raw = response.read().decode("utf-8", errors="replace")
            parsed: Any = raw
            if raw:
                try:
                    parsed = json.loads(raw)
                except json.JSONDecodeError:
                    parsed = raw
            return {"status": response.status, "body": parsed}
    except urllib.error.HTTPError as exc:
        raw = exc.read().decode("utf-8", errors="replace")
        parsed: Any = raw
        if raw:
            try:
                parsed = json.loads(raw)
            except json.JSONDecodeError:
                parsed = raw
        return {"status": exc.code, "body": parsed}


def mcp_headers(session_id: Optional[str] = None) -> Dict[str, str]:
    if not N8N_MCP_BEARER_TOKEN:
        raise ValueError("N8N_MCP_BEARER_TOKEN is not set")

    result = {
        "Accept": "application/json, text/event-stream",
        "Content-Type": "application/json",
        "Authorization": f"Bearer {N8N_MCP_BEARER_TOKEN}",
    }
    if session_id:
        result["Mcp-Session-Id"] = session_id
    return result


def n8n_mcp_request(payload: Dict[str, Any], session_id: Optional[str] = None) -> Dict[str, Any]:
    if not N8N_MCP_URL:
        raise ValueError("N8N_MCP_URL is not set")

    data_bytes = json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(url=N8N_MCP_URL, data=data_bytes, headers=mcp_headers(session_id=session_id), method="POST")
    context = None
    if not N8N_VERIFY_TLS and N8N_MCP_URL.startswith("https://"):
        context = ssl._create_unverified_context()

    try:
        with urllib.request.urlopen(request, timeout=N8N_TIMEOUT_SECONDS, context=context) as response:
            raw = response.read().decode("utf-8", errors="replace")
            parsed: Any = raw
            if raw:
                try:
                    parsed = json.loads(raw)
                except json.JSONDecodeError:
                    sse_match = re.search(r"data:\s*(\{.*\})\s*$", raw, flags=re.S)
                    if sse_match:
                        try:
                            parsed = json.loads(sse_match.group(1))
                        except json.JSONDecodeError:
                            parsed = raw
                    else:
                        parsed = raw
            return {
                "status": response.status,
                "headers": {
                    "content-type": response.headers.get("Content-Type", ""),
                    "mcp-session-id": response.headers.get("Mcp-Session-Id", ""),
                },
                "body": parsed,
            }
    except urllib.error.HTTPError as exc:
        raw = exc.read().decode("utf-8", errors="replace")
        parsed: Any = raw
        if raw:
            try:
                parsed = json.loads(raw)
            except json.JSONDecodeError:
                sse_match = re.search(r"data:\s*(\{.*\})\s*$", raw, flags=re.S)
                if sse_match:
                    try:
                        parsed = json.loads(sse_match.group(1))
                    except json.JSONDecodeError:
                        parsed = raw
                else:
                    parsed = raw
        return {
            "status": exc.code,
            "headers": {
                "content-type": exc.headers.get("Content-Type", "") if exc.headers else "",
                "mcp-session-id": exc.headers.get("Mcp-Session-Id", "") if exc.headers else "",
            },
            "body": parsed,
        }


def n8n_mcp_initialize_session() -> Dict[str, Any]:
    init_payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {"name": "fortisai-n8n-openapi-bridge", "version": "1.0.0"},
        },
    }
    init_result = n8n_mcp_request(payload=init_payload)
    if int(init_result.get("status", 500)) >= 400:
        return init_result

    session_id = str(init_result.get("headers", {}).get("mcp-session-id", "")).strip()
    if session_id:
        # Best-effort notification required by MCP handshake semantics.
        n8n_mcp_request(
            payload={"jsonrpc": "2.0", "method": "notifications/initialized", "params": {}},
            session_id=session_id,
        )

    return init_result


@app.get("/healthz", include_in_schema=False)
def healthz() -> Dict[str, Any]:
    return n8n_request("GET", "/healthz", require_api_key=False)


@app.get("/n8n_connection_info")
def n8n_connection_info() -> Dict[str, Any]:
    return {
        "base_url": N8N_BASE_URL,
        "has_api_key": bool(N8N_API_KEY),
        "has_basic_auth": bool(N8N_BASIC_AUTH_USER and N8N_BASIC_AUTH_PASSWORD),
        "mcp_url": N8N_MCP_URL,
        "has_mcp_bearer_token": bool(N8N_MCP_BEARER_TOKEN),
        "verify_tls": N8N_VERIFY_TLS,
    }


@app.get("/n8n_mcp_connection_info")
def n8n_mcp_connection_info() -> Dict[str, Any]:
    return {
        "mcp_url": N8N_MCP_URL,
        "has_mcp_bearer_token": bool(N8N_MCP_BEARER_TOKEN),
        "verify_tls": N8N_VERIFY_TLS,
    }


@app.post("/n8n_mcp_initialize")
def n8n_mcp_initialize(request: MpcInitializeRequest) -> Dict[str, Any]:
    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {
            "protocolVersion": request.protocolVersion,
            "capabilities": request.capabilities,
            "clientInfo": request.clientInfo,
        },
    }
    try:
        result = n8n_mcp_request(payload=payload)
    except Exception as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    if int(result.get("status", 500)) >= 400:
        raise HTTPException(status_code=int(result.get("status", 500)), detail=result)
    return result


@app.post("/n8n_mcp_request")
def n8n_mcp_proxy(request: MpcProxyRequest) -> Dict[str, Any]:
    try:
        result = n8n_mcp_request(payload=request.payload, session_id=request.sessionId)
    except Exception as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    if int(result.get("status", 500)) >= 400:
        raise HTTPException(status_code=int(result.get("status", 500)), detail=result)
    return result


@app.post("/n8n_mcp_list_tools")
def n8n_mcp_list_tools(request: MpcToolsListRequest) -> Dict[str, Any]:
    session_id = request.sessionId
    initialize_result = None
    if not session_id:
        initialize_result = n8n_mcp_initialize_session()
        if int(initialize_result.get("status", 500)) >= 400:
            raise HTTPException(status_code=int(initialize_result.get("status", 500)), detail=initialize_result)
        session_id = str(initialize_result.get("headers", {}).get("mcp-session-id", "")).strip() or None

    try:
        tools_result = n8n_mcp_request(
            payload={"jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": {}},
            session_id=session_id,
        )
    except Exception as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    if int(tools_result.get("status", 500)) >= 400:
        raise HTTPException(status_code=int(tools_result.get("status", 500)), detail=tools_result)

    return {
        "initialize": initialize_result,
        "tools": tools_result,
        "sessionId": session_id,
    }


@app.post("/n8n_mcp_call_tool")
def n8n_mcp_call_tool(request: MpcToolCallRequest) -> Dict[str, Any]:
    session_id = request.sessionId
    initialize_result = None
    if not session_id:
        initialize_result = n8n_mcp_initialize_session()
        if int(initialize_result.get("status", 500)) >= 400:
            raise HTTPException(status_code=int(initialize_result.get("status", 500)), detail=initialize_result)
        session_id = str(initialize_result.get("headers", {}).get("mcp-session-id", "")).strip() or None

    payload = {
        "jsonrpc": "2.0",
        "id": 3,
        "method": "tools/call",
        "params": {
            "name": request.name,
            "arguments": request.arguments,
        },
    }

    try:
        call_result = n8n_mcp_request(payload=payload, session_id=session_id)
    except Exception as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    if int(call_result.get("status", 500)) >= 400:
        raise HTTPException(status_code=int(call_result.get("status", 500)), detail=call_result)

    return {
        "initialize": initialize_result,
        "call": call_result,
        "sessionId": session_id,
    }


@app.post("/n8n_api_request")
def api_request(request: ApiRequest) -> Dict[str, Any]:
    try:
        result = n8n_request(
            method=request.method,
            path=request.path,
            query=request.query,
            body=request.body,
            require_api_key=request.requireApiKey,
        )
    except Exception as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    if int(result.get("status", 500)) >= 400:
        raise HTTPException(status_code=int(result.get("status", 500)), detail=result)
    return result


@app.get("/n8n_list_workflows")
def n8n_list_workflows(limit: int = 100) -> Dict[str, Any]:
    try:
        result = n8n_request("GET", "/api/v1/workflows", query={"limit": limit}, require_api_key=True)
    except Exception as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    if int(result.get("status", 500)) >= 400:
        raise HTTPException(status_code=int(result.get("status", 500)), detail=result)
    return result


@app.get("/n8n_get_workflow/{workflow_id}")
def n8n_get_workflow(workflow_id: str) -> Dict[str, Any]:
    try:
        result = n8n_request("GET", f"/api/v1/workflows/{workflow_id}", require_api_key=True)
    except Exception as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    if int(result.get("status", 500)) >= 400:
        raise HTTPException(status_code=int(result.get("status", 500)), detail=result)
    return result


@app.post("/n8n_create_workflow")
def n8n_create_workflow(request: WorkflowRequest) -> Dict[str, Any]:
    try:
        result = n8n_request("POST", "/api/v1/workflows", body=request.workflow, require_api_key=True)
    except Exception as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    if int(result.get("status", 500)) >= 400:
        raise HTTPException(status_code=int(result.get("status", 500)), detail=result)
    return result


@app.post("/n8n_update_workflow")
def n8n_update_workflow(request: WorkflowUpdateRequest) -> Dict[str, Any]:
    try:
        result = n8n_request("PUT", f"/api/v1/workflows/{request.id}", body=request.workflow, require_api_key=True)
    except Exception as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    if int(result.get("status", 500)) >= 400:
        raise HTTPException(status_code=int(result.get("status", 500)), detail=result)
    return result


@app.post("/n8n_set_workflow_active")
def n8n_set_workflow_active(request: WorkflowActiveRequest) -> Dict[str, Any]:
    route = "activate" if request.active else "deactivate"
    try:
        result = n8n_request("POST", f"/api/v1/workflows/{request.id}/{route}", require_api_key=True)
    except Exception as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    if int(result.get("status", 500)) == 404:
        result = n8n_request(
            "PATCH",
            f"/api/v1/workflows/{request.id}",
            body={"active": request.active},
            require_api_key=True,
        )

    if int(result.get("status", 500)) >= 400:
        raise HTTPException(status_code=int(result.get("status", 500)), detail=result)
    return result


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("N8N_BRIDGE_PORT", "8092")))
