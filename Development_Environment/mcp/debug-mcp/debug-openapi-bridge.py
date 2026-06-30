#!/usr/bin/env python3
import os
from urllib.error import URLError
from urllib.request import urlopen

from fastapi import FastAPI

app = FastAPI(title="FortisAI MCP Debug Bridge", version="0.1.0")

SQLCL_OPENAPI_URL = os.getenv(
    "DEBUG_SQLCL_OPENAPI_URL", "http://fortisai-mcp-openapi-sqlcl.fortisai.local:8091/openapi.json"
)
N8N_OPENAPI_URL = os.getenv(
    "DEBUG_N8N_OPENAPI_URL", "http://fortisai-mcp-openapi-n8n.fortisai.local:8092/openapi.json"
)
DIFY_OPENAPI_URL = os.getenv(
    "DEBUG_DIFY_OPENAPI_URL", "http://fortisai-mcp-openapi-dify.fortisai.local:8093/openapi.json"
)
BRIDGE_PORT = int(os.getenv("DEBUG_BRIDGE_PORT", "8094"))


def _probe(url: str) -> dict:
    try:
        with urlopen(url, timeout=5) as response:  # nosec B310
            return {"ok": True, "status": int(response.status)}
    except URLError as exc:
        return {"ok": False, "error": str(exc)}
    except Exception as exc:  # pragma: no cover
        return {"ok": False, "error": str(exc)}


@app.get("/healthz", include_in_schema=False)
def healthz() -> dict:
    return {"ok": True, "service": "fortisai-mcp-openapi-debug"}


@app.get("/debug_bridge_status")
def debug_bridge_status() -> dict:
    sqlcl = _probe(SQLCL_OPENAPI_URL)
    n8n = _probe(N8N_OPENAPI_URL)
    dify = _probe(DIFY_OPENAPI_URL)
    all_ok = bool(sqlcl.get("ok") and n8n.get("ok") and dify.get("ok"))

    return {
        "ok": all_ok,
        "targets": {
            "sqlcl": {"url": SQLCL_OPENAPI_URL, **sqlcl},
            "n8n": {"url": N8N_OPENAPI_URL, **n8n},
            "dify": {"url": DIFY_OPENAPI_URL, **dify},
        },
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=BRIDGE_PORT)
