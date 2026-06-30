#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER="$SCRIPT_DIR/fortisai-dev-helper.sh"
CONTAINER_NAME="${LLAMA_SERVER_CONTAINER_NAME:-fortisai-llama-server}"
LLAMA_URL="${LLAMA_SERVER_URL:-http://127.0.0.1:8011}"
PROMPT="${LLAMA_TEST_PROMPT:-Reply with a short sentence about this model and include the model name.}"
DELETE_FAILED="${LLAMA_DELETE_FAILED:-false}"

fetch_models() {
  curl --max-time 10 -fsS "$LLAMA_URL/v1/models" | python3 -c 'import json, sys; payload = json.load(sys.stdin); print("\n".join(entry["id"] for entry in payload.get("data", []) if entry.get("id")))'
}

invoke_model() {
  local model_id="$1"
  python3 -c 'import json, sys; from urllib import request; base_url, model_id, prompt = sys.argv[1:4]; payload = {"model": model_id, "messages": [{"role": "user", "content": prompt}], "max_tokens": 64, "temperature": 0}; body = json.dumps(payload).encode("utf-8"); req = request.Request(f"{base_url}/v1/chat/completions", data=body, headers={"Content-Type": "application/json"}, method="POST"); response = request.urlopen(req, timeout=120); result = json.load(response); choices = result.get("choices") or []; content = ""; 
if choices:
    content = (choices[0].get("message") or {}).get("content") or "";
print(content.strip())' "$LLAMA_URL" "$model_id" "$PROMPT"; return $?
}

validate_gpu() {
  local gpu_devices
  gpu_devices="$(podman inspect "$CONTAINER_NAME" --format '{{range .HostConfig.Devices}}{{.PathOnHost}}{{"\n"}}{{end}}' 2>/dev/null || true)"
  if [[ -z "$gpu_devices" ]]; then
    echo "ERROR: llama-server container is not configured with GPU device mappings"
    exit 1
  fi

  if ! printf '%s\n' "$gpu_devices" | grep -q '^/dev/nvidia'; then
    echo "ERROR: llama-server container does not expose NVIDIA device nodes"
    exit 1
  fi

  echo "GPU device nodes mapped into $CONTAINER_NAME"
}

if ! curl --max-time 5 -fsS "$LLAMA_URL/v1/models" >/dev/null 2>&1; then
  echo "Starting llama-router with the helper..."
  "$HELPER" llama-router-up
fi

models="$(fetch_models)"
if [[ -z "$models" ]]; then
  echo "ERROR: llama-server returned no models"
  exit 1
fi

#validate_gpu

failures=0
while IFS= read -r model_id; do
  [[ -n "$model_id" ]] || continue
  echo "=== $model_id ==="
  if ! output="$(invoke_model "$model_id")"; then
    if [[ "$DELETE_FAILED" == "true" ]]; then
      echo "Removing failed model $model_id from server..."
      curl -s -X DELETE "http://127.0.0.1:8011/v1/models/$model_id" 2>/dev/null || true
    fi
    echo "ERROR: model invocation failed for $model_id"
    failures=1
    continue
  fi
  if [[ -z "$output" ]]; then
    if [[ "$DELETE_FAILED" == "true" ]]; then
      echo "Removing failed model $model_id from server..."
      curl -s -X DELETE "http://127.0.0.1:8011/v1/models/$model_id" 2>/dev/null || true
    fi
    echo "ERROR: empty response for $model_id"
    failures=1
    continue
  fi
  printf '%s\n' "$output"
  echo
done <<< "$models"

exit "$failures"
