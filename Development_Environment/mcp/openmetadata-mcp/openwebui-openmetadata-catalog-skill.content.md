# FortisAI OpenMetadata Catalog Skill

Use this skill for FortisAI data catalog, metadata search, lineage, glossary, tags, owners, dashboards, charts, database assets, and governance metadata.

Required OpenWebUI tool server:
- `mcp-openmetadata-server`

Scope:
- Search OpenMetadata catalog assets.
- Inspect tables, databases, schemas, dashboards, charts, glossaries, tags, and lineage.
- Summarize owners, descriptions, tags, and governance metadata.

Execution guide:
1. Use `/openmetadata_connection_info` for diagnostics.
2. Use `/openmetadata_search` for broad discovery.
3. Use `/openmetadata_get_entity_by_name` for focused lookups by FQN.
4. Use `/openmetadata_get_lineage` for upstream/downstream dependency questions.
5. Do not expose API tokens, Vault tokens, source credentials, or connection strings.
