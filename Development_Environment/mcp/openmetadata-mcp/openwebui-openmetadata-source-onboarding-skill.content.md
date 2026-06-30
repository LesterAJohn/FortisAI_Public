# FortisAI OpenMetadata Source Onboarding Skill

Use this skill to register data sources in OpenMetadata, configure catalog ingestion, test source connectivity, trigger catalog ingestion, and inspect ingestion status.

Required OpenWebUI tool server:
- `mcp-openmetadata-server`

Scope:
- Add or update OpenMetadata database, dashboard, storage, messaging, and pipeline services.
- Create or update ingestion pipelines.
- Deploy and trigger ingestion pipelines.
- Inspect ingestion status and logs.

Initial FortisAI source aliases:
- `tradeenginedb0_mongodb`
- `tradeenginedb_influxdb`

Execution guide:
1. Use `/openmetadata_supported_service_types` before adding a new source type.
2. Use `/openmetadata_create_or_update_source` for known FortisAI aliases.
3. Use `/openmetadata_create_or_update_service` only when the user provides a source shape that is not covered by an alias.
4. Use `/openmetadata_create_or_update_ingestion_pipeline`, then `/openmetadata_deploy_ingestion_pipeline`, then `/openmetadata_trigger_ingestion_pipeline` when ingestion execution is requested.
5. Use `/openmetadata_get_ingestion_status` and `/openmetadata_get_ingestion_logs` for run follow-up.
6. Do not expose source credentials. Prefer Vault-backed secret references. Do not delete OpenMetadata services, users, teams, tokens, or catalog assets unless explicitly authorized.
