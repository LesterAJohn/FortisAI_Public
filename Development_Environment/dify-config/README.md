# FortisAI Dify Config

This directory stores source-controlled Dify configuration artifacts.

## Local OpenAI-Compatible Router

The scheduled n8n workflow generates:

- `main/dify/configurations/local-openai-compatible-router.yaml`
- `main/dify/generated/local-openai-compatible-router.generated.yaml`
- `main/dify/generated/local-openai-compatible-router.reference.yaml`
- `main/dify/generated/local-llm-classification.generated.json`
- `main/dify/generated/setup-openai-compatible-models.mjs`
- `main/dify/generated/import-local-openai-compatible-router.mjs`

The stable YAML in `configurations/` is native Dify app DSL (`kind: app`) and uses a standard `start -> llm -> answer` graph so the Dify GUI can render the workflow editor. The advanced-chat router uses Dify's built-in `sys.query` input and does not define a custom start-node input variable; stale `id`/`name` style start variables can break Dify Studio in current Dify builds. The generated reference YAML keeps the raw FortisAI routing policy for audit and troubleshooting.

The generated app uses the primary local OpenAI-compatible endpoint exposed to Dify/n8n:

- Linux: `http://fortisai-llama-server.fortisai.local:8011/v1`
- Mac/Windows default: `http://host.docker.internal:8011/v1`, overrideable through `FORTISAI_LLAMA_OPENAI_BASE_URL`

On Linux, the secondary endpoint `http://fortisai-llama-server-secondary.fortisai.local:8012/v1` is reserved for support tools that need direct LLM access. The FortisAI proxy and generated Dify router stay on the primary endpoint.

It maps request types such as coding, reasoning, summarization, classification, long-context analysis, fast chat, multimodal/vision-adjacent work, and safety guardrail review to the best available local models.

The helper-managed Dify OpenAPI bridge also exposes the router as an OpenAI-compatible facade:

- Base URL inside the Linux development network: `http://fortisai-mcp-openapi-dify.fortisai.local:8093/v1`
- Local host URL after `mcp-up`: `http://127.0.0.1:8093/v1`
- Model name: `fortisai`
- Supported endpoints: `GET /v1/models`, `GET /v1/models/fortisai`, `POST /v1/chat/completions`, `POST /v1/completions`, `POST /v1/embeddings`, and `POST /v1/responses`

Clients should send OpenAI-compatible requests with `"model": "fortisai"`. The bridge reads `main/dify/generated/local-llm-classification.generated.json`, selects the best supporting local LLM for the request, forwards all standard request attributes such as `temperature`, `max_tokens`, `max_output_tokens`, `top_p`, `tools`, `response_format`, and `stream`, then returns an OpenAI-shaped response with the public model set back to `fortisai`. If the client omits an output cap, helper startup applies `FORTISAI_OPENAI_ROUTER_DEFAULT_MAX_TOKENS=1536`; explicit client caps are preserved. Set it to `0` only when intentionally allowing responses to run until the model, client, or bridge timeout stops them. Chat requests are normalized before forwarding: flat or legacy function-tool definitions are converted into the nested OpenAI `{"type":"function","function":{...}}` schema required by llama.cpp, and all `system` and `developer` messages are merged into one leading `system` message so strict llama.cpp Jinja templates do not reject system messages inserted after user/assistant history. Non-streaming responses include a `fortisai` metadata object showing the route, supporting model, Honcho memory status, retrieval status, and `timings_ms` for Honcho, RAG, classification, model status, and upstream LLM generation. The bridge always forwards to the classified preferred model; it no longer substitutes an already-loaded local model when the preferred model is cold. Helper startup sets `FORTISAI_OPENAI_ROUTER_TIMEOUT_SECONDS=1800` and `FORTISAI_OPENAI_ROUTER_PREFER_LOADED_MODELS=false` so cold preferred-model loads and long local completions have time to complete.

FortisAI chat/completion retrieval order is Honcho personal memory, Qdrant general-knowledge vector retrieval, Firecrawl web search, then the selected LLM. Firecrawl search is attempted on every request; returned web results are passed into context immediately and queued for background Qdrant upsert by default using `FORTISAI_RAG_BACKGROUND_WEB_UPSERT=true`. The default RAG collection base is `fortisai_general_knowledge`, with an embedding-dimension suffix added automatically. The default RAG embedding endpoint is the secondary llama-server at `http://fortisai-llama-server-secondary.fortisai.local:8012/v1`.

For streaming clients such as Cline, the bridge sends SSE comment keepalives while waiting for a cold model load or slow first token. Synthetic OpenAI stream chunks include `id`, `object`, `created`, and `model`; keepalives stay outside the JSON event stream so clients do not interpret them as empty assistant content. Streamed upstream chunks are normalized back to the public `fortisai` model name and null content deltas are converted to empty strings. If the upstream stream closes without a final OpenAI `data: [DONE]` marker, the bridge emits one before closing the client stream. The default keepalive interval is `FORTISAI_OPENAI_ROUTER_STREAM_KEEPALIVE_SECONDS=10`.

Cline-style prompts and OpenAI tool definitions that reference `execute_command` receive a guard instruction requiring `requires_approval`; forwarded `execute_command` tool schemas are patched so the field is required with a default of `true`. If a routed model still omits the field, the bridge repairs returned XML tool blocks and OpenAI `tool_calls` to include approval-required behavior so Cline asks before executing the command. The streaming repair also handles fragmented XML opening tags such as `<execute` followed by `_command>`. Guarded Cline tool requests do not use a Cline-specific model default; they follow the generated FortisAI/Dify `agentic_tool_use` route recommendation. Set `FORTISAI_OPENAI_ROUTER_DEFAULT_MAX_TOKENS=0` only for intentionally uncapped proxy behavior. The Cline guard is enabled by default, but `FORTISAI_CLINE_TOOL_MAX_TOKENS=0` prevents guarded requests from shrinking below the shared proxy default; set it above `0` only when a smaller Cline-specific planning cap is required.

Cline tool requests still perform Honcho and RAG lookup, but the query and injected context are capped with `FORTISAI_CLINE_RETRIEVAL_QUERY_CHARS=1200` and `FORTISAI_CLINE_CONTEXT_LIMIT_CHARS=1600` by default. This prevents large workspace/tool prompts from being expanded with oversized memory and Firecrawl context before reaching the local model. Non-Cline FortisAI requests keep the standard Honcho/RAG limits.

`POST /v1/responses` adapts OpenAI Responses API requests to the local chat-completions backend and returns a Responses-shaped object with `output_text`. `POST /v1/embeddings` proxies to the helper-managed llama server, which Linux now starts with `--embeddings --pooling mean` by default.

Route matching uses exact generated hint words and phrases instead of raw substring matching. This prevents `script` from matching `transcript` and `api` from matching `capital`. Use `POST /fortisai_router_preview` to inspect the selected route without sending the request to a model.

The generated setup and import scripts are small wrappers used by the n8n workflow runner. They call the stable repository scripts:

- `setup-openai-compatible-models.mjs`: configures every runnable generated local model in Dify's OpenAI-compatible provider before the router app is imported.
- `import-local-openai-compatible-router.mjs`: imports and publishes the generated router app without creating duplicate apps.

The model setup script uses the Dify OpenAPI bridge endpoint `/dify_openai_compatible_model_setup` when available. That bridge path reuses an existing validated encrypted OpenAI-compatible credential template and writes the model rows directly through Dify's database connection, which avoids slow per-model validation after one credential has already been proven. If the template is missing, the script creates one validated credential through Dify's admin API first, then reruns the fast setup.

The router import script normalizes the generated YAML before import so older start-node variable shapes are removed before Dify stores the draft workflow.

## Import Dify App

Use `import-dify-app.py` from the repository root to manually import and activate the local router app:

```bash
cd /opt/home/aiuser/FortisAI
./Development_Environment/dify-config/import-dify-app.py
```

By default the importer reads `main/dify/configurations/local-openai-compatible-router.yaml`. Native Dify DSL files with `kind: app` are imported directly. Legacy FortisAI router files with `kind: fortisai.dify.openai-compatible-router.v1` are still compiled into an importable Dify `advanced-chat` app before import.

The importer resolves the Dify admin API key from environment variables, Vault, Dify `.env`, or the local compatibility JSON. It resolves the workspace from environment variables, Vault, or the Dify admin workspace API. Secret values are not printed.

The import is safe to rerun. The script checks for an existing app by exact app name and passes that app ID back to Dify so changed YAML updates the existing app instead of creating a duplicate. If multiple apps share the same name, pass `--app-id` to select the intended app explicitly.

Before publishing, the importer installs any Dify marketplace dependencies declared by the app YAML and configures the OpenAI-compatible model connection required by the workflow LLM node. The default model setup only touches workflow-required models so reruns stay fast and avoid repeatedly validating every route candidate. Use `--setup-route-models` when you intentionally want to attempt Dify credentials for every generated route model.

For the production n8n path, the generated `setup-openai-compatible-models.mjs` script runs before app import so every runnable generated router model is available to Dify. The importer is still useful for manual repair or one-off app updates.

The Dify OpenAPI bridge also exposes the admin console API through `/dify_api_request` with `authMode: admin`. After `mcp-up`, a read-only provider check should return HTTP 200 and include the OpenAI-compatible provider:

```bash
curl -sS -X POST http://127.0.0.1:8093/dify_api_request \
  -H 'Content-Type: application/json' \
  -d '{"method":"GET","path":"/console/api/workspaces/current/model-providers","query":{"model_type":"llm"},"authMode":"admin"}'
```

Common options:

- `--yaml PATH`: import a different YAML file.
- `--app-id ID`: update a specific existing app.
- `--app-name NAME`: override the app name used during import.
- `--dry-run`: validate inputs and show the planned create/update action.
- `--skip-model-setup`: import and publish without changing Dify model provider credentials.
- `--setup-route-models`: also configure the generated route models, not just the workflow LLM model.
- `--skip-publish`: import without publishing the workflow.

## Generated Classification Data

`main/dify/generated/local-llm-classification.generated.json` records the source model list, LLMDB-assisted model classifications, generated routes, and the classifier source. A successful agent run records `classification_source=classifier_agent`; if the classifier is unavailable, the script records `heuristic_fallback` and includes the classifier error in the n8n last-run report.

`main/dify/configurations/local-openai-compatible-router.yaml` is the stable Dify app file for import. `main/dify/generated/local-openai-compatible-router.generated.yaml` is kept as the generated app copy from the most recent run. `main/dify/generated/local-openai-compatible-router.reference.yaml` is the raw FortisAI router document for downstream routing automation or comparison.

The generated script wrappers are committed so the workflow can run without writing new executable code at startup. They are regenerated by `Development_Environment/n8n-config/main/n8n/scripts/classify-local-llm-router.mjs` whenever the classifier updates router artifacts.
