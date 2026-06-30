# FortisAI Websearch Skill

Use this skill when OpenWebUI needs current public web information through the FortisAI Firecrawl pod.

Required OpenWebUI tool server:
- `mcp-websearch-server`

Callable tool names:
- `websearch_search` for normal public web searches.
- `websearch` as a compatibility alias for `websearch_search` when the model emits the shorter tool name.
- `websearch_scrape` for inspecting a specific URL after search.
- `websearch_connection_info` only for diagnostics.

Scope:
- Search the public web for current or externally sourced information.
- Inspect a specific URL returned by search when more page detail is needed.
- Return concise answers grounded in the URLs and titles returned by Firecrawl.

Execution guide:
1. For normal web queries, call `websearch_search` with OpenWebUI tool-call JSON that uses `parameters`, not `arguments`: `{"tool_calls":[{"name":"websearch_search","parameters":{"query":"Bishop Arts District Dallas restaurants list","limit":5}}]}`.
2. Never call `websearch_search` or `websearch` with empty `parameters`; `query` is required and must be copied from the user's requested search topic. Do not emit raw `<tool_call>` text in user-visible answers.
3. If the model emits `websearch`, OpenWebUI can execute that compatibility alias with the same `parameters` object as `websearch_search`.
4. Use `websearch_connection_info` only for diagnostics or to confirm Firecrawl health.
5. Use `websearch_scrape` only for URLs that need page-level detail after search.
6. Prefer result titles, URLs, descriptions, and markdown snippets from Firecrawl over unsupported claims.
7. Cite the URLs you relied on in the answer.
8. If Firecrawl reports `/health` as missing, check `/v0/health/liveness` and `/v0/health/readiness`; the current image exposes those public health paths.
9. If a bridge call fails, report the endpoint, status, and short error message. Do not expose API keys, Vault tokens, or container environment values.

Endpoint guide:
- `GET /websearch_connection_info`
- `POST /websearch_search`
- `POST /websearch`
- `POST /websearch_scrape`

Recommended request shapes:
```json
{"query":"FortisAI local AI platform","limit":5,"scrapeOptions":{"formats":["markdown"],"onlyMainContent":true}}
```
```json
{"query":"Bishop Arts District Dallas restaurants list","limit":15}
```
```json
{"url":"https://example.com","formats":["markdown"],"onlyMainContent":true}
```

OpenWebUI tool-call example:
```json
{"tool_calls":[{"name":"websearch_search","parameters":{"query":"Stock and Barrel Bishop Arts Dallas location","limit":5}}]}
```
