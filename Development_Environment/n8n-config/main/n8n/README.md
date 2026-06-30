# FortisAI n8n Workflows

This directory contains executable n8n workflow artifacts for FortisAI.

## Layout

- `configurations/`: source-controlled workflow JSON files.
- `scripts/`: helper scripts executed by workflows.
- `templates/`: reusable workflow scaffolds.
- `generated/`: runtime reports written by scheduled jobs.

## Monthly Local LLM Router Classification

`configurations/weekly-local-llm-router-classification.json` runs on day 1 of every month at 6:00 PM Eastern and executes `scripts/classify-local-llm-router.mjs` inside the n8n container.

The script pulls local models from an OpenAI-compatible `/v1/models` endpoint, reads public LLMDB model data, filters aliases listed in `LLAMA_DISABLED_MODELS_FILE` or `llm_directory/disabled_models.json`, excludes non-first split GGUF shards, asks the local Mistral classifier model to review route labels and tool-use capability, and writes Dify artifacts under `/FortisAI/Development_Environment/dify-config`.

The stable output at `/FortisAI/Development_Environment/dify-config/main/dify/configurations/local-openai-compatible-router.yaml` is native Dify app DSL with a `start -> llm -> answer` workflow graph. The raw FortisAI routing document is retained at `/FortisAI/Development_Environment/dify-config/main/dify/generated/local-openai-compatible-router.reference.yaml`.

The generated app includes the Dify OpenAI-compatible marketplace dependency and points the workflow LLM node at `langgenius/openai_api_compatible/openai_api_compatible`.

The classifier also writes generated workflow-runner wrappers under `/FortisAI/Development_Environment/dify-config/main/dify/generated`:

- `setup-openai-compatible-models.mjs`
- `import-local-openai-compatible-router.mjs`

The monthly workflow runs these wrappers after classification. Model setup runs first so active generated route models are configured for the router and stale FortisAI-managed OpenAI-compatible Dify model rows are pruned, then app import updates and publishes `local-openai-compatible-router`. The generated classification marks the `agentic_tool_use` route as tool-use capable and force-loads the selected model when requests include OpenAI tools, function calls, or tool-choice metadata. Run Linux model validation first; it restores existing disabled GGUF files by default, retests them, and disables models that cannot answer within the default 300-second validation SLA before route generation. Split GGUF sets are validated and routed through shard `00001` only while later shards remain enabled on disk as support files.

On Linux, the helper mounts this repo into n8n at `/FortisAI/Development_Environment/n8n-config` and `/FortisAI/Development_Environment/dify-config` and prepares the mount permissions so scheduled jobs can write generated artifacts.


## Runner Sidecar

The monthly router workflow uses built-in HTTP Request nodes to call the runner sidecar. The helper deploys this runner sidecar with the n8n compose stack. The runner uses the n8n image with `/usr/local/bin/node` as its entrypoint, executes repository scripts from the mounted `/FortisAI` paths, and keeps the HTTP response open while long local model and Dify setup work runs.

Runner endpoints:

- `http://fortisai-n8n-workflow-runner.fortisai.local:5680/run/local-llm-router-classification`
- `http://fortisai-n8n-workflow-runner.fortisai.local:5680/run/dify-openai-compatible-model-setup`
- `http://fortisai-n8n-workflow-runner.fortisai.local:5680/run/dify-local-openai-compatible-router-import`

On Linux, run `./fortisai-dev-helper.sh n8n-import-workflows` from `Development_Environment/linux` after editing workflow JSON. This regenerates the compose file, starts both `fortisai-n8n` and `fortisai-n8n-workflow-runner`, imports workflows, and activates source-controlled workflows marked `active: true`.
