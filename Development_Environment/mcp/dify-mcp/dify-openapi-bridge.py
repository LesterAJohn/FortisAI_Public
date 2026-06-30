#!/usr/bin/env python3
from __future__ import annotations

import json
import logging
import os
import queue
import re
import ssl
import ast
import hashlib
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
from typing import Any, Dict, Literal, Optional

import uvicorn
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import StreamingResponse
from pydantic import BaseModel


def _normalize_coredns_base_url(url: str, default_url: str) -> str:
    """Force localhost-style URLs to use the FortisAI CoreDNS FQDN."""
    candidate = (url or "").strip()
    if not candidate:
        return default_url.rstrip("/")

    parsed = urllib.parse.urlparse(candidate)
    if parsed.hostname not in {"localhost", "127.0.0.1", "::1"}:
        return candidate.rstrip("/")

    default_parsed = urllib.parse.urlparse(default_url)
    scheme = parsed.scheme or default_parsed.scheme or "http"
    host = default_parsed.hostname or parsed.hostname or "localhost"
    port = parsed.port or default_parsed.port
    path = parsed.path or default_parsed.path or "/v1"
    netloc = host if not port else f"{host}:{port}"
    return urllib.parse.urlunparse((scheme, netloc, path, "", "", "")).rstrip("/")

DIFY_BASE_URL = os.environ.get("DIFY_BASE_URL", "http://docker_api_1.fortisai.local:5001").rstrip("/")
# Dify /v1 endpoints require an app API key. Keep ADMIN_API_KEY fallback for
# backward compatibility with existing helper scripts and env files.
DIFY_API_KEY = os.environ.get("DIFY_API_KEY", "").strip() or os.environ.get("ADMIN_API_KEY", "").strip()
DIFY_ADMIN_API_KEY = os.environ.get("DIFY_ADMIN_API_KEY", "").strip() or os.environ.get("ADMIN_API_KEY", "").strip()
DIFY_CONSOLE_ACCESS_TOKEN = os.environ.get("DIFY_CONSOLE_ACCESS_TOKEN", "").strip()
DIFY_ADMIN_WORKSPACE_ID = os.environ.get("DIFY_ADMIN_WORKSPACE_ID", "").strip()
DIFY_VERIFY_TLS = os.environ.get("DIFY_VERIFY_TLS", "true").strip().lower() in {"1", "true", "yes", "on"}
DIFY_TIMEOUT_SECONDS = int(os.environ.get("DIFY_TIMEOUT_SECONDS", "30"))
DIFY_DB_HOST = os.environ.get("DIFY_DB_HOST", "").strip()
DIFY_DB_PORT = int(os.environ.get("DIFY_DB_PORT", "5432"))
DIFY_DB_NAME = os.environ.get("DIFY_DB_NAME", "").strip()
DIFY_DB_USER = os.environ.get("DIFY_DB_USER", "").strip()
DIFY_DB_PASSWORD = os.environ.get("DIFY_DB_PASSWORD", "").strip()
_RESOLVED_ADMIN_WORKSPACE_ID = DIFY_ADMIN_WORKSPACE_ID

FORTISAI_OPENAI_ROUTER_MODEL = os.environ.get("FORTISAI_OPENAI_ROUTER_MODEL", "fortisai").strip() or "fortisai"
FORTISAI_OPENAI_ROUTER_APP_NAME = (
    os.environ.get("FORTISAI_OPENAI_ROUTER_APP_NAME", "local-openai-compatible-router").strip()
    or "local-openai-compatible-router"
)
FORTISAI_OPENAI_ROUTER_CLASSIFICATION_FILE = os.environ.get(
    "FORTISAI_OPENAI_ROUTER_CLASSIFICATION_FILE",
    "/workspace/Development_Environment/dify-config/main/dify/generated/local-llm-classification.generated.json",
).strip()
FORTISAI_LLAMA_OPENAI_BASE_URL = _normalize_coredns_base_url(
    os.environ.get(
        "FORTISAI_LLAMA_OPENAI_BASE_URL",
        "http://fortisai-llama-server.fortisai.local:8011/v1",
    ),
    "http://fortisai-llama-server.fortisai.local:8011/v1",
)
FORTISAI_LLAMA_OPENAI_API_KEY = os.environ.get("FORTISAI_LLAMA_OPENAI_API_KEY", "local-llama").strip()
FORTISAI_OPENAI_EMBEDDING_MODEL = os.environ.get("FORTISAI_OPENAI_EMBEDDING_MODEL", "").strip()
FORTISAI_OPENAI_ROUTER_TIMEOUT_SECONDS = max(
    int(os.environ.get("FORTISAI_OPENAI_ROUTER_TIMEOUT_SECONDS", "1800")),
    600,
)
FORTISAI_OPENAI_ROUTER_FORCE_LOAD_TIMEOUT_SECONDS = max(
    int(
        os.environ.get(
            "FORTISAI_OPENAI_ROUTER_FORCE_LOAD_TIMEOUT_SECONDS",
            str(FORTISAI_OPENAI_ROUTER_TIMEOUT_SECONDS),
        )
    ),
    FORTISAI_OPENAI_ROUTER_TIMEOUT_SECONDS,
    600,
)
FORTISAI_OPENAI_ROUTER_STREAM_KEEPALIVE_SECONDS = float(
    os.environ.get("FORTISAI_OPENAI_ROUTER_STREAM_KEEPALIVE_SECONDS", "10")
)
FORTISAI_OPENAI_ROUTER_DEFAULT_MAX_TOKENS = max(
    int(os.environ.get("FORTISAI_OPENAI_ROUTER_DEFAULT_MAX_TOKENS", "2048")),
    0,
)
FORTISAI_OPENAI_ROUTER_MAX_TOKENS_HARD_LIMIT = max(
    int(os.environ.get("FORTISAI_OPENAI_ROUTER_MAX_TOKENS_HARD_LIMIT", "3072")),
    0,
)
FORTISAI_CLINE_TOOL_GUARD_ENABLED = os.environ.get(
    "FORTISAI_CLINE_TOOL_GUARD_ENABLED",
    "true",
).strip().lower() in {"1", "true", "yes", "on"}
FORTISAI_CLINE_TOOL_MAX_TOKENS = max(int(os.environ.get("FORTISAI_CLINE_TOOL_MAX_TOKENS", "0")), 0)
FORTISAI_CLINE_RETRIEVAL_QUERY_CHARS = max(
    int(os.environ.get("FORTISAI_CLINE_RETRIEVAL_QUERY_CHARS", "1200")),
    0,
)
FORTISAI_CLINE_CONTEXT_LIMIT_CHARS = max(
    int(os.environ.get("FORTISAI_CLINE_CONTEXT_LIMIT_CHARS", "1600")),
    0,
)
FORTISAI_TOOL_EXECUTION_BRIDGE_ENABLED = os.environ.get(
    "FORTISAI_TOOL_EXECUTION_BRIDGE_ENABLED",
    "true",
).strip().lower() not in {"0", "false", "no", "off"}
FORTISAI_TOOL_EXECUTION_MAX_ROUNDS = max(int(os.environ.get("FORTISAI_TOOL_EXECUTION_MAX_ROUNDS", "1")), 0)
FORTISAI_TOOL_EXECUTION_TIMEOUT_SECONDS = max(float(os.environ.get("FORTISAI_TOOL_EXECUTION_TIMEOUT_SECONDS", "300")), 1.0)
FORTISAI_TOOL_EXECUTION_PREFLIGHT_LLM_TIMEOUT_SECONDS = max(
    float(os.environ.get("FORTISAI_TOOL_EXECUTION_PREFLIGHT_LLM_TIMEOUT_SECONDS", "300")),
    1.0,
)
FORTISAI_TOOL_EXECUTION_RESULT_LIMIT_CHARS = max(int(os.environ.get("FORTISAI_TOOL_EXECUTION_RESULT_LIMIT_CHARS", "12000")), 1000)
FORTISAI_TOOL_EXECUTION_REGISTRY_JSON = os.environ.get("FORTISAI_TOOL_EXECUTION_REGISTRY_JSON", "").strip()
FORTISAI_TOOL_EXECUTION_SKILL_DISCOVERY_ENABLED = os.environ.get(
    "FORTISAI_TOOL_EXECUTION_SKILL_DISCOVERY_ENABLED",
    "true",
).strip().lower() not in {"0", "false", "no", "off"}
FORTISAI_TOOL_EXECUTION_SKILL_ROOT = (
    os.environ.get("FORTISAI_TOOL_EXECUTION_SKILL_ROOT", "").strip()
    or "/workspace/Development_Environment/mcp"
)
FORTISAI_TOOL_EXECUTION_SKILL_REFRESH_SECONDS = max(
    float(os.environ.get("FORTISAI_TOOL_EXECUTION_SKILL_REFRESH_SECONDS", "300")),
    0.0,
)
FORTISAI_TOOL_EXECUTION_OPENAPI_FETCH_TIMEOUT_SECONDS = max(
    float(os.environ.get("FORTISAI_TOOL_EXECUTION_OPENAPI_FETCH_TIMEOUT_SECONDS", "5")),
    1.0,
)
FORTISAI_TOOL_EXECUTION_OPENWEBUI_SKILL_API_ENABLED = os.environ.get(
    "FORTISAI_TOOL_EXECUTION_OPENWEBUI_SKILL_API_ENABLED",
    "true",
).strip().lower() not in {"0", "false", "no", "off"}
_FORTISAI_OPENWEBUI_URL_ENV = (
    os.environ.get("FORTISAI_OPENWEBUI_URL", "").strip()
    or os.environ.get("OPENWEBUI_INTERNAL_URL", "").strip()
)
if not _FORTISAI_OPENWEBUI_URL_ENV:
    _FORTISAI_OPENWEBUI_URL_CANDIDATE = os.environ.get("OPENWEBUI_URL", "").strip()
    if _FORTISAI_OPENWEBUI_URL_CANDIDATE:
        _FORTISAI_OPENWEBUI_URL_HOST = urllib.parse.urlparse(_FORTISAI_OPENWEBUI_URL_CANDIDATE).hostname or ""
        if _FORTISAI_OPENWEBUI_URL_HOST not in {"localhost", "127.0.0.1", "::1"}:
            _FORTISAI_OPENWEBUI_URL_ENV = _FORTISAI_OPENWEBUI_URL_CANDIDATE
FORTISAI_OPENWEBUI_URL = (
    _FORTISAI_OPENWEBUI_URL_ENV
    or "http://fortisai-openwebui.fortisai.local:8080"
).rstrip("/")
FORTISAI_OPENWEBUI_DEFAULT_API_KEY_USER = os.environ.get(
    "FORTISAI_OPENWEBUI_DEFAULT_API_KEY_USER",
    "LesterAJohn@gmail.com",
).strip()
FORTISAI_VAULT_ADDR = (
    os.environ.get("FORTISAI_VAULT_ADDR", "").strip()
    or os.environ.get("VAULT_ADDR", "").strip()
).rstrip("/")
FORTISAI_VAULT_TOKEN = (
    os.environ.get("FORTISAI_VAULT_TOKEN", "").strip()
    or os.environ.get("VAULT_TOKEN", "").strip()
)
FORTISAI_WEBSEARCH_OPENAPI_BASE_URL = (
    os.environ.get("FORTISAI_WEBSEARCH_OPENAPI_BASE_URL", "").strip()
    or "http://fortisai-mcp-openapi-websearch.fortisai.local:8097"
).rstrip("/")
# Keep the FortisAI facade on the classified preferred model, even when another model is already loaded.
FORTISAI_OPENAI_ROUTER_PREFER_LOADED_MODELS = False
FORTISAI_OPENAI_ROUTER_MODEL_STATUS_TIMEOUT_SECONDS = float(
    os.environ.get("FORTISAI_OPENAI_ROUTER_MODEL_STATUS_TIMEOUT_SECONDS", "5")
)
FORTISAI_OPENAI_ROUTER_MODEL_STATUS_CACHE_SECONDS = float(
    os.environ.get("FORTISAI_OPENAI_ROUTER_MODEL_STATUS_CACHE_SECONDS", "15")
)
FORTISAI_HONCHO_DEFAULT_MODEL = "mistral__mistralai_Mistral-Small-3.2-24B-Instruct-2506-Q8_0"
FORTISAI_HONCHO_BASE_URL = (
    os.environ.get("FORTISAI_HONCHO_BASE_URL", "").strip()
    or os.environ.get("HONCHO_BASE_URL", "").strip()
    or "http://fortisai-honcho-api.fortisai.local:8000"
).rstrip("/")
FORTISAI_HONCHO_API_KEY = (
    os.environ.get("FORTISAI_HONCHO_API_KEY", "").strip()
    or os.environ.get("HONCHO_API_KEY", "").strip()
)
FORTISAI_HONCHO_REQUIRED = os.environ.get("FORTISAI_HONCHO_REQUIRED", "true").strip().lower() not in {
    "0",
    "false",
    "no",
    "off",
}
FORTISAI_HONCHO_WORKSPACE_ID = os.environ.get("FORTISAI_HONCHO_WORKSPACE_ID", "fortisai").strip() or "fortisai"
FORTISAI_HONCHO_ASSISTANT_PEER_ID = (
    os.environ.get("FORTISAI_HONCHO_ASSISTANT_PEER_ID", "fortisai_proxy").strip()
    or "fortisai_proxy"
)
FORTISAI_HONCHO_DEFAULT_USER_ID = (
    os.environ.get("FORTISAI_HONCHO_DEFAULT_USER_ID", "fortisai_default_user").strip()
    or "fortisai_default_user"
)
FORTISAI_HONCHO_DEFAULT_SESSION_ID = (
    os.environ.get("FORTISAI_HONCHO_DEFAULT_SESSION_ID", "default").strip()
    or "default"
)
FORTISAI_HONCHO_SESSION_SCOPE = (
    os.environ.get("FORTISAI_HONCHO_SESSION_SCOPE", "user").strip().lower()
    or "user"
)
if FORTISAI_HONCHO_SESSION_SCOPE not in {"user", "conversation"}:
    FORTISAI_HONCHO_SESSION_SCOPE = "user"
FORTISAI_HONCHO_MODEL = os.environ.get("FORTISAI_HONCHO_MODEL", FORTISAI_HONCHO_DEFAULT_MODEL).strip() or FORTISAI_HONCHO_DEFAULT_MODEL
FORTISAI_HONCHO_TIMEOUT_SECONDS = max(float(os.environ.get("FORTISAI_HONCHO_TIMEOUT_SECONDS", "10")), 1.0)
FORTISAI_HONCHO_CONTEXT_LIMIT_CHARS = max(int(os.environ.get("FORTISAI_HONCHO_CONTEXT_LIMIT_CHARS", "6000")), 0)
FORTISAI_HONCHO_CONTEXT_MAX_MESSAGES = max(int(os.environ.get("FORTISAI_HONCHO_CONTEXT_MAX_MESSAGES", "12")), 1)
FORTISAI_RAG_ENABLED = os.environ.get("FORTISAI_RAG_ENABLED", "true").strip().lower() not in {
    "0",
    "false",
    "no",
    "off",
}
FORTISAI_RAG_QDRANT_URL = (
    os.environ.get("FORTISAI_RAG_QDRANT_URL", "").strip()
    or os.environ.get("QDRANT_URL", "").strip()
    or os.environ.get("FORTISAI_QDRANT_URL", "").strip()
    or "http://qdrant.fortisai.local:6333"
).rstrip("/")
FORTISAI_RAG_QDRANT_API_KEY = (
    os.environ.get("FORTISAI_RAG_QDRANT_API_KEY", "").strip()
    or os.environ.get("QDRANT_API_KEY", "").strip()
)
FORTISAI_RAG_QDRANT_COLLECTION = (
    os.environ.get("FORTISAI_RAG_QDRANT_COLLECTION", "fortisai_general_knowledge").strip()
    or "fortisai_general_knowledge"
)
FORTISAI_TOOL_MEMORY_QDRANT_ENABLED = os.environ.get(
    "FORTISAI_TOOL_MEMORY_QDRANT_ENABLED",
    os.environ.get("FORTISAI_TOOL_REGISTRY_QDRANT_ENABLED", "true"),
).strip().lower() not in {"0", "false", "no", "off"}
FORTISAI_TOOL_MEMORY_QDRANT_COLLECTION = (
    os.environ.get("FORTISAI_TOOL_MEMORY_QDRANT_COLLECTION", "fortisai_tool_registry").strip()
    or "fortisai_tool_registry"
)
FORTISAI_TOOL_MEMORY_UPSERT_MAX = max(int(os.environ.get("FORTISAI_TOOL_MEMORY_UPSERT_MAX", "500")), 0)
FORTISAI_TOOL_MEMORY_SEARCH_LIMIT = max(int(os.environ.get("FORTISAI_TOOL_MEMORY_SEARCH_LIMIT", "8")), 0)
FORTISAI_TOOL_MEMORY_SCORE_THRESHOLD = float(os.environ.get("FORTISAI_TOOL_MEMORY_SCORE_THRESHOLD", "0.12"))
FORTISAI_DAYTONA_DEFAULT_SANDBOX = (
    os.environ.get("FORTISAI_DAYTONA_DEFAULT_SANDBOX", "fortisai-openwebui-smoke").strip()
    or "fortisai-openwebui-smoke"
)
FORTISAI_RAG_VECTOR_LIMIT = max(int(os.environ.get("FORTISAI_RAG_VECTOR_LIMIT", "5")), 0)
FORTISAI_RAG_VECTOR_SCORE_THRESHOLD = float(os.environ.get("FORTISAI_RAG_VECTOR_SCORE_THRESHOLD", "0.20"))
FORTISAI_RAG_CONTEXT_LIMIT_CHARS = max(int(os.environ.get("FORTISAI_RAG_CONTEXT_LIMIT_CHARS", "8000")), 0)
FORTISAI_RAG_EMBEDDING_BASE_URL = (
    _normalize_coredns_base_url(
        os.environ.get("FORTISAI_RAG_EMBEDDING_BASE_URL", ""),
        "http://fortisai-llama-server-secondary.fortisai.local:8012/v1",
    )
)
FORTISAI_RAG_EMBEDDING_API_KEY = (
    os.environ.get("FORTISAI_RAG_EMBEDDING_API_KEY", "").strip()
    or FORTISAI_LLAMA_OPENAI_API_KEY
)
FORTISAI_RAG_EMBEDDING_MODEL = os.environ.get("FORTISAI_RAG_EMBEDDING_MODEL", "").strip()
FORTISAI_RAG_EMBEDDING_INPUT_CHARS = max(int(os.environ.get("FORTISAI_RAG_EMBEDDING_INPUT_CHARS", "8000")), 256)
FORTISAI_RAG_FIRECRAWL_URL = (
    os.environ.get("FORTISAI_RAG_FIRECRAWL_URL", "").strip()
    or os.environ.get("FIRECRAWL_INTERNAL_URL", "").strip()
    or os.environ.get("FIRECRAWL_URL", "").strip()
    or "http://fortisai-firecrawl.fortisai.local:3002"
).rstrip("/")
FORTISAI_RAG_FIRECRAWL_API_KEY = (
    os.environ.get("FORTISAI_RAG_FIRECRAWL_API_KEY", "").strip()
    or os.environ.get("FIRECRAWL_API_KEY", "").strip()
)
FORTISAI_RAG_WEB_LIMIT = max(int(os.environ.get("FORTISAI_RAG_WEB_LIMIT", "3")), 0)
FORTISAI_RAG_WEB_TIMEOUT_SECONDS = max(float(os.environ.get("FORTISAI_RAG_WEB_TIMEOUT_SECONDS", "20")), 1.0)
FORTISAI_RAG_QUERY_CHARS = max(int(os.environ.get("FORTISAI_RAG_QUERY_CHARS", "600")), 64)
FORTISAI_RAG_UPSERT_WEB_RESULTS = os.environ.get("FORTISAI_RAG_UPSERT_WEB_RESULTS", "true").strip().lower() not in {
    "0",
    "false",
    "no",
    "off",
}
FORTISAI_RAG_BACKGROUND_WEB_UPSERT = os.environ.get("FORTISAI_RAG_BACKGROUND_WEB_UPSERT", "true").strip().lower() not in {
    "0",
    "false",
    "no",
    "off",
}
_ROUTER_CLASSIFICATION_CACHE: Dict[str, Any] = {}
_UPSTREAM_MODEL_STATUS_CACHE: Dict[str, Any] = {}
_BRIDGE_TOOL_REGISTRY_CACHE: Dict[str, Any] = {"expires_at": 0.0, "registry": {}, "registries": {}}

app = FastAPI(title="fortisai-dify-openapi-bridge", version="1.0.0")
_LOG_LEVEL_NAME = os.environ.get("FORTISAI_DIFY_BRIDGE_LOG_LEVEL", "INFO").strip().upper() or "INFO"
_LOG_LEVEL = getattr(logging, _LOG_LEVEL_NAME, logging.INFO)
logging.basicConfig(
    level=_LOG_LEVEL,
    format="%(asctime)s %(levelname)s %(name)s: %(message)s",
)
log = logging.getLogger("fortisai-dify-openapi-bridge")
log.setLevel(_LOG_LEVEL)


def _elapsed_ms(started_at: float) -> int:
    return int(round((time.monotonic() - started_at) * 1000))


def _route_timings(route_info: Dict[str, Any]) -> Dict[str, Any]:
    timings = route_info.setdefault("timings_ms", {})
    if not isinstance(timings, dict):
        timings = {}
        route_info["timings_ms"] = timings
    return timings


class ApiRequest(BaseModel):
    method: str
    path: str
    query: Optional[Dict[str, Any]] = None
    body: Optional[Dict[str, Any]] = None
    headers: Optional[Dict[str, str]] = None
    authMode: Literal["auto", "app", "admin", "console", "none"] = "auto"
    requireApiKey: bool = True


class ChatMessageRequest(BaseModel):
    inputs: Dict[str, Any] = {}
    query: str
    response_mode: str = "blocking"
    user: str = "openwebui"
    conversation_id: Optional[str] = None
    files: Optional[list[Dict[str, Any]]] = None


class OpenAiCompatibleModelSetupRequest(BaseModel):
    provider: str = "langgenius/openai_api_compatible/openai_api_compatible"
    models: list[str]
    modelType: str = "llm"
    templateModel: Optional[str] = None
    pruneStale: bool = False
    managedCredentialName: str = "FortisAI local"


def normalize_dify_path(path: str) -> str:
    clean_path = path if path.startswith("/") else f"/{path}"

    aliases = {
        "/info": "/v1/parameters",
        "/v1/info": "/v1/parameters",
        "/apps": "/v1/parameters",
        "/v1/apps": "/v1/parameters",
        "/chat": "/v1/chat-messages",
        "/v1/chat": "/v1/chat-messages",
    }

    if clean_path in aliases:
        return aliases[clean_path]

    # Most Dify app API calls are versioned under /v1. If a caller omits the prefix,
    # add it automatically for common top-level resources.
    if clean_path.startswith("/") and not clean_path.startswith("/v1/"):
        first_segment = clean_path.split("/", 2)[1] if len(clean_path.split("/")) > 1 else ""
        if first_segment in {
            "chat-messages",
            "completion-messages",
            "workflows",
            "parameters",
            "messages",
            "conversations",
            "meta",
            "audio-to-text",
            "text-to-audio",
            "files",
        }:
            return f"/v1{clean_path}"

    return clean_path


def resolve_auth_mode(path: str, auth_mode: str) -> str:
    if auth_mode != "auto":
        return auth_mode

    clean_path = normalize_dify_path(path)
    if clean_path.startswith("/console/api/admin"):
        return "admin"
    if clean_path.startswith("/console/api/"):
        return "admin"
    if clean_path.startswith("/v1/"):
        return "app"
    return "none"


def discover_admin_workspace_id() -> str:
    global _RESOLVED_ADMIN_WORKSPACE_ID

    if _RESOLVED_ADMIN_WORKSPACE_ID:
        return _RESOLVED_ADMIN_WORKSPACE_ID
    if not DIFY_ADMIN_API_KEY:
        return ""

    url = f"{DIFY_BASE_URL}/console/api/workspaces"
    req_headers = {
        "Accept": "application/json",
        "Authorization": f"Bearer {DIFY_ADMIN_API_KEY}",
    }
    request = urllib.request.Request(url=url, headers=req_headers, method="GET")
    context = None
    if not DIFY_VERIFY_TLS and url.startswith("https://"):
        context = ssl._create_unverified_context()

    try:
        with urllib.request.urlopen(request, timeout=DIFY_TIMEOUT_SECONDS, context=context) as response:
            raw = response.read().decode("utf-8", errors="replace")
            parsed = json.loads(raw) if raw else {}
            workspaces = parsed.get("workspaces") if isinstance(parsed, dict) else None
            if isinstance(workspaces, list) and workspaces:
                current = next((w for w in workspaces if isinstance(w, dict) and w.get("current") is True), None)
                target = current or next((w for w in workspaces if isinstance(w, dict) and w.get("id")), None)
                if isinstance(target, dict) and target.get("id"):
                    _RESOLVED_ADMIN_WORKSPACE_ID = str(target.get("id")).strip()
                    log.info("Resolved Dify admin workspace id via /console/api/workspaces")
                    return _RESOLVED_ADMIN_WORKSPACE_ID
    except Exception as exc:
        log.warning("Could not auto-resolve Dify admin workspace id: %s", exc)

    return ""


def headers(path: str, auth_mode: str, require_api_key: bool) -> Dict[str, str]:
    result = {
        "Accept": "application/json",
    }

    resolved_auth_mode = resolve_auth_mode(path=path, auth_mode=auth_mode)
    if resolved_auth_mode == "app":
        if DIFY_API_KEY:
            result["Authorization"] = f"Bearer {DIFY_API_KEY}"
        elif require_api_key:
            raise ValueError("DIFY_API_KEY is not set for app mode")
    elif resolved_auth_mode == "admin":
        if DIFY_ADMIN_API_KEY:
            result["Authorization"] = f"Bearer {DIFY_ADMIN_API_KEY}"
            workspace_id = discover_admin_workspace_id()
            if workspace_id:
                result["X-WORKSPACE-ID"] = workspace_id
        elif require_api_key:
            raise ValueError("DIFY_ADMIN_API_KEY is not set for admin mode")
    elif resolved_auth_mode == "console":
        if DIFY_CONSOLE_ACCESS_TOKEN:
            result["Authorization"] = f"Bearer {DIFY_CONSOLE_ACCESS_TOKEN}"
        elif require_api_key:
            raise ValueError("DIFY_CONSOLE_ACCESS_TOKEN is not set for console mode")

    return result


def dify_request(
    method: str,
    path: str,
    query: Optional[Dict[str, Any]] = None,
    body: Optional[Dict[str, Any]] = None,
    request_headers: Optional[Dict[str, str]] = None,
    auth_mode: str = "auto",
    require_api_key: bool = False,
) -> Dict[str, Any]:
    clean_path = normalize_dify_path(path)
    url = f"{DIFY_BASE_URL}{clean_path}"

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
    req_headers = headers(path=clean_path, auth_mode=auth_mode, require_api_key=require_api_key)
    if request_headers:
        req_headers.update(request_headers)
    if body is not None:
        data_bytes = json.dumps(body).encode("utf-8")
        req_headers["Content-Type"] = "application/json"

    request = urllib.request.Request(url=url, data=data_bytes, headers=req_headers, method=method.upper())
    context = None
    if not DIFY_VERIFY_TLS and url.startswith("https://"):
        context = ssl._create_unverified_context()

    try:
        with urllib.request.urlopen(request, timeout=DIFY_TIMEOUT_SECONDS, context=context) as response:
            raw = response.read().decode("utf-8", errors="replace")
            parsed: Any = raw
            if raw:
                try:
                    parsed = json.loads(raw)
                except json.JSONDecodeError:
                    parsed = raw
            return {
                "status": response.status,
                "path": clean_path,
                "auth_mode": resolve_auth_mode(path=clean_path, auth_mode=auth_mode),
                "body": parsed,
            }
    except urllib.error.HTTPError as exc:
        raw = exc.read().decode("utf-8", errors="replace")
        parsed: Any = raw
        if raw:
            try:
                parsed = json.loads(raw)
            except json.JSONDecodeError:
                parsed = raw
        log.warning("Dify HTTP error: method=%s path=%s status=%s", method.upper(), clean_path, exc.code)
        return {
            "status": exc.code,
            "path": clean_path,
            "auth_mode": resolve_auth_mode(path=clean_path, auth_mode=auth_mode),
            "body": parsed,
        }


def load_router_classification() -> Dict[str, Any]:
    path = FORTISAI_OPENAI_ROUTER_CLASSIFICATION_FILE
    if not path:
        return {}

    try:
        stat = os.stat(path)
    except FileNotFoundError:
        return {}
    except Exception as exc:
        log.warning("Could not stat FortisAI router classification file %s: %s", path, exc)
        return {}

    if (
        _ROUTER_CLASSIFICATION_CACHE.get("path") == path
        and _ROUTER_CLASSIFICATION_CACHE.get("mtime") == stat.st_mtime
        and isinstance(_ROUTER_CLASSIFICATION_CACHE.get("data"), dict)
    ):
        return _ROUTER_CLASSIFICATION_CACHE["data"]

    try:
        with open(path, "r", encoding="utf-8") as handle:
            parsed = json.load(handle)
    except Exception as exc:
        log.warning("Could not load FortisAI router classification file %s: %s", path, exc)
        return {}

    if not isinstance(parsed, dict):
        return {}

    _ROUTER_CLASSIFICATION_CACHE.clear()
    _ROUTER_CLASSIFICATION_CACHE.update({"path": path, "mtime": stat.st_mtime, "data": parsed})
    return parsed


def _route_entries(config: Dict[str, Any]) -> list[Dict[str, Any]]:
    routes = config.get("routes")
    if isinstance(routes, list):
        return [route for route in routes if isinstance(route, dict)]
    if isinstance(routes, dict):
        result: list[Dict[str, Any]] = []
        for key, value in routes.items():
            if isinstance(value, dict):
                route = dict(value)
                route.setdefault("route", key)
                result.append(route)
        return result
    return []


def _router_model_ids(config: Dict[str, Any]) -> list[str]:
    models = config.get("models")
    result: list[str] = []
    seen: set[str] = set()
    if not isinstance(models, list):
        return result

    for item in models:
        if isinstance(item, str):
            model_id = item.strip()
        elif isinstance(item, dict):
            model_id = str(
                item.get("model_id")
                or item.get("id")
                or item.get("model")
                or item.get("name")
                or ""
            ).strip()
            if item.get("enabled") is False or item.get("disabled") is True or item.get("runnable") is False:
                continue
        else:
            continue
        if model_id and model_id not in seen:
            seen.add(model_id)
            result.append(model_id)
    return result


def _normalize_hint_list(raw_value: Any) -> list[str]:
    if isinstance(raw_value, str):
        return [raw_value]
    if isinstance(raw_value, list):
        return [str(item).strip() for item in raw_value if str(item).strip()]
    return []


def _text_has_phrase(text: str, phrase: str) -> bool:
    clean_phrase = " ".join(str(phrase or "").strip().lower().split())
    if not clean_phrase:
        return False

    # Treat model-routing hints as tokens/phrases, not arbitrary substrings.
    # This prevents false positives such as "script" inside "transcript" or
    # "api" inside "capital".
    tokens = re.findall(r"[a-z0-9]+", clean_phrase)
    if not tokens:
        return False
    pattern = r"\b" + r"[\W_]+".join(re.escape(token) for token in tokens) + r"\b"
    return re.search(pattern, text, flags=re.IGNORECASE) is not None


def _route_label(route: Dict[str, Any]) -> str:
    return str(
        route.get("route")
        or route.get("id")
        or route.get("name")
        or route.get("request_type")
        or route.get("label")
        or "default"
    ).strip()


def _route_model_candidates(route: Dict[str, Any]) -> list[str]:
    candidates: list[str] = []
    for key in ("primary_model", "model", "target_model", "default_model"):
        value = str(route.get(key) or "").strip()
        if value:
            candidates.append(value)

    for key in ("fallback_models", "fallbacks", "fallback_model"):
        value = route.get(key)
        if isinstance(value, str):
            candidates.append(value.strip())
        elif isinstance(value, list):
            candidates.extend(str(item).strip() for item in value if str(item).strip())

    result: list[str] = []
    seen: set[str] = set()
    for model in candidates:
        if model and model not in seen:
            seen.add(model)
            result.append(model)
    return result


def _route_required_capabilities(route: Dict[str, Any]) -> list[str]:
    return _normalize_hint_list(route.get("required_capabilities")) + _normalize_hint_list(route.get("capabilities_required"))


def _route_force_model_load(route: Dict[str, Any]) -> bool:
    value = route.get("force_model_load")
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        return value.strip().lower() in {"1", "true", "yes", "on", "force", "required"}
    return _route_label(route) == "agentic_tool_use"


def _select_available_model(candidates: list[str], available_models: list[str]) -> str:
    available = set(available_models)
    for model in candidates:
        if not available or model in available:
            return model
    return available_models[0] if available_models else ""


def _local_openai_model_statuses() -> Dict[str, str]:
    now = time.monotonic()
    cached_statuses = _UPSTREAM_MODEL_STATUS_CACHE.get("statuses")
    cached_at = float(_UPSTREAM_MODEL_STATUS_CACHE.get("cached_at") or 0)
    if (
        _UPSTREAM_MODEL_STATUS_CACHE.get("base_url") == FORTISAI_LLAMA_OPENAI_BASE_URL
        and isinstance(cached_statuses, dict)
        and now - cached_at <= FORTISAI_OPENAI_ROUTER_MODEL_STATUS_CACHE_SECONDS
    ):
        return cached_statuses

    url = f"{FORTISAI_LLAMA_OPENAI_BASE_URL}/models"
    request = urllib.request.Request(url=url, headers=_openai_upstream_headers(), method="GET")
    try:
        with urllib.request.urlopen(
            request,
            timeout=FORTISAI_OPENAI_ROUTER_MODEL_STATUS_TIMEOUT_SECONDS,
        ) as response:
            parsed = _parse_upstream_body(response.read())
    except Exception as exc:
        log.warning("Could not load local OpenAI model statuses from %s: %s", url, exc)
        if isinstance(cached_statuses, dict):
            return cached_statuses
        return {}

    statuses: Dict[str, str] = {}
    data = parsed.get("data") if isinstance(parsed, dict) else None
    if isinstance(data, list):
        for item in data:
            if not isinstance(item, dict):
                continue
            model_id = str(item.get("id") or "").strip()
            if not model_id:
                continue
            raw_status = item.get("status")
            if isinstance(raw_status, dict):
                status = str(raw_status.get("value") or "unknown").strip() or "unknown"
            else:
                status = str(raw_status or "unknown").strip() or "unknown"
            statuses[model_id] = status

    _UPSTREAM_MODEL_STATUS_CACHE.clear()
    _UPSTREAM_MODEL_STATUS_CACHE.update(
        {
            "base_url": FORTISAI_LLAMA_OPENAI_BASE_URL,
            "cached_at": now,
            "statuses": statuses,
        }
    )
    return statuses


def _extract_content_text(content: Any) -> str:
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts: list[str] = []
        for item in content:
            if isinstance(item, str):
                parts.append(item)
            elif isinstance(item, dict):
                if item.get("type") in {"text", "input_text"} and item.get("text"):
                    parts.append(str(item.get("text")))
                elif item.get("text"):
                    parts.append(str(item.get("text")))
                elif item.get("content"):
                    parts.append(_extract_content_text(item.get("content")))
        return "\n".join(part for part in parts if part)
    if isinstance(content, dict):
        if content.get("text"):
            return str(content.get("text"))
        if content.get("content"):
            return _extract_content_text(content.get("content"))
    return str(content) if content is not None else ""


def _extract_chat_text(payload: Dict[str, Any]) -> str:
    messages = payload.get("messages")
    if not isinstance(messages, list):
        return ""

    parts: list[str] = []
    for message in messages:
        if not isinstance(message, dict):
            continue
        role = str(message.get("role") or "").strip()
        content = _extract_content_text(message.get("content"))
        if not content:
            continue
        if role:
            parts.append(f"{role}: {content}")
        else:
            parts.append(content)
    return "\n".join(parts)


def _strip_openwebui_generated_tool_instructions(text: str) -> str:
    """Remove OpenWebUI-generated tool instruction blocks before bridge heuristics."""
    raw = str(text or "")
    if not raw:
        return ""

    generated_markers = [
        "You have access to a Python code interpreter via:",
        "This Python environment runs via Pyodide",
        "User-uploaded files are available at /mnt/uploads/",
        "Do NOT use triple backticks",
        "Always print meaningful outputs",
    ]
    marker_positions = [raw.find(marker) for marker in generated_markers if raw.find(marker) >= 0]
    if not marker_positions:
        return raw.strip()

    first_marker = min(marker_positions)
    header_positions: list[int] = []
    for header in ("Code Interpreter", "Pyodide Environment", "Persistent File System"):
        pattern = re.compile(rf"(?im)^[ \t]*{re.escape(header)}[ \t]*$")
        for match in pattern.finditer(raw):
            if match.start() <= first_marker:
                header_positions.append(match.start())

    cut_at = min(header_positions) if header_positions else first_marker
    return raw[:cut_at].strip()


def _extract_tool_intent_text(payload: Dict[str, Any]) -> str:
    prompt_text = _extract_last_user_text(payload) or _extract_chat_text(payload)
    return _strip_openwebui_generated_tool_instructions(prompt_text)


def _normalize_chat_messages_for_upstream(payload: Dict[str, Any]) -> tuple[Dict[str, Any], bool]:
    """Merge system/developer messages into one leading system message for strict chat templates."""
    messages = payload.get("messages")
    if not isinstance(messages, list):
        return dict(payload), False

    seen_non_system = False
    system_count = 0
    needs_normalization = False
    for message in messages:
        if not isinstance(message, dict):
            seen_non_system = True
            continue
        raw_role = str(message.get("role") or "").strip()
        role = raw_role.lower()
        if role in {"system", "developer"}:
            system_count += 1
            if role == "developer" or raw_role != "system" or seen_non_system or system_count > 1:
                needs_normalization = True
        else:
            seen_non_system = True

    if not needs_normalization:
        return dict(payload), False

    system_parts: list[str] = []
    normalized_messages: list[Any] = []
    for message in messages:
        if not isinstance(message, dict):
            normalized_messages.append(message)
            continue
        role = str(message.get("role") or "").strip().lower()
        if role in {"system", "developer"}:
            content = _extract_content_text(message.get("content")).strip()
            if content:
                system_parts.append(content)
            continue
        normalized_messages.append(dict(message))

    if system_parts:
        normalized_messages.insert(0, {"role": "system", "content": "\n\n".join(system_parts)})

    normalized = dict(payload)
    normalized["messages"] = normalized_messages
    return normalized, True


CLINE_TOOL_GUARD_MESSAGE = (
    "Cline tool-use guard: when you use Cline's execute_command tool, always include "
    "the required requires_approval parameter. Use <requires_approval>true</requires_approval> "
    "unless the user's instructions and Cline policy explicitly allow the command to run without approval. "
    "Never emit an execute_command tool call with requires_approval omitted."
)


def _looks_like_cline_request(payload: Dict[str, Any], prompt_text: str) -> bool:
    if not FORTISAI_CLINE_TOOL_GUARD_ENABLED:
        return False
    if _payload_has_cline_execute_command_tool(payload):
        return True
    text = f"{prompt_text}\n{_extract_preview_text(payload)}".lower()
    if "cline" in text:
        return True
    if "execute_command" in text and "requires_approval" in text:
        return True
    return "<execute_command" in text or "execute command" in text


def _function_name_from_tool_def(tool_def: Any) -> str:
    if not isinstance(tool_def, dict):
        return ""
    function_def = tool_def.get("function")
    if isinstance(function_def, dict):
        return str(function_def.get("name") or "").strip()
    return str(tool_def.get("name") or "").strip()


def _payload_has_cline_execute_command_tool(payload: Dict[str, Any]) -> bool:
    for field in ("tools", "functions"):
        items = payload.get(field)
        if not isinstance(items, list):
            continue
        for item in items:
            if _function_name_from_tool_def(item) == "execute_command":
                return True
    return False


def _enforce_cline_execute_command_schema(payload: Dict[str, Any]) -> tuple[Dict[str, Any], bool]:
    if not FORTISAI_CLINE_TOOL_GUARD_ENABLED:
        return dict(payload), False

    enriched = dict(payload)
    changed = False
    for field in ("tools", "functions"):
        items = payload.get(field)
        if not isinstance(items, list):
            continue
        patched_items: list[Any] = []
        for item in items:
            if not isinstance(item, dict) or _function_name_from_tool_def(item) != "execute_command":
                patched_items.append(item)
                continue

            item_copy = dict(item)
            function_def = item_copy.get("function")
            if isinstance(function_def, dict):
                function_copy = dict(function_def)
                item_copy["function"] = function_copy
            else:
                function_copy = item_copy

            parameters = function_copy.get("parameters")
            if not isinstance(parameters, dict):
                parameters = {"type": "object", "properties": {}, "required": []}
            else:
                parameters = dict(parameters)
            properties = parameters.get("properties")
            if not isinstance(properties, dict):
                properties = {}
            else:
                properties = dict(properties)
            approval_schema = properties.get("requires_approval")
            if not isinstance(approval_schema, dict):
                approval_schema = {}
            else:
                approval_schema = dict(approval_schema)
            approval_schema.setdefault("type", "boolean")
            approval_schema.setdefault("default", True)
            approval_schema.setdefault(
                "description",
                "Required by Cline. Set true unless the command is explicitly allowed to run without approval.",
            )
            properties["requires_approval"] = approval_schema
            parameters["properties"] = properties

            required = parameters.get("required")
            if not isinstance(required, list):
                required = []
            if "requires_approval" not in required:
                required = list(required) + ["requires_approval"]
            parameters["required"] = required
            function_copy["parameters"] = parameters
            patched_items.append(item_copy)
            changed = True

        if changed:
            enriched[field] = patched_items

    return enriched, changed


def _normalize_openai_tool_def_for_upstream(tool_def: Any) -> tuple[Any, bool]:
    if not isinstance(tool_def, dict):
        return tool_def, False

    function_def = tool_def.get("function")
    if isinstance(function_def, dict):
        function_copy = dict(function_def)
        if "strict" in tool_def and "strict" not in function_copy:
            function_copy["strict"] = tool_def["strict"]
        if not isinstance(function_copy.get("parameters"), dict):
            input_schema = tool_def.get("input_schema")
            function_copy["parameters"] = (
                input_schema if isinstance(input_schema, dict) else {"type": "object", "properties": {}}
            )
        normalized = {"type": "function", "function": function_copy}
        return normalized, normalized != tool_def

    tool_type = str(tool_def.get("type") or "").strip()
    if tool_type and tool_type != "function":
        return tool_def, False

    name = str(tool_def.get("name") or "").strip()
    if not name:
        return tool_def, False

    parameters = tool_def.get("parameters")
    if not isinstance(parameters, dict):
        input_schema = tool_def.get("input_schema")
        parameters = input_schema if isinstance(input_schema, dict) else {"type": "object", "properties": {}}

    function_payload: Dict[str, Any] = {
        "name": name,
        "description": str(tool_def.get("description") or ""),
        "parameters": parameters,
    }
    if "strict" in tool_def:
        function_payload["strict"] = tool_def["strict"]

    return {"type": "function", "function": function_payload}, True


def _normalize_openai_tools_for_upstream(payload: Dict[str, Any]) -> tuple[Dict[str, Any], Dict[str, Any]]:
    normalized = dict(payload)
    info: Dict[str, Any] = {
        "changed": False,
        "flat_tools_converted": 0,
        "legacy_functions_converted": 0,
        "dict_tools_wrapped": 0,
    }

    tools = payload.get("tools")
    if isinstance(tools, list):
        normalized_tools: list[Any] = []
        for tool in tools:
            normalized_tool, changed = _normalize_openai_tool_def_for_upstream(tool)
            normalized_tools.append(normalized_tool)
            if changed:
                info["flat_tools_converted"] += 1
        if info["flat_tools_converted"]:
            normalized["tools"] = normalized_tools
            info["changed"] = True
    elif isinstance(tools, dict):
        normalized_tool, changed = _normalize_openai_tool_def_for_upstream(tools)
        if isinstance(normalized_tool, dict) and isinstance(normalized_tool.get("function"), dict):
            normalized["tools"] = [normalized_tool]
            info["dict_tools_wrapped"] = 1
            if changed:
                info["flat_tools_converted"] = 1
            info["changed"] = True

    if "tools" not in normalized:
        functions = payload.get("functions")
        if isinstance(functions, list) and functions:
            converted_tools: list[Any] = []
            converted_count = 0
            for function_def in functions:
                normalized_tool, changed = _normalize_openai_tool_def_for_upstream(function_def)
                converted_tools.append(normalized_tool)
                if changed:
                    converted_count += 1
            if converted_tools and converted_count == len(converted_tools):
                normalized["tools"] = converted_tools
                normalized.pop("functions", None)
                info["legacy_functions_converted"] = converted_count
                info["changed"] = True

                function_call = normalized.pop("function_call", None)
                if "tool_choice" not in normalized:
                    if isinstance(function_call, str) and function_call.strip().lower() in {"auto", "none"}:
                        normalized["tool_choice"] = function_call.strip().lower()
                    elif isinstance(function_call, dict):
                        choice_name = str(function_call.get("name") or "").strip()
                        if choice_name:
                            normalized["tool_choice"] = {"type": "function", "function": {"name": choice_name}}

    return normalized, info


def _inject_cline_tool_guard(
    endpoint_path: str,
    payload: Dict[str, Any],
    prompt_text: str,
) -> tuple[Dict[str, Any], bool, bool]:
    if not _looks_like_cline_request(payload, prompt_text):
        return dict(payload), False, False

    enriched, schema_enforced = _enforce_cline_execute_command_schema(payload)
    if endpoint_path == "/chat/completions":
        raw_messages = enriched.get("messages")
        messages: list[Any] = raw_messages if isinstance(raw_messages, list) else []
        enriched["messages"] = [{"role": "system", "content": CLINE_TOOL_GUARD_MESSAGE}] + messages
        return enriched, True, schema_enforced
    if endpoint_path == "/completions":
        prompt = enriched.get("prompt")
        prefix = f"{CLINE_TOOL_GUARD_MESSAGE}\n\n"
        if isinstance(prompt, list):
            enriched["prompt"] = [f"{prefix}{_extract_content_text(item)}" for item in prompt]
        else:
            enriched["prompt"] = f"{prefix}{_extract_content_text(prompt)}"
        return enriched, True, schema_enforced

    return enriched, True, schema_enforced


def _extract_completion_text(payload: Dict[str, Any]) -> str:
    prompt = payload.get("prompt")
    if isinstance(prompt, list):
        return "\n".join(_extract_content_text(item) for item in prompt)
    return _extract_content_text(prompt)


def _first_non_empty(*values: Any) -> str:
    for value in values:
        if value is None:
            continue
        text = str(value).strip()
        if text:
            return text
    return ""


def _request_header(http_request: Optional[Request], *names: str) -> str:
    if http_request is None:
        return ""
    for name in names:
        value = http_request.headers.get(name)
        if value:
            return str(value).strip()
    return ""


def _honcho_safe_id(prefix: str, raw_value: Any, add_prefix: bool = True) -> str:
    raw_text = str(raw_value or "").strip() or "default"
    cleaned = re.sub(r"[^A-Za-z0-9_-]+", "_", raw_text).strip("_-") or "default"
    if add_prefix and not cleaned.startswith(f"{prefix}_"):
        cleaned = f"{prefix}_{cleaned}"
    if len(cleaned) <= 512:
        return cleaned
    digest = hashlib.sha256(cleaned.encode("utf-8")).hexdigest()[:16]
    suffix_len = max(1, 512 - len(prefix) - len(digest) - 3)
    return f"{prefix}_{digest}_{cleaned[-suffix_len:]}"


def _honcho_json_summary(value: Any, limit: int = 500) -> str:
    if isinstance(value, str):
        text = value
    else:
        try:
            text = json.dumps(value, ensure_ascii=False, separators=(",", ":"))
        except Exception:
            text = str(value)
    if len(text) > limit:
        return f"{text[:limit]}..."
    return text


def _honcho_headers() -> Dict[str, str]:
    result = {
        "Accept": "application/json",
    }
    if FORTISAI_HONCHO_API_KEY:
        result["Authorization"] = f"Bearer {FORTISAI_HONCHO_API_KEY}"
    return result


def _honcho_request(
    method: str,
    path: str,
    body: Optional[Dict[str, Any]] = None,
    expected_statuses: tuple[int, ...] = (200, 201, 204),
) -> Any:
    if not FORTISAI_HONCHO_BASE_URL:
        raise RuntimeError("FORTISAI_HONCHO_BASE_URL is not configured")

    url = f"{FORTISAI_HONCHO_BASE_URL}{path}"
    req_headers = _honcho_headers()
    data_bytes = None
    if body is not None:
        data_bytes = json.dumps(body).encode("utf-8")
        req_headers["Content-Type"] = "application/json"

    request = urllib.request.Request(url=url, data=data_bytes, headers=req_headers, method=method.upper())
    try:
        with urllib.request.urlopen(request, timeout=FORTISAI_HONCHO_TIMEOUT_SECONDS) as response:
            raw = response.read()
            if response.status not in expected_statuses:
                raise RuntimeError(f"Honcho HTTP {response.status} for {method.upper()} {path}")
            return _parse_upstream_body(raw)
    except urllib.error.HTTPError as exc:
        raw = exc.read()
        parsed = _parse_upstream_body(raw)
        if exc.code in expected_statuses:
            return parsed
        raise RuntimeError(
            f"Honcho HTTP {exc.code} for {method.upper()} {path}: {_honcho_json_summary(parsed)}"
        ) from exc


def _resolve_honcho_identity(payload: Dict[str, Any], http_request: Optional[Request]) -> Dict[str, str]:
    metadata = payload.get("metadata") if isinstance(payload.get("metadata"), dict) else {}
    inputs = payload.get("inputs") if isinstance(payload.get("inputs"), dict) else {}
    raw_user = _first_non_empty(
        payload.get("user"),
        payload.get("user_id"),
        payload.get("username"),
        metadata.get("fortisai_user"),
        metadata.get("user_id"),
        metadata.get("user"),
        inputs.get("user_id"),
        inputs.get("user"),
        _request_header(http_request, "x-fortisai-user", "x-user-id", "x-user"),
        _request_header(http_request, "x-openwebui-user-email", "x-openwebui-user-name"),
        _request_header(http_request, "cf-access-authenticated-user-email"),
    )
    if not raw_user:
        auth_header = _request_header(http_request, "authorization")
        if auth_header:
            raw_user = f"auth_{hashlib.sha256(auth_header.encode('utf-8')).hexdigest()[:16]}"
    if not raw_user:
        raw_user = FORTISAI_HONCHO_DEFAULT_USER_ID

    raw_session = _first_non_empty(
        payload.get("conversation_id"),
        payload.get("session_id"),
        payload.get("thread_id"),
        metadata.get("conversation_id"),
        metadata.get("session_id"),
        metadata.get("thread_id"),
        inputs.get("conversation_id"),
        inputs.get("session_id"),
        _request_header(http_request, "x-fortisai-session", "x-session-id", "x-conversation-id"),
        FORTISAI_HONCHO_DEFAULT_SESSION_ID,
    )

    user_peer_id = _honcho_safe_id("user", raw_user)
    session_seed = user_peer_id if FORTISAI_HONCHO_SESSION_SCOPE == "user" else f"{user_peer_id}_{raw_session}"
    session_id = _honcho_safe_id("session", session_seed)
    return {
        "workspace_id": _honcho_safe_id("workspace", FORTISAI_HONCHO_WORKSPACE_ID, add_prefix=False),
        "assistant_peer_id": _honcho_safe_id("assistant", FORTISAI_HONCHO_ASSISTANT_PEER_ID),
        "user_peer_id": user_peer_id,
        "session_id": session_id,
        "session_scope": FORTISAI_HONCHO_SESSION_SCOPE,
        "raw_user": raw_user,
        "raw_session": raw_session,
    }


def _honcho_encode_id(value: str) -> str:
    return urllib.parse.quote(value, safe="")


def _ensure_honcho_scope(identity: Dict[str, str]) -> None:
    workspace_id = identity["workspace_id"]
    user_peer_id = identity["user_peer_id"]
    assistant_peer_id = identity["assistant_peer_id"]
    session_id = identity["session_id"]

    _honcho_request(
        "POST",
        "/v3/workspaces",
        {
            "id": workspace_id,
            "metadata": {
                "source": "fortisai_llm_proxy",
                "model": FORTISAI_HONCHO_MODEL,
            },
        },
    )
    _honcho_request(
        "POST",
        f"/v3/workspaces/{_honcho_encode_id(workspace_id)}/peers",
        {
            "id": user_peer_id,
            "metadata": {
                "role": "user",
                "source": "fortisai_llm_proxy",
            },
        },
    )
    _honcho_request(
        "POST",
        f"/v3/workspaces/{_honcho_encode_id(workspace_id)}/peers",
        {
            "id": assistant_peer_id,
            "metadata": {
                "role": "assistant",
                "source": "fortisai_llm_proxy",
            },
        },
    )
    _honcho_request(
        "POST",
        f"/v3/workspaces/{_honcho_encode_id(workspace_id)}/sessions",
        {
            "id": session_id,
            "peers": {
                user_peer_id: {
                    "observe_me": True,
                    "observe_others": False,
                },
                assistant_peer_id: {
                    "observe_me": False,
                    "observe_others": True,
                },
            },
            "metadata": {
                "source": "fortisai_llm_proxy",
            },
        },
    )


def _honcho_messages_to_text(messages: Any, max_messages: int) -> str:
    if not isinstance(messages, list):
        return ""
    parts: list[str] = []
    for item in messages[-max_messages:]:
        if not isinstance(item, dict):
            continue
        metadata = item.get("metadata") if isinstance(item.get("metadata"), dict) else {}
        role = str(metadata.get("role") or item.get("peer_id") or "peer").strip()
        content = _extract_content_text(item.get("content")).strip()
        if content:
            parts.append(f"- {role}: {content}")
    return "\n".join(parts)


def _honcho_search_results_to_text(results: Any, max_items: int) -> str:
    if not isinstance(results, list):
        return ""
    parts: list[str] = []
    for item in results[:max_items]:
        if not isinstance(item, dict):
            continue
        metadata = item.get("metadata") if isinstance(item.get("metadata"), dict) else {}
        role = str(metadata.get("role") or item.get("peer_id") or "peer").strip()
        content = _extract_content_text(item.get("content")).strip()
        if content:
            parts.append(f"- {role}: {content}")
    return "\n".join(parts)


def _limit_honcho_text(text: str) -> str:
    if FORTISAI_HONCHO_CONTEXT_LIMIT_CHARS <= 0:
        return ""
    text = text.strip()
    if len(text) <= FORTISAI_HONCHO_CONTEXT_LIMIT_CHARS:
        return text
    return text[-FORTISAI_HONCHO_CONTEXT_LIMIT_CHARS:]


def _honcho_context_to_text(context: Any, search_results: Any) -> str:
    sections: list[str] = []
    if isinstance(context, dict):
        summary = _extract_content_text(context.get("summary")).strip()
        if summary:
            sections.append(f"Session summary:\n{summary}")
        peer_representation = _extract_content_text(context.get("peer_representation")).strip()
        if peer_representation:
            sections.append(f"Peer representation:\n{peer_representation}")
        peer_card = _extract_content_text(context.get("peer_card")).strip()
        if peer_card:
            sections.append(f"Peer card:\n{peer_card}")
        messages_text = _honcho_messages_to_text(
            context.get("messages"),
            max_messages=FORTISAI_HONCHO_CONTEXT_MAX_MESSAGES,
        )
        if messages_text:
            sections.append(f"Recent session messages:\n{messages_text}")

    search_text = _honcho_search_results_to_text(
        search_results,
        max_items=FORTISAI_HONCHO_CONTEXT_MAX_MESSAGES,
    )
    if search_text:
        sections.append(f"Relevant user memory:\n{search_text}")

    return _limit_honcho_text("\n\n".join(sections))


def _lookup_honcho_memory(identity: Dict[str, str], prompt_text: str) -> str:
    workspace_id = _honcho_encode_id(identity["workspace_id"])
    session_id = _honcho_encode_id(identity["session_id"])
    user_peer_id = _honcho_encode_id(identity["user_peer_id"])
    context = _honcho_request("GET", f"/v3/workspaces/{workspace_id}/sessions/{session_id}/context")
    search_results: Any = []
    if prompt_text.strip():
        try:
            search_results = _honcho_request(
                "POST",
                f"/v3/workspaces/{workspace_id}/peers/{user_peer_id}/search",
                {"query": prompt_text},
            )
        except Exception as exc:
            log.warning("Honcho peer search skipped: %s", exc)
    return _honcho_context_to_text(context=context, search_results=search_results)


def _honcho_error_response(exc: Exception) -> HTTPException:
    return HTTPException(
        status_code=503,
        detail={
            "error": "FortisAI Honcho memory is required but unavailable",
            "honcho_base_url": FORTISAI_HONCHO_BASE_URL,
            "honcho_workspace_id": FORTISAI_HONCHO_WORKSPACE_ID,
            "detail": str(exc),
        },
    )


def _prepare_honcho_context(
    payload: Dict[str, Any],
    prompt_text: str,
    http_request: Optional[Request],
) -> Optional[Dict[str, Any]]:
    if not FORTISAI_HONCHO_BASE_URL:
        if FORTISAI_HONCHO_REQUIRED:
            raise _honcho_error_response(RuntimeError("FORTISAI_HONCHO_BASE_URL is not configured"))
        return None

    try:
        identity = _resolve_honcho_identity(payload=payload, http_request=http_request)
        _ensure_honcho_scope(identity)
        memory_text = _lookup_honcho_memory(identity=identity, prompt_text=prompt_text)
        identity.update(
            {
                "memory_text": memory_text,
                "user_text": _extract_last_user_text(payload),
            }
        )
        return identity
    except Exception as exc:
        if FORTISAI_HONCHO_REQUIRED:
            raise _honcho_error_response(exc) from exc
        log.warning("Honcho memory bypassed because it is not required and lookup failed: %s", exc)
        return None


def _honcho_system_message(honcho_context: Dict[str, Any]) -> str:
    memory_text = str(honcho_context.get("memory_text") or "").strip()
    return "\n\n".join(
        [
            "FortisAI Honcho memory context is required for this request.",
            (
                f"Workspace: {honcho_context.get('workspace_id')}\n"
                f"User peer: {honcho_context.get('user_peer_id')}\n"
                f"Session: {honcho_context.get('session_id')}"
            ),
            "Use this memory when it is relevant. Do not expose these bookkeeping identifiers unless asked.",
            memory_text or "No prior Honcho memory was available for this user/session.",
        ]
    )


def _inject_honcho_memory(
    endpoint_path: str,
    payload: Dict[str, Any],
    honcho_context: Optional[Dict[str, Any]],
    rag_context: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    if not honcho_context and not rag_context:
        return dict(payload)

    enriched = dict(payload)
    context_messages: list[str] = []
    if honcho_context:
        context_messages.append(_honcho_system_message(honcho_context))
    rag_message = _rag_system_message(rag_context)
    if rag_message:
        context_messages.append(rag_message)
    memory_message = "\n\n".join([item for item in context_messages if item.strip()])
    if not memory_message:
        return enriched

    if endpoint_path == "/chat/completions":
        raw_messages = payload.get("messages")
        messages: list[Any] = raw_messages if isinstance(raw_messages, list) else []
        enriched["messages"] = [{"role": "system", "content": memory_message}] + messages
    elif endpoint_path == "/completions":
        prompt = payload.get("prompt")
        prefix = f"{memory_message}\n\nUser request:\n"
        if isinstance(prompt, list):
            enriched["prompt"] = [f"{prefix}{_extract_content_text(item)}" for item in prompt]
        else:
            enriched["prompt"] = f"{prefix}{_extract_content_text(prompt)}"
    return enriched


def _honcho_route_metadata(honcho_context: Optional[Dict[str, Any]]) -> Dict[str, Any]:
    return {
        "required": FORTISAI_HONCHO_REQUIRED,
        "base_url": FORTISAI_HONCHO_BASE_URL,
        "workspace_id": honcho_context.get("workspace_id") if honcho_context else FORTISAI_HONCHO_WORKSPACE_ID,
        "user_peer_id": honcho_context.get("user_peer_id") if honcho_context else "",
        "session_id": honcho_context.get("session_id") if honcho_context else "",
        "session_scope": honcho_context.get("session_scope") if honcho_context else FORTISAI_HONCHO_SESSION_SCOPE,
        "source_conversation_id": honcho_context.get("raw_session") if honcho_context else "",
        "model": FORTISAI_HONCHO_MODEL,
        "context_injected": bool(honcho_context and honcho_context.get("memory_text")),
        "cline_context_limited": bool(honcho_context and honcho_context.get("cline_context_limited")),
    }


def _rag_limited_text(text: Any, limit: int) -> str:
    value = _extract_content_text(text).strip()
    if limit > 0 and len(value) > limit:
        return value[:limit]
    return value


def _rag_context_limited(text: str) -> str:
    text = str(text or "").strip()
    if FORTISAI_RAG_CONTEXT_LIMIT_CHARS <= 0:
        return ""
    if len(text) <= FORTISAI_RAG_CONTEXT_LIMIT_CHARS:
        return text
    return text[:FORTISAI_RAG_CONTEXT_LIMIT_CHARS]


def _limit_cline_retrieval_query(prompt_text: str) -> str:
    if FORTISAI_CLINE_RETRIEVAL_QUERY_CHARS <= 0:
        return prompt_text
    return _rag_limited_text(prompt_text, FORTISAI_CLINE_RETRIEVAL_QUERY_CHARS)


def _limit_cline_contexts(
    honcho_context: Optional[Dict[str, Any]],
    rag_context: Optional[Dict[str, Any]],
) -> tuple[Optional[Dict[str, Any]], Optional[Dict[str, Any]]]:
    if FORTISAI_CLINE_CONTEXT_LIMIT_CHARS <= 0:
        return honcho_context, rag_context

    limited_honcho = honcho_context
    if honcho_context and honcho_context.get("memory_text"):
        limited_honcho = dict(honcho_context)
        limited_honcho["memory_text"] = _rag_limited_text(
            honcho_context.get("memory_text"),
            FORTISAI_CLINE_CONTEXT_LIMIT_CHARS,
        )
        limited_honcho["cline_context_limited"] = True

    limited_rag = rag_context
    if rag_context:
        limited_rag = dict(rag_context)
        per_section_limit = max(1, FORTISAI_CLINE_CONTEXT_LIMIT_CHARS // 2)
        for key in ("vector_text", "web_text"):
            if limited_rag.get(key):
                limited_rag[key] = _rag_limited_text(limited_rag.get(key), per_section_limit)
        limited_rag["cline_context_limited"] = True

    return limited_honcho, limited_rag


def _rag_json_request(
    method: str,
    url: str,
    body: Optional[Dict[str, Any]] = None,
    headers: Optional[Dict[str, str]] = None,
    timeout: float = 10.0,
    expected_statuses: tuple[int, ...] = (200, 201, 202),
) -> Any:
    req_headers = {"Accept": "application/json"}
    if headers:
        req_headers.update(headers)
    data_bytes = None
    if body is not None:
        data_bytes = json.dumps(body).encode("utf-8")
        req_headers["Content-Type"] = "application/json"
    request = urllib.request.Request(url=url, data=data_bytes, headers=req_headers, method=method.upper())
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            parsed = _parse_upstream_body(response.read())
            if response.status not in expected_statuses:
                raise RuntimeError(f"HTTP {response.status} from {url}")
            return parsed
    except urllib.error.HTTPError as exc:
        parsed = _parse_upstream_body(exc.read())
        if exc.code in expected_statuses:
            return parsed
        raise RuntimeError(f"HTTP {exc.code} from {url}: {_honcho_json_summary(parsed)}") from exc


def _rag_embedding_headers(api_key: str = "") -> Dict[str, str]:
    headers = {"Accept": "application/json", "Content-Type": "application/json"}
    key = (api_key or FORTISAI_RAG_EMBEDDING_API_KEY).strip()
    if key:
        headers["Authorization"] = f"Bearer {key}"
    return headers


def _rag_embedding_request_target() -> tuple[str, str, str, Dict[str, Any]]:
    configured_model = FORTISAI_RAG_EMBEDDING_MODEL.strip()
    if configured_model:
        return (
            FORTISAI_RAG_EMBEDDING_BASE_URL,
            configured_model,
            FORTISAI_RAG_EMBEDDING_API_KEY,
            {
                "request_type": "rag_embeddings_direct",
                "routed_model": configured_model,
                "embedding_selection_policy": "operator_override",
            },
        )

    route_info = choose_fortisai_embedding_route(config=load_router_classification())
    routed_model = str(route_info.get("routed_model") or "").strip()
    return (
        FORTISAI_LLAMA_OPENAI_BASE_URL,
        routed_model,
        FORTISAI_LLAMA_OPENAI_API_KEY,
        route_info,
    )


def _rag_embed_text(text: str) -> list[float]:
    query = _rag_limited_text(text, FORTISAI_RAG_EMBEDDING_INPUT_CHARS)
    base_url, model, api_key, _route_info = _rag_embedding_request_target()
    if not query or not base_url or not model:
        return []
    payload = {"model": model, "input": query}
    parsed = _rag_json_request(
        "POST",
        f"{base_url}/embeddings",
        body=payload,
        headers=_rag_embedding_headers(api_key),
        timeout=FORTISAI_OPENAI_ROUTER_TIMEOUT_SECONDS,
    )
    if not isinstance(parsed, dict):
        return []
    data = parsed.get("data")
    if not isinstance(data, list) or not data:
        return []
    first = data[0] if isinstance(data[0], dict) else {}
    embedding = first.get("embedding")
    if not isinstance(embedding, list):
        return []
    result: list[float] = []
    for value in embedding:
        try:
            result.append(float(value))
        except (TypeError, ValueError):
            continue
    return result


def _qdrant_collection_name(vector_size: int) -> str:
    base = re.sub(r"[^A-Za-z0-9_-]+", "_", FORTISAI_RAG_QDRANT_COLLECTION).strip("_") or "fortisai_general_knowledge"
    return f"{base}_d{vector_size}"


def _qdrant_headers() -> Dict[str, str]:
    result: Dict[str, str] = {"Accept": "application/json"}
    if FORTISAI_RAG_QDRANT_API_KEY:
        result["api-key"] = FORTISAI_RAG_QDRANT_API_KEY
    return result


def _qdrant_request(
    method: str,
    path: str,
    body: Optional[Dict[str, Any]] = None,
    expected_statuses: tuple[int, ...] = (200, 201, 202),
) -> Any:
    if not FORTISAI_RAG_QDRANT_URL:
        raise RuntimeError("Qdrant URL is not configured")
    return _rag_json_request(
        method,
        f"{FORTISAI_RAG_QDRANT_URL}{path}",
        body=body,
        headers=_qdrant_headers(),
        timeout=FORTISAI_RAG_WEB_TIMEOUT_SECONDS,
        expected_statuses=expected_statuses,
    )


def _ensure_qdrant_collection(collection: str, vector_size: int) -> None:
    encoded = urllib.parse.quote(collection, safe="")
    try:
        _qdrant_request("GET", f"/collections/{encoded}", expected_statuses=(200,))
        return
    except Exception:
        pass
    try:
        _qdrant_request(
            "PUT",
            f"/collections/{encoded}",
            body={"vectors": {"size": vector_size, "distance": "Cosine"}},
            expected_statuses=(200, 201),
        )
    except Exception as exc:
        if "already exists" in str(exc).lower():
            return
        raise


def _qdrant_search(vector: list[float], limit: int) -> tuple[str, list[Dict[str, Any]]]:
    if not vector or limit <= 0:
        return "", []
    collection = _qdrant_collection_name(len(vector))
    _ensure_qdrant_collection(collection, len(vector))
    body: Dict[str, Any] = {
        "vector": vector,
        "limit": limit,
        "with_payload": True,
        "with_vector": False,
    }
    if FORTISAI_RAG_VECTOR_SCORE_THRESHOLD > 0:
        body["score_threshold"] = FORTISAI_RAG_VECTOR_SCORE_THRESHOLD
    parsed = _qdrant_request(
        "POST",
        f"/collections/{urllib.parse.quote(collection, safe='')}/points/search",
        body=body,
        expected_statuses=(200,),
    )
    result = parsed.get("result") if isinstance(parsed, dict) else []
    return collection, [item for item in result if isinstance(item, dict)] if isinstance(result, list) else []


def _qdrant_upsert_web_results(collection: str, web_results: list[Dict[str, Any]]) -> int:
    if not collection or not web_results or not FORTISAI_RAG_UPSERT_WEB_RESULTS:
        return 0
    points: list[Dict[str, Any]] = []
    for item in web_results:
        text = _web_result_content(item)
        if not text:
            continue
        try:
            vector = _rag_embed_text(text)
        except Exception as exc:
            log.warning("FortisAI RAG web result embedding skipped: %s", exc)
            continue
        if not vector:
            continue
        target_collection = _qdrant_collection_name(len(vector))
        _ensure_qdrant_collection(target_collection, len(vector))
        if target_collection != collection:
            collection = target_collection
        url = str(item.get("url") or "").strip()
        title = str(item.get("title") or "").strip()
        point_key = url or f"{title}:{hashlib.sha256(text.encode('utf-8')).hexdigest()}"
        point_id = str(uuid.uuid5(uuid.NAMESPACE_URL, point_key))
        points.append(
            {
                "id": point_id,
                "vector": vector,
                "payload": {
                    "source": "firecrawl",
                    "url": url,
                    "title": title,
                    "description": _rag_limited_text(item.get("description"), 1000),
                    "content": _rag_limited_text(text, 6000),
                    "indexed_at": int(time.time()),
                },
            }
        )
    if not points:
        return 0
    _qdrant_request(
        "PUT",
        f"/collections/{urllib.parse.quote(collection, safe='')}/points?wait=true",
        body={"points": points},
        expected_statuses=(200, 201),
    )
    return len(points)


def _qdrant_upsert_web_results_async(collection: str, web_results: list[Dict[str, Any]]) -> bool:
    if not collection or not web_results or not FORTISAI_RAG_UPSERT_WEB_RESULTS:
        return False
    result_copy = [dict(item) for item in web_results]

    def worker() -> None:
        started_at = time.monotonic()
        try:
            count = _qdrant_upsert_web_results(collection, result_copy)
            log.info(
                "FortisAI RAG web result upsert completed: collection=%s count=%s elapsed_ms=%s",
                collection,
                count,
                _elapsed_ms(started_at),
            )
        except Exception as exc:
            log.warning("FortisAI RAG web result upsert failed asynchronously: %s", exc)

    threading.Thread(target=worker, name="fortisai-rag-web-upsert", daemon=True).start()
    return True


def _qdrant_tool_collection_name(vector_size: int) -> str:
    base = re.sub(r"[^A-Za-z0-9_-]+", "_", FORTISAI_TOOL_MEMORY_QDRANT_COLLECTION).strip("_") or "fortisai_tool_registry"
    return f"{base}_d{vector_size}"


def _tool_memory_text(name: str, spec: Dict[str, Any]) -> str:
    parts = [
        "FortisAI OpenWebUI skill-backed MCP/OpenAPI tool.",
        f"Tool name: {name}",
        f"Tool server: {spec.get('server_name') or spec.get('source') or ''}",
        f"HTTP method: {spec.get('method') or ''}",
        f"OpenAPI path: {spec.get('path') or ''}",
        f"Operation id: {spec.get('operation_id') or ''}",
        f"Description: {spec.get('description') or ''}",
    ]
    path_params = spec.get("path_params") if isinstance(spec.get("path_params"), list) else []
    required_body_fields = spec.get("required_body_fields") if isinstance(spec.get("required_body_fields"), list) else []
    if path_params:
        parts.append(f"Required path parameters: {', '.join(str(item) for item in path_params)}")
    if required_body_fields:
        parts.append(f"Required request fields: {', '.join(str(item) for item in required_body_fields)}")
    return _rag_limited_text("\n".join(parts), 2200)


def _tool_memory_signature(registry: Dict[str, Dict[str, Any]], cache_key: str) -> str:
    rows: list[tuple[str, str, str, str, str]] = []
    for name, spec in registry.items():
        if not isinstance(spec, dict):
            continue
        rows.append(
            (
                str(name),
                str(spec.get("server_name") or spec.get("source") or ""),
                str(spec.get("method") or ""),
                str(spec.get("path") or spec.get("url") or ""),
                str(spec.get("operation_id") or ""),
            )
        )
    raw = json.dumps([str(cache_key or ""), sorted(rows)], sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def _qdrant_upsert_tool_registry(
    registry: Dict[str, Dict[str, Any]],
    cache_key: str,
) -> int:
    if not FORTISAI_TOOL_MEMORY_QDRANT_ENABLED or not registry or FORTISAI_TOOL_MEMORY_UPSERT_MAX <= 0:
        return 0
    points: list[Dict[str, Any]] = []
    collection = ""
    for index, (name, spec) in enumerate(sorted(registry.items())):
        if index >= FORTISAI_TOOL_MEMORY_UPSERT_MAX:
            break
        if not isinstance(spec, dict):
            continue
        text = _tool_memory_text(name, spec)
        if not text:
            continue
        try:
            vector = _rag_embed_text(text)
        except Exception as exc:
            log.warning("FortisAI tool memory embedding skipped: tool=%s error=%s", name, exc)
            continue
        if not vector:
            continue
        collection = _qdrant_tool_collection_name(len(vector))
        _ensure_qdrant_collection(collection, len(vector))
        point_key = f"{cache_key}:{name}:{spec.get('method')}:{spec.get('path') or spec.get('url')}"
        points.append(
            {
                "id": str(uuid.uuid5(uuid.NAMESPACE_URL, point_key)),
                "vector": vector,
                "payload": {
                    "source": "fortisai_tool_registry",
                    "cache_key": str(cache_key or ""),
                    "name": name,
                    "server_name": str(spec.get("server_name") or ""),
                    "method": str(spec.get("method") or ""),
                    "path": str(spec.get("path") or ""),
                    "operation_id": str(spec.get("operation_id") or ""),
                    "description": _rag_limited_text(spec.get("description"), 1200),
                    "read_only_fallback": _bridge_read_only_fallback_allowed(name, spec),
                    "content": text,
                    "indexed_at": int(time.time()),
                },
            }
        )
    if not points or not collection:
        return 0
    _qdrant_request(
        "PUT",
        f"/collections/{urllib.parse.quote(collection, safe='')}/points?wait=true",
        body={"points": points},
        expected_statuses=(200, 201),
    )
    return len(points)


def _qdrant_upsert_tool_registry_async(
    registry: Dict[str, Dict[str, Any]],
    cache_key: str,
) -> bool:
    if not FORTISAI_TOOL_MEMORY_QDRANT_ENABLED or not registry:
        return False
    signature = _tool_memory_signature(registry, cache_key)
    signatures = _BRIDGE_TOOL_REGISTRY_CACHE.setdefault("tool_memory_signatures", {})
    if isinstance(signatures, dict) and signatures.get(cache_key) == signature:
        return False
    if isinstance(signatures, dict):
        signatures[cache_key] = signature
    registry_copy = {name: dict(spec) for name, spec in registry.items() if isinstance(spec, dict)}

    def worker() -> None:
        started_at = time.monotonic()
        try:
            count = _qdrant_upsert_tool_registry(registry_copy, cache_key)
            log.info(
                "FortisAI tool memory upsert completed: tools=%s cache_key=%s elapsed_ms=%s",
                count,
                cache_key,
                _elapsed_ms(started_at),
            )
        except Exception as exc:
            log.warning("FortisAI tool memory upsert failed asynchronously: %s", exc)

    threading.Thread(target=worker, name="fortisai-tool-memory-upsert", daemon=True).start()
    return True


def _qdrant_search_tool_memory(prompt_text: str, registry: Dict[str, Dict[str, Any]]) -> list[str]:
    if not FORTISAI_TOOL_MEMORY_QDRANT_ENABLED or not prompt_text or FORTISAI_TOOL_MEMORY_SEARCH_LIMIT <= 0:
        return []
    matching_servers: list[str] = []
    try:
        vector = _rag_embed_text(prompt_text)
    except Exception as exc:
        log.warning("FortisAI tool memory search embedding failed: %s", exc)
        return []
    if not vector:
        return []
    collection = _qdrant_tool_collection_name(len(vector))
    try:
        _ensure_qdrant_collection(collection, len(vector))
        prompt_tokens = _bridge_prompt_hint_tokens(prompt_text)
        matching_servers = sorted(
            {
                str(spec.get("server_name") or "")
                for spec in registry.values()
                if isinstance(spec, dict)
                and str(spec.get("server_name") or "")
                and (_bridge_server_prompt_hints(str(spec.get("server_name") or "")) & prompt_tokens)
            }
        )
        search_payloads: list[Dict[str, Any]] = []
        for server_name in matching_servers[:4]:
            search_payloads.append(
                {
                    "filter": {
                        "must": [
                            {
                                "key": "server_name",
                                "match": {"value": server_name},
                            }
                        ]
                    }
                }
            )
        search_payloads.append({})
        rows: list[Dict[str, Any]] = []
        for search_filter in search_payloads:
            body: Dict[str, Any] = {
                "vector": vector,
                "limit": FORTISAI_TOOL_MEMORY_SEARCH_LIMIT,
                "with_payload": True,
                "with_vector": False,
            }
            body.update(search_filter)
            if FORTISAI_TOOL_MEMORY_SCORE_THRESHOLD > 0:
                body["score_threshold"] = FORTISAI_TOOL_MEMORY_SCORE_THRESHOLD
            parsed = _qdrant_request(
                "POST",
                f"/collections/{urllib.parse.quote(collection, safe='')}/points/search",
                body=body,
                expected_statuses=(200,),
            )
            result = parsed.get("result") if isinstance(parsed, dict) else []
            if isinstance(result, list):
                rows.extend(item for item in result if isinstance(item, dict))
            if rows and search_filter:
                break
    except Exception as exc:
        log.warning("FortisAI tool memory search failed: %s", exc)
        return []
    names: list[str] = []
    seen: set[str] = set()
    for item in rows:
        payload = item.get("payload") if isinstance(item, dict) and isinstance(item.get("payload"), dict) else {}
        name = str(payload.get("name") or "").strip()
        if not name or name in seen or name not in registry:
            continue
        spec = registry.get(name)
        if not isinstance(spec, dict) or not _bridge_read_only_fallback_allowed(name, spec):
            continue
        seen.add(name)
        names.append(name)
    if names or not matching_servers:
        return names

    prompt_tokens = _bridge_match_tokens(prompt_text)
    scored: list[tuple[int, str]] = []
    for server_name in matching_servers[:4]:
        try:
            parsed = _qdrant_request(
                "POST",
                f"/collections/{urllib.parse.quote(collection, safe='')}/points/scroll",
                body={
                    "filter": {
                        "must": [
                            {
                                "key": "server_name",
                                "match": {"value": server_name},
                            }
                        ]
                    },
                    "limit": max(FORTISAI_TOOL_MEMORY_SEARCH_LIMIT, 100),
                    "with_payload": True,
                    "with_vector": False,
                },
                expected_statuses=(200,),
            )
        except Exception as exc:
            log.warning("FortisAI tool memory scroll failed: server=%s error=%s", server_name, exc)
            continue
        result = parsed.get("result") if isinstance(parsed, dict) else {}
        points = result.get("points") if isinstance(result, dict) else []
        if not isinstance(points, list):
            continue
        for item in points:
            payload = item.get("payload") if isinstance(item, dict) and isinstance(item.get("payload"), dict) else {}
            name = str(payload.get("name") or "").strip()
            if not name or name in seen or name not in registry:
                continue
            spec = registry.get(name)
            if not isinstance(spec, dict) or not _bridge_read_only_fallback_allowed(name, spec):
                continue
            searchable = " ".join(
                [
                    name,
                    str(payload.get("path") or ""),
                    str(payload.get("operation_id") or ""),
                    str(payload.get("description") or ""),
                    str(payload.get("content") or ""),
                ]
            )
            tool_tokens = _bridge_match_tokens(searchable)
            overlap = tool_tokens & prompt_tokens
            if not overlap:
                continue
            listing_prompt = bool(prompt_tokens & {"all", "list", "pull", "show"})
            detail_tokens = {"config", "detail", "details", "ip", "statistic", "statistics", "status"}
            if listing_prompt and tool_tokens & detail_tokens and not prompt_tokens & detail_tokens:
                continue
            score = len(overlap) * 4
            if listing_prompt and tool_tokens & {"get", "list", "search"}:
                score += 3
            if listing_prompt and not tool_tokens & detail_tokens:
                score += 4
            if {"vm", "vms"} & prompt_tokens and {"vm", "vms"} & tool_tokens:
                score += 6
            if {"container", "containers"} & prompt_tokens and {"container", "containers"} & tool_tokens:
                score += 6
            if {"workflow", "workflows"} & prompt_tokens and {"workflow", "workflows"} & tool_tokens:
                score += 6
            if score >= 4:
                scored.append((score, name))
    scored.sort(key=lambda item: (-item[0], item[1]))
    for _score, name in scored:
        if name in seen:
            continue
        seen.add(name)
        names.append(name)
        if len(names) >= FORTISAI_TOOL_MEMORY_SEARCH_LIMIT:
            break
    return names


def _vector_results_to_text(results: list[Dict[str, Any]]) -> str:
    parts: list[str] = []
    for index, item in enumerate(results, start=1):
        payload = item.get("payload") if isinstance(item.get("payload"), dict) else {}
        title = _rag_limited_text(payload.get("title"), 200) or "Vector result"
        url = _rag_limited_text(payload.get("url"), 500)
        content = _rag_limited_text(payload.get("content") or payload.get("description"), 1400)
        score = item.get("score")
        score_text = f" score={score:.3f}" if isinstance(score, (float, int)) else ""
        header = f"{index}. {title}{score_text}"
        if url:
            header = f"{header}\n   URL: {url}"
        if content:
            header = f"{header}\n   {content}"
        parts.append(header)
    return _rag_context_limited("\n".join(parts))


def _firecrawl_headers() -> Dict[str, str]:
    result = {"Accept": "application/json", "Content-Type": "application/json"}
    if FORTISAI_RAG_FIRECRAWL_API_KEY:
        result["Authorization"] = f"Bearer {FORTISAI_RAG_FIRECRAWL_API_KEY}"
    return result


def _firecrawl_search(query: str) -> list[Dict[str, Any]]:
    if not FORTISAI_RAG_FIRECRAWL_URL or FORTISAI_RAG_WEB_LIMIT <= 0:
        return []
    query_text = _rag_limited_text(query, FORTISAI_RAG_QUERY_CHARS)
    if not query_text:
        return []
    body = {
        "query": query_text,
        "limit": FORTISAI_RAG_WEB_LIMIT,
        "scrapeOptions": {"formats": ["markdown"]},
    }
    parsed = _rag_json_request(
        "POST",
        f"{FORTISAI_RAG_FIRECRAWL_URL}/v1/search",
        body=body,
        headers=_firecrawl_headers(),
        timeout=FORTISAI_RAG_WEB_TIMEOUT_SECONDS,
        expected_statuses=(200,),
    )
    data = parsed.get("data") if isinstance(parsed, dict) else []
    if not isinstance(data, list):
        return []
    return [item for item in data if isinstance(item, dict)]


def _web_result_content(item: Dict[str, Any]) -> str:
    return _rag_limited_text(
        _first_non_empty(
            item.get("markdown"),
            item.get("content"),
            item.get("description"),
            item.get("title"),
            item.get("url"),
        ),
        FORTISAI_RAG_EMBEDDING_INPUT_CHARS,
    )


def _web_results_to_text(results: list[Dict[str, Any]]) -> str:
    parts: list[str] = []
    for index, item in enumerate(results, start=1):
        title = _rag_limited_text(item.get("title"), 200) or "Web result"
        url = _rag_limited_text(item.get("url"), 500)
        description = _rag_limited_text(
            _first_non_empty(item.get("description"), item.get("markdown"), item.get("content")),
            1400,
        )
        entry = f"{index}. {title}"
        if url:
            entry = f"{entry}\n   URL: {url}"
        if description:
            entry = f"{entry}\n   {description}"
        parts.append(entry)
    return _rag_context_limited("\n".join(parts))


def _prepare_rag_context(prompt_text: str) -> Optional[Dict[str, Any]]:
    if not FORTISAI_RAG_ENABLED:
        return None

    total_started_at = time.monotonic()
    query = _rag_limited_text(prompt_text, FORTISAI_RAG_QUERY_CHARS)
    _rag_embedding_base_url, rag_embedding_model, _rag_embedding_api_key, rag_embedding_route = _rag_embedding_request_target()
    context: Dict[str, Any] = {
        "enabled": True,
        "provider": "qdrant+firecrawl",
        "qdrant_url": FORTISAI_RAG_QDRANT_URL,
        "firecrawl_url": FORTISAI_RAG_FIRECRAWL_URL,
        "embedding_model": rag_embedding_model or "auto",
        "embedding_selection_policy": rag_embedding_route.get("embedding_selection_policy", "classified_route"),
        "collection": "",
        "vector_result_count": 0,
        "web_result_count": 0,
        "web_upsert_count": 0,
        "web_upsert_queued_count": 0,
        "web_upsert_status": "not_started",
        "vector_text": "",
        "web_text": "",
        "timings_ms": {},
        "errors": [],
    }
    timings = context["timings_ms"]

    query_vector: list[float] = []
    vector_started_at = time.monotonic()
    try:
        query_vector = _rag_embed_text(query)
        if query_vector:
            collection, vector_results = _qdrant_search(query_vector, FORTISAI_RAG_VECTOR_LIMIT)
            context["collection"] = collection
            context["vector_result_count"] = len(vector_results)
            context["vector_text"] = _vector_results_to_text(vector_results)
    except Exception as exc:
        log.warning("FortisAI RAG vector lookup failed: %s", exc)
        context["errors"].append(f"vector_lookup: {exc}")
    finally:
        timings["vector_lookup_ms"] = _elapsed_ms(vector_started_at)

    web_results: list[Dict[str, Any]] = []
    web_started_at = time.monotonic()
    try:
        web_results = _firecrawl_search(query)
        context["web_result_count"] = len(web_results)
        context["web_text"] = _web_results_to_text(web_results)
    except Exception as exc:
        log.warning("FortisAI RAG Firecrawl search failed: %s", exc)
        context["errors"].append(f"websearch: {exc}")
    finally:
        timings["firecrawl_ms"] = _elapsed_ms(web_started_at)

    upsert_started_at = time.monotonic()
    try:
        if not web_results:
            context["web_upsert_status"] = "not_needed"
        elif not FORTISAI_RAG_UPSERT_WEB_RESULTS:
            context["web_upsert_status"] = "disabled"
        else:
            collection = str(context.get("collection") or "")
            if not collection and query_vector:
                collection = _qdrant_collection_name(len(query_vector))
            if collection:
                context["collection"] = collection
            if FORTISAI_RAG_BACKGROUND_WEB_UPSERT:
                queued = _qdrant_upsert_web_results_async(collection, web_results)
                context["web_upsert_status"] = "queued" if queued else "skipped"
                context["web_upsert_queued_count"] = len(web_results) if queued else 0
            else:
                context["web_upsert_count"] = _qdrant_upsert_web_results(collection, web_results)
                context["web_upsert_status"] = "completed"
    except Exception as exc:
        log.warning("FortisAI RAG web result upsert failed: %s", exc)
        context["web_upsert_status"] = "failed"
        context["errors"].append(f"web_upsert: {exc}")
    finally:
        timings["web_upsert_enqueue_ms"] = _elapsed_ms(upsert_started_at)
        timings["total_ms"] = _elapsed_ms(total_started_at)

    log.info(
        "FortisAI RAG prepared: collection=%s vector_results=%s web_results=%s web_upsert_status=%s timings_ms=%s",
        context.get("collection"),
        context.get("vector_result_count"),
        context.get("web_result_count"),
        context.get("web_upsert_status"),
        timings,
    )
    return context

def _rag_system_message(rag_context: Optional[Dict[str, Any]]) -> str:
    if not rag_context:
        return ""
    vector_text = str(rag_context.get("vector_text") or "").strip()
    web_text = str(rag_context.get("web_text") or "").strip()
    sections = [
        "FortisAI retrieval context follows Honcho personal memory.",
        "You have live Firecrawl web search results for this request when the Firecrawl section contains entries. Do not claim you cannot browse or cannot access current web data in that case; use those results, cite their URLs, and say only that Firecrawl returned no usable results when the section explicitly says so.",
        "Use Honcho for personal/user-specific information. Use Qdrant and Firecrawl for general/current knowledge. Prefer Firecrawl results for freshness when they conflict with older vector results.",
    ]
    sections.append(
        "Qdrant general knowledge results:\n"
        + (vector_text or "No matching Qdrant general knowledge results were available before web search.")
    )
    sections.append(
        "Firecrawl web search results:\n"
        + (web_text or "Firecrawl web search was attempted, but no usable results were returned.")
    )
    return "\n\n".join(sections)


def _rag_route_metadata(rag_context: Optional[Dict[str, Any]]) -> Dict[str, Any]:
    if not rag_context:
        return {
            "enabled": FORTISAI_RAG_ENABLED,
            "provider": "qdrant+firecrawl",
            "context_injected": False,
        }
    return {
        "enabled": True,
        "provider": rag_context.get("provider"),
        "vector_db": "qdrant",
        "collection": rag_context.get("collection"),
        "embedding_model": rag_context.get("embedding_model"),
        "vector_result_count": rag_context.get("vector_result_count", 0),
        "web_result_count": rag_context.get("web_result_count", 0),
        "web_upsert_count": rag_context.get("web_upsert_count", 0),
        "web_upsert_queued_count": rag_context.get("web_upsert_queued_count", 0),
        "web_upsert_status": rag_context.get("web_upsert_status", "unknown"),
        "context_injected": bool(rag_context.get("vector_text") or rag_context.get("web_text")),
        "cline_context_limited": bool(rag_context.get("cline_context_limited")),
        "timings_ms": rag_context.get("timings_ms", {}),
        "errors": rag_context.get("errors", []),
    }


def _extract_last_user_text(payload: Dict[str, Any]) -> str:
    messages = payload.get("messages")
    if isinstance(messages, list):
        for message in reversed(messages):
            if not isinstance(message, dict):
                continue
            role = str(message.get("role") or "").strip().lower()
            if role == "user":
                return _extract_content_text(message.get("content")).strip()
    if "prompt" in payload:
        return _extract_completion_text(payload).strip()
    return _extract_preview_text(payload).strip()


def _extract_preview_text(payload: Dict[str, Any]) -> str:
    if isinstance(payload.get("messages"), list):
        return _extract_chat_text(payload)
    if "prompt" in payload:
        return _extract_completion_text(payload)
    if "input" in payload:
        return _extract_content_text(payload.get("input"))
    if "query" in payload:
        return _extract_content_text(payload.get("query"))
    return _extract_content_text(payload)


def _payload_requires_tool_use(payload: Dict[str, Any]) -> bool:
    tool_choice = payload.get("tool_choice")
    if isinstance(tool_choice, dict) and tool_choice:
        choice_type = str(tool_choice.get("type") or "").strip().lower()
        if choice_type in {"", "auto", "none"}:
            return False
        return True
    if isinstance(tool_choice, str) and tool_choice.strip().lower() not in {"", "none", "auto"}:
        return True

    function_call = payload.get("function_call")
    if isinstance(function_call, dict) and function_call:
        function_name = str(function_call.get("name") or "").strip().lower()
        if function_name in {"", "auto", "none"}:
            return False
        return True
    if isinstance(function_call, str) and function_call.strip().lower() not in {"", "none", "auto"}:
        return True

    return False


def _prompt_requires_tool_use(prompt_text: str) -> bool:
    text = prompt_text.lower()
    phrases = [
        "tool use",
        "use a tool",
        "call a tool",
        "tool call",
        "function call",
        "api call",
        "mcp tool",
        "using mcp",
        "workflow automation",
        "orchestrate",
        "agentic",
        "code execution",
        "execute code",
        "run code",
        "execute python",
        "run python",
        "python script",
        "execute a script",
        "run a script",
        "generate and execute",
    ]
    return any(_text_has_phrase(text, phrase) for phrase in phrases)


def _route_info_for_route(
    route: Dict[str, Any],
    config: Dict[str, Any],
    available_models: list[str],
    score: int,
    matches: list[str],
    tool_use_required: bool = False,
) -> Dict[str, Any]:
    route_label = _route_label(route or {})
    candidate_models = _route_model_candidates(route or {})
    model = _select_available_model(candidate_models, available_models)
    if not model:
        model = FORTISAI_OPENAI_ROUTER_MODEL

    force_model_load = _route_force_model_load(route or {}) or tool_use_required
    result: Dict[str, Any] = {
        "app": FORTISAI_OPENAI_ROUTER_APP_NAME,
        "router_model": FORTISAI_OPENAI_ROUTER_MODEL,
        "request_type": route_label,
        "routed_model": model,
        "score": score,
        "matched_hints": matches,
        "classification_source": config.get("classification_source") or "unavailable",
        "candidate_models": candidate_models,
    }
    required_capabilities = _route_required_capabilities(route or {})
    if required_capabilities:
        result["required_capabilities"] = required_capabilities
    if force_model_load:
        result["force_model_load"] = True
        result["load_policy"] = "force_selected_model"
    if tool_use_required:
        result["tool_use_required"] = True
    return result


def choose_fortisai_route(prompt_text: str, config: Dict[str, Any]) -> Dict[str, Any]:
    routes = _route_entries(config)
    available_models = _router_model_ids(config)
    text = prompt_text.lower()

    best_route: Optional[Dict[str, Any]] = None
    best_score = -1
    best_matches: list[str] = []

    for route in routes:
        label = _route_label(route)
        hints = (
            _normalize_hint_list(route.get("hints"))
            + _normalize_hint_list(route.get("match_hints"))
            + _normalize_hint_list(route.get("keywords"))
            + _normalize_hint_list(route.get("request_hints"))
        )
        score = 0
        matches: list[str] = []
        for hint in hints:
            normalized_hint = hint.lower()
            if normalized_hint and _text_has_phrase(text, normalized_hint):
                score += 3 if " " in normalized_hint else 1
                matches.append(hint)
        for token in label.replace("_", " ").split():
            if len(token) >= 4 and _text_has_phrase(text, token):
                score += 1

        if label == "long_context" and len(prompt_text) > 8000:
            score += 8
        if label == "safety_guardrail" and matches:
            score += 4

        if score > best_score:
            best_route = route
            best_score = score
            best_matches = matches

    if best_route is None or best_score <= 0:
        preferred_label = "fast_chat" if len(prompt_text) <= 500 else "analysis_research"
        best_route = next((route for route in routes if _route_label(route) == preferred_label), None)
        if best_route is None:
            best_route = next((route for route in routes if _route_label(route) == "analysis_research"), None)
        if best_route is None and routes:
            best_route = routes[0]
        best_score = 0
        best_matches = []

    return _route_info_for_route(
        route=best_route or {},
        config=config,
        available_models=available_models,
        score=best_score,
        matches=best_matches,
    )


def choose_fortisai_tool_use_route(prompt_text: str, config: Dict[str, Any]) -> Dict[str, Any]:
    routes = _route_entries(config)
    available_models = _router_model_ids(config)
    tool_route = next((route for route in routes if _route_label(route) == "agentic_tool_use"), None)
    if tool_route is None:
        return choose_fortisai_route(prompt_text=prompt_text, config=config)
    route_info = _route_info_for_route(
        route=tool_route,
        config=config,
        available_models=available_models,
        score=99,
        matches=["tool_use_required"],
        tool_use_required=True,
    )
    route_info["classification_override"] = "explicit tool-use request"
    return route_info


def _fortisai_model_object(model_id: str, extra: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    result: Dict[str, Any] = {
        "id": model_id,
        "object": "model",
        "created": 0,
        "owned_by": "fortisai",
    }
    if extra:
        result.update(extra)
    return result


def _openai_upstream_headers() -> Dict[str, str]:
    result = {
        "Accept": "application/json",
        "Content-Type": "application/json",
    }
    if FORTISAI_LLAMA_OPENAI_API_KEY:
        result["Authorization"] = f"Bearer {FORTISAI_LLAMA_OPENAI_API_KEY}"
    return result


def _preferred_embedding_models(available_models: list[str]) -> list[str]:
    preferred = [
        FORTISAI_OPENAI_EMBEDDING_MODEL,
        "qwen__Qwen_Qwen2.5-1.5B-Instruct-GGUF__qwen2.5-1.5b-instruct-q4_0",
        "qwen__Qwen_Qwen2.5-1.5B-Instruct-GGUF__qwen2.5-1.5b-instruct-q8_0",
        "microsoft__microsoft_Phi-3-mini-4k-instruct-gguf__Phi-3-mini-4k-instruct-q4",
        "microsoft__microsoft_Phi-3-mini-4k-instruct-gguf__Phi-3-mini-4k-instruct-fp16",
    ]
    result: list[str] = []
    for model in preferred + available_models:
        model = str(model or "").strip()
        if model and model not in result:
            result.append(model)
    return result


def choose_fortisai_embedding_route(config: Dict[str, Any]) -> Dict[str, Any]:
    routes = _route_entries(config)
    available_models = _router_model_ids(config)
    statuses = _local_openai_model_statuses()
    configured_model = FORTISAI_OPENAI_EMBEDDING_MODEL.strip()
    if configured_model:
        candidates = [configured_model]
        selected_model = configured_model
        route_info: Dict[str, Any] = {
            "app": FORTISAI_OPENAI_ROUTER_APP_NAME,
            "router_model": FORTISAI_OPENAI_ROUTER_MODEL,
            "request_type": "embeddings_direct",
            "routed_model": selected_model,
            "score": 100,
            "matched_hints": ["configured_embedding_model"],
            "classification_source": config.get("classification_source") or "operator_override",
            "candidate_models": candidates,
            "embedding_selection_policy": "operator_override",
        }
        if statuses:
            route_info["selected_model_status"] = statuses.get(selected_model, "unknown")
        return route_info

    embedding_route = next((route for route in routes if _route_label(route) == "embeddings"), None)
    if embedding_route is not None:
        route_info = _route_info_for_route(
            route=embedding_route,
            config=config,
            available_models=available_models,
            score=100,
            matches=["embedding_request"],
        )
        route_info["embedding_selection_policy"] = "classified_route"
        if statuses:
            route_info["selected_model_status"] = statuses.get(route_info.get("routed_model", ""), "unknown")
        return route_info

    candidates = _preferred_embedding_models(available_models)
    loaded_model = next((model for model in candidates if statuses.get(model) == "loaded"), "")
    selected_model = loaded_model or _select_available_model(candidates, available_models)
    if not selected_model:
        selected_model = FORTISAI_OPENAI_ROUTER_MODEL
    route_info = {
        "app": FORTISAI_OPENAI_ROUTER_APP_NAME,
        "router_model": FORTISAI_OPENAI_ROUTER_MODEL,
        "request_type": "embeddings",
        "routed_model": selected_model,
        "score": 0,
        "matched_hints": [],
        "classification_source": config.get("classification_source") or "unavailable",
        "candidate_models": candidates,
        "embedding_selection_policy": "legacy_fallback",
    }
    if statuses:
        route_info["selected_model_status"] = statuses.get(selected_model, "unknown")
    return route_info


def _parse_upstream_body(raw: bytes) -> Any:
    if not raw:
        return {}
    text = raw.decode("utf-8", errors="replace")
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        return text


EXECUTE_COMMAND_BLOCK_RE = re.compile(r"(<execute_command\b[^>]*>)(.*?)(</execute_command>)", re.IGNORECASE | re.DOTALL)
REQUIRES_APPROVAL_RE = re.compile(
    r"<requires_approval>\s*(?:true|false)\s*</requires_approval>",
    re.IGNORECASE,
)


def _repair_cline_execute_command_text(text: str) -> tuple[str, int]:
    if not FORTISAI_CLINE_TOOL_GUARD_ENABLED or "execute_command" not in str(text):
        return text, 0

    repairs = 0

    def replace_block(match: re.Match[str]) -> str:
        nonlocal repairs
        body = match.group(2)
        if REQUIRES_APPROVAL_RE.search(body):
            return match.group(0)
        repairs += 1
        separator = "" if body.endswith(("\n", "\r")) else "\n"
        return f"{match.group(1)}{body}{separator}<requires_approval>true</requires_approval>\n{match.group(3)}"

    repaired = EXECUTE_COMMAND_BLOCK_RE.sub(replace_block, text)
    return repaired, repairs


def _repair_cline_content_value(value: Any) -> tuple[Any, int]:
    if isinstance(value, str):
        return _repair_cline_execute_command_text(value)
    if isinstance(value, list):
        repaired_items: list[Any] = []
        repairs = 0
        changed = False
        for item in value:
            repaired_item, item_repairs = _repair_cline_content_value(item)
            repaired_items.append(repaired_item)
            repairs += item_repairs
            changed = changed or repaired_item is not item
        return (repaired_items if changed else value), repairs
    if isinstance(value, dict):
        repaired = dict(value)
        repairs = 0
        changed = False
        for key in ("text", "content"):
            if key not in repaired:
                continue
            repaired_value, value_repairs = _repair_cline_content_value(repaired[key])
            if value_repairs:
                repaired[key] = repaired_value
                repairs += value_repairs
                changed = True
        return (repaired if changed else value), repairs
    return value, 0


def _repair_cline_tool_call(tool_call: Dict[str, Any]) -> int:
    function_info = tool_call.get("function")
    if not isinstance(function_info, dict):
        return 0
    if str(function_info.get("name") or "").strip() != "execute_command":
        return 0

    arguments = function_info.get("arguments")
    if isinstance(arguments, dict):
        if "requires_approval" not in arguments:
            arguments = dict(arguments)
            arguments["requires_approval"] = True
            function_info["arguments"] = arguments
            return 1
        return 0

    if not isinstance(arguments, str) or not arguments.strip():
        function_info["arguments"] = json.dumps({"requires_approval": True}, separators=(",", ":"))
        return 1

    try:
        parsed_args = json.loads(arguments)
    except json.JSONDecodeError:
        return 0
    if isinstance(parsed_args, dict) and "requires_approval" not in parsed_args:
        parsed_args["requires_approval"] = True
        function_info["arguments"] = json.dumps(parsed_args, separators=(",", ":"))
        return 1
    return 0


def _repair_cline_openai_response(parsed: Any) -> tuple[Any, int]:
    if not FORTISAI_CLINE_TOOL_GUARD_ENABLED or not isinstance(parsed, dict):
        return parsed, 0

    repaired = dict(parsed)
    choices = repaired.get("choices")
    if not isinstance(choices, list):
        return parsed, 0

    repaired_choices: list[Any] = []
    total_repairs = 0
    changed = False
    for choice in choices:
        if not isinstance(choice, dict):
            repaired_choices.append(choice)
            continue
        choice_copy = dict(choice)
        for field in ("message", "delta"):
            message = choice_copy.get(field)
            if not isinstance(message, dict):
                continue
            message_copy = dict(message)
            if "content" in message_copy:
                content, repairs = _repair_cline_content_value(message_copy.get("content"))
                if repairs:
                    message_copy["content"] = content
                    total_repairs += repairs
                    changed = True
            tool_calls = message_copy.get("tool_calls")
            if isinstance(tool_calls, list):
                repaired_tool_calls = []
                tool_changed = False
                for tool_call in tool_calls:
                    if isinstance(tool_call, dict):
                        tool_call_copy = dict(tool_call)
                        function_info = tool_call_copy.get("function")
                        if isinstance(function_info, dict):
                            tool_call_copy["function"] = dict(function_info)
                        repairs = _repair_cline_tool_call(tool_call_copy)
                        if repairs:
                            total_repairs += repairs
                            tool_changed = True
                            changed = True
                        repaired_tool_calls.append(tool_call_copy)
                    else:
                        repaired_tool_calls.append(tool_call)
                if tool_changed:
                    message_copy["tool_calls"] = repaired_tool_calls
            if message_copy != message:
                choice_copy[field] = message_copy
        repaired_choices.append(choice_copy)

    if changed:
        repaired["choices"] = repaired_choices
        return repaired, total_repairs
    return parsed, 0


def _repair_cline_openai_stream_chunk(chunk: bytes, state: Dict[str, Any]) -> tuple[bytes, int]:
    try:
        text = chunk.decode("utf-8", errors="replace")
    except Exception:
        return chunk, 0

    output_lines: list[str] = []
    total_repairs = 0
    changed = False
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line.startswith("data:"):
            output_lines.append(raw_line)
            continue
        data = line[5:].strip()
        if not data or data == "[DONE]":
            output_lines.append(raw_line)
            continue
        try:
            parsed = json.loads(data)
        except json.JSONDecodeError:
            output_lines.append(raw_line)
            continue
        line_changed = False
        if isinstance(parsed, dict) and parsed.get("model") != FORTISAI_OPENAI_ROUTER_MODEL:
            parsed["model"] = FORTISAI_OPENAI_ROUTER_MODEL
            line_changed = True
            changed = True
        choices = parsed.get("choices") if isinstance(parsed, dict) else None
        if isinstance(choices, list):
            for choice in choices:
                if not isinstance(choice, dict):
                    continue
                delta = choice.get("delta")
                if not isinstance(delta, dict):
                    continue
                if "content" in delta and delta.get("content") is None:
                    delta["content"] = ""
                    line_changed = True
                    changed = True
                content = delta.get("content")
                if FORTISAI_CLINE_TOOL_GUARD_ENABLED and isinstance(content, str):
                    previous_tail = str(state.get("content_tail") or "")
                    combined = previous_tail + content
                    combined_lowered = combined.lower()
                    opening_match = re.search(r"<execute_command\b[^>]*>", combined, flags=re.IGNORECASE)
                    if opening_match and not state.get("inside_execute_command"):
                        state["inside_execute_command"] = True
                        state["requires_approval_seen"] = False

                    if "<requires_approval" in combined_lowered:
                        state["requires_approval_seen"] = True

                    if opening_match and not state.get("requires_approval_seen"):
                        after_open = combined_lowered[opening_match.end():]
                        if "<requires_approval" in after_open:
                            state["requires_approval_seen"] = True
                        else:
                            insertion_offset = opening_match.end() - len(previous_tail)
                            insertion_offset = max(0, min(len(content), insertion_offset))
                            content = (
                                content[:insertion_offset]
                                + "\n<requires_approval>true</requires_approval>"
                                + content[insertion_offset:]
                            )
                            delta["content"] = content
                            state["requires_approval_seen"] = True
                            total_repairs += 1
                            line_changed = True
                            changed = True
                            combined = previous_tail + content
                            combined_lowered = combined.lower()

                    lowered = content.lower()
                    if "</execute_command>" in lowered and state.get("inside_execute_command") and not state.get("requires_approval_seen"):
                        delta["content"] = content.replace(
                            "</execute_command>",
                            "<requires_approval>true</requires_approval>\n</execute_command>",
                            1,
                        )
                        state["requires_approval_seen"] = True
                        total_repairs += 1
                        line_changed = True
                        changed = True
                    if "</execute_command>" in lowered:
                        state["inside_execute_command"] = False
                        state["requires_approval_seen"] = False
                    state["content_tail"] = (str(state.get("content_tail") or "") + content)[-240:]

                tool_calls = delta.get("tool_calls")
                if FORTISAI_CLINE_TOOL_GUARD_ENABLED and isinstance(tool_calls, list):
                    tool_names = state.setdefault("tool_call_names", {})
                    tool_args = state.setdefault("tool_call_arguments", {})
                    if not isinstance(tool_names, dict) or not isinstance(tool_args, dict):
                        continue
                    for tool_call in tool_calls:
                        if not isinstance(tool_call, dict):
                            continue
                        index = str(tool_call.get("index", 0))
                        function_info = tool_call.get("function")
                        if not isinstance(function_info, dict):
                            continue
                        name = str(function_info.get("name") or tool_names.get(index) or "").strip()
                        if function_info.get("name"):
                            tool_names[index] = name
                        arguments_delta = function_info.get("arguments")
                        if isinstance(arguments_delta, dict):
                            if name == "execute_command" and "requires_approval" not in arguments_delta:
                                arguments_delta = dict(arguments_delta)
                                arguments_delta["requires_approval"] = True
                                function_info["arguments"] = arguments_delta
                                total_repairs += 1
                                line_changed = True
                                changed = True
                            continue
                        if not isinstance(arguments_delta, str):
                            continue
                        previous_arguments = str(tool_args.get(index) or "")
                        accumulated_arguments = previous_arguments + arguments_delta
                        tool_args[index] = accumulated_arguments
                        if "requires_approval" in accumulated_arguments:
                            continue
                        if name != "execute_command":
                            continue
                        try:
                            parsed_arguments = json.loads(accumulated_arguments)
                        except json.JSONDecodeError:
                            continue
                        if not isinstance(parsed_arguments, dict) or "requires_approval" in parsed_arguments:
                            continue
                        replacement_delta, replacements = re.subn(
                            r"}(\s*)$",
                            r',"requires_approval":true}\1',
                            arguments_delta,
                            count=1,
                        )
                        if replacements:
                            function_info["arguments"] = replacement_delta
                            tool_args[index] = previous_arguments + replacement_delta
                            total_repairs += replacements
                            line_changed = True
                            changed = True

        if FORTISAI_CLINE_TOOL_GUARD_ENABLED:
            repaired, repairs = _repair_cline_openai_response(parsed)
        else:
            repaired, repairs = parsed, 0
        if repairs or line_changed:
            output_lines.append("data: " + json.dumps(repaired, separators=(",", ":")))
            total_repairs += repairs
            changed = True
        else:
            output_lines.append(raw_line)

    if not changed:
        return chunk, 0
    suffix = "\n\n" if text.endswith("\n\n") else "\n"
    return ("\n".join(output_lines) + suffix).encode("utf-8"), total_repairs


def _openai_stream_has_done(chunk: bytes) -> bool:
    try:
        text = chunk.decode("utf-8", errors="replace")
    except Exception:
        return False
    return any(line.strip() == "data: [DONE]" for line in text.splitlines())


def _rewrite_openai_response(parsed: Any, route_info: Dict[str, Any]) -> Any:
    if isinstance(parsed, dict):
        parsed, cline_repairs = _repair_cline_openai_response(parsed)
        parsed = dict(parsed)
        if cline_repairs:
            route_info = dict(route_info)
            route_info["cline_execute_command_repaired"] = cline_repairs
        parsed["model"] = FORTISAI_OPENAI_ROUTER_MODEL
        parsed["fortisai"] = route_info
    return parsed


def _rewrite_openai_embeddings_response(parsed: Any, route_info: Dict[str, Any]) -> Any:
    if isinstance(parsed, dict):
        parsed = dict(parsed)
        parsed["model"] = FORTISAI_OPENAI_ROUTER_MODEL
        parsed["fortisai"] = route_info
    return parsed


def _stream_upstream_response(response: Any):
    try:
        while True:
            chunk = response.read(8192)
            if not chunk:
                break
            yield chunk
    finally:
        response.close()


def _openai_stream_chunk(
    route_info: Dict[str, Any],
    delta: Optional[Dict[str, Any]] = None,
    stream_id: Optional[str] = None,
    created: Optional[int] = None,
) -> bytes:
    payload = {
        "id": stream_id or f"chatcmpl-fortisai-{uuid.uuid4().hex}",
        "object": "chat.completion.chunk",
        "created": created or int(time.time()),
        "model": FORTISAI_OPENAI_ROUTER_MODEL,
        "choices": [
            {
                "index": 0,
                "delta": delta if delta is not None else {"content": ""},
                "finish_reason": None,
            }
        ],
    }
    return f"data: {json.dumps(payload, separators=(',', ':'))}\n\n".encode("utf-8")


def _sse_comment(comment: str) -> bytes:
    safe_comment = str(comment or "keepalive").replace("\r", " ").replace("\n", " ")
    return f": {safe_comment}\n\n".encode("utf-8")


def _sse_error(payload: Dict[str, Any]) -> bytes:
    return f"data: {json.dumps({'error': payload}, separators=(',', ':'))}\n\n".encode("utf-8")


def _extract_openai_response_text(parsed: Any) -> str:
    if not isinstance(parsed, dict):
        return ""
    choices = parsed.get("choices")
    if not isinstance(choices, list):
        return ""
    parts: list[str] = []
    for choice in choices:
        if not isinstance(choice, dict):
            continue
        message = choice.get("message")
        if isinstance(message, dict):
            content = _extract_content_text(message.get("content")).strip()
            if content:
                parts.append(content)
        text = _extract_content_text(choice.get("text")).strip()
        if text:
            parts.append(text)
    return "\n".join(parts)


def _extract_openai_stream_text(chunk: bytes) -> str:
    try:
        text = chunk.decode("utf-8", errors="replace")
    except Exception:
        return ""
    parts: list[str] = []
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line.startswith("data:"):
            continue
        data = line[5:].strip()
        if not data or data == "[DONE]":
            continue
        try:
            parsed = json.loads(data)
        except json.JSONDecodeError:
            continue
        if not isinstance(parsed, dict):
            continue
        choices = parsed.get("choices")
        if not isinstance(choices, list):
            continue
        for choice in choices:
            if not isinstance(choice, dict):
                continue
            delta = choice.get("delta")
            if isinstance(delta, dict):
                delta_text = _extract_content_text(delta.get("content"))
                if delta_text:
                    parts.append(delta_text)
            choice_text = _extract_content_text(choice.get("text"))
            if choice_text:
                parts.append(choice_text)
    return "".join(parts)


def _honcho_message_content(text: str) -> str:
    return str(text or "").strip()[:25000]


def _honcho_writeback(
    honcho_context: Optional[Dict[str, Any]],
    route_info: Dict[str, Any],
    endpoint_path: str,
    assistant_text: str,
    strict: bool,
) -> None:
    if not honcho_context:
        return

    messages: list[Dict[str, Any]] = []
    metadata = {
        "source": "fortisai_llm_proxy",
        "endpoint": endpoint_path,
        "router_model": FORTISAI_OPENAI_ROUTER_MODEL,
        "routed_model": route_info.get("routed_model"),
        "request_type": route_info.get("request_type"),
        "honcho_model": FORTISAI_HONCHO_MODEL,
        "honcho_session_scope": honcho_context.get("session_scope"),
        "source_conversation_id": honcho_context.get("raw_session"),
        "source_user_id": honcho_context.get("raw_user"),
    }
    user_text = _honcho_message_content(str(honcho_context.get("user_text") or ""))
    if user_text:
        messages.append(
            {
                "content": user_text,
                "peer_id": honcho_context["user_peer_id"],
                "metadata": {
                    **metadata,
                    "role": "user",
                },
            }
        )

    assistant_content = _honcho_message_content(assistant_text)
    if assistant_content:
        messages.append(
            {
                "content": assistant_content,
                "peer_id": honcho_context["assistant_peer_id"],
                "metadata": {
                    **metadata,
                    "role": "assistant",
                },
            }
        )

    if not messages:
        return

    try:
        workspace_id = _honcho_encode_id(honcho_context["workspace_id"])
        session_id = _honcho_encode_id(honcho_context["session_id"])
        _honcho_request(
            "POST",
            f"/v3/workspaces/{workspace_id}/sessions/{session_id}/messages",
            {"messages": messages},
        )
    except Exception as exc:
        if strict and FORTISAI_HONCHO_REQUIRED:
            raise _honcho_error_response(exc) from exc
        log.warning("Honcho writeback failed: %s", exc)


def _stream_upstream_response_with_keepalive(
    request: urllib.request.Request,
    route_info: Dict[str, Any],
    timeout_seconds: int,
    endpoint_path: str,
    honcho_context: Optional[Dict[str, Any]] = None,
):
    events: "queue.Queue[tuple[str, Any]]" = queue.Queue()
    assistant_parts: list[str] = []
    cline_stream_state = {"inside_execute_command": False, "requires_approval_seen": False}
    cline_stream_repairs = 0
    stream_done_seen = False

    def upstream_worker() -> None:
        timings = _route_timings(route_info)
        upstream_started_at = time.monotonic()
        try:
            response = urllib.request.urlopen(request, timeout=timeout_seconds)
        except urllib.error.HTTPError as exc:
            raw = exc.read()
            parsed = _parse_upstream_body(raw)
            log.warning(
                "FortisAI streaming upstream HTTP error: endpoint=%s routed_model=%s status=%s",
                endpoint_path,
                route_info.get("routed_model"),
                exc.code,
            )
            timings["upstream_stream_ms"] = _elapsed_ms(upstream_started_at)
            events.put(("http_error", {"status_code": exc.code, "upstream": parsed}))
            return
        except Exception as exc:
            timings["upstream_stream_ms"] = _elapsed_ms(upstream_started_at)
            log.exception("FortisAI streaming upstream request failed")
            events.put(("error", {"error": str(exc)}))
            return

        try:
            events.put(("response", {"status_code": getattr(response, "status", 200)}))
            while True:
                chunk = response.readline()
                if not chunk:
                    break
                events.put(("chunk", chunk))
        except Exception as exc:
            log.exception("FortisAI streaming upstream read failed")
            events.put(("error", {"error": str(exc)}))
        finally:
            timings["upstream_stream_ms"] = _elapsed_ms(upstream_started_at)
            log.info(
                "FortisAI router stream completed: endpoint=%s routed_model=%s request_type=%s timings_ms=%s default_cap=%s",
                endpoint_path,
                route_info.get("routed_model"),
                route_info.get("request_type"),
                timings,
                route_info.get("default_output_cap_tokens") or route_info.get("output_cap_hard_limit_tokens"),
            )
            response.close()
            events.put(("done", None))

    threading.Thread(target=upstream_worker, name="fortisai-upstream-stream", daemon=True).start()

    stream_id = f"chatcmpl-fortisai-{uuid.uuid4().hex}"
    created = int(time.time())
    yield _openai_stream_chunk(route_info, {"role": "assistant", "content": ""}, stream_id, created)
    while True:
        try:
            kind, payload = events.get(timeout=max(1.0, FORTISAI_OPENAI_ROUTER_STREAM_KEEPALIVE_SECONDS))
        except queue.Empty:
            yield _sse_comment("fortisai keepalive")
            continue

        if kind == "response":
            continue
        if kind == "chunk":
            assistant_delta = _extract_openai_stream_text(payload)
            if assistant_delta:
                assistant_parts.append(assistant_delta)
            if _openai_stream_has_done(payload):
                stream_done_seen = True
            repaired_payload, repairs = _repair_cline_openai_stream_chunk(payload, cline_stream_state)
            if repairs:
                cline_stream_repairs += repairs
            if _openai_stream_has_done(repaired_payload):
                stream_done_seen = True
            yield repaired_payload
            continue
        if kind == "http_error":
            yield _sse_error({"upstream": payload, "fortisai": route_info})
            yield b"data: [DONE]\n\n"
            break
        if kind == "error":
            yield _sse_error(
                {
                    "error": "FortisAI local OpenAI-compatible endpoint is unavailable",
                    "upstream": payload,
                    "fortisai": route_info,
                }
            )
            yield b"data: [DONE]\n\n"
            break
        if kind == "done":
            if cline_stream_repairs:
                route_info = dict(route_info)
                route_info["cline_execute_command_repaired"] = cline_stream_repairs
            _honcho_writeback(
                honcho_context=honcho_context,
                route_info=route_info,
                endpoint_path=endpoint_path,
                assistant_text="".join(assistant_parts),
                strict=False,
            )
            if not stream_done_seen:
                yield b"data: [DONE]\n\n"
            break


def _coerce_positive_token_limit(value: Any) -> Optional[int]:
    if isinstance(value, bool) or value is None:
        return None
    try:
        token_limit = int(value)
    except (TypeError, ValueError):
        return None
    if token_limit <= 0:
        return None
    return token_limit


def _apply_output_token_limits(endpoint_path: str, payload: Dict[str, Any], route_info: Dict[str, Any]) -> Dict[str, Any]:
    cap_fields = ("max_tokens", "max_completion_tokens") if endpoint_path == "/chat/completions" else ("max_tokens",)
    capped_payload = dict(payload)

    if FORTISAI_OPENAI_ROUTER_DEFAULT_MAX_TOKENS > 0 and not any(
        field in capped_payload and capped_payload[field] is not None for field in cap_fields
    ):
        cap_tokens = FORTISAI_OPENAI_ROUTER_DEFAULT_MAX_TOKENS
        cline_guard = route_info.get("cline_tool_guard")
        if isinstance(cline_guard, dict) and FORTISAI_CLINE_TOOL_MAX_TOKENS > 0:
            cap_tokens = min(cap_tokens, FORTISAI_CLINE_TOOL_MAX_TOKENS)
            cline_guard["default_output_cap_tokens"] = cap_tokens

        capped_payload["max_tokens"] = cap_tokens
        route_info["default_output_cap_applied"] = True
        route_info["default_output_cap_tokens"] = cap_tokens

    hard_limit = FORTISAI_OPENAI_ROUTER_MAX_TOKENS_HARD_LIMIT
    if hard_limit <= 0:
        return capped_payload

    for field in cap_fields:
        token_limit = _coerce_positive_token_limit(capped_payload.get(field))
        if token_limit is None or token_limit <= hard_limit:
            continue
        capped_payload[field] = hard_limit
        route_info["output_cap_hard_limit_tokens"] = hard_limit
        route_info["output_cap_clamped"] = True
        route_info.setdefault("output_cap_original_tokens", {})[field] = token_limit
    return capped_payload



def _bridge_tool_builtin_registry() -> Dict[str, Dict[str, Any]]:
    base = FORTISAI_WEBSEARCH_OPENAPI_BASE_URL
    return {
        "websearch_search": {
            "method": "POST",
            "url": f"{base}/websearch_search",
            "description": "Search the web through the FortisAI Firecrawl websearch bridge.",
            "source": "builtin_websearch",
        },
        "websearch": {
            "method": "POST",
            "url": f"{base}/websearch",
            "description": "Compatibility alias for websearch_search.",
            "source": "builtin_websearch",
        },
        "websearch_scrape": {
            "method": "POST",
            "url": f"{base}/websearch_scrape",
            "description": "Scrape one URL through the FortisAI Firecrawl websearch bridge.",
            "source": "builtin_websearch",
        },
    }


def _bridge_tool_skill_root() -> str:
    configured = FORTISAI_TOOL_EXECUTION_SKILL_ROOT
    if configured and os.path.isdir(configured):
        return configured
    workspace_fallback = "/workspace/Development_Environment/mcp"
    if os.path.isdir(workspace_fallback):
        return workspace_fallback
    local_fallback = os.path.join(os.getcwd(), "Development_Environment", "mcp")
    if os.path.isdir(local_fallback):
        return local_fallback
    return configured


def _bridge_read_json_file(path: str) -> Optional[Any]:
    try:
        with open(path, "r", encoding="utf-8") as handle:
            return json.load(handle)
    except Exception as exc:
        log.debug("FortisAI tool bridge skipped JSON file: path=%s error=%s", path, exc)
        return None


def _bridge_iter_skill_asset_files() -> list[str]:
    root = _bridge_tool_skill_root()
    if not root or not os.path.isdir(root):
        return []
    result: list[str] = []
    for dirpath, _dirnames, filenames in os.walk(root):
        for filename in filenames:
            if filename.endswith(("tools.import.json", "skill.create.json", "skill.content.md")):
                result.append(os.path.join(dirpath, filename))
    return sorted(result)


def _bridge_tool_server_imports_from_skills() -> Dict[str, Dict[str, Any]]:
    imports: Dict[str, Dict[str, Any]] = {}
    for asset_path in _bridge_iter_skill_asset_files():
        if not asset_path.endswith("tools.import.json"):
            continue
        parsed = _bridge_read_json_file(asset_path)
        entries = parsed if isinstance(parsed, list) else [parsed]
        for entry in entries:
            if not isinstance(entry, dict):
                continue
            config = entry.get("config") if isinstance(entry.get("config"), dict) else {}
            if config.get("enable") is False:
                continue
            info = entry.get("info") if isinstance(entry.get("info"), dict) else {}
            server_name = str(info.get("name") or "").strip()
            base_url = str(entry.get("url") or "").rstrip("/")
            spec_path = str(entry.get("path") or "openapi.json").lstrip("/")
            if not server_name or not base_url:
                continue
            imports[server_name] = {
                "name": server_name,
                "base_url": base_url,
                "openapi_url": f"{base_url}/{spec_path}",
                "asset_path": asset_path,
                "function_name_filter_list": str(config.get("function_name_filter_list") or "").strip(),
            }
    return imports


def _bridge_tool_filter_allows(source: Dict[str, Any], aliases: list[str], path: str, operation_id: str) -> bool:
    raw_filter = str(source.get("function_name_filter_list") or "").strip()
    if not raw_filter:
        return True
    filters = [
        item.strip()
        for item in re.split(r"[\s,]+", raw_filter)
        if item.strip()
    ]
    if not filters:
        return True
    candidates = {str(path or "").strip(), str(operation_id or "").strip(), *aliases}
    for item in filters:
        normalized = re.sub(r"[^A-Za-z0-9_]", "_", item).strip("_")
        if item in candidates or (normalized and normalized in candidates):
            return True
    return False


def _bridge_openwebui_skill_api_url(path: str = "") -> str:
    if not FORTISAI_OPENWEBUI_URL:
        return ""
    suffix = str(path or "").lstrip("/")
    base = f"{FORTISAI_OPENWEBUI_URL}/api/v1/skills"
    return f"{base}/{suffix}" if suffix else f"{base}/"


def _bridge_extract_openwebui_skill_text(value: Any, depth: int = 0) -> str:
    if depth > 4 or value is None:
        return ""
    if isinstance(value, str):
        return value
    if isinstance(value, list):
        return "\n".join(
            part
            for part in (_bridge_extract_openwebui_skill_text(item, depth + 1) for item in value)
            if part
        )
    if not isinstance(value, dict):
        return ""

    parts: list[str] = []
    for key in (
        "name",
        "title",
        "description",
        "content",
        "prompt",
        "instructions",
        "instruction",
        "system_prompt",
    ):
        raw = value.get(key)
        if isinstance(raw, str) and raw.strip():
            parts.append(raw)

    for key in ("skill", "meta", "info", "data", "spec"):
        raw = value.get(key)
        nested = _bridge_extract_openwebui_skill_text(raw, depth + 1)
        if nested:
            parts.append(nested)

    return "\n".join(parts)


def _bridge_safe_vault_user_segment(value: str) -> str:
    text = str(value or "").strip().lower()
    return re.sub(r"[^a-z0-9]+", "_", text).strip("_")


def _bridge_vault_get_secret_value(path: str) -> str:
    clean_path = str(path or "").strip().strip("/")
    if not clean_path or ".." in clean_path or not FORTISAI_VAULT_ADDR or not FORTISAI_VAULT_TOKEN:
        return ""
    encoded_path = "/".join(urllib.parse.quote(part, safe="") for part in clean_path.split("/"))
    url = f"{FORTISAI_VAULT_ADDR}/v1/secret/data/fortisai/dev/{encoded_path}"
    request = urllib.request.Request(
        url=url,
        headers={
            "Accept": "application/json",
            "X-Vault-Token": FORTISAI_VAULT_TOKEN,
        },
        method="GET",
    )
    try:
        with urllib.request.urlopen(request, timeout=FORTISAI_TOOL_EXECUTION_OPENAPI_FETCH_TIMEOUT_SECONDS) as response:
            parsed = _parse_upstream_body(response.read())
    except urllib.error.HTTPError as exc:
        try:
            exc.read()
        except Exception:
            pass
        if exc.code not in {403, 404}:
            log.warning("FortisAI tool bridge Vault lookup failed: path=%s status=%s", clean_path, exc.code)
        return ""
    except Exception as exc:
        log.warning("FortisAI tool bridge Vault lookup skipped: path=%s error=%s", clean_path, exc)
        return ""
    if not isinstance(parsed, dict):
        return ""
    value = parsed.get("data", {}).get("data", {}).get("value", "")
    return str(value or "").strip()


def _bridge_openwebui_identity_values(payload: Dict[str, Any], http_request: Optional[Request]) -> list[str]:
    metadata = payload.get("metadata") if isinstance(payload.get("metadata"), dict) else {}
    inputs = payload.get("inputs") if isinstance(payload.get("inputs"), dict) else {}
    values = [
        _request_header(http_request, "x-openwebui-user-email", "x-openwebui-user-mail", "x-user-email"),
        _request_header(http_request, "x-openwebui-user-id", "x-user-id"),
        _request_header(http_request, "x-openwebui-user-name", "x-user-name"),
        metadata.get("openwebui_user_email"),
        metadata.get("user_email"),
        metadata.get("email"),
        metadata.get("openwebui_user_id"),
        metadata.get("user_id"),
        inputs.get("openwebui_user_email"),
        inputs.get("user_email"),
        inputs.get("openwebui_user_id"),
        inputs.get("user_id"),
        payload.get("openwebui_user_email"),
        payload.get("user_email"),
        payload.get("openwebui_user_id"),
        payload.get("user_id"),
        payload.get("user"),
    ]
    result: list[str] = []
    seen: set[str] = set()
    for value in values:
        text = str(value or "").strip()
        if not text or text.lower() in {"openwebui", "anonymous", "default"}:
            continue
        key = text.lower()
        if key in seen:
            continue
        seen.add(key)
        result.append(text)
    return result


def _bridge_openwebui_api_key_context(
    payload: Optional[Dict[str, Any]] = None,
    http_request: Optional[Request] = None,
) -> Dict[str, str]:
    payload = payload if isinstance(payload, dict) else {}
    identity_values = _bridge_openwebui_identity_values(payload, http_request)
    search_identities = list(identity_values)
    if not search_identities and FORTISAI_OPENWEBUI_DEFAULT_API_KEY_USER:
        search_identities.append(FORTISAI_OPENWEBUI_DEFAULT_API_KEY_USER)

    for identity in search_identities:
        user_segment = _bridge_safe_vault_user_segment(identity)
        if not user_segment:
            continue
        vault_path = f"openwebui/users/{user_segment}/api_key"
        api_key = _bridge_vault_get_secret_value(vault_path)
        if api_key:
            return {
                "api_key": api_key,
                "source": "vault_user",
                "identity": identity,
                "vault_user": user_segment,
                "cache_key": f"openwebui-user:{user_segment}",
            }

    if identity_values:
        return {
            "api_key": "",
            "source": "missing_user_key",
            "identity": identity_values[0],
            "vault_user": _bridge_safe_vault_user_segment(identity_values[0]),
            "cache_key": f"openwebui-missing:{_bridge_safe_vault_user_segment(identity_values[0]) or 'unknown'}",
        }

    return {"api_key": "", "source": "unavailable", "identity": "", "vault_user": "", "cache_key": "repo-fallback"}


def _bridge_openwebui_get_json(api_key: str, path: str) -> Optional[Any]:
    url = _bridge_openwebui_skill_api_url(path)
    if not url:
        return None
    request = urllib.request.Request(
        url=url,
        headers={
            "Accept": "application/json",
            "Authorization": f"Bearer {api_key}",
        },
        method="GET",
    )
    try:
        with urllib.request.urlopen(request, timeout=FORTISAI_TOOL_EXECUTION_OPENAPI_FETCH_TIMEOUT_SECONDS) as response:
            return _parse_upstream_body(response.read())
    except urllib.error.HTTPError as exc:
        try:
            exc.read()
        except Exception:
            pass
        log.warning("FortisAI tool bridge OpenWebUI skill API path skipped: path=%s status=%s", path or "/", exc.code)
        return None
    except Exception as exc:
        log.warning("FortisAI tool bridge OpenWebUI skill API path skipped: path=%s error=%s", path or "/", exc)
        return None


def _bridge_openwebui_skill_items_from_payload(payload: Any) -> list[Any]:
    if isinstance(payload, list):
        return payload
    if isinstance(payload, dict):
        for key in ("data", "skills", "items", "results"):
            if isinstance(payload.get(key), list):
                return payload.get(key) or []
    return []


def _bridge_openwebui_skill_payloads(api_key: str) -> Optional[list[Any]]:
    export_payload = _bridge_openwebui_get_json(api_key, "export")
    export_items = _bridge_openwebui_skill_items_from_payload(export_payload)
    if export_payload is not None:
        if export_items:
            return export_items
        log.warning("FortisAI tool bridge OpenWebUI skill export returned an unexpected payload shape")

    list_payload = _bridge_openwebui_get_json(api_key, "")
    list_items = _bridge_openwebui_skill_items_from_payload(list_payload)
    if list_payload is None:
        return None
    if not list_items:
        log.warning("FortisAI tool bridge OpenWebUI skill list returned an unexpected payload shape")
        return []

    detailed_items: list[Any] = []
    for item in list_items:
        if not isinstance(item, dict):
            detailed_items.append(item)
            continue
        skill_id = str(item.get("id") or "").strip()
        content = _bridge_extract_openwebui_skill_text(item)
        if skill_id and "Required OpenWebUI tool server" not in content:
            detail = _bridge_openwebui_get_json(api_key, f"id/{urllib.parse.quote(skill_id, safe='')}")
            if isinstance(detail, dict):
                detailed_items.append(detail)
                continue
        detailed_items.append(item)
    return detailed_items


def _bridge_openwebui_skill_texts(api_key_context: Optional[Dict[str, str]] = None) -> Optional[list[str]]:
    if not FORTISAI_TOOL_EXECUTION_OPENWEBUI_SKILL_API_ENABLED:
        return None
    api_key_context = api_key_context if isinstance(api_key_context, dict) else _bridge_openwebui_api_key_context()
    api_key = str(api_key_context.get("api_key") or "").strip()
    if not api_key:
        log.info("FortisAI tool bridge OpenWebUI skill API skipped: user API key unavailable")
        return None

    raw_items = _bridge_openwebui_skill_payloads(api_key)
    if raw_items is None:
        return None

    texts = []
    for item in raw_items:
        content = _bridge_extract_openwebui_skill_text(item).strip()
        if content:
            texts.append(content)
    log.info(
        "FortisAI tool bridge loaded OpenWebUI skills: count=%s api_key_source=%s user=%s",
        len(texts),
        api_key_context.get("source"),
        api_key_context.get("vault_user"),
    )
    return texts


def _bridge_skill_texts_by_server_from_texts(
    imports: Dict[str, Dict[str, Any]],
    skill_text_items: list[str],
) -> Dict[str, str]:
    texts: Dict[str, list[str]] = {name: [] for name in imports}
    for content in skill_text_items:
        if not content:
            continue
        for server_name in imports:
            if server_name in content:
                texts.setdefault(server_name, []).append(content)
    return {name: "\n".join(parts) for name, parts in texts.items() if parts}


def _bridge_repo_skill_text_items() -> list[str]:
    items: list[str] = []
    for asset_path in _bridge_iter_skill_asset_files():
        content = ""
        if asset_path.endswith("skill.create.json"):
            parsed = _bridge_read_json_file(asset_path)
            if isinstance(parsed, dict):
                content = str(parsed.get("content") or "")
        elif asset_path.endswith("skill.content.md"):
            try:
                with open(asset_path, "r", encoding="utf-8") as handle:
                    content = handle.read()
            except Exception as exc:
                log.debug("FortisAI tool bridge skipped skill content: path=%s error=%s", asset_path, exc)
        if content.strip():
            items.append(content)
    return items


def _bridge_skill_texts_by_server(
    imports: Dict[str, Dict[str, Any]],
    api_key_context: Optional[Dict[str, str]] = None,
) -> Dict[str, str]:
    live_skill_texts = _bridge_openwebui_skill_texts(api_key_context)
    if live_skill_texts is not None:
        live_matches = _bridge_skill_texts_by_server_from_texts(imports, live_skill_texts)
        if live_matches:
            log.info(
                "FortisAI tool bridge using OpenWebUI skill API for tool discovery: matched_servers=%s",
                len(live_matches),
            )
            return live_matches
        log.warning("FortisAI tool bridge OpenWebUI skill API produced no matching tool-server skill text; falling back to repo skill payloads")

    repo_matches = _bridge_skill_texts_by_server_from_texts(imports, _bridge_repo_skill_text_items())
    if repo_matches:
        log.info(
            "FortisAI tool bridge using repo skill payload fallback for tool discovery: matched_servers=%s",
            len(repo_matches),
        )
    return repo_matches


def _bridge_tool_aliases(path: str, method: str, operation_id: str) -> list[str]:
    aliases: list[str] = []
    if operation_id:
        aliases.append(operation_id)
        suffix = f"_{method.lower()}"
        if operation_id.endswith(suffix):
            aliases.append(operation_id[: -len(suffix)])
        if operation_id.startswith("tool_") and operation_id.endswith(suffix):
            aliases.append(operation_id[len("tool_") : -len(suffix)])

    first_segment = path.strip("/").split("/", 1)[0]
    if first_segment and "{" not in first_segment and first_segment not in {"healthz", "livez", "readyz"}:
        aliases.append(first_segment)

    result: list[str] = []
    seen: set[str] = set()
    for alias in aliases:
        clean = re.sub(r"[^A-Za-z0-9_]", "_", str(alias or "").strip()).strip("_")
        if not clean or clean in seen:
            continue
        seen.add(clean)
        result.append(clean)
    return result


def _bridge_openapi_resolve_schema(spec: Dict[str, Any], schema: Any) -> Dict[str, Any]:
    if not isinstance(schema, dict):
        return {}
    ref = str(schema.get("$ref") or "").strip()
    if not ref.startswith("#/"):
        return schema
    current: Any = spec
    for part in ref[2:].split("/"):
        if not isinstance(current, dict):
            return {}
        current = current.get(part.replace("~1", "/").replace("~0", "~"))
    return current if isinstance(current, dict) else {}


def _bridge_operation_required_body_fields(spec: Dict[str, Any], operation: Dict[str, Any]) -> list[str]:
    request_body = operation.get("requestBody") if isinstance(operation.get("requestBody"), dict) else {}
    content = request_body.get("content") if isinstance(request_body.get("content"), dict) else {}
    schema: Any = {}
    for content_type in ("application/json", "application/x-www-form-urlencoded", "multipart/form-data"):
        media = content.get(content_type) if isinstance(content.get(content_type), dict) else {}
        if isinstance(media.get("schema"), dict):
            schema = media.get("schema")
            break
    schema = _bridge_openapi_resolve_schema(spec, schema)
    required = schema.get("required") if isinstance(schema, dict) else []
    if isinstance(required, list):
        return [str(item) for item in required if str(item or "").strip()]
    return []


def _bridge_skill_mentions_tool(skill_text: str, aliases: list[str], path: str) -> bool:
    if not skill_text:
        return False
    for alias in aliases:
        if re.search(rf"(?<![A-Za-z0-9_]){re.escape(alias)}(?![A-Za-z0-9_])", skill_text):
            return True
        if f"/{alias}" in skill_text:
            return True
    first_segment = path.strip("/").split("/", 1)[0]
    return bool(first_segment and f"/{first_segment}" in skill_text)


def _bridge_tool_registry_from_skills(
    payload: Optional[Dict[str, Any]] = None,
    http_request: Optional[Request] = None,
) -> Dict[str, Dict[str, Any]]:
    if not FORTISAI_TOOL_EXECUTION_SKILL_DISCOVERY_ENABLED:
        return {}
    api_key_context = _bridge_openwebui_api_key_context(payload, http_request)
    cache_key = str(api_key_context.get("cache_key") or "repo-fallback")
    now = time.monotonic()
    registries = _BRIDGE_TOOL_REGISTRY_CACHE.setdefault("registries", {})
    cached_entry = registries.get(cache_key) if isinstance(registries, dict) else None
    if isinstance(cached_entry, dict):
        cached_registry = cached_entry.get("registry")
        cached_expires_at = float(cached_entry.get("expires_at") or 0.0)
        if isinstance(cached_registry, dict) and cached_registry and cached_expires_at > now:
            return dict(cached_registry)

    registry: Dict[str, Dict[str, Any]] = {}
    imports = _bridge_tool_server_imports_from_skills()
    skill_texts = _bridge_skill_texts_by_server(imports, api_key_context)
    for server_name, source in imports.items():
        skill_text = skill_texts.get(server_name, "")
        if not skill_text:
            continue
        base_url = str(source.get("base_url") or "").rstrip("/")
        openapi_url = str(source.get("openapi_url") or "")
        try:
            request = urllib.request.Request(url=openapi_url, headers={"Accept": "application/json"}, method="GET")
            with urllib.request.urlopen(request, timeout=FORTISAI_TOOL_EXECUTION_OPENAPI_FETCH_TIMEOUT_SECONDS) as response:
                spec = _parse_upstream_body(response.read())
        except Exception as exc:
            log.warning("FortisAI tool bridge skill source skipped: server=%s url=%s error=%s", server_name, openapi_url, exc)
            continue
        paths = spec.get("paths") if isinstance(spec, dict) else None
        if not isinstance(paths, dict):
            continue
        for api_path, methods in paths.items():
            if not isinstance(methods, dict):
                continue
            for method, operation in methods.items():
                method_upper = str(method or "").upper()
                if method_upper not in {"GET", "POST", "PUT", "PATCH", "DELETE"} or not isinstance(operation, dict):
                    continue
                operation_id = str(operation.get("operationId") or "").strip()
                aliases = _bridge_tool_aliases(str(api_path), method_upper, operation_id)
                if not aliases or not _bridge_tool_filter_allows(source, aliases, str(api_path), operation_id):
                    continue
                entry = {
                    "method": method_upper,
                    "url": f"{base_url}{api_path}",
                    "base_url": base_url,
                    "path": str(api_path),
                    "path_params": re.findall(r"{([^}/]+)}", str(api_path)),
                    "description": str(operation.get("summary") or operation.get("description") or ""),
                    "source": f"skill:{server_name}",
                    "server_name": server_name,
                    "operation_id": operation_id,
                    "required_body_fields": _bridge_operation_required_body_fields(spec, operation),
                }
                for alias in aliases:
                    registry[alias] = dict(entry)

    refresh_seconds = FORTISAI_TOOL_EXECUTION_SKILL_REFRESH_SECONDS
    expires_at = now + refresh_seconds if refresh_seconds > 0 else 0.0
    if isinstance(registries, dict):
        registries[cache_key] = {"registry": dict(registry), "expires_at": expires_at}
    _BRIDGE_TOOL_REGISTRY_CACHE["registry"] = dict(registry)
    _BRIDGE_TOOL_REGISTRY_CACHE["expires_at"] = expires_at
    log.info(
        "FortisAI tool bridge loaded skill registry: tools=%s tool_servers=%s skill_servers=%s api_key_source=%s user=%s",
        len(registry),
        len(imports),
        len(skill_texts),
        api_key_context.get("source"),
        api_key_context.get("vault_user"),
    )
    if registry:
        _qdrant_upsert_tool_registry_async(registry, cache_key)
    return registry


def _bridge_tool_apply_registry_json(registry: Dict[str, Dict[str, Any]]) -> Dict[str, Dict[str, Any]]:
    if not FORTISAI_TOOL_EXECUTION_REGISTRY_JSON:
        return registry

    try:
        parsed = json.loads(FORTISAI_TOOL_EXECUTION_REGISTRY_JSON)
    except json.JSONDecodeError as exc:
        log.warning("FortisAI tool bridge registry JSON ignored: %s", exc)
        return registry

    if not isinstance(parsed, dict):
        log.warning("FortisAI tool bridge registry JSON ignored: expected an object")
        return registry

    for name, spec in parsed.items():
        tool_name = str(name or "").strip()
        if not tool_name:
            continue
        if spec is False or spec is None:
            registry.pop(tool_name, None)
            continue
        if isinstance(spec, str):
            registry[tool_name] = {"method": "POST", "url": spec.strip(), "source": "manual_registry"}
        elif isinstance(spec, dict):
            base_url = str(spec.get("base_url") or spec.get("baseUrl") or "").rstrip("/")
            spec_path = str(spec.get("path") or "").strip()
            url = str(spec.get("url") or "").strip()
            if not url and base_url and spec_path:
                url = f"{base_url}/{spec_path.lstrip('/')}"
            if not url:
                log.warning("FortisAI tool bridge registry entry ignored without URL: %s", tool_name)
                continue
            registry[tool_name] = {
                "method": str(spec.get("method") or "POST").upper(),
                "url": url,
                "headers": spec.get("headers") if isinstance(spec.get("headers"), dict) else {},
                "description": str(spec.get("description") or ""),
                "path_params": spec.get("path_params") if isinstance(spec.get("path_params"), list) else [],
                "source": "manual_registry",
            }
    return registry


def _bridge_tool_registry(
    payload: Optional[Dict[str, Any]] = None,
    http_request: Optional[Request] = None,
) -> Dict[str, Dict[str, Any]]:
    registry = _bridge_tool_builtin_registry()
    registry.update(_bridge_tool_registry_from_skills(payload, http_request))
    return _bridge_tool_apply_registry_json(registry)

def _normalize_bridge_tool_arguments(value: Any) -> Dict[str, Any]:
    if isinstance(value, dict):
        return dict(value)
    if isinstance(value, str):
        stripped = value.strip()
        if not stripped:
            return {}
        try:
            parsed = json.loads(stripped)
            return dict(parsed) if isinstance(parsed, dict) else {}
        except json.JSONDecodeError:
            return _parse_pythonish_tool_kwargs(stripped)
    return {}


def _parse_pythonish_tool_kwargs(raw_params: str) -> Dict[str, Any]:
    raw_params = str(raw_params or "").strip()
    if not raw_params:
        return {}

    try:
        parsed = ast.parse(f"_tool({raw_params})", mode="eval")
        call = parsed.body
        if isinstance(call, ast.Call):
            result: Dict[str, Any] = {}
            for keyword in call.keywords:
                if not keyword.arg:
                    continue
                try:
                    result[keyword.arg] = ast.literal_eval(keyword.value)
                except Exception:
                    result[keyword.arg] = ast.get_source_segment(f"_tool({raw_params})", keyword.value) or ""
            if result:
                return result
    except SyntaxError:
        pass

    result: Dict[str, Any] = {}
    for part in re.split(r",\s*(?=[A-Za-z_][A-Za-z0-9_]*\s*=)", raw_params):
        if "=" not in part:
            continue
        key, value = part.split("=", 1)
        key = key.strip()
        value = value.strip()
        if not key:
            continue
        try:
            result[key] = ast.literal_eval(value)
        except Exception:
            result[key] = value.strip().strip(chr(34)).strip(chr(39))
    return result


def _bridge_tool_call_from_mapping(item: Any, source: str) -> Optional[Dict[str, Any]]:
    if not isinstance(item, dict):
        return None
    function_info = item.get("function") if isinstance(item.get("function"), dict) else {}
    name = str(
        item.get("name")
        or item.get("tool")
        or item.get("tool_name")
        or item.get("toolName")
        or function_info.get("name")
        or ""
    ).strip()
    if not name:
        return None
    raw_args = None
    for key in ("parameters", "arguments", "args", "input"):
        if key in item:
            raw_args = item.get(key)
            break
    if raw_args is None:
        raw_args = function_info.get("arguments")
    if raw_args is None:
        ignored = {"name", "tool", "tool_name", "toolName", "function", "id", "type", "source"}
        raw_args = {key: value for key, value in item.items() if key not in ignored}
    return {
        "name": name,
        "parameters": _normalize_bridge_tool_arguments(raw_args),
        "source": source,
    }


def _bridge_tool_calls_from_json_text(text: str) -> list[Dict[str, Any]]:
    if not text or "{" not in text:
        return []
    start = text.find("{")
    end = text.rfind("}")
    if start < 0 or end <= start:
        return []
    snippet = text[start : end + 1]
    try:
        parsed = json.loads(snippet)
    except json.JSONDecodeError:
        return []
    if not isinstance(parsed, dict):
        return []

    calls: list[Dict[str, Any]] = []
    raw_calls = parsed.get("tool_calls") or parsed.get("tools")
    if isinstance(raw_calls, list):
        for item in raw_calls:
            call = _bridge_tool_call_from_mapping(item, "json_text")
            if call:
                calls.append(call)
    else:
        call = _bridge_tool_call_from_mapping(parsed, "json_text")
        if call:
            calls.append(call)
    return calls


def _bridge_ast_call_name(node: ast.AST) -> str:
    if isinstance(node, ast.Name):
        return node.id
    if isinstance(node, ast.Attribute):
        return node.attr
    return ""


def _bridge_tool_call_from_pythonish_text(raw_text: str, source: str) -> Optional[Dict[str, Any]]:
    raw = str(raw_text or "").strip()
    if not raw:
        return None
    raw = re.sub(r"^```(?:json|python)?\s*", "", raw, flags=re.IGNORECASE).strip()
    raw = re.sub(r"\s*```$", "", raw).strip()
    raw = re.sub(r"</?(?:code|tool_call)>", "", raw, flags=re.IGNORECASE).strip()

    try:
        parsed = ast.parse(raw, mode="eval")
        expression = parsed.body
        if isinstance(expression, ast.Call):
            name = _bridge_ast_call_name(expression.func).strip()
            if not name:
                return None
            params: Dict[str, Any] = {}
            for index, arg in enumerate(expression.args):
                try:
                    value = ast.literal_eval(arg)
                except Exception:
                    value = ast.get_source_segment(raw, arg) or ""
                if index == 0 and isinstance(value, dict):
                    params.update(value)
                else:
                    params[f"arg{index}"] = value
            for keyword in expression.keywords:
                if not keyword.arg:
                    continue
                try:
                    params[keyword.arg] = ast.literal_eval(keyword.value)
                except Exception:
                    params[keyword.arg] = ast.get_source_segment(raw, keyword.value) or ""
            return {"name": name, "parameters": params, "source": source}
    except SyntaxError:
        pass

    match = re.search(r"\b([A-Za-z_][A-Za-z0-9_]*)\s*\((.*)\)\s*$", raw, flags=re.DOTALL)
    if not match:
        return None
    return {
        "name": match.group(1).strip(),
        "parameters": _parse_pythonish_tool_kwargs(match.group(2)),
        "source": source,
    }


def _bridge_tool_calls_from_xml_text(text: str) -> list[Dict[str, Any]]:
    if not text or "<tool_call" not in text.lower():
        return []
    calls: list[Dict[str, Any]] = []
    block_pattern = re.compile(
        r"<tool_call>\s*(.*?)(?:</tool_call>|</code>|(?=<tool_call>)|$)",
        re.DOTALL | re.IGNORECASE,
    )
    for match in block_pattern.finditer(text):
        block = match.group(1).strip()
        if not block:
            continue
        json_calls = _bridge_tool_calls_from_json_text(block)
        if json_calls:
            calls.extend(json_calls)
            continue
        call = _bridge_tool_call_from_pythonish_text(block, "xml_text")
        if call:
            calls.append(call)
    return calls


def _bridge_explicit_web_request(prompt_text: str) -> bool:
    text = str(prompt_text or "").lower()
    return bool(
        text
        and (
            "websearch" in text
            or "web search" in text
            or "search the web" in text
            or "current" in text
            or "latest" in text
            or "recent" in text
            or "real data" in text
            or "using data at" in text
            or "menu items" in text
            or re.search(r"\b(restaurants?|dining)\b", text)
            or re.search(r"\b(menu|hours|events?)\b.*\b(at|near|in)\b", text)
            or re.search(r"\b[a-z0-9-]+(?:\.[a-z0-9-]+)+\b", prompt_text, re.IGNORECASE)
        )
    )


_BRIDGE_TOOL_PROMPT_HINT_STOPWORDS = {
    "api",
    "bridge",
    "fortisai",
    "local",
    "mcp",
    "openapi",
    "server",
    "tool",
    "tools",
}

_BRIDGE_SHORT_PROMPT_HINTS = {"ai", "db", "id", "ip", "lxc", "vm"}


def _bridge_prompt_hint_tokens(value: str) -> set[str]:
    tokens = set()
    for token in re.findall(r"[a-z0-9]+", str(value or "").lower()):
        if token in _BRIDGE_TOOL_PROMPT_HINT_STOPWORDS:
            continue
        if len(token) < 3 and token not in _BRIDGE_SHORT_PROMPT_HINTS and not any(char.isdigit() for char in token):
            continue
        tokens.add(token)
    return tokens


def _bridge_server_prompt_hints(server_name: str) -> set[str]:
    raw = str(server_name or "").lower()
    hints = _bridge_prompt_hint_tokens(raw)
    if raw.startswith("mcp-"):
        hints.update(_bridge_prompt_hint_tokens(raw[4:]))
    return hints


def _bridge_prompt_mentions_skill_server(
    prompt_text: str,
    payload: Optional[Dict[str, Any]] = None,
    http_request: Optional[Request] = None,
) -> bool:
    prompt_tokens = _bridge_prompt_hint_tokens(prompt_text)
    if not prompt_tokens:
        return False
    imports = _bridge_tool_server_imports_from_skills()
    if not imports:
        return False
    matching_servers = [
        server_name
        for server_name in imports
        if _bridge_server_prompt_hints(server_name) & prompt_tokens
    ]
    if not matching_servers:
        return False
    api_key_context = _bridge_openwebui_api_key_context(payload, http_request)
    skill_texts = _bridge_skill_texts_by_server(imports, api_key_context)
    for server_name in matching_servers:
        if server_name in skill_texts:
            return True
    return False


_BRIDGE_READ_FALLBACK_VERBS = {
    "connection",
    "find",
    "get",
    "info",
    "inspect",
    "list",
    "query",
    "search",
    "show",
    "status",
}

_BRIDGE_DERIVABLE_QUERY_FIELDS = {"q", "query", "search", "search_query", "term", "text"}

_BRIDGE_MUTATING_FALLBACK_VERBS = {
    "cancel",
    "clear",
    "clone",
    "create",
    "delete",
    "deploy",
    "download",
    "execute",
    "index",
    "pull",
    "reset",
    "restart",
    "restore",
    "retry",
    "rollback",
    "run",
    "shutdown",
    "start",
    "stop",
    "trigger",
    "update",
}


def _bridge_match_tokens(value: str) -> set[str]:
    tokens = _bridge_prompt_hint_tokens(value)
    expanded = set(tokens)
    for token in tokens:
        if token.endswith("ies") and len(token) > 4:
            expanded.add(f"{token[:-3]}y")
        if token.endswith("s") and len(token) > 3:
            expanded.add(token[:-1])
    if "vm" in expanded:
        expanded.add("vms")
    if "vms" in expanded:
        expanded.add("vm")
    return expanded


def _bridge_read_only_fallback_allowed(name: str, spec: Dict[str, Any]) -> bool:
    if spec.get("path_params"):
        return False
    required_body_fields = [
        str(item or "").strip()
        for item in (spec.get("required_body_fields") if isinstance(spec.get("required_body_fields"), list) else [])
        if str(item or "").strip()
    ]
    if required_body_fields and not all(field in _BRIDGE_DERIVABLE_QUERY_FIELDS for field in required_body_fields):
        return False
    method = str(spec.get("method") or "").upper()
    tokens = _bridge_match_tokens(" ".join([name, str(spec.get("path") or ""), str(spec.get("operation_id") or "")]))
    if tokens & _BRIDGE_MUTATING_FALLBACK_VERBS:
        return False
    return method == "GET" or bool(tokens & _BRIDGE_READ_FALLBACK_VERBS)


def _bridge_fallback_tool_parameters(prompt_text: str, spec: Dict[str, Any]) -> Dict[str, Any]:
    params: Dict[str, Any] = {}
    required_body_fields = spec.get("required_body_fields") if isinstance(spec.get("required_body_fields"), list) else []
    for field in required_body_fields:
        field_name = str(field or "").strip()
        if field_name in _BRIDGE_DERIVABLE_QUERY_FIELDS:
            params[field_name] = _rag_limited_text(prompt_text, 500)
    return params


def _bridge_extract_github_repository(prompt_text: str) -> str:
    text = str(prompt_text or "")
    url_match = re.search(
        r"https?://github\.com/([A-Za-z0-9_.-]+)/([A-Za-z0-9_.-]+)(?:\.git)?(?:[/?#)\]\s]|$)",
        text,
        flags=re.IGNORECASE,
    )
    if url_match:
        owner = url_match.group(1).strip()
        repo = re.sub(r"\.git$", "", url_match.group(2).strip(), flags=re.IGNORECASE)
        return f"{owner}/{repo}"
    short_match = re.search(r"\b([A-Za-z0-9_.-]+)/([A-Za-z0-9_.-]+)(?:\.git)?\b", text)
    if short_match:
        owner = short_match.group(1).strip()
        repo = re.sub(r"\.git$", "", short_match.group(2).strip(), flags=re.IGNORECASE)
        if owner.lower() not in {"http:", "https:"}:
            return f"{owner}/{repo}"
    return ""


def _bridge_find_registry_tool(
    registry: Dict[str, Dict[str, Any]],
    preferred_names: list[str],
    required_tokens: set[str],
    server_tokens: Optional[set[str]] = None,
) -> str:
    for name in preferred_names:
        if name in registry:
            return name
    for name, spec in registry.items():
        if not isinstance(spec, dict):
            continue
        searchable = " ".join(
            [
                name,
                str(spec.get("path") or ""),
                str(spec.get("operation_id") or ""),
                str(spec.get("description") or ""),
            ]
        )
        tool_tokens = _bridge_match_tokens(searchable)
        if required_tokens and not required_tokens.issubset(tool_tokens):
            continue
        if server_tokens:
            server_hints = _bridge_server_prompt_hints(str(spec.get("server_name") or ""))
            if not (server_hints & server_tokens or tool_tokens & server_tokens):
                continue
        return name
    return ""


def _bridge_dedupe_preflight_calls(calls: list[Dict[str, Any]]) -> list[Dict[str, Any]]:
    result: list[Dict[str, Any]] = []
    seen: set[str] = set()
    for call in calls:
        name = str(call.get("name") or "").strip()
        if not name:
            continue
        key = f"{name}:{json.dumps(call.get('parameters') or {}, sort_keys=True, default=str)}"
        if key in seen:
            continue
        seen.add(key)
        result.append(call)
    return result


def _bridge_codeindexer_github_preflight_calls(
    prompt_text: str,
    registry: Dict[str, Dict[str, Any]],
) -> list[Dict[str, Any]]:
    repo = _bridge_extract_github_repository(prompt_text)
    if not repo:
        return []
    prompt_tokens = _bridge_match_tokens(prompt_text)
    if not (prompt_tokens & {"clone", "github", "index", "pull", "repo", "repository", "search"}):
        return []
    if "index" in prompt_tokens or "search" in prompt_tokens:
        preferred = ["codeindexer_index_github_repository"]
        required = {"index", "github", "repository"}
        reason = "prompt requested GitHub repository indexing"
    elif "pull" in prompt_tokens:
        preferred = ["codeindexer_pull_github_repository"]
        required = {"pull", "github", "repository"}
        reason = "prompt requested GitHub repository pull"
    else:
        preferred = ["codeindexer_clone_github_repository"]
        required = {"clone", "github", "repository"}
        reason = "prompt requested GitHub repository preparation"
    name = _bridge_find_registry_tool(
        registry,
        preferred_names=preferred,
        required_tokens=required,
        server_tokens={"codeindexer"},
    )
    if not name:
        return []
    return [
        {
            "name": name,
            "parameters": {"repository": repo},
            "source": "codeindexer_github_preflight",
            "fallback_reason": reason,
        }
    ]


def _bridge_dify_apps_preflight_calls(
    prompt_text: str,
    registry: Dict[str, Dict[str, Any]],
) -> list[Dict[str, Any]]:
    prompt_tokens = _bridge_match_tokens(prompt_text)
    if "dify" not in prompt_tokens or not (prompt_tokens & {"app", "apps", "application", "applications"}):
        return []
    name = _bridge_find_registry_tool(
        registry,
        preferred_names=["dify_api_request"],
        required_tokens={"dify", "request"},
        server_tokens={"dify"},
    )
    if not name:
        return []
    return [
        {
            "name": name,
            "parameters": {"method": "GET", "path": "/console/api/apps", "authMode": "auto"},
            "source": "dify_apps_preflight",
            "fallback_reason": "prompt requested Dify app listing",
        }
    ]


def _bridge_python_script_for_prompt(prompt_text: str) -> str:
    text = str(prompt_text or "").lower()
    count_match = re.search(r"\bfirst\s+(\d{1,3})\b", text) or re.search(r"\b(\d{1,3})\s+(?:fibonacci|numbers?)\b", text)
    count = 10
    if count_match:
        try:
            count = min(max(int(count_match.group(1)), 1), 100)
        except Exception:
            count = 10
    if "fibonacci" in text:
        return "\n".join(
            [
                "if ! command -v python3 >/dev/null 2>&1; then apt-get update >/tmp/fortisai-apt-update.log 2>&1 && DEBIAN_FRONTEND=noninteractive apt-get install -y python3 >/tmp/fortisai-python-install.log 2>&1; fi",
                "python3 - <<'PY'",
                f"count = {count}",
                "values = []",
                "a, b = 0, 1",
                "for _ in range(count):",
                "    values.append(a)",
                "    a, b = b, a + b",
                "print(values)",
                "PY",
            ]
        )
    return "\n".join(
        [
            "if ! command -v python3 >/dev/null 2>&1; then apt-get update >/tmp/fortisai-apt-update.log 2>&1 && DEBIAN_FRONTEND=noninteractive apt-get install -y python3 >/tmp/fortisai-python-install.log 2>&1; fi",
            "python3 - <<'PY'",
            "import platform",
            "print('FortisAI Daytona Python execution OK')",
            "print('python=' + platform.python_version())",
            "print('sample_result=' + str(sum(range(10))))",
            "PY",
        ]
    )


def _bridge_daytona_python_preflight_calls(
    prompt_text: str,
    registry: Dict[str, Dict[str, Any]],
) -> list[Dict[str, Any]]:
    prompt_tokens = _bridge_match_tokens(prompt_text)
    text = str(prompt_text or "").lower()
    if not (prompt_tokens & {"python", "script", "code", "execute", "run"}):
        return []
    if not (
        "generate and execute" in text
        or "execute python" in text
        or "run python" in text
        or "python script" in text
        or "code execution" in text
        or ("daytona" in prompt_tokens and prompt_tokens & {"execute", "run"})
    ):
        return []
    name = _bridge_find_registry_tool(
        registry,
        preferred_names=["daytona_execute_command"],
        required_tokens={"daytona", "execute", "command"},
        server_tokens={"daytona"},
    )
    if not name:
        return []
    return [
        {
            "name": name,
            "parameters": {
                "sandbox_id_or_name": FORTISAI_DAYTONA_DEFAULT_SANDBOX,
                "command": _bridge_python_script_for_prompt(prompt_text),
                "timeout_seconds": 300,
            },
            "source": "daytona_python_preflight",
            "fallback_reason": "prompt explicitly requested Python code execution in Daytona",
        }
    ]


def _bridge_read_only_fallback_tool_calls(
    prompt_text: str,
    registry: Dict[str, Dict[str, Any]],
) -> list[Dict[str, Any]]:
    prompt_tokens = _bridge_match_tokens(prompt_text)
    if not prompt_tokens:
        return []
    mentioned_servers = {
        str(spec.get("server_name") or "")
        for spec in registry.values()
        if isinstance(spec, dict)
        and str(spec.get("server_name") or "")
        and (_bridge_server_prompt_hints(str(spec.get("server_name") or "")) & prompt_tokens)
    }

    scored: list[tuple[int, str, Dict[str, Any]]] = []
    for name, spec in registry.items():
        if not isinstance(spec, dict) or not _bridge_read_only_fallback_allowed(name, spec):
            continue
        server_name = str(spec.get("server_name") or "")
        if mentioned_servers and server_name not in mentioned_servers:
            continue
        server_overlap = _bridge_server_prompt_hints(server_name) & prompt_tokens
        searchable = " ".join(
            [
                name,
                str(spec.get("path") or ""),
                str(spec.get("operation_id") or ""),
                str(spec.get("description") or ""),
            ]
        )
        tool_tokens = _bridge_match_tokens(searchable)
        overlap = tool_tokens & prompt_tokens
        if not overlap:
            continue
        if not server_overlap and len(overlap) < 2:
            continue
        listing_prompt = bool(prompt_tokens & {"all", "list", "pull", "show"})
        detail_tokens = {"config", "detail", "details", "ip", "statistic", "statistics", "status"}
        if listing_prompt and tool_tokens & detail_tokens and not prompt_tokens & detail_tokens:
            continue
        if listing_prompt and tool_tokens & {"connection", "info"} and not prompt_tokens & {"connection", "health", "status"}:
            continue
        if tool_tokens & {"ingestion", "log", "logs"} and not prompt_tokens & {"ingestion", "log", "logs"}:
            continue
        score = (len(server_overlap) * 8) + (len(overlap) * 4)
        if listing_prompt and tool_tokens & {"get", "list", "search"}:
            score += 3
        if listing_prompt and not tool_tokens & detail_tokens:
            score += 4
        if tool_tokens & {"search", "query"}:
            score += 5
        if prompt_tokens & {"status", "health"} and tool_tokens & {"status", "info", "connection", "list"}:
            score += 3
        if {"vm", "vms"} & prompt_tokens and {"vm", "vms"} & tool_tokens:
            score += 6
        if {"container", "containers"} & prompt_tokens and {"container", "containers"} & tool_tokens:
            score += 6
        if {"workflow", "workflows"} & prompt_tokens and {"workflow", "workflows"} & tool_tokens:
            score += 6
        if score >= 10:
            scored.append((score, name, spec))

    scored.sort(key=lambda item: (-item[0], item[1]))
    results: list[Dict[str, Any]] = []
    seen_paths: set[str] = set()
    for _score, name, spec in scored:
        path_key = f"{spec.get('method')} {spec.get('url') or spec.get('path')}"
        if path_key in seen_paths:
            continue
        seen_paths.add(path_key)
        results.append(
            {
                "name": name,
                "parameters": _bridge_fallback_tool_parameters(prompt_text, spec),
                "source": "skill_read_only_fallback",
                "fallback_reason": "prompt matched skill-bound read-only OpenAPI tool",
            }
        )
        if len(results) >= 3:
            break
    if not results:
        for name in _qdrant_search_tool_memory(prompt_text, registry):
            spec = registry.get(name)
            if not isinstance(spec, dict):
                continue
            path_key = f"{spec.get('method')} {spec.get('url') or spec.get('path')}"
            if path_key in seen_paths:
                continue
            seen_paths.add(path_key)
            results.append(
                {
                    "name": name,
                    "parameters": _bridge_fallback_tool_parameters(prompt_text, spec),
                    "source": "qdrant_tool_memory_fallback",
                    "fallback_reason": "prompt matched remembered Qdrant tool metadata",
                }
            )
            if len(results) >= 3:
                break
    return results


def _detect_bridge_tool_calls(
    parsed: Any,
    payload: Dict[str, Any],
    http_request: Optional[Request] = None,
    registry: Optional[Dict[str, Dict[str, Any]]] = None,
) -> list[Dict[str, Any]]:
    registry = registry if isinstance(registry, dict) else _bridge_tool_registry(payload, http_request)
    available = set(registry.keys())
    detected: list[Dict[str, Any]] = []

    if isinstance(parsed, dict):
        choices = parsed.get("choices")
        if isinstance(choices, list):
            for choice in choices:
                if not isinstance(choice, dict):
                    continue
                message = choice.get("message") if isinstance(choice.get("message"), dict) else {}
                tool_calls = message.get("tool_calls")
                if isinstance(tool_calls, list):
                    for item in tool_calls:
                        call = _bridge_tool_call_from_mapping(item, "openai_tool_call")
                        if call:
                            detected.append(call)
                content = _extract_content_text(message.get("content"))
                detected.extend(_bridge_tool_calls_from_json_text(content))
                detected.extend(_bridge_tool_calls_from_xml_text(content))
        else:
            detected.extend(_bridge_tool_calls_from_json_text(_extract_content_text(parsed)))

    if not detected:
        assistant_text = _extract_openai_response_text(parsed).lower()
        prompt_text = _extract_tool_intent_text(payload)
        if _bridge_explicit_web_request(prompt_text) and "websearch_search" in available:
            detected.append(
                {
                    "name": "websearch_search",
                    "parameters": {"query": _rag_limited_text(prompt_text, 500), "limit": 10},
                    "source": "explicit_web_fallback",
                    "fallback_reason": "explicit web/current/site-data request",
                    "assistant_text_sample": assistant_text[:200],
                }
            )
        else:
            detected.extend(_bridge_read_only_fallback_tool_calls(prompt_text, registry))

    result: list[Dict[str, Any]] = []
    seen: set[str] = set()
    for call in detected:
        name = str(call.get("name") or "").strip()
        if name not in available:
            log.warning("FortisAI tool bridge detected unavailable tool: name=%s source=%s", name, call.get("source"))
            continue
        key = f"{name}:{json.dumps(call.get('parameters') or {}, sort_keys=True, default=str)}"
        if key in seen:
            continue
        seen.add(key)
        result.append(call)
    return result


def _bridge_preflight_tool_calls(
    payload: Dict[str, Any],
    http_request: Optional[Request] = None,
    registry: Optional[Dict[str, Dict[str, Any]]] = None,
) -> tuple[list[Dict[str, Any]], Dict[str, Dict[str, Any]]]:
    registry = registry if isinstance(registry, dict) else _bridge_tool_registry(payload, http_request)
    prompt_text = _extract_tool_intent_text(payload)
    if not prompt_text:
        return [], registry
    specialized_calls = _bridge_dedupe_preflight_calls(
        _bridge_codeindexer_github_preflight_calls(prompt_text, registry)
        + _bridge_dify_apps_preflight_calls(prompt_text, registry)
        + _bridge_daytona_python_preflight_calls(prompt_text, registry)
    )
    if specialized_calls:
        return specialized_calls, registry
    if _bridge_explicit_web_request(prompt_text) and "websearch_search" in registry:
        return [
            {
                "name": "websearch_search",
                "parameters": {"query": _rag_limited_text(prompt_text, 500), "limit": 10},
                "source": "explicit_web_preflight",
                "fallback_reason": "explicit web/current/site-data request",
            }
        ], registry
    structured_calls = _bridge_dedupe_preflight_calls(_bridge_read_only_fallback_tool_calls(prompt_text, registry))
    if structured_calls:
        return structured_calls, registry
    return [], registry


def _bridge_route_info_with_tool_results(
    route_info: Dict[str, Any],
    calls: list[Dict[str, Any]],
    results: list[Dict[str, Any]],
    phase: str,
) -> Dict[str, Any]:
    updated = dict(route_info)
    bridge_info = dict(updated.get("tool_execution_bridge") if isinstance(updated.get("tool_execution_bridge"), dict) else {})
    bridge_info.update(
        {
            "enabled": True,
            "max_rounds": FORTISAI_TOOL_EXECUTION_MAX_ROUNDS,
            "executed": any(bool(result.get("ok")) for result in results),
            "rounds": max(int(bridge_info.get("rounds") or 0), 1 if calls else 0),
            "detected": bool(calls),
            "phase": phase,
            "tools": list(bridge_info.get("tools") or []) + [str(call.get("name") or "") for call in calls],
            "last_result_count": len(results),
            "last_success_count": sum(1 for result in results if result.get("ok")),
        }
    )
    updated["tool_execution_bridge"] = bridge_info
    return updated


def _bridge_tool_results_response_text(
    prompt_text: str,
    tool_results: list[Dict[str, Any]],
) -> str:
    prompt_text = _strip_openwebui_generated_tool_instructions(prompt_text)
    lines = [
        "I executed the available FortisAI tools for this request and returned the live tool results.",
        "",
    ]
    if prompt_text:
        lines.append(f"Request: {prompt_text}")
        lines.append("")
    for index, result in enumerate(tool_results, start=1):
        tool_name = str(result.get("tool") or "tool")
        ok = bool(result.get("ok"))
        status = result.get("status", "n/a")
        elapsed = result.get("elapsed_ms", "n/a")
        lines.append(f"{index}. `{tool_name}`: {'ok' if ok else 'failed'} (status {status}, {elapsed} ms)")
        if ok:
            lines.append(_honcho_json_summary(result.get("result"), 3500))
        else:
            lines.append(_honcho_json_summary(result.get("error"), 1200))
        lines.append("")
    return _rag_limited_text("\n".join(lines).strip(), FORTISAI_TOOL_EXECUTION_RESULT_LIMIT_CHARS)


def _bridge_tool_results_openai_response(
    route_info: Dict[str, Any],
    prompt_text: str,
    tool_results: list[Dict[str, Any]],
) -> Dict[str, Any]:
    return {
        "id": f"chatcmpl-fortisai-tools-{uuid.uuid4().hex}",
        "object": "chat.completion",
        "created": int(time.time()),
        "model": str(route_info.get("routed_model") or FORTISAI_OPENAI_ROUTER_MODEL),
        "choices": [
            {
                "index": 0,
                "message": {
                    "role": "assistant",
                    "content": _bridge_tool_results_response_text(prompt_text, tool_results),
                },
                "finish_reason": "stop",
            }
        ],
        "usage": {"prompt_tokens": 0, "completion_tokens": 0, "total_tokens": 0},
    }


def _bridge_path_param_candidates(name: str) -> list[str]:
    raw = str(name or "").strip()
    snake = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", raw).lower()
    camel = re.sub(r"_([a-zA-Z])", lambda match: match.group(1).upper(), snake)
    candidates = [raw, snake, camel, snake.replace("_", "")]
    if snake.endswith("_id"):
        candidates.extend(["id", f"{snake[:-3]}Id", f"{snake[:-3]}ID"])
    if snake.endswith("_name"):
        candidates.append("name")
    result: list[str] = []
    seen: set[str] = set()
    for candidate in candidates:
        clean = str(candidate or "").strip()
        if clean and clean not in seen:
            seen.add(clean)
            result.append(clean)
    return result


def _bridge_apply_path_params(
    url: str,
    params: Dict[str, Any],
    path_params: list[Any],
) -> tuple[str, Dict[str, Any], list[str]]:
    updated_params = dict(params)
    missing: list[str] = []
    updated_url = url
    for path_param in path_params:
        param_name = str(path_param or "").strip()
        if not param_name:
            continue
        chosen_key = ""
        chosen_value: Any = None
        for candidate in _bridge_path_param_candidates(param_name):
            if candidate in updated_params and updated_params[candidate] is not None:
                chosen_key = candidate
                chosen_value = updated_params[candidate]
                break
        if chosen_key == "":
            missing.append(param_name)
            continue
        encoded_value = urllib.parse.quote(str(chosen_value), safe="")
        updated_url = updated_url.replace("{" + param_name + "}", encoded_value)
        updated_params.pop(chosen_key, None)
    return updated_url, updated_params, missing


def _execute_bridge_tool_call(
    call: Dict[str, Any],
    registry: Optional[Dict[str, Dict[str, Any]]] = None,
) -> Dict[str, Any]:
    registry = registry if isinstance(registry, dict) else _bridge_tool_registry()
    name = str(call.get("name") or "").strip()
    spec = registry.get(name)
    if not spec:
        log.warning("FortisAI tool bridge cannot execute unregistered tool: %s", name)
        return {"ok": False, "tool": name, "error": "tool_not_registered"}

    url = str(spec.get("url") or "").strip()
    method = str(spec.get("method") or "POST").upper()
    params = dict(call.get("parameters") if isinstance(call.get("parameters"), dict) else {})
    path_params = spec.get("path_params") if isinstance(spec.get("path_params"), list) else []
    url, params, missing_path_params = _bridge_apply_path_params(url, params, path_params)
    if missing_path_params:
        log.warning(
            "FortisAI tool bridge missing path parameter: tool=%s missing=%s provided=%s",
            name,
            missing_path_params,
            sorted(params.keys()),
        )
        return {
            "ok": False,
            "tool": name,
            "source": call.get("source"),
            "parameters": params,
            "error": "missing_path_parameter",
            "missing_path_parameters": missing_path_params,
        }
    headers = {"Accept": "application/json", "Content-Type": "application/json"}
    extra_headers = spec.get("headers") if isinstance(spec.get("headers"), dict) else {}
    headers.update({str(k): str(v) for k, v in extra_headers.items()})

    data_bytes = None
    if method == "GET":
        query_items = []
        for key, value in params.items():
            if value is None:
                continue
            if isinstance(value, (list, tuple)):
                for item in value:
                    query_items.append((key, str(item)))
            else:
                query_items.append((key, str(value)))
        if query_items:
            url = f"{url}?{urllib.parse.urlencode(query_items)}"
    else:
        data_bytes = json.dumps(params).encode("utf-8")

    started_at = time.monotonic()
    log.info(
        "FortisAI tool bridge executing: tool=%s source=%s method=%s url=%s param_keys=%s",
        name,
        call.get("source"),
        method,
        url.split("?", 1)[0],
        sorted(params.keys()),
    )
    request = urllib.request.Request(url=url, data=data_bytes, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=FORTISAI_TOOL_EXECUTION_TIMEOUT_SECONDS) as response:
            raw = response.read()
            parsed = _parse_upstream_body(raw)
            result = {
                "ok": True,
                "tool": name,
                "status": getattr(response, "status", 200),
                "elapsed_ms": _elapsed_ms(started_at),
                "source": call.get("source"),
                "parameters": params,
                "result": parsed,
            }
            log.info(
                "FortisAI tool bridge executed: tool=%s status=%s elapsed_ms=%s",
                name,
                result["status"],
                result["elapsed_ms"],
            )
            return result
    except urllib.error.HTTPError as exc:
        parsed = _parse_upstream_body(exc.read())
        log.warning("FortisAI tool bridge HTTP error: tool=%s status=%s", name, exc.code)
        return {
            "ok": False,
            "tool": name,
            "status": exc.code,
            "elapsed_ms": _elapsed_ms(started_at),
            "source": call.get("source"),
            "parameters": params,
            "error": parsed,
        }
    except Exception as exc:
        log.exception("FortisAI tool bridge execution failed: tool=%s", name)
        return {
            "ok": False,
            "tool": name,
            "elapsed_ms": _elapsed_ms(started_at),
            "source": call.get("source"),
            "parameters": params,
            "error": f"{type(exc).__name__}: {exc}",
        }


def _bridge_tool_result_context(tool_results: list[Dict[str, Any]]) -> str:
    result_text = _honcho_json_summary(tool_results, FORTISAI_TOOL_EXECUTION_RESULT_LIMIT_CHARS)
    return "\n\n".join(
        [
            "FortisAI executed OpenAPI/MCP bridge tools for this request.",
            "Use these tool results as real external data. Cite URLs from the results when available.",
            "Do not emit raw <tool_call> markup or JSON tool call blocks in the final answer.",
            f"Tool result JSON:\n{result_text}",
        ]
    )


def _payload_with_bridge_tool_results(payload: Dict[str, Any], tool_results: list[Dict[str, Any]]) -> Dict[str, Any]:
    enriched = dict(payload)
    messages = payload.get("messages") if isinstance(payload.get("messages"), list) else []
    enriched["messages"] = (
        [{"role": "system", "content": _bridge_tool_result_context(tool_results)}]
        + [dict(message) if isinstance(message, dict) else message for message in messages]
        + [
            {
                "role": "user",
                "content": "Answer the original user request directly using the FortisAI tool results above. Do not call another tool unless it is strictly necessary.",
            }
        ]
    )
    enriched["stream"] = False
    return enriched


def _bridge_tool_execution_should_buffer_stream(
    endpoint_path: str,
    payload: Dict[str, Any],
    http_request: Optional[Request] = None,
) -> bool:
    if not FORTISAI_TOOL_EXECUTION_BRIDGE_ENABLED or endpoint_path != "/chat/completions":
        return False
    prompt_text = _extract_tool_intent_text(payload)
    return (
        _payload_requires_tool_use(payload)
        or _prompt_requires_tool_use(prompt_text)
        or _bridge_explicit_web_request(prompt_text)
        or _bridge_prompt_mentions_skill_server(prompt_text, payload, http_request)
    )


def _run_upstream_openai_once(
    endpoint_path: str,
    upstream_payload: Dict[str, Any],
    route_info: Dict[str, Any],
    timeout_seconds: int,
    timing_key: str,
) -> Any:
    url = f"{FORTISAI_LLAMA_OPENAI_BASE_URL}{endpoint_path}"
    data_bytes = json.dumps(upstream_payload).encode("utf-8")
    request = urllib.request.Request(
        url=url,
        data=data_bytes,
        headers=_openai_upstream_headers(),
        method="POST",
    )
    timings = _route_timings(route_info)
    upstream_started_at = time.monotonic()
    try:
        with urllib.request.urlopen(request, timeout=timeout_seconds) as response:
            parsed = _parse_upstream_body(response.read())
    except urllib.error.HTTPError as exc:
        timings[timing_key] = _elapsed_ms(upstream_started_at)
        raw = exc.read()
        parsed = _parse_upstream_body(raw)
        log.warning(
            "FortisAI router upstream HTTP error: endpoint=%s routed_model=%s status=%s",
            endpoint_path,
            route_info.get("routed_model"),
            exc.code,
        )
        raise HTTPException(
            status_code=exc.code,
            detail={"upstream": parsed, "fortisai": route_info},
        ) from exc
    except Exception as exc:
        timings[timing_key] = _elapsed_ms(upstream_started_at)
        log.exception("FortisAI router upstream request failed")
        raise HTTPException(
            status_code=502,
            detail={
                "error": "FortisAI local OpenAI-compatible endpoint is unavailable",
                "upstream_base_url": FORTISAI_LLAMA_OPENAI_BASE_URL,
                "fortisai": route_info,
            },
        ) from exc

    timings[timing_key] = _elapsed_ms(upstream_started_at)
    return parsed


def _mediate_bridge_tool_calls(
    endpoint_path: str,
    upstream_payload: Dict[str, Any],
    parsed: Any,
    route_info: Dict[str, Any],
    timeout_seconds: int,
    http_request: Optional[Request] = None,
) -> tuple[Any, Dict[str, Any]]:
    if (
        not FORTISAI_TOOL_EXECUTION_BRIDGE_ENABLED
        or endpoint_path != "/chat/completions"
        or FORTISAI_TOOL_EXECUTION_MAX_ROUNDS <= 0
    ):
        return parsed, route_info

    current = parsed
    current_payload = dict(upstream_payload)
    route_info = dict(route_info)
    bridge_info: Dict[str, Any] = {
        "enabled": True,
        "max_rounds": FORTISAI_TOOL_EXECUTION_MAX_ROUNDS,
        "executed": False,
        "rounds": 0,
        "tools": [],
    }
    route_info["tool_execution_bridge"] = bridge_info

    for round_index in range(FORTISAI_TOOL_EXECUTION_MAX_ROUNDS):
        registry = _bridge_tool_registry(current_payload, http_request)
        calls = _detect_bridge_tool_calls(current, current_payload, http_request=http_request, registry=registry)
        if not calls:
            if round_index == 0:
                log.info("FortisAI tool bridge detected no executable tool calls")
            break

        bridge_info["rounds"] = round_index + 1
        bridge_info["detected"] = True
        bridge_info["tools"].extend(str(call.get("name") or "") for call in calls)
        log.info(
            "FortisAI tool bridge detected calls: round=%s names=%s sources=%s",
            round_index + 1,
            [call.get("name") for call in calls],
            [call.get("source") for call in calls],
        )

        results = [_execute_bridge_tool_call(call, registry=registry) for call in calls]
        bridge_info["executed"] = any(bool(result.get("ok")) for result in results)
        bridge_info["last_result_count"] = len(results)
        bridge_info["last_success_count"] = sum(1 for result in results if result.get("ok"))

        current_payload = _payload_with_bridge_tool_results(current_payload, results)
        current_payload, messages_normalized = _normalize_chat_messages_for_upstream(current_payload)
        if messages_normalized:
            bridge_info["messages_normalized_after_tool_results"] = True
        current = _run_upstream_openai_once(
            endpoint_path=endpoint_path,
            upstream_payload=current_payload,
            route_info=route_info,
            timeout_seconds=timeout_seconds,
            timing_key=f"tool_result_llm_round_{round_index + 1}_ms",
        )

    return current, route_info


def _openai_stream_finish_chunk(
    route_info: Dict[str, Any],
    stream_id: str,
    created: int,
    finish_reason: str = "stop",
) -> bytes:
    payload = {
        "id": stream_id,
        "object": "chat.completion.chunk",
        "created": created,
        "model": FORTISAI_OPENAI_ROUTER_MODEL,
        "choices": [{"index": 0, "delta": {}, "finish_reason": finish_reason}],
    }
    if route_info:
        payload["fortisai"] = route_info
    return f"data: {json.dumps(payload, separators=(',', ':'))}\n\n".encode("utf-8")


def _stream_openai_response_object(parsed: Any, route_info: Dict[str, Any]):
    stream_id = str(parsed.get("id") or f"chatcmpl-fortisai-{uuid.uuid4().hex}") if isinstance(parsed, dict) else f"chatcmpl-fortisai-{uuid.uuid4().hex}"
    created = int(parsed.get("created") or time.time()) if isinstance(parsed, dict) else int(time.time())
    yield _openai_stream_chunk(route_info, {"role": "assistant", "content": ""}, stream_id, created)
    text = _extract_openai_response_text(parsed)
    if text:
        yield _openai_stream_chunk(route_info, {"content": text}, stream_id, created)
    yield _openai_stream_finish_chunk(route_info, stream_id, created)
    yield b"data: [DONE]\n\n"

def _proxy_to_local_openai(
    endpoint_path: str,
    payload: Dict[str, Any],
    route_info: Dict[str, Any],
    honcho_context: Optional[Dict[str, Any]] = None,
    http_request: Optional[Request] = None,
) -> Any:
    upstream_payload = dict(payload)
    upstream_payload = _apply_output_token_limits(endpoint_path, upstream_payload, route_info)
    if endpoint_path == "/chat/completions":
        upstream_payload, tool_schema_info = _normalize_openai_tools_for_upstream(upstream_payload)
        if tool_schema_info.get("changed"):
            route_info = dict(route_info)
            route_info["tool_schema_normalized_for_upstream"] = tool_schema_info
        upstream_payload, messages_normalized = _normalize_chat_messages_for_upstream(upstream_payload)
        if messages_normalized:
            route_info = dict(route_info)
            route_info["messages_normalized"] = True
    upstream_payload["model"] = route_info["routed_model"]

    timeout_seconds = (
        FORTISAI_OPENAI_ROUTER_FORCE_LOAD_TIMEOUT_SECONDS
        if route_info.get("force_model_load")
        else FORTISAI_OPENAI_ROUTER_TIMEOUT_SECONDS
    )

    stream_requested = bool(payload.get("stream"))
    buffer_stream_for_tools = stream_requested and _bridge_tool_execution_should_buffer_stream(endpoint_path, upstream_payload, http_request)

    if stream_requested and not buffer_stream_for_tools:
        url = f"{FORTISAI_LLAMA_OPENAI_BASE_URL}{endpoint_path}"
        data_bytes = json.dumps(upstream_payload).encode("utf-8")
        request = urllib.request.Request(
            url=url,
            data=data_bytes,
            headers=_openai_upstream_headers(),
            method="POST",
        )
        return StreamingResponse(
            _stream_upstream_response_with_keepalive(
                request=request,
                route_info=route_info,
                timeout_seconds=timeout_seconds,
                endpoint_path=endpoint_path,
                honcho_context=honcho_context,
            ),
            media_type="text/event-stream",
            headers={
                "Cache-Control": "no-cache",
                "X-Accel-Buffering": "no",
                "X-FortisAI-Model": route_info["routed_model"],
                "X-FortisAI-Request-Type": route_info["request_type"],
            },
        )

    nonstream_payload = dict(upstream_payload)
    nonstream_payload["stream"] = False
    preflight_calls: list[Dict[str, Any]] = []
    preflight_results: list[Dict[str, Any]] = []
    if (
        FORTISAI_TOOL_EXECUTION_BRIDGE_ENABLED
        and endpoint_path == "/chat/completions"
        and FORTISAI_TOOL_EXECUTION_MAX_ROUNDS > 0
        and (buffer_stream_for_tools or _bridge_tool_execution_should_buffer_stream(endpoint_path, nonstream_payload, http_request))
    ):
        preflight_calls, preflight_registry = _bridge_preflight_tool_calls(nonstream_payload, http_request)
        if preflight_calls:
            log.info(
                "FortisAI tool bridge preflight calls: names=%s sources=%s",
                [call.get("name") for call in preflight_calls],
                [call.get("source") for call in preflight_calls],
            )
            preflight_results = [_execute_bridge_tool_call(call, registry=preflight_registry) for call in preflight_calls]
            route_info = _bridge_route_info_with_tool_results(route_info, preflight_calls, preflight_results, "preflight")
            nonstream_payload = _payload_with_bridge_tool_results(nonstream_payload, preflight_results)
            nonstream_payload, messages_normalized = _normalize_chat_messages_for_upstream(nonstream_payload)
            if messages_normalized:
                route_info = dict(route_info)
                bridge_info = dict(route_info.get("tool_execution_bridge") if isinstance(route_info.get("tool_execution_bridge"), dict) else {})
                bridge_info["messages_normalized_after_tool_results"] = True
                route_info["tool_execution_bridge"] = bridge_info

    if preflight_results:
        try:
            parsed = _run_upstream_openai_once(
                endpoint_path=endpoint_path,
                upstream_payload=nonstream_payload,
                route_info=route_info,
                timeout_seconds=min(timeout_seconds, FORTISAI_TOOL_EXECUTION_PREFLIGHT_LLM_TIMEOUT_SECONDS),
                timing_key="preflight_tool_result_llm_ms",
            )
        except HTTPException as exc:
            log.warning("FortisAI preflight tool result summarization fell back to deterministic response: %s", exc.detail)
            route_info = dict(route_info)
            bridge_info = dict(route_info.get("tool_execution_bridge") if isinstance(route_info.get("tool_execution_bridge"), dict) else {})
            bridge_info["final_answer_source"] = "deterministic_tool_result_fallback"
            bridge_info["preflight_llm_error"] = exc.detail
            route_info["tool_execution_bridge"] = bridge_info
            parsed = _bridge_tool_results_openai_response(
                route_info=route_info,
                prompt_text=_extract_tool_intent_text(payload),
                tool_results=preflight_results,
            )
    else:
        parsed = _run_upstream_openai_once(
            endpoint_path=endpoint_path,
            upstream_payload=nonstream_payload,
            route_info=route_info,
            timeout_seconds=timeout_seconds,
            timing_key="upstream_llm_ms",
        )
        parsed, route_info = _mediate_bridge_tool_calls(
            endpoint_path=endpoint_path,
            upstream_payload=nonstream_payload,
            parsed=parsed,
            route_info=route_info,
            timeout_seconds=timeout_seconds,
            http_request=http_request,
        )

    timings = _route_timings(route_info)
    log.info(
        "FortisAI router completed: endpoint=%s routed_model=%s request_type=%s timings_ms=%s default_cap=%s tool_bridge=%s",
        endpoint_path,
        route_info.get("routed_model"),
        route_info.get("request_type"),
        timings,
        route_info.get("default_output_cap_tokens"),
        route_info.get("tool_execution_bridge"),
    )
    rewritten = _rewrite_openai_response(parsed, route_info)
    assistant_text = _extract_openai_response_text(rewritten)
    _honcho_writeback(
        honcho_context=honcho_context,
        route_info=route_info,
        endpoint_path=endpoint_path,
        assistant_text=assistant_text,
        strict=True,
    )
    if stream_requested:
        return StreamingResponse(
            _stream_openai_response_object(rewritten, route_info),
            media_type="text/event-stream",
            headers={
                "Cache-Control": "no-cache",
                "X-Accel-Buffering": "no",
                "X-FortisAI-Model": route_info["routed_model"],
                "X-FortisAI-Request-Type": route_info["request_type"],
            },
        )
    return rewritten

def _proxy_embeddings_to_local_openai(payload: Dict[str, Any], route_info: Dict[str, Any]) -> Any:
    upstream_payload = dict(payload)
    upstream_payload["model"] = route_info["routed_model"]
    url = f"{FORTISAI_LLAMA_OPENAI_BASE_URL}/embeddings"
    data_bytes = json.dumps(upstream_payload).encode("utf-8")
    request = urllib.request.Request(
        url=url,
        data=data_bytes,
        headers=_openai_upstream_headers(),
        method="POST",
    )

    try:
        with urllib.request.urlopen(request, timeout=FORTISAI_OPENAI_ROUTER_TIMEOUT_SECONDS) as response:
            parsed = _parse_upstream_body(response.read())
    except urllib.error.HTTPError as exc:
        raw = exc.read()
        parsed = _parse_upstream_body(raw)
        log.warning(
            "FortisAI embeddings upstream HTTP error: routed_model=%s status=%s",
            route_info.get("routed_model"),
            exc.code,
        )
        raise HTTPException(
            status_code=exc.code,
            detail={"upstream": parsed, "fortisai": route_info},
        ) from exc
    except Exception as exc:
        log.exception("FortisAI embeddings upstream request failed")
        raise HTTPException(
            status_code=502,
            detail={
                "error": "FortisAI local embeddings endpoint is unavailable",
                "upstream_base_url": FORTISAI_LLAMA_OPENAI_BASE_URL,
                "fortisai": route_info,
            },
        ) from exc

    return _rewrite_openai_embeddings_response(parsed, route_info)


def _route_openai_payload(
    endpoint_path: str,
    payload: Dict[str, Any],
    prompt_text: str,
    http_request: Optional[Request] = None,
) -> Any:
    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="OpenAI-compatible request body must be a JSON object")

    timings: Dict[str, Any] = {}
    intent_prompt_text = _extract_tool_intent_text(payload) or _strip_openwebui_generated_tool_instructions(prompt_text)
    preflight_cline_request = _looks_like_cline_request(payload, intent_prompt_text)
    retrieval_prompt_text = _limit_cline_retrieval_query(intent_prompt_text) if preflight_cline_request else intent_prompt_text

    honcho_started_at = time.monotonic()
    honcho_context = _prepare_honcho_context(
        payload=payload,
        prompt_text=retrieval_prompt_text,
        http_request=http_request,
    )
    timings["honcho_ms"] = _elapsed_ms(honcho_started_at)

    rag_started_at = time.monotonic()
    rag_context = _prepare_rag_context(prompt_text=retrieval_prompt_text)
    timings["rag_ms"] = _elapsed_ms(rag_started_at)
    if preflight_cline_request:
        honcho_context, rag_context = _limit_cline_contexts(honcho_context, rag_context)

    inject_started_at = time.monotonic()
    effective_payload = _inject_honcho_memory(
        endpoint_path=endpoint_path,
        payload=payload,
        honcho_context=honcho_context,
        rag_context=rag_context,
    )
    effective_payload, cline_tool_guard_applied, cline_tool_schema_enforced = _inject_cline_tool_guard(
        endpoint_path=endpoint_path,
        payload=effective_payload,
        prompt_text=prompt_text,
    )
    effective_prompt_text = (
        _extract_chat_text(effective_payload)
        if endpoint_path == "/chat/completions"
        else _extract_completion_text(effective_payload)
    )
    effective_intent_text = _extract_tool_intent_text(effective_payload) or _strip_openwebui_generated_tool_instructions(effective_prompt_text)
    timings["context_injection_ms"] = _elapsed_ms(inject_started_at)

    classification_started_at = time.monotonic()
    requested_model = str(effective_payload.get("model") or FORTISAI_OPENAI_ROUTER_MODEL).strip()
    config = load_router_classification()
    available_models = _router_model_ids(config)
    tool_use_required = _payload_requires_tool_use(effective_payload) or _prompt_requires_tool_use(effective_intent_text)

    if requested_model and requested_model != FORTISAI_OPENAI_ROUTER_MODEL:
        route_info = {
            "app": FORTISAI_OPENAI_ROUTER_APP_NAME,
            "router_model": FORTISAI_OPENAI_ROUTER_MODEL,
            "request_type": "direct",
            "routed_model": requested_model,
            "score": 0,
            "matched_hints": [],
            "classification_source": config.get("classification_source") or "client_model",
        }
        if tool_use_required:
            route_info["tool_use_required"] = True
            route_info["force_model_load"] = True
            route_info["load_policy"] = "force_selected_model"
    else:
        route_info = (
            choose_fortisai_tool_use_route(prompt_text=effective_intent_text, config=config)
            if tool_use_required
            else choose_fortisai_route(prompt_text=effective_intent_text, config=config)
        )
    timings["classification_ms"] = _elapsed_ms(classification_started_at)

    if available_models and route_info["routed_model"] not in available_models:
        fallback_model = _select_available_model([], available_models)
        route_info = dict(route_info)
        route_info["requested_routed_model"] = route_info["routed_model"]
        route_info["routed_model"] = fallback_model
        route_info["fallback_reason"] = "selected model was not present in generated classification"

    if route_info.get("request_type") != "direct":
        status_started_at = time.monotonic()
        statuses = _local_openai_model_statuses()
        timings["model_status_ms"] = _elapsed_ms(status_started_at)
        if statuses:
            route_info = dict(route_info)
            route_info["selected_model_status"] = statuses.get(route_info["routed_model"], "unknown")

    route_info = dict(route_info)
    if cline_tool_guard_applied:
        route_info["cline_tool_guard"] = {
            "enabled": True,
            "execute_command_requires_approval_default": True,
            "schema_enforced": cline_tool_schema_enforced,
        }
    route_info["honcho"] = _honcho_route_metadata(honcho_context)
    route_info["retrieval"] = _rag_route_metadata(rag_context)
    route_info["timings_ms"] = timings

    log.info(
        "FortisAI route prepared: endpoint=%s routed_model=%s request_type=%s timings_ms=%s",
        endpoint_path,
        route_info.get("routed_model"),
        route_info.get("request_type"),
        timings,
    )
    return _proxy_to_local_openai(
        endpoint_path=endpoint_path,
        payload=effective_payload,
        route_info=route_info,
        honcho_context=honcho_context,
        http_request=http_request,
    )

def _responses_input_to_messages(payload: Dict[str, Any]) -> list[Dict[str, Any]]:
    messages: list[Dict[str, Any]] = []
    instructions = _extract_content_text(payload.get("instructions"))
    if instructions:
        messages.append({"role": "system", "content": instructions})

    raw_input = payload.get("input")
    if raw_input is None and isinstance(payload.get("messages"), list):
        raw_input = payload.get("messages")

    if isinstance(raw_input, str):
        messages.append({"role": "user", "content": raw_input})
    elif isinstance(raw_input, list):
        for item in raw_input:
            if isinstance(item, dict):
                role = str(item.get("role") or "user").strip() or "user"
                if role == "developer":
                    role = "system"
                content = _extract_content_text(item.get("content") if "content" in item else item)
                if content:
                    messages.append({"role": role, "content": content})
            else:
                content = _extract_content_text(item)
                if content:
                    messages.append({"role": "user", "content": content})
    else:
        content = _extract_content_text(raw_input)
        if content:
            messages.append({"role": "user", "content": content})

    if not messages:
        messages.append({"role": "user", "content": ""})
    return messages


def _responses_chat_payload(payload: Dict[str, Any]) -> Dict[str, Any]:
    chat_payload: Dict[str, Any] = {
        "model": payload.get("model") or FORTISAI_OPENAI_ROUTER_MODEL,
        "messages": _responses_input_to_messages(payload),
    }
    field_map = {
        "max_output_tokens": "max_tokens",
        "max_tokens": "max_tokens",
        "temperature": "temperature",
        "top_p": "top_p",
        "stop": "stop",
        "tools": "tools",
        "tool_choice": "tool_choice",
        "response_format": "response_format",
        "parallel_tool_calls": "parallel_tool_calls",
        "presence_penalty": "presence_penalty",
        "frequency_penalty": "frequency_penalty",
        "seed": "seed",
    }
    for source, target in field_map.items():
        if source in payload and payload[source] is not None:
            chat_payload[target] = payload[source]
    chat_payload["stream"] = False
    return chat_payload


def _responses_output_text(chat_response: Any) -> str:
    if not isinstance(chat_response, dict):
        return ""
    choices = chat_response.get("choices")
    if not isinstance(choices, list) or not choices:
        return ""
    message = choices[0].get("message") if isinstance(choices[0], dict) else None
    if isinstance(message, dict):
        content = message.get("content")
        if isinstance(content, str):
            return content
        return _extract_content_text(content)
    text = choices[0].get("text") if isinstance(choices[0], dict) else ""
    return str(text or "")


def _build_responses_object(payload: Dict[str, Any], chat_response: Any) -> Dict[str, Any]:
    output_text = _responses_output_text(chat_response)
    created_at = int(time.time())
    chat_id = chat_response.get("id") if isinstance(chat_response, dict) else ""
    response_id = str(chat_id or f"resp_{uuid.uuid4().hex}")
    output_id = f"msg_{uuid.uuid4().hex}"
    fortisai_info = chat_response.get("fortisai") if isinstance(chat_response, dict) else None
    usage = chat_response.get("usage") if isinstance(chat_response, dict) else None

    result: Dict[str, Any] = {
        "id": response_id if response_id.startswith("resp_") else f"resp_{response_id}",
        "object": "response",
        "created_at": created_at,
        "status": "completed",
        "model": FORTISAI_OPENAI_ROUTER_MODEL,
        "output": [
            {
                "id": output_id,
                "type": "message",
                "status": "completed",
                "role": "assistant",
                "content": [
                    {
                        "type": "output_text",
                        "text": output_text,
                        "annotations": [],
                    }
                ],
            }
        ],
        "output_text": output_text,
        "parallel_tool_calls": bool(payload.get("parallel_tool_calls", False)),
        "error": None,
        "incomplete_details": None,
    }
    if usage is not None:
        result["usage"] = usage
    if fortisai_info is not None:
        result["fortisai"] = fortisai_info
    return result


def _responses_sse(response_obj: Dict[str, Any]):
    created = dict(response_obj)
    created["status"] = "in_progress"
    yield f"event: response.created\ndata: {json.dumps(created, separators=(',', ':'))}\n\n".encode("utf-8")
    output_text = str(response_obj.get("output_text") or "")
    if output_text:
        delta = {
            "type": "response.output_text.delta",
            "item_id": response_obj["output"][0]["id"],
            "output_index": 0,
            "content_index": 0,
            "delta": output_text,
        }
        yield f"event: response.output_text.delta\ndata: {json.dumps(delta, separators=(',', ':'))}\n\n".encode("utf-8")
    completed = dict(response_obj)
    completed["type"] = "response.completed"
    yield f"event: response.completed\ndata: {json.dumps(completed, separators=(',', ':'))}\n\n".encode("utf-8")
    yield b"data: [DONE]\n\n"


def _anthropic_tools_to_openai_tools(payload: Dict[str, Any]) -> list[Dict[str, Any]]:
    tools = payload.get("tools")
    if not isinstance(tools, list):
        return []

    converted: list[Dict[str, Any]] = []
    for tool in tools:
        if not isinstance(tool, dict):
            continue
        name = str(tool.get("name") or "").strip()
        if not name:
            continue
        converted.append(
            {
                "type": "function",
                "function": {
                    "name": name,
                    "description": str(tool.get("description") or ""),
                    "parameters": tool.get("input_schema")
                    if isinstance(tool.get("input_schema"), dict)
                    else {"type": "object", "properties": {}},
                },
            }
        )
    return converted


def _anthropic_messages_chat_payload(payload: Dict[str, Any]) -> Dict[str, Any]:
    messages: list[Dict[str, Any]] = []
    system_text = _extract_content_text(payload.get("system")).strip()
    if system_text:
        messages.append({"role": "system", "content": system_text})

    raw_messages = payload.get("messages")
    if isinstance(raw_messages, list):
        for message in raw_messages:
            if not isinstance(message, dict):
                continue
            role = str(message.get("role") or "user").strip().lower() or "user"
            if role not in {"assistant", "system", "user"}:
                role = "user"
            content = _extract_content_text(message.get("content"))
            messages.append({"role": role, "content": content})

    if not messages:
        messages.append({"role": "user", "content": ""})

    chat_payload: Dict[str, Any] = {
        "model": payload.get("model") or FORTISAI_OPENAI_ROUTER_MODEL,
        "messages": messages,
        "stream": False,
    }
    field_map = {
        "max_tokens": "max_tokens",
        "temperature": "temperature",
        "top_p": "top_p",
    }
    for source, target in field_map.items():
        if source in payload and payload[source] is not None:
            chat_payload[target] = payload[source]
    if payload.get("stop_sequences") is not None:
        chat_payload["stop"] = payload.get("stop_sequences")

    converted_tools = _anthropic_tools_to_openai_tools(payload)
    if converted_tools:
        chat_payload["tools"] = converted_tools
        tool_choice = payload.get("tool_choice")
        if isinstance(tool_choice, dict):
            choice_type = str(tool_choice.get("type") or "").strip()
            choice_name = str(tool_choice.get("name") or "").strip()
            if choice_type == "tool" and choice_name:
                chat_payload["tool_choice"] = {"type": "function", "function": {"name": choice_name}}
            elif choice_type in {"any", "auto"}:
                chat_payload["tool_choice"] = "auto"

    metadata = payload.get("metadata")
    if isinstance(metadata, dict):
        chat_payload["metadata"] = dict(metadata)
        user_id = metadata.get("user_id") or metadata.get("user")
        if user_id:
            chat_payload["user"] = str(user_id)

    return chat_payload


def _anthropic_usage(chat_response: Any) -> Dict[str, int]:
    usage = chat_response.get("usage") if isinstance(chat_response, dict) else None
    if not isinstance(usage, dict):
        return {"input_tokens": 0, "output_tokens": 0}
    return {
        "input_tokens": int(usage.get("prompt_tokens") or usage.get("input_tokens") or 0),
        "output_tokens": int(usage.get("completion_tokens") or usage.get("output_tokens") or 0),
    }


def _build_anthropic_message_object(payload: Dict[str, Any], chat_response: Any) -> Dict[str, Any]:
    text = _responses_output_text(chat_response)
    response_id = ""
    if isinstance(chat_response, dict):
        response_id = str(chat_response.get("id") or "")
    result: Dict[str, Any] = {
        "id": response_id if response_id.startswith("msg_") else f"msg_{uuid.uuid4().hex}",
        "type": "message",
        "role": "assistant",
        "model": str(payload.get("model") or FORTISAI_OPENAI_ROUTER_MODEL),
        "content": [{"type": "text", "text": text}],
        "stop_reason": "end_turn",
        "stop_sequence": None,
        "usage": _anthropic_usage(chat_response),
    }
    if isinstance(chat_response, dict) and chat_response.get("fortisai") is not None:
        result["fortisai"] = chat_response.get("fortisai")
    return result


def _anthropic_messages_sse(message_obj: Dict[str, Any]):
    start_message = dict(message_obj)
    start_message["content"] = []
    start_message["stop_reason"] = None
    start_message["stop_sequence"] = None
    start_message["usage"] = {
        "input_tokens": int(message_obj.get("usage", {}).get("input_tokens") or 0),
        "output_tokens": 0,
    }
    yield (
        "event: message_start\n"
        f"data: {json.dumps({'type': 'message_start', 'message': start_message}, separators=(',', ':'))}\n\n"
    ).encode("utf-8")

    yield (
        "event: content_block_start\n"
        f"data: {json.dumps({'type': 'content_block_start', 'index': 0, 'content_block': {'type': 'text', 'text': ''}}, separators=(',', ':'))}\n\n"
    ).encode("utf-8")

    text = _extract_content_text(message_obj.get("content"))
    if text:
        yield (
            "event: content_block_delta\n"
            f"data: {json.dumps({'type': 'content_block_delta', 'index': 0, 'delta': {'type': 'text_delta', 'text': text}}, separators=(',', ':'))}\n\n"
        ).encode("utf-8")

    yield b"event: content_block_stop\ndata: {\"type\":\"content_block_stop\",\"index\":0}\n\n"
    usage = {"output_tokens": int(message_obj.get("usage", {}).get("output_tokens") or 0)}
    delta = {"stop_reason": message_obj.get("stop_reason") or "end_turn", "stop_sequence": None}
    yield (
        "event: message_delta\n"
        f"data: {json.dumps({'type': 'message_delta', 'delta': delta, 'usage': usage}, separators=(',', ':'))}\n\n"
    ).encode("utf-8")
    yield b"event: message_stop\ndata: {\"type\":\"message_stop\"}\n\n"


@app.get("/healthz", include_in_schema=False)
def healthz() -> Dict[str, str]:
    return {"status": "ok"}


@app.get("/v1/models")
@app.get("/fortisai/v1/models")
def fortisai_openai_models() -> Dict[str, Any]:
    config = load_router_classification()
    routes = _route_entries(config)
    routed_models = []
    seen: set[str] = set()
    for route in routes:
        model = _select_available_model(_route_model_candidates(route), _router_model_ids(config))
        if model and model not in seen:
            seen.add(model)
            routed_models.append({"route": _route_label(route), "model": model})

    return {
        "object": "list",
        "data": [
            _fortisai_model_object(
                FORTISAI_OPENAI_ROUTER_MODEL,
                {
                    "root": FORTISAI_OPENAI_ROUTER_MODEL,
                    "parent": None,
                    "fortisai": {
                        "app": FORTISAI_OPENAI_ROUTER_APP_NAME,
                        "classification_source": config.get("classification_source") or "unavailable",
                        "route_count": len(routes),
                        "routed_models": routed_models,
                        "capabilities": [
                            "chat.completions",
                            "completions",
                            "embeddings",
                            "responses",
                            "honcho_memory",
                            "qdrant_retrieval",
                            "firecrawl_websearch",
                        ],
                        "honcho_required": FORTISAI_HONCHO_REQUIRED,
                        "rag_enabled": FORTISAI_RAG_ENABLED,
                    },
                },
            )
        ],
    }


@app.get("/v1/models/{model_id:path}")
@app.get("/fortisai/v1/models/{model_id:path}")
def fortisai_openai_model(model_id: str) -> Dict[str, Any]:
    if model_id != FORTISAI_OPENAI_ROUTER_MODEL:
        raise HTTPException(status_code=404, detail=f"Unknown FortisAI router model: {model_id}")
    return _fortisai_model_object(
        FORTISAI_OPENAI_ROUTER_MODEL,
        {
            "root": FORTISAI_OPENAI_ROUTER_MODEL,
            "parent": None,
            "fortisai": {
                "app": FORTISAI_OPENAI_ROUTER_APP_NAME,
                "classification_file": FORTISAI_OPENAI_ROUTER_CLASSIFICATION_FILE,
                "upstream_base_url": FORTISAI_LLAMA_OPENAI_BASE_URL,
                "embedding_model": FORTISAI_OPENAI_EMBEDDING_MODEL or "auto",
                "capabilities": [
                    "chat.completions",
                    "completions",
                    "embeddings",
                    "responses",
                    "honcho_memory",
                    "qdrant_retrieval",
                    "firecrawl_websearch",
                ],
                "honcho_required": FORTISAI_HONCHO_REQUIRED,
                "rag_enabled": FORTISAI_RAG_ENABLED,
                "rag_vector_db": "qdrant",
                "rag_collection": FORTISAI_RAG_QDRANT_COLLECTION,
                "rag_websearch": "firecrawl",
            },
        },
    )


@app.post("/fortisai_router_preview")
@app.post("/fortisai/v1/router/preview")
def fortisai_router_preview(request: Dict[str, Any]) -> Dict[str, Any]:
    if not isinstance(request, dict):
        raise HTTPException(status_code=400, detail="Router preview request body must be a JSON object")
    prompt_text = _extract_preview_text(request)
    intent_prompt_text = _extract_tool_intent_text(request) or _strip_openwebui_generated_tool_instructions(prompt_text)
    config = load_router_classification()
    route_info = (
        choose_fortisai_tool_use_route(prompt_text=intent_prompt_text, config=config)
        if _payload_requires_tool_use(request) or _prompt_requires_tool_use(intent_prompt_text)
        else choose_fortisai_route(prompt_text=intent_prompt_text, config=config)
    )
    return {
        "status": "ok",
        "classification_file": FORTISAI_OPENAI_ROUTER_CLASSIFICATION_FILE,
        "classification_source": config.get("classification_source") or "unavailable",
        "prompt_text_length": len(prompt_text),
        "intent_prompt_text_length": len(intent_prompt_text),
        "route": route_info,
    }


@app.post("/v1/chat/completions")
@app.post("/fortisai/v1/chat/completions")
def fortisai_chat_completions(request: Dict[str, Any], http_request: Request) -> Any:
    return _route_openai_payload(
        endpoint_path="/chat/completions",
        payload=request,
        prompt_text=_extract_chat_text(request),
        http_request=http_request,
    )


@app.post("/v1/completions")
@app.post("/fortisai/v1/completions")
def fortisai_completions(request: Dict[str, Any], http_request: Request) -> Any:
    return _route_openai_payload(
        endpoint_path="/completions",
        payload=request,
        prompt_text=_extract_completion_text(request),
        http_request=http_request,
    )


@app.post("/v1/embeddings")
@app.post("/fortisai/v1/embeddings")
def fortisai_embeddings(request: Dict[str, Any]) -> Any:
    if not isinstance(request, dict):
        raise HTTPException(status_code=400, detail="OpenAI-compatible embeddings request body must be a JSON object")

    requested_model = str(request.get("model") or FORTISAI_OPENAI_ROUTER_MODEL).strip()
    config = load_router_classification()
    if requested_model and requested_model != FORTISAI_OPENAI_ROUTER_MODEL:
        route_info = {
            "app": FORTISAI_OPENAI_ROUTER_APP_NAME,
            "router_model": FORTISAI_OPENAI_ROUTER_MODEL,
            "request_type": "embeddings_direct",
            "routed_model": requested_model,
            "score": 0,
            "matched_hints": [],
            "classification_source": config.get("classification_source") or "client_model",
        }
    else:
        route_info = choose_fortisai_embedding_route(config=config)
    return _proxy_embeddings_to_local_openai(payload=request, route_info=route_info)


@app.post("/v1/responses")
@app.post("/fortisai/v1/responses")
def fortisai_responses(request: Dict[str, Any], http_request: Request) -> Any:
    if not isinstance(request, dict):
        raise HTTPException(status_code=400, detail="OpenAI-compatible responses request body must be a JSON object")

    chat_payload = _responses_chat_payload(request)
    chat_response = _route_openai_payload(
        endpoint_path="/chat/completions",
        payload=chat_payload,
        prompt_text=_extract_chat_text(chat_payload),
        http_request=http_request,
    )
    if isinstance(chat_response, StreamingResponse):
        raise HTTPException(status_code=500, detail="Unexpected streaming response from internal chat adapter")

    response_obj = _build_responses_object(payload=request, chat_response=chat_response)
    if bool(request.get("stream")):
        return StreamingResponse(_responses_sse(response_obj), media_type="text/event-stream")
    return response_obj


@app.post("/messages")
@app.post("/v1/messages")
@app.post("/v1/v1/messages")
@app.post("/fortisai/v1/messages")
def fortisai_anthropic_messages(request: Dict[str, Any], http_request: Request) -> Any:
    if not isinstance(request, dict):
        raise HTTPException(status_code=400, detail="Anthropic-compatible messages request body must be a JSON object")

    chat_payload = _anthropic_messages_chat_payload(request)
    chat_response = _route_openai_payload(
        endpoint_path="/chat/completions",
        payload=chat_payload,
        prompt_text=_extract_chat_text(chat_payload),
        http_request=http_request,
    )
    if isinstance(chat_response, StreamingResponse):
        raise HTTPException(status_code=500, detail="Unexpected streaming response from internal messages adapter")

    message_obj = _build_anthropic_message_object(payload=request, chat_response=chat_response)
    if bool(request.get("stream")):
        return StreamingResponse(_anthropic_messages_sse(message_obj), media_type="text/event-stream")
    return message_obj


@app.on_event("startup")
def startup_resolve_workspace() -> None:
    # Best effort: discover workspace id once at startup so admin console routes
    # work without requiring explicit DIFY_ADMIN_WORKSPACE_ID env wiring.
    discover_admin_workspace_id()


@app.get("/dify_connection_info")
def dify_connection_info() -> Dict[str, Any]:
    _rag_embedding_base_url, rag_embedding_model, _rag_embedding_api_key, rag_embedding_route = _rag_embedding_request_target()
    return {
        "base_url": DIFY_BASE_URL,
        "has_api_key": bool(DIFY_API_KEY),
        "has_admin_api_key": bool(DIFY_ADMIN_API_KEY),
        "has_console_access_token": bool(DIFY_CONSOLE_ACCESS_TOKEN),
        "has_admin_workspace_id": bool(discover_admin_workspace_id()),
        "verify_tls": DIFY_VERIFY_TLS,
        "fortisai_openai_router_model": FORTISAI_OPENAI_ROUTER_MODEL,
        "fortisai_openai_router_app": FORTISAI_OPENAI_ROUTER_APP_NAME,
        "fortisai_openai_router_classification_file": FORTISAI_OPENAI_ROUTER_CLASSIFICATION_FILE,
        "fortisai_openai_router_classification_loaded": bool(load_router_classification()),
        "fortisai_llama_openai_base_url": FORTISAI_LLAMA_OPENAI_BASE_URL,
        "fortisai_openai_router_timeout_seconds": FORTISAI_OPENAI_ROUTER_TIMEOUT_SECONDS,
        "fortisai_openai_router_force_load_timeout_seconds": FORTISAI_OPENAI_ROUTER_FORCE_LOAD_TIMEOUT_SECONDS,
        "fortisai_openai_router_stream_keepalive_seconds": FORTISAI_OPENAI_ROUTER_STREAM_KEEPALIVE_SECONDS,
        "fortisai_openai_router_default_max_tokens": FORTISAI_OPENAI_ROUTER_DEFAULT_MAX_TOKENS,
        "fortisai_openai_router_max_tokens_hard_limit": FORTISAI_OPENAI_ROUTER_MAX_TOKENS_HARD_LIMIT,
        "fortisai_cline_tool_guard_enabled": FORTISAI_CLINE_TOOL_GUARD_ENABLED,
        "fortisai_cline_tool_max_tokens": FORTISAI_CLINE_TOOL_MAX_TOKENS,
        "fortisai_cline_retrieval_query_chars": FORTISAI_CLINE_RETRIEVAL_QUERY_CHARS,
        "fortisai_cline_context_limit_chars": FORTISAI_CLINE_CONTEXT_LIMIT_CHARS,
        "fortisai_openai_router_prefer_loaded_models": FORTISAI_OPENAI_ROUTER_PREFER_LOADED_MODELS,
        "fortisai_openai_embedding_model": FORTISAI_OPENAI_EMBEDDING_MODEL or "auto",
        "has_fortisai_llama_openai_api_key": bool(FORTISAI_LLAMA_OPENAI_API_KEY),
        "fortisai_honcho_base_url": FORTISAI_HONCHO_BASE_URL,
        "fortisai_honcho_required": FORTISAI_HONCHO_REQUIRED,
        "fortisai_honcho_workspace_id": FORTISAI_HONCHO_WORKSPACE_ID,
        "fortisai_honcho_assistant_peer_id": FORTISAI_HONCHO_ASSISTANT_PEER_ID,
        "fortisai_honcho_model": FORTISAI_HONCHO_MODEL,
        "fortisai_honcho_context_limit_chars": FORTISAI_HONCHO_CONTEXT_LIMIT_CHARS,
        "has_fortisai_honcho_api_key": bool(FORTISAI_HONCHO_API_KEY),
        "fortisai_rag_enabled": FORTISAI_RAG_ENABLED,
        "fortisai_rag_vector_db": "qdrant",
        "fortisai_rag_qdrant_url": FORTISAI_RAG_QDRANT_URL,
        "fortisai_rag_qdrant_collection": FORTISAI_RAG_QDRANT_COLLECTION,
        "has_fortisai_rag_qdrant_api_key": bool(FORTISAI_RAG_QDRANT_API_KEY),
        "fortisai_rag_firecrawl_url": FORTISAI_RAG_FIRECRAWL_URL,
        "has_fortisai_rag_firecrawl_api_key": bool(FORTISAI_RAG_FIRECRAWL_API_KEY),
        "fortisai_rag_embedding_base_url": _rag_embedding_base_url,
        "fortisai_rag_embedding_model": rag_embedding_model or "auto",
        "fortisai_rag_embedding_override_model": FORTISAI_RAG_EMBEDDING_MODEL or "",
        "fortisai_rag_embedding_selection_policy": rag_embedding_route.get(
            "embedding_selection_policy",
            "classified_route",
        ),
        "fortisai_rag_background_web_upsert": FORTISAI_RAG_BACKGROUND_WEB_UPSERT,
    }


def _dify_db_connection():
    if not all([DIFY_DB_HOST, DIFY_DB_NAME, DIFY_DB_USER, DIFY_DB_PASSWORD]):
        raise RuntimeError("Dify database environment is not configured for bridge model setup")
    try:
        import psycopg2
    except Exception as exc:
        raise RuntimeError("psycopg2 is not installed in the Dify bridge container") from exc
    return psycopg2.connect(
        host=DIFY_DB_HOST,
        port=DIFY_DB_PORT,
        dbname=DIFY_DB_NAME,
        user=DIFY_DB_USER,
        password=DIFY_DB_PASSWORD,
    )


@app.post("/dify_openai_compatible_model_setup")
def dify_openai_compatible_model_setup(request: OpenAiCompatibleModelSetupRequest) -> Dict[str, Any]:
    provider = request.provider.strip()
    model_type = request.modelType.strip() or "llm"
    models: list[str] = []
    seen: set[str] = set()
    for raw_model in request.models:
        model = str(raw_model or "").strip()
        if not model or model in seen:
            continue
        seen.add(model)
        models.append(model)
    if not provider:
        raise HTTPException(status_code=400, detail="provider is required")
    if not models:
        raise HTTPException(status_code=400, detail="models are required")
    managed_credential_name = (request.managedCredentialName or "FortisAI local").strip() or "FortisAI local"

    try:
        conn = _dify_db_connection()
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc

    configured: list[dict[str, Any]] = []
    removed_models: list[str] = []
    try:
        with conn:
            with conn.cursor() as cur:
                template_where = [
                    "provider_name = %s",
                    "model_type = %s",
                    "encrypted_config IS NOT NULL",
                    "encrypted_config <> ''",
                ]
                template_params: list[Any] = [provider, model_type]
                if request.templateModel:
                    template_where.append("model_name = %s")
                    template_params.append(request.templateModel)
                if DIFY_ADMIN_WORKSPACE_ID:
                    template_where.append("tenant_id = %s")
                    template_params.append(DIFY_ADMIN_WORKSPACE_ID)

                cur.execute(
                    f"""
                    SELECT tenant_id, encrypted_config
                    FROM provider_model_credentials
                    WHERE {' AND '.join(template_where)}
                    ORDER BY updated_at DESC
                    LIMIT 1
                    """,
                    template_params,
                )
                template = cur.fetchone()
                if not template:
                    raise HTTPException(
                        status_code=409,
                        detail="No existing validated Dify model credential template is available",
                    )
                tenant_id, encrypted_config = template

                for model in models:
                    cur.execute(
                        """
                        SELECT credential_id
                        FROM provider_models
                        WHERE tenant_id = %s
                          AND provider_name = %s
                          AND model_name = %s
                          AND model_type = %s
                          AND credential_id IS NOT NULL
                        """,
                        (tenant_id, provider, model, model_type),
                    )
                    existing_model = cur.fetchone()
                    if existing_model and existing_model[0]:
                        configured.append({"model": model, "action": "existing", "credential_id_present": True})
                        continue

                    cur.execute(
                        """
                        SELECT id
                        FROM provider_model_credentials
                        WHERE tenant_id = %s
                          AND provider_name = %s
                          AND model_name = %s
                          AND model_type = %s
                        ORDER BY updated_at DESC
                        LIMIT 1
                        """,
                        (tenant_id, provider, model, model_type),
                    )
                    credential = cur.fetchone()
                    action = "reuse-credential"
                    if credential:
                        credential_id = credential[0]
                    else:
                        cur.execute(
                            """
                            INSERT INTO provider_model_credentials (
                              tenant_id, provider_name, model_name, model_type, credential_name, encrypted_config
                            )
                            VALUES (%s, %s, %s, %s, %s, %s)
                            RETURNING id
                            """,
                            (tenant_id, provider, model, model_type, "FortisAI local", encrypted_config),
                        )
                        credential_id = cur.fetchone()[0]
                        action = "created-credential"

                    cur.execute(
                        """
                        INSERT INTO provider_models (
                          tenant_id, provider_name, model_name, model_type, credential_id, is_valid
                        )
                        VALUES (%s, %s, %s, %s, %s, true)
                        ON CONFLICT (tenant_id, provider_name, model_name, model_type)
                        DO UPDATE SET
                          credential_id = EXCLUDED.credential_id,
                          is_valid = true,
                          updated_at = CURRENT_TIMESTAMP(0)
                        """,
                        (tenant_id, provider, model, model_type, credential_id),
                    )
                    configured.append({"model": model, "action": action, "credential_id_present": True})

                if request.pruneStale:
                    cur.execute(
                        """
                        SELECT pm.model_name
                        FROM provider_models pm
                        LEFT JOIN provider_model_credentials pmc
                               ON pmc.id = pm.credential_id
                        WHERE pm.tenant_id = %s
                          AND pm.provider_name = %s
                          AND pm.model_type = %s
                          AND NOT (pm.model_name = ANY(%s))
                          AND (pmc.credential_name = %s OR pmc.credential_name IS NULL)
                        ORDER BY pm.model_name
                        """,
                        (tenant_id, provider, model_type, models, managed_credential_name),
                    )
                    removed_models = [str(row[0]) for row in cur.fetchall() if row and row[0]]
                    if removed_models:
                        cur.execute(
                            """
                            DELETE FROM provider_models
                            WHERE tenant_id = %s
                              AND provider_name = %s
                              AND model_type = %s
                              AND model_name = ANY(%s)
                            """,
                            (tenant_id, provider, model_type, removed_models),
                        )
                        cur.execute(
                            """
                            DELETE FROM provider_model_credentials pmc
                            WHERE pmc.tenant_id = %s
                              AND pmc.provider_name = %s
                              AND pmc.model_type = %s
                              AND pmc.model_name = ANY(%s)
                              AND pmc.credential_name = %s
                              AND NOT EXISTS (
                                SELECT 1
                                FROM provider_models pm
                                WHERE pm.credential_id = pmc.id
                              )
                            """,
                            (tenant_id, provider, model_type, removed_models, managed_credential_name),
                        )
    except HTTPException:
        raise
    except Exception as exc:
        log.exception("Dify OpenAI-compatible model setup failed")
        raise HTTPException(status_code=500, detail=str(exc)) from exc
    finally:
        conn.close()

    return {
        "status": "ok",
        "provider": provider,
        "model_type": model_type,
        "model_count": len(models),
        "configured_model_count": len(configured),
        "prune_stale": request.pruneStale,
        "removed_model_count": len(removed_models),
        "configured_models": configured,
        "removed_models": removed_models,
    }


@app.post("/dify_api_request")
def api_request(request: ApiRequest) -> Dict[str, Any]:
    try:
        result = dify_request(
            method=request.method,
            path=request.path,
            query=request.query,
            body=request.body,
            request_headers=request.headers,
            auth_mode=request.authMode,
            require_api_key=request.requireApiKey,
        )
    except Exception as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    if int(result.get("status", 500)) >= 400:
        raise HTTPException(status_code=int(result.get("status", 500)), detail=result)
    return result


@app.post("/dify_chat_messages")
def dify_chat_messages(request: ChatMessageRequest) -> Dict[str, Any]:
    payload = {
        "inputs": request.inputs,
        "query": request.query,
        "response_mode": request.response_mode,
        "user": request.user,
    }
    if request.conversation_id:
        payload["conversation_id"] = request.conversation_id
    if request.files:
        payload["files"] = request.files

    result = dify_request(
        method="POST",
        path="/v1/chat-messages",
        body=payload,
        auth_mode="app",
        require_api_key=True,
    )
    if int(result.get("status", 500)) >= 400:
        raise HTTPException(status_code=int(result.get("status", 500)), detail=result)
    return result


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("DIFY_BRIDGE_PORT", "8093")))
