"""
title: FortisAI Dify MCP Skill
author: FortisAI
version: 1.0.0
description: Dify-only OpenWebUI helper skill for planning and validating Dify app changes.
required_open_webui_version: 0.5.0
"""

from typing import Dict, List
from pydantic import BaseModel, Field


class Tools:
    class Valves(BaseModel):
        environment: str = Field(
            default="local",
            description="Environment label for generated Dify change plans",
        )
        max_steps: int = Field(default=8, description="Maximum plan steps to return")

    def __init__(self):
        self.valves = self.Valves()

    def validate_dify_scope(self, request_text: str) -> Dict[str, object]:
        """Classify if a request is Dify-only and list out-of-scope signals."""
        text = (request_text or "").lower()
        out_of_scope_markers = [
            "terraform",
            "kubernetes",
            "sql",
            "database",
            "podman",
            "oracle",
        ]
        found = [marker for marker in out_of_scope_markers if marker in text]
        return {
            "is_dify_only": len(found) == 0,
            "out_of_scope_markers": found,
            "recommended_focus": "dify app, prompt, dataset, and workflow configuration",
        }

    def build_dify_change_plan(self, objective: str, app_name: str = "") -> Dict[str, object]:
        """Create a concise Dify-focused implementation plan."""
        target = app_name.strip() or "target Dify app"
        steps: List[str] = [
            f"Confirm objective and acceptance criteria for {target}",
            "Select endpoint family intentionally: /v1/* for runtime, /console/api/* for console/admin",
            "Use /dify_api_request authMode=auto unless an explicit auth override is required",
            "Identify affected Dify components (app config, prompts, datasets, workflow nodes)",
            "Apply smallest possible configuration/prompt updates",
            "Run Dify test conversations for happy path and one failure path",
            "Document changes and rollback approach",
        ]
        return {
            "environment": self.valves.environment,
            "objective": objective,
            "app_name": target,
            "steps": steps[: self.valves.max_steps],
        }

    def draft_dify_prompt_revision(
        self,
        current_prompt: str,
        improvement_goal: str,
        constraints: str = "",
    ) -> Dict[str, str]:
        """Generate a revised Dify prompt draft with explicit constraints."""
        constraint_text = constraints.strip() or "Keep response concise, accurate, and safe."
        revised = (
            "System instructions:\n"
            f"Goal: {improvement_goal.strip()}\n"
            f"Constraints: {constraint_text}\n\n"
            "Existing baseline to preserve important behavior:\n"
            f"{current_prompt.strip()}\n\n"
            "Required behavior updates:\n"
            "1. Ask clarifying questions only when essential.\n"
            "2. Prefer deterministic outputs over broad speculation.\n"
            "3. Return structured results with short rationale."
        )
        return {"improvement_goal": improvement_goal, "revised_prompt": revised}

    def summarize_dify_release_checklist(self, app_name: str, release_scope: str) -> Dict[str, object]:
        """Provide a release checklist template for Dify-only changes."""
        checklist = [
            "Validate prompt and workflow logic changes in staging",
            "Verify dataset references and retrieval settings",
            "Run regression chat tests for critical intents",
            "Confirm no secrets are embedded in prompts or variables",
            "Record release notes and rollback instructions",
        ]
        return {
            "app_name": app_name,
            "release_scope": release_scope,
            "checklist": checklist,
        }

    def get_dify_runtime_endpoints(self) -> Dict[str, object]:
        """Return supported Dify runtime and console endpoints for bridge usage."""
        return {
            "runtime_endpoints": {
                "get_parameters": "GET /v1/parameters",
                "get_meta": "GET /v1/meta",
                "chat_messages": "POST /v1/chat-messages",
                "completion_messages": "POST /v1/completion-messages",
                "run_workflow": "POST /v1/workflows/run",
            },
            "console_endpoints": {
                "list_apps": "GET /console/api/apps",
                "list_workspaces": "GET /console/api/workspaces",
                "admin_explore_apps": "GET /console/api/admin/insert-explore-apps",
            },
            "auth_mode_guidance": {
                "recommended": "auto",
                "auto_behavior": {
                    "/v1/*": "app auth",
                    "/console/api/*": "admin auth",
                },
            },
            "do_not_use": [
                "Legacy non-console /api/* paths for Dify console operations",
            ],
        }

    def build_dify_api_request_template(
        self,
        path: str,
        method: str = "GET",
        auth_mode: str = "auto",
    ) -> Dict[str, object]:
        """Return a ready-to-send body template for /dify_api_request."""
        normalized = self.normalize_dify_runtime_path(path)
        return {
            "method": method.upper(),
            "path": normalized.get("normalized", path),
            "authMode": auth_mode,
            "requireApiKey": True,
            "query": None,
            "body": None,
        }

    def normalize_dify_runtime_path(self, path: str) -> Dict[str, str]:
        """Normalize common legacy paths to Dify runtime or console endpoint paths."""
        raw = (path or "").strip()
        if not raw:
            return {"input": raw, "normalized": "", "reason": "empty path"}

        if not raw.startswith("/"):
            raw = f"/{raw}"

        aliases = {
            "/info": "/v1/parameters",
            "/v1/info": "/v1/parameters",
            "/chat": "/v1/chat-messages",
            "/v1/chat": "/v1/chat-messages",
            "/apps": "/console/api/apps",
            "/api/apps": "/console/api/apps",
            "/workspaces": "/console/api/workspaces",
        }

        normalized = aliases.get(raw, raw)
        if normalized.startswith("/") and not normalized.startswith("/v1/"):
            segment = normalized.split("/", 2)[1] if len(normalized.split("/")) > 1 else ""
            if segment in {
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
                normalized = f"/v1{normalized}"

        return {
            "input": path,
            "normalized": normalized,
            "reason": "runtime/console endpoint normalization",
        }
