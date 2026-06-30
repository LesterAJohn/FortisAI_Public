#!/usr/bin/env python3
"""FortisAI Firecrawl Websearch OpenAPI bridge."""

from __future__ import annotations

import json
import os
import time
import urllib.error
import urllib.request
from typing import Any, Dict, List, Optional

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field


APP_NAME = "FortisAI Firecrawl Websearch Bridge"
FIRECRAWL_URL = os.environ.get("FIRECRAWL_INTERNAL_URL") or os.environ.get("FIRECRAWL_URL") or "http://fortisai-firecrawl.fortisai.local:3002"
FIRECRAWL_URL = FIRECRAWL_URL.rstrip("/")
FIRECRAWL_API_KEY = os.environ.get("FIRECRAWL_API_KEY", "")
BRIDGE_PORT = int(os.environ.get("WEBSEARCH_BRIDGE_PORT", "8097"))

app = FastAPI(
    title=APP_NAME,
    version="1.0.0",
    description="OpenAPI bridge for FortisAI web search through the Firecrawl pod.",
)


class WebSearchRequest(BaseModel):
    query: str = Field(..., description="Search query to run through Firecrawl.", min_length=1)
    limit: int = Field(5, ge=1, le=20, description="Maximum number of search results to return.")
    scrapeOptions: Dict[str, Any] = Field(
        default_factory=lambda: {"formats": ["markdown"], "onlyMainContent": True},
        description="Firecrawl search scrapeOptions payload.",
    )
    timeout_seconds: int = Field(60, ge=1, le=180, description="HTTP timeout for the Firecrawl request.")


class WebScrapeRequest(BaseModel):
    url: str = Field(..., description="URL to scrape with Firecrawl.", min_length=1)
    formats: List[str] = Field(default_factory=lambda: ["markdown"], description="Firecrawl output formats.")
    onlyMainContent: bool = Field(True, description="Request only the main page content.")
    timeout_seconds: int = Field(60, ge=1, le=180, description="HTTP timeout for the Firecrawl request.")


def _headers() -> Dict[str, str]:
    headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "User-Agent": "fortisai-websearch-openapi-bridge/1.0",
    }
    if FIRECRAWL_API_KEY:
        headers["Authorization"] = f"Bearer {FIRECRAWL_API_KEY}"
    return headers


def _json_request(path: str, payload: Optional[Dict[str, Any]] = None, timeout: int = 30) -> Dict[str, Any]:
    data = None if payload is None else json.dumps(payload).encode("utf-8")
    method = "GET" if payload is None else "POST"
    request = urllib.request.Request(
        f"{FIRECRAWL_URL}{path}",
        data=data,
        headers=_headers(),
        method=method,
    )

    started = time.monotonic()
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            body = response.read().decode("utf-8", errors="replace")
            status = getattr(response, "status", 200)
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        raise HTTPException(
            status_code=502,
            detail={
                "ok": False,
                "status": exc.code,
                "firecrawl_url": FIRECRAWL_URL,
                "path": path,
                "message": body[:2000],
            },
        ) from exc
    except Exception as exc:
        raise HTTPException(
            status_code=502,
            detail={
                "ok": False,
                "firecrawl_url": FIRECRAWL_URL,
                "path": path,
                "error": type(exc).__name__,
                "message": str(exc),
            },
        ) from exc

    try:
        parsed: Any = json.loads(body) if body else {}
    except json.JSONDecodeError:
        parsed = {"raw": body}

    if not isinstance(parsed, dict):
        parsed = {"data": parsed}

    parsed.setdefault("status", status)
    parsed.setdefault("elapsed_ms", round((time.monotonic() - started) * 1000, 2))
    return parsed


def _probe(path: str, timeout: int = 5) -> Dict[str, Any]:
    request = urllib.request.Request(f"{FIRECRAWL_URL}{path}", headers=_headers(), method="GET")
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            text = response.read().decode("utf-8", errors="replace")
            return {"ok": True, "status": getattr(response, "status", 200), "body_sample": text[:300]}
    except urllib.error.HTTPError as exc:
        text = exc.read().decode("utf-8", errors="replace")
        return {"ok": False, "status": exc.code, "body_sample": text[:300]}
    except Exception as exc:
        return {"ok": False, "status": 0, "error": type(exc).__name__, "message": str(exc)}


@app.get("/healthz", operation_id="websearch_healthz", summary="Bridge health check", include_in_schema=False)
def healthz() -> Dict[str, Any]:
    return {"ok": True, "service": "websearch", "firecrawl_url": FIRECRAWL_URL}


@app.get(
    "/websearch_connection_info",
    operation_id="websearch_connection_info",
    summary="Return Firecrawl bridge connection details and public health probes",
)
def websearch_connection_info() -> Dict[str, Any]:
    return {
        "ok": True,
        "bridge": "fortisai-mcp-openapi-websearch",
        "firecrawl_url": FIRECRAWL_URL,
        "has_firecrawl_api_key": bool(FIRECRAWL_API_KEY),
        "health_paths": {
            "/": _probe("/"),
            "/health": _probe("/health"),
            "/v0/health/liveness": _probe("/v0/health/liveness"),
            "/v0/health/readiness": _probe("/v0/health/readiness"),
        },
    }


@app.post("/websearch_search", operation_id="websearch_search", summary="Search the web through Firecrawl")
def websearch_search(request: WebSearchRequest) -> Dict[str, Any]:
    payload = {
        "query": request.query.strip(),
        "limit": request.limit,
        "scrapeOptions": request.scrapeOptions,
    }
    result = _json_request("/v1/search", payload=payload, timeout=request.timeout_seconds)
    data = result.get("data")
    result_count = len(data) if isinstance(data, list) else 0
    return {
        "ok": bool(result.get("success", True)),
        "status": result.get("status", 200),
        "query": payload["query"],
        "result_count": result_count,
        "firecrawl_url": FIRECRAWL_URL,
        "data": data,
        "raw": result,
    }


@app.post(
    "/websearch",
    operation_id="websearch",
    summary="Compatibility alias for websearch_search",
)
def websearch(request: WebSearchRequest) -> Dict[str, Any]:
    return websearch_search(request)


@app.post("/websearch_scrape", operation_id="websearch_scrape", summary="Scrape a URL through Firecrawl")
def websearch_scrape(request: WebScrapeRequest) -> Dict[str, Any]:
    payload = {
        "url": request.url.strip(),
        "formats": request.formats,
        "onlyMainContent": request.onlyMainContent,
    }
    result = _json_request("/v1/scrape", payload=payload, timeout=request.timeout_seconds)
    return {
        "ok": bool(result.get("success", True)),
        "status": result.get("status", 200),
        "url": payload["url"],
        "firecrawl_url": FIRECRAWL_URL,
        "data": result.get("data"),
        "raw": result,
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=BRIDGE_PORT)

