# FortisAI n8n Config

This directory stores source-controlled n8n workflows for FortisAI local and OCI-GitHub import workflows.

## Monthly Local LLM Router Classification

- Workflow: `main/n8n/configurations/weekly-local-llm-router-classification.json`
- Script: `main/n8n/scripts/classify-local-llm-router.mjs`
- Schedule: day 1 of every month at 6:00 PM Eastern (`America/New_York`)
- Linux runtime endpoint: `FORTISAI_LLAMA_OPENAI_BASE_URL`, defaulting to `http://fortisai-llama-server.fortisai.local:8011/v1` inside n8n
- Mac/Windows runtime endpoint: override `FORTISAI_LLAMA_OPENAI_BASE_URL` for LM Studio or another OpenAI-compatible local endpoint

The workflow runs the script inside the n8n container. Helpers mount this repo into n8n as `/FortisAI/Development_Environment/n8n-config` and `/FortisAI/Development_Environment/dify-config`.

The script writes native Dify app YAML to `Development_Environment/dify-config/main/dify/configurations/local-openai-compatible-router.yaml`. The generated app uses a standard `start -> llm -> answer` workflow graph so the Dify GUI can render it cleanly. Because it is an advanced-chat app, the router uses Dify's built-in `sys.query` input and does not generate a custom start-node input variable. The raw FortisAI routing table is also written to `Development_Environment/dify-config/main/dify/generated/local-openai-compatible-router.reference.yaml` for audit and downstream automation. The generated classification JSON now includes per-model `tool_use` and `embedding` metadata, marks the `agentic_tool_use` route with `required_capabilities: ["tool_use"]` and `force_model_load: true`, adds an `embeddings` route used by the Dify `/v1/embeddings` facade, and records disabled-manifest counts so models that failed validation are auditable.

Run Linux model validation before the monthly classifier. The validator first restores existing `.gguf.disable...` files by default (`LLAMA_RESTORE_DISABLED_BEFORE_TESTS=true`) so previously disabled normal models and split sets are retested, then disables GGUF files that are unloadable, unsupported, non-runnable support assets, or do not respond within the default 300-second `LLAMA_TEST_TIMEOUT_SECONDS` budget. Split GGUF sets are tested through shard `00001` only; later shards are restored/left enabled for llama.cpp to read and are skipped as standalone test/import targets unless shard `00001` fails, in which case the whole split set is disabled. The classifier reads `LLAMA_DISABLED_MODELS_FILE` or `llm_directory/disabled_models.json` and filters any manifest-listed model aliases plus non-first split shards before selecting Dify router targets.

The generated Dify app declares the OpenAI-compatible marketplace dependency and uses the installed provider id `langgenius/openai_api_compatible/openai_api_compatible` for the workflow LLM node. The companion Dify importer installs the dependency if needed, configures the workflow model connection, and publishes the app after model setup succeeds.

The production workflow runs three actions through the n8n workflow-runner sidecar:

1. Run the local LLM classifier and generate Dify artifacts.
2. Run the generated Dify OpenAI-compatible model setup script so active generated route models are configured before app import and stale FortisAI-managed OpenAI-compatible Dify model rows are pruned.
3. Run the generated Dify router import script to update and publish `local-openai-compatible-router`.

After helper `mcp-up`, the Dify OpenAPI bridge uses the generated classification file as the live routing policy for the OpenAI-compatible facade at `http://127.0.0.1:8093/v1`. Clients should request model `fortisai`; the bridge routes each chat, completion, response, or embedding request to the preferred supporting local model selected from the generated classification data and returns an OpenAI-shaped response. The bridge does not substitute an already-loaded model when the preferred model is cold; helper startup gives cold preferred-model loads a 600-second router timeout. Requests that include OpenAI `tools`, `functions`, `tool_choice`, function calls, or clear tool-use language are routed to `agentic_tool_use` and mark the selected tool-use model for force-load behavior. Embedding clients should also use model `fortisai` unless intentionally overriding with a specific model.

The runner exposes these internal endpoints to the n8n container:

- `POST /run/local-llm-router-classification`
- `POST /run/dify-openai-compatible-model-setup`
- `POST /run/dify-local-openai-compatible-router-import`

## Linux Test

From `/opt/home/aiuser/FortisAI` on `aiengine000`:

```bash
LOCAL_OPENAI_BASE_URL=http://127.0.0.1:8011/v1 \
  node Development_Environment/n8n-config/main/n8n/scripts/classify-local-llm-router.mjs
```

From the n8n container after helper setup/recreate:

```bash
podman exec fortisai-n8n node /FortisAI/Development_Environment/n8n-config/main/n8n/scripts/classify-local-llm-router.mjs
```


## Classifier Runtime Details

The classifier agent uses `mistral__mistralai_Mistral-Small-3.2-24B-Instruct-2506-Q8_0` by default when that model is active. If the configured classifier is disabled or absent from the filtered active `/v1/models` list, the script selects an active local fallback, records `requested_classifier_model` and `classifier_model_changed`, sends a compact LLMDB-assisted prompt with numeric row indexes and tool-use evidence, then expands the returned route labels back to full model IDs in the generated Dify app, reference router, and classification artifacts.

Default runtime controls:

- `LLM_ROUTER_CLASSIFIER_MODEL`: override the classifier model.
- `LLM_ROUTER_CLASSIFIER_MAX_TOKENS`: defaults to `768`; the agent returns only changes from seeded labels.
- `LLM_ROUTER_CLASSIFIER_TIMEOUT_MS`: defaults to `900000`.
- `LLM_ROUTER_CLASSIFIER_STREAM`: defaults to streaming enabled; set to `0` only for troubleshooting.
- `SKIP_LLM_CLASSIFIER=1`: generate deterministic fallback routing without calling the classifier.

Recent Linux validation on `aiengine000` observed 30 router-visible local model entries after llama catalog repair. The classifier output still records the model count and `classification_source` in `Development_Environment/dify-config/main/dify/generated/local-llm-classification.generated.json`; rerun the monthly workflow after model changes so the generated router reflects the current `/v1/models` list.


## Import Workflows

Use `./Development_Environment/n8n-config/import-n8n-workflows.sh` to import JSON workflows from `Development_Environment/n8n-config/main/n8n/configurations` into a running n8n container. The script sanitizes source-control metadata that n8n cannot import directly, skips zero-node examples by default, imports through the n8n CLI, and activates workflows marked `active: true`.

Gmail spam-filter workflow exports set the OpenAI Chat Model timeout to `300000` ms so local FortisAI tool-use requests have enough time to route through the Dify/OpenAI bridge and execute Qdrant memory retrieval before n8n retries or fails the node.

Spam-memory vector writes use the dimension-suffixed Qdrant collection `gmail_spam_memory_d1536` and request OpenAI Embeddings model `fortisai`. The Dify `/v1/embeddings` bridge selects the concrete embedding model from the generated `embeddings` request type. Qdrant vector dimensions are exact, not buffered; if the classified embedding route changes to a model with a different vector size, create a new dimension-suffixed collection and migrate/re-embed records before switching workflows.

The AOL spam-filter workflow uses the same Qdrant memory pattern and also depends on the FortisAI AOL IMAP bridge at `http://fortisai-mcp-openapi-aol-imap.fortisai.local:8101` for mailbox move/delete actions that n8n's built-in IMAP trigger does not provide.

Activation defaults to `auto`: the importer uses the public API when `N8N_API_KEY` is available, then falls back to the local n8n CLI if API activation is unavailable. CLI activation restarts n8n so scheduled triggers are loaded by the running server. Use `--activation-method api` or `--activation-method cli` to force one activation path.

Runtime requirements:

- `podman`, `jq`, and `curl` on the host.
- Running `fortisai-n8n` container.
- `N8N_API_KEY` in the environment for public API activation. On Linux, the FortisAI helper loads this from Vault path `secret/fortisai/dev/n8n/api_key`.

Linux helper command:

```bash
cd /opt/home/aiuser/FortisAI/Development_Environment/linux
./fortisai-dev-helper.sh n8n-import-workflows
```

The helper starts/unseals Vault, loads only the n8n runtime secrets needed for this operation, regenerates the n8n compose stack with the workflow runner sidecar, starts the stack quietly, and then runs the importer.

## Hourly Gmail Spam Filter Setup

- Source workflow JSON: `main/n8n/configurations/hourly-gmail-spam-filter.json`
- Live workflow name: `Hourly Gmail Spam Filter`
- Live workflow id on `aiengine000`: `6li60U1h6fStNFw4`
- Gmail source and trigger nodes must feed their matching `Stamp Route ...` node first. The stamp nodes attach stable source fields such as `routeMailbox`, `sourceMessageId`, `sourceFrom`, `sourceSubject`, `sourceSnippet`, and `sourceLabels`.
- Agent output is merged back with the stamped source item before validation, audit, and memory writes. `Validate AI Output` and `Build Memory Records` must read only their current item fields and must not use cross-node lookups like `$('Get Recent Inbox Messages').item`.
- Existing Gmail messages with the `SPAM` label are harvested through `Build SPAM Label Memory Records` before `Qdrant Memory Insert`; the same harvest branch also feeds the intentional Gmail delete nodes. Raw Gmail items must not feed `Qdrant Memory Insert` directly because the memory data loader requires `memoryText`.

Current live flow summary (export refresh 2026-06-30):

1. Trigger layer: `Every Hour`, `Manual Trigger`, and three Gmail inbox triggers (`Gmail Trigger`, `Gmail Trigger1`, `Gmail Trigger2`).
2. Source mailbox reads: `Get Recent Inbox Messages`, `customerservice@aitradeengines.com`, and `lesterajohn@oneserverx.com`.
3. Route normalization and source merge: `Stamp Route Lester`, `Stamp Route CustomerService`, `Stamp Route OneServerX`, then `Merge Source With AI Output` before validation.
4. Guardrails: `Validate AI Output` -> `Validation Switch` with alert branch (`Validation Alert` -> `Alert Route Switch` -> `AI Alert Label Added*`).
5. Decision fan-out: `Switch` routes by `routeMailbox` into mailbox-specific spam label/remove-label nodes (`Add Spam Label*`, `Remove Inbox Label*`) with `AI-Reviewed Label Added*` markers.
6. Memory loop: `Build Memory Records` and `Build SPAM Label Memory Records` feed `Memory Data Loader` -> `Qdrant Memory Insert`, while retrieval uses `Qdrant Memory Tool` + `OpenAI Embeddings` in the classifier path.

Configure Gmail OAuth2 in n8n:

1. In Google Cloud Console, create/select a project and enable `Gmail API`.
2. Configure OAuth consent screen for your Gmail account (internal or external as needed).
3. Create an OAuth client id for `Web application`.
4. Add the n8n OAuth callback URL shown in n8n Gmail credential UI (typically `https://<your-n8n-host>/rest/oauth2-credential/callback`).
5. In n8n, create credential type `Gmail OAuth2 API` and complete Google authorization.

Attach the Gmail credential to workflow nodes:

1. Open `Hourly Gmail Spam Filter`.
2. Set the same `Gmail OAuth2 API` credential on:
  - `Get Recent Inbox Messages`
  - `Add Spam Label`
  - `Remove Inbox Label`

Validate and activate:

1. Run `Manual Trigger` once and confirm sample spam messages are labeled `SPAM` and removed from `INBOX`.
2. Verify agent output remains valid JSON with `verdict`, `reason`, and `memory_used`.
3. Save workflow and toggle it to `Active`.
4. Confirm hourly runs appear in n8n Executions.

## Hourly AOL Spam Filter Setup

- Source workflow JSON: `main/n8n/configurations/hourly-aol-spam-filter.json`
- Live workflow name: `Hourly AOL Spam Filter`
- Live workflow id on `aiengine000`: `8CqjMUL6HY7bAOLs`
- Live export: `main/n8n/configurations/live-all-workflows/hourly-aol-spam-filter-8CqjMUL6HY7bAOLs.json`
- Bridge: `fortisai-mcp-openapi-aol-imap` on `http://fortisai-mcp-openapi-aol-imap.fortisai.local:8101`

Required n8n credentials:

- `AOL IMAP - LesterAJohn@aol.com`
- `AOL IMAP - laj0703@aol.com`
- `AOL IMAP - LesterAJohn1@aol.com`

Required Vault paths for AOL app passwords:

- `secret/fortisai/dev/aol/imap/lesterajohn/password`
- `secret/fortisai/dev/aol/imap/laj0703/password`
- `secret/fortisai/dev/aol/imap/lesterajohn1/password`

Workflow behavior:

- Three `Email Trigger (IMAP)` nodes watch the AOL Inbox folders for new unread messages and do not mark messages read.
- Each trigger feeds its matching `Stamp Route ...` node so downstream nodes get stable fields such as `account_id`, `sourceMailbox`, `sourceFolder`, `imapUid`, `sourceFrom`, `sourceSubject`, and `sourceSnippet`. The route nodes normalize HTML/raw IMAP payloads and cap snippets before the classifier prompt so large messages do not exceed the local model context window.
- The classifier uses the shared `gmail_spam_memory_d1536` Qdrant collection so AOL and Gmail spam evidence reinforce the same FortisAI spam model through the classified `fortisai` embedding route.
- AOL spam memory records compact each stored Qdrant document before embedding: sender, subject, snippet, reason, account, and folder fields are bounded, with the embedded snippet capped at 220 characters. This keeps long newsletters and malformed spam below the local llama-server embedding batch limit while preserving the useful spam-matching signals.
- Classifier verdict `SPAM` feeds `Move AOL Spam to Spam Folder`, which calls `/aol_imap_move_message` and moves the message to the AOL `Spam` folder. Duplicate IMAP trigger races can arrive after a prior execution already moved the same message; the bridge treats that not-found case as an idempotent skipped action instead of a hard 404.
- The hourly Spam-folder learning branch calls `/aol_imap_fetch_messages` with logical folder `Spam`. The AOL IMAP bridge expands that logical request across AOL spam aliases (`Spam`, `Bulk`, and `Junk` by default), because live AOL mailboxes can store webmail spam under `Bulk` even when `Spam` exists. It builds memory records for those messages, inserts them into Qdrant, then calls `/aol_imap_delete_messages`. This delete is intentional: it keeps Spam-folder messages placed there by the user or by another spam solution from being relearned repeatedly after they are stored as memory. `Prepare AOL Spam Delete Requests` runs after the Qdrant insert succeeds, groups de-duplicated delete payloads by `account_id` and actual `source_folder`, and sends one batch delete request per group to avoid AOL IMAP login churn.

Current live flow summary (export refresh 2026-06-30):

1. Trigger layer: `Every Hour`, `Manual Trigger`, and three AOL IMAP inbox triggers (`AOL Inbox Trigger - LesterAJohn@aol.com`, `AOL Inbox Trigger - laj0703@aol.com`, `AOL Inbox Trigger - LesterAJohn1@aol.com`).
2. Source normalization: mailbox-specific route stamp nodes (`Stamp Route Lester`, `Stamp Route LAJ0703`, `Stamp Route Lester1`) provide stable account and message fields before classification.
3. Classifier and guardrails: `AI Agent Spam Classifier` -> `Merge Source With AI Output` -> `Validate AI Output` -> `Keep Spam Only`.
4. Live spam handling: spam verdicts call `Move AOL Spam to Spam Folder` through the AOL IMAP bridge.
5. Spam-folder learning: hourly fetch nodes (`Fetch AOL Spam - ...`) feed `Split AOL Spam Folder Messages` -> `Build AOL Spam Folder Memory Records` -> `AOL Spam Folder Data Loader` -> `Qdrant AOL Spam Folder Insert`.
6. Post-learn cleanup: `Prepare AOL Spam Delete Requests` batches account/folder deletes into `Delete Learned AOL Spam` for idempotent cleanup.

Validate and activate:

1. Run `./Development_Environment/linux/fortisai-dev-helper.sh mcp-up` on `aiengine000` so `fortisai-mcp-openapi-aol-imap` is running.
2. Confirm `GET http://127.0.0.1:8101/aol_imap_connection_info` reports Vault configured and all three accounts present.
3. Confirm `POST http://127.0.0.1:8101/aol_imap_list_mailboxes` works for each account id.
4. Import workflows with `./Development_Environment/linux/fortisai-dev-helper.sh n8n-import-workflows` after repo sync, or import this workflow through the n8n CLI and activate it.
5. Confirm n8n reports `Hourly AOL Spam Filter` active with four registered triggers: one hourly schedule and three IMAP Inbox triggers.
