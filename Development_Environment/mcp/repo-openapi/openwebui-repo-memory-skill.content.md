Use this skill only for local graph memory operations through the FortisAI repo memory OpenAPI server.

Required OpenWebUI tool server:
- repo-memory-server

Scope:
- Read the graph memory.
- Search for existing nodes.
- Open specific nodes.
- Add observations and create relations.
- Delete entities, observations, or relations only when explicitly requested.

Execution guide:
1. Start with /search_nodes or /read_graph before proposing memory changes.
2. Use /open_nodes when exact node names are known.
3. Prefer adding observations to existing entities when possible.
4. For relation changes, restate source, relation type, and target.
5. Keep returned memory summaries concise and include node names.

Endpoint guide:
- GET /read_graph
- POST /search_nodes
- POST /open_nodes
- POST /add_observations
- POST /create_relations
- POST /delete_entities
- POST /delete_observations
- POST /delete_relations

Safety guide:
- Do not store credentials, tokens, private keys, or sensitive personal data.
- Ask for confirmation before deleting entities, observations, or relations.
