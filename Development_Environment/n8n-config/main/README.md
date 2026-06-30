# n8n OCI-GitHub Best Practice Structure

# This README describes the recommended structure for n8n workflow configuration management in OCI-GitHub pipelines.

## Directory Layout

- n8n-config/
  - main/
    - n8n/
      - configurations/
        - <workflow1>.json
        - <workflow2>.json
        - ...
      - templates/
        - workflow-template.json

## Guidelines

- Each workflow should have its own JSON file in the configurations/ directory (e.g., sync-crm.json, data-pipeline.json).
- Each JSON file should define a single n8n workflow.
- Avoid bundling multiple workflows in a single file.
- Use clear, descriptive filenames for each workflow.
- Store shared resources (if any) in a separate directory (e.g., shared/).
- Use a main branch for production-ready configs; use feature branches for development/testing.
- Protect the main branch with required reviews and CI checks.

## Example

```
n8n-config/
  main/
    n8n/
      configurations/
        sync-crm.json
        data-pipeline.json
        alerting.json
```

## Import Automation

## Monthly Local LLM Router Classification

- Workflow file: `n8n/configurations/weekly-local-llm-router-classification.json`
- Script file: `n8n/scripts/classify-local-llm-router.mjs`
- Schedule: day 1 of every month at 6:00 PM Eastern (`America/New_York`)
- Purpose: pull local OpenAI-compatible models, combine them with LLMDB model data, ask the local classifier model `mistral__mistralai_Mistral-Small-3.2-24B-Instruct-2506-Q8_0` to classify them, and write native Dify app YAML plus router reference data under `dify-config`.
- Runtime mount: helper-generated n8n compose exposes `/FortisAI/Development_Environment/n8n-config` and `/FortisAI/Development_Environment/dify-config` inside the container.
- Classifier transport: streaming OpenAI-compatible chat completions are used so slow local model generation does not hit Node fetch header timeouts.
- Output format: the agent returns compact row-indexed JSON; the script expands it to full model IDs before writing the Dify app YAML, router reference YAML, and classification JSON. If the agent response is malformed, generation continues with deterministic LLMDB/name/quantization heuristics and records the error in the generated classification JSON and last-run report.
- Generated follow-up scripts: the classifier also writes `dify/generated/setup-openai-compatible-models.mjs` and `dify/generated/import-local-openai-compatible-router.mjs`.
- Production order: the workflow first runs classification/generation, then runs the generated Dify OpenAI-compatible model setup for all runnable local models, then imports and publishes the generated `local-openai-compatible-router` app.
- Dify import contract: the generated app declares the OpenAI-compatible marketplace dependency and uses the installed provider id `langgenius/openai_api_compatible/openai_api_compatible`.
- Precondition: run the Linux monthly model update and validation sequence first (`model_update.py run-once`, then `test_llama_models.py`). Validation quarantines corrupted, incomplete, support-only, unsupported Bitnet, and high-precision BF16/FP16 GGUF files with a `.disable...` suffix and restarts `fortisai-llama-server`, so this workflow reads only loadable `/v1/models` entries.

- The import pipeline should iterate over all JSON files in configurations/ and process each workflow individually.
- The pipeline should use CI/CD upsert behavior: update existing workflows (match by ID first, then name), create when missing, and explicitly enforce active state.
- Optional prune mode may delete workflows not defined in source control when explicitly enabled for controlled environments.
- Keep template files in templates/ so they are not imported as real workflows.

## Template Usage

1. Copy n8n/templates/workflow-template.json to n8n/configurations/<your-workflow>.json.
2. Replace WORKFLOW_NAME_PLACEHOLDER and WORKFLOW_ID_PLACEHOLDER.
3. Commit and push via pull request.

## Versioning
- Use GitHub PRs for changes.
- Tag releases for major config updates.

---
This structure ensures modular, maintainable, and automatable n8n workflow management for OCI-GitHub workflows.
