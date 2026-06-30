# FortisAI AOL IMAP Bridge

This bridge exposes Vault-backed AOL IMAP actions for the FortisAI n8n spam workflows.

## Runtime

- Container: `fortisai-mcp-openapi-aol-imap`
- Host port: `8101`
- Internal URL: `http://fortisai-mcp-openapi-aol-imap.fortisai.local:8101`
- Bridge source: `aol-imap-openapi-bridge.py`

The helper starts this bridge through `Development_Environment/mcp/start-mcp-openapi-bridges.sh` and stops it through `stop-mcp-openapi-bridges.sh`. It receives `FORTISAI_VAULT_ADDR`, `VAULT_ADDR`, and the helper-managed read-only `VAULT_TOKEN`.

## Vault Paths

The bridge reads AOL app passwords from these Vault paths:

- `secret/fortisai/dev/aol/imap/lesterajohn/password`
- `secret/fortisai/dev/aol/imap/laj0703/password`
- `secret/fortisai/dev/aol/imap/lesterajohn1/password`

Do not put AOL app passwords in workflow exports, documentation, or shell history.

## Endpoints

- `GET /aol_imap_connection_info` - show configured accounts and Vault/password availability without returning secrets.
- `POST /aol_imap_list_mailboxes` - list IMAP folders for a configured account.
- `POST /aol_imap_folder_counts` - return counts for common folders such as `Inbox`, `Spam`, `Junk`, and `Bulk`.
- `POST /aol_imap_fetch_messages` - fetch message summaries from a folder for hourly Spam-folder learning. When `source_folder` is logical `Spam`, the bridge scans `Spam`, `Bulk`, and `Junk` by default and preserves each message's actual source folder for later delete requests.
- `POST /aol_imap_move_message` - move an Inbox message to `Spam` after classifier verdict `SPAM`.
- `POST /aol_imap_delete_message` - delete a Spam-folder message after Qdrant memory insertion.
- `POST /aol_imap_delete_messages` - delete a batch of learned Spam-folder messages from one account/folder with a single IMAP session and one final expunge.

The message action endpoints prefer IMAP UID. They also accept RFC `Message-ID` as a fallback when UID is unavailable. Move and delete are idempotent for duplicate-processing races: if the selected source folder exists but the message is already gone, the bridge returns `ok: true`, `skipped: true`, and an action reason instead of surfacing a 404 to n8n. Use the batch delete endpoint for learned spam cleanup so AOL does not see one login per message.

## n8n Workflow

`Development_Environment/n8n-config/main/n8n/configurations/hourly-aol-spam-filter.json` defines `Hourly AOL Spam Filter`.

The workflow uses three AOL IMAP trigger credentials for Inbox arrivals, classifies each message with the FortisAI spam-memory agent, writes spam decisions into the shared `gmail_spam_memory_d1536` Qdrant collection, and moves classifier spam to the AOL `Spam` folder. It caps normalized IMAP snippets before the classifier prompt to keep large raw messages inside the local model context window. It also runs hourly Spam-folder scans through this bridge, builds compact memory records for user- or provider-placed spam, writes them into Qdrant, and deletes those learned Spam-folder messages. AOL exposes provider spam in IMAP `Bulk` on the current mailboxes, with `Spam` and `Junk` still present as folders, so the bridge treats logical `Spam` fetches as an alias scan across all three. The bridge tolerates malformed message charsets such as `unknown-8bit` so one bad spam message does not fail the whole fetch. `Prepare AOL Spam Delete Requests` rebuilds valid delete payloads after Qdrant insertion, groups them by account and actual source folder, and uses batch delete to avoid AOL IMAP login rate/logoff failures. The memory builder bounds sender, subject, snippet, reason, account, and folder fields before embedding so long newsletters stay below the llama-server embedding batch limit.
