#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import shlex
import subprocess
import sys
from pathlib import Path
from typing import Any, Dict, Optional

PROTOCOL_VERSION = "2024-11-05"
DEFAULT_SQLCL_CONTAINER = "fortisai-sqlcl"
DEFAULT_DEV_HOME = Path(os.environ.get("FORTISAI_DEV_HOME", Path.home() / "fortisai-dev"))
DEFAULT_WALLET_ENV = DEFAULT_DEV_HOME / "oracle-wallet" / "oracle-db.env"


def parse_env_file(path: Path) -> Dict[str, str]:
    values: Dict[str, str] = {}
    if not path.is_file():
        return values

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("export "):
            line = line[len("export ") :].strip()
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip('"').strip("'")
    return values


class SqlclMcpServer:
    def __init__(self) -> None:
        env_path = Path(os.environ.get("ORACLE_DB_WALLET_ENV_FILE", DEFAULT_WALLET_ENV))
        wallet_values = parse_env_file(env_path)

        self.wallet_env_file = env_path
        self.wallet_dir = Path(os.environ.get("ORACLE_WALLET_DIR", wallet_values.get("ORACLE_WALLET_DIR", env_path.parent)))
        self.oracle_db_host = os.environ.get("ORACLE_DB_HOST", wallet_values.get("ORACLE_DB_HOST", "fortisai-oracle-db"))
        self.oracle_db_port = os.environ.get("ORACLE_DB_PORT", wallet_values.get("ORACLE_DB_PORT", "1521"))
        self.oracle_db_service_name = os.environ.get("ORACLE_DB_SERVICE_NAME", wallet_values.get("ORACLE_DB_SERVICE_NAME", "FREEPDB1"))
        self.oracle_db_user = os.environ.get("ORACLE_DB_USER", wallet_values.get("ORACLE_DB_USER", "pdbadmin"))
        self.oracle_db_password = os.environ.get("ORACLE_DB_PASSWORD", wallet_values.get("ORACLE_DB_PASSWORD", ""))
        self.oracle_db_connect_string = os.environ.get(
            "ORACLE_DB_CONNECT_STRING",
            wallet_values.get("ORACLE_DB_CONNECT_STRING", f"localhost:{self.oracle_db_port}/{self.oracle_db_service_name}"),
        )
        self.sqlcl_container = os.environ.get("SQLCL_CONTAINER_NAME", DEFAULT_SQLCL_CONTAINER)

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

    def tools(self) -> Dict[str, Any]:
        return {
            "tools": [
                {
                    "name": "sqlcl_query",
                    "description": "Run a read-only SQL query through the SQLcl sidecar and return the raw output.",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "sql": {"type": "string", "description": "SQL SELECT or read-only statement to execute."},
                        },
                        "required": ["sql"],
                        "additionalProperties": False,
                    },
                },
                {
                    "name": "sqlcl_execute",
                    "description": "Run a SQL statement through the SQLcl sidecar and return the raw output.",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "sql": {"type": "string", "description": "SQL statement to execute."},
                        },
                        "required": ["sql"],
                        "additionalProperties": False,
                    },
                },
                {
                    "name": "sqlcl_connection_info",
                    "description": "Return the SQLcl sidecar connection details currently in use.",
                    "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False},
                },
            ]
        }

    def sqlcl_command(self, sql_text: str, readonly: bool = False) -> subprocess.CompletedProcess[str]:
        if not sql_text.strip():
            raise ValueError("sql must not be empty")

        runtime_connect_string = f"{self.oracle_db_host}:{self.oracle_db_port}/{self.oracle_db_service_name}"
        connect_string = f"{self.oracle_db_user}/{self.oracle_db_password}@{runtime_connect_string}"
        command = [
            "podman",
            "exec",
            "-i",
            self.sqlcl_container,
            "/bin/sh",
            "-lc",
            f"sql -L {shlex.quote(connect_string)}",
        ]

        sql_body = sql_text.strip()
        if not sql_body.endswith(";"):
            sql_body += ";"

        script = [
            "set echo off",
            "set feedback on",
            "set heading on",
            "set pagesize 50000",
            "set linesize 32767",
            "set trimspool on",
            "set tab off",
        ]
        if readonly:
            script.append("set serveroutput on")
        script.extend([sql_body, "exit"])

        return subprocess.run(
            command,
            input="\n".join(script) + "\n",
            text=True,
            capture_output=True,
            check=False,
        )

    def handle_tools_call(self, request_id: Any, params: Dict[str, Any]) -> None:
        name = params.get("name")
        arguments = params.get("arguments") or {}

        try:
            if name == "sqlcl_connection_info":
                self.result(
                    request_id,
                    self.tool_content(
                        json.dumps(
                            {
                                "wallet_env_file": str(self.wallet_env_file),
                                "wallet_dir": str(self.wallet_dir),
                                "sqlcl_container": self.sqlcl_container,
                                "oracle_db_host": self.oracle_db_host,
                                "oracle_db_port": self.oracle_db_port,
                                "oracle_db_service_name": self.oracle_db_service_name,
                                "oracle_db_user": self.oracle_db_user,
                                "oracle_db_connect_string": self.oracle_db_connect_string,
                            },
                            indent=2,
                        )
                    ),
                )
                return

            if name == "sqlcl_query":
                proc = self.sqlcl_command(str(arguments.get("sql", "")), readonly=True)
            elif name == "sqlcl_execute":
                proc = self.sqlcl_command(str(arguments.get("sql", "")), readonly=False)
            else:
                self.error(request_id, -32601, f"Unknown tool: {name}")
                return
        except Exception as exc:
            self.result(request_id, self.tool_content(str(exc), is_error=True))
            return

        output_parts = []
        if proc.stdout:
            output_parts.append(proc.stdout.rstrip())
        if proc.stderr:
            output_parts.append(proc.stderr.rstrip())
        output = "\n\n".join(part for part in output_parts if part)

        if proc.returncode != 0:
            self.result(request_id, self.tool_content(output or f"SQLcl exited with code {proc.returncode}", is_error=True))
            return

        self.result(request_id, self.tool_content(output or "SQLcl completed successfully."))

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
                        "serverInfo": {"name": "fortisai-sqlcl-mcp", "version": "1.0.0"},
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
    SqlclMcpServer().run()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
