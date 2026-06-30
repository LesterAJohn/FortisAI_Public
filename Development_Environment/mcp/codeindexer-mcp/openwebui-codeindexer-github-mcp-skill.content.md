# FortisAI CodeIndexer GitHub Skill

Use this skill to clone, update, index, search, and clear GitHub repositories through the FortisAI CodeIndexer bridge.

Required OpenWebUI tool server:
- `mcp-codeindexer-server`

Scope:
- Clone or pull public GitHub repositories into the FortisAI-managed CodeIndexer cache.
- Clone or pull private GitHub repositories only when a GitHub token is present in Vault and the repository is allowed by policy.
- Index cached GitHub repositories with CodeIndexer/Milvus.
- Search indexed GitHub repositories with natural-language questions.

Execution guide:
1. Use `/codeindexer_connection_info` to confirm the GitHub cache path and whether a GitHub token is configured.
2. Use `/codeindexer_clone_github_repository` or `/codeindexer_pull_github_repository` to prepare a repository.
3. Use `/codeindexer_index_github_repository` before searching when the repository has not been indexed.
4. Use `/codeindexer_search_github_repository` for repository-specific code questions.
5. For normal FortisAI repository search, use `/codeindexer_index` and `/codeindexer_search` on `/workspace`.
6. Do not expose GitHub tokens, Vault tokens, clone headers, or credentials.
