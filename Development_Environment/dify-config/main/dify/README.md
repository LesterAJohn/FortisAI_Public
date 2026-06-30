# FortisAI Dify Artifacts

This directory contains Dify-facing source and generated configuration.

## Layout

- `configurations/`: stable importable Dify YAML configuration.
- `generated/`: latest generated Dify app copy, router reference, classification data, and workflow-runner script wrappers from n8n.
- `templates/`: reusable Dify app scaffolds.

## Local Router

`configurations/local-openai-compatible-router.yaml` is native Dify app DSL generated from the scheduled n8n classifier workflow. It uses a standard `start -> llm -> answer` graph so the Dify GUI can render the workflow editor. The router is an advanced-chat app and relies on Dify's built-in `sys.query`; it should not define legacy custom start variables using `id`/`name` fields.

The generated classification JSON records every available local model, its inferred provider/family/quantization hints, LLMDB reference, route labels, quality tier, routing weight, and embedding suitability. It includes an `embeddings` request type that the Dify OpenAPI bridge uses for `/v1/embeddings` whenever clients request the public `fortisai` model and no explicit embedding override is set. `generated/local-openai-compatible-router.reference.yaml` retains the raw FortisAI routing policy for downstream automation, audit, and troubleshooting.

The published app is also fronted by the helper-managed Dify OpenAPI bridge as an OpenAI-compatible router named `fortisai`. After `mcp-up`, use `http://127.0.0.1:8093/v1` from the Linux host or `http://fortisai-mcp-openapi-dify.fortisai.local:8093/v1` from containers on the FortisAI network. Send chat or completion requests with `"model": "fortisai"`; the bridge uses `generated/local-llm-classification.generated.json` to select the supporting local model and proxies the request to `fortisai-llama-server`.

Supported facade endpoints:

- `GET /v1/models`
- `GET /v1/models/fortisai`
- `POST /v1/chat/completions`
- `POST /v1/completions`
- `POST /v1/embeddings`
- `POST /v1/responses`

The facade preserves normal OpenAI-compatible request options and rewrites non-streaming responses so the public model remains `fortisai` while adding route metadata under `fortisai`. The bridge always forwards to the classified preferred model and waits for that model to load when cold; helper startup sets a 600-second router timeout and disables already-loaded model substitution. Responses API requests are adapted to chat completions and returned with `output_text`; embeddings are proxied to the helper-managed llama server, which Linux starts with `--embeddings --pooling mean`.

Routing uses exact generated hint words and phrases to avoid false positives from substrings. Use `POST /fortisai_router_preview` on the bridge to inspect a route decision without running a completion.

## Importing

Run the importer from the repository root to create or update the Dify app from the stable router YAML:

```bash
cd /opt/home/aiuser/FortisAI
./Development_Environment/dify-config/import-dify-app.py
```

The importer sends the native Dify app YAML through the Dify console API, confirms pending imports, and publishes the workflow so the app is active. Repeated runs update the existing app by exact name or by `--app-id`, which prevents duplicate apps when the YAML changes.

The importer installs declared marketplace dependencies before publish. For the local router this is the Dify OpenAI-compatible provider `langgenius/openai_api_compatible/openai_api_compatible`. It then configures the workflow-required classifier model connection against the local `/v1` endpoint and reuses an existing Dify credential when present so reruns do not block on slow model validation.

Use `./Development_Environment/dify-config/import-dify-app.py --dry-run` to verify the selected YAML, Dify endpoint, workspace, and create/update target before applying changes.

Use `--setup-route-models` only when you want to configure every generated route model in Dify. That path can take noticeably longer because Dify validates each local model credential.

## Production Model Setup

The monthly n8n workflow now runs generated wrappers after classification:

- `generated/setup-openai-compatible-models.mjs`
- `generated/import-local-openai-compatible-router.mjs`

The setup wrapper calls `/FortisAI/Development_Environment/dify-config/setup-openai-compatible-models.mjs`, which configures every runnable generated local model for the OpenAI-compatible provider before app import. It prefers the Dify OpenAPI bridge fast setup endpoint `/dify_openai_compatible_model_setup`; that endpoint reuses one existing validated credential template and upserts the Dify model rows for all generated router models.

The import wrapper calls `/FortisAI/Development_Environment/dify-config/import-local-openai-compatible-router.mjs`, which updates the existing `local-openai-compatible-router` app, confirms the import, and publishes the workflow.

The import wrapper also normalizes the generated YAML before import to remove stale start-node variable blocks that Dify Studio cannot render safely.
