#!/usr/bin/env python3
from __future__ import annotations

import base64
import json
import os
import ssl
import sys
import urllib.error
import urllib.parse
import urllib.request
from typing import Any, Dict, Optional

PROTOCOL_VERSION = "2024-11-05"


def as_bool(value: Optional[str], default: bool) -> bool:
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


class N8nMcpServer:
    def __init__(self) -> None:
        self.base_url = os.environ.get("N8N_BASE_URL", "http://127.0.0.1:5678").rstrip("/")
        self.api_key = os.environ.get("N8N_API_KEY", "").strip()
        self.username = os.environ.get("N8N_BASIC_AUTH_USER", "").strip()
        self.password = os.environ.get("N8N_BASIC_AUTH_PASSWORD", "").strip()
        self.verify_tls = as_bool(os.environ.get("N8N_VERIFY_TLS"), True)
        self.timeout_seconds = int(os.environ.get("N8N_TIMEOUT_SECONDS", "30"))

    def send(self, payload: Dict[str, Any]) -> None:
        body = json.dumps(payload, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
        header = f"Content-Length: {len(body)}\r\n\r\n".encode("ascii")
        sys.stdout.buffer.write(header)
        sys.stdout.buffer.write(body)
        sys.stdout.buffer.flush()

    def read_message(self) -> Optional[Dict[str, Any]]:
        headers: Dict[str, str] = {}
        while True:
            line = sys.stdin.buffer.readline()
            if not line:
                return None
            if line in (b"\r\n", b"\n"):
                break
            try:
                key, value = line.decode("utf-8").split(":", 1)
            except ValueError:
                continue
            headers[key.strip().lower()] = value.strip()

        content_length = int(headers.get("content-length", "0"))
        if content_length <= 0:
            return None

        body = sys.stdin.buffer.read(content_length)
        if not body:
            return None
        return json.loads(body.decode("utf-8"))

    def result(self, request_id: Any, data: Any) -> None:
        self.send({"jsonrpc": "2.0", "id": request_id, "result": data})

    def error(self, request_id: Any, code: int, message: str) -> None:
        self.send({"jsonrpc": "2.0", "id": request_id, "error": {"code": code, "message": message}})

    def tool_content(self, text: str, is_error: bool = False) -> Dict[str, Any]:
        return {"content": [{"type": "text", "text": text}], "isError": is_error}

    def _headers(self, require_api_key: bool) -> Dict[str, str]:
        headers = {"Accept": "application/json"}

        if self.api_key:
            headers["X-N8N-API-KEY"] = self.api_key
        elif require_api_key:
            raise ValueError(
                "N8N_API_KEY is not set. Generate an n8n API key and set N8N_API_KEY in MCP env."
            )

        if self.username and self.password:
            encoded = base64.b64encode(f"{self.username}:{self.password}".encode("utf-8")).decode("ascii")
            headers["Authorization"] = f"Basic {encoded}"

        return headers

    def _request(
        self,
        method: str,
        path: str,
        query: Optional[Dict[str, Any]] = None,
        body: Optional[Dict[str, Any]] = None,
        require_api_key: bool = False,
    ) -> Dict[str, Any]:
        clean_path = path if path.startswith("/") else f"/{path}"
        url = f"{self.base_url}{clean_path}"

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
        headers = self._headers(require_api_key=require_api_key)
        if body is not None:
            data_bytes = json.dumps(body).encode("utf-8")
            headers["Content-Type"] = "application/json"

        request = urllib.request.Request(url=url, data=data_bytes, headers=headers, method=method.upper())

        context = None
        if not self.verify_tls and url.startswith("https://"):
            context = ssl._create_unverified_context()

        try:
            with urllib.request.urlopen(request, timeout=self.timeout_seconds, context=context) as response:
                raw = response.read().decode("utf-8", errors="replace")
                return self._format_response(response.status, raw)
        except urllib.error.HTTPError as exc:
            raw = exc.read().decode("utf-8", errors="replace")
            return self._format_response(exc.code, raw)

    def _format_response(self, status: int, raw_body: str) -> Dict[str, Any]:
        parsed: Any = raw_body
        if raw_body:
            try:
                parsed = json.loads(raw_body)
            except json.JSONDecodeError:
                parsed = raw_body
        else:
            parsed = None

        return {"status": status, "body": parsed}

    def tools(self) -> Dict[str, Any]:
        return {
            "tools": [
                {
                    "name": "n8n_connection_info",
                    "description": "Return n8n MCP bridge connection configuration summary.",
                    "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False},
                },
                {
                    "name": "n8n_health",
                    "description": "Check n8n health endpoint.",
                    "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False},
                },
                {
                    "name": "n8n_api_request",
                    "description": "Send a direct request to n8n API. Use /api/v1/... paths for workflow automation.",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "method": {"type": "string", "description": "HTTP method"},
                            "path": {"type": "string", "description": "API path, for example /api/v1/workflows"},
                            "query": {"type": "object", "description": "Optional query params", "additionalProperties": True},
                            "body": {"type": "object", "description": "Optional JSON body", "additionalProperties": True},
                            "requireApiKey": {
                                "type": "boolean",
                                "description": "When true, fail early if N8N_API_KEY is missing.",
                                "default": True,
                            },
                        },
                        "required": ["method", "path"],
                        "additionalProperties": False,
                    },
                },
                {
                    "name": "n8n_list_workflows",
                    "description": "List workflows via n8n public API.",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "limit": {"type": "integer", "minimum": 1, "maximum": 250, "default": 100},
                            "active": {"type": "boolean"},
                        },
                        "additionalProperties": False,
                    },
                },
                {
                    "name": "n8n_get_workflow",
                    "description": "Get a workflow by id via n8n public API.",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "id": {"type": "string", "description": "Workflow id"},
                        },
                        "required": ["id"],
                        "additionalProperties": False,
                    },
                },
                {
                    "name": "n8n_create_workflow",
                    "description": "Create a workflow via n8n public API.",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "workflow": {"type": "object", "additionalProperties": True},
                        },
                        "required": ["workflow"],
                        "additionalProperties": False,
                    },
                },
                {
                    "name": "n8n_update_workflow",
                    "description": "Update a workflow by id via n8n public API.",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "id": {"type": "string"},
                            "workflow": {"type": "object", "additionalProperties": True},
                        },
                        "required": ["id", "workflow"],
                        "additionalProperties": False,
                    },
                },
                {
                    "name": "n8n_set_workflow_active",
                    "description": "Activate or deactivate a workflow.",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "id": {"type": "string"},
                            "active": {"type": "boolean"},
                        },
                        "required": ["id", "active"],
                        "additionalProperties": False,
                    },
                },
            ]
        }

    def handle_tools_call(self, request_id: Any, params: Dict[str, Any]) -> None:
        name = params.get("name")
        arguments = params.get("arguments") or {}

        try:
            if name == "n8n_connection_info":
                payload = {
                    "base_url": self.base_url,
                    "has_api_key": bool(self.api_key),
                    "has_basic_auth": bool(self.username and self.password),
                    "verify_tls": self.verify_tls,
                    "timeout_seconds": self.timeout_seconds,
                }
                self.result(request_id, self.tool_content(json.dumps(payload, indent=2)))
                return

            if name == "n8n_health":
                resp = self._request("GET", "/healthz", require_api_key=False)
                self.result(request_id, self.tool_content(json.dumps(resp, indent=2)))
                return

            if name == "n8n_api_request":
                method = str(arguments.get("method", "GET"))
                path = str(arguments.get("path", "")).strip()
                if not path:
                    raise ValueError("path must not be empty")
                query = arguments.get("query") if isinstance(arguments.get("query"), dict) else None
                body = arguments.get("body") if isinstance(arguments.get("body"), dict) else None
                require_api_key = bool(arguments.get("requireApiKey", True))
                resp = self._request(method, path, query=query, body=body, require_api_key=require_api_key)
                is_error = int(resp.get("status", 500)) >= 400
                self.result(request_id, self.tool_content(json.dumps(resp, indent=2), is_error=is_error))
                return

            if name == "n8n_list_workflows":
                limit = int(arguments.get("limit", 100))
                active = arguments.get("active")
                query: Dict[str, Any] = {"limit": limit}
                if isinstance(active, bool):
                    query["active"] = str(active).lower()
                resp = self._request("GET", "/api/v1/workflows", query=query, require_api_key=True)
                is_error = int(resp.get("status", 500)) >= 400
                self.result(request_id, self.tool_content(json.dumps(resp, indent=2), is_error=is_error))
                return

            if name == "n8n_get_workflow":
                workflow_id = str(arguments.get("id", "")).strip()
                if not workflow_id:
                    raise ValueError("id must not be empty")
                resp = self._request("GET", f"/api/v1/workflows/{workflow_id}", require_api_key=True)
                is_error = int(resp.get("status", 500)) >= 400
                self.result(request_id, self.tool_content(json.dumps(resp, indent=2), is_error=is_error))
                return

            if name == "n8n_create_workflow":
                workflow = arguments.get("workflow")
                if not isinstance(workflow, dict):
                    raise ValueError("workflow must be an object")
                resp = self._request("POST", "/api/v1/workflows", body=workflow, require_api_key=True)
                is_error = int(resp.get("status", 500)) >= 400
                self.result(request_id, self.tool_content(json.dumps(resp, indent=2), is_error=is_error))
                return

            if name == "n8n_update_workflow":
                workflow_id = str(arguments.get("id", "")).strip()
                workflow = arguments.get("workflow")
                if not workflow_id:
                    raise ValueError("id must not be empty")
                if not isinstance(workflow, dict):
                    raise ValueError("workflow must be an object")
                resp = self._request("PUT", f"/api/v1/workflows/{workflow_id}", body=workflow, require_api_key=True)
                is_error = int(resp.get("status", 500)) >= 400
                self.result(request_id, self.tool_content(json.dumps(resp, indent=2), is_error=is_error))
                return

            if name == "n8n_set_workflow_active":
                workflow_id = str(arguments.get("id", "")).strip()
                active = arguments.get("active")
                if not workflow_id:
                    raise ValueError("id must not be empty")
                if not isinstance(active, bool):
                    raise ValueError("active must be boolean")

                route = "activate" if active else "deactivate"
                resp = self._request(
                    "POST",
                    f"/api/v1/workflows/{workflow_id}/{route}",
                    require_api_key=True,
                )

                if int(resp.get("status", 500)) == 404:
                    resp = self._request(
                        "PATCH",
                        f"/api/v1/workflows/{workflow_id}",
                        body={"active": active},
                        require_api_key=True,
                    )

                is_error = int(resp.get("status", 500)) >= 400
                self.result(request_id, self.tool_content(json.dumps(resp, indent=2), is_error=is_error))
                return

            self.error(request_id, -32601, f"Unknown tool: {name}")
        except Exception as exc:
            self.result(request_id, self.tool_content(str(exc), is_error=True))

    def run(self) -> None:
        while True:
            message = self.read_message()
            if message is None:
                return

            method = message.get("method")
            request_id = message.get("id")

            if method == "initialize":
                self.result(
                    request_id,
                    {
                        "protocolVersion": PROTOCOL_VERSION,
                        "serverInfo": {"name": "fortisai-n8n-mcp", "version": "1.0.0"},
                        "capabilities": {"tools": {}},
                    },
                )
            elif method == "notifications/initialized":
                continue
            elif method == "tools/list":
                self.result(request_id, self.tools())
            elif method == "tools/call":
                self.handle_tools_call(request_id, message.get("params") or {})
            elif method == "ping":
                self.result(request_id, {})
            else:
                self.error(request_id, -32601, f"Unknown method: {method}")


def main() -> int:
    N8nMcpServer().run()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())