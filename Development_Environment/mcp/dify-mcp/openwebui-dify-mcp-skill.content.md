# FortisAI Dify Skill

Use this skill only for Dify-related tasks in OpenWebUI.

Required OpenWebUI tool server:
- `mcp-dify-server`

Scope:
- Dify app behavior and orchestration
- Prompt and instruction tuning
- Dataset usage and retrieval strategy
- Dify workflow and tool-calling patterns

Execution guide:
1. Clarify the target Dify app/workflow and expected outcome before proposing changes.
2. Prefer incremental updates to prompts and workflow logic instead of broad rewrites.
3. For diagnostics, summarize issue, probable root cause, and smallest safe fix.
4. Return concise Dify-centered outputs: app/workflow name, changed component, and validation result.
5. For Dify bridge calls, use the bridge OpenAPI routes and choose endpoint family intentionally:
	- Runtime app requests: `/v1/*` (app auth).
	- Console/admin requests: `/console/api/*` (admin auth in `auto` mode).
6. If an API call fails, report HTTP status, endpoint, and suggested next step.

Endpoint guide (runtime + console):
- `GET /v1/parameters`
- `GET /v1/meta`
- `POST /v1/chat-messages`
- `POST /v1/completion-messages`
- `POST /v1/workflows/run`
- `GET /console/api/apps`
- `GET /console/api/workspaces`
- `GET /console/api/admin/insert-explore-apps`

Bridge auth-mode guide:
- `/dify_api_request` supports `authMode` values: `auto`, `app`, `admin`, `console`, `none`.
- Recommended default: `authMode: "auto"`.
- In `auto` mode, `/v1/*` uses app auth and `/console/api/*` uses admin auth.

Do not use:
- Legacy non-console `/api/*` paths for Dify console operations. Use `/console/api/*` for console routes.

Safety guide:
- Do not expose secrets, tokens, or credentials.
- Do not modify unrelated systems when handling Dify requests.
- Ask for confirmation before destructive or high-impact Dify changes.
