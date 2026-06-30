#!/usr/bin/env python3
"""Import or update a FortisAI Dify app from source-controlled YAML."""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any

import yaml


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent
DEFAULT_YAML = SCRIPT_DIR / "main/dify/configurations/local-openai-compatible-router.yaml"
DEFAULT_DIFY_BASE_URL = "http://127.0.0.1:18081"
DEFAULT_OPENAI_COMPATIBLE_PROVIDER = "langgenius/openai_api_compatible/openai_api_compatible"
DEFAULT_OPENAI_COMPATIBLE_PLUGIN = (
    "langgenius/openai_api_compatible:0.0.53@a0dfb462961a03c6a6415d4185043185b01017c64da93cf82a9e5ecaf59f8ed0"
)
DEFAULT_LOCAL_OPENAI_BASE_URL = "http://fortisai-llama-server.fortisai.local:8011/v1"
DEFAULT_LOCAL_OPENAI_API_KEY = "local-llama"
VAULT_KEYS_FILE = Path("/opt/home/aiuser/fortisai-dev/vault/vault-init.json")
DIFY_ENV_FILE = Path("/opt/home/aiuser/fortisai-dev/dify/docker/.env")
DIFY_KEY_JSON_FILES = [
    Path("/opt/home/aiuser/fortisai-dev/mcp/dify-mcp/dify-api-key.json"),
    REPO_ROOT / "Development_Environment/mcp/dify-mcp/dify-api-key.json",
]


class DifyImportError(RuntimeError):
    pass


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Import/update a Dify app from YAML, confirm if needed, and publish it.",
    )
    parser.add_argument(
        "--yaml",
        default=os.environ.get("DIFY_IMPORT_YAML", str(DEFAULT_YAML)),
        help=f"YAML file to import. Defaults to {DEFAULT_YAML}",
    )
    parser.add_argument(
        "--base-url",
        default=os.environ.get("DIFY_BASE_URL", DEFAULT_DIFY_BASE_URL),
        help=f"Dify base URL. Defaults to {DEFAULT_DIFY_BASE_URL}",
    )
    parser.add_argument("--workspace-id", default=os.environ.get("DIFY_ADMIN_WORKSPACE_ID") or "")
    parser.add_argument("--app-id", default=os.environ.get("DIFY_IMPORT_APP_ID") or "")
    parser.add_argument("--app-name", default=os.environ.get("DIFY_IMPORT_APP_NAME") or "")
    parser.add_argument("--marked-name", default=os.environ.get("DIFY_IMPORT_MARKED_NAME") or "FortisAI import")
    parser.add_argument(
        "--marked-comment",
        default=os.environ.get("DIFY_IMPORT_MARKED_COMMENT") or "Imported from FortisAI source-controlled YAML",
    )
    parser.add_argument("--skip-publish", action="store_true", help="Import/update only; do not publish workflow apps")
    parser.add_argument(
        "--skip-model-setup",
        action="store_true",
        help="Do not configure OpenAI-compatible provider/model credentials before publishing",
    )
    parser.add_argument(
        "--openai-provider",
        default=os.environ.get("DIFY_OPENAI_COMPATIBLE_PROVIDER") or DEFAULT_OPENAI_COMPATIBLE_PROVIDER,
        help=f"OpenAI-compatible provider id. Defaults to {DEFAULT_OPENAI_COMPATIBLE_PROVIDER}",
    )
    parser.add_argument(
        "--openai-base-url",
        default=os.environ.get("DIFY_LOCAL_OPENAI_BASE_URL") or os.environ.get("FORTISAI_LLAMA_OPENAI_BASE_URL") or "",
        help="OpenAI-compatible base URL visible from Dify containers",
    )
    parser.add_argument(
        "--setup-route-models",
        action="store_true",
        help="Also configure every generated route model; default configures only workflow LLM models needed for publish",
    )
    parser.add_argument("--dry-run", action="store_true", help="Validate inputs and report the planned action")
    return parser.parse_args()


def read_env_file(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    if not path.exists():
        return values
    for raw_line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip('"').strip("'")
    return values


def http_json(
    method: str,
    url: str,
    *,
    headers: dict[str, str] | None = None,
    body: dict[str, Any] | None = None,
    timeout: int = 60,
) -> tuple[int, dict[str, Any]]:
    data = None
    request_headers = {"Accept": "application/json"}
    if headers:
        request_headers.update(headers)
    if body is not None:
        data = json.dumps(body).encode("utf-8")
        request_headers["Content-Type"] = "application/json"

    request = urllib.request.Request(url, data=data, headers=request_headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            raw = response.read().decode("utf-8", errors="replace")
            return response.status, json.loads(raw) if raw else {}
    except urllib.error.HTTPError as exc:
        raw = exc.read().decode("utf-8", errors="replace")
        try:
            payload = json.loads(raw) if raw else {}
        except json.JSONDecodeError:
            payload = {"message": raw[:1000]}
        return exc.code, payload
    except (TimeoutError, urllib.error.URLError) as exc:
        return 599, {"message": str(exc) or exc.__class__.__name__}


def vault_value(path: str) -> str:
    token = os.environ.get("VAULT_TOKEN", "").strip()
    if not token and VAULT_KEYS_FILE.exists():
        try:
            token = json.loads(VAULT_KEYS_FILE.read_text(encoding="utf-8")).get("root_token", "").strip()
        except Exception:
            token = ""
    if not token:
        return ""

    url = f"http://127.0.0.1:8200/v1/secret/data/fortisai/dev/{path}"
    try:
        status, payload = http_json("GET", url, headers={"X-Vault-Token": token}, timeout=10)
    except Exception:
        return ""
    if status >= 300:
        return ""
    value = payload.get("data", {}).get("data", {}).get("value", "")
    return str(value or "").strip()


def resolve_admin_key() -> tuple[str, str]:
    candidates: list[tuple[str, str]] = [
        ("env:DIFY_ADMIN_API_KEY", os.environ.get("DIFY_ADMIN_API_KEY", "")),
        ("env:ADMIN_API_KEY", os.environ.get("ADMIN_API_KEY", "")),
        ("vault:dify/admin_api_key", vault_value("dify/admin_api_key")),
        ("vault:dify/api_key", vault_value("dify/api_key")),
    ]

    env_values = read_env_file(DIFY_ENV_FILE)
    candidates.append(("dify-env:ADMIN_API_KEY", env_values.get("ADMIN_API_KEY", "")))

    for key_file in DIFY_KEY_JSON_FILES:
        if not key_file.exists():
            continue
        try:
            payload = json.loads(key_file.read_text(encoding="utf-8"))
        except Exception:
            continue
        candidates.extend(
            [
                (f"{key_file}:dify_admin_api_key", payload.get("dify_admin_api_key", "")),
                (f"{key_file}:dify_api_key", payload.get("dify_api_key", "")),
            ]
        )

    for source, value in candidates:
        clean = str(value or "").strip()
        if clean:
            return clean, source
    raise DifyImportError("No Dify admin API key found in env, Vault, Dify .env, or compatibility JSON")


def resolve_local_openai_api_key() -> tuple[str, str]:
    candidates: list[tuple[str, str]] = [
        ("env:FORTISAI_LLAMA_OPENAI_API_KEY", os.environ.get("FORTISAI_LLAMA_OPENAI_API_KEY", "")),
        ("env:LOCAL_OPENAI_API_KEY", os.environ.get("LOCAL_OPENAI_API_KEY", "")),
        ("env:OPENAI_API_KEY", os.environ.get("OPENAI_API_KEY", "")),
        ("vault:llama/openai_api_key", vault_value("llama/openai_api_key")),
        ("vault:llama/api_key", vault_value("llama/api_key")),
    ]

    env_values = read_env_file(DIFY_ENV_FILE)
    candidates.append(("dify-env:FORTISAI_LLAMA_OPENAI_API_KEY", env_values.get("FORTISAI_LLAMA_OPENAI_API_KEY", "")))

    for source, value in candidates:
        clean = str(value or "").strip()
        if clean:
            return clean, source
    return DEFAULT_LOCAL_OPENAI_API_KEY, "default:local-llama"


def console_headers(admin_key: str, workspace_id: str = "") -> dict[str, str]:
    headers = {"Authorization": f"Bearer {admin_key}"}
    if workspace_id:
        headers["X-WORKSPACE-ID"] = workspace_id
    return headers


def resolve_workspace_id(base_url: str, admin_key: str, explicit_workspace_id: str) -> tuple[str, str]:
    if explicit_workspace_id:
        return explicit_workspace_id, "explicit"

    for env_name in ("DIFY_WORKSPACE_ID", "DIFY_ADMIN_WORKSPACE_ID"):
        value = os.environ.get(env_name, "").strip()
        if value:
            return value, f"env:{env_name}"

    for vault_path in ("dify/admin_workspace_id", "dify/workspace_id"):
        value = vault_value(vault_path)
        if value:
            return value, f"vault:{vault_path}"

    url = f"{base_url.rstrip('/')}/console/api/all-workspaces?page=1&limit=100"
    status, payload = http_json("GET", url, headers=console_headers(admin_key), timeout=30)
    if status == 599:
        return "", "admin-api:implicit-current-workspace"
    if status >= 300:
        raise DifyImportError(f"Could not list Dify workspaces via admin API (HTTP {status}): {payload}")

    workspaces = payload.get("data") or payload.get("workspaces") or []
    if not isinstance(workspaces, list) or not workspaces:
        raise DifyImportError("Dify admin API returned no workspaces")

    current = next((w for w in workspaces if isinstance(w, dict) and w.get("current") is True), None)
    target = current or next((w for w in workspaces if isinstance(w, dict) and w.get("id")), None)
    if not isinstance(target, dict) or not target.get("id"):
        raise DifyImportError("Dify admin API returned workspaces without ids")
    return str(target["id"]), "admin-api:all-workspaces"


def load_yaml(path: Path) -> dict[str, Any]:
    try:
        data = yaml.safe_load(path.read_text(encoding="utf-8"))
    except yaml.YAMLError as exc:
        raise DifyImportError(f"Invalid YAML: {exc}") from exc
    if not isinstance(data, dict):
        raise DifyImportError("YAML root must be a mapping")
    return data


def router_answer_text(router: dict[str, Any]) -> str:
    metadata = router.get("metadata") or {}
    provider = router.get("provider") or {}
    routes = router.get("routes") or []
    lines = [
        "FortisAI local LLM routing configuration is installed.",
        "",
        f"Router: {metadata.get('name', 'local-openai-compatible-router')}",
        f"Endpoint: {provider.get('endpoint_base_url', '')}",
        f"Default request type: {(router.get('routing_policy') or {}).get('default_request_type', '')}",
        "",
        "Available routes:",
    ]
    for route in routes[:20]:
        if not isinstance(route, dict):
            continue
        request_type = route.get("request_type", "")
        primary = route.get("primary_model", "")
        lines.append(f"- {request_type}: {primary}")
    return "\n".join(lines)


def compile_router_to_app(router: dict[str, Any], app_name_override: str = "") -> dict[str, Any]:
    metadata = router.get("metadata") or {}
    app_name = app_name_override or metadata.get("name") or "local-openai-compatible-router"
    description = metadata.get("description") or "FortisAI local OpenAI-compatible model router."
    answer_text = router_answer_text(router)

    return {
        "version": "0.6.0",
        "kind": "app",
        "app": {
            "name": app_name,
            "mode": "advanced-chat",
            "icon": "\U0001F916",
            "icon_background": "#FFEAD5",
            "icon_type": "emoji",
            "description": description,
            "use_icon_as_answer_icon": False,
        },
        "workflow": {
            "conversation_variables": [],
            "environment_variables": [],
            "features": {
                "file_upload": {
                    "enabled": False,
                    "allowed_file_extensions": [],
                    "allowed_file_types": [],
                    "allowed_file_upload_methods": [],
                    "fileUploadConfig": {
                        "attachment_image_file_size_limit": 2,
                        "audio_file_size_limit": 50,
                        "batch_count_limit": 5,
                        "file_size_limit": 15,
                        "file_upload_limit": 20,
                        "image_file_batch_limit": 10,
                        "image_file_size_limit": 10,
                        "single_chunk_attachment_limit": 10,
                        "video_file_size_limit": 100,
                        "workflow_file_upload_limit": 10,
                    },
                    "image": {"enabled": False, "number_limits": 3, "transfer_methods": []},
                    "number_limits": 3,
                },
                "opening_statement": "",
                "retriever_resource": {"enabled": False},
                "sensitive_word_avoidance": {"enabled": False},
                "speech_to_text": {"enabled": False},
                "suggested_questions": [],
                "suggested_questions_after_answer": {"enabled": False},
                "text_to_speech": {"enabled": False, "language": "", "voice": ""},
            },
            "graph": {
                "edges": [
                    {
                        "id": "start-to-answer",
                        "source": "start",
                        "sourceHandle": "source",
                        "target": "answer",
                        "targetHandle": "target",
                        "type": "custom",
                        "zIndex": 0,
                        "data": {"isInLoop": False, "sourceType": "start", "targetType": "answer"},
                    }
                ],
                "nodes": [
                    {
                        "id": "start",
                        "type": "custom",
                        "position": {"x": 80, "y": 280},
                        "positionAbsolute": {"x": 80, "y": 280},
                        "sourcePosition": "right",
                        "targetPosition": "left",
                        "width": 243,
                        "height": 74,
                        "selected": False,
                        "data": {
                            "title": "User Input",
                            "type": "start",
                            "variables": [
                                {
                                    "id": "user_input",
                                    "name": "user_input",
                                    "type": "string",
                                    "required": False,
                                    "default": "",
                                }
                            ],
                            "selected": False,
                        },
                    },
                    {
                        "id": "answer",
                        "type": "custom",
                        "position": {"x": 420, "y": 280},
                        "positionAbsolute": {"x": 420, "y": 280},
                        "sourcePosition": "right",
                        "targetPosition": "left",
                        "width": 243,
                        "height": 105,
                        "selected": False,
                        "data": {
                            "title": "Router Summary",
                            "type": "answer",
                            "answer": answer_text,
                            "variables": [],
                            "selected": False,
                        },
                    },
                ],
                "viewport": {"x": 0, "y": 0, "zoom": 1},
            },
            "rag_pipeline_variables": [],
        },
    }


def prepare_app_dsl(source: dict[str, Any], app_name_override: str = "") -> tuple[dict[str, Any], str]:
    if source.get("kind") == "app" and isinstance(source.get("app"), dict):
        app = source
        if app_name_override:
            app = json.loads(json.dumps(source))
            app.setdefault("app", {})["name"] = app_name_override
        return app, "native-dify-app"

    if source.get("kind") == "fortisai.dify.openai-compatible-router.v1":
        return compile_router_to_app(source, app_name_override), "compiled-fortisai-router"

    raise DifyImportError(
        "YAML is not a Dify app DSL and is not a FortisAI router YAML "
        "(expected kind: app or fortisai.dify.openai-compatible-router.v1)"
    )


def app_name(app_dsl: dict[str, Any]) -> str:
    name = str((app_dsl.get("app") or {}).get("name") or "").strip()
    if not name:
        raise DifyImportError("Dify app DSL is missing app.name")
    return name


def workflow_llm_models(app_dsl: dict[str, Any]) -> list[dict[str, str]]:
    graph = ((app_dsl.get("workflow") or {}).get("graph") or {})
    nodes = graph.get("nodes") or []
    models: list[dict[str, str]] = []
    for node in nodes:
        if not isinstance(node, dict):
            continue
        data = node.get("data") or {}
        if not isinstance(data, dict) or data.get("type") != "llm":
            continue
        model_data = data.get("model") or {}
        if not isinstance(model_data, dict):
            continue
        provider = str(model_data.get("provider") or "").strip()
        model = str(model_data.get("name") or "").strip()
        mode = str(model_data.get("mode") or "chat").strip() or "chat"
        if provider and model:
            models.append({"provider": provider, "model": model, "mode": mode})
    return models


def fortisai_route_models(app_dsl: dict[str, Any], provider: str) -> list[dict[str, str]]:
    fortisai = app_dsl.get("fortisai") or {}
    if not isinstance(fortisai, dict):
        return []
    route_models = fortisai.get("route_models") or []
    classifier_model = fortisai.get("classifier_model")
    candidates = [classifier_model, *(route_models if isinstance(route_models, list) else [])]
    result: list[dict[str, str]] = []
    for model in candidates:
        clean = str(model or "").strip()
        if clean:
            result.append({"provider": provider, "model": clean, "mode": "chat"})
    return result


def unique_model_refs(refs: list[dict[str, str]]) -> list[dict[str, str]]:
    seen: set[tuple[str, str, str]] = set()
    result: list[dict[str, str]] = []
    for ref in refs:
        provider = str(ref.get("provider") or "").strip()
        model = str(ref.get("model") or "").strip()
        mode = str(ref.get("mode") or "chat").strip() or "chat"
        key = (provider, model, mode)
        if not provider or not model or key in seen:
            continue
        seen.add(key)
        result.append({"provider": provider, "model": model, "mode": mode})
    return result


def marketplace_dependencies(app_dsl: dict[str, Any]) -> list[str]:
    result: list[str] = []
    dependencies = app_dsl.get("dependencies") or []
    if isinstance(dependencies, list):
        for dependency in dependencies:
            if not isinstance(dependency, dict) or dependency.get("type") != "marketplace":
                continue
            value = dependency.get("value") or {}
            if not isinstance(value, dict):
                continue
            identifier = str(value.get("marketplace_plugin_unique_identifier") or "").strip()
            if identifier:
                result.append(identifier)
    if not result:
        result.append(DEFAULT_OPENAI_COMPATIBLE_PLUGIN)
    return sorted(set(result))


def list_model_providers(
    base_url: str,
    admin_key: str,
    workspace_id: str,
    model_type: str = "llm",
) -> tuple[int, dict[str, Any]]:
    query = urllib.parse.urlencode({"model_type": model_type})
    return http_json(
        "GET",
        f"{base_url.rstrip('/')}/console/api/workspaces/current/model-providers?{query}",
        headers=console_headers(admin_key, workspace_id),
        timeout=30,
    )


def model_provider_available(providers_payload: dict[str, Any], provider: str) -> bool:
    providers = providers_payload.get("data") or []
    if not isinstance(providers, list):
        return False
    return any(isinstance(item, dict) and item.get("provider") == provider for item in providers)


def install_marketplace_dependencies(
    base_url: str,
    admin_key: str,
    workspace_id: str,
    plugin_identifiers: list[str],
) -> tuple[int, dict[str, Any]]:
    return http_json(
        "POST",
        f"{base_url.rstrip('/')}/console/api/workspaces/current/plugin/install/pkg",
        headers=console_headers(admin_key, workspace_id),
        body={"plugin_unique_identifiers": plugin_identifiers},
        timeout=90,
    )


def ensure_model_provider(
    base_url: str,
    admin_key: str,
    workspace_id: str,
    app_dsl: dict[str, Any],
    provider: str,
) -> dict[str, Any]:
    status, payload = list_model_providers(base_url, admin_key, workspace_id)
    if status == 599:
        return {"status": "unknown", "provider": provider, "installed": False, "reason": "provider-list-timeout"}
    if status >= 300:
        raise DifyImportError(f"Could not list Dify model providers (HTTP {status}): {payload}")
    if model_provider_available(payload, provider):
        return {"status": "available", "provider": provider, "installed": False}

    plugin_identifiers = marketplace_dependencies(app_dsl)
    install_status, install_payload = install_marketplace_dependencies(
        base_url, admin_key, workspace_id, plugin_identifiers
    )
    if install_status >= 300:
        raise DifyImportError(
            f"Could not install Dify marketplace dependencies (HTTP {install_status}): {install_payload}"
        )

    for _ in range(10):
        time.sleep(2)
        status, payload = list_model_providers(base_url, admin_key, workspace_id)
        if status >= 300:
            raise DifyImportError(f"Could not list Dify model providers after install (HTTP {status}): {payload}")
        if model_provider_available(payload, provider):
            return {
                "status": "available",
                "provider": provider,
                "installed": True,
                "install_http": install_status,
                "install_task_id": install_payload.get("task_id"),
                "plugins": plugin_identifiers,
            }

    raise DifyImportError(
        f"Dify model provider {provider!r} was not available after installing dependencies: {plugin_identifiers}"
    )


def local_openai_base_url(app_dsl: dict[str, Any], explicit_base_url: str) -> tuple[str, str]:
    if explicit_base_url:
        return explicit_base_url.rstrip("/"), "explicit"

    fortisai = app_dsl.get("fortisai") or {}
    if isinstance(fortisai, dict):
        value = str(fortisai.get("openai_base_url") or "").strip()
        if value:
            return value.rstrip("/"), "app:fortisai.openai_base_url"

    env_values = read_env_file(DIFY_ENV_FILE)
    for source, value in (
        ("dify-env:FORTISAI_LLAMA_OPENAI_BASE_URL", env_values.get("FORTISAI_LLAMA_OPENAI_BASE_URL", "")),
        ("dify-env:FORTISAI_LLAMA_SERVER_BASE_URL", env_values.get("FORTISAI_LLAMA_SERVER_BASE_URL", "")),
    ):
        clean = str(value or "").strip()
        if clean:
            return clean.rstrip("/"), source

    for source, value in (
        ("env:DIFY_LOCAL_OPENAI_BASE_URL", os.environ.get("DIFY_LOCAL_OPENAI_BASE_URL", "")),
        ("env:FORTISAI_LLAMA_OPENAI_BASE_URL", os.environ.get("FORTISAI_LLAMA_OPENAI_BASE_URL", "")),
        ("env:FORTISAI_LLAMA_SERVER_BASE_URL", os.environ.get("FORTISAI_LLAMA_SERVER_BASE_URL", "")),
    ):
        clean = str(value or "").strip()
        if clean:
            return clean.rstrip("/"), source

    return DEFAULT_LOCAL_OPENAI_BASE_URL, "default:fortisai-llama-server"


def openai_compatible_credentials(base_url: str, api_key: str, mode: str) -> list[dict[str, Any]]:
    base = {
        "endpoint_url": base_url,
        "api_key": api_key,
        "mode": mode,
        "context_size": "4096",
        "max_tokens_to_sample": "4096",
    }
    candidates = [
        base,
        {"endpoint_url": base_url, "api_key": api_key, "mode": mode, "context_size": "4096"},
        {"endpoint_url": base_url, "api_key": api_key, "context_size": "4096"},
    ]
    unique: list[dict[str, Any]] = []
    seen: set[str] = set()
    for item in candidates:
        key = json.dumps(item, sort_keys=True)
        if key in seen:
            continue
        seen.add(key)
        unique.append(item)
    return unique


def list_apps(base_url: str, admin_key: str, workspace_id: str) -> list[dict[str, Any]]:
    result: list[dict[str, Any]] = []
    page = 1
    while True:
        query = urllib.parse.urlencode({"page": page, "limit": 100})
        url = f"{base_url.rstrip('/')}/console/api/apps?{query}"
        status, payload = http_json("GET", url, headers=console_headers(admin_key, workspace_id), timeout=30)
        if status >= 300:
            raise DifyImportError(f"Could not list Dify apps (HTTP {status}): {payload}")
        data = payload.get("data") or []
        if isinstance(data, list):
            result.extend(item for item in data if isinstance(item, dict))
        if not payload.get("has_more"):
            break
        page += 1
    return result


def find_existing_app(apps: list[dict[str, Any]], name: str) -> dict[str, Any] | None:
    matches = [app for app in apps if str(app.get("name", "")).strip() == name]
    if len(matches) > 1:
        ids = ", ".join(str(app.get("id")) for app in matches)
        raise DifyImportError(f"Multiple Dify apps named {name!r}; pass --app-id explicitly. Matching ids: {ids}")
    return matches[0] if matches else None


def import_app(
    base_url: str,
    admin_key: str,
    workspace_id: str,
    yaml_content: str,
    app_id: str,
) -> tuple[int, dict[str, Any]]:
    body = {"mode": "yaml-content", "yaml_content": yaml_content}
    if app_id:
        body["app_id"] = app_id
    return http_json(
        "POST",
        f"{base_url.rstrip('/')}/console/api/apps/imports",
        headers=console_headers(admin_key, workspace_id),
        body=body,
        timeout=90,
    )


def confirm_import(base_url: str, admin_key: str, workspace_id: str, import_id: str) -> tuple[int, dict[str, Any]]:
    return http_json(
        "POST",
        f"{base_url.rstrip('/')}/console/api/apps/imports/{urllib.parse.quote(import_id)}/confirm",
        headers=console_headers(admin_key, workspace_id),
        body={},
        timeout=90,
    )


def publish_app(
    base_url: str,
    admin_key: str,
    workspace_id: str,
    app_id: str,
    marked_name: str,
    marked_comment: str,
) -> tuple[int, dict[str, Any]]:
    marked_name = marked_name[:30]
    marked_comment = marked_comment[:100]
    return http_json(
        "POST",
        f"{base_url.rstrip('/')}/console/api/apps/{urllib.parse.quote(app_id)}/workflows/publish",
        headers=console_headers(admin_key, workspace_id),
        body={"marked_name": marked_name, "marked_comment": marked_comment},
        timeout=90,
    )


def credential_id_from_payload(payload: dict[str, Any]) -> str:
    current = str(payload.get("current_credential_id") or "").strip()
    if current:
        return current
    available = payload.get("available_credentials") or []
    if isinstance(available, list):
        for item in available:
            if not isinstance(item, dict):
                continue
            for key in ("credential_id", "id"):
                value = str(item.get(key) or "").strip()
                if value:
                    return value
    return ""


def same_credential_error(payload: dict[str, Any]) -> bool:
    message = str(payload.get("message") or payload.get("error") or payload).lower()
    return "same credential" in message


def get_model_credential(
    base_url: str,
    admin_key: str,
    workspace_id: str,
    provider: str,
    model: str,
) -> tuple[int, dict[str, Any]]:
    query = urllib.parse.urlencode({"model": model, "model_type": "llm", "config_from": "custom-model"})
    return http_json(
        "GET",
        f"{base_url.rstrip('/')}/console/api/workspaces/current/model-providers/{provider}/models/credentials?{query}",
        headers=console_headers(admin_key, workspace_id),
        timeout=30,
    )


def validate_model_credential(
    base_url: str,
    admin_key: str,
    workspace_id: str,
    provider: str,
    model: str,
    credentials: dict[str, Any],
) -> tuple[int, dict[str, Any]]:
    return http_json(
        "POST",
        f"{base_url.rstrip('/')}/console/api/workspaces/current/model-providers/{provider}/models/credentials/validate",
        headers=console_headers(admin_key, workspace_id),
        body={"model": model, "model_type": "llm", "credentials": credentials},
        timeout=60,
    )


def save_model_credential(
    base_url: str,
    admin_key: str,
    workspace_id: str,
    provider: str,
    model: str,
    credentials: dict[str, Any],
    credential_id: str,
) -> tuple[int, dict[str, Any], str]:
    body: dict[str, Any] = {
        "model": model,
        "model_type": "llm",
        "credentials": credentials,
        "name": "FortisAI local",
    }
    if credential_id:
        body["credential_id"] = credential_id
        method = "PUT"
    else:
        method = "POST"
    status, payload = http_json(
        method,
        f"{base_url.rstrip('/')}/console/api/workspaces/current/model-providers/{provider}/models/credentials",
        headers=console_headers(admin_key, workspace_id),
        body=body,
        timeout=60,
    )
    return status, payload, "update" if credential_id else "create"


def switch_model_credential(
    base_url: str,
    admin_key: str,
    workspace_id: str,
    provider: str,
    model: str,
    credential_id: str,
) -> tuple[int, dict[str, Any]]:
    return http_json(
        "POST",
        f"{base_url.rstrip('/')}/console/api/workspaces/current/model-providers/{provider}/models/credentials/switch",
        headers=console_headers(admin_key, workspace_id),
        body={"model": model, "model_type": "llm", "credential_id": credential_id},
        timeout=30,
    )


def add_model_to_provider_list(
    base_url: str,
    admin_key: str,
    workspace_id: str,
    provider: str,
    model: str,
    credential_id: str,
) -> tuple[int, dict[str, Any]]:
    return http_json(
        "POST",
        f"{base_url.rstrip('/')}/console/api/workspaces/current/model-providers/{provider}/models",
        headers=console_headers(admin_key, workspace_id),
        body={"model": model, "model_type": "llm", "config_from": "custom-model", "credential_id": credential_id},
        timeout=30,
    )


def enable_model(
    base_url: str,
    admin_key: str,
    workspace_id: str,
    provider: str,
    model: str,
) -> tuple[int, dict[str, Any]]:
    return http_json(
        "PATCH",
        f"{base_url.rstrip('/')}/console/api/workspaces/current/model-providers/{provider}/models/enable",
        headers=console_headers(admin_key, workspace_id),
        body={"model": model, "model_type": "llm"},
        timeout=30,
    )


def select_valid_credentials(
    base_url: str,
    admin_key: str,
    workspace_id: str,
    provider: str,
    model: str,
    local_base_url: str,
    api_key: str,
    mode: str,
) -> tuple[dict[str, Any], dict[str, Any]]:
    errors: list[str] = []
    for credentials in openai_compatible_credentials(local_base_url, api_key, mode):
        status, payload = validate_model_credential(base_url, admin_key, workspace_id, provider, model, credentials)
        if status < 300 and payload.get("result") == "success":
            return credentials, {"validate_http": status, "schema": sorted(credentials.keys())}
        message = payload.get("error") or payload.get("message") or payload
        errors.append(f"HTTP {status}: {message}")
    raise DifyImportError(
        f"Could not validate OpenAI-compatible credentials for {provider}/{model}. "
        f"Tried {len(errors)} schema variants. Last error: {errors[-1] if errors else 'none'}"
    )


def setup_model_connections(
    base_url: str,
    admin_key: str,
    workspace_id: str,
    app_dsl: dict[str, Any],
    openai_provider: str,
    explicit_openai_base_url: str,
    setup_route_models: bool = False,
) -> dict[str, Any]:
    required_refs = unique_model_refs(workflow_llm_models(app_dsl))
    required_keys = {(ref["provider"], ref["model"]) for ref in required_refs}
    route_refs = fortisai_route_models(app_dsl, openai_provider) if setup_route_models else []
    refs = unique_model_refs(required_refs + route_refs)
    refs = [ref for ref in refs if ref["provider"] == openai_provider]
    if not refs:
        return {"status": "skipped", "reason": "no-openai-compatible-models"}

    provider_setup = ensure_model_provider(base_url, admin_key, workspace_id, app_dsl, openai_provider)
    local_base_url, local_base_url_source = local_openai_base_url(app_dsl, explicit_openai_base_url)
    local_api_key, local_api_key_source = resolve_local_openai_api_key()
    configured: list[dict[str, Any]] = []
    skipped: list[dict[str, Any]] = []

    for ref in refs:
        model = ref["model"]
        mode = ref.get("mode") or "chat"
        required = (openai_provider, model) in required_keys
        try:
            credential_status, credential_payload = get_model_credential(
                base_url, admin_key, workspace_id, openai_provider, model
            )
            if credential_status >= 300:
                raise DifyImportError(
                    f"Could not read existing Dify model credential for {openai_provider}/{model} "
                    f"(HTTP {credential_status}): {credential_payload}"
                )
            current_credential_id = credential_id_from_payload(credential_payload)
            if current_credential_id:
                validation = {"validate_http": "skipped-existing-credential", "schema": []}
                save_action = "existing"
            else:
                credentials, validation = select_valid_credentials(
                    base_url,
                    admin_key,
                    workspace_id,
                    openai_provider,
                    model,
                    local_base_url,
                    local_api_key,
                    mode,
                )
                save_status, save_payload, save_action = save_model_credential(
                    base_url,
                    admin_key,
                    workspace_id,
                    openai_provider,
                    model,
                    credentials,
                    current_credential_id,
                )
                if save_status >= 300:
                    raise DifyImportError(
                        f"Could not {save_action} Dify model credential for {openai_provider}/{model} "
                        f"(HTTP {save_status}): {save_payload}"
                    )

            reread_status, reread_payload = get_model_credential(base_url, admin_key, workspace_id, openai_provider, model)
            if reread_status >= 300:
                raise DifyImportError(
                    f"Could not re-read Dify model credential for {openai_provider}/{model} "
                    f"(HTTP {reread_status}): {reread_payload}"
                )
            credential_id = credential_id_from_payload(reread_payload)
            if credential_id:
                switch_status, switch_payload = switch_model_credential(
                    base_url, admin_key, workspace_id, openai_provider, model, credential_id
                )
                if switch_status >= 300 and not same_credential_error(switch_payload):
                    raise DifyImportError(
                        f"Could not switch active Dify model credential for {openai_provider}/{model} "
                        f"(HTTP {switch_status}): {switch_payload}"
                    )
                add_status, add_payload = add_model_to_provider_list(
                    base_url, admin_key, workspace_id, openai_provider, model, credential_id
                )
                if add_status >= 300 and not same_credential_error(add_payload):
                    raise DifyImportError(
                        f"Could not add Dify model to provider list for {openai_provider}/{model} "
                        f"(HTTP {add_status}): {add_payload}"
                    )
            enable_status, enable_payload = enable_model(base_url, admin_key, workspace_id, openai_provider, model)
            if enable_status >= 300:
                raise DifyImportError(
                    f"Could not enable Dify model for {openai_provider}/{model} "
                    f"(HTTP {enable_status}): {enable_payload}"
                )
        except DifyImportError as exc:
            if required:
                raise
            skipped.append({"provider": openai_provider, "model": model, "reason": str(exc)[:500]})
            continue

        configured.append(
            {
                "provider": openai_provider,
                "model": model,
                "required": required,
                "action": save_action,
                "credential_id_present": bool(credential_id),
                **validation,
            }
        )

    return {
        "status": "configured",
        "provider": openai_provider,
        "provider_setup": provider_setup,
        "route_models_requested": setup_route_models,
        "model_count": len(configured),
        "skipped_model_count": len(skipped),
        "openai_base_url_source": local_base_url_source,
        "openai_api_key_source": local_api_key_source,
        "models": configured,
        "skipped_models": skipped,
    }


def main() -> int:
    args = parse_args()
    yaml_path = Path(args.yaml).expanduser()
    if not yaml_path.is_absolute():
        yaml_path = (Path.cwd() / yaml_path).resolve()
    if not yaml_path.exists():
        raise DifyImportError(f"YAML file not found: {yaml_path}")

    source = load_yaml(yaml_path)
    app_dsl, source_type = prepare_app_dsl(source, args.app_name)
    name = app_name(app_dsl)
    yaml_content = yaml.safe_dump(app_dsl, sort_keys=False, allow_unicode=True)

    admin_key, admin_key_source = resolve_admin_key()
    workspace_id, workspace_source = resolve_workspace_id(args.base_url, admin_key, args.workspace_id)
    apps = list_apps(args.base_url, admin_key, workspace_id)
    existing = None if args.app_id else find_existing_app(apps, name)
    target_app_id = args.app_id or (str(existing.get("id")) if existing else "")
    action = "update" if target_app_id else "create"

    summary: dict[str, Any] = {
        "source_yaml": str(yaml_path),
        "source_type": source_type,
        "dify_base_url": args.base_url,
        "workspace_source": workspace_source,
        "admin_key_source": admin_key_source,
        "app_name": name,
        "action": action,
        "target_app_id": target_app_id or None,
    }

    if args.dry_run:
        route_refs = fortisai_route_models(app_dsl, args.openai_provider) if args.setup_route_models else []
        model_refs = unique_model_refs(workflow_llm_models(app_dsl) + route_refs)
        model_refs = [ref for ref in model_refs if ref["provider"] == args.openai_provider]
        _, local_base_url_source = local_openai_base_url(app_dsl, args.openai_base_url)
        if args.skip_model_setup:
            summary["model_setup"] = {"status": "skipped-by-flag"}
        else:
            summary["model_setup"] = {
                "status": "planned",
                "provider": args.openai_provider,
                "model_count": len(model_refs),
                "route_models_requested": args.setup_route_models,
                "openai_base_url_source": local_base_url_source,
                "plugins": marketplace_dependencies(app_dsl),
                "models": [{"provider": ref["provider"], "model": ref["model"]} for ref in model_refs],
            }
        summary["dry_run"] = True
        print(json.dumps(summary, indent=2))
        return 0

    import_status, import_result = import_app(args.base_url, admin_key, workspace_id, yaml_content, target_app_id)
    summary["import_http"] = import_status
    summary["import_status"] = import_result.get("status")
    if import_status >= 300:
        summary["error"] = import_result.get("error") or import_result.get("message") or import_result
        print(json.dumps(summary, indent=2))
        return 1

    if import_result.get("status") == "pending":
        confirm_status, confirm_result = confirm_import(args.base_url, admin_key, workspace_id, str(import_result["id"]))
        summary["confirm_http"] = confirm_status
        summary["confirm_status"] = confirm_result.get("status")
        if confirm_status >= 300:
            summary["error"] = confirm_result.get("error") or confirm_result.get("message") or confirm_result
            print(json.dumps(summary, indent=2))
            return 1
        import_result = confirm_result

    app_id = str(import_result.get("app_id") or target_app_id or "")
    app_mode = str(import_result.get("app_mode") or (app_dsl.get("app") or {}).get("mode") or "")
    summary["app_id"] = app_id or None
    summary["app_mode"] = app_mode

    if not app_id:
        summary["error"] = "Dify import did not return an app_id"
        print(json.dumps(summary, indent=2))
        return 1

    if args.skip_model_setup:
        summary["model_setup"] = "skipped"
    else:
        summary["model_setup"] = setup_model_connections(
            args.base_url,
            admin_key,
            workspace_id,
            app_dsl,
            args.openai_provider,
            args.openai_base_url,
            args.setup_route_models,
        )

    if args.skip_publish:
        summary["publish"] = "skipped"
    elif app_mode in {"advanced-chat", "workflow"}:
        publish_status, publish_result = publish_app(
            args.base_url,
            admin_key,
            workspace_id,
            app_id,
            args.marked_name,
            f"{args.marked_comment}; {yaml_path.name}; {int(time.time())}",
        )
        summary["publish_http"] = publish_status
        summary["publish_result"] = publish_result.get("result")
        if publish_status >= 300 or publish_result.get("result") != "success":
            summary["error"] = publish_result.get("message") or publish_result.get("error") or publish_result
            print(json.dumps(summary, indent=2))
            return 1
    else:
        summary["publish"] = f"not-required-for-mode:{app_mode}"

    print(json.dumps(summary, indent=2))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except DifyImportError as exc:
        print(json.dumps({"error": str(exc)}, indent=2), file=sys.stderr)
        raise SystemExit(1)
