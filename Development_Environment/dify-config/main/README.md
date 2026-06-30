# Dify OCI-GitHub Best Practice Structure

# This README describes the recommended structure for Dify configuration management in OCI-GitHub pipelines.

## Directory Layout

- dify-config/
  - main/
    - dify/
      - configurations/
        - <app1>.yaml
        - <app2>.yaml
        - ...
      - templates/
        - app-template.yaml

## Guidelines

- Each application should have its own YAML file in the configurations/ directory (e.g., chatbot.yaml, summarizer.yaml).
- Each YAML file should define a single Dify app and its workflow/config.
- Avoid bundling multiple apps in a single YAML file.
- Use clear, descriptive filenames for each app.
- Store shared resources (if any) in a separate directory (e.g., shared/).
- Use a main branch for production-ready configs; use feature branches for development/testing.
- Protect the main branch with required reviews and CI checks.

## Example

```
dify-config/
  main/
    dify/
      configurations/
        chatbot.yaml
        summarizer.yaml
        qa-bot.yaml
```

## Import Automation

## Local OpenAI-Compatible Router

- Router config: `dify/configurations/local-openai-compatible-router.yaml`
- Generated copy: `dify/generated/local-openai-compatible-router.generated.yaml`
- Classification source data: `dify/generated/local-llm-classification.generated.json`
- Generated model setup wrapper: `dify/generated/setup-openai-compatible-models.mjs`
- Generated router import wrapper: `dify/generated/import-local-openai-compatible-router.mjs`
- Purpose: provide Dify with an OpenAI-compatible local provider and request-type routing policy generated from local model availability plus LLMDB-assisted classification.
- Endpoint: `FORTISAI_LLAMA_OPENAI_BASE_URL`; Linux resolves this as the primary `http://fortisai-llama-server.fortisai.local:8011/v1` inside containers. The secondary `http://fortisai-llama-server-secondary.fortisai.local:8012/v1` endpoint is reserved for support tools and is not used by the generated Dify router.
- Classification: generated monthly by n8n using LLMDB data, tool-use evidence, and the local Mistral classifier model. If the classifier returns malformed JSON, the generator falls back to deterministic LLMDB/name/quantization heuristics and records `classifier_error` in `dify/generated/local-llm-classification.generated.json`.
- Route categories: coding, agentic tool use, reasoning/math, analysis/research, summarization, classification/extraction, long context, fast chat, multimodal/vision, and safety guardrails. The `agentic_tool_use` route carries `required_capabilities: ["tool_use"]` and `force_model_load: true` so explicit tool requests use the classified tool-use model even when another model is already loaded.
- Production order: generate router artifacts, run the generated OpenAI-compatible model setup wrapper for the active route model set, then run the generated router import wrapper to update and publish `local-openai-compatible-router`.
- Model setup: the generated wrapper calls the stable `Development_Environment/dify-config/setup-openai-compatible-models.mjs` script, which prefers the Dify OpenAPI bridge fast endpoint `/dify_openai_compatible_model_setup` and falls back to Dify admin API validation when needed. The default fast path imports only models referenced by active generated router routes and prunes stale FortisAI-managed OpenAI-compatible model rows from Dify; pass `--keep-stale-models` or set `DIFY_MODEL_SETUP_PRUNE_STALE=false` to keep old rows for troubleshooting.
- Model eligibility: run Linux model validation before classification. Validation restores existing `.gguf.disable...` files by default so previously disabled normal models and split sets are retested, then unloadable, corrupted, incomplete, support-only, unsupported Bitnet `ggml-model-i2_s`, high-precision `BF16`/`FP16`, and models that do not answer within the 300-second validation SLA are renamed with a `.disable...` suffix and recorded in `llm_directory/disabled_models.json`; the restarted llama router excludes those files from `/v1/models`, and the classifier also filters any manifest-listed model aliases before generating routes. Split GGUF sets are represented by shard `00001` only for validation, route generation, and Dify model setup; later shards remain enabled on disk as supporting files unless shard `00001` fails.

- The import pipeline should iterate over all YAML files in configurations/ and import each app individually.
- The pipeline should update an existing app with the same name or explicit app ID instead of creating duplicates.
- Keep template files in templates/ so they are not imported as real apps.

## Template Usage

1. Copy dify/templates/app-template.yaml to dify/configurations/<your-app>.yaml.
2. Replace APP_NAME_PLACEHOLDER and MODEL_NAME_PLACEHOLDER.
3. Commit and push via pull request.

## Versioning
- Use GitHub PRs for changes.
- Tag releases for major config updates.

---
This structure ensures modular, maintainable, and automatable Dify app management for OCI-GitHub workflows.
