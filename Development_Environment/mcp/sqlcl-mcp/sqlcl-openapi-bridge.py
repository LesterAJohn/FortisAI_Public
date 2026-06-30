#!/usr/bin/env python3
from __future__ import annotations

import os
from pathlib import Path
from typing import Any, Dict

import oracledb
import uvicorn
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel


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


DEFAULT_DEV_HOME = Path(os.environ.get("FORTISAI_DEV_HOME", Path.home() / "fortisai-dev"))
DEFAULT_WALLET_ENV = DEFAULT_DEV_HOME / "oracle-wallet" / "oracle-db.env"
wallet_values = parse_env_file(Path(os.environ.get("ORACLE_DB_WALLET_ENV_FILE", DEFAULT_WALLET_ENV)))

ORACLE_DB_HOST = os.environ.get("ORACLE_DB_HOST", wallet_values.get("ORACLE_DB_HOST", "fortisai-oracle-db"))
ORACLE_DB_PORT = os.environ.get("ORACLE_DB_PORT", wallet_values.get("ORACLE_DB_PORT", "1521"))
ORACLE_DB_SERVICE_NAME = os.environ.get("ORACLE_DB_SERVICE_NAME", wallet_values.get("ORACLE_DB_SERVICE_NAME", "FREEPDB1"))
ORACLE_DB_USER = os.environ.get("ORACLE_DB_USER", wallet_values.get("ORACLE_DB_USER", "pdbadmin"))
ORACLE_DB_PASSWORD = os.environ.get("ORACLE_DB_PASSWORD", wallet_values.get("ORACLE_DB_PASSWORD", ""))

app = FastAPI(title="fortisai-sqlcl-openapi-bridge", version="1.0.0")


class SqlRequest(BaseModel):
    sql: str


def run_sql(sql_text: str) -> Dict[str, Any]:
    if not sql_text.strip():
        raise ValueError("sql must not be empty")

    dsn = f"{ORACLE_DB_HOST}:{ORACLE_DB_PORT}/{ORACLE_DB_SERVICE_NAME}"
    conn = oracledb.connect(user=ORACLE_DB_USER, password=ORACLE_DB_PASSWORD, dsn=dsn)
    try:
        cursor = conn.cursor()
        cursor.execute(sql_text)

        if cursor.description:
            columns = [col[0] for col in cursor.description]
            rows = cursor.fetchmany(500)
            return {
                "ok": True,
                "type": "query",
                "columns": columns,
                "row_count": len(rows),
                "rows": rows,
            }

        conn.commit()
        return {
            "ok": True,
            "type": "execute",
            "rows_affected": cursor.rowcount,
        }
    finally:
        conn.close()


@app.get("/healthz", include_in_schema=False)
def healthz() -> Dict[str, str]:
    return {"status": "ok"}


@app.get("/sqlcl_connection_info")
def sqlcl_connection_info() -> Dict[str, Any]:
    return {
        "oracle_db_host": ORACLE_DB_HOST,
        "oracle_db_port": ORACLE_DB_PORT,
        "oracle_db_service_name": ORACLE_DB_SERVICE_NAME,
        "oracle_db_user": ORACLE_DB_USER,
    }


@app.post("/sqlcl_query")
def sqlcl_query(request: SqlRequest) -> Dict[str, Any]:
    try:
        result = run_sql(request.sql)
    except Exception as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    if not result["ok"]:
        raise HTTPException(status_code=500, detail=result)
    return result


@app.post("/sqlcl_execute")
def sqlcl_execute(request: SqlRequest) -> Dict[str, Any]:
    try:
        result = run_sql(request.sql)
    except Exception as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    if not result["ok"]:
        raise HTTPException(status_code=500, detail=result)
    return result


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("SQLCL_BRIDGE_PORT", "8091")))
