# FortisAI Composio SaaS Connector Skill

Use this skill for external SaaS applications and cloud services that are not already exposed through a dedicated FortisAI MCP/OpenAPI bridge.

Required OpenWebUI tool server:
- `mcp-composio-server`

Session requirement:
- Every Composio tool call must use the current OpenWebUI user as the Composio session `user_id`. Include `openwebui_user_id` with the OpenWebUI username, email, or user id in `/composio_search_tools`, `/composio_execute_tool`, and `/composio_mcp_request` calls. The FortisAI bridge forwards that identity to the local Composio MCP proxy, which creates or reuses `Composio().create(user_id=<openwebui user>, mcp=True)` and calls the returned `session.mcp.url` with `session.mcp.headers`.

Allowed by default:
- Email, calendar, chat, document, storage, CRM, ticketing, project management, marketing, finance, analytics, HR, ecommerce, developer SaaS, and other third-party cloud applications available through Composio.
- Examples include Gmail, Outlook, Microsoft Teams, Slack, Google Calendar, Google Drive, Google Docs, Google Sheets, Notion, Linear, Jira, GitHub, GitLab, HubSpot, Salesforce, Zendesk, Asana, Trello, Airtable, Dropbox, OneDrive, DocuSign, Shopify, Stripe, Mailchimp, and similar SaaS services.

Do not use Composio when a FortisAI-native MCP/OpenAPI bridge exists for the task.

FortisAI-native exclusions:
- Firecrawl / websearch: use `mcp-websearch-server`.
- Daytona / code execution: use `mcp-daytona-server`.
- Oracle SQL / SQLcl: use `mcp-sqlcl-server`.
- n8n workflows: use `mcp-n8n-server`.
- Dify / FortisAI proxy: use `mcp-dify-server`.
- CodeIndexer / semantic code search: use `mcp-codeindexer-server`.
- Proxmox infrastructure operations: use `mcp-proxmox-server`.
- OpenMetadata catalog and ingestion tasks: use `mcp-openmetadata-server`.
- FortisAI repo filesystem, memory, and time operations: use the repo OpenAPI tools.

Execution guide:
1. Use `/composio_connection_info` to confirm the Composio MCP URL is configured; a Vault API key is optional when the local Composio SDK/container is already authenticated.
2. Use `/composio_search_tools` with `openwebui_user_id` set to the current OpenWebUI username/user id to inspect available allowed tools for that user session.
3. Use `/composio_execute_tool` with the same `openwebui_user_id` only for the requested external SaaS action.
4. Never expose OAuth links, API keys, bearer headers, Vault tokens, or connected-account secrets.
5. Prefer read-only SaaS actions unless the user explicitly asks for a write action.
