#!/usr/bin/env bash
set -euo pipefail

OPENWEBUI_URL="${OPENWEBUI_URL:-http://localhost:3000}"
OPENWEBUI_BEARER_TOKEN="${OPENWEBUI_BEARER_TOKEN:-}"
OPENCLAW_BASE_URL="${OPENCLAW_BASE_URL:-}"
TOOL_ID="${TOOL_ID:-fortisai_openclaw_chat_tool}"
TOOL_NAME="${TOOL_NAME:-FortisAI OpenClaw Chat Tool}"
TOOL_DESCRIPTION="${TOOL_DESCRIPTION:-Send chat prompts from OpenWebUI to OpenClaw.}"

if [[ -z "$OPENCLAW_BASE_URL" ]]; then
  if command -v podman >/dev/null 2>&1 && \
    [[ "$(podman inspect fortisai-coredns --format '{{.State.Running}}' 2>/dev/null || true)" == "true" ]]; then
    OPENCLAW_BASE_URL="http://fortisai-claw-gateway.fortisai.local:18789/v1"
  else
    OPENCLAW_BASE_URL="http://fortisai-claw-gateway:18789/v1"
  fi
fi

if [[ -z "$OPENWEBUI_BEARER_TOKEN" ]]; then
  echo "ERROR: OPENWEBUI_BEARER_TOKEN is not set."
  echo "Set it first, for example:"
  echo "  export OPENWEBUI_BEARER_TOKEN='<token>'"
  exit 1
fi

read -r -d '' TOOL_CONTENT <<'PYTOOL' || true
"""
title: OpenClaw Chat Tool
author: FortisAI
version: 1.0.0
description: Query OpenClaw from OpenWebUI custom tools.
"""

from pydantic import BaseModel, Field
import requests


class Tools:
  class Valves(BaseModel):
    openclaw_base_url: str = Field(
      default="__OPENCLAW_BASE_URL__",
      description="OpenClaw OpenAI-compatible base URL",
    )
    openclaw_api_key: str = Field(
      default="fortisai-claw-gateway-dev-token",
      description="OpenClaw gateway API key",
    )
    openclaw_model: str = Field(
      default="default",
      description="OpenClaw model name",
    )

  def __init__(self):
    self.valves = self.Valves()

  def ask_openclaw(self, prompt: str) -> str:
    """Send a prompt to OpenClaw and return the response text."""
    headers = {
      "Authorization": f"Bearer {self.valves.openclaw_api_key}",
      "Content-Type": "application/json",
    }
    payload = {
      "model": self.valves.openclaw_model,
      "messages": [{"role": "user", "content": prompt}],
      "temperature": 0.2,
    }

    response = requests.post(
      f"{self.valves.openclaw_base_url}/chat/completions",
      headers=headers,
      json=payload,
      timeout=60,
    )
    response.raise_for_status()
    data = response.json()
    return data["choices"][0]["message"]["content"]
PYTOOL

TOOL_CONTENT="${TOOL_CONTENT//__OPENCLAW_BASE_URL__/$OPENCLAW_BASE_URL}"

OPENWEBUI_URL="$OPENWEBUI_URL" \
OPENWEBUI_BEARER_TOKEN="$OPENWEBUI_BEARER_TOKEN" \
TOOL_ID="$TOOL_ID" \
TOOL_NAME="$TOOL_NAME" \
TOOL_DESCRIPTION="$TOOL_DESCRIPTION" \
TOOL_CONTENT="$TOOL_CONTENT" \
python3 - <<'PY'
import json
import os
import urllib.error
import urllib.request

base_url = os.environ["OPENWEBUI_URL"].rstrip("/")
token = os.environ["OPENWEBUI_BEARER_TOKEN"]
payload = {
    "id": os.environ["TOOL_ID"],
    "name": os.environ["TOOL_NAME"],
    "description": os.environ["TOOL_DESCRIPTION"],
    "meta": {},
    "content": os.environ["TOOL_CONTENT"],
}

req = urllib.request.Request(
    f"{base_url}/api/v1/tools/create",
    data=json.dumps(payload).encode("utf-8"),
    headers={
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    },
    method="POST",
)

try:
    with urllib.request.urlopen(req, timeout=30) as resp:
        body = resp.read().decode("utf-8", "replace")
        print(f"create_http_code={resp.status}")
        print(body)
except urllib.error.HTTPError as exc:
    body = exc.read().decode("utf-8", "replace")
    print(f"create_http_code={exc.code}")
    print(body)
    if exc.code == 400:
        print("hint=Tool may already exist or payload shape may need adjustment for this OpenWebUI version.")
    raise SystemExit(1)
PY
