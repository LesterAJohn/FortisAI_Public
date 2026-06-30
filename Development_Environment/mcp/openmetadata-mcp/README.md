# FortisAI OpenMetadata MCP Bridge

This directory contains the FortisAI OpenAPI bridge and OpenWebUI assets for the existing OpenMetadata runtime.

The bridge exposes a curated catalog, source onboarding, and ingestion-control surface instead of importing the full OpenMetadata Swagger document into OpenWebUI.

## Runtime

- Container: `fortisai-mcp-openapi-openmetadata`
- OpenAPI: `http://127.0.0.1:8100/openapi.json`
- Connection info: `http://127.0.0.1:8100/openmetadata_connection_info`
- Supported service types: `http://127.0.0.1:8100/openmetadata_supported_service_types`

## Tool Surface

- catalog search
- entity lookup by type, name, or FQN
- lineage lookup
- supported service type discovery
- create or update known database sources
- create or update ingestion pipelines
- deploy, trigger, and inspect ingestion pipeline runs

## TradeEngine Sources

The bridge includes aliases for the TradeEngine database sources used for local testing:

- `tradeenginedb0_mongodb`
- `tradeenginedb_influxdb`

Credentials are read from Vault and must not be copied into docs, workflow exports, or OpenWebUI prompts. The bridge reads the normalized TradeEngine paths and the OpenMetadata source paths for compatibility. OpenMetadata 1.12.6 does not expose InfluxDB as a native database service type, so the InfluxDB source is registered through the `CustomDatabase` path until native support exists.

Authenticated source, ingestion, and catalog search operations require `secret/fortisai/dev/openmetadata/api_token`. Without that token, connection checks can succeed but authenticated API calls return an OpenMetadata authorization error. Linux helper startup can refresh the token automatically when the OpenMetadata admin identity is stored in Vault at `secret/fortisai/dev/openmetadata/admin_email` and `secret/fortisai/dev/openmetadata/admin_password`.

## OpenWebUI Assets

- `openwebui-openmetadata-mcp-tools.import.json`
- `openwebui-openmetadata-catalog-skill.create.json`
- `openwebui-openmetadata-catalog-skill.content.md`
- `openwebui-openmetadata-source-onboarding-skill.create.json`
- `openwebui-openmetadata-source-onboarding-skill.content.md`

Helper `mcp-up` imports the tool connection and both skills when OpenWebUI is available.
