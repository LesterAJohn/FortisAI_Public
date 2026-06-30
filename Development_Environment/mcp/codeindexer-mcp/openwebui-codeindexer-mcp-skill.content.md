# FortisAI CodeIndexer Skill

Use this skill only for semantic code indexing and code search tasks in OpenWebUI.

Required OpenWebUI tool server:
- `mcp-codeindexer-server`

Scope:
- Index a repository or source tree before semantic search.
- Search indexed code with natural-language questions.
- Clear and rebuild an index when source paths or embeddings change.

Execution guide:
1. Use `/codeindexer_connection_info` first if you need to confirm the mounted workspace, Milvus address, or embedding endpoint.
2. Use `/codeindexer_index` before `/codeindexer_search` when a path has not been indexed.
3. Prefer the mounted FortisAI workspace path `/workspace`; host path `/opt/home/aiuser/FortisAI` is translated by the bridge.
4. Use `force: true` only when rebuilding an existing index.
5. For broad repository questions, search first, then quote only the relevant file paths and line summaries returned by CodeIndexer.
6. If a bridge call fails, report the endpoint, path, and short error message. Do not expose API keys, Vault tokens, or container environment values.

Endpoint guide:
- `GET /codeindexer_connection_info`
- `GET /codeindexer_tools`
- `POST /codeindexer_index`
- `POST /codeindexer_search`
- `POST /codeindexer_clear`
- `POST /codeindexer_mcp_tool`

Recommended request shapes:

```json
{"path":"/workspace","force":false,"splitter":"ast"}
```

```json
{"path":"/workspace","query":"Where is the Linux helper all-up sequence implemented?","limit":10}
```
