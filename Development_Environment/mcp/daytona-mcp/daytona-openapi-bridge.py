#!/usr/bin/env python3
"""FortisAI Daytona OpenAPI bridge."""

from __future__ import annotations

import json
import os
import time
import urllib.error
import urllib.parse
import urllib.request
from typing import Any, Dict, Optional

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field


APP_NAME = "FortisAI Daytona Bridge"
DAYTONA_API_URL = (os.environ.get("DAYTONA_API_URL") or "http://daytona-api.fortisai.local:3000/api").rstrip("/")
DAYTONA_DASHBOARD_URL = (os.environ.get("DAYTONA_DASHBOARD_URL") or "http://daytona-api.fortisai.local:3000").rstrip("/")
DAYTONA_PROXY_URL = (os.environ.get("DAYTONA_PROXY_URL") or "http://daytona-proxy.fortisai.local:4000/toolbox").rstrip("/")
DAYTONA_API_KEY = os.environ.get("DAYTONA_API_KEY", "")
DAYTONA_ORG_ID = os.environ.get("DAYTONA_ORG_ID", "")
DAYTONA_DEFAULT_SNAPSHOT = os.environ.get("DAYTONA_DEFAULT_SNAPSHOT", "fortisai-ubuntu-22.04")
BRIDGE_PORT = int(os.environ.get("DAYTONA_BRIDGE_PORT", "8098"))

app = FastAPI(
    title=APP_NAME,
    version="1.0.0",
    description="OpenAPI bridge for Daytona sandbox lifecycle and sandbox command execution inside FortisAI.",
)


class SandboxListRequest(BaseModel):
    limit: int = Field(10, ge=1, le=100, description="Maximum number of sandboxes to return.")
    cursor: Optional[str] = Field(None, description="Daytona pagination cursor.")
    states: Optional[list[str]] = Field(None, description="Optional sandbox states filter.")
    name: Optional[str] = Field(None, description="Optional sandbox name filter.")
    id: Optional[str] = Field(None, description="Optional sandbox id filter.")
    includeErroredDeleted: Optional[bool] = Field(None, description="Include errored/deleted sandboxes when supported.")


class SandboxRefRequest(BaseModel):
    sandbox_id_or_name: str = Field(..., min_length=1, description="Daytona sandbox id or name.")
    verbose: bool = Field(False, description="Request verbose sandbox detail when supported.")


class SandboxCreateRequest(BaseModel):
    name: str = Field(..., min_length=1, description="Sandbox name.")
    target: str = Field("us", min_length=1, description="Daytona target/region.")
    autoDeleteInterval: int = Field(0, ge=0, description="Daytona auto-delete interval. Zero disables auto-delete when supported.")
    labels: Optional[Dict[str, str]] = Field(None, description="Optional sandbox labels.")
    env: Optional[Dict[str, str]] = Field(None, description="Optional sandbox environment variables.")
    snapshot: Optional[str] = Field(None, description="Optional snapshot id/name.")
    public: Optional[bool] = Field(None, description="Optional public visibility flag.")


class SandboxDeleteRequest(BaseModel):
    sandbox_id_or_name: str = Field(..., min_length=1, description="Daytona sandbox id or name to delete.")


class ToolboxProxyRequest(BaseModel):
    sandbox_id: str = Field(..., min_length=1, description="Daytona sandbox id.")


class ExecuteCommandRequest(BaseModel):
    sandbox_id_or_name: str = Field(..., min_length=1, description="Daytona sandbox id or name.")
    command: str = Field(..., min_length=1, description="Shell command to execute inside the sandbox.")
    cwd: Optional[str] = Field(None, description="Working directory inside the sandbox.")
    timeout_seconds: int = Field(30, ge=1, le=1800, description="Command timeout in seconds.")


def _headers() -> Dict[str, str]:
    headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "User-Agent": "fortisai-daytona-openapi-bridge/1.0",
    }
    if DAYTONA_API_KEY:
        headers["Authorization"] = f"Bearer {DAYTONA_API_KEY}"
    if DAYTONA_ORG_ID:
        headers["X-Daytona-Organization-ID"] = DAYTONA_ORG_ID
    return headers


def _json_request(
    method: str,
    path: str,
    payload: Optional[Dict[str, Any]] = None,
    query: Optional[Dict[str, Any]] = None,
    timeout: int = 30,
    base_url: Optional[str] = None,
    expected_statuses: tuple[int, ...] = (200,),
) -> Dict[str, Any]:
    target_base = (base_url or DAYTONA_API_URL).rstrip("/")
    target_path = path if path.startswith("/") else f"/{path}"
    url = f"{target_base}{target_path}"
    if query:
        clean_query: Dict[str, Any] = {}
        for key, value in query.items():
            if value is None:
                continue
            if isinstance(value, list):
                clean_query[key] = ",".join(str(item) for item in value)
            else:
                clean_query[key] = value
        if clean_query:
            url = f"{url}?{urllib.parse.urlencode(clean_query)}"

    body = None if payload is None else json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(url, data=body, headers=_headers(), method=method.upper())

    started = time.monotonic()
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            raw = response.read().decode("utf-8", errors="replace")
            status = getattr(response, "status", 200)
    except urllib.error.HTTPError as exc:
        raw = exc.read().decode("utf-8", errors="replace")
        raise HTTPException(
            status_code=502,
            detail={
                "ok": False,
                "status": exc.code,
                "url": url,
                "message": raw[:2000],
            },
        ) from exc
    except Exception as exc:
        raise HTTPException(
            status_code=502,
            detail={
                "ok": False,
                "url": url,
                "error": type(exc).__name__,
                "message": str(exc),
            },
        ) from exc

    if status not in expected_statuses:
        raise HTTPException(status_code=502, detail={"ok": False, "status": status, "url": url, "message": raw[:2000]})

    try:
        parsed: Any = json.loads(raw) if raw else {}
    except json.JSONDecodeError:
        parsed = {"raw": raw}
    if not isinstance(parsed, dict):
        parsed = {"data": parsed}
    parsed.setdefault("status", status)
    parsed.setdefault("elapsed_ms", round((time.monotonic() - started) * 1000, 2))
    return parsed


def _probe(url: str, timeout: int = 5) -> Dict[str, Any]:
    request = urllib.request.Request(url, headers=_headers(), method="GET")
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            text = response.read().decode("utf-8", errors="replace")
            return {"ok": True, "status": getattr(response, "status", 200), "body_sample": text[:300]}
    except urllib.error.HTTPError as exc:
        text = exc.read().decode("utf-8", errors="replace")
        return {"ok": False, "status": exc.code, "body_sample": text[:300]}
    except Exception as exc:
        return {"ok": False, "status": 0, "error": type(exc).__name__, "message": str(exc)}


def _model_dict(model: BaseModel) -> Dict[str, Any]:
    if hasattr(model, "model_dump"):
        return model.model_dump(exclude_none=True)
    return model.dict(exclude_none=True)


def _sandbox_id(sandbox: Dict[str, Any], fallback: str) -> str:
    for key in ("id", "name"):
        value = sandbox.get(key)
        if isinstance(value, str) and value.strip():
            return value.strip()
    return fallback


def _get_sandbox(sandbox_id_or_name: str, verbose: bool = False) -> Dict[str, Any]:
    query = {"verbose": str(bool(verbose)).lower()} if verbose else None
    return _json_request("GET", f"/sandbox/{urllib.parse.quote(sandbox_id_or_name, safe='')}", query=query, timeout=60)


def _daytona_not_found(exc: HTTPException) -> bool:
    detail = exc.detail if isinstance(exc.detail, dict) else {}
    return exc.status_code == 502 and int(detail.get("status") or 0) == 404


def _wait_for_sandbox_started(sandbox_id_or_name: str, timeout_seconds: int = 180) -> Dict[str, Any]:
    deadline = time.monotonic() + max(timeout_seconds, 1)
    last: Dict[str, Any] = {}
    while time.monotonic() < deadline:
        last = _get_sandbox(sandbox_id_or_name.strip(), verbose=False)
        state = str(last.get("state") or "").lower()
        if state == "started":
            return last
        time.sleep(5)
    raise HTTPException(
        status_code=504,
        detail={
            "ok": False,
            "message": f"Daytona sandbox did not reach started state within {timeout_seconds} seconds.",
            "sandbox": last,
        },
    )


def _create_execution_sandbox(name: str) -> Dict[str, Any]:
    payload: Dict[str, Any] = {
        "name": name,
        "target": "us",
        "autoDeleteInterval": 0,
        "autoStopInterval": 0,
        "autoArchiveInterval": 0,
        "labels": {"source": "openwebui", "managed_by": "fortisai-daytona-bridge"},
    }
    if DAYTONA_DEFAULT_SNAPSHOT:
        payload["snapshot"] = DAYTONA_DEFAULT_SNAPSHOT
    result = _json_request("POST", "/sandbox", payload=payload, timeout=180, expected_statuses=(200, 201, 202))
    created_name = str(result.get("name") or name).strip() or name
    return _wait_for_sandbox_started(created_name, timeout_seconds=180)


def _get_or_create_execution_sandbox(sandbox_id_or_name: str) -> Dict[str, Any]:
    name = sandbox_id_or_name.strip()
    try:
        return _get_sandbox(name, verbose=False)
    except HTTPException as exc:
        if not _daytona_not_found(exc):
            raise
        return _create_execution_sandbox(name)


def _normalize_proxy_url(url: str) -> str:
    value = (url or DAYTONA_PROXY_URL).rstrip("/")
    parsed = urllib.parse.urlparse(value)
    if parsed.hostname in {"127.0.0.1", "localhost", "aiengine000", "AIEngine000"}:
        return DAYTONA_PROXY_URL
    return value


def _toolbox_proxy_url(sandbox_id: str) -> str:
    if os.environ.get("DAYTONA_TOOLBOX_PROXY_URL"):
        return _normalize_proxy_url(os.environ["DAYTONA_TOOLBOX_PROXY_URL"])
    try:
        response = _json_request("GET", f"/sandbox/{urllib.parse.quote(sandbox_id, safe='')}/toolbox-proxy-url", timeout=30)
        data = response.get("data")
        value = response.get("url")
        if not value and isinstance(data, dict):
            value = data.get("url")
        if isinstance(value, str) and value.strip():
            return _normalize_proxy_url(value.strip())
    except HTTPException:
        pass
    return DAYTONA_PROXY_URL


@app.get("/healthz", operation_id="daytona_healthz", summary="Bridge health check", include_in_schema=False)
def healthz() -> Dict[str, Any]:
    return {"ok": True, "service": "daytona", "daytona_api_url": DAYTONA_API_URL}


@app.get("/daytona_connection_info", operation_id="daytona_connection_info", summary="Return Daytona bridge connection details")
def daytona_connection_info() -> Dict[str, Any]:
    return {
        "ok": True,
        "bridge": "fortisai-mcp-openapi-daytona",
        "daytona_api_url": DAYTONA_API_URL,
        "daytona_dashboard_url": DAYTONA_DASHBOARD_URL,
        "daytona_proxy_url": DAYTONA_PROXY_URL,
        "has_daytona_api_key": bool(DAYTONA_API_KEY),
        "has_daytona_org_id": bool(DAYTONA_ORG_ID),
        "health": {
            "api": _probe(f"{DAYTONA_API_URL.rsplit('/api', 1)[0]}/api/health"),
            "proxy": _probe(DAYTONA_PROXY_URL.rsplit('/toolbox', 1)[0] + "/health"),
        },
    }


@app.post("/daytona_list_sandboxes", operation_id="daytona_list_sandboxes", summary="List Daytona sandboxes")
def daytona_list_sandboxes(request: SandboxListRequest) -> Dict[str, Any]:
    query = _model_dict(request)
    result = _json_request("GET", "/sandbox", query=query, timeout=60)
    data = result.get("data") or result.get("items") or result.get("sandboxes")
    count = len(data) if isinstance(data, list) else None
    return {"ok": True, "status": result.get("status", 200), "count": count, "data": result}


@app.post("/daytona_get_sandbox", operation_id="daytona_get_sandbox", summary="Get Daytona sandbox details")
def daytona_get_sandbox(request: SandboxRefRequest) -> Dict[str, Any]:
    result = _get_sandbox(request.sandbox_id_or_name.strip(), request.verbose)
    return {"ok": True, "status": result.get("status", 200), "sandbox": result}


@app.post("/daytona_create_sandbox", operation_id="daytona_create_sandbox", summary="Create a Daytona sandbox")
def daytona_create_sandbox(request: SandboxCreateRequest) -> Dict[str, Any]:
    payload = _model_dict(request)
    if DAYTONA_DEFAULT_SNAPSHOT and not payload.get("snapshot"):
        payload["snapshot"] = DAYTONA_DEFAULT_SNAPSHOT
    result = _json_request("POST", "/sandbox", payload=payload, timeout=180, expected_statuses=(200, 201, 202))
    return {"ok": True, "status": result.get("status", 200), "sandbox": result}


@app.post("/daytona_delete_sandbox", operation_id="daytona_delete_sandbox", summary="Delete a Daytona sandbox")
def daytona_delete_sandbox(request: SandboxDeleteRequest) -> Dict[str, Any]:
    result = _json_request(
        "DELETE",
        f"/sandbox/{urllib.parse.quote(request.sandbox_id_or_name.strip(), safe='')}",
        timeout=120,
        expected_statuses=(200, 202, 204),
    )
    return {"ok": True, "status": result.get("status", 200), "response": result}


@app.post("/daytona_get_toolbox_proxy", operation_id="daytona_get_toolbox_proxy", summary="Get toolbox proxy URL for a Daytona sandbox")
def daytona_get_toolbox_proxy(request: ToolboxProxyRequest) -> Dict[str, Any]:
    proxy_url = _toolbox_proxy_url(request.sandbox_id.strip())
    return {"ok": True, "sandbox_id": request.sandbox_id.strip(), "toolbox_proxy_url": proxy_url}


@app.post("/daytona_execute_command", operation_id="daytona_execute_command", summary="Execute a command inside a Daytona sandbox")
def daytona_execute_command(request: ExecuteCommandRequest) -> Dict[str, Any]:
    sandbox = _get_or_create_execution_sandbox(request.sandbox_id_or_name.strip())
    sandbox_id = _sandbox_id(sandbox, request.sandbox_id_or_name.strip())
    payload: Dict[str, Any] = {"command": request.command, "timeout": float(request.timeout_seconds)}
    if request.cwd:
        payload["cwd"] = request.cwd

    proxy_url = _toolbox_proxy_url(sandbox_id)
    try:
        result = _json_request(
            "POST",
            f"/{urllib.parse.quote(sandbox_id, safe='')}/process/execute",
            payload=payload,
            timeout=request.timeout_seconds + 10,
            base_url=proxy_url,
            expected_statuses=(200,),
        )
        source = "toolbox_proxy"
    except HTTPException:
        result = _json_request(
            "POST",
            f"/toolbox/{urllib.parse.quote(sandbox_id, safe='')}/toolbox/process/execute",
            payload=payload,
            timeout=request.timeout_seconds + 10,
            expected_statuses=(200,),
        )
        source = "api_toolbox_fallback"

    exit_code = result.get("exitCode")
    return {
        "ok": exit_code in (0, 0.0, None),
        "source": source,
        "sandbox_id": sandbox_id,
        "exit_code": exit_code,
        "result": result.get("result"),
        "raw": result,
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=BRIDGE_PORT)
