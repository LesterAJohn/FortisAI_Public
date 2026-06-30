param(
    [Parameter(Position = 0)]
    [string]$Command = "help",

    [Parameter(Position = 1)]
    [string]$Target = "",

    [Parameter(Position = 2)]
    [string]$Name = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$BaseDir = if ($env:FORTISAI_DEV_HOME) { $env:FORTISAI_DEV_HOME } else { Join-Path $HOME "fortisai-dev" }
$ConfigReposDir = Join-Path $BaseDir "config-repos"
$DevEnvDir = Split-Path -Parent $PSScriptRoot
$RepoRootDir = Split-Path -Parent $DevEnvDir
$TemplatesDir = Join-Path $DevEnvDir "templates"
$McpRootDir = Join-Path $DevEnvDir "mcp"
$N8nDir = Join-Path $BaseDir "n8n"
$OpenWebUiDir = Join-Path $BaseDir "openwebui"
$OpenVscodeDir = Join-Path $BaseDir "openvscode"
$AppsmithDir = Join-Path $BaseDir "appsmith"
$MongodbDir = Join-Path $BaseDir "mongodb"
$RedisDir = Join-Path $BaseDir "redis"
$RabbitMqDir = Join-Path $BaseDir "rabbitmq"
$VaultDir = Join-Path $BaseDir "vault"
$PgvectorDir = Join-Path $BaseDir "pgvector"
$OracleDbDir = Join-Path $BaseDir "oracle-db"
$OrdsDir = Join-Path $BaseDir "ords"
$SqlclDir = Join-Path $BaseDir "sqlcl"
$SqlclMcpDir = Join-Path $BaseDir "sqlcl-mcp"
$HonchoDir = Join-Path $BaseDir "honcho"
$HonchoRepoDir = Join-Path $HonchoDir "repo"
$OpenClawDir = Join-Path $BaseDir "claw-gateway"
$HermesDir = Join-Path $BaseDir "hermes-agent"
$FirecrawlDir = Join-Path $BaseDir "firecrawl"
$TraefikDir = Join-Path $BaseDir "traefik"
$CodeIndexerDir = Join-Path $BaseDir "codeindexer"
$CodeIndexerRepoDir = Join-Path $CodeIndexerDir "repo"
$CodeIndexerStateDir = Join-Path $CodeIndexerDir "state"
$MilvusDir = Join-Path $BaseDir "milvus"
$OpenMetadataDir = Join-Path $BaseDir "openmetadata"
$OpenSearchDir = Join-Path $BaseDir "opensearch"
$OpenApiServersDir = Join-Path $BaseDir "openapi-servers"
$OpenApiServersRepoDir = Join-Path $OpenApiServersDir "repo"
$OracleNodeApiDir = Join-Path $DevEnvDir "oracle-node-api"
$DifyRepoDir = Join-Path $BaseDir "dify"
$DifyDockerDir = Join-Path $DifyRepoDir "docker"
$DifyVaultComposeFile = Join-Path $DifyDockerDir "docker-compose.fortisai-vault.yaml"
$DifyMcpDir = Join-Path $McpRootDir "dify-mcp"
$DifyApiKeyJsonFile = Join-Path $DifyMcpDir "dify-api-key.json"
$DifyMcpSqlclBridgeScript = Join-Path $McpRootDir "sqlcl-mcp/sqlcl-openapi-bridge.py"
$DifyMcpN8nBridgeScript = Join-Path $McpRootDir "n8n-mcp/n8n-openapi-bridge.py"
$DifyMcpDifyBridgeScript = Join-Path $McpRootDir "dify-mcp/dify-openapi-bridge.py"
$DifyMcpDebugBridgeScript = Join-Path $McpRootDir "debug-mcp/debug-openapi-bridge.py"
$ProxmoxMcpDir = Join-Path $McpRootDir "proxmox"
$ProxmoxMcpConfigFile = Join-Path $ProxmoxMcpDir "proxmox-config.json"
$N8nMcpDir = Join-Path $McpRootDir "n8n-mcp"
$N8nMcpServerFile = Join-Path $N8nMcpDir "n8n-mcp-server.py"
$CodeIndexerMcpDir = Join-Path $McpRootDir "codeindexer-mcp"
$FortisAiCalicoDnsZone = if ($env:FORTISAI_CALICO_DNS_ZONE) { $env:FORTISAI_CALICO_DNS_ZONE } else { "fortisai.local" }
$FortisAiCoreDnsContainerName = if ($env:FORTISAI_COREDNS_CONTAINER_NAME) { $env:FORTISAI_COREDNS_CONTAINER_NAME } else { "fortisai-coredns" }
$SqlclOpenWebUiToolsImportFile = Join-Path $McpRootDir "sqlcl-mcp/openwebui-sqlcl-mcp-tools.import.json"
$SqlclOpenWebUiSkillCreateFile = Join-Path $McpRootDir "sqlcl-mcp/openwebui-sqlcl-mcp-skill.create.json"
$N8nOpenWebUiToolsImportFile = Join-Path $N8nMcpDir "openwebui-n8n-mcp-tools.import.json"
$N8nOpenWebUiSkillCreateFile = Join-Path $N8nMcpDir "openwebui-n8n-mcp-skill.create.json"
$CodeIndexerOpenWebUiToolsImportFile = Join-Path $CodeIndexerMcpDir "openwebui-codeindexer-mcp-tools.import.json"
$CodeIndexerOpenWebUiSkillCreateFile = Join-Path $CodeIndexerMcpDir "openwebui-codeindexer-mcp-skill.create.json"
$ProxmoxOpenWebUiToolsImportFile = Join-Path $ProxmoxMcpDir "openwebui-proxmox-mcp-tools.import.json"
$ProxmoxOpenWebUiSkillCreateFile = Join-Path $ProxmoxMcpDir "openwebui-proxmox-mcp-skill.create.json"
$RepoOpenApiMcpDir = Join-Path $McpRootDir "repo-openapi"
$RepoFilesystemOpenWebUiToolsImportFile = Join-Path $RepoOpenApiMcpDir "openwebui-repo-filesystem-tools.import.json"
$RepoFilesystemOpenWebUiSkillCreateFile = Join-Path $RepoOpenApiMcpDir "openwebui-repo-filesystem-skill.create.json"
$RepoMemoryOpenWebUiToolsImportFile = Join-Path $RepoOpenApiMcpDir "openwebui-repo-memory-tools.import.json"
$RepoMemoryOpenWebUiSkillCreateFile = Join-Path $RepoOpenApiMcpDir "openwebui-repo-memory-skill.create.json"
$RepoTimeOpenWebUiToolsImportFile = Join-Path $RepoOpenApiMcpDir "openwebui-repo-time-tools.import.json"
$RepoTimeOpenWebUiSkillCreateFile = Join-Path $RepoOpenApiMcpDir "openwebui-repo-time-skill.create.json"
$DifyOpenWebUiToolsImportFile = Join-Path $DifyMcpDir "openwebui-dify-mcp-tools.import.json"
$DifyOpenWebUiSkillCreateFile = Join-Path $DifyMcpDir "openwebui-dify-mcp-skill.create.json"
$DaytonaRepoDir = Join-Path $BaseDir "daytona"
$DaytonaComposeFile = Join-Path $DaytonaRepoDir "docker/docker-compose.yaml"
$DaytonaRuntimeFile = Join-Path $DaytonaRepoDir "docker/docker-compose.fortisai.runtime.yaml"

$N8nComposeFile = Join-Path $N8nDir "docker-compose.yml"
$OpenWebUiComposeFile = Join-Path $OpenWebUiDir "docker-compose.yml"
$OpenVscodeComposeFile = Join-Path $OpenVscodeDir "docker-compose.yml"
$AppsmithComposeFile = Join-Path $AppsmithDir "docker-compose.yml"
$MongodbComposeFile = Join-Path $MongodbDir "docker-compose.yml"
$RedisComposeFile = Join-Path $RedisDir "docker-compose.yml"
$RabbitMqComposeFile = Join-Path $RabbitMqDir "docker-compose.yml"
$VaultComposeFile = Join-Path $VaultDir "docker-compose.yml"
$VaultConfigFile = Join-Path $VaultDir "config/vault.hcl"
$VaultKeysFile = if ($env:VAULT_KEYS_FILE) { $env:VAULT_KEYS_FILE } else { Join-Path $VaultDir "vault-init.json" }
$PgvectorComposeFile = Join-Path $PgvectorDir "docker-compose.yml"
$OracleDbComposeFile = Join-Path $OracleDbDir "docker-compose.yml"
$OracleDbStartupDir = Join-Path $OracleDbDir "startup"
$OrdsComposeFile = Join-Path $OrdsDir "docker-compose.yml"
$SqlclComposeFile = Join-Path $SqlclDir "docker-compose.yml"
$SqlclMcpConfigFile = Join-Path $SqlclMcpDir "mcp.json"
$HonchoComposeFile = Join-Path $HonchoDir "docker-compose.yml"
$OpenClawComposeFile = Join-Path $OpenClawDir "docker-compose.yml"
$HermesComposeFile = Join-Path $HermesDir "docker-compose.yml"
$FirecrawlComposeFile = Join-Path $FirecrawlDir "docker-compose.yml"
$TraefikComposeFile = Join-Path $TraefikDir "docker-compose.yml"
$TraefikStaticConfigFile = Join-Path $TraefikDir "traefik.yml"
$TraefikDynamicConfigFile = Join-Path $TraefikDir "dynamic.yml"
$TraefikUsersFile = Join-Path $TraefikDir "users.htpasswd"
$MilvusComposeFile = Join-Path $MilvusDir "docker-compose.yml"
$OpenMetadataComposeFile = Join-Path $OpenMetadataDir "docker-compose.yml"
$OpenSearchComposeFile = Join-Path $OpenSearchDir "docker-compose.yml"
$OpenApiServersComposeFile = Join-Path $OpenApiServersRepoDir "compose.yaml"
$OpenClawRuntimeConfigFile = Join-Path $OpenClawDir "fortisai-claw-gateway.json"
$OracleNodeApiComposeFile = Join-Path $OracleNodeApiDir "docker-compose.yml"
$OpenApiServersEnvTemplateFile = Join-Path $OpenApiServersDir "openwebui-openapi-tools.env.example"
$OpenApiServersJsonTemplateFile = Join-Path $OpenApiServersDir "openwebui-openapi-tools.example.json"

$ProdEnvFile = Join-Path $BaseDir ".prod-link.env"
$ProdEnvExampleFile = Join-Path $BaseDir ".prod-link.env.example"

$N8nUrl = if ($env:N8N_URL) { $env:N8N_URL } else { "http://localhost:5678" }
$N8nBasicAuthUser = if ($env:N8N_BASIC_AUTH_USER) { $env:N8N_BASIC_AUTH_USER } else { "admin" }
$N8nBasicAuthPassword = if ($env:N8N_BASIC_AUTH_PASSWORD) { $env:N8N_BASIC_AUTH_PASSWORD } else { "change-me-n8n" }
$OpenWebUiUrl = if ($env:OPENWEBUI_URL) { $env:OPENWEBUI_URL } else { "http://localhost:3000" }
$FortisAiOpenWebUiDefaultApiKeyUser = if ($env:FORTISAI_OPENWEBUI_DEFAULT_API_KEY_USER) { $env:FORTISAI_OPENWEBUI_DEFAULT_API_KEY_USER } else { "LesterAJohn@gmail.com" }
$OpenWebUiApiUser = if ($env:OPENWEBUI_API_USER) { $env:OPENWEBUI_API_USER } else { $FortisAiOpenWebUiDefaultApiKeyUser }
$OpenVscodeUrl = if ($env:OPENVSCODE_URL) { $env:OPENVSCODE_URL } else { "http://localhost:13000" }
$AppsmithUrl = if ($env:APPSMITH_URL) { $env:APPSMITH_URL } else { "http://localhost:18080" }
$MongodbUrl = if ($env:MONGODB_URL) { $env:MONGODB_URL } else { "mongodb://127.0.0.1:27017/appsmith?replicaSet=rs0" }
$DifyUrl = if ($env:DIFY_URL) { $env:DIFY_URL } else { "http://localhost:18081" }
$RedisUrl = if ($env:REDIS_URL) { $env:REDIS_URL } else { "redis://127.0.0.1:6379" }
$RabbitMqUrl = if ($env:RABBITMQ_URL) { $env:RABBITMQ_URL } else { "amqp://fortisai:fortisai@127.0.0.1:5672" }
$RabbitMqManagementUrl = if ($env:RABBITMQ_MANAGEMENT_URL) { $env:RABBITMQ_MANAGEMENT_URL } else { "http://127.0.0.1:15672" }
$VaultUrl = if ($env:VAULT_URL) { $env:VAULT_URL } else { "http://127.0.0.1:8200" }
$PgvectorUrl = if ($env:PGVECTOR_URL) { $env:PGVECTOR_URL } else { "postgresql://fortisai:fortisai@127.0.0.1:5432/fortisai" }
$QdrantUrl = if ($env:QDRANT_URL) { $env:QDRANT_URL } else { "http://127.0.0.1:6333" }
$QdrantInternalUrl = if ($env:QDRANT_INTERNAL_URL) { $env:QDRANT_INTERNAL_URL } else { "http://qdrant:6333" }
$QdrantApiKey = if ($env:QDRANT_API_KEY) { $env:QDRANT_API_KEY } else { "difyai123456" }
$QdrantHostPort = if ($env:QDRANT_HOST_PORT) { [int]$env:QDRANT_HOST_PORT } else { 6333 }
$QdrantGrpcHostPort = if ($env:QDRANT_GRPC_HOST_PORT) { [int]$env:QDRANT_GRPC_HOST_PORT } else { 6334 }
$DaytonaUrl = if ($env:DAYTONA_URL) { $env:DAYTONA_URL } else { "http://localhost:3300" }
$LmStudioModelsUrl = if ($env:LMSTUDIO_MODELS_URL) { $env:LMSTUDIO_MODELS_URL } else { "http://localhost:1234/v1/models" }
$FortisaiLlamaServerUrl = if ($env:FORTISAI_LLAMA_SERVER_URL) { $env:FORTISAI_LLAMA_SERVER_URL } else { "http://host.docker.internal:8011" }
$FortisaiLlamaServerBaseUrl = if ($env:FORTISAI_LLAMA_SERVER_BASE_URL) { $env:FORTISAI_LLAMA_SERVER_BASE_URL } else { "$FortisaiLlamaServerUrl/v1" }
$FortisaiLlamaOpenAiBaseUrl = if ($env:FORTISAI_LLAMA_OPENAI_BASE_URL) { $env:FORTISAI_LLAMA_OPENAI_BASE_URL } else { $FortisaiLlamaServerBaseUrl }
$FortisaiLlamaOpenAiApiKey = if ($env:FORTISAI_LLAMA_OPENAI_API_KEY) { $env:FORTISAI_LLAMA_OPENAI_API_KEY } else { "local-llama" }
$OrdsUrl = if ($env:ORDS_URL) { $env:ORDS_URL } else { "http://127.0.0.1:8181/ords/" }
$ApexUrl = if ($env:APEX_URL) { $env:APEX_URL } else { "http://127.0.0.1:8181/ords/apex" }
$OracleNodeApiUrl = if ($env:ORACLE_NODE_API_URL) { $env:ORACLE_NODE_API_URL } else { "http://127.0.0.1:8090" }
$HonchoUrl = if ($env:HONCHO_URL) { $env:HONCHO_URL } else { "http://127.0.0.1:8010" }
$OpenClawUrl = if ($env:OPENCLAW_URL) { $env:OPENCLAW_URL } else { "http://127.0.0.1:18789" }
$HermesUrl = if ($env:HERMES_URL) { $env:HERMES_URL } else { "http://127.0.0.1:8642" }
$FirecrawlUrl = if ($env:FIRECRAWL_URL) { $env:FIRECRAWL_URL } else { "http://127.0.0.1:3002" }
$TraefikUrl = if ($env:TRAEFIK_URL) { $env:TRAEFIK_URL } else { "http://127.0.0.1:18000" }
$TraefikDashboardUrl = if ($env:TRAEFIK_DASHBOARD_URL) { $env:TRAEFIK_DASHBOARD_URL } else { "http://127.0.0.1:18088/dashboard/" }
$CodeIndexerOpenApiUrl = if ($env:CODEINDEXER_OPENAPI_URL) { $env:CODEINDEXER_OPENAPI_URL } else { "http://127.0.0.1:8096" }
$MilvusUrl = if ($env:MILVUS_URL) { $env:MILVUS_URL } else { "http://127.0.0.1:19091/healthz" }
$OpenMetadataUrl = if ($env:OPENMETADATA_URL) { $env:OPENMETADATA_URL } else { "http://127.0.0.1:18585" }
$OpenSearchUrl = if ($env:OPENSEARCH_URL) { $env:OPENSEARCH_URL } else { "http://127.0.0.1:9200" }
$OpenApiFilesystemUrl = if ($env:OPENAPI_FILESYSTEM_URL) { $env:OPENAPI_FILESYSTEM_URL } else { "http://127.0.0.1:8081" }
$OpenApiMemoryUrl = if ($env:OPENAPI_MEMORY_URL) { $env:OPENAPI_MEMORY_URL } else { "http://127.0.0.1:8082" }
$OpenApiTimeUrl = if ($env:OPENAPI_TIME_URL) { $env:OPENAPI_TIME_URL } else { "http://127.0.0.1:8083" }
$OpenApiOpenWebUiHostBase = if ($env:OPENAPI_OPENWEBUI_HOST_BASE) { $env:OPENAPI_OPENWEBUI_HOST_BASE } else { "http://host.containers.internal" }
$OpenApiFilesystemOpenWebUiUrl = if ($env:OPENAPI_FILESYSTEM_OPENWEBUI_URL) { $env:OPENAPI_FILESYSTEM_OPENWEBUI_URL } else { "${OpenApiOpenWebUiHostBase}:8081" }
$OpenApiMemoryOpenWebUiUrl = if ($env:OPENAPI_MEMORY_OPENWEBUI_URL) { $env:OPENAPI_MEMORY_OPENWEBUI_URL } else { "${OpenApiOpenWebUiHostBase}:8082" }
$OpenApiTimeOpenWebUiUrl = if ($env:OPENAPI_TIME_OPENWEBUI_URL) { $env:OPENAPI_TIME_OPENWEBUI_URL } else { "${OpenApiOpenWebUiHostBase}:8083" }

$DaytonaApiHostPort = if ($env:DAYTONA_API_HOST_PORT) { [int]$env:DAYTONA_API_HOST_PORT } else { 3300 }
$DaytonaProxyHostPort = if ($env:DAYTONA_PROXY_HOST_PORT) { [int]$env:DAYTONA_PROXY_HOST_PORT } else { 4400 }
$DaytonaSshHostPort = if ($env:DAYTONA_SSH_HOST_PORT) { [int]$env:DAYTONA_SSH_HOST_PORT } else { 2223 }
$DaytonaDexHostPort = if ($env:DAYTONA_DEX_HOST_PORT) { [int]$env:DAYTONA_DEX_HOST_PORT } else { 5556 }
$DaytonaPgAdminHostPort = if ($env:DAYTONA_PGADMIN_HOST_PORT) { [int]$env:DAYTONA_PGADMIN_HOST_PORT } else { 55050 }
$DaytonaRegistryUiHostPort = if ($env:DAYTONA_REGISTRY_UI_HOST_PORT) { [int]$env:DAYTONA_REGISTRY_UI_HOST_PORT } else { 55100 }
$DaytonaRegistryHostPort = if ($env:DAYTONA_REGISTRY_HOST_PORT) { [int]$env:DAYTONA_REGISTRY_HOST_PORT } else { 56000 }
$DaytonaMaildevHostPort = if ($env:DAYTONA_MAILDEV_HOST_PORT) { [int]$env:DAYTONA_MAILDEV_HOST_PORT } else { 11080 }
$DaytonaMinioConsoleHostPort = if ($env:DAYTONA_MINIO_CONSOLE_HOST_PORT) { [int]$env:DAYTONA_MINIO_CONSOLE_HOST_PORT } else { 59001 }
$DaytonaJaegerHostPort = if ($env:DAYTONA_JAEGER_HOST_PORT) { [int]$env:DAYTONA_JAEGER_HOST_PORT } else { 16687 }

$FortisaiSharedNetwork = if ($env:FORTISAI_SHARED_NETWORK) { $env:FORTISAI_SHARED_NETWORK } else { "fortisai-dev-net" }
$OracleDbContainerName = if ($env:ORACLE_DB_CONTAINER_NAME) { $env:ORACLE_DB_CONTAINER_NAME } else { "fortisai-oracle-db" }
$OracleDbImage = if ($env:ORACLE_DB_IMAGE) { $env:ORACLE_DB_IMAGE } else { "container-registry.oracle.com/database/free:latest" }
$OracleDbHostPort = if ($env:ORACLE_DB_HOST_PORT) { [int]$env:ORACLE_DB_HOST_PORT } else { 1521 }
$OracleDbPdb = if ($env:ORACLE_DB_PDB) { $env:ORACLE_DB_PDB } else { "FREEPDB1" }
$OracleDbUser = if ($env:ORACLE_DB_USER) { $env:ORACLE_DB_USER } else { "pdbadmin" }
$OracleDbPassword = if ($env:ORACLE_DB_PASSWORD) { $env:ORACLE_DB_PASSWORD } else { "FortisAI26ai!2026" }
$OrdsContainerName = if ($env:ORDS_CONTAINER_NAME) { $env:ORDS_CONTAINER_NAME } else { "fortisai-ords" }
$OrdsImage = if ($env:ORDS_IMAGE) { $env:ORDS_IMAGE } else { "container-registry.oracle.com/database/ords:latest" }
$OrdsHostPort = if ($env:ORDS_HOST_PORT) { [int]$env:ORDS_HOST_PORT } else { 8181 }
$OrdsConfigVolume = if ($env:ORDS_CONFIG_VOLUME) { $env:ORDS_CONFIG_VOLUME } else { "fortisai-ords-config" }
$OrdsDbUser = if ($env:ORDS_DB_USER) { $env:ORDS_DB_USER } else { "ORDS_PUBLIC_USER" }
$OrdsDbPassword = if ($env:ORDS_DB_PASSWORD) { $env:ORDS_DB_PASSWORD } else { $OracleDbPassword }
$SqlclContainerName = if ($env:SQLCL_CONTAINER_NAME) { $env:SQLCL_CONTAINER_NAME } else { "fortisai-sqlcl" }
$SqlclImage = if ($env:SQLCL_IMAGE) { $env:SQLCL_IMAGE } else { "container-registry.oracle.com/database/sqlcl:latest" }
$OracleNodeApiContainerName = if ($env:ORACLE_NODE_API_CONTAINER_NAME) { $env:ORACLE_NODE_API_CONTAINER_NAME } else { "fortisai-oracle-node-api" }
$AppsmithContainerName = if ($env:APPSMITH_CONTAINER_NAME) { $env:APPSMITH_CONTAINER_NAME } else { "fortisai-appsmith" }
$AppsmithImage = if ($env:APPSMITH_IMAGE) { $env:APPSMITH_IMAGE } else { "appsmith/appsmith-ce:latest" }
$AppsmithHostPort = if ($env:APPSMITH_HOST_PORT) { [int]$env:APPSMITH_HOST_PORT } else { 18080 }
$OpenVscodeContainerName = if ($env:OPENVSCODE_CONTAINER_NAME) { $env:OPENVSCODE_CONTAINER_NAME } else { "fortisai-openvscode" }
$OpenVscodeImage = if ($env:OPENVSCODE_IMAGE) { $env:OPENVSCODE_IMAGE } else { "gitpod/openvscode-server:latest" }
$OpenVscodeHostPort = if ($env:OPENVSCODE_HOST_PORT) { [int]$env:OPENVSCODE_HOST_PORT } else { 13000 }
$OpenWebUiContainerName = if ($env:OPENWEBUI_CONTAINER_NAME) { $env:OPENWEBUI_CONTAINER_NAME } else { "fortisai-openwebui" }
$OpenVscodeConnectionToken = if ($env:OPENVSCODE_CONNECTION_TOKEN) { $env:OPENVSCODE_CONNECTION_TOKEN } else { "fortisai-openvscode-dev-token" }
$OpenVscodeWorkspaceDir = if ($env:OPENVSCODE_WORKSPACE_DIR) { $env:OPENVSCODE_WORKSPACE_DIR } else { $HOME }
$OpenVscodeWorkspaceMountPath = if ($env:OPENVSCODE_WORKSPACE_MOUNT_PATH) { $env:OPENVSCODE_WORKSPACE_MOUNT_PATH } else { "/workspace" }
$OpenVscodeUsers = if ($env:OPENVSCODE_USERS) { $env:OPENVSCODE_USERS } else { if ($env:USERNAME) { $env:USERNAME } else { "aiuser" } }
$OpenVscodeServerBin = if ($env:OPENVSCODE_SERVER_BIN) { $env:OPENVSCODE_SERVER_BIN } else { "/home/.openvscode-server/bin/openvscode-server" }
$OpenVscodeUserDataDir = if ($env:OPENVSCODE_USER_DATA_DIR) { $env:OPENVSCODE_USER_DATA_DIR } else { "/home/openvscode-server/.openvscode-user-data" }
$OpenVscodeExtensionsDir = if ($env:OPENVSCODE_EXTENSIONS_DIR) { $env:OPENVSCODE_EXTENSIONS_DIR } else { "/home/openvscode-server/.openvscode-extensions" }
$MongodbContainerName = if ($env:MONGODB_CONTAINER_NAME) { $env:MONGODB_CONTAINER_NAME } else { "fortisai-mongodb" }
$MongodbImage = if ($env:MONGODB_IMAGE) { $env:MONGODB_IMAGE } else { "mongo:7" }
$MongodbHostPort = if ($env:MONGODB_HOST_PORT) { [int]$env:MONGODB_HOST_PORT } else { 27017 }
$MongodbDb = if ($env:MONGODB_DB) { $env:MONGODB_DB } else { "appsmith" }
$MongodbReplicaSet = if ($env:MONGODB_REPLICA_SET) { $env:MONGODB_REPLICA_SET } else { "rs0" }
$AppsmithDbUrl = if ($env:APPSMITH_DB_URL) { $env:APPSMITH_DB_URL } else { "mongodb://${MongodbContainerName}:27017/${MongodbDb}?replicaSet=$MongodbReplicaSet" }
$RedisContainerName = if ($env:REDIS_CONTAINER_NAME) { $env:REDIS_CONTAINER_NAME } else { "fortisai-redis" }
$RedisImage = if ($env:REDIS_IMAGE) { $env:REDIS_IMAGE } else { "redis:7-alpine" }
$RedisHostPort = if ($env:REDIS_HOST_PORT) { [int]$env:REDIS_HOST_PORT } else { 6379 }
$RabbitMqContainerName = if ($env:RABBITMQ_CONTAINER_NAME) { $env:RABBITMQ_CONTAINER_NAME } else { "fortisai-rabbitmq" }
$RabbitMqImage = if ($env:RABBITMQ_IMAGE) { $env:RABBITMQ_IMAGE } else { "rabbitmq:3.13-management-alpine" }
$RabbitMqHostPort = if ($env:RABBITMQ_HOST_PORT) { [int]$env:RABBITMQ_HOST_PORT } else { 5672 }
$RabbitMqManagementHostPort = if ($env:RABBITMQ_MANAGEMENT_HOST_PORT) { [int]$env:RABBITMQ_MANAGEMENT_HOST_PORT } else { 15672 }
$RabbitMqDefaultUser = if ($env:RABBITMQ_DEFAULT_USER) { $env:RABBITMQ_DEFAULT_USER } else { "fortisai" }
$RabbitMqDefaultPassword = if ($env:RABBITMQ_DEFAULT_PASSWORD) { $env:RABBITMQ_DEFAULT_PASSWORD } else { "fortisai" }
$VaultContainerName = if ($env:VAULT_CONTAINER_NAME) { $env:VAULT_CONTAINER_NAME } else { "fortisai-vault" }
$VaultImage = if ($env:VAULT_IMAGE) { $env:VAULT_IMAGE } else { "docker.io/hashicorp/vault:latest" }
$VaultHostPort = if ($env:VAULT_HOST_PORT) { [int]$env:VAULT_HOST_PORT } else { 8200 }
$VaultInternalUrl = if ($env:VAULT_INTERNAL_URL) { $env:VAULT_INTERNAL_URL } else { "http://${VaultContainerName}:8200" }
$VaultApiAddr = if ($env:VAULT_API_ADDR) { $env:VAULT_API_ADDR } else { "http://127.0.0.1:$VaultHostPort" }
$VaultToken = if ($env:VAULT_TOKEN) { $env:VAULT_TOKEN } else { "" }
$PgvectorContainerName = if ($env:PGVECTOR_CONTAINER_NAME) { $env:PGVECTOR_CONTAINER_NAME } else { "fortisai-pgvector" }
$PgvectorImage = if ($env:PGVECTOR_IMAGE) { $env:PGVECTOR_IMAGE } else { "pgvector/pgvector:pg16" }
$PgvectorHostPort = if ($env:PGVECTOR_HOST_PORT) { [int]$env:PGVECTOR_HOST_PORT } else { 5432 }
$PgvectorDb = if ($env:PGVECTOR_DB) { $env:PGVECTOR_DB } else { "fortisai" }
$PgvectorUser = if ($env:PGVECTOR_USER) { $env:PGVECTOR_USER } else { "fortisai" }
$PgvectorPassword = if ($env:PGVECTOR_PASSWORD) { $env:PGVECTOR_PASSWORD } else { "fortisai" }
$AppsmithPostgresDbUrl = if ($env:APPSMITH_POSTGRES_DB_URL) { $env:APPSMITH_POSTGRES_DB_URL } else { "postgresql://${PgvectorUser}:${PgvectorPassword}@${PgvectorContainerName}:5432/$PgvectorDb" }
$AppsmithRedisUrl = if ($env:APPSMITH_REDIS_URL) { $env:APPSMITH_REDIS_URL } else { "redis://${RedisContainerName}:6379" }
$AppsmithDisableTelemetry = if ($env:APPSMITH_DISABLE_TELEMETRY) { $env:APPSMITH_DISABLE_TELEMETRY } else { "true" }
$AppsmithSegmentCeKey = if ($env:APPSMITH_SEGMENT_CE_KEY) { $env:APPSMITH_SEGMENT_CE_KEY } else { "disabled" }
$AppsmithPylonAppId = if ($env:APPSMITH_PYLON_APP_ID) { $env:APPSMITH_PYLON_APP_ID } else { "disabled" }
$AppsmithBetterbugsApiKey = if ($env:APPSMITH_BETTERBUGS_API_KEY) { $env:APPSMITH_BETTERBUGS_API_KEY } else { "disabled" }
$AppsmithCloudServicesBaseUrl = if ($env:APPSMITH_CLOUD_SERVICES_BASE_URL) { $env:APPSMITH_CLOUD_SERVICES_BASE_URL } else { "" }
$HonchoDb = if ($env:HONCHO_DB) { $env:HONCHO_DB } else { "honcho" }
$HonchoApiContainerName = if ($env:HONCHO_API_CONTAINER_NAME) { $env:HONCHO_API_CONTAINER_NAME } else { "fortisai-honcho-api" }
$HonchoDeriverContainerName = if ($env:HONCHO_DERIVER_CONTAINER_NAME) { $env:HONCHO_DERIVER_CONTAINER_NAME } else { "fortisai-honcho-deriver" }
$HonchoHostPort = if ($env:HONCHO_HOST_PORT) { [int]$env:HONCHO_HOST_PORT } else { 8010 }
$HonchoLlmOpenaiApiKey = if ($env:HONCHO_LLM_OPENAI_API_KEY) { $env:HONCHO_LLM_OPENAI_API_KEY } else { "lmstudio" }
$HonchoLmStudioBaseUrl = if ($env:HONCHO_LMSTUDIO_BASE_URL) { $env:HONCHO_LMSTUDIO_BASE_URL } else { "http://host.docker.internal:1234/v1" }
$HonchoLmStudioModelsUrl = if ($env:HONCHO_LMSTUDIO_MODELS_URL) { $env:HONCHO_LMSTUDIO_MODELS_URL } else { $LmStudioModelsUrl }
$HonchoLmStudioModel = if ($env:HONCHO_LMSTUDIO_MODEL) { $env:HONCHO_LMSTUDIO_MODEL } else { "auto" }
$HonchoEmbedMessages = if ($env:HONCHO_EMBED_MESSAGES) { $env:HONCHO_EMBED_MESSAGES } else { "false" }
$FortisaiProxyOpenAiBaseUrl = if ($env:FORTISAI_PROXY_OPENAI_BASE_URL) { $env:FORTISAI_PROXY_OPENAI_BASE_URL } else { "http://fortisai-mcp-openapi-dify:8093/v1" }
$FortisaiProxyOpenAiApiKey = if ($env:FORTISAI_PROXY_OPENAI_API_KEY) { $env:FORTISAI_PROXY_OPENAI_API_KEY } else { "local-llama" }
$FortisaiProxyOpenAiModel = if ($env:FORTISAI_PROXY_OPENAI_MODEL) { $env:FORTISAI_PROXY_OPENAI_MODEL } else { "fortisai" }
$OpenClawContainerName = if ($env:OPENCLAW_CONTAINER_NAME) { $env:OPENCLAW_CONTAINER_NAME } else { "fortisai-claw-gateway" }
$OpenClawImage = if ($env:OPENCLAW_IMAGE) { $env:OPENCLAW_IMAGE } else { "docker.io/library/node:24-bookworm" }
$OpenClawGatewayPort = if ($env:OPENCLAW_GATEWAY_PORT) { [int]$env:OPENCLAW_GATEWAY_PORT } else { 18789 }
$OpenClawBridgePort = if ($env:OPENCLAW_BRIDGE_PORT) { [int]$env:OPENCLAW_BRIDGE_PORT } else { 18790 }
$OpenClawGatewayBind = if ($env:OPENCLAW_GATEWAY_BIND) { $env:OPENCLAW_GATEWAY_BIND } else { "0.0.0.0" }
$OpenClawGatewayToken = if ($env:OPENCLAW_GATEWAY_TOKEN) { $env:OPENCLAW_GATEWAY_TOKEN } else { "fortisai-claw-gateway-dev-token" }
$OpenClawGatewayPassword = if ($env:OPENCLAW_GATEWAY_PASSWORD) { $env:OPENCLAW_GATEWAY_PASSWORD } else { "" }
$OpenClawLmStudioBaseUrl = if ($env:OPENCLAW_LMSTUDIO_BASE_URL) { $env:OPENCLAW_LMSTUDIO_BASE_URL } else { $FortisaiProxyOpenAiBaseUrl }
$OpenClawLmStudioModel = if ($env:OPENCLAW_LMSTUDIO_MODEL) { $env:OPENCLAW_LMSTUDIO_MODEL } else { $FortisaiProxyOpenAiModel }
$OpenClawOpenAiApiKey = if ($env:OPENCLAW_OPENAI_API_KEY) { $env:OPENCLAW_OPENAI_API_KEY } else { $FortisaiProxyOpenAiApiKey }
$OpenClawHonchoPluginPackage = if ($env:OPENCLAW_HONCHO_PLUGIN_PACKAGE) { $env:OPENCLAW_HONCHO_PLUGIN_PACKAGE } else { "@honcho-ai/openclaw-honcho" }
$OpenClawHonchoBaseUrl = if ($env:OPENCLAW_HONCHO_BASE_URL) { $env:OPENCLAW_HONCHO_BASE_URL } else { "http://$HonchoApiContainerName:8000" }
$OpenClawHonchoWorkspaceId = if ($env:OPENCLAW_HONCHO_WORKSPACE_ID) { $env:OPENCLAW_HONCHO_WORKSPACE_ID } else { "openclaw" }
$OpenClawHonchoApiKey = if ($env:OPENCLAW_HONCHO_API_KEY) { $env:OPENCLAW_HONCHO_API_KEY } else { "" }
$HermesContainerName = if ($env:HERMES_CONTAINER_NAME) { $env:HERMES_CONTAINER_NAME } else { "fortisai-hermes" }
$HermesImage = if ($env:HERMES_IMAGE) { $env:HERMES_IMAGE } else { "nousresearch/hermes-agent:latest" }
$HermesGatewayPort = if ($env:HERMES_GATEWAY_PORT) { [int]$env:HERMES_GATEWAY_PORT } else { 8642 }
$HermesDashboardPort = if ($env:HERMES_DASHBOARD_PORT) { [int]$env:HERMES_DASHBOARD_PORT } else { 9119 }
$HermesDashboard = if ($env:HERMES_DASHBOARD) { $env:HERMES_DASHBOARD } else { "1" }
$HermesApiServerEnabled = if ($env:HERMES_API_SERVER_ENABLED) { $env:HERMES_API_SERVER_ENABLED } else { "true" }
$HermesApiServerHost = if ($env:HERMES_API_SERVER_HOST) { $env:HERMES_API_SERVER_HOST } else { "0.0.0.0" }
$HermesApiServerKey = if ($env:HERMES_API_SERVER_KEY) { $env:HERMES_API_SERVER_KEY } else { "fortisai-hermes-dev-api-key" }
$HermesApiServerCorsOrigins = if ($env:HERMES_API_SERVER_CORS_ORIGINS) { $env:HERMES_API_SERVER_CORS_ORIGINS } else { "*" }
$HermesHonchoBaseUrl = if ($env:HERMES_HONCHO_BASE_URL) { $env:HERMES_HONCHO_BASE_URL } else { "http://$HonchoApiContainerName:8000" }
$HermesHonchoWorkspaceId = if ($env:HERMES_HONCHO_WORKSPACE_ID) { $env:HERMES_HONCHO_WORKSPACE_ID } else { "hermes" }
$HermesHonchoApiKey = if ($env:HERMES_HONCHO_API_KEY) { $env:HERMES_HONCHO_API_KEY } else { "" }
$HermesDaytonaDashboardUrl = if ($env:HERMES_DAYTONA_DASHBOARD_URL) { $env:HERMES_DAYTONA_DASHBOARD_URL } else { $DaytonaUrl }
$HermesDaytonaApiUrl = if ($env:HERMES_DAYTONA_API_URL) { $env:HERMES_DAYTONA_API_URL } else { "http://host.docker.internal:$DaytonaApiHostPort" }
$HermesOpenAiBaseUrl = if ($env:HERMES_OPENAI_BASE_URL) { $env:HERMES_OPENAI_BASE_URL } else { $FortisaiProxyOpenAiBaseUrl }
$HermesOpenAiApiKey = if ($env:HERMES_OPENAI_API_KEY) { $env:HERMES_OPENAI_API_KEY } else { $FortisaiProxyOpenAiApiKey }
$HermesOpenAiModel = if ($env:HERMES_OPENAI_MODEL) { $env:HERMES_OPENAI_MODEL } else { $FortisaiProxyOpenAiModel }
$HermesWhatsappEnabled = if ($env:HERMES_WHATSAPP_ENABLED) { $env:HERMES_WHATSAPP_ENABLED } else { "false" }
$FirecrawlContainerName = if ($env:FIRECRAWL_CONTAINER_NAME) { $env:FIRECRAWL_CONTAINER_NAME } else { "fortisai-firecrawl" }
$FirecrawlImage = if ($env:FIRECRAWL_IMAGE) { $env:FIRECRAWL_IMAGE } else { "ghcr.io/firecrawl/firecrawl:latest" }
$FirecrawlHostPort = if ($env:FIRECRAWL_HOST_PORT) { [int]$env:FIRECRAWL_HOST_PORT } else { 3002 }
$FirecrawlApiKey = if ($env:FIRECRAWL_API_KEY) { $env:FIRECRAWL_API_KEY } else { "fortisai-firecrawl-dev-api-key" }
$FirecrawlInternalUrl = if ($env:FIRECRAWL_INTERNAL_URL) { $env:FIRECRAWL_INTERNAL_URL } else { "http://$FirecrawlContainerName:3002" }
$FirecrawlDbName = if ($env:FIRECRAWL_DB_NAME) { $env:FIRECRAWL_DB_NAME } else { "firecrawl" }
$FirecrawlDbUser = if ($env:FIRECRAWL_DB_USER) { $env:FIRECRAWL_DB_USER } else { $PgvectorUser }
$FirecrawlDbPassword = if ($env:FIRECRAWL_DB_PASSWORD) { $env:FIRECRAWL_DB_PASSWORD } else { $PgvectorPassword }
$FirecrawlDatabaseUrl = if ($env:FIRECRAWL_DATABASE_URL) { $env:FIRECRAWL_DATABASE_URL } else { "postgresql://${FirecrawlDbUser}:${FirecrawlDbPassword}@$PgvectorContainerName:5432/$FirecrawlDbName" }
$FirecrawlRabbitMqUser = if ($env:FIRECRAWL_RABBITMQ_USER) { $env:FIRECRAWL_RABBITMQ_USER } else { $RabbitMqDefaultUser }
$FirecrawlRabbitMqPassword = if ($env:FIRECRAWL_RABBITMQ_PASSWORD) { $env:FIRECRAWL_RABBITMQ_PASSWORD } else { $RabbitMqDefaultPassword }
$FirecrawlRabbitMqUrl = if ($env:FIRECRAWL_RABBITMQ_URL) { $env:FIRECRAWL_RABBITMQ_URL } else { "amqp://${FirecrawlRabbitMqUser}:${FirecrawlRabbitMqPassword}@$RabbitMqContainerName:5672" }
$FirecrawlRedisUrl = if ($env:FIRECRAWL_REDIS_URL) { $env:FIRECRAWL_REDIS_URL } else { "redis://${RedisContainerName}:6379" }
$FirecrawlRedisEvictUrl = if ($env:FIRECRAWL_REDIS_EVICT_URL) { $env:FIRECRAWL_REDIS_EVICT_URL } else { $FirecrawlRedisUrl }
$FirecrawlRedisRateLimitUrl = if ($env:FIRECRAWL_REDIS_RATE_LIMIT_URL) { $env:FIRECRAWL_REDIS_RATE_LIMIT_URL } else { $FirecrawlRedisUrl }
$FirecrawlNuqSqlUrl = if ($env:FIRECRAWL_NUQ_SQL_URL) { $env:FIRECRAWL_NUQ_SQL_URL } else { "https://raw.githubusercontent.com/firecrawl/firecrawl/main/apps/nuq-postgres/nuq.sql" }
$TraefikContainerName = if ($env:TRAEFIK_CONTAINER_NAME) { $env:TRAEFIK_CONTAINER_NAME } else { "fortisai-traefik" }
$TraefikImage = if ($env:TRAEFIK_IMAGE) { $env:TRAEFIK_IMAGE } else { "docker.io/library/traefik:latest" }
$TraefikWebHostPort = if ($env:TRAEFIK_WEB_HOST_PORT) { [int]$env:TRAEFIK_WEB_HOST_PORT } else { 18000 }
$TraefikDashboardHostPort = if ($env:TRAEFIK_DASHBOARD_HOST_PORT) { [int]$env:TRAEFIK_DASHBOARD_HOST_PORT } else { 18088 }
$TraefikDashboardUser = if ($env:TRAEFIK_DASHBOARD_USER) { $env:TRAEFIK_DASHBOARD_USER } else { "fortisai" }
$TraefikDashboardPassword = if ($env:TRAEFIK_DASHBOARD_PASSWORD) { $env:TRAEFIK_DASHBOARD_PASSWORD } else { "" }
$CodeIndexerRepoUrl = if ($env:CODEINDEXER_REPO_URL) { $env:CODEINDEXER_REPO_URL } else { "https://github.com/Indiejayk8s/CodeIndexer.git" }
$CodeIndexerBridgeContainerName = if ($env:CODEINDEXER_BRIDGE_CONTAINER_NAME) { $env:CODEINDEXER_BRIDGE_CONTAINER_NAME } else { "fortisai-mcp-openapi-codeindexer" }
$CodeIndexerBridgeHostPort = if ($env:CODEINDEXER_BRIDGE_HOST_PORT) { [int]$env:CODEINDEXER_BRIDGE_HOST_PORT } else { 8096 }
$CodeIndexerOpenAiBaseUrl = if ($env:CODEINDEXER_OPENAI_BASE_URL) { $env:CODEINDEXER_OPENAI_BASE_URL } else { "http://fortisai-mcp-openapi-dify:8093/v1" }
$CodeIndexerOpenAiApiKey = if ($env:CODEINDEXER_OPENAI_API_KEY) { $env:CODEINDEXER_OPENAI_API_KEY } else { "local-llama" }
$CodeIndexerOpenAiEmbeddingModel = if ($env:CODEINDEXER_OPENAI_EMBEDDING_MODEL) { $env:CODEINDEXER_OPENAI_EMBEDDING_MODEL } else { "fortisai" }
$CodeIndexerOpenAiEmbeddingDimension = if ($env:CODEINDEXER_OPENAI_EMBEDDING_DIMENSION) { $env:CODEINDEXER_OPENAI_EMBEDDING_DIMENSION } else { "1536" }
$CodeIndexerMilvusAddress = if ($env:CODEINDEXER_MILVUS_ADDRESS) { $env:CODEINDEXER_MILVUS_ADDRESS } else { "fortisai-milvus:19530" }
$CodeIndexerMilvusToken = if ($env:CODEINDEXER_MILVUS_TOKEN) { $env:CODEINDEXER_MILVUS_TOKEN } else { "" }
$CodeIndexerMcpTimeoutMs = if ($env:CODEINDEXER_MCP_TIMEOUT_MS) { $env:CODEINDEXER_MCP_TIMEOUT_MS } else { "900000" }
$MilvusEtcdContainerName = if ($env:MILVUS_ETCD_CONTAINER_NAME) { $env:MILVUS_ETCD_CONTAINER_NAME } else { "fortisai-milvus-etcd" }
$MilvusMinioContainerName = if ($env:MILVUS_MINIO_CONTAINER_NAME) { $env:MILVUS_MINIO_CONTAINER_NAME } else { "fortisai-milvus-minio" }
$MilvusContainerName = if ($env:MILVUS_CONTAINER_NAME) { $env:MILVUS_CONTAINER_NAME } else { "fortisai-milvus" }
$MilvusImage = if ($env:MILVUS_IMAGE) { $env:MILVUS_IMAGE } else { "docker.io/milvusdb/milvus:v2.4.15" }
$MilvusEtcdImage = if ($env:MILVUS_ETCD_IMAGE) { $env:MILVUS_ETCD_IMAGE } else { "quay.io/coreos/etcd:v3.5.18" }
$MilvusMinioImage = if ($env:MILVUS_MINIO_IMAGE) { $env:MILVUS_MINIO_IMAGE } else { "docker.io/minio/minio:latest" }
$MilvusHostPort = if ($env:MILVUS_HOST_PORT) { [int]$env:MILVUS_HOST_PORT } else { 19530 }
$MilvusHealthHostPort = if ($env:MILVUS_HEALTH_HOST_PORT) { [int]$env:MILVUS_HEALTH_HOST_PORT } else { 19091 }
$MilvusMinioRootUser = if ($env:MILVUS_MINIO_ROOT_USER) { $env:MILVUS_MINIO_ROOT_USER } else { "minioadmin" }
$MilvusMinioRootPassword = if ($env:MILVUS_MINIO_ROOT_PASSWORD) { $env:MILVUS_MINIO_ROOT_PASSWORD } else { "minioadmin" }
$OpenMetadataContainerName = if ($env:OPENMETADATA_CONTAINER_NAME) { $env:OPENMETADATA_CONTAINER_NAME } else { "fortisai-openmetadata" }
$OpenMetadataImage = if ($env:OPENMETADATA_IMAGE) { $env:OPENMETADATA_IMAGE } else { "docker.io/openmetadata/server:1.12.6" }
$OpenMetadataHostPort = if ($env:OPENMETADATA_HOST_PORT) { [int]$env:OPENMETADATA_HOST_PORT } else { 18585 }
$OpenMetadataAdminHostPort = if ($env:OPENMETADATA_ADMIN_HOST_PORT) { [int]$env:OPENMETADATA_ADMIN_HOST_PORT } else { 18586 }
$OpenMetadataDbName = if ($env:OPENMETADATA_DB_NAME) { $env:OPENMETADATA_DB_NAME } else { "openmetadata_db" }
$OpenMetadataFernetKey = if ($env:OPENMETADATA_FERNET_KEY) { $env:OPENMETADATA_FERNET_KEY } else { "" }
$OpenMetadataJwtKeyId = if ($env:OPENMETADATA_JWT_KEY_ID) { $env:OPENMETADATA_JWT_KEY_ID } else { "fortisai-local-dev" }
$OpenMetadataHeapOpts = if ($env:OPENMETADATA_HEAP_OPTS) { $env:OPENMETADATA_HEAP_OPTS } else { "-Xmx1G -Xms1G" }
$OpenSearchContainerName = if ($env:OPENSEARCH_CONTAINER_NAME) { $env:OPENSEARCH_CONTAINER_NAME } else { "fortisai-opensearch" }
$OpenSearchImage = if ($env:OPENSEARCH_IMAGE) { $env:OPENSEARCH_IMAGE } else { "docker.io/opensearchproject/opensearch:2" }
$OpenSearchHostPort = if ($env:OPENSEARCH_HOST_PORT) { [int]$env:OPENSEARCH_HOST_PORT } else { 9200 }
$OpenSearchPerformanceHostPort = if ($env:OPENSEARCH_PERFORMANCE_HOST_PORT) { [int]$env:OPENSEARCH_PERFORMANCE_HOST_PORT } else { 9600 }
$OpenSearchJavaOpts = if ($env:OPENSEARCH_JAVA_OPTS) { $env:OPENSEARCH_JAVA_OPTS } else { "-Xms512m -Xmx512m" }
$OpenWebUiLlmBackend = if ($env:OPENWEBUI_LLM_BACKEND) { $env:OPENWEBUI_LLM_BACKEND } else { "hermes" }
$SqlclMcpPythonCmd = if ($env:SQLCL_MCP_PYTHON_CMD) { $env:SQLCL_MCP_PYTHON_CMD } else { "python" }
$ApexDownloadUrl = if ($env:APEX_DOWNLOAD_URL) { $env:APEX_DOWNLOAD_URL } else { "https://download.oracle.com/otn_software/apex/apex-latest.zip" }
$ApexWorkDir = if ($env:APEX_WORK_DIR) { $env:APEX_WORK_DIR } else { Join-Path $OracleDbDir "apex" }
$ApexAdminPassword = if ($env:APEX_ADMIN_PASSWORD) { $env:APEX_ADMIN_PASSWORD } else { $OracleDbPassword }
$OcrRegistry = if ($env:OCR_REGISTRY) { $env:OCR_REGISTRY } else { "container-registry.oracle.com" }
$OcrUsername = if ($env:OCR_USERNAME) { $env:OCR_USERNAME } else { "" }
$OcrAuthToken = if ($env:OCR_AUTH_TOKEN) { $env:OCR_AUTH_TOKEN } else { "" }
$OracleWalletDir = if ($env:ORACLE_WALLET_DIR) { $env:ORACLE_WALLET_DIR } else { Join-Path $BaseDir "oracle-wallet" }
$OracleWalletEnvFile = if ($env:ORACLE_WALLET_ENV_FILE) { $env:ORACLE_WALLET_ENV_FILE } else { Join-Path $OracleWalletDir "wallet-env.sh" }
$OracleWalletSetupFile = if ($env:ORACLE_WALLET_SETUP_FILE) { $env:ORACLE_WALLET_SETUP_FILE } else { Join-Path $OracleWalletDir "wallet-setup.sh" }
$OracleWalletCredentialsHelpFile = if ($env:ORACLE_WALLET_CREDENTIALS_HELP_FILE) { $env:ORACLE_WALLET_CREDENTIALS_HELP_FILE } else { Join-Path $OracleWalletDir "oracle-wallet-credentials.sh" }
$OracleDbWalletEnvFile = if ($env:ORACLE_DB_WALLET_ENV_FILE) { $env:ORACLE_DB_WALLET_ENV_FILE } else { Join-Path $OracleWalletDir "oracle-db.env" }
$OracleDbWalletScriptFile = if ($env:ORACLE_DB_WALLET_SCRIPT_FILE) { $env:ORACLE_DB_WALLET_SCRIPT_FILE } else { Join-Path $OracleWalletDir "oracle-db-info.sh" }
$SqlclMcpServerFile = if ($env:SQLCL_MCP_SERVER_FILE) { $env:SQLCL_MCP_SERVER_FILE } else { Join-Path $McpRootDir "sqlcl-mcp/sqlcl-mcp-server.py" }
$McpSqlclOpenApiUrl = if ($env:MCP_SQLCL_OPENAPI_URL) { $env:MCP_SQLCL_OPENAPI_URL } else { "http://127.0.0.1:8091/openapi.json" }
$McpN8nOpenApiUrl = if ($env:MCP_N8N_OPENAPI_URL) { $env:MCP_N8N_OPENAPI_URL } else { "http://127.0.0.1:8092/openapi.json" }
$McpDifyOpenApiUrl = if ($env:MCP_DIFY_OPENAPI_URL) { $env:MCP_DIFY_OPENAPI_URL } else { "http://127.0.0.1:8093/openapi.json" }
$McpDebugOpenApiUrl = if ($env:MCP_DEBUG_OPENAPI_URL) { $env:MCP_DEBUG_OPENAPI_URL } else { "http://127.0.0.1:8094/openapi.json" }
$McpProxmoxOpenApiUrl = if ($env:MCP_PROXMOX_OPENAPI_URL) { $env:MCP_PROXMOX_OPENAPI_URL } else { "http://127.0.0.1:8095/openapi.json" }
$McpCodeIndexerOpenApiUrl = if ($env:MCP_CODEINDEXER_OPENAPI_URL) { $env:MCP_CODEINDEXER_OPENAPI_URL } else { "http://127.0.0.1:8096/openapi.json" }
$ProxmoxBridgeEnabled = if ($env:PROXMOX_BRIDGE_ENABLED) { $env:PROXMOX_BRIDGE_ENABLED } else { "auto" }
$ProxmoxHost = if ($env:PROXMOX_HOST) { $env:PROXMOX_HOST } else { "" }
$ProxmoxPort = if ($env:PROXMOX_PORT) { $env:PROXMOX_PORT } else { "" }
$ProxmoxUser = if ($env:PROXMOX_USER) { $env:PROXMOX_USER } else { "" }
$ProxmoxTokenName = if ($env:PROXMOX_TOKEN_NAME) { $env:PROXMOX_TOKEN_NAME } else { "" }
$ProxmoxTokenValue = if ($env:PROXMOX_TOKEN_VALUE) { $env:PROXMOX_TOKEN_VALUE } else { "" }
$ProxmoxVerifySsl = if ($env:PROXMOX_VERIFY_SSL) { $env:PROXMOX_VERIFY_SSL } else { "" }
$ProxmoxDevMode = if ($env:PROXMOX_DEV_MODE) { $env:PROXMOX_DEV_MODE } else { "" }
$ProxmoxService = if ($env:PROXMOX_SERVICE) { $env:PROXMOX_SERVICE } else { "" }
$ProxmoxApiKey = if ($env:PROXMOX_API_KEY) { $env:PROXMOX_API_KEY } else { "fortisai-proxmox-openapi-dev-key" }
$ProxmoxApiStrictAuth = if ($env:PROXMOX_API_STRICT_AUTH) { $env:PROXMOX_API_STRICT_AUTH } else { "false" }
$ProxmoxLogLevel = if ($env:LOG_LEVEL) { $env:LOG_LEVEL } else { "INFO" }

$PodmanCpus = if ($env:PODMAN_CPUS) { [int]$env:PODMAN_CPUS } else { 6 }
$PodmanMemoryMb = if ($env:PODMAN_MEMORY_MB) { [int]$env:PODMAN_MEMORY_MB } else { 12288 }
$PodmanDiskGb = if ($env:PODMAN_DISK_GB) { [int]$env:PODMAN_DISK_GB } else { 80 }

function Write-Log {
    param([string]$Message)
    Write-Host "[fortisai-dev] $Message"
}

function Throw-Error {
    param([string]$Message)
    throw "[fortisai-dev] ERROR: $Message"
}

function ConvertFrom-SecureStringToPlainText {
    param([Parameter(Mandatory = $true)][System.Security.SecureString]$SecureString)

    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

function New-HexKey {
    return ([guid]::NewGuid().ToString("N").ToLowerInvariant())
}

function New-UrlSafeSecret {
    param([int]$Bytes = 32)

    $buffer = New-Object byte[] $Bytes
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $rng.GetBytes($buffer)
    }
    finally {
        $rng.Dispose()
    }

    return ([Convert]::ToBase64String($buffer).TrimEnd("=") -replace "\+", "-" -replace "/", "_")
}

function Test-EnvProvided {
    param([Parameter(Mandatory = $true)][string]$Name)
    $value = [Environment]::GetEnvironmentVariable($Name, "Process")
    return -not [string]::IsNullOrEmpty($value)
}

function Set-RuntimeValue {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [AllowEmptyString()][string]$Value,
        [string]$EnvName = ""
    )

    if ($Name.StartsWith("env:")) {
        $targetEnvName = $Name.Substring(4)
        [Environment]::SetEnvironmentVariable($targetEnvName, $Value, "Process")
        return
    }

    Set-Variable -Name $Name -Value $Value -Scope Script
    if (-not $EnvName) {
        $EnvName = $Name
    }
    [Environment]::SetEnvironmentVariable($EnvName, $Value, "Process")
}

function Get-VaultRootToken {
    if (-not (Test-Path $VaultKeysFile)) {
        return ""
    }

    try {
        $payload = Get-Content -Path $VaultKeysFile -Raw | ConvertFrom-Json
        return ([string]$payload.root_token).Trim()
    }
    catch {
        return ""
    }
}

function Invoke-VaultCli {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$VaultArgs)

    $rootToken = Get-VaultRootToken
    if (-not $rootToken) {
        return $null
    }

    & podman exec `
        -e "VAULT_ADDR=http://127.0.0.1:8200" `
        -e "VAULT_TOKEN=$rootToken" `
        $VaultContainerName vault @VaultArgs
}

function Test-VaultToken {
    param([AllowEmptyString()][string]$Token)
    if (-not $Token) {
        return $false
    }

    & podman exec -e "VAULT_ADDR=http://127.0.0.1:8200" -e "VAULT_TOKEN=$Token" $VaultContainerName vault token lookup *> $null
    return $LASTEXITCODE -eq 0
}

function Enable-VaultKv {
    try {
        $mountsJson = Invoke-VaultCli secrets list -format=json 2>$null
        if ($LASTEXITCODE -eq 0 -and $mountsJson) {
            $mounts = $mountsJson | ConvertFrom-Json
            if (($mounts.PSObject.Properties.Name) -contains "secret/") {
                return
            }
        }
    }
    catch {
    }

    Invoke-VaultCli secrets enable -path=secret kv-v2 *> $null
}

function Get-VaultSecretValue {
    param([Parameter(Mandatory = $true)][string]$Path)

    try {
        $value = Invoke-VaultCli kv get "-field=value" "secret/fortisai/dev/$Path" 2>$null
        if ($LASTEXITCODE -eq 0 -and $value) {
            return (($value | Select-Object -First 1).ToString()).Trim()
        }
    }
    catch {
    }
    return ""
}

function Set-VaultSecretValue {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [AllowEmptyString()][string]$Value
    )

    if (-not $Value) {
        return
    }

    Invoke-VaultCli kv put "secret/fortisai/dev/$Path" "value=$Value" *> $null
}

function Remove-VaultSecretValue {
    param([Parameter(Mandatory = $true)][string]$Path)

    Invoke-VaultCli kv metadata delete "secret/fortisai/dev/$Path" *> $null
}

function Normalize-VaultSecretPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $normalized = $Path.Trim().TrimStart("/").Replace("\", "/")
    foreach ($prefix in @("secret/data/fortisai/dev/", "secret/fortisai/dev/", "fortisai/dev/")) {
        if ($normalized.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            $normalized = $normalized.Substring($prefix.Length)
            break
        }
    }

    if ([string]::IsNullOrWhiteSpace($normalized) -or $normalized.Contains("..") -or $normalized.StartsWith("/")) {
        Throw-Error "Invalid Vault path. Use a path under secret/fortisai/dev, for example: hermes/api_server_key"
    }

    return $normalized
}

function Ensure-VaultOperatorAccess {
    Ensure-PodmanMachine
    if (-not (Test-ContainerRunning -Name $VaultContainerName)) {
        Start-Vault
    }

    Wait-VaultReady

    if (-not (Test-VaultInitialized)) {
        Throw-Error "Vault is not initialized. Run: .\fortisai-dev-helper.ps1 vault-init"
    }

    if (Test-VaultSealed) {
        Unseal-Vault
    }

    Enable-VaultKv
}

function Read-VaultSecret {
    param([AllowEmptyString()][string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        Throw-Error "Missing Vault path. Usage: .\fortisai-dev-helper.ps1 vault-read <path>"
    }

    $relativePath = Normalize-VaultSecretPath -Path $Path
    Ensure-VaultOperatorAccess
    $value = Get-VaultSecretValue -Path $relativePath
    if ([string]::IsNullOrEmpty($value)) {
        Throw-Error "Vault secret not found or empty: secret/fortisai/dev/$relativePath"
    }

    Write-Output $value
}

function Write-VaultSecret {
    param(
        [AllowEmptyString()][string]$Path,
        [AllowEmptyString()][string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        Throw-Error "Missing Vault path. Usage: .\fortisai-dev-helper.ps1 vault-write <path> <value>"
    }

    $secretValue = $Value
    if ([string]::IsNullOrEmpty($secretValue) -and [Console]::IsInputRedirected) {
        $secretValue = [Console]::In.ReadToEnd().TrimEnd("`r", "`n")
    }

    if ([string]::IsNullOrEmpty($secretValue)) {
        Throw-Error "Missing Vault value. Pass it as the third argument or pipe it on stdin."
    }

    $relativePath = Normalize-VaultSecretPath -Path $Path
    Ensure-VaultOperatorAccess
    Set-VaultSecretValue -Path $relativePath -Value $secretValue
    Write-Log "Wrote Vault secret: secret/fortisai/dev/$relativePath"
}

function Remove-VaultSecret {
    param([AllowEmptyString()][string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        Throw-Error "Missing Vault path. Usage: .\fortisai-dev-helper.ps1 vault-del <path>"
    }

    $relativePath = Normalize-VaultSecretPath -Path $Path
    Ensure-VaultOperatorAccess
    Remove-VaultSecretValue -Path $relativePath
    Write-Log "Deleted Vault secret metadata and all versions: secret/fortisai/dev/$relativePath"
}

function Resolve-VaultRuntimeSecret {
    param(
        [Parameter(Mandatory = $true)][string]$VariableName,
        [Parameter(Mandatory = $true)][string]$VaultPath,
        [string]$EnvName = ""
    )

    $envOnly = $VariableName.StartsWith("env:")
    if (-not $EnvName) {
        if ($envOnly) {
            $EnvName = $VariableName.Substring(4)
        }
        else {
            $EnvName = $VariableName
        }
    }

    if ($envOnly) {
        $currentValue = [string][Environment]::GetEnvironmentVariable($EnvName, "Process")
    }
    else {
        $currentValue = [string](Get-Variable -Name $VariableName -Scope Script -ValueOnly -ErrorAction SilentlyContinue)
    }

    if ((Test-EnvProvided -Name $EnvName) -and $currentValue) {
        Set-VaultSecretValue -Path $VaultPath -Value $currentValue
        return
    }

    $vaultValue = Get-VaultSecretValue -Path $VaultPath
    if ($vaultValue) {
        Set-RuntimeValue -Name $VariableName -Value $vaultValue -EnvName $EnvName
        return
    }

    if ($currentValue) {
        Set-VaultSecretValue -Path $VaultPath -Value $currentValue
    }
}

function Ensure-VaultServiceToken {
    if ((Test-EnvProvided -Name "VAULT_TOKEN") -and $VaultToken) {
        return
    }

    $existingToken = Get-VaultSecretValue -Path "vault/service_token"
    if (Test-VaultToken -Token $existingToken) {
        Set-RuntimeValue -Name "VaultToken" -Value $existingToken -EnvName "VAULT_TOKEN"
        return
    }

    $rootToken = Get-VaultRootToken
    if (-not $rootToken) {
        Throw-Error "Vault root token was not found in $VaultKeysFile"
    }

    $policy = @"
path "secret/data/fortisai/dev/*" {
  capabilities = ["read"]
}

path "secret/metadata/fortisai/dev/*" {
  capabilities = ["list", "read"]
}
"@

    $policy | & podman exec -i -e "VAULT_ADDR=http://127.0.0.1:8200" -e "VAULT_TOKEN=$rootToken" $VaultContainerName vault policy write fortisai-dev-read - *> $null
    if ($LASTEXITCODE -ne 0) {
        Throw-Error "Could not write Vault read policy for local components"
    }

    $tokenJson = Invoke-VaultCli token create -policy=fortisai-dev-read -ttl=720h -renewable=true -format=json
    if ($LASTEXITCODE -ne 0 -or -not $tokenJson) {
        Throw-Error "Could not create Vault service token for local components"
    }

    $tokenObj = ($tokenJson | Out-String) | ConvertFrom-Json
    $serviceToken = [string]$tokenObj.auth.client_token
    if (-not $serviceToken) {
        Throw-Error "Could not parse Vault service token for local components"
    }

    Set-RuntimeValue -Name "VaultToken" -Value $serviceToken -EnvName "VAULT_TOKEN"
    Set-VaultSecretValue -Path "vault/service_token" -Value $serviceToken
}

function Assert-VaultSecretValue {
    param([string]$Path)

    $value = Get-VaultSecretValue -Path $Path
    if (-not $value) {
        Throw-Error "Vault secret missing after sync: secret/fortisai/dev/$Path"
    }
}

function Confirm-VaultRuntimeSecret {
    param(
        [string]$VariableName,
        [string]$EnvName,
        [string]$VaultPath
    )

    Resolve-VaultRuntimeSecret -VariableName $VariableName -EnvName $EnvName -VaultPath $VaultPath
    Assert-VaultSecretValue -Path $VaultPath
}

function Confirm-VaultRuntimeSecrets {
    Confirm-VaultRuntimeSecret -VariableName "N8nBasicAuthPassword" -EnvName "N8N_BASIC_AUTH_PASSWORD" -VaultPath "n8n/basic_auth_password"
    Confirm-VaultRuntimeSecret -VariableName "OracleDbPassword" -EnvName "ORACLE_DB_PASSWORD" -VaultPath "oracle/db_password"
    Confirm-VaultRuntimeSecret -VariableName "RabbitMqDefaultPassword" -EnvName "RABBITMQ_DEFAULT_PASSWORD" -VaultPath "rabbitmq/default_password"
    Confirm-VaultRuntimeSecret -VariableName "PgvectorPassword" -EnvName "PGVECTOR_PASSWORD" -VaultPath "pgvector/password"
    Confirm-VaultRuntimeSecret -VariableName "OrdsDbPassword" -EnvName "ORDS_DB_PASSWORD" -VaultPath "oracle/ords_db_password"
    Confirm-VaultRuntimeSecret -VariableName "ApexAdminPassword" -EnvName "APEX_ADMIN_PASSWORD" -VaultPath "oracle/apex_admin_password"
    Confirm-VaultRuntimeSecret -VariableName "QdrantApiKey" -EnvName "QDRANT_API_KEY" -VaultPath "qdrant/api_key"
    Confirm-VaultRuntimeSecret -VariableName "OpenVscodeConnectionToken" -EnvName "OPENVSCODE_CONNECTION_TOKEN" -VaultPath "openvscode/connection_token"
    Confirm-VaultRuntimeSecret -VariableName "AppsmithBetterbugsApiKey" -EnvName "APPSMITH_BETTERBUGS_API_KEY" -VaultPath "appsmith/betterbugs_api_key"
    Confirm-VaultRuntimeSecret -VariableName "HonchoLlmOpenaiApiKey" -EnvName "HONCHO_LLM_OPENAI_API_KEY" -VaultPath "honcho/llm_openai_api_key"
    Confirm-VaultRuntimeSecret -VariableName "OpenClawGatewayToken" -EnvName "OPENCLAW_GATEWAY_TOKEN" -VaultPath "claw-gateway/gateway_token"
    Confirm-VaultRuntimeSecret -VariableName "OpenClawOpenAiApiKey" -EnvName "OPENCLAW_OPENAI_API_KEY" -VaultPath "claw-gateway/openai_api_key"
    Confirm-VaultRuntimeSecret -VariableName "HermesApiServerKey" -EnvName "HERMES_API_SERVER_KEY" -VaultPath "hermes/api_server_key"
    Confirm-VaultRuntimeSecret -VariableName "FirecrawlApiKey" -EnvName "FIRECRAWL_API_KEY" -VaultPath "firecrawl/api_key"
    Confirm-VaultRuntimeSecret -VariableName "TraefikDashboardPassword" -EnvName "TRAEFIK_DASHBOARD_PASSWORD" -VaultPath "traefik/dashboard_password"
    Confirm-VaultRuntimeSecret -VariableName "CodeIndexerOpenAiApiKey" -EnvName "CODEINDEXER_OPENAI_API_KEY" -VaultPath "codeindexer/openai_api_key"
    Confirm-VaultRuntimeSecret -VariableName "MilvusMinioRootPassword" -EnvName "MILVUS_MINIO_ROOT_PASSWORD" -VaultPath "milvus/minio_root_password"
    Confirm-VaultRuntimeSecret -VariableName "OpenMetadataFernetKey" -EnvName "OPENMETADATA_FERNET_KEY" -VaultPath "openmetadata/fernet_key"
    Confirm-VaultRuntimeSecret -VariableName "env:APP_API_KEY" -VaultPath "dify/app_api_key"
    Confirm-VaultRuntimeSecret -VariableName "env:KNOWLEDGE_API_KEY" -VaultPath "dify/knowledge_api_key"
    Confirm-VaultRuntimeSecret -VariableName "env:DIFY_API_KEY" -VaultPath "dify/api_key"
    Assert-VaultSecretValue -Path "vault/service_token"
}

function Set-RuntimeSecretDefaults {
    if (-not $script:N8nBasicAuthPassword) { $script:N8nBasicAuthPassword = "change-me-n8n" }
    if (-not $script:OracleDbPassword) { $script:OracleDbPassword = "FortisAI26ai!2026" }
    if (-not $script:RabbitMqDefaultPassword) { $script:RabbitMqDefaultPassword = "fortisai" }
    if (-not $script:PgvectorPassword) { $script:PgvectorPassword = "fortisai" }
    if (-not $script:QdrantApiKey) { $script:QdrantApiKey = "difyai123456" }
    if (-not $script:OpenVscodeConnectionToken) { $script:OpenVscodeConnectionToken = "fortisai-openvscode-dev-token" }
    if (-not $script:AppsmithBetterbugsApiKey) { $script:AppsmithBetterbugsApiKey = "disabled" }
    if (-not $script:HonchoLlmOpenaiApiKey) { $script:HonchoLlmOpenaiApiKey = "lmstudio" }
    if (-not $script:OpenClawGatewayToken) { $script:OpenClawGatewayToken = "fortisai-claw-gateway-dev-token" }
    if (-not $script:OpenClawOpenAiApiKey) { $script:OpenClawOpenAiApiKey = "lmstudio" }
    if (-not $script:HermesApiServerKey) { $script:HermesApiServerKey = "fortisai-hermes-dev-api-key" }
    if (-not $script:FirecrawlApiKey) { $script:FirecrawlApiKey = "fortisai-firecrawl-dev-api-key" }
    if (-not $script:CodeIndexerOpenAiApiKey) { $script:CodeIndexerOpenAiApiKey = "local-llama" }
    if (-not $script:MilvusMinioRootPassword) { $script:MilvusMinioRootPassword = "minioadmin" }
    if (-not $script:TraefikDashboardPassword) { $script:TraefikDashboardPassword = New-UrlSafeSecret -Bytes 24 }
    if (-not $script:OpenMetadataFernetKey) { $script:OpenMetadataFernetKey = New-UrlSafeSecret -Bytes 32 }
}

function Update-DerivedSecretValues {
    if (-not (Test-EnvProvided -Name "ORDS_DB_PASSWORD")) {
        $script:OrdsDbPassword = $script:OracleDbPassword
    }
    if (-not (Test-EnvProvided -Name "APEX_ADMIN_PASSWORD")) {
        $script:ApexAdminPassword = $script:OracleDbPassword
    }
    if (-not (Test-EnvProvided -Name "FIRECRAWL_DB_PASSWORD")) {
        $script:FirecrawlDbPassword = $script:PgvectorPassword
    }
    if (-not (Test-EnvProvided -Name "FIRECRAWL_RABBITMQ_PASSWORD")) {
        $script:FirecrawlRabbitMqPassword = $script:RabbitMqDefaultPassword
    }
    if (-not (Test-EnvProvided -Name "RABBITMQ_URL")) {
        $script:RabbitMqUrl = "amqp://${RabbitMqDefaultUser}:${RabbitMqDefaultPassword}@127.0.0.1:5672"
    }
    if (-not (Test-EnvProvided -Name "PGVECTOR_URL")) {
        $script:PgvectorUrl = "postgresql://${PgvectorUser}:${PgvectorPassword}@127.0.0.1:5432/$PgvectorDb"
    }
    if (-not (Test-EnvProvided -Name "APPSMITH_POSTGRES_DB_URL")) {
        $script:AppsmithPostgresDbUrl = "postgresql://${PgvectorUser}:${PgvectorPassword}@${PgvectorContainerName}:5432/$PgvectorDb"
    }
    if (-not (Test-EnvProvided -Name "FIRECRAWL_DATABASE_URL")) {
        $script:FirecrawlDatabaseUrl = "postgresql://${FirecrawlDbUser}:${FirecrawlDbPassword}@$PgvectorContainerName:5432/$FirecrawlDbName"
    }
    if (-not (Test-EnvProvided -Name "FIRECRAWL_RABBITMQ_URL")) {
        $script:FirecrawlRabbitMqUrl = "amqp://${FirecrawlRabbitMqUser}:${FirecrawlRabbitMqPassword}@$RabbitMqContainerName:5672"
    }
    if (-not (Test-EnvProvided -Name "CODEINDEXER_OPENAI_BASE_URL")) {
        $script:CodeIndexerOpenAiBaseUrl = "http://fortisai-mcp-openapi-dify:8093/v1"
    }
    if (-not (Test-EnvProvided -Name "CODEINDEXER_MILVUS_ADDRESS")) {
        $script:CodeIndexerMilvusAddress = "${MilvusContainerName}:19530"
    }
}

function ConvertTo-OpenWebUiUserSecretSegment {
    param([AllowEmptyString()][string]$Value)

    return (($Value.Trim().ToLowerInvariant() -replace '[^a-z0-9]+', '_').Trim('_'))
}

function Sync-VaultRuntimeSecrets {
    Enable-VaultKv
    Set-RuntimeSecretDefaults
    Load-ProxmoxConfigFromJson

    Resolve-VaultRuntimeSecret -VariableName "N8nBasicAuthPassword" -EnvName "N8N_BASIC_AUTH_PASSWORD" -VaultPath "n8n/basic_auth_password"
    Resolve-VaultRuntimeSecret -VariableName "OracleDbPassword" -EnvName "ORACLE_DB_PASSWORD" -VaultPath "oracle/db_password"
    Resolve-VaultRuntimeSecret -VariableName "RabbitMqDefaultPassword" -EnvName "RABBITMQ_DEFAULT_PASSWORD" -VaultPath "rabbitmq/default_password"
    Resolve-VaultRuntimeSecret -VariableName "PgvectorPassword" -EnvName "PGVECTOR_PASSWORD" -VaultPath "pgvector/password"
    Update-DerivedSecretValues

    Resolve-VaultRuntimeSecret -VariableName "OrdsDbPassword" -EnvName "ORDS_DB_PASSWORD" -VaultPath "oracle/ords_db_password"
    Resolve-VaultRuntimeSecret -VariableName "ApexAdminPassword" -EnvName "APEX_ADMIN_PASSWORD" -VaultPath "oracle/apex_admin_password"
    Resolve-VaultRuntimeSecret -VariableName "QdrantApiKey" -EnvName "QDRANT_API_KEY" -VaultPath "qdrant/api_key"
    Resolve-VaultRuntimeSecret -VariableName "OpenVscodeConnectionToken" -EnvName "OPENVSCODE_CONNECTION_TOKEN" -VaultPath "openvscode/connection_token"
    Resolve-VaultRuntimeSecret -VariableName "AppsmithBetterbugsApiKey" -EnvName "APPSMITH_BETTERBUGS_API_KEY" -VaultPath "appsmith/betterbugs_api_key"
    Resolve-VaultRuntimeSecret -VariableName "HonchoLlmOpenaiApiKey" -EnvName "HONCHO_LLM_OPENAI_API_KEY" -VaultPath "honcho/llm_openai_api_key"
    Resolve-VaultRuntimeSecret -VariableName "env:N8N_API_KEY" -VaultPath "n8n/api_key"
    $openWebUiUserSegment = ConvertTo-OpenWebUiUserSecretSegment -Value $OpenWebUiApiUser
    if ($openWebUiUserSegment) {
        Resolve-VaultRuntimeSecret -VariableName "env:OPENWEBUI_BEARER_TOKEN" -VaultPath "openwebui/users/$openWebUiUserSegment/api_key"
    }
    Resolve-VaultRuntimeSecret -VariableName "env:OCR_AUTH_TOKEN" -VaultPath "oracle/ocr_auth_token"
    Resolve-VaultRuntimeSecret -VariableName "env:DAYTONA_API_KEY" -VaultPath "daytona/api_key"
    Resolve-VaultRuntimeSecret -VariableName "OpenClawGatewayToken" -EnvName "OPENCLAW_GATEWAY_TOKEN" -VaultPath "claw-gateway/gateway_token"
    Resolve-VaultRuntimeSecret -VariableName "OpenClawGatewayPassword" -EnvName "OPENCLAW_GATEWAY_PASSWORD" -VaultPath "claw-gateway/gateway_password"
    Resolve-VaultRuntimeSecret -VariableName "OpenClawOpenAiApiKey" -EnvName "OPENCLAW_OPENAI_API_KEY" -VaultPath "claw-gateway/openai_api_key"
    Resolve-VaultRuntimeSecret -VariableName "OpenClawHonchoApiKey" -EnvName "OPENCLAW_HONCHO_API_KEY" -VaultPath "claw-gateway/honcho_api_key"
    Resolve-VaultRuntimeSecret -VariableName "HermesApiServerKey" -EnvName "HERMES_API_SERVER_KEY" -VaultPath "hermes/api_server_key"
    Resolve-VaultRuntimeSecret -VariableName "HermesHonchoApiKey" -EnvName "HERMES_HONCHO_API_KEY" -VaultPath "hermes/honcho_api_key"
    Resolve-VaultRuntimeSecret -VariableName "FirecrawlApiKey" -EnvName "FIRECRAWL_API_KEY" -VaultPath "firecrawl/api_key"
    Resolve-VaultRuntimeSecret -VariableName "TraefikDashboardPassword" -EnvName "TRAEFIK_DASHBOARD_PASSWORD" -VaultPath "traefik/dashboard_password"
    Resolve-VaultRuntimeSecret -VariableName "CodeIndexerOpenAiApiKey" -EnvName "CODEINDEXER_OPENAI_API_KEY" -VaultPath "codeindexer/openai_api_key"
    Resolve-VaultRuntimeSecret -VariableName "CodeIndexerMilvusToken" -EnvName "CODEINDEXER_MILVUS_TOKEN" -VaultPath "codeindexer/milvus_token"
    Resolve-VaultRuntimeSecret -VariableName "MilvusMinioRootPassword" -EnvName "MILVUS_MINIO_ROOT_PASSWORD" -VaultPath "milvus/minio_root_password"
    Resolve-VaultRuntimeSecret -VariableName "OpenMetadataFernetKey" -EnvName "OPENMETADATA_FERNET_KEY" -VaultPath "openmetadata/fernet_key"
    Resolve-VaultRuntimeSecret -VariableName "ProxmoxHost" -EnvName "PROXMOX_HOST" -VaultPath "proxmox/host"
    Resolve-VaultRuntimeSecret -VariableName "ProxmoxPort" -EnvName "PROXMOX_PORT" -VaultPath "proxmox/port"
    Resolve-VaultRuntimeSecret -VariableName "ProxmoxUser" -EnvName "PROXMOX_USER" -VaultPath "proxmox/user"
    Resolve-VaultRuntimeSecret -VariableName "ProxmoxTokenName" -EnvName "PROXMOX_TOKEN_NAME" -VaultPath "proxmox/token_name"
    Resolve-VaultRuntimeSecret -VariableName "ProxmoxTokenValue" -EnvName "PROXMOX_TOKEN_VALUE" -VaultPath "proxmox/token_value"
    Resolve-VaultRuntimeSecret -VariableName "ProxmoxVerifySsl" -EnvName "PROXMOX_VERIFY_SSL" -VaultPath "proxmox/verify_ssl"
    Resolve-VaultRuntimeSecret -VariableName "ProxmoxDevMode" -EnvName "PROXMOX_DEV_MODE" -VaultPath "proxmox/dev_mode"
    Resolve-VaultRuntimeSecret -VariableName "ProxmoxService" -EnvName "PROXMOX_SERVICE" -VaultPath "proxmox/service"
    Resolve-VaultRuntimeSecret -VariableName "ProxmoxApiKey" -EnvName "PROXMOX_API_KEY" -VaultPath "proxmox/openapi_api_key"
    Resolve-VaultRuntimeSecret -VariableName "ProxmoxApiStrictAuth" -EnvName "PROXMOX_API_STRICT_AUTH" -VaultPath "proxmox/openapi_strict_auth"
    Resolve-VaultRuntimeSecret -VariableName "ProxmoxLogLevel" -EnvName "LOG_LEVEL" -VaultPath "proxmox/log_level"

    Resolve-VaultRuntimeSecret -VariableName "env:APP_API_KEY" -VaultPath "dify/app_api_key"
    Resolve-VaultRuntimeSecret -VariableName "env:KNOWLEDGE_API_KEY" -VaultPath "dify/knowledge_api_key"
    Resolve-VaultRuntimeSecret -VariableName "env:DIFY_API_KEY" -VaultPath "dify/api_key"
    Resolve-VaultRuntimeSecret -VariableName "env:DIFY_ADMIN_API_KEY" -VaultPath "dify/admin_api_key"
    Resolve-VaultRuntimeSecret -VariableName "env:DIFY_CONSOLE_ACCESS_TOKEN" -VaultPath "dify/console_access_token"
    Load-DifyApiKeyFromJson
    Resolve-VaultRuntimeSecret -VariableName "env:APP_API_KEY" -VaultPath "dify/app_api_key"
    Resolve-VaultRuntimeSecret -VariableName "env:KNOWLEDGE_API_KEY" -VaultPath "dify/knowledge_api_key"
    Resolve-VaultRuntimeSecret -VariableName "env:DIFY_API_KEY" -VaultPath "dify/api_key"
    Resolve-VaultRuntimeSecret -VariableName "env:DIFY_ADMIN_API_KEY" -VaultPath "dify/admin_api_key"
    Resolve-VaultRuntimeSecret -VariableName "env:DIFY_CONSOLE_ACCESS_TOKEN" -VaultPath "dify/console_access_token"
    $env:ADMIN_API_KEY = $env:DIFY_API_KEY
    $env:ADMIN_API_KEY_ENABLE = "true"
    Load-DifyApiKeyFromJson

    Update-DerivedSecretValues
    Ensure-VaultServiceToken
    Confirm-VaultRuntimeSecrets
    Write-Log "Vault-backed runtime secrets are ready"
}

function Prepare-VaultRuntimeSecrets {
    Ensure-PodmanMachine
    Ensure-SharedNetwork
    Write-VaultCompose
    Start-Vault
    Unseal-Vault
    Sync-VaultRuntimeSecrets
}

function Import-VaultRuntimeSecretsIfAvailable {
    if ((Test-Path $VaultKeysFile) -and (Test-ContainerRunning -Name $VaultContainerName) -and (Test-VaultInitialized) -and -not (Test-VaultSealed)) {
        try {
            Sync-VaultRuntimeSecrets
        }
        catch {
            Write-Log "Vault-backed runtime secret load skipped"
        }
    }
}

function Load-ProxmoxConfigFromJson {
    if (-not (Test-Path $ProxmoxMcpConfigFile)) {
        return
    }

    try {
        $payload = Get-Content -Path $ProxmoxMcpConfigFile -Raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        return
    }

    function Get-ProxmoxJsonProperty {
        param(
            [AllowNull()]$Object,
            [string]$Name
        )

        if ($null -eq $Object) {
            return $null
        }

        $property = $Object.PSObject.Properties[$Name]
        if ($null -eq $property) {
            return $null
        }

        return $property.Value
    }

    function Set-ProxmoxRuntimeIfUnset {
        param(
            [string]$VariableName,
            [string]$EnvName,
            [AllowNull()]$Value
        )

        if ($null -eq $Value) {
            return
        }
        if (Test-EnvProvided -Name $EnvName) {
            return
        }

        if ($Value -is [bool]) {
            $stringValue = if ($Value) { "true" } else { "false" }
        }
        else {
            $stringValue = ([string]$Value).Trim()
        }

        if ($stringValue) {
            Set-RuntimeValue -Name $VariableName -EnvName $EnvName -Value $stringValue
        }
    }

    $proxmox = Get-ProxmoxJsonProperty -Object $payload -Name "proxmox"
    $auth = Get-ProxmoxJsonProperty -Object $payload -Name "auth"
    $logging = Get-ProxmoxJsonProperty -Object $payload -Name "logging"
    $security = Get-ProxmoxJsonProperty -Object $payload -Name "security"

    Set-ProxmoxRuntimeIfUnset -VariableName "ProxmoxHost" -EnvName "PROXMOX_HOST" -Value (Get-ProxmoxJsonProperty -Object $proxmox -Name "host")
    Set-ProxmoxRuntimeIfUnset -VariableName "ProxmoxPort" -EnvName "PROXMOX_PORT" -Value (Get-ProxmoxJsonProperty -Object $proxmox -Name "port")
    Set-ProxmoxRuntimeIfUnset -VariableName "ProxmoxVerifySsl" -EnvName "PROXMOX_VERIFY_SSL" -Value (Get-ProxmoxJsonProperty -Object $proxmox -Name "verify_ssl")
    Set-ProxmoxRuntimeIfUnset -VariableName "ProxmoxService" -EnvName "PROXMOX_SERVICE" -Value (Get-ProxmoxJsonProperty -Object $proxmox -Name "service")
    Set-ProxmoxRuntimeIfUnset -VariableName "ProxmoxUser" -EnvName "PROXMOX_USER" -Value (Get-ProxmoxJsonProperty -Object $auth -Name "user")
    Set-ProxmoxRuntimeIfUnset -VariableName "ProxmoxTokenName" -EnvName "PROXMOX_TOKEN_NAME" -Value (Get-ProxmoxJsonProperty -Object $auth -Name "token_name")
    Set-ProxmoxRuntimeIfUnset -VariableName "ProxmoxTokenValue" -EnvName "PROXMOX_TOKEN_VALUE" -Value (Get-ProxmoxJsonProperty -Object $auth -Name "token_value")
    Set-ProxmoxRuntimeIfUnset -VariableName "ProxmoxLogLevel" -EnvName "LOG_LEVEL" -Value (Get-ProxmoxJsonProperty -Object $logging -Name "level")
    Set-ProxmoxRuntimeIfUnset -VariableName "ProxmoxDevMode" -EnvName "PROXMOX_DEV_MODE" -Value (Get-ProxmoxJsonProperty -Object $security -Name "dev_mode")
}

function Test-ProxmoxMcpConfigured {
    $mode = $ProxmoxBridgeEnabled.ToLowerInvariant()
    if ($mode -in @("1", "true", "yes", "on")) {
        return $true
    }
    if ($mode -in @("0", "false", "no", "off")) {
        return $false
    }

    if (Test-Path $ProxmoxMcpConfigFile) {
        return $true
    }

    return [bool]($ProxmoxHost -and $ProxmoxUser -and $ProxmoxTokenName -and $ProxmoxTokenValue)
}

function Resolve-DifyRuntimeApiKey {
    if (-not (Test-ContainerRunning -Name "docker_api_1")) {
        return ""
    }
    if (-not (Test-ContainerRunning -Name $PgvectorContainerName)) {
        return ""
    }

    $dbName = (& podman exec docker_api_1 sh -lc 'printf %s "$DB_DATABASE"' 2>$null | Select-Object -First 1).Trim()
    $dbUser = (& podman exec docker_api_1 sh -lc 'printf %s "$DB_USERNAME"' 2>$null | Select-Object -First 1).Trim()
    if (-not $dbName -or -not $dbUser) {
        return ""
    }

    $sql = "WITH target AS (SELECT id AS app_id, tenant_id FROM apps ORDER BY created_at DESC LIMIT 1), existing AS (SELECT token FROM api_tokens WHERE type='app' AND app_id=(SELECT app_id FROM target) ORDER BY created_at DESC LIMIT 1), inserted AS (INSERT INTO api_tokens (app_id, tenant_id, type, token) SELECT app_id, tenant_id, 'app', 'app-' || substring(md5(random()::text || clock_timestamp()::text) from 1 for 24) FROM target WHERE NOT EXISTS (SELECT 1 FROM existing) RETURNING token) SELECT COALESCE((SELECT token FROM existing), (SELECT token FROM inserted), '');"
    $runtimeKey = (& podman exec $PgvectorContainerName psql -U $dbUser -d $dbName -tAc $sql 2>$null | Select-Object -First 1).Trim()
    if ($runtimeKey -like 'app-*') {
        return $runtimeKey
    }

    return ""
}

function Resolve-DifyRuntimeAdminApiKey {
    if (-not (Test-ContainerRunning -Name "docker_api_1")) {
        return ""
    }

    $adminKey = (& podman exec docker_api_1 sh -lc 'printf %s "$ADMIN_API_KEY"' 2>$null | Select-Object -First 1).Trim()
    if ($adminKey) {
        return $adminKey
    }

    return ""
}

function Resolve-DifyRuntimeWorkspaceId {
    if (-not (Test-ContainerRunning -Name "docker_api_1")) {
        return ""
    }
    if (-not (Test-ContainerRunning -Name $PgvectorContainerName)) {
        return ""
    }

    $dbName = (& podman exec docker_api_1 sh -lc 'printf %s "$DB_DATABASE"' 2>$null | Select-Object -First 1).Trim()
    $dbUser = (& podman exec docker_api_1 sh -lc 'printf %s "$DB_USERNAME"' 2>$null | Select-Object -First 1).Trim()
    if (-not $dbName -or -not $dbUser) {
        return ""
    }

    $workspaceId = (& podman exec $PgvectorContainerName psql -U $dbUser -d $dbName -tAc "SELECT id FROM tenants ORDER BY created_at DESC LIMIT 1;" 2>$null | Select-Object -First 1).Trim()
    if ($workspaceId) {
        return $workspaceId
    }

    return ""
}

function Ensure-DifyApiKeysJson {
    New-Item -ItemType Directory -Force -Path $DifyMcpDir | Out-Null

    $payloadObj = @{}
    if (Test-Path $DifyApiKeyJsonFile) {
        try {
            $existingPayload = Get-Content -Raw -Path $DifyApiKeyJsonFile | ConvertFrom-Json -ErrorAction Stop
            foreach ($p in $existingPayload.PSObject.Properties) {
                $payloadObj[$p.Name] = $p.Value
            }
        }
        catch {
        }
    }

    $appKey = if ($env:APP_API_KEY) { $env:APP_API_KEY } else { [string]$payloadObj["dify_app_api_key"] }
    if (-not $appKey) {
        $appKey = New-HexKey
    }

    $knowledgeKey = if ($env:KNOWLEDGE_API_KEY) { $env:KNOWLEDGE_API_KEY } else { [string]$payloadObj["dify_knowledge_api_key"] }
    if (-not $knowledgeKey) {
        $knowledgeKey = New-HexKey
    }

    $apiKey = if ($env:DIFY_API_KEY) { $env:DIFY_API_KEY } elseif ($env:ADMIN_API_KEY) { $env:ADMIN_API_KEY } else { [string]$payloadObj["dify_api_key"] }
    if (-not $apiKey) {
        $apiKey = [string]$payloadObj["dify_admin_api_key"]
    }
    if (-not $apiKey) {
        $apiKey = [string]$payloadObj["admin_api_key"]
    }
    if (-not $apiKey) {
        $apiKey = New-HexKey
    }

    $payloadObj["dify_app_api_key"] = $appKey
    $payloadObj["dify_knowledge_api_key"] = $knowledgeKey
    $payloadObj["dify_api_key"] = $apiKey
    $payloadObj["updated_at"] = (Get-Date).ToUniversalTime().ToString("o")

    $payload = $payloadObj | ConvertTo-Json -Depth 4
    Set-Content -Path $DifyApiKeyJsonFile -Value ($payload + "`n")

    return $payloadObj
}

function Get-DifyApiKeyFromJson {
    if (-not (Test-Path $DifyApiKeyJsonFile)) {
        return ""
    }

    try {
        $content = Get-Content -Path $DifyApiKeyJsonFile -Raw -ErrorAction Stop
        $obj = $content | ConvertFrom-Json -ErrorAction Stop
        $key = [string]$obj.dify_app_api_key
        return $key.Trim()
    }
    catch {
        return ""
    }
}

function Get-DifyKnowledgeApiKeyFromJson {
    if (-not (Test-Path $DifyApiKeyJsonFile)) {
        return ""
    }

    try {
        $content = Get-Content -Path $DifyApiKeyJsonFile -Raw -ErrorAction Stop
        $obj = $content | ConvertFrom-Json -ErrorAction Stop
        $key = [string]$obj.dify_knowledge_api_key
        return $key.Trim()
    }
    catch {
        return ""
    }
}

function Get-DifyAdminApiKeyFromJson {
    if (-not (Test-Path $DifyApiKeyJsonFile)) {
        return ""
    }

    try {
        $content = Get-Content -Path $DifyApiKeyJsonFile -Raw -ErrorAction Stop
        $obj = $content | ConvertFrom-Json -ErrorAction Stop
        $key = [string]$obj.dify_api_key
        if (-not $key) { $key = [string]$obj.dify_admin_api_key }
        if (-not $key) { $key = [string]$obj.admin_api_key }
        return $key.Trim()
    }
    catch {
        return ""
    }
}

function Load-DifyApiKeyFromJson {
    $payload = Ensure-DifyApiKeysJson

    $runtimeKey = Resolve-DifyRuntimeApiKey
    if ($runtimeKey) {
        $payload["dify_app_api_key"] = $runtimeKey
        $payload["dify_api_key"] = $runtimeKey
        $payload["updated_at"] = (Get-Date).ToUniversalTime().ToString("o")
        $payloadJson = $payload | ConvertTo-Json -Depth 4
        Set-Content -Path $DifyApiKeyJsonFile -Value ($payloadJson + "`n")
    }

    $appKey = [string]$payload["dify_app_api_key"]
    $knowledgeKey = [string]$payload["dify_knowledge_api_key"]
    $adminKey = [string]$payload["dify_api_key"]

    if ($appKey) {
        $env:APP_API_KEY = $appKey
    }
    if ($knowledgeKey) {
        $env:KNOWLEDGE_API_KEY = $knowledgeKey
    }
    if ($adminKey) {
        $env:DIFY_API_KEY = $adminKey
        $env:ADMIN_API_KEY = $adminKey
    }
    $env:ADMIN_API_KEY_ENABLE = "true"
}

function Set-DifyApiKey {
    $existingKey = Get-DifyApiKeyFromJson
    if ($existingKey) {
        $change = Read-Host "Dify API key file already exists. Change key? [y/N]"
        if ($change -notmatch '^[Yy]$') {
            $env:DIFY_API_KEY = $existingKey
            $env:ADMIN_API_KEY = $existingKey
            $env:ADMIN_API_KEY_ENABLE = "true"
            Write-Log "Keeping existing Dify API key in $DifyApiKeyJsonFile"
            return
        }
    }

    $secureOne = Read-Host "Dify app API key" -AsSecureString
    $difyApiKey = ConvertFrom-SecureStringToPlainText -SecureString $secureOne
    if (-not $difyApiKey) {
        Throw-Error "Dify app API key cannot be empty"
    }

    $secureTwo = Read-Host "Confirm Dify app API key" -AsSecureString
    $difyApiKeyConfirm = ConvertFrom-SecureStringToPlainText -SecureString $secureTwo
    if ($difyApiKey -ne $difyApiKeyConfirm) {
        Throw-Error "Dify app API key values do not match"
    }

    New-Item -ItemType Directory -Force -Path $DifyMcpDir | Out-Null
    $payloadObj = @{}
    if (Test-Path $DifyApiKeyJsonFile) {
        try {
            $existingPayload = Get-Content -Raw -Path $DifyApiKeyJsonFile | ConvertFrom-Json -ErrorAction Stop
            foreach ($p in $existingPayload.PSObject.Properties) {
                $payloadObj[$p.Name] = $p.Value
            }
        }
        catch {
        }
    }
    $payloadObj["dify_app_api_key"] = $difyApiKey
    $payloadObj["dify_api_key"] = $difyApiKey
    $payloadObj["updated_at"] = (Get-Date).ToUniversalTime().ToString("o")
    $payload = $payloadObj | ConvertTo-Json -Depth 4
    Set-Content -Path $DifyApiKeyJsonFile -Value ($payload + "`n")

    $env:APP_API_KEY = $difyApiKey
    $env:DIFY_API_KEY = $difyApiKey
    $env:ADMIN_API_KEY = $difyApiKey
    $env:ADMIN_API_KEY_ENABLE = "true"
    Write-Log "Saved Dify app API key to $DifyApiKeyJsonFile"
    Write-Log "DIFY_API_KEY is now available to helper commands in this run"
    Write-Log "Other helper commands auto-load DIFY_API_KEY from this JSON file"
}

function Set-OrAddEnvVar {
    param(
        [string]$FilePath,
        [string]$Key,
        [string]$Value
    )

    $content = if (Test-Path $FilePath) { Get-Content -Path $FilePath -Raw } else { "" }
    if ($content -match "(?m)^$([regex]::Escape($Key))=") {
        $content = [regex]::Replace($content, "(?m)^$([regex]::Escape($Key))=.*$", "$Key=$Value")
    }
    else {
        $content = $content.TrimEnd() + "`r`n$Key=$Value`r`n"
    }
    Set-Content -Path $FilePath -Value $content -Encoding UTF8
}

function Require-Command {
    param([string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        Throw-Error "Missing required command: $Name"
    }
}

function Get-ComposeRunner {
    # Detect whether podman compose uses the native plugin or delegates to external podman-compose.
    # Delegation output contains the text "podman-compose"; the native plugin does not.
    $pcOut = (& podman compose version 2>&1) -join " "
    if ($pcOut -notmatch "podman-compose" -and $pcOut -match "version") {
        return "podman"
    }

    # podman is delegating to external podman-compose (or podman compose is unavailable).
    # Check version: 1.5.x has profile/depends_on bugs that break Dify.
    if (Get-Command podman-compose -ErrorAction SilentlyContinue) {
        $pcVerLine = (& podman-compose version 2>&1) -join " "
        if ($pcVerLine -match '(\d+)\.(\d+)') {
            $major = [int]$Matches[1]
            $minor = [int]$Matches[2]
            if ($major -ge 1 -and $minor -ge 5) {
                # Prefer docker compose (Docker Desktop) which handles profiles correctly.
                if (Get-Command docker -ErrorAction SilentlyContinue) {
                    try {
                        & docker compose version *> $null
                        Write-Log "podman-compose $major.$minor has known Dify incompatibilities; using 'docker compose' instead"
                        return "docker"
                    } catch {}
                }
                throw "[fortisai-dev] ERROR: podman-compose $major.$minor has known incompatibilities with Dify (profile/depends_on bugs).`nFix option 1: install Docker Desktop from https://www.docker.com/products/docker-desktop`nFix option 2: pip install podman-compose<1.5"
            }
        }
        return "podman-compose"
    }

    Throw-Error "No compose implementation found. Install Docker Desktop or podman-compose."
}

function Invoke-Compose {
    param(
        [string[]]$Args
    )

    $runner = Get-ComposeRunner
    switch ($runner) {
        "podman"         { & podman compose @Args }
        "docker"         { & docker compose @Args }
        "podman-compose" { & podman-compose @Args }
    }
}

function Test-DockerComposeAvailable {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        return $false
    }

    try {
        & docker compose version *> $null
        return $true
    }
    catch {
        return $false
    }
}

function Ensure-PodmanMachine {
    Require-Command podman

    $machines = & podman machine list --format "{{.Name}}"
    if (-not $machines) {
        Write-Log "Initializing Podman machine"
        & podman machine init --cpus $PodmanCpus --memory $PodmanMemoryMb --disk-size $PodmanDiskGb | Out-Null
    }

    Write-Log "Starting Podman machine"
    try {
        & podman machine start | Out-Null
    }
    catch {
        # start may fail if already running
    }

    try {
        & podman info *> $null
    }
    catch {
        Throw-Error "Podman machine is not ready. Run 'podman machine start' manually and retry."
    }
}

function Ensure-SharedNetwork {
    & podman network exists $FortisaiSharedNetwork *> $null
    if ($LASTEXITCODE -eq 0) {
        return
    }

    Write-Log "Creating shared development network: $FortisaiSharedNetwork"
    & podman network create $FortisaiSharedNetwork *> $null
    if ($LASTEXITCODE -ne 0) {
        & podman network exists $FortisaiSharedNetwork *> $null
        if ($LASTEXITCODE -eq 0) {
            return
        }
        Throw-Error "Failed to create shared development network: $FortisaiSharedNetwork"
    }
}

function Test-ContainerRunning {
    param([string]$Name)

    $state = & podman inspect -f "{{.State.Running}}" $Name 2>$null
    $stateLine = $state | Select-Object -First 1
    if (-not $stateLine) {
        return $false
    }
    return ($stateLine.Trim() -eq "true")
}

function Test-ContainerExists {
    param([string]$Name)

    & podman container exists $Name *> $null
    return ($LASTEXITCODE -eq 0)
}

function Test-ContainerHasVaultRuntimeEnv {
    param([string]$Name)

    $envLines = & podman inspect --format "{{range .Config.Env}}{{println .}}{{end}}" $Name 2>$null
    return (($envLines -match "^VAULT_TOKEN=.") -and ($envLines -match "^VAULT_ADDR=.") -and ($envLines -match "^FORTISAI_VAULT_ADDR=."))
}

function Test-ContainerNeedsVaultRuntimeRefresh {
    param(
        [string]$Name,
        [string]$ComposeFile
    )

    if (-not $VaultToken) { return $false }
    if (-not (Test-ContainerExists -Name $Name)) { return $false }
    if (-not (Test-Path $ComposeFile)) { return $false }
    $composeText = Get-Content -Path $ComposeFile -Raw
    if ($composeText -notmatch "VAULT_TOKEN") { return $false }
    return -not (Test-ContainerHasVaultRuntimeEnv -Name $Name)
}

function Refresh-ContainerVaultRuntimeEnv {
    param(
        [string]$Name,
        [string]$ComposeFile
    )

    if (Test-ContainerNeedsVaultRuntimeRefresh -Name $Name -ComposeFile $ComposeFile) {
        Write-Log "Recreating container to apply Vault runtime env: $Name"
        & podman rm -f $Name *> $null
    }
}

function Refresh-DifyVaultRuntimeEnv {
    if (-not (Test-Path $DifyVaultComposeFile)) {
        return
    }

    $difyContainers = @("docker_api_1", "docker_worker_1", "docker_worker_beat_1", "docker_web_1", "docker_sandbox_1", "docker_plugin_daemon_1")
    $needsRefresh = $false
    foreach ($containerName in $difyContainers) {
        if (Test-ContainerNeedsVaultRuntimeRefresh -Name $containerName -ComposeFile $DifyVaultComposeFile) {
            $needsRefresh = $true
            break
        }
    }

    if ($needsRefresh) {
        Write-Log "Recreating Dify containers to apply Vault runtime env"
        Push-Location $DifyDockerDir
        $difyComposeArgs = @(Get-DifyComposeFileArgs)
        Invoke-Compose -Args ($difyComposeArgs + @("--profile", "qdrant", "down", "--remove-orphans"))
        Pop-Location
    }
}

function Start-ComposeContainer {
    param(
        [string]$ComposeFile,
        [string]$ContainerName
    )

    if (Test-ContainerRunning -Name $ContainerName) {
        if (Test-ContainerNeedsVaultRuntimeRefresh -Name $ContainerName -ComposeFile $ComposeFile) {
            Write-Log "Recreating container to apply Vault runtime env: $ContainerName"
            & podman rm -f $ContainerName *> $null
        }
        else {
            return
        }
    }

    if ((Test-ContainerExists -Name $ContainerName) -and (Test-ContainerNeedsVaultRuntimeRefresh -Name $ContainerName -ComposeFile $ComposeFile)) {
        Write-Log "Removing existing container to apply Vault runtime env: $ContainerName"
        & podman rm -f $ContainerName *> $null
    }

    if (Test-ContainerExists -Name $ContainerName) {
        & podman start $ContainerName *> $null
        Start-Sleep -Seconds 1
        if (Test-ContainerRunning -Name $ContainerName) {
            return
        }

        Write-Log "Removing non-startable existing container: $ContainerName"
        & podman rm -f $ContainerName *> $null
    }

    Invoke-Compose -Args @("-f", $ComposeFile, "up", "-d")
    if (-not (Test-ContainerRunning -Name $ContainerName)) {
        Throw-Error "Container is not running after startup attempt: $ContainerName"
    }
}

function Get-DifyComposeFileArgs {
    $composeArgs = @()
    if (Test-Path (Join-Path $DifyDockerDir "docker-compose.yaml")) {
        $composeArgs += @("-f", "docker-compose.yaml")
    }
    elseif (Test-Path (Join-Path $DifyDockerDir "docker-compose.yml")) {
        $composeArgs += @("-f", "docker-compose.yml")
    }

    if (Test-Path $DifyVaultComposeFile) {
        $composeArgs += @("-f", "docker-compose.fortisai-vault.yaml")
    }

    return $composeArgs
}

function Wait-OracleDbReady {
    $maxAttempts = 60

    Write-Log "Waiting for Oracle DB to accept connections"
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        & podman exec $OracleDbContainerName bash -lc "printf 'select 1 from dual;`nexit`n' | sqlplus -L -s \"pdbadmin/$OracleDbPassword@$OracleDbPdb\"" *> $null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Oracle DB is ready"
            return
        }

        Start-Sleep -Seconds 5
    }

    Throw-Error "Oracle DB did not become ready in time"
}

function Pull-OracleDbImage {
    Require-Command podman

    & podman image exists $OracleDbImage *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Oracle DB image already present: $OracleDbImage"
        return
    }

    Write-Log "Oracle DB image not found locally; attempting pull: $OracleDbImage"

    if ($OcrUsername -and $OcrAuthToken) {
        Write-Log "Logging into OCR registry ($OcrRegistry) with OCR_USERNAME and OCR_AUTH_TOKEN"
        $OcrAuthToken | & podman login $OcrRegistry --username $OcrUsername --password-stdin *> $null
        if ($LASTEXITCODE -ne 0) {
            Throw-Error "OCR login failed for $OcrRegistry. Verify OCR_USERNAME/OCR_AUTH_TOKEN and ensure terms are accepted for the repository."
        }
    }
    else {
        Write-Log "OCR credentials not set (OCR_USERNAME/OCR_AUTH_TOKEN); trying anonymous pull"
    }

    & podman pull $OracleDbImage
    if ($LASTEXITCODE -ne 0) {
        Throw-Error "Failed to pull Oracle DB image: $OracleDbImage. If first pull, accept terms at https://container-registry.oracle.com/ords/ocr/ba/database/free and set OCR credentials."
    }

    Write-Log "Pulled Oracle DB image successfully: $OracleDbImage"
}

function Pull-OrdsSqlclImages {
    Require-Command podman

    & podman image exists $OrdsImage *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Log "ORDS image already present: $OrdsImage"
    }
    else {
        Write-Log "Pulling ORDS image: $OrdsImage"
        & podman pull $OrdsImage
    }

    & podman image exists $SqlclImage *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Log "SQLcl image already present: $SqlclImage"
    }
    else {
        Write-Log "Pulling SQLcl image: $SqlclImage"
        & podman pull $SqlclImage
    }
}

function Initialize-OrdsConfig {
    Require-Command podman

    & podman volume create $OrdsConfigVolume *> $null

    $dbHost = $OracleDbContainerName
    $dbPort = $OracleDbHostPort
    $dbServiceName = $OracleDbPdb

    if (Test-Path $OracleDbWalletEnvFile) {
        Get-Content $OracleDbWalletEnvFile | ForEach-Object {
            if ($_ -match '^ORACLE_DB_HOST=(.*)$') { $dbHost = $Matches[1] }
            elseif ($_ -match '^ORACLE_DB_PORT=(.*)$') { $dbPort = [int]$Matches[1] }
            elseif ($_ -match '^ORACLE_DB_SERVICE_NAME=(.*)$') { $dbServiceName = $Matches[1] }
        }
    }

    $hasConfig = & podman run --rm -v "${OrdsConfigVolume}:/etc/ords/config" $OrdsImage /bin/sh -lc "if [ -f /etc/ords/config/global/settings.xml ]; then echo 1; else echo 0; fi"
    if (($hasConfig | Select-Object -Last 1).Trim() -eq "1") {
        Write-Log "ORDS config already exists in volume: $OrdsConfigVolume"
        return
    }

    Write-Log "Initializing ORDS config volume: $OrdsConfigVolume"

    $stdinData = @"
$OracleDbPassword
$OracleDbPassword
$OrdsDbPassword
$OrdsDbPassword
$OrdsDbPassword
"@

    $stdinData | & podman run -i --rm --network $FortisaiSharedNetwork -v "${OrdsConfigVolume}:/etc/ords/config" $OrdsImage --config /etc/ords/config install --admin-user SYS --db-hostname $dbHost --db-port $dbPort --db-servicename $dbServiceName --db-user $OrdsDbUser --proxy-user --feature-sdw true --password-stdin *> $null
}

function Write-N8nCompose {
    New-Item -ItemType Directory -Force -Path $N8nDir | Out-Null
    $repoRootMount = $RepoRootDir.Replace('\', '/')
    @"
services:
  n8n:
    image: n8nio/n8n:latest
    container_name: fortisai-n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - N8N_HOST=localhost
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - NODE_ENV=development
      - GENERIC_TIMEZONE=UTC
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=$N8nBasicAuthUser
      - N8N_BASIC_AUTH_PASSWORD=$N8nBasicAuthPassword
      - FORTISAI_SHARED_NETWORK=$FortisaiSharedNetwork
      - FORTISAI_ORACLE_DB_HOST=$OracleDbContainerName
      - FORTISAI_ORACLE_DB_PORT=$OracleDbHostPort
      - FORTISAI_ORACLE_DB_PDB=$OracleDbPdb
      - FORTISAI_ORACLE_DB_USER=$OracleDbUser
      - FORTISAI_ORACLE_DB_PASSWORD=$OracleDbPassword
      - FORTISAI_REDIS_URL=redis://${RedisContainerName}:6379
      - FORTISAI_PGVECTOR_DSN=postgresql://${PgvectorUser}:${PgvectorPassword}@${PgvectorContainerName}:5432/$PgvectorDb
      - FORTISAI_QDRANT_URL=$QdrantInternalUrl
      - FORTISAI_LLAMA_SERVER_URL=$FortisaiLlamaServerUrl
      - FORTISAI_LLAMA_SERVER_BASE_URL=$FortisaiLlamaServerBaseUrl
      - FORTISAI_LLAMA_OPENAI_BASE_URL=$FortisaiLlamaOpenAiBaseUrl
      - FORTISAI_LLAMA_OPENAI_API_KEY=$FortisaiLlamaOpenAiApiKey
      - FORTISAI_REPO_ROOT=/FortisAI
      - FORTISAI_N8N_CONFIG_DIR=/FortisAI/Development_Environment/n8n-config
      - FORTISAI_DIFY_CONFIG_DIR=/FortisAI/Development_Environment/dify-config
      - FORTISAI_VAULT_ADDR=$VaultInternalUrl
      - VAULT_ADDR=$VaultInternalUrl
      - VAULT_TOKEN=$VaultToken
      - QDRANT_URL=$QdrantInternalUrl
      - QDRANT_API_KEY=$QdrantApiKey
    volumes:
      - n8n_data:/home/node/.n8n
      - "$repoRootMount/Development_Environment/n8n-config:/FortisAI/Development_Environment/n8n-config:rw"
      - "$repoRootMount/Development_Environment/dify-config:/FortisAI/Development_Environment/dify-config:rw"
  n8n-workflow-runner:
    image: n8nio/n8n:latest
    container_name: fortisai-n8n-workflow-runner
    restart: unless-stopped
    entrypoint: ["/usr/local/bin/node"]
    command: ["/FortisAI/Development_Environment/n8n-config/main/n8n/scripts/local-workflow-runner.mjs"]
    depends_on:
      - n8n
    environment:
      - N8N_HOST=localhost
      - NODE_ENV=development
      - GENERIC_TIMEZONE=UTC
      - FORTISAI_REPO_ROOT=/FortisAI
      - FORTISAI_N8N_CONFIG_DIR=/FortisAI/Development_Environment/n8n-config
      - FORTISAI_DIFY_CONFIG_DIR=/FortisAI/Development_Environment/dify-config
      - FORTISAI_LLAMA_SERVER_URL=$FortisaiLlamaServerUrl
      - FORTISAI_LLAMA_SERVER_BASE_URL=$FortisaiLlamaServerBaseUrl
      - FORTISAI_LLAMA_OPENAI_BASE_URL=$FortisaiLlamaOpenAiBaseUrl
      - FORTISAI_LLAMA_OPENAI_API_KEY=$FortisaiLlamaOpenAiApiKey
    volumes:
      - "$repoRootMount/Development_Environment/n8n-config:/FortisAI/Development_Environment/n8n-config:rw"
      - "$repoRootMount/Development_Environment/dify-config:/FortisAI/Development_Environment/dify-config:rw"
volumes:
  n8n_data:
networks:
    default:
        name: $FortisaiSharedNetwork
        external: true
"@ | Set-Content -Path $N8nComposeFile -Encoding UTF8
}

function Write-OpenWebUiCompose {
    $resolvedOpenAiBaseUrl = ""
    $resolvedOpenAiApiKey = ""

    switch ($OpenWebUiLlmBackend.ToLowerInvariant()) {
        "hermes" {
            $resolvedOpenAiBaseUrl = "http://$HermesContainerName:8642/v1"
            $resolvedOpenAiApiKey = $HermesApiServerKey
        }
        "openclaw" {
            $resolvedOpenAiBaseUrl = "http://$OpenClawContainerName:18789/v1"
            $resolvedOpenAiApiKey = $OpenClawGatewayToken
        }
        default {
            Throw-Error "Unsupported OPENWEBUI_LLM_BACKEND: $OpenWebUiLlmBackend (use openclaw or hermes)"
        }
    }

    New-Item -ItemType Directory -Force -Path $OpenWebUiDir | Out-Null
    @"
services:
  openwebui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: fortisai-openwebui
    restart: unless-stopped
    ports:
      - "3000:8080"
    environment:
      - WEBUI_AUTH=true
      - ENABLE_SIGNUP=true
                        - ENABLE_OPENAI_API=true
                                                - OPENAI_API_BASE_URL=$resolvedOpenAiBaseUrl
                                                - OPENAI_API_KEY=$resolvedOpenAiApiKey
                        - FIRECRAWL_BASE_URL=$FirecrawlInternalUrl
                        - FIRECRAWL_API_KEY=$FirecrawlApiKey
            - FORTISAI_SHARED_NETWORK=$FortisaiSharedNetwork
            - FORTISAI_ORACLE_DB_HOST=fortisai-oracle-db
            - FORTISAI_ORACLE_DB_PORT=$OracleDbHostPort
            - FORTISAI_ORACLE_DB_PDB=$OracleDbPdb
            - FORTISAI_ORACLE_DB_USER=$OracleDbUser
            - FORTISAI_ORACLE_DB_PASSWORD=$OracleDbPassword
            - FORTISAI_REDIS_URL=redis://${RedisContainerName}:6379
            - FORTISAI_PGVECTOR_DSN=postgresql://${PgvectorUser}:${PgvectorPassword}@${PgvectorContainerName}:5432/$PgvectorDb
            - FORTISAI_VAULT_ADDR=$VaultInternalUrl
            - VAULT_ADDR=$VaultInternalUrl
            - VAULT_TOKEN=$VaultToken
    volumes:
      - openwebui_data:/app/backend/data
volumes:
  openwebui_data:
networks:
    default:
        name: $FortisaiSharedNetwork
        external: true
"@ | Set-Content -Path $OpenWebUiComposeFile -Encoding UTF8
}

function Get-OpenVscodeUserEntries {
    return ($OpenVscodeUsers -replace ',', ' ').Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)
}

function New-OpenVscodeUserSlug {
    param([string]$Value)

    if (-not $Value) { $Value = "user" }
    $slug = $Value.ToLowerInvariant() -replace '[^a-z0-9]+', '-'
    $slug = $slug.Trim('-')
    if (-not $slug) { $slug = "user" }
    return $slug
}

function Get-OpenVscodeUserRecords {
    param([switch]$RefreshTokens)

    $entries = @(Get-OpenVscodeUserEntries)
    if ($entries.Count -eq 0) {
        $entries = @($(if ($env:USERNAME) { $env:USERNAME } else { "aiuser" }))
    }

    $records = @()
    $seen = @{}
    $index = 0
    foreach ($entry in $entries) {
        $parts = $entry.Split(':', 4)
        $userName = if ($parts.Count -ge 1 -and $parts[0]) { $parts[0] } else { if ($env:USERNAME) { $env:USERNAME } else { "aiuser" } }
        $slug = New-OpenVscodeUserSlug -Value $userName
        if ($seen.ContainsKey($slug)) {
            Throw-Error "Duplicate OpenVSCode user slug in OPENVSCODE_USERS: $slug"
        }
        $seen[$slug] = $true

        $userPort = if ($parts.Count -ge 2 -and $parts[1]) { [int]$parts[1] } else { $OpenVscodeHostPort + $index }
        $userToken = if ($parts.Count -ge 3) { $parts[2] } else { "" }
        $userWorkspace = if ($parts.Count -ge 4 -and $parts[3]) { $parts[3] } else { $OpenVscodeWorkspaceDir }
        $serviceName = if ($index -eq 0) { "openvscode" } else { "openvscode-$slug" }
        $containerName = if ($index -eq 0) { $OpenVscodeContainerName } else { "$OpenVscodeContainerName-$slug" }
        $userDir = Join-Path (Join-Path $OpenVscodeDir "users") $slug
        $tokenFile = Join-Path $userDir "connection-token"

        New-Item -ItemType Directory -Force -Path $userDir | Out-Null
        New-Item -ItemType Directory -Force -Path $userWorkspace | Out-Null

        if ($userToken -and $RefreshTokens) {
            Set-Content -Path $tokenFile -Value $userToken -Encoding Ascii -NoNewline
        }
        elseif ($index -eq 0 -and -not (Test-Path $tokenFile)) {
            Set-Content -Path $tokenFile -Value $OpenVscodeConnectionToken -Encoding Ascii -NoNewline
        }
        elseif ($index -eq 0 -and $RefreshTokens -and $OpenVscodeConnectionToken -ne "fortisai-openvscode-dev-token") {
            Set-Content -Path $tokenFile -Value $OpenVscodeConnectionToken -Encoding Ascii -NoNewline
        }
        elseif (-not (Test-Path $tokenFile)) {
            Set-Content -Path $tokenFile -Value (New-UrlSafeSecret -Bytes 24) -Encoding Ascii -NoNewline
        }

        $records += [pscustomobject]@{
            Index = $index
            UserName = $userName
            Slug = $slug
            Port = $userPort
            TokenFile = $tokenFile
            Workspace = $userWorkspace
            ContainerName = $containerName
            ServiceName = $serviceName
        }
        $index += 1
    }

    return $records
}

function Get-OpenVscodeContainerForUser {
    param([string]$User = "")

    $targetSlug = if ($User) { New-OpenVscodeUserSlug -Value $User } else { "" }
    foreach ($record in Get-OpenVscodeUserRecords) {
        if (-not $User -and $record.Index -eq 0) { return $record.ContainerName }
        if ($User -eq $record.UserName -or $User -eq $record.Slug -or $targetSlug -eq $record.Slug) {
            return $record.ContainerName
        }
    }

    return ""
}

function Show-OpenVscodeUsers {
    Write-OpenVscodeCompose
    Get-OpenVscodeUserRecords | Format-Table UserName, Port, ContainerName, TokenFile, Workspace -AutoSize
}

function Write-OpenVscodeCompose {
    New-Item -ItemType Directory -Force -Path $OpenVscodeDir | Out-Null
    $lines = New-Object System.Collections.Generic.List[string]
    $volumeLines = New-Object System.Collections.Generic.List[string]
    $lines.Add("services:")

    foreach ($record in Get-OpenVscodeUserRecords -RefreshTokens) {
        $serverVolume = if ($record.Index -eq 0) { "openvscode_data" } else { "openvscode_server_$($record.Slug)" }
        $userDataVolume = "openvscode_user_data_$($record.Slug)"
        $extensionsVolume = "openvscode_extensions_$($record.Slug)"
        $tokenHost = $record.TokenFile.Replace('\', '/')
        $workspaceHost = $record.Workspace.Replace('\', '/')

        $lines.Add("    $($record.ServiceName):")
        $lines.Add("        image: $OpenVscodeImage")
        $lines.Add("        container_name: $($record.ContainerName)")
        $lines.Add("        restart: unless-stopped")
        $lines.Add("        ports:")
        $lines.Add("            - `"$($record.Port):3000`"")
        $lines.Add("        environment:")
        $lines.Add("            - OPENVSCODE_USER=$($record.UserName)")
        $lines.Add("            - OPENVSCODE_USER_SLUG=$($record.Slug)")
        $lines.Add("            - OPENVSCODE_USER_DATA_DIR=$OpenVscodeUserDataDir")
        $lines.Add("            - OPENVSCODE_EXTENSIONS_DIR=$OpenVscodeExtensionsDir")
        $lines.Add("            - FORTISAI_SHARED_NETWORK=$FortisaiSharedNetwork")
        $lines.Add("            - FORTISAI_VAULT_ADDR=$VaultInternalUrl")
        $lines.Add("            - VAULT_ADDR=$VaultInternalUrl")
        $lines.Add("            - VAULT_TOKEN=$VaultToken")
        $lines.Add("        entrypoint: $OpenVscodeServerBin")
        $lines.Add("        command:")
        $lines.Add("            - --host")
        $lines.Add("            - 0.0.0.0")
        $lines.Add("            - --port")
        $lines.Add("            - `"3000`"")
        $lines.Add("            - --connection-token-file")
        $lines.Add("            - /run/fortisai-openvscode/connection-token")
        $lines.Add("            - --telemetry-level")
        $lines.Add("            - `"off`"")
        $lines.Add("            - --user-data-dir")
        $lines.Add("            - $OpenVscodeUserDataDir")
        $lines.Add("            - --extensions-dir")
        $lines.Add("            - $OpenVscodeExtensionsDir")
        $lines.Add("        volumes:")
        $lines.Add("            - ${serverVolume}:/home/.openvscode-server")
        $lines.Add("            - ${userDataVolume}:$OpenVscodeUserDataDir")
        $lines.Add("            - ${extensionsVolume}:$OpenVscodeExtensionsDir")
        $lines.Add("            - ${tokenHost}:/run/fortisai-openvscode/connection-token:ro")
        $lines.Add("            - ${workspaceHost}:$OpenVscodeWorkspaceMountPath")

        $volumeLines.Add("    ${serverVolume}:")
        $volumeLines.Add("    ${userDataVolume}:")
        $volumeLines.Add("    ${extensionsVolume}:")
    }

    $lines.Add("volumes:")
    foreach ($line in $volumeLines) { $lines.Add($line) }
    $lines.Add("networks:")
    $lines.Add("    default:")
    $lines.Add("        name: $FortisaiSharedNetwork")
    $lines.Add("        external: true")
    Set-Content -Path $OpenVscodeComposeFile -Value ($lines -join [Environment]::NewLine) -Encoding UTF8
}

function Start-OpenVscode {
    Write-OpenVscodeCompose
    Invoke-Compose -Args @("-f", $OpenVscodeComposeFile, "up", "-d")
    Show-OpenVscodeUsers
}

function Stop-OpenVscode {
    if (Test-Path $OpenVscodeComposeFile) {
        try {
            Invoke-Compose -Args @("-f", $OpenVscodeComposeFile, "down")
        }
        catch {
            Write-Log "OpenVSCode compose shutdown failed; forcing container removal"
        }
    }

    foreach ($record in Get-OpenVscodeUserRecords) {
        & podman rm -f $record.ContainerName *> $null
    }
    & podman rm -f $OpenVscodeContainerName *> $null
}

function Install-OpenVscodeExtension {
    param([string]$TargetOrExtension, [string]$MaybeExtension)

    $targetUser = ""
    $extension = $TargetOrExtension
    if ($MaybeExtension) {
        $targetUser = $TargetOrExtension
        $extension = $MaybeExtension
    }
    if (-not $extension) {
        Throw-Error "Usage: .\fortisai-dev-helper.ps1 openvscode-install-extension [user] <extension-id-or-vsix>"
    }

    $containerName = Get-OpenVscodeContainerForUser -User $targetUser
    if (-not $containerName) { Throw-Error "Unknown OpenVSCode user: $(if ($targetUser) { $targetUser } else { 'default' })" }
    if (-not (Test-ContainerRunning -Name $containerName)) { Throw-Error "OpenVSCode container is not running: $containerName" }

    $containerExtension = $extension
    if (Test-Path $extension) {
        $containerExtension = "/tmp/$(Split-Path -Leaf $extension)"
        & podman cp $extension "${containerName}:$containerExtension"
    }

    & podman exec $containerName $OpenVscodeServerBin --user-data-dir $OpenVscodeUserDataDir --extensions-dir $OpenVscodeExtensionsDir --install-extension $containerExtension --force
    if (Test-Path $extension) {
        & podman exec $containerName rm -f $containerExtension *> $null
    }
}

function Uninstall-OpenVscodeExtension {
    param([string]$TargetOrExtension, [string]$MaybeExtension)

    $targetUser = ""
    $extension = $TargetOrExtension
    if ($MaybeExtension) {
        $targetUser = $TargetOrExtension
        $extension = $MaybeExtension
    }
    if (-not $extension) {
        Throw-Error "Usage: .\fortisai-dev-helper.ps1 openvscode-uninstall-extension [user] <extension-id>"
    }

    $containerName = Get-OpenVscodeContainerForUser -User $targetUser
    if (-not $containerName) { Throw-Error "Unknown OpenVSCode user: $(if ($targetUser) { $targetUser } else { 'default' })" }
    if (-not (Test-ContainerRunning -Name $containerName)) { Throw-Error "OpenVSCode container is not running: $containerName" }

    & podman exec $containerName $OpenVscodeServerBin --user-data-dir $OpenVscodeUserDataDir --extensions-dir $OpenVscodeExtensionsDir --uninstall-extension $extension
}

function List-OpenVscodeExtensions {
    param([string]$User = "")

    $containerName = Get-OpenVscodeContainerForUser -User $User
    if (-not $containerName) { Throw-Error "Unknown OpenVSCode user: $(if ($User) { $User } else { 'default' })" }
    if (-not (Test-ContainerRunning -Name $containerName)) { Throw-Error "OpenVSCode container is not running: $containerName" }

    & podman exec $containerName $OpenVscodeServerBin --user-data-dir $OpenVscodeUserDataDir --extensions-dir $OpenVscodeExtensionsDir --list-extensions
}

function Start-OpenWebUi {
    $resolvedOpenAiBaseUrl = ""
    $resolvedOpenAiApiKey = ""

    switch ($OpenWebUiLlmBackend.ToLowerInvariant()) {
        "hermes" {
            $resolvedOpenAiBaseUrl = "http://$HermesContainerName:8642/v1"
            $resolvedOpenAiApiKey = $HermesApiServerKey
        }
        "openclaw" {
            $resolvedOpenAiBaseUrl = "http://$OpenClawContainerName:18789/v1"
            $resolvedOpenAiApiKey = $OpenClawGatewayToken
        }
        default {
            Throw-Error "Unsupported OPENWEBUI_LLM_BACKEND: $OpenWebUiLlmBackend (use openclaw or hermes)"
        }
    }

    try {
        Refresh-ContainerVaultRuntimeEnv -Name "fortisai-openwebui" -ComposeFile $OpenWebUiComposeFile
        Invoke-Compose -Args @("-f", $OpenWebUiComposeFile, "up", "-d")
        if (Test-ContainerRunning -Name "fortisai-openwebui") {
            return
        }

        Write-Log "OpenWebUI compose completed without a running container; falling back to direct podman run"
    }
    catch {
        Write-Log "OpenWebUI compose startup failed; falling back to direct podman run"
    }

    & podman rm -f fortisai-openwebui *> $null
    & podman volume create fortisai-openwebui-data *> $null

    $runArgs = @(
        "run", "-d",
        "--name", "fortisai-openwebui",
        "--restart", "unless-stopped",
        "--network", $FortisaiSharedNetwork,
        "-p", "3000:8080",
        "-e", "WEBUI_AUTH=true",
        "-e", "ENABLE_SIGNUP=true",
        "-e", "ENABLE_OPENAI_API=true",
        "-e", "OPENAI_API_BASE_URL=$resolvedOpenAiBaseUrl",
        "-e", "OPENAI_API_KEY=$resolvedOpenAiApiKey",
        "-e", "FIRECRAWL_BASE_URL=$FirecrawlInternalUrl",
        "-e", "FIRECRAWL_API_KEY=$FirecrawlApiKey",
        "-e", "FORTISAI_SHARED_NETWORK=$FortisaiSharedNetwork",
        "-e", "FORTISAI_ORACLE_DB_HOST=$OracleDbContainerName",
        "-e", "FORTISAI_ORACLE_DB_PORT=$OracleDbHostPort",
        "-e", "FORTISAI_ORACLE_DB_PDB=$OracleDbPdb",
        "-e", "FORTISAI_ORACLE_DB_USER=$OracleDbUser",
        "-e", "FORTISAI_ORACLE_DB_PASSWORD=$OracleDbPassword",
        "-e", "FORTISAI_REDIS_URL=redis://${RedisContainerName}:6379",
        "-e", "FORTISAI_PGVECTOR_DSN=postgresql://${PgvectorUser}:${PgvectorPassword}@${PgvectorContainerName}:5432/$PgvectorDb",
        "-e", "FORTISAI_VAULT_ADDR=$VaultInternalUrl",
        "-e", "VAULT_ADDR=$VaultInternalUrl",
        "-e", "VAULT_TOKEN=$VaultToken",
        "-v", "fortisai-openwebui-data:/app/backend/data",
        "ghcr.io/open-webui/open-webui:main"
    )

    & podman @runArgs *> $null
    if ($LASTEXITCODE -ne 0) {
        Throw-Error "OpenWebUI fallback start failed"
    }

    if (-not (Test-ContainerRunning -Name "fortisai-openwebui")) {
        Throw-Error "OpenWebUI fallback runtime did not stay running"
    }

    Write-Log "OpenWebUI started using fallback runtime path"
}

function Stop-OpenWebUi {
    if (Test-Path $OpenWebUiComposeFile) {
        try {
            Invoke-Compose -Args @("-f", $OpenWebUiComposeFile, "down")
        }
        catch {
            Write-Log "OpenWebUI compose shutdown failed; forcing container removal"
        }
    }

    & podman rm -f fortisai-openwebui *> $null
}

function Setup-OpenClaw {
    Require-Command podman
    Test-OpenClawPorts

    Ensure-PodmanMachine
    Ensure-SharedNetwork
    Write-VaultCompose
    Setup-OpenClawRuntime
    Write-OpenClawCompose
}

function Start-OpenClaw {
    Prepare-VaultRuntimeSecrets
    Setup-OpenClaw
    Start-Vault
    Unseal-Vault
    Write-Log "Starting OpenClaw"
    Start-ComposeContainer -ComposeFile $OpenClawComposeFile -ContainerName $OpenClawContainerName
}

function Stop-OpenClaw {
    Ensure-PodmanMachine
    if (Test-Path $OpenClawComposeFile) {
        Write-Log "Stopping OpenClaw"
        Invoke-Compose -Args @("-f", $OpenClawComposeFile, "down")
    }
    elseif (Test-ContainerExists -Name $OpenClawContainerName) {
        Write-Log "Stopping OpenClaw"
        & podman rm -f $OpenClawContainerName *> $null
    }
}

function Start-Hermes {
    Prepare-VaultRuntimeSecrets
    Setup-All
    Write-Log "Starting Hermes Agent"
    Invoke-Compose -Args @("-f", $HermesComposeFile, "up", "-d")
}

function Stop-Hermes {
    Ensure-PodmanMachine
    if (Test-Path $HermesComposeFile) {
        Write-Log "Stopping Hermes Agent"
        Invoke-Compose -Args @("-f", $HermesComposeFile, "down")
    }
}

function Start-Vault {
    Ensure-PodmanMachine
    Ensure-SharedNetwork
    Write-VaultCompose
    Write-Log "Starting HashiCorp Vault"
    Start-ComposeContainer -ComposeFile $VaultComposeFile -ContainerName $VaultContainerName
    Write-Log "Vault URL: $VaultUrl"
}

function Stop-Vault {
    Ensure-PodmanMachine
    if (Test-Path $VaultComposeFile) {
        Write-Log "Stopping HashiCorp Vault"
        Invoke-Compose -Args @("-f", $VaultComposeFile, "down")
    }
}

function Wait-VaultReady {
    $attempts = 30
    while ($attempts -gt 0) {
        & podman exec -e "VAULT_ADDR=http://127.0.0.1:8200" $VaultContainerName vault status *> $null
        if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 2) {
            return
        }
        Start-Sleep -Seconds 2
        $attempts -= 1
    }

    Throw-Error "Vault did not become reachable in time"
}

function Test-VaultInitialized {
    try {
        $statusJson = & podman exec -e "VAULT_ADDR=http://127.0.0.1:8200" $VaultContainerName vault status -format=json 2>$null
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 2) {
            return $false
        }
        $status = $statusJson | ConvertFrom-Json
        return [bool]$status.initialized
    }
    catch {
        return $false
    }
}

function Test-VaultSealed {
    try {
        $statusJson = & podman exec -e "VAULT_ADDR=http://127.0.0.1:8200" $VaultContainerName vault status -format=json 2>$null
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 2) {
            return $true
        }
        $status = $statusJson | ConvertFrom-Json
        return [bool]$status.sealed
    }
    catch {
        return $true
    }
}

function Initialize-Vault {
    if (-not (Test-ContainerRunning -Name $VaultContainerName)) {
        Start-Vault
    }

    Wait-VaultReady

    if (Test-VaultInitialized) {
        Write-Log "Vault is already initialized"
        Write-Log "Init key file: $VaultKeysFile"
        return
    }

    if (Test-Path $VaultKeysFile) {
        Throw-Error "Vault is uninitialized, but key file already exists: $VaultKeysFile. Move that file aside before reinitializing."
    }

    Write-Log "Initializing Vault with one local unseal key"
    $initJson = & podman exec -e "VAULT_ADDR=http://127.0.0.1:8200" $VaultContainerName vault operator init -key-shares=1 -key-threshold=1 -format=json
    if ($LASTEXITCODE -ne 0 -or -not $initJson) {
        Throw-Error "Vault initialization failed"
    }

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $VaultKeysFile) | Out-Null
    $initJson | Set-Content -Path $VaultKeysFile -Encoding UTF8
    try { & chmod 600 $VaultKeysFile } catch {}

    Write-Log "Vault init credentials saved to $VaultKeysFile"
    Write-Log "Keep this file local; it contains the root token and unseal key."
    Unseal-Vault
}

function Unseal-Vault {
    if (-not (Test-ContainerRunning -Name $VaultContainerName)) {
        Throw-Error "Vault container is not running. Start it with: .\fortisai-dev-helper.ps1 vault-up"
    }

    Wait-VaultReady

    if (-not (Test-VaultInitialized)) {
        Throw-Error "Vault is not initialized. Run: .\fortisai-dev-helper.ps1 vault-init"
    }

    if (-not (Test-VaultSealed)) {
        Write-Log "Vault is already unsealed"
        return
    }

    if (-not (Test-Path $VaultKeysFile)) {
        Throw-Error "Vault init key file not found: $VaultKeysFile. Run: .\fortisai-dev-helper.ps1 vault-init"
    }

    $payload = Get-Content -Path $VaultKeysFile -Raw | ConvertFrom-Json
    $unsealKey = $null
    if ($payload.unseal_keys_b64 -and $payload.unseal_keys_b64.Count -gt 0) {
        $unsealKey = $payload.unseal_keys_b64[0]
    }
    elseif ($payload.unseal_keys_hex -and $payload.unseal_keys_hex.Count -gt 0) {
        $unsealKey = $payload.unseal_keys_hex[0]
    }

    if (-not $unsealKey) {
        Throw-Error "Could not read unseal key from $VaultKeysFile"
    }

    & podman exec -e "VAULT_ADDR=http://127.0.0.1:8200" $VaultContainerName vault operator unseal $unsealKey *> $null
    if ($LASTEXITCODE -ne 0) {
        Throw-Error "Vault unseal failed"
    }
    Write-Log "Vault unsealed"
}

function Show-VaultStatus {
    Ensure-PodmanMachine
    if (-not (Test-ContainerRunning -Name $VaultContainerName)) {
        Write-Log "Vault container is not running"
        return
    }

    & podman exec -e "VAULT_ADDR=http://127.0.0.1:8200" $VaultContainerName vault status
}

function Write-OpenClawCompose {
        New-Item -ItemType Directory -Force -Path $OpenClawDir | Out-Null
        $openClawHostDir = $OpenClawDir.Replace('\\', '/')
        $openClawConfigName = Split-Path -Leaf $OpenClawRuntimeConfigFile

        @"
services:
    claw-gateway:
        image: $OpenClawImage
        container_name: $OpenClawContainerName
        restart: unless-stopped
        ports:
            - "${OpenClawGatewayPort}:18789"
            - "${OpenClawBridgePort}:18790"
        environment:
            - OPENCLAW_CONFIG_PATH=/home/node/.openclaw/$openClawConfigName
            - OPENCLAW_GATEWAY_PORT=18789
            - OPENCLAW_BRIDGE_PORT=18790
            - OPENCLAW_GATEWAY_BIND=$OpenClawGatewayBind
            - OPENCLAW_GATEWAY_TOKEN=$OpenClawGatewayToken
            - OPENCLAW_GATEWAY_PASSWORD=$OpenClawGatewayPassword
            - OPENAI_API_KEY=$OpenClawOpenAiApiKey
            - OPENAI_BASE_URL=$OpenClawLmStudioBaseUrl
            - FIRECRAWL_BASE_URL=$FirecrawlInternalUrl
            - FIRECRAWL_API_KEY=$FirecrawlApiKey
            - FORTISAI_VAULT_ADDR=$VaultInternalUrl
            - VAULT_ADDR=$VaultInternalUrl
            - VAULT_TOKEN=$VaultToken
        volumes:
            - $openClawHostDir`:/home/node/.openclaw
        entrypoint:
            - /bin/sh
            - -lc
            - |
                set -e
                a=open
                b=claw
                p="`${a}`${b}"
                command -v "`${p}" >/dev/null 2>&1 || npm install -g "`${p}" >/dev/null 2>&1
                if [ -n "$OpenClawHonchoPluginPackage" ] && ! npm list -g "$OpenClawHonchoPluginPackage" >/dev/null 2>&1; then
                    timeout 120 npm install -g "$OpenClawHonchoPluginPackage" >/dev/null 2>&1 || true
                fi
                exec "`${p}" gateway run --allow-unconfigured --token "`${OPENCLAW_GATEWAY_TOKEN}"
        networks:
            - shared-net
networks:
    shared-net:
        name: $FortisaiSharedNetwork
        external: true
"@ | Set-Content -Path $OpenClawComposeFile -Encoding UTF8
}

function Write-HermesCompose {
        New-Item -ItemType Directory -Force -Path $HermesDir | Out-Null
        $hermesEnvFile = Join-Path $HermesDir ".env"
        Set-OrAddEnvVar -FilePath $hermesEnvFile -Key "WHATSAPP_ENABLED" -Value $HermesWhatsappEnabled
        $hermesHostDir = $HermesDir.Replace('\\', '/')

        @"
services:
    hermes:
        image: $HermesImage
        container_name: $HermesContainerName
        restart: unless-stopped
        command:
            - gateway
            - run
        ports:
            - "${HermesGatewayPort}:8642"
            - "${HermesDashboardPort}:9119"
        environment:
            - HERMES_DASHBOARD=$HermesDashboard
            - HERMES_DASHBOARD_INSECURE=true
            - API_SERVER_ENABLED=$HermesApiServerEnabled
            - API_SERVER_HOST=$HermesApiServerHost
            - API_SERVER_KEY=$HermesApiServerKey
            - API_SERVER_CORS_ORIGINS=$HermesApiServerCorsOrigins
            - OPENAI_BASE_URL=$HermesOpenAiBaseUrl
            - OPENAI_API_BASE_URL=$HermesOpenAiBaseUrl
            - OPENAI_API_KEY=$HermesOpenAiApiKey
            - OPENAI_MODEL=$HermesOpenAiModel
            - HERMES_OPENAI_BASE_URL=$HermesOpenAiBaseUrl
            - HERMES_OPENAI_API_KEY=$HermesOpenAiApiKey
            - HERMES_OPENAI_MODEL=$HermesOpenAiModel
            - WHATSAPP_ENABLED=$HermesWhatsappEnabled
            - FORTISAI_PROXY_OPENAI_BASE_URL=$FortisaiProxyOpenAiBaseUrl
            - FORTISAI_PROXY_OPENAI_MODEL=$FortisaiProxyOpenAiModel
            - FORTISAI_HONCHO_BASE_URL=$HermesHonchoBaseUrl
            - FORTISAI_HONCHO_WORKSPACE_ID=$HermesHonchoWorkspaceId
            - FORTISAI_HONCHO_API_KEY=$HermesHonchoApiKey
            - FORTISAI_DAYTONA_DASHBOARD_URL=$HermesDaytonaDashboardUrl
            - FORTISAI_DAYTONA_API_URL=$HermesDaytonaApiUrl
            - FORTISAI_FIRECRAWL_BASE_URL=$FirecrawlInternalUrl
            - FORTISAI_FIRECRAWL_API_KEY=$FirecrawlApiKey
            - FORTISAI_VAULT_ADDR=$VaultInternalUrl
            - VAULT_ADDR=$VaultInternalUrl
            - VAULT_TOKEN=$VaultToken
        volumes:
            - $hermesHostDir`:/opt/data
        networks:
            - shared-net
networks:
    shared-net:
        name: $FortisaiSharedNetwork
        external: true
"@ | Set-Content -Path $HermesComposeFile -Encoding UTF8
}

function Write-AppsmithCompose {
    New-Item -ItemType Directory -Force -Path $AppsmithDir | Out-Null
    @"
services:
    appsmith:
        image: $AppsmithImage
        container_name: $AppsmithContainerName
        restart: unless-stopped
        ports:
            - "${AppsmithHostPort}:80"
        environment:
            - APPSMITH_DB_URL=$AppsmithDbUrl
            - APPSMITH_MONGODB_URI=$AppsmithDbUrl
            - APPSMITH_POSTGRES_DB_URL=$AppsmithPostgresDbUrl
            - APPSMITH_REDIS_URL=$AppsmithRedisUrl
            - APPSMITH_DISABLE_TELEMETRY=$AppsmithDisableTelemetry
            - APPSMITH_SEGMENT_CE_KEY=$AppsmithSegmentCeKey
            - APPSMITH_PYLON_APP_ID=$AppsmithPylonAppId
            - APPSMITH_BETTERBUGS_API_KEY=$AppsmithBetterbugsApiKey
            - APPSMITH_CLOUD_SERVICES_BASE_URL=$AppsmithCloudServicesBaseUrl
            - FORTISAI_MONGODB_URL=$AppsmithDbUrl
            - FORTISAI_REDIS_URL=redis://${RedisContainerName}:6379
            - FORTISAI_PGVECTOR_DSN=postgresql://${PgvectorUser}:${PgvectorPassword}@${PgvectorContainerName}:5432/$PgvectorDb
            - FORTISAI_VAULT_ADDR=$VaultInternalUrl
            - VAULT_ADDR=$VaultInternalUrl
            - VAULT_TOKEN=$VaultToken
        volumes:
            - appsmith_stacks:/appsmith-stacks
        networks:
            - shared-net
volumes:
    appsmith_stacks:
networks:
    shared-net:
        name: $FortisaiSharedNetwork
        external: true
"@ | Set-Content -Path $AppsmithComposeFile -Encoding UTF8
}

function Write-MongodbCompose {
    New-Item -ItemType Directory -Force -Path $MongodbDir | Out-Null
    @"
services:
    mongodb:
        image: $MongodbImage
        container_name: $MongodbContainerName
        restart: unless-stopped
        command: ["mongod", "--bind_ip_all", "--replSet", "$MongodbReplicaSet"]
        ports:
            - "${MongodbHostPort}:27017"
        volumes:
            - mongodb_data:/data/db
        networks:
            - shared-net
volumes:
    mongodb_data:
networks:
    shared-net:
        name: $FortisaiSharedNetwork
        external: true
"@ | Set-Content -Path $MongodbComposeFile -Encoding UTF8
}

function Wait-MongodbReady {
    $attempts = 30
    while ($attempts -gt 0) {
        & podman exec $MongodbContainerName mongosh --quiet --eval 'db.adminCommand({ ping: 1 }).ok' *> $null
        if ($LASTEXITCODE -eq 0) {
            return
        }
        Start-Sleep -Seconds 2
        $attempts -= 1
    }

    Throw-Error "MongoDB did not become ready in time"
}

function Ensure-MongodbReplicaSet {
    if (-not (Test-ContainerRunning -Name $MongodbContainerName)) {
        Throw-Error "MongoDB container is not running"
    }

    Wait-MongodbReady

    $status = (& podman exec $MongodbContainerName mongosh --quiet --eval 'try { rs.status().ok } catch (e) { 0 }' 2>$null | Select-Object -First 1)
    if ($status -and $status.Trim() -eq "1") {
        return
    }

    Write-Log "Initializing MongoDB replica set: $MongodbReplicaSet"
    & podman exec $MongodbContainerName mongosh --quiet --eval "rs.initiate({_id: '$MongodbReplicaSet', members:[{_id: 0, host: '$MongodbContainerName:27017'}]})" *> $null

    $attempts = 30
    while ($attempts -gt 0) {
        $ready = (& podman exec $MongodbContainerName mongosh --quiet --eval 'try { rs.status().ok } catch (e) { 0 }' 2>$null | Select-Object -First 1)
        if ($ready -and $ready.Trim() -eq "1") {
            return
        }
        Start-Sleep -Seconds 2
        $attempts -= 1
    }

    Throw-Error "MongoDB replica set did not initialize in time"
}

function Write-RedisCompose {
    New-Item -ItemType Directory -Force -Path $RedisDir | Out-Null
    @"
services:
    redis:
        image: $RedisImage
        container_name: $RedisContainerName
        restart: unless-stopped
        ports:
            - "${RedisHostPort}:6379"
        volumes:
            - redis_data:/data
        networks:
            - shared-net
volumes:
    redis_data:
networks:
    shared-net:
        name: $FortisaiSharedNetwork
        external: true
"@ | Set-Content -Path $RedisComposeFile -Encoding UTF8
}

function Write-RabbitMqCompose {
    New-Item -ItemType Directory -Force -Path $RabbitMqDir | Out-Null
    @"
services:
    rabbitmq:
        image: $RabbitMqImage
        container_name: $RabbitMqContainerName
        restart: unless-stopped
        ports:
            - "${RabbitMqHostPort}:5672"
            - "${RabbitMqManagementHostPort}:15672"
        environment:
            - RABBITMQ_DEFAULT_USER=$RabbitMqDefaultUser
            - RABBITMQ_DEFAULT_PASS=$RabbitMqDefaultPassword
        volumes:
            - rabbitmq_data:/var/lib/rabbitmq
        networks:
            - shared-net
volumes:
    rabbitmq_data:
networks:
    shared-net:
        name: $FortisaiSharedNetwork
        external: true
"@ | Set-Content -Path $RabbitMqComposeFile -Encoding UTF8
}

function Write-VaultCompose {
    New-Item -ItemType Directory -Force -Path (Join-Path $VaultDir "config") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $VaultDir "file") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $VaultDir "logs") | Out-Null

    @"
ui = true
disable_mlock = true
api_addr = "$VaultApiAddr"
cluster_addr = "http://$VaultContainerName`:8201"

storage "file" {
  path = "/vault/file"
}

listener "tcp" {
  address = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  tls_disable = true
}
"@ | Set-Content -Path $VaultConfigFile -Encoding UTF8

    @"
services:
    vault:
        image: $VaultImage
        container_name: $VaultContainerName
        user: "0:0"
        restart: unless-stopped
        command: server
        ports:
            - "127.0.0.1:$VaultHostPort`:8200"
        environment:
            - VAULT_ADDR=http://127.0.0.1:8200
            - VAULT_API_ADDR=$VaultApiAddr
            - SKIP_SETCAP=true
        volumes:
            - ./config:/vault/config
            - ./file:/vault/file
            - ./logs:/vault/logs
        networks:
            - shared-net
networks:
    shared-net:
        name: $FortisaiSharedNetwork
        external: true
"@ | Set-Content -Path $VaultComposeFile -Encoding UTF8
}

function Write-FirecrawlCompose {
    New-Item -ItemType Directory -Force -Path $FirecrawlDir | Out-Null
    @"
services:
    firecrawl:
        image: $FirecrawlImage
        container_name: $FirecrawlContainerName
        restart: unless-stopped
        ports:
            - "${FirecrawlHostPort}:3002"
        environment:
            - PORT=3002
            - HOST=0.0.0.0
            - FIRECRAWL_API_KEY=$FirecrawlApiKey
            - NUQ_DATABASE_URL=$FirecrawlDatabaseUrl
            - NUQ_RABBITMQ_URL=$FirecrawlRabbitMqUrl
            - REDIS_URL=$FirecrawlRedisUrl
            - REDIS_EVICT_URL=$FirecrawlRedisEvictUrl
            - REDIS_RATE_LIMIT_URL=$FirecrawlRedisRateLimitUrl
            - FORTISAI_VAULT_ADDR=$VaultInternalUrl
            - VAULT_ADDR=$VaultInternalUrl
            - VAULT_TOKEN=$VaultToken
        networks:
            - shared-net
networks:
    shared-net:
        name: $FortisaiSharedNetwork
        external: true
"@ | Set-Content -Path $FirecrawlComposeFile -Encoding UTF8
}

function Write-PgvectorCompose {
    New-Item -ItemType Directory -Force -Path $PgvectorDir | Out-Null
    @"
services:
    pgvector:
        image: $PgvectorImage
        container_name: $PgvectorContainerName
        restart: unless-stopped
        ports:
            - "${PgvectorHostPort}:5432"
        environment:
            POSTGRES_DB: $PgvectorDb
            POSTGRES_USER: $PgvectorUser
            POSTGRES_PASSWORD: $PgvectorPassword
        volumes:
            - pgvector_data:/var/lib/postgresql/data
        networks:
            - shared-net
volumes:
    pgvector_data:
networks:
    shared-net:
        name: $FortisaiSharedNetwork
        external: true
"@ | Set-Content -Path $PgvectorComposeFile -Encoding UTF8
}

function Write-TraefikCompose {
    New-Item -ItemType Directory -Force -Path $TraefikDir | Out-Null

    $sha1 = [System.Security.Cryptography.SHA1]::Create()
    try {
        $passwordBytes = [System.Text.Encoding]::UTF8.GetBytes($TraefikDashboardPassword)
        $passwordHash = [Convert]::ToBase64String($sha1.ComputeHash($passwordBytes))
    }
    finally {
        $sha1.Dispose()
    }
    "${TraefikDashboardUser}:{SHA}$passwordHash" | Set-Content -Path $TraefikUsersFile -Encoding ASCII

    @"
api:
  dashboard: true
  insecure: false

entryPoints:
  web:
    address: ":8080"
  dashboard:
    address: ":8088"

providers:
  file:
    filename: /etc/traefik/dynamic.yml
    watch: true

log:
  level: INFO
"@ | Set-Content -Path $TraefikStaticConfigFile -Encoding UTF8

    $dynamicConfig = @'
http:
  routers:
    dashboard:
      rule: "PathPrefix(`/api`) || PathPrefix(`/dashboard`)"
      entryPoints:
        - dashboard
      service: api@internal
      middlewares:
        - dashboard-auth
    openwebui:
      rule: "Host(`openwebui.fortisai.localhost`)"
      entryPoints:
        - web
      service: openwebui
    n8n:
      rule: "Host(`n8n.fortisai.localhost`)"
      entryPoints:
        - web
      service: n8n
    dify:
      rule: "Host(`dify.fortisai.localhost`)"
      entryPoints:
        - web
      service: dify
    codeindexer:
      rule: "Host(`codeindexer.fortisai.localhost`)"
      entryPoints:
        - web
      service: codeindexer
    openmetadata:
      rule: "Host(`openmetadata.fortisai.localhost`)"
      entryPoints:
        - web
      service: openmetadata
  middlewares:
    dashboard-auth:
      basicAuth:
        usersFile: /etc/traefik/users.htpasswd
  services:
    openwebui:
      loadBalancer:
        servers:
          - url: "http://{{OPENWEBUI_CONTAINER_NAME}}:8080"
    n8n:
      loadBalancer:
        servers:
          - url: "http://fortisai-n8n:5678"
    dify:
      loadBalancer:
        servers:
          - url: "http://docker_nginx_1:80"
    codeindexer:
      loadBalancer:
        servers:
          - url: "http://{{CODEINDEXER_BRIDGE_CONTAINER_NAME}}:8096"
    openmetadata:
      loadBalancer:
        servers:
          - url: "http://{{OPENMETADATA_CONTAINER_NAME}}:8585"
'@
    $dynamicConfig = $dynamicConfig.Replace("{{OPENWEBUI_CONTAINER_NAME}}", $OpenWebUiContainerName)
    $dynamicConfig = $dynamicConfig.Replace("{{CODEINDEXER_BRIDGE_CONTAINER_NAME}}", $CodeIndexerBridgeContainerName)
    $dynamicConfig = $dynamicConfig.Replace("{{OPENMETADATA_CONTAINER_NAME}}", $OpenMetadataContainerName)
    $dynamicConfig | Set-Content -Path $TraefikDynamicConfigFile -Encoding UTF8

    @"
services:
  traefik:
    image: $TraefikImage
    container_name: $TraefikContainerName
    restart: unless-stopped
    ports:
      - "${TraefikWebHostPort}:8080"
      - "${TraefikDashboardHostPort}:8088"
    volumes:
      - ./traefik.yml:/etc/traefik/traefik.yml:ro
      - ./dynamic.yml:/etc/traefik/dynamic.yml:ro
      - ./users.htpasswd:/etc/traefik/users.htpasswd:ro
    environment:
      - FORTISAI_VAULT_ADDR=$VaultInternalUrl
      - VAULT_ADDR=$VaultInternalUrl
      - VAULT_TOKEN=$VaultToken
    networks:
      - shared-net
networks:
  shared-net:
    name: $FortisaiSharedNetwork
    external: true
"@ | Set-Content -Path $TraefikComposeFile -Encoding UTF8
}

function Write-MilvusCompose {
    New-Item -ItemType Directory -Force -Path $MilvusDir | Out-Null
    @"
services:
  etcd:
    image: $MilvusEtcdImage
    container_name: $MilvusEtcdContainerName
    restart: unless-stopped
    command: >
      etcd
      -advertise-client-urls=http://127.0.0.1:2379
      -listen-client-urls=http://0.0.0.0:2379
      --data-dir=/etcd
    environment:
      - ETCD_AUTO_COMPACTION_MODE=revision
      - ETCD_AUTO_COMPACTION_RETENTION=1000
      - ETCD_QUOTA_BACKEND_BYTES=4294967296
      - ETCD_SNAPSHOT_COUNT=50000
    volumes:
      - milvus_etcd:/etcd
    networks:
      - shared-net

  minio:
    image: $MilvusMinioImage
    container_name: $MilvusMinioContainerName
    restart: unless-stopped
    command: minio server /minio_data --console-address ":9001"
    environment:
      - MINIO_ROOT_USER=$MilvusMinioRootUser
      - MINIO_ROOT_PASSWORD=$MilvusMinioRootPassword
    volumes:
      - milvus_minio:/minio_data
    networks:
      - shared-net

  milvus:
    image: $MilvusImage
    container_name: $MilvusContainerName
    restart: unless-stopped
    command: ["milvus", "run", "standalone"]
    ports:
      - "${MilvusHostPort}:19530"
      - "${MilvusHealthHostPort}:9091"
    environment:
      - ETCD_ENDPOINTS=${MilvusEtcdContainerName}:2379
      - MINIO_ADDRESS=${MilvusMinioContainerName}:9000
      - FORTISAI_VAULT_ADDR=$VaultInternalUrl
      - VAULT_ADDR=$VaultInternalUrl
      - VAULT_TOKEN=$VaultToken
    volumes:
      - milvus_data:/var/lib/milvus
    networks:
      - shared-net

volumes:
  milvus_etcd:
  milvus_minio:
  milvus_data:

networks:
  shared-net:
    name: $FortisaiSharedNetwork
    external: true
"@ | Set-Content -Path $MilvusComposeFile -Encoding UTF8
}

function Write-OpenSearchCompose {
    New-Item -ItemType Directory -Force -Path $OpenSearchDir | Out-Null
    @"
services:
  opensearch:
    image: $OpenSearchImage
    container_name: $OpenSearchContainerName
    restart: unless-stopped
    ports:
      - "${OpenSearchHostPort}:9200"
      - "${OpenSearchPerformanceHostPort}:9600"
    environment:
      - discovery.type=single-node
      - plugins.security.disabled=true
      - DISABLE_SECURITY_PLUGIN=true
      - OPENSEARCH_JAVA_OPTS=$OpenSearchJavaOpts
      - FORTISAI_VAULT_ADDR=$VaultInternalUrl
      - VAULT_ADDR=$VaultInternalUrl
      - VAULT_TOKEN=$VaultToken
    volumes:
      - opensearch_data:/usr/share/opensearch/data
    networks:
      - shared-net
volumes:
  opensearch_data:
networks:
  shared-net:
    name: $FortisaiSharedNetwork
    external: true
"@ | Set-Content -Path $OpenSearchComposeFile -Encoding UTF8
}

function Write-OpenMetadataCompose {
    New-Item -ItemType Directory -Force -Path $OpenMetadataDir | Out-Null
    @"
services:
  openmetadata:
    image: $OpenMetadataImage
    container_name: $OpenMetadataContainerName
    restart: unless-stopped
    ports:
      - "${OpenMetadataHostPort}:8585"
      - "${OpenMetadataAdminHostPort}:8586"
    environment:
      - OPENMETADATA_CLUSTER_NAME=fortisai-openmetadata
      - SERVER_PORT=8585
      - SERVER_ADMIN_PORT=8586
      - LOG_LEVEL=INFO
      - AUTHENTICATION_PROVIDER=basic
      - AUTHENTICATION_ENABLE_SELF_SIGNUP=true
      - AUTHORIZER_ADMIN_PRINCIPALS=[admin]
      - AUTHORIZER_ALLOWED_REGISTRATION_DOMAIN=["all"]
      - AUTHORIZER_ALLOWED_DOMAINS=[]
      - AUTHORIZER_ENFORCE_PRINCIPAL_DOMAIN=false
      - AUTHORIZER_ENABLE_SECURE_SOCKET=false
      - AUTHENTICATION_PUBLIC_KEYS=[http://${OpenMetadataContainerName}:8585/api/v1/system/config/jwks]
      - PIPELINE_SERVICE_CLIENT_CLASS_NAME=org.openmetadata.service.clients.pipeline.noop.NoopClient
      - PIPELINE_SERVICE_CLIENT_ENDPOINT=http://${OpenMetadataContainerName}:8585
      - SERVER_HOST_API_URL=http://${OpenMetadataContainerName}:8585/api
      - DB_DRIVER_CLASS=org.postgresql.Driver
      - DB_SCHEME=postgresql
      - DB_PARAMS=sslmode=disable
      - DB_USE_SSL=false
      - DB_USER=$PgvectorUser
      - DB_USER_PASSWORD=$PgvectorPassword
      - DB_HOST=$PgvectorContainerName
      - DB_PORT=5432
      - OM_DATABASE=$OpenMetadataDbName
      - ELASTICSEARCH_HOST=$OpenSearchContainerName
      - ELASTICSEARCH_PORT=9200
      - ELASTICSEARCH_SCHEME=http
      - SEARCH_TYPE=opensearch
      - ELASTICSEARCH_USER=
      - ELASTICSEARCH_PASSWORD=
      - FERNET_KEY=$OpenMetadataFernetKey
      - SECRET_MANAGER=db
      - OPENMETADATA_HEAP_OPTS=$OpenMetadataHeapOpts
      - JWT_KEY_ID=$OpenMetadataJwtKeyId
      - FORTISAI_VAULT_ADDR=$VaultInternalUrl
      - VAULT_ADDR=$VaultInternalUrl
      - VAULT_TOKEN=$VaultToken
    networks:
      - shared-net
networks:
  shared-net:
    name: $FortisaiSharedNetwork
    external: true
"@ | Set-Content -Path $OpenMetadataComposeFile -Encoding UTF8
}

function Write-OracleDbCompose {
        New-Item -ItemType Directory -Force -Path $OracleDbStartupDir | Out-Null

        $startupScript = @"
whenever sqlerror exit failure rollback;
declare
    user_count integer;
begin
    select count(*) into user_count from dba_users where username = 'FORTISAI_APP';
    if user_count = 0 then
        execute immediate q'[create user fortisai_app identified by "$OracleDbPassword" default tablespace users temporary tablespace temp quota unlimited on users]';
        execute immediate 'grant create session, create table, create view, create sequence, create procedure to fortisai_app';
    end if;
end;
/
"@
        Set-Content -Path (Join-Path $OracleDbStartupDir "01-fortisai-app-user.sql") -Value $startupScript -Encoding UTF8

        @"
services:
    oracle-db:
        image: $OracleDbImage
        container_name: $OracleDbContainerName
        restart: unless-stopped
        ports:
            - "${OracleDbHostPort}:1521"
        environment:
            ORACLE_PWD: $OracleDbPassword
            ORACLE_CHARACTERSET: AL32UTF8
        volumes:
            - oracle_db_data:/opt/oracle/oradata
            - ./startup:/opt/oracle/scripts/startup:ro
        networks:
            - shared-net
volumes:
    oracle_db_data:
networks:
    shared-net:
        name: $FortisaiSharedNetwork
        external: true
"@ | Set-Content -Path $OracleDbComposeFile -Encoding UTF8
}

function Write-OrdsCompose {
        New-Item -ItemType Directory -Force -Path $OrdsDir | Out-Null

        @"
services:
    ords:
        image: $OrdsImage
        container_name: $OrdsContainerName
        restart: unless-stopped
        ports:
            - "$OrdsHostPort`:8080"
        env_file:
            - $OracleDbWalletEnvFile
        environment:
            - ORACLE_WALLET_DIR=/opt/oracle/wallet
            - TNS_ADMIN=/opt/oracle/wallet
        volumes:
            - $OrdsConfigVolume`:/etc/ords/config
            - $OracleWalletDir`:/opt/oracle/wallet:ro
        networks:
            - shared-net
volumes:
    ${OrdsConfigVolume}:
        external: true
networks:
    shared-net:
        name: $FortisaiSharedNetwork
        external: true
"@ | Set-Content -Path $OrdsComposeFile -Encoding UTF8
}

function Write-SqlclCompose {
        New-Item -ItemType Directory -Force -Path $SqlclDir | Out-Null

        @"
services:
    sqlcl:
        image: $SqlclImage
        container_name: $SqlclContainerName
        restart: unless-stopped
        env_file:
            - $OracleDbWalletEnvFile
        environment:
            - ORACLE_WALLET_DIR=/opt/oracle/wallet
            - TNS_ADMIN=/opt/oracle/wallet
        entrypoint: ["/bin/sh", "-lc", "tail -f /dev/null"]
        volumes:
            - $OracleWalletDir`:/opt/oracle/wallet:ro
        networks:
            - shared-net
networks:
    shared-net:
        name: $FortisaiSharedNetwork
        external: true
"@ | Set-Content -Path $SqlclComposeFile -Encoding UTF8
}

function Write-HonchoCompose {
        New-Item -ItemType Directory -Force -Path $HonchoDir | Out-Null
        $honchoContext = $HonchoRepoDir.Replace('\\', '/')
        $honchoEnvFile = (Join-Path $HonchoRepoDir ".env").Replace('\\', '/')

        @"
services:
    api:
        build:
            context: $honchoContext
            dockerfile: Dockerfile
        container_name: $HonchoApiContainerName
        entrypoint: ["sh", "docker/entrypoint.sh"]
        restart: unless-stopped
        ports:
            - "${HonchoHostPort}:8000"
        env_file:
            - $honchoEnvFile
        environment:
            - DB_CONNECTION_URI=postgresql+psycopg://${PgvectorUser}:${PgvectorPassword}@${PgvectorContainerName}:5432/$HonchoDb
            - CACHE_URL=redis://${RedisContainerName}:6379/0?suppress=true
            - CACHE_ENABLED=true
            - VECTOR_STORE_TYPE=pgvector
            - FORTISAI_VAULT_ADDR=$VaultInternalUrl
            - VAULT_ADDR=$VaultInternalUrl
            - VAULT_TOKEN=$VaultToken
        networks:
            - shared-net

    deriver:
        build:
            context: $honchoContext
            dockerfile: Dockerfile
        container_name: $HonchoDeriverContainerName
        entrypoint: ["/app/.venv/bin/python", "-m", "src.deriver"]
        restart: unless-stopped
        env_file:
            - $honchoEnvFile
        environment:
            - DB_CONNECTION_URI=postgresql+psycopg://${PgvectorUser}:${PgvectorPassword}@${PgvectorContainerName}:5432/$HonchoDb
            - CACHE_URL=redis://${RedisContainerName}:6379/0?suppress=true
            - CACHE_ENABLED=true
            - VECTOR_STORE_TYPE=pgvector
            - FORTISAI_VAULT_ADDR=$VaultInternalUrl
            - VAULT_ADDR=$VaultInternalUrl
            - VAULT_TOKEN=$VaultToken
        networks:
            - shared-net

networks:
    shared-net:
        name: $FortisaiSharedNetwork
        external: true
"@ | Set-Content -Path $HonchoComposeFile -Encoding UTF8
}

function Setup-HonchoRepo {
    Require-Command git

    $resolvedHonchoModel = $HonchoLmStudioModel

    New-Item -ItemType Directory -Force -Path $HonchoDir | Out-Null
    if (-not (Test-Path (Join-Path $HonchoRepoDir ".git"))) {
        Write-Log "Cloning Honcho repository"
        & git clone https://github.com/plastic-labs/honcho.git $HonchoRepoDir
    }
    else {
        Write-Log "Honcho repository already exists at $HonchoRepoDir"
    }

    $honchoEnv = Join-Path $HonchoRepoDir ".env"
    $honchoEnvTemplate = Join-Path $HonchoRepoDir ".env.template"

    if (-not (Test-Path $honchoEnv)) {
        if (-not (Test-Path $honchoEnvTemplate)) {
            Throw-Error "Honcho .env.template was not found in $HonchoRepoDir"
        }
        Write-Log "Creating Honcho .env from template"
        Copy-Item -Path $honchoEnvTemplate -Destination $honchoEnv
    }

    Set-OrAddEnvVar -FilePath $honchoEnv -Key "DB_CONNECTION_URI" -Value "postgresql+psycopg://${PgvectorUser}:${PgvectorPassword}@${PgvectorContainerName}:5432/$HonchoDb"
    Set-OrAddEnvVar -FilePath $honchoEnv -Key "CACHE_ENABLED" -Value "true"
    Set-OrAddEnvVar -FilePath $honchoEnv -Key "CACHE_URL" -Value "redis://${RedisContainerName}:6379/0?suppress=true"
    Set-OrAddEnvVar -FilePath $honchoEnv -Key "VECTOR_STORE_TYPE" -Value "pgvector"
    Set-OrAddEnvVar -FilePath $honchoEnv -Key "FORTISAI_VAULT_ADDR" -Value $VaultInternalUrl
    Set-OrAddEnvVar -FilePath $honchoEnv -Key "VAULT_ADDR" -Value $VaultInternalUrl
    if ($VaultToken) {
        Set-OrAddEnvVar -FilePath $honchoEnv -Key "VAULT_TOKEN" -Value $VaultToken
    }
    Set-OrAddEnvVar -FilePath $honchoEnv -Key "AUTH_USE_AUTH" -Value "false"
    Set-OrAddEnvVar -FilePath $honchoEnv -Key "LLM_OPENAI_API_KEY" -Value $HonchoLlmOpenaiApiKey

    if ([string]::IsNullOrWhiteSpace($resolvedHonchoModel) -or $resolvedHonchoModel -eq "auto") {
        try {
            $modelsResponse = Invoke-RestMethod -Uri $HonchoLmStudioModelsUrl -Method Get -TimeoutSec 5
            if ($modelsResponse.data -and $modelsResponse.data.Count -gt 0 -and $modelsResponse.data[0].id) {
                $resolvedHonchoModel = [string]$modelsResponse.data[0].id
            }
        }
        catch {
            # Ignore and use fallback model id.
        }
    }

    if ([string]::IsNullOrWhiteSpace($resolvedHonchoModel)) {
        $resolvedHonchoModel = "local-model"
        Write-Log "LM Studio model auto-detection failed; using fallback model id: $resolvedHonchoModel"
    }
    else {
        Write-Log "Using Honcho LM Studio model id: $resolvedHonchoModel"
    }

    Set-OrAddEnvVar -FilePath $honchoEnv -Key "EMBED_MESSAGES" -Value $HonchoEmbedMessages
    Set-OrAddEnvVar -FilePath $honchoEnv -Key "DERIVER_MODEL_CONFIG__TRANSPORT" -Value "openai"
    Set-OrAddEnvVar -FilePath $honchoEnv -Key "DERIVER_MODEL_CONFIG__MODEL" -Value $resolvedHonchoModel
    Set-OrAddEnvVar -FilePath $honchoEnv -Key "DERIVER_MODEL_CONFIG__OVERRIDES__BASE_URL" -Value $HonchoLmStudioBaseUrl
    Set-OrAddEnvVar -FilePath $honchoEnv -Key "SUMMARY_MODEL_CONFIG__TRANSPORT" -Value "openai"
    Set-OrAddEnvVar -FilePath $honchoEnv -Key "SUMMARY_MODEL_CONFIG__MODEL" -Value $resolvedHonchoModel
    Set-OrAddEnvVar -FilePath $honchoEnv -Key "SUMMARY_MODEL_CONFIG__OVERRIDES__BASE_URL" -Value $HonchoLmStudioBaseUrl
    Set-OrAddEnvVar -FilePath $honchoEnv -Key "DREAM_DEDUCTION_MODEL_CONFIG__TRANSPORT" -Value "openai"
    Set-OrAddEnvVar -FilePath $honchoEnv -Key "DREAM_DEDUCTION_MODEL_CONFIG__MODEL" -Value $resolvedHonchoModel
    Set-OrAddEnvVar -FilePath $honchoEnv -Key "DREAM_DEDUCTION_MODEL_CONFIG__OVERRIDES__BASE_URL" -Value $HonchoLmStudioBaseUrl
    Set-OrAddEnvVar -FilePath $honchoEnv -Key "DREAM_INDUCTION_MODEL_CONFIG__TRANSPORT" -Value "openai"
    Set-OrAddEnvVar -FilePath $honchoEnv -Key "DREAM_INDUCTION_MODEL_CONFIG__MODEL" -Value $resolvedHonchoModel
    Set-OrAddEnvVar -FilePath $honchoEnv -Key "DREAM_INDUCTION_MODEL_CONFIG__OVERRIDES__BASE_URL" -Value $HonchoLmStudioBaseUrl

    foreach ($dialecticLevel in @("minimal", "low", "medium", "high", "max")) {
        Set-OrAddEnvVar -FilePath $honchoEnv -Key "DIALECTIC_LEVELS__${dialecticLevel}__MODEL_CONFIG__TRANSPORT" -Value "openai"
        Set-OrAddEnvVar -FilePath $honchoEnv -Key "DIALECTIC_LEVELS__${dialecticLevel}__MODEL_CONFIG__MODEL" -Value $resolvedHonchoModel
        Set-OrAddEnvVar -FilePath $honchoEnv -Key "DIALECTIC_LEVELS__${dialecticLevel}__MODEL_CONFIG__OVERRIDES__BASE_URL" -Value $HonchoLmStudioBaseUrl
    }
}

function Setup-OpenApiServersRepo {
    Require-Command git

    New-Item -ItemType Directory -Force -Path $OpenApiServersDir | Out-Null
    if (-not (Test-Path (Join-Path $OpenApiServersRepoDir ".git"))) {
        Write-Log "Cloning OpenAPI servers repository"
        & git clone https://github.com/open-webui/openapi-servers.git $OpenApiServersRepoDir
    }
    else {
        Write-Log "OpenAPI servers repository already exists at $OpenApiServersRepoDir"
    }

    if (-not (Test-Path $OpenApiServersComposeFile)) {
        Throw-Error "OpenAPI servers compose file not found: $OpenApiServersComposeFile"
    }
}

function Write-OpenApiServersOpenWebUiTemplate {
    New-Item -ItemType Directory -Force -Path $OpenApiServersDir | Out-Null

    $mcpSqlclBaseUrl = $McpSqlclOpenApiUrl -replace '/openapi\.json$', ''
    $mcpN8nBaseUrl = $McpN8nOpenApiUrl -replace '/openapi\.json$', ''
    $mcpDifyBaseUrl = $McpDifyOpenApiUrl -replace '/openapi\.json$', ''
    $mcpCodeIndexerBaseUrl = $McpCodeIndexerOpenApiUrl -replace '/openapi\.json$', ''
    $mcpProxmoxBaseUrl = $McpProxmoxOpenApiUrl -replace '/openapi\.json$', ''

    @"
# Open WebUI OpenAPI Tool Servers template
OPENAPI_FILESYSTEM_URL=$OpenApiFilesystemUrl
OPENAPI_MEMORY_URL=$OpenApiMemoryUrl
OPENAPI_TIME_URL=$OpenApiTimeUrl
OPENAPI_FILESYSTEM_OPENWEBUI_URL=$OpenApiFilesystemOpenWebUiUrl
OPENAPI_MEMORY_OPENWEBUI_URL=$OpenApiMemoryOpenWebUiUrl
OPENAPI_TIME_OPENWEBUI_URL=$OpenApiTimeOpenWebUiUrl
OPENAPI_MCP_SQLCL_URL=$mcpSqlclBaseUrl
OPENAPI_MCP_N8N_URL=$mcpN8nBaseUrl
OPENAPI_MCP_DIFY_URL=$mcpDifyBaseUrl
OPENAPI_MCP_CODEINDEXER_URL=$mcpCodeIndexerBaseUrl
OPENAPI_MCP_PROXMOX_URL=$mcpProxmoxBaseUrl
"@ | Set-Content -Path $OpenApiServersEnvTemplateFile -Encoding UTF8

    @"
[
  {
    "name": "repo-filesystem-server",
    "base_url": "$OpenApiFilesystemOpenWebUiUrl",
    "openapi_url": "$OpenApiFilesystemOpenWebUiUrl/openapi.json"
  },
  {
    "name": "repo-memory-server",
    "base_url": "$OpenApiMemoryOpenWebUiUrl",
    "openapi_url": "$OpenApiMemoryOpenWebUiUrl/openapi.json"
  },
  {
    "name": "repo-time-server",
    "base_url": "$OpenApiTimeOpenWebUiUrl",
    "openapi_url": "$OpenApiTimeOpenWebUiUrl/openapi.json"
  },
  {
    "name": "mcp-sqlcl-server",
    "base_url": "$mcpSqlclBaseUrl",
    "openapi_url": "$McpSqlclOpenApiUrl"
  },
  {
    "name": "mcp-n8n-server",
    "base_url": "$mcpN8nBaseUrl",
    "openapi_url": "$McpN8nOpenApiUrl"
  },
  {
    "name": "mcp-dify-server",
    "base_url": "$mcpDifyBaseUrl",
    "openapi_url": "$McpDifyOpenApiUrl"
  },
  {
    "name": "mcp-codeindexer-server",
    "base_url": "$mcpCodeIndexerBaseUrl",
    "openapi_url": "$McpCodeIndexerOpenApiUrl"
  },
  {
    "name": "mcp-proxmox-server",
    "base_url": "$mcpProxmoxBaseUrl",
    "openapi_url": "$McpProxmoxOpenApiUrl"
  }
]
"@ | Set-Content -Path $OpenApiServersJsonTemplateFile -Encoding UTF8

    Write-Log "Wrote OpenAPI server templates for Open WebUI:"
    Write-Log "- $OpenApiServersEnvTemplateFile"
    Write-Log "- $OpenApiServersJsonTemplateFile"
}

function Ensure-HonchoDatabase {
    if (-not (Test-ContainerRunning -Name $PgvectorContainerName)) {
        Throw-Error "pgvector container is not running. Start it with: .\fortisai-dev-helper.ps1 up"
    }

    $exists = (& podman exec $PgvectorContainerName psql -U $PgvectorUser -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$HonchoDb';" 2>$null | Select-Object -First 1).Trim()
    if ($exists -eq "1") {
        Write-Log "Honcho database already exists: $HonchoDb"
        return
    }

    Write-Log "Creating dedicated Honcho database in pgvector: $HonchoDb"
    & podman exec $PgvectorContainerName psql -U $PgvectorUser -d postgres -c "CREATE DATABASE \"$HonchoDb\" OWNER \"$PgvectorUser\";" *> $null
    if ($LASTEXITCODE -ne 0) {
        Throw-Error "Failed creating Honcho database: $HonchoDb"
    }
}

function Ensure-FirecrawlDatabase {
    if (-not (Test-ContainerRunning -Name $PgvectorContainerName)) {
        Throw-Error "pgvector container is not running. Start it with: .\fortisai-dev-helper.ps1 up"
    }

    $exists = (& podman exec $PgvectorContainerName psql -U $PgvectorUser -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$FirecrawlDbName';" 2>$null | Select-Object -First 1).Trim()
    if ($exists -eq "1") {
        Write-Log "Firecrawl database already exists: $FirecrawlDbName"
    }
    else {
        Write-Log "Creating dedicated Firecrawl database in pgvector: $FirecrawlDbName"
        & podman exec $PgvectorContainerName psql -U $PgvectorUser -d postgres -c "CREATE DATABASE \"$FirecrawlDbName\" OWNER \"$PgvectorUser\";" *> $null
        if ($LASTEXITCODE -ne 0) {
            $existsAfterCreate = (& podman exec $PgvectorContainerName psql -U $PgvectorUser -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$FirecrawlDbName';" 2>$null | Select-Object -First 1).Trim()
            if ($existsAfterCreate -eq "1") {
                Write-Log "Firecrawl database already exists: $FirecrawlDbName"
            }
            else {
                Throw-Error "Failed creating Firecrawl database: $FirecrawlDbName"
            }
        }
    }

    $nuqSqlFile = Join-Path $FirecrawlDir "nuq.sql"
    Write-Log "Fetching Firecrawl NUQ schema: $FirecrawlNuqSqlUrl"
    try {
        Invoke-WebRequest -Uri $FirecrawlNuqSqlUrl -OutFile $nuqSqlFile -UseBasicParsing
        Write-Log "Applying Firecrawl NUQ schema to database: $FirecrawlDbName"
        & podman cp $nuqSqlFile "${PgvectorContainerName}:/tmp/nuq.sql" *> $null
        & podman exec $PgvectorContainerName psql -U $PgvectorUser -d $FirecrawlDbName -f /tmp/nuq.sql *> $null
        & podman exec $PgvectorContainerName rm -f /tmp/nuq.sql *> $null
    }
    catch {
        Write-Log "Unable to fetch/apply NUQ schema; Firecrawl may restart if schema is missing"
    }
}

function Ensure-PostgresDatabase {
    param([Parameter(Mandatory = $true)][string]$DatabaseName)

    if (-not (Test-ContainerRunning -Name $PgvectorContainerName)) {
        Throw-Error "pgvector container is not running. Start it with: .\fortisai-dev-helper.ps1 up"
    }

    $exists = (& podman exec $PgvectorContainerName psql -U $PgvectorUser -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DatabaseName';" 2>$null | Select-Object -First 1).Trim()
    if ($exists -eq "1") {
        Write-Log "Postgres database already exists: $DatabaseName"
        return
    }

    Write-Log "Creating Postgres database in pgvector: $DatabaseName"
    & podman exec $PgvectorContainerName psql -U $PgvectorUser -d postgres -c "CREATE DATABASE \"$DatabaseName\" OWNER \"$PgvectorUser\";" *> $null
    if ($LASTEXITCODE -ne 0) {
        Throw-Error "Failed creating Postgres database: $DatabaseName"
    }
}

function Wait-HttpStatus {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [Parameter(Mandatory = $true)][string]$Name,
        [int]$ExpectedStatus = 200,
        [int]$TimeoutSeconds = 120
    )

    $elapsed = 0
    while ($elapsed -lt $TimeoutSeconds) {
        $status = Get-HttpStatusCode -Url $Url
        if ($status -eq $ExpectedStatus) {
            Write-Log "$Name ready (HTTP $status)"
            return $true
        }
        Start-Sleep -Seconds 3
        $elapsed += 3
    }

    Write-Log "$Name did not report HTTP $ExpectedStatus within ${TimeoutSeconds}s"
    return $false
}

function Patch-CodeIndexerForFortisAI {
    Require-Command python
    $mcpFile = Join-Path $CodeIndexerRepoDir "packages/mcp/src/index.ts"
    $embeddingFile = Join-Path $CodeIndexerRepoDir "packages/core/src/embedding/openai-embedding.ts"
    if (-not ((Test-Path $mcpFile) -and (Test-Path $embeddingFile))) {
        Throw-Error "CodeIndexer source files not found under $CodeIndexerRepoDir"
    }

    $previousRepo = $env:CODEINDEXER_REPO_DIR
    try {
        $env:CODEINDEXER_REPO_DIR = $CodeIndexerRepoDir
        @'
from pathlib import Path
import os

repo = Path(os.environ["CODEINDEXER_REPO_DIR"])
mcp = repo / "packages/mcp/src/index.ts"
embedding = repo / "packages/core/src/embedding/openai-embedding.ts"

text = mcp.read_text()
text = text.replace(
"""    openaiApiKey: string;
    milvusAddress: string;
    milvusToken?: string;
}""",
"""    openaiApiKey: string;
    openaiBaseUrl?: string;
    embeddingModel?: string;
    embeddingDimension?: number;
    milvusAddress: string;
    milvusToken?: string;
}""",
)
text = text.replace(
"""        const embedding = new OpenAIEmbedding({
            apiKey: config.openaiApiKey,
            model: 'text-embedding-3-small'
        });""",
"""        const embedding = new OpenAIEmbedding({
            apiKey: config.openaiApiKey,
            baseURL: config.openaiBaseUrl,
            model: config.embeddingModel || 'text-embedding-3-small',
            dimension: config.embeddingDimension
        });""",
)
text = text.replace(
"""        openaiApiKey: process.env.OPENAI_API_KEY || "",
        milvusAddress: process.env.MILVUS_ADDRESS || "localhost:19530",
        milvusToken: process.env.MILVUS_TOKEN
    };""",
"""        openaiApiKey: process.env.OPENAI_API_KEY || "",
        openaiBaseUrl: process.env.OPENAI_BASE_URL || process.env.OPENAI_API_BASE_URL || undefined,
        embeddingModel: process.env.OPENAI_EMBEDDING_MODEL || "text-embedding-3-small",
        embeddingDimension: process.env.OPENAI_EMBEDDING_DIMENSION ? Number(process.env.OPENAI_EMBEDDING_DIMENSION) : undefined,
        milvusAddress: process.env.MILVUS_ADDRESS || "localhost:19530",
        milvusToken: process.env.MILVUS_TOKEN
    };""",
)
text = text.replace(
"""  OPENAI_API_KEY          OpenAI API key (required)
  MILVUS_ADDRESS          Milvus address (default: localhost:19530)""",
"""  OPENAI_API_KEY          OpenAI-compatible API key (required)
  OPENAI_BASE_URL         OpenAI-compatible base URL
  OPENAI_EMBEDDING_MODEL  Embedding model name
  OPENAI_EMBEDDING_DIMENSION Embedding vector dimension
  MILVUS_ADDRESS          Milvus address (default: localhost:19530)""",
)
mcp.write_text(text)

text = embedding.read_text()
text = text.replace(
"""    baseURL?: string; // OpenAI supports custom baseURL
}""",
"""    baseURL?: string; // OpenAI supports custom baseURL
    dimension?: number;
}""",
)
text = text.replace(
"""        // Set dimension based on model
        this.updateDimensionForModel(config.model || 'text-embedding-3-small');""",
"""        // Set dimension based on explicit config or model.
        if (config.dimension && Number.isFinite(config.dimension)) {
            this.dimension = config.dimension;
        } else {
            this.updateDimensionForModel(config.model || 'text-embedding-3-small');
        }""",
)
text = text.replace(
"""        return {
            vector: response.data[0].embedding,
            dimension: this.dimension
        };""",
"""        const vector = response.data[0].embedding;
        if (Array.isArray(vector) && vector.length > 0) {
            this.dimension = vector.length;
        }
        return {
            vector,
            dimension: this.dimension
        };""",
)
text = text.replace(
"""        return response.data.map((item) => ({
            vector: item.embedding,
            dimension: this.dimension
        }));""",
"""        const firstVector = response.data[0]?.embedding;
        if (Array.isArray(firstVector) && firstVector.length > 0) {
            this.dimension = firstVector.length;
        }
        return response.data.map((item) => ({
            vector: item.embedding,
            dimension: this.dimension
        }));""",
)
embedding.write_text(text)
'@ | & python -
        if ($LASTEXITCODE -ne 0) {
            Throw-Error "Failed patching CodeIndexer for FortisAI OpenAI-compatible embeddings"
        }
    }
    finally {
        $env:CODEINDEXER_REPO_DIR = $previousRepo
    }
}

function Setup-CodeIndexerRepo {
    Require-Command git
    New-Item -ItemType Directory -Force -Path $CodeIndexerDir | Out-Null
    New-Item -ItemType Directory -Force -Path $CodeIndexerStateDir | Out-Null

    if (-not (Test-Path (Join-Path $CodeIndexerRepoDir ".git"))) {
        Write-Log "Cloning CodeIndexer repository"
        & git clone $CodeIndexerRepoUrl $CodeIndexerRepoDir
        if ($LASTEXITCODE -ne 0) {
            Throw-Error "Failed cloning CodeIndexer repository"
        }
    }
    else {
        Write-Log "CodeIndexer repository already exists at $CodeIndexerRepoDir"
    }

    Patch-CodeIndexerForFortisAI
}

function Build-CodeIndexerMcp {
    Setup-CodeIndexerRepo
    $builtFile = Join-Path $CodeIndexerRepoDir "packages/mcp/dist/index.js"
    if (Test-Path $builtFile) {
        Write-Log "CodeIndexer MCP build already exists"
        return
    }

    $repoHostDir = $CodeIndexerRepoDir.Replace('\', '/')
    Write-Log "Building CodeIndexer MCP package with Node 20"
    & podman run --rm `
        --network $FortisaiSharedNetwork `
        -v "$repoHostDir`:/codeindexer" `
        -w /codeindexer `
        docker.io/node:20-bookworm `
        sh -lc "corepack enable && corepack prepare pnpm@10.0.0 --activate && pnpm install --frozen-lockfile && pnpm --filter @code-indexer/mcp... build"
    if ($LASTEXITCODE -ne 0) {
        Throw-Error "CodeIndexer MCP build failed"
    }
}

function Start-Milvus {
    Ensure-PodmanMachine
    Ensure-SharedNetwork
    Write-MilvusCompose
    if ((Test-ContainerRunning -Name $MilvusEtcdContainerName) -and
        (Test-ContainerRunning -Name $MilvusMinioContainerName) -and
        (Test-ContainerRunning -Name $MilvusContainerName)) {
        Wait-HttpStatus -Url $MilvusUrl -Name "Milvus" -ExpectedStatus 200 -TimeoutSeconds 180 | Out-Null
        return
    }

    if ((Test-ContainerExists -Name $MilvusEtcdContainerName) -or
        (Test-ContainerExists -Name $MilvusMinioContainerName) -or
        (Test-ContainerExists -Name $MilvusContainerName)) {
        & podman rm -f $MilvusEtcdContainerName $MilvusMinioContainerName $MilvusContainerName *> $null
        Start-Sleep -Seconds 2
    }

    Write-Log "Starting Milvus for CodeIndexer"
    Invoke-Compose -Args @("-f", $MilvusComposeFile, "up", "-d")
    Wait-HttpStatus -Url $MilvusUrl -Name "Milvus" -ExpectedStatus 200 -TimeoutSeconds 180 | Out-Null
}

function Stop-Milvus {
    Ensure-PodmanMachine
    if (Test-Path $MilvusComposeFile) {
        Write-Log "Stopping Milvus"
        Invoke-Compose -Args @("-f", $MilvusComposeFile, "down") *> $null
    }
}

function Start-CodeIndexer {
    Setup-All
    Prepare-VaultRuntimeSecrets
    Write-MilvusCompose
    Start-Milvus
    Build-CodeIndexerMcp
    Write-Log "CodeIndexer MCP build ready; run mcp-up to start the OpenAPI bridge"
}

function Stop-CodeIndexer {
    Ensure-PodmanMachine
    & podman rm -f $CodeIndexerBridgeContainerName *> $null
    Stop-Milvus
}

function Check-CodeIndexer {
    Write-Log "Checking CodeIndexer bridge: $CodeIndexerOpenApiUrl/healthz"
    Test-Http -Url "$CodeIndexerOpenApiUrl/healthz" -Name "codeindexer_bridge"
    Write-Log "Checking Milvus: $MilvusUrl"
    Test-Http -Url $MilvusUrl -Name "milvus"
}

function Start-OpenSearch {
    Ensure-PodmanMachine
    Ensure-SharedNetwork
    Write-OpenSearchCompose
    Write-Log "Starting OpenSearch for OpenMetadata"
    Start-ComposeContainer -ComposeFile $OpenSearchComposeFile -ContainerName $OpenSearchContainerName
    Wait-HttpStatus -Url $OpenSearchUrl -Name "OpenSearch" -ExpectedStatus 200 -TimeoutSeconds 180 | Out-Null
}

function Stop-OpenSearch {
    Ensure-PodmanMachine
    if (Test-Path $OpenSearchComposeFile) {
        Write-Log "Stopping OpenSearch"
        Invoke-Compose -Args @("-f", $OpenSearchComposeFile, "down") *> $null
    }
}

function Invoke-OpenMetadataMigration {
    Write-Log "Running OpenMetadata database migration"
    & podman rm -f fortisai-openmetadata-migrate *> $null
    & podman run --rm --name fortisai-openmetadata-migrate `
        --network $FortisaiSharedNetwork `
        -e "DB_DRIVER_CLASS=org.postgresql.Driver" `
        -e "DB_SCHEME=postgresql" `
        -e "DB_PARAMS=sslmode=disable" `
        -e "DB_USE_SSL=false" `
        -e "DB_USER=$PgvectorUser" `
        -e "DB_USER_PASSWORD=$PgvectorPassword" `
        -e "DB_HOST=$PgvectorContainerName" `
        -e "DB_PORT=5432" `
        -e "OM_DATABASE=$OpenMetadataDbName" `
        -e "ELASTICSEARCH_HOST=$OpenSearchContainerName" `
        -e "ELASTICSEARCH_PORT=9200" `
        -e "ELASTICSEARCH_SCHEME=http" `
        -e "SEARCH_TYPE=opensearch" `
        -e "FERNET_KEY=$OpenMetadataFernetKey" `
        -e "PIPELINE_SERVICE_CLIENT_CLASS_NAME=org.openmetadata.service.clients.pipeline.noop.NoopClient" `
        $OpenMetadataImage ./bootstrap/openmetadata-ops.sh migrate
    if ($LASTEXITCODE -ne 0) {
        Throw-Error "OpenMetadata migration failed"
    }
}

function Start-OpenMetadata {
    Setup-All
    Prepare-VaultRuntimeSecrets
    Write-PgvectorCompose
    Start-ComposeContainer -ComposeFile $PgvectorComposeFile -ContainerName $PgvectorContainerName
    Ensure-PostgresDatabase -DatabaseName $OpenMetadataDbName
    Start-OpenSearch
    Write-OpenMetadataCompose
    Invoke-OpenMetadataMigration
    Write-Log "Starting OpenMetadata"
    Start-ComposeContainer -ComposeFile $OpenMetadataComposeFile -ContainerName $OpenMetadataContainerName
    Wait-HttpStatus -Url "$OpenMetadataUrl/api/v1/system/version" -Name "OpenMetadata" -ExpectedStatus 200 -TimeoutSeconds 240 | Out-Null
}

function Stop-OpenMetadata {
    Ensure-PodmanMachine
    if (Test-Path $OpenMetadataComposeFile) {
        Write-Log "Stopping OpenMetadata"
        Invoke-Compose -Args @("-f", $OpenMetadataComposeFile, "down") *> $null
    }
    Stop-OpenSearch
}

function Check-OpenMetadata {
    Write-Log "Checking OpenMetadata: $OpenMetadataUrl/api/v1/system/version"
    Test-Http -Url "$OpenMetadataUrl/api/v1/system/version" -Name "openmetadata"
    Write-Log "Checking OpenSearch: $OpenSearchUrl"
    Test-Http -Url $OpenSearchUrl -Name "opensearch"
}

function Start-Traefik {
    Setup-All
    Prepare-VaultRuntimeSecrets
    Write-TraefikCompose
    Write-Log "Starting Traefik"
    Start-ComposeContainer -ComposeFile $TraefikComposeFile -ContainerName $TraefikContainerName
    Wait-HttpStatus -Url $TraefikDashboardUrl -Name "Traefik dashboard" -ExpectedStatus 401 -TimeoutSeconds 60 | Out-Null
}

function Stop-Traefik {
    Ensure-PodmanMachine
    if (Test-Path $TraefikComposeFile) {
        Write-Log "Stopping Traefik"
        Invoke-Compose -Args @("-f", $TraefikComposeFile, "down") *> $null
    }
}

function Check-Traefik {
    Write-Log "Checking Traefik web entrypoint: $TraefikUrl"
    Test-Http -Url $TraefikUrl -Name "traefik_web"
    Write-Log "Checking Traefik dashboard auth challenge: $TraefikDashboardUrl"
    Test-Http -Url $TraefikDashboardUrl -Name "traefik_dashboard"
}

function Test-OpenClawPorts {
        if ($OpenClawGatewayPort -eq $OpenClawBridgePort) {
                Throw-Error "OPENCLAW_GATEWAY_PORT and OPENCLAW_BRIDGE_PORT must be different"
        }

        $reservedPorts = @(
                $HonchoHostPort,
                $OracleDbHostPort,
                $OrdsHostPort,
                $AppsmithHostPort,
                $RedisHostPort,
                $RabbitMqHostPort,
                $RabbitMqManagementHostPort,
                $PgvectorHostPort,
                $QdrantHostPort,
                $QdrantGrpcHostPort,
                $FirecrawlHostPort,
                $DaytonaApiHostPort,
                $DaytonaProxyHostPort,
                $DaytonaSshHostPort,
                $DaytonaDexHostPort,
                $DaytonaPgAdminHostPort,
                $DaytonaRegistryUiHostPort,
                $DaytonaRegistryHostPort,
                $DaytonaMaildevHostPort,
                $DaytonaMinioConsoleHostPort,
                $DaytonaJaegerHostPort
        )

        foreach ($reserved in $reservedPorts) {
                if ($OpenClawGatewayPort -eq $reserved -or $OpenClawBridgePort -eq $reserved) {
                        Throw-Error "OpenClaw port conflict detected. OPENCLAW_GATEWAY_PORT=$OpenClawGatewayPort OPENCLAW_BRIDGE_PORT=$OpenClawBridgePort overlaps an existing service port ($reserved)."
                }
        }
}

function Test-HermesPorts {
    if ($HermesGatewayPort -eq $HermesDashboardPort) {
        Throw-Error "HERMES_GATEWAY_PORT and HERMES_DASHBOARD_PORT must be different"
    }

    $reservedPorts = @(
        $HonchoHostPort,
        $OracleDbHostPort,
        $OrdsHostPort,
        $AppsmithHostPort,
        $RedisHostPort,
        $RabbitMqHostPort,
        $RabbitMqManagementHostPort,
        $PgvectorHostPort,
        $QdrantHostPort,
        $QdrantGrpcHostPort,
        $OpenClawGatewayPort,
        $OpenClawBridgePort,
        $FirecrawlHostPort,
        $DaytonaApiHostPort,
        $DaytonaProxyHostPort,
        $DaytonaSshHostPort,
        $DaytonaDexHostPort,
        $DaytonaPgAdminHostPort,
        $DaytonaRegistryUiHostPort,
        $DaytonaRegistryHostPort,
        $DaytonaMaildevHostPort,
        $DaytonaMinioConsoleHostPort,
        $DaytonaJaegerHostPort
    )

    foreach ($reserved in $reservedPorts) {
        if ($HermesGatewayPort -eq $reserved -or $HermesDashboardPort -eq $reserved) {
            Throw-Error "Hermes port conflict detected. HERMES_GATEWAY_PORT=$HermesGatewayPort HERMES_DASHBOARD_PORT=$HermesDashboardPort overlaps an existing service port ($reserved)."
        }
    }
}

function Test-FirecrawlPort {
    $reservedPorts = @(
        5678,
        3000,
        8081,
        $HonchoHostPort,
        $OracleDbHostPort,
        $OrdsHostPort,
        $AppsmithHostPort,
        $RedisHostPort,
        $RabbitMqHostPort,
        $RabbitMqManagementHostPort,
        $PgvectorHostPort,
        $QdrantHostPort,
        $QdrantGrpcHostPort,
        $OpenClawGatewayPort,
        $OpenClawBridgePort,
        $HermesGatewayPort,
        $HermesDashboardPort,
        $DaytonaApiHostPort,
        $DaytonaProxyHostPort,
        $DaytonaSshHostPort,
        $DaytonaDexHostPort,
        $DaytonaPgAdminHostPort,
        $DaytonaRegistryUiHostPort,
        $DaytonaRegistryHostPort,
        $DaytonaMaildevHostPort,
        $DaytonaMinioConsoleHostPort,
        $DaytonaJaegerHostPort
    )

    foreach ($reserved in $reservedPorts) {
        if ($FirecrawlHostPort -eq $reserved) {
            Throw-Error "Firecrawl port conflict detected. FIRECRAWL_HOST_PORT=$FirecrawlHostPort overlaps an existing service port ($reserved)."
        }
    }
}

function Normalize-HermesDashboard {
    $rawValue = ""
    if ($null -ne $HermesDashboard) {
        $rawValue = "$HermesDashboard"
    }
    $normalized = $rawValue.Trim().ToLowerInvariant()

    switch ($normalized) {
        "1" { $script:HermesDashboard = "1"; return }
        "true" { $script:HermesDashboard = "1"; return }
        "yes" { $script:HermesDashboard = "1"; return }
        "on" { $script:HermesDashboard = "1"; return }
        "0" {
            Write-Log "HERMES_DASHBOARD=$rawValue is not allowed during startup; forcing HERMES_DASHBOARD=1"
            $script:HermesDashboard = "1"
            return
        }
        "false" {
            Write-Log "HERMES_DASHBOARD=$rawValue is not allowed during startup; forcing HERMES_DASHBOARD=1"
            $script:HermesDashboard = "1"
            return
        }
        "no" {
            Write-Log "HERMES_DASHBOARD=$rawValue is not allowed during startup; forcing HERMES_DASHBOARD=1"
            $script:HermesDashboard = "1"
            return
        }
        "off" {
            Write-Log "HERMES_DASHBOARD=$rawValue is not allowed during startup; forcing HERMES_DASHBOARD=1"
            $script:HermesDashboard = "1"
            return
        }
        "" {
            Write-Log "HERMES_DASHBOARD is empty; forcing HERMES_DASHBOARD=1"
            $script:HermesDashboard = "1"
            return
        }
        default {
            Write-Log "HERMES_DASHBOARD=$rawValue is invalid; forcing HERMES_DASHBOARD=1"
            $script:HermesDashboard = "1"
            return
        }
    }
}

function Setup-OpenClawRuntime {
        New-Item -ItemType Directory -Force -Path (Join-Path $OpenClawDir "workspace") | Out-Null

    $openAiKeyRef = '`${OPENAI_API_KEY}'
    $openClawBaseUrl = $OpenClawLmStudioBaseUrl
    $openClawModel = $OpenClawLmStudioModel
    $openClawAlias = "LM Studio Local"

    if ($openClawBaseUrl -eq $FortisaiProxyOpenAiBaseUrl -and $openClawModel -eq $FortisaiProxyOpenAiModel) {
        $openClawAlias = "FortisAI Proxy"
    }
    if (-not $openClawModel -or $openClawModel -eq "auto") {
        $openClawModel = "local-model"
        Write-Log "No OpenAI-compatible model override supplied for OpenClaw; using fallback model id: $openClawModel"
    }

        @"
{
    "gateway": {
        "port": 18789,
        "bind": "$OpenClawGatewayBind",
        "auth": {
            "mode": "token",
            "token": "$OpenClawGatewayToken"
        }
    },
    "env": {
        "OPENAI_API_KEY": "$OpenClawOpenAiApiKey",
        "OPENAI_BASE_URL": "$openClawBaseUrl"
    },
    "agents": {
        "defaults": {
            "workspace": "/home/node/.openclaw/workspace",
            "model": {
                "primary": "lmstudio/$openClawModel"
            },
            "models": {
                "lmstudio/$openClawModel": {
                    "alias": "$openClawAlias"
                }
            }
        }
    },
    "models": {
        "mode": "merge",
        "providers": {
            "lmstudio": {
                "baseUrl": "$openClawBaseUrl",
                "apiKey": "$openAiKeyRef",
                "api": "openai-completions",
                "models": [
                    {
                        "id": "$openClawModel",
                        "name": "$openClawAlias",
                        "reasoning": false,
                        "input": [
                            "text"
                        ],
                        "cost": {
                            "input": 0,
                            "output": 0,
                            "cacheRead": 0,
                            "cacheWrite": 0
                        },
                        "contextWindow": 128000,
                        "maxTokens": 8192
                    }
                ]
            }
        }
    },
    "plugins": {
        "entries": {
            "openclaw-honcho": {
                "enabled": true,
                "config": {
                    "baseUrl": "$OpenClawHonchoBaseUrl",
                    "workspaceId": "$OpenClawHonchoWorkspaceId",
                    "apiKey": "$OpenClawHonchoApiKey"
                }
            }
        }
    }
}
"@ | Set-Content -Path $OpenClawRuntimeConfigFile -Encoding UTF8
}

function Write-SqlclMcpConfig {
                New-Item -ItemType Directory -Force -Path $SqlclMcpDir | Out-Null

                $configBaseDir = $BaseDir.Replace('\', '/')
                $configServerFile = $SqlclMcpServerFile.Replace('\', '/')
                $configN8nMcpServerFile = $N8nMcpServerFile.Replace('\\', '/')
                $configWalletEnvFile = $OracleDbWalletEnvFile.Replace('\', '/')
                $n8nApiKey = ""

                if ($env:N8N_API_KEY -and $env:N8N_API_KEY.Trim()) {
                    $n8nApiKey = $env:N8N_API_KEY.Trim()
                }
                elseif (Test-Path $SqlclMcpConfigFile) {
                    try {
                        $existingObj = (Get-Content -Path $SqlclMcpConfigFile -Raw) | ConvertFrom-Json
                        $existingKey = $existingObj.mcpServers.'fortisai-n8n'.env.N8N_API_KEY
                        if ($null -ne $existingKey -and "$existingKey".Trim()) {
                            $n8nApiKey = "$existingKey".Trim()
                        }
                    }
                    catch {
                        $n8nApiKey = ""
                    }
                }

                @"
{
    "mcpServers": {
        "fortisai-sqlcl": {
            "command": "$SqlclMcpPythonCmd",
            "args": [
                "$configServerFile"
            ],
            "env": {
                "FORTISAI_DEV_HOME": "$configBaseDir",
                "SQLCL_CONTAINER_NAME": "$SqlclContainerName",
                "ORACLE_DB_WALLET_ENV_FILE": "$configWalletEnvFile",
                "ORACLE_DB_HOST": "$OracleDbContainerName",
                "ORACLE_DB_PORT": "$OracleDbHostPort",
                "ORACLE_DB_SERVICE_NAME": "$OracleDbPdb",
                "ORACLE_DB_USER": "$OracleDbUser",
                "ORACLE_DB_PASSWORD": "$OracleDbPassword"
            }
        },
        "fortisai-n8n": {
            "command": "$SqlclMcpPythonCmd",
            "args": [
                "$configN8nMcpServerFile"
            ],
            "env": {
                "N8N_BASE_URL": "$N8nUrl",
                "N8N_API_KEY": "$n8nApiKey"
            }
        }
    }
}
"@ | Set-Content -Path $SqlclMcpConfigFile -Encoding UTF8
}

function Write-DaytonaRuntimeCompose {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $DaytonaRuntimeFile) | Out-Null

        $content = Get-Content -Path $DaytonaComposeFile -Raw
        $content = $content -replace '(?m)^(\s*-\s*)3000:3000\s*$', "`$1$DaytonaApiHostPort`:3000"
        $content = $content -replace '(?m)^(\s*-\s*)4000:4000\s*$', "`$1$DaytonaProxyHostPort`:4000"
        $content = $content -replace '(?m)^(\s*-\s*)2222:2222\s*$', "`$1$DaytonaSshHostPort`:2222"
        $content = $content -replace '(?m)^(\s*-\s*)5556:5556\s*$', "`$1$DaytonaDexHostPort`:5556"
        $content = $content -replace '(?m)^(\s*-\s*)5050:80\s*$', "`$1$DaytonaPgAdminHostPort`:80"
        $content = $content -replace '(?m)^(\s*-\s*)5100:80\s*$', "`$1$DaytonaRegistryUiHostPort`:80"
        $content = $content -replace '(?m)^(\s*-\s*)6000:6000\s*$', "`$1$DaytonaRegistryHostPort`:6000"
        $content = $content -replace '(?m)^(\s*-\s*)1080:1080\s*$', "`$1$DaytonaMaildevHostPort`:1080"
        $content = $content -replace '(?m)^(\s*-\s*)9001:9001\s*$', "`$1$DaytonaMinioConsoleHostPort`:9001"
        $content = $content -replace '(?m)^(\s*-\s*)16686:16686\s*$', "`$1$DaytonaJaegerHostPort`:16686"
            $content = $content -replace 'DASHBOARD_URL=http://localhost:3000/dashboard', "DASHBOARD_URL=http://localhost:$DaytonaApiHostPort/dashboard"
            $content = $content -replace 'DASHBOARD_BASE_API_URL=http://localhost:3000', "DASHBOARD_BASE_API_URL=http://localhost:$DaytonaApiHostPort"
            $content = $content -replace 'PUBLIC_OIDC_DOMAIN=http://localhost:5556/dex', "PUBLIC_OIDC_DOMAIN=http://localhost:$DaytonaDexHostPort/dex"
            $content = $content -replace 'OIDC_PUBLIC_DOMAIN=http://localhost:5556/dex', "OIDC_PUBLIC_DOMAIN=http://localhost:$DaytonaDexHostPort/dex"
            $content = $content -replace 'PROXY_DOMAIN=proxy.localhost:4000', "PROXY_DOMAIN=proxy.localhost:$DaytonaProxyHostPort"
            $content = $content -replace 'PROXY_TEMPLATE_URL=http://\{\{PORT\}\}-\{\{sandboxId\}\}\.proxy\.localhost:4000', "PROXY_TEMPLATE_URL=http://{{PORT}}-{{sandboxId}}.proxy.localhost:$DaytonaProxyHostPort"
            $content = $content -replace 'SSH_GATEWAY_URL=localhost:2222', "SSH_GATEWAY_URL=localhost:$DaytonaSshHostPort"
            $content = $content -replace 'SSH_GATEWAY_COMMAND=ssh -p 2222 \{\{TOKEN\}\}@localhost', "SSH_GATEWAY_COMMAND=ssh -p $DaytonaSshHostPort {{TOKEN}}@localhost"
            if ($content -notmatch 'DOCKER_IGNORE_BR_NETFILTER_ERROR=') {
                $content = $content -replace '(?m)^([ \t]*-[ \t]*DAYTONA_RUNNER_TOKEN=.*)$', "$1`r`n      - DOCKER_IGNORE_BR_NETFILTER_ERROR=1"
            }

        if ($content -notmatch '(?m)^networks:') {
            $content = $content.TrimEnd() + "`r`n`r`nnetworks:`r`n  default:`r`n    name: $FortisaiSharedNetwork`r`n    external: true`r`n"
        }

        Set-Content -Path $DaytonaRuntimeFile -Value $content -Encoding UTF8
}

function Setup-DaytonaRepo {
        Require-Command git

        New-Item -ItemType Directory -Force -Path $BaseDir | Out-Null
        if (-not (Test-Path (Join-Path $DaytonaRepoDir ".git"))) {
                Write-Log "Cloning Daytona repository"
                & git clone https://github.com/daytonaio/daytona.git $DaytonaRepoDir
        }
        else {
                Write-Log "Daytona repository already exists at $DaytonaRepoDir"
        }

        if (-not (Test-Path $DaytonaComposeFile)) {
                Throw-Error "Daytona compose file not found: $DaytonaComposeFile"
        }

        $dexConfig = Join-Path $DaytonaRepoDir "docker/dex/config.yaml"
        if (Test-Path $dexConfig) {
            $dexContent = Get-Content -Path $dexConfig -Raw

            $plainRedirect = "http://localhost:$DaytonaApiHostPort'"
            if ($dexContent -notmatch [regex]::Escape($plainRedirect)) {
                $dexContent = $dexContent -replace "http://localhost:3000'", "http://localhost:3000'`n      - 'http://localhost:$DaytonaApiHostPort'"
            }

            $oauthRedirect = "http://localhost:$DaytonaApiHostPort/api/oauth2-redirect.html'"
            if ($dexContent -notmatch [regex]::Escape($oauthRedirect)) {
                $dexContent = $dexContent -replace "http://localhost:3000/api/oauth2-redirect.html'", "http://localhost:3000/api/oauth2-redirect.html'`n      - 'http://localhost:$DaytonaApiHostPort/api/oauth2-redirect.html'"
            }

            Set-Content -Path $dexConfig -Value $dexContent -Encoding UTF8
        }

        Write-DaytonaRuntimeCompose
        Write-Log "Prepared Daytona runtime compose file: $DaytonaRuntimeFile"
        Write-Log "Optional but recommended for Daytona preview URLs:"
        Write-Log "  cd $DaytonaRepoDir ; ./scripts/setup-proxy-dns.sh"
}

function Setup-DifyRepo {
    Require-Command git

    New-Item -ItemType Directory -Force -Path $BaseDir | Out-Null

    if (-not (Test-Path (Join-Path $DifyRepoDir ".git"))) {
        Write-Log "Cloning Dify repository"
        & git clone https://github.com/langgenius/dify.git $DifyRepoDir
    }
    else {
        Write-Log "Dify repository already exists at $DifyRepoDir"
    }

    $difyEnv = Join-Path $DifyDockerDir ".env"
    $difyEnvExample = Join-Path $DifyDockerDir ".env.example"

    if (-not (Test-Path $difyEnv)) {
        Write-Log "Creating Dify .env from template"
        Copy-Item -Path $difyEnvExample -Destination $difyEnv
    }

    Set-OrAddEnvVar -FilePath $difyEnv -Key "EXPOSE_NGINX_PORT" -Value "18081"
    Set-OrAddEnvVar -FilePath $difyEnv -Key "EXPOSE_NGINX_SSL_PORT" -Value "4433"
    Set-OrAddEnvVar -FilePath $difyEnv -Key "DB_TYPE" -Value "postgresql"
    Set-OrAddEnvVar -FilePath $difyEnv -Key "DB_HOST" -Value $PgvectorContainerName
    Set-OrAddEnvVar -FilePath $difyEnv -Key "DB_PORT" -Value "5432"
    Set-OrAddEnvVar -FilePath $difyEnv -Key "DB_DATABASE" -Value $PgvectorDb
    Set-OrAddEnvVar -FilePath $difyEnv -Key "DB_USERNAME" -Value $PgvectorUser
    Set-OrAddEnvVar -FilePath $difyEnv -Key "DB_PASSWORD" -Value $PgvectorPassword
    Set-OrAddEnvVar -FilePath $difyEnv -Key "REDIS_HOST" -Value $RedisContainerName
    Set-OrAddEnvVar -FilePath $difyEnv -Key "REDIS_PORT" -Value "6379"
    Set-OrAddEnvVar -FilePath $difyEnv -Key "REDIS_PASSWORD" -Value ""
    Set-OrAddEnvVar -FilePath $difyEnv -Key "CELERY_BROKER_URL" -Value "redis://$RedisContainerName`:6379/1"
    Set-OrAddEnvVar -FilePath $difyEnv -Key "EVENT_BUS_REDIS_URL" -Value "redis://$RedisContainerName`:6379/2"
    Set-OrAddEnvVar -FilePath $difyEnv -Key "VECTOR_STORE" -Value "qdrant"
    Set-OrAddEnvVar -FilePath $difyEnv -Key "QDRANT_URL" -Value $QdrantInternalUrl
    Set-OrAddEnvVar -FilePath $difyEnv -Key "QDRANT_API_KEY" -Value $QdrantApiKey
    Set-OrAddEnvVar -FilePath $difyEnv -Key "QDRANT_CLIENT_TIMEOUT" -Value "20"
    Set-OrAddEnvVar -FilePath $difyEnv -Key "QDRANT_GRPC_ENABLED" -Value "false"
    Set-OrAddEnvVar -FilePath $difyEnv -Key "QDRANT_GRPC_PORT" -Value "6334"
    Set-OrAddEnvVar -FilePath $difyEnv -Key "FORTISAI_LLAMA_SERVER_URL" -Value $FortisaiLlamaServerUrl
    Set-OrAddEnvVar -FilePath $difyEnv -Key "FORTISAI_LLAMA_SERVER_BASE_URL" -Value $FortisaiLlamaServerBaseUrl
    Set-OrAddEnvVar -FilePath $difyEnv -Key "FORTISAI_LLAMA_OPENAI_BASE_URL" -Value $FortisaiLlamaOpenAiBaseUrl
    Set-OrAddEnvVar -FilePath $difyEnv -Key "FORTISAI_LLAMA_OPENAI_API_KEY" -Value $FortisaiLlamaOpenAiApiKey
    Set-OrAddEnvVar -FilePath $difyEnv -Key "FORTISAI_VAULT_ADDR" -Value $VaultInternalUrl
    Set-OrAddEnvVar -FilePath $difyEnv -Key "VAULT_ADDR" -Value $VaultInternalUrl
    if ($VaultToken) {
        Set-OrAddEnvVar -FilePath $difyEnv -Key "VAULT_TOKEN" -Value $VaultToken
    }
    if ($env:APP_API_KEY) {
        Set-OrAddEnvVar -FilePath $difyEnv -Key "APP_API_KEY" -Value $env:APP_API_KEY
    }
    if ($env:KNOWLEDGE_API_KEY) {
        Set-OrAddEnvVar -FilePath $difyEnv -Key "KNOWLEDGE_API_KEY" -Value $env:KNOWLEDGE_API_KEY
    }
    if ($env:ADMIN_API_KEY) {
        Set-OrAddEnvVar -FilePath $difyEnv -Key "ADMIN_API_KEY_ENABLE" -Value "true"
        Set-OrAddEnvVar -FilePath $difyEnv -Key "ADMIN_API_KEY" -Value $env:ADMIN_API_KEY
    }

    # -----------------------------------------------------------------------
    # podman-compose (all versions) does not honour `required: false` in
    # depends_on when the referenced service is profile-gated.  Dify's compose
    # file has api, worker, worker_beat, and plugin_daemon depending on
    # alternative database containers (db_postgres, db_mysql, oceanbase,
    # seekdb) with required: false, causing a KeyError at startup.
    #
    # Fix: patch docker-compose.yaml in-place (once, with a .orig backup) to
    # remove those profile-gated depends_on entries and any depends_on: blocks
    # left empty after removal.
    # -----------------------------------------------------------------------
    $composeFile = Join-Path $DifyDockerDir "docker-compose.yaml"
    if (Test-Path $composeFile) {
        Write-Log "Patching Dify docker-compose.yaml for podman-compose compatibility"
        $patchScript = @'
import os, re, sys, shutil
f = sys.argv[1]
bak = f + ".orig"
if not os.path.exists(bak):
    shutil.copy2(f, bak)
with open(f) as fp:
    content = fp.read()
for svc in ("db_postgres", "db_mysql", "oceanbase", "seekdb"):
    pattern = rf"      {svc}:\n        condition: service_healthy\n        required: false\n"
    content = re.sub(pattern, "", content)
content = re.sub(r"      redis:\n        condition: service_started\n", "", content)

redis_service_pattern = r"\n  redis:\n(?:    .*\n)*?(?=\n  [A-Za-z0-9_-]+:)"
content = re.sub(redis_service_pattern, "\n", content, count=1)

redis_comment_block_pattern = r"\n  # The redis cache\.\n(?:  #.*\n)*  redis:\n(?:    .*\n)*?(?=\n  # The DifySandbox)"
content = re.sub(redis_comment_block_pattern, "\n", content, count=1)

content = re.sub(r"    depends_on:\n(?=\s{0,4}\S|\s*\n)", "", content)

# Ensure Dify services resolve shared FortisAI service names.
content = content.replace(
    "networks:\n  default:\n    driver: bridge\n",
    "networks:\n  default:\n    name: fortisai-dev-net\n    external: true\n"
)
with open(f, "w") as fp:
    fp.write(content)
print("docker-compose.yaml patched; original saved as docker-compose.yaml.orig")
'@
        $tmpScript = Join-Path $env:TEMP "dify_patch.py"
        Set-Content -Path $tmpScript -Value $patchScript -Encoding UTF8
        & python $tmpScript $composeFile
        Remove-Item $tmpScript -ErrorAction SilentlyContinue
    }

    if (Test-Path $composeFile) {
        $composeContent = Get-Content -Path $composeFile -Raw
        $serviceNames = @([regex]::Matches($composeContent, '(?m)^  ([A-Za-z0-9_-]+):\s*$') | ForEach-Object { $_.Groups[1].Value })
        $vaultTargets = @("api", "worker", "worker_beat", "web", "plugin_daemon", "sandbox") | Where-Object { $serviceNames -contains $_ }
        if ($vaultTargets.Count -eq 0) {
            Remove-Item -Path $DifyVaultComposeFile -ErrorAction SilentlyContinue
        }
        else {
            $vaultAddrYaml = $VaultInternalUrl | ConvertTo-Json -Compress
            $vaultTokenYaml = $VaultToken | ConvertTo-Json -Compress
            $llamaServerUrlYaml = $FortisaiLlamaServerUrl | ConvertTo-Json -Compress
            $llamaServerBaseUrlYaml = $FortisaiLlamaServerBaseUrl | ConvertTo-Json -Compress
            $llamaOpenAiBaseUrlYaml = $FortisaiLlamaOpenAiBaseUrl | ConvertTo-Json -Compress
            $llamaOpenAiApiKeyYaml = $FortisaiLlamaOpenAiApiKey | ConvertTo-Json -Compress
            $vaultOverrideLines = @("services:")
            foreach ($serviceName in $vaultTargets) {
                $vaultOverrideLines += @(
                    "  ${serviceName}:",
                    "    environment:",
                    "      FORTISAI_VAULT_ADDR: $vaultAddrYaml",
                    "      VAULT_ADDR: $vaultAddrYaml",
                    "      VAULT_TOKEN: $vaultTokenYaml",
                    "      FORTISAI_LLAMA_SERVER_URL: $llamaServerUrlYaml",
                    "      FORTISAI_LLAMA_SERVER_BASE_URL: $llamaServerBaseUrlYaml",
                    "      FORTISAI_LLAMA_OPENAI_BASE_URL: $llamaOpenAiBaseUrlYaml",
                    "      FORTISAI_LLAMA_OPENAI_API_KEY: $llamaOpenAiApiKeyYaml"
                )
            }
            Set-Content -Path $DifyVaultComposeFile -Value (($vaultOverrideLines -join "`n") + "`n") -Encoding UTF8
        }
    }

    if ((Test-Path $composeFile) -and (-not (Select-String -Path $composeFile -Pattern 'QDRANT_HOST_PORT' -Quiet))) {
        $composeContent = Get-Content -Path $composeFile -Raw
        $replacement = @'
$1    ports:
      - "${QDRANT_HOST_PORT:-6333}:6333"
      - "${QDRANT_GRPC_HOST_PORT:-6334}:6334"
'@
        $composeContent = [regex]::Replace($composeContent, '(?ms)(  qdrant:\r?\n.*?    volumes:\r?\n      - \./volumes/qdrant:/qdrant/storage\r?\n)', $replacement, 1)
        Set-Content -Path $composeFile -Value $composeContent -Encoding UTF8
    }

    if ((Test-Path $difyEnv) -and (-not (Select-String -Path $difyEnv -Pattern '^FORTISAI_ORACLE_DB_HOST=' -Quiet))) {
        Add-Content -Path $difyEnv -Value @"

# FortisAI local Oracle AI Database Free connection details
FORTISAI_SHARED_NETWORK=$FortisaiSharedNetwork
FORTISAI_ORACLE_DB_HOST=fortisai-oracle-db
FORTISAI_ORACLE_DB_PORT=$OracleDbHostPort
FORTISAI_ORACLE_DB_PDB=$OracleDbPdb
FORTISAI_ORACLE_DB_USER=$OracleDbUser
FORTISAI_ORACLE_DB_PASSWORD=$OracleDbPassword
FORTISAI_VAULT_ADDR=$VaultInternalUrl
VAULT_ADDR=$VaultInternalUrl
"@
    }
}

function Setup-OracleWalletDir {
    New-Item -ItemType Directory -Force -Path $OracleWalletDir | Out-Null

    if (-not (Test-Path $OracleDbWalletEnvFile)) {
        @"
ORACLE_DB_HOST=$OracleDbContainerName
ORACLE_DB_PORT=$OracleDbHostPort
ORACLE_DB_SERVICE_NAME=$OracleDbPdb
ORACLE_DB_USER=$OracleDbUser
ORACLE_DB_PASSWORD=$OracleDbPassword
ORACLE_DB_CONNECT_STRING=localhost:$OracleDbHostPort/$OracleDbPdb
ORACLE_WALLET_DIR=/opt/oracle/wallet
TNS_ADMIN=/opt/oracle/wallet
"@ | Set-Content -Path $OracleDbWalletEnvFile -Encoding UTF8
        & chmod 600 $OracleDbWalletEnvFile 2>$null
    }

    if (-not (Test-Path $OracleDbWalletScriptFile)) {
        @'
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ ! -f "$SCRIPT_DIR/oracle-db.env" ]]; then
  echo "Missing wallet env file: $SCRIPT_DIR/oracle-db.env" >&2
  exit 1
fi

. "$SCRIPT_DIR/oracle-db.env"

cat <<EOF
ORACLE_DB_HOST=$ORACLE_DB_HOST
ORACLE_DB_PORT=$ORACLE_DB_PORT
ORACLE_DB_SERVICE_NAME=$ORACLE_DB_SERVICE_NAME
ORACLE_DB_USER=$ORACLE_DB_USER
ORACLE_DB_PASSWORD=$ORACLE_DB_PASSWORD
ORACLE_WALLET_DIR=$ORACLE_WALLET_DIR
TNS_ADMIN=$TNS_ADMIN
EOF
'@ | Set-Content -Path $OracleDbWalletScriptFile -Encoding UTF8
        try { & chmod +x $OracleDbWalletScriptFile } catch {}
    }

    if (-not (Test-Path $OracleWalletEnvFile)) {
        @'
#!/usr/bin/env bash
set -euo pipefail

export ORACLE_WALLET_DIR="${ORACLE_WALLET_DIR:-$HOME/fortisai-dev/oracle-wallet}"
export ORACLE_WALLET_ZIP="${ORACLE_WALLET_ZIP:-$ORACLE_WALLET_DIR/oracle-wallet.zip}"
export ORACLE_WALLET_UNZIP_DIR="${ORACLE_WALLET_UNZIP_DIR:-$ORACLE_WALLET_DIR/unzipped}"
export TNS_ADMIN="${TNS_ADMIN:-$ORACLE_WALLET_UNZIP_DIR}"
'@ | Set-Content -Path $OracleWalletEnvFile -Encoding UTF8
    }

    if (-not (Test-Path $OracleWalletSetupFile)) {
        @'
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$SCRIPT_DIR/unzipped"

echo "Oracle wallet directory ready: $SCRIPT_DIR"
echo "Place an OCI wallet zip at: $SCRIPT_DIR/oracle-wallet.zip"
echo "Source this file to export wallet variables: . $SCRIPT_DIR/wallet-env.sh"
echo "Run the credentials helper for DB inputs and ewallet.p12 generation: $SCRIPT_DIR/oracle-wallet-credentials.sh --help"
'@ | Set-Content -Path $OracleWalletSetupFile -Encoding UTF8
    }

        if (-not (Test-Path $OracleWalletCredentialsHelpFile)) {
                @'
#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: oracle-wallet-credentials.sh [options]

Collect Oracle wallet credential metadata and optionally build ewallet.p12 from
separate certificate and private key files.

Options:
    --wallet-dir DIR           Wallet directory to populate
    --db-host HOST             Oracle DB host name
    --db-port PORT             Oracle DB listener port
    --db-service-name NAME     Oracle DB service name or PDB
    --db-user USER             Database user name
    --db-password PASSWORD     Database password
    --connect-string STRING    JDBC-style connect string to record
    --certificate-file FILE    PEM certificate file to ingest into ewallet.p12
    --private-key-file FILE    PEM private key file to ingest into ewallet.p12
    --p12-output FILE          Output path for ewallet.p12
    --p12-password PASSWORD    Password used to protect ewallet.p12
    --alias NAME               Friendly alias to embed in the PKCS#12 bundle
    --help                     Show this help

If a value is not supplied on the command line, the script prompts for it.
EOF
}

prompt_value() {
    local label="$1"
    local current_value="$2"
    local secret_flag="${3:-false}"
    local input_value=""

    if [[ -n "$current_value" ]]; then
        printf '%s\n' "$current_value"
        return 0
    fi

    if [[ "$secret_flag" == true ]]; then
        read -r -s -p "$label: " input_value
        printf '\n'
    else
        read -r -p "$label: " input_value
    fi

    printf '%s\n' "$input_value"
}

wallet_dir="${ORACLE_WALLET_DIR:-$HOME/fortisai-dev/oracle-wallet}"
db_host=""
db_port=""
db_service_name=""
db_user=""
db_password=""
connect_string=""
certificate_file=""
private_key_file=""
p12_output=""
p12_password=""
alias_name="oracle-wallet"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --wallet-dir)
            wallet_dir="$2"
            shift 2
            ;;
        --db-host)
            db_host="$2"
            shift 2
            ;;
        --db-port)
            db_port="$2"
            shift 2
            ;;
        --db-service-name)
            db_service_name="$2"
            shift 2
            ;;
        --db-user)
            db_user="$2"
            shift 2
            ;;
        --db-password)
            db_password="$2"
            shift 2
            ;;
        --connect-string)
            connect_string="$2"
            shift 2
            ;;
        --certificate-file)
            certificate_file="$2"
            shift 2
            ;;
        --private-key-file)
            private_key_file="$2"
            shift 2
            ;;
        --p12-output)
            p12_output="$2"
            shift 2
            ;;
        --p12-password)
            p12_password="$2"
            shift 2
            ;;
        --alias)
            alias_name="$2"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

New-Item -ItemType Directory -Force -Path $wallet_dir | Out-Null

db_host="$(prompt_value 'Oracle DB host' $db_host)"
db_port="$(prompt_value 'Oracle DB port' $db_port)"
db_service_name="$(prompt_value 'Oracle DB service name' $db_service_name)"
db_user="$(prompt_value 'Oracle DB user' $db_user)"
db_password="$(prompt_value 'Oracle DB password' $db_password true)"
connect_string="$(prompt_value 'Oracle DB connect string' $connect_string)"

if [[ -z "$connect_string" ]]; then
    connect_string="${db_host}:${db_port}/${db_service_name}"
fi

if [[ -n "$certificate_file" || -n "$private_key_file" ]]; then
    if [[ -z "$certificate_file" || -z "$private_key_file" ]]; then
        echo "Both --certificate-file and --private-key-file are required together." >&2
        exit 1
    fi

    if [[ -z "$p12_output" ]]; then
        p12_output="$wallet_dir/ewallet.p12"
    fi

    if [[ -z "$p12_password" ]]; then
        p12_password="$(prompt_value 'ewallet.p12 password' $p12_password true)"
    fi

    if ! command -v openssl >/dev/null 2>&1; then
        echo "openssl is required to build ewallet.p12 from certificate and private key files." >&2
        exit 1
    fi

    & openssl pkcs12 -export -in $certificate_file -inkey $private_key_file -out $p12_output -name $alias_name -passout "pass:$p12_password"
fi

@"
ORACLE_DB_HOST=$db_host
ORACLE_DB_PORT=$db_port
ORACLE_DB_SERVICE_NAME=$db_service_name
ORACLE_DB_USER=$db_user
ORACLE_DB_PASSWORD=$db_password
ORACLE_DB_CONNECT_STRING=$connect_string
ORACLE_WALLET_DIR=$wallet_dir
ORACLE_WALLET_P12=$p12_output
ORACLE_WALLET_CERTIFICATE_FILE=$certificate_file
ORACLE_WALLET_PRIVATE_KEY_FILE=$private_key_file
"@ | Set-Content -Path (Join-Path $wallet_dir "oracle-wallet-credentials.env") -Encoding UTF8

try { & chmod 600 (Join-Path $wallet_dir "oracle-wallet-credentials.env") } catch {}

Write-Host "Oracle wallet credential helper complete."
Write-Host "Wallet directory: $wallet_dir"
Write-Host "Credential env file: $(Join-Path $wallet_dir 'oracle-wallet-credentials.env')"
'@ | Set-Content -Path $OracleWalletCredentialsHelpFile -Encoding UTF8
                try { & chmod +x $OracleWalletCredentialsHelpFile } catch {}
        }
}

function Setup-ConfigRepos {
    Require-Command git

    $difyConfigDir = Join-Path $ConfigReposDir "dify-config"
    $n8nConfigDir = Join-Path $ConfigReposDir "n8n-config"

    New-Item -ItemType Directory -Force -Path (Join-Path $difyConfigDir "apps") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $difyConfigDir "prompts") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $difyConfigDir "datasets") | Out-Null

    New-Item -ItemType Directory -Force -Path (Join-Path $n8nConfigDir "workflows") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $n8nConfigDir "credentials") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $n8nConfigDir "metadata") | Out-Null

    $difyReadme = Join-Path $difyConfigDir "README.md"
    if (-not (Test-Path $difyReadme)) {
        @"
# dify-config

Git-managed Dify configuration repository.

Recommended naming:
- apps/<domain>-<capability>.yaml
- prompts/<domain>-<purpose>.yaml
- datasets/<domain>-<dataset>.yaml
"@ | Set-Content -Path $difyReadme -Encoding UTF8
    }

    $n8nReadme = Join-Path $n8nConfigDir "README.md"
    if (-not (Test-Path $n8nReadme)) {
        @"
# n8n-config

Git-managed n8n workflow configuration repository.

Recommended naming:
- workflows/<domain>-<workflow>.json
- metadata/<domain>-tags.json
- credentials/README.md
"@ | Set-Content -Path $n8nReadme -Encoding UTF8
    }

    $sampleDify = Join-Path $difyConfigDir "apps/customer-support-agent.yaml"
    if (-not (Test-Path $sampleDify)) {
        @"
app:
  name: customer-support-agent
  environment: dev
  notes: replace this starter file with an exported Dify YAML artifact
"@ | Set-Content -Path $sampleDify -Encoding UTF8
    }

    $sampleN8n = Join-Path $n8nConfigDir "workflows/lead-intake.json"
    if (-not (Test-Path $sampleN8n)) {
        @"
{
  "name": "lead-intake",
  "active": false,
  "nodes": [],
  "connections": {},
  "meta": {
    "notes": "replace this starter file with an exported n8n workflow JSON artifact"
  }
}
"@ | Set-Content -Path $sampleN8n -Encoding UTF8
    }

    $credReadme = Join-Path $n8nConfigDir "credentials/README.md"
    if (-not (Test-Path $credReadme)) {
        @"
# credentials

Do not commit exported secrets or live credential payloads.
Store only documentation or placeholder references in this directory.
"@ | Set-Content -Path $credReadme -Encoding UTF8
    }

    foreach ($repo in @($difyConfigDir, $n8nConfigDir)) {
        if (-not (Test-Path (Join-Path $repo ".git"))) {
            Push-Location $repo
            & git init | Out-Null
            & git branch -M main | Out-Null
            Pop-Location
        }
    }

    Write-Log "Scaffolded config repositories under $ConfigReposDir"
}

function Scaffold-Templates {
    param(
        [string]$Mode = "all",
        [string]$Name = ""
    )

    if ($Mode -notin @("all", "dify", "n8n")) {
        Throw-Error "Unknown scaffold target: $Mode. Use all, dify, or n8n."
    }

    if ($Name -and $Name -notmatch '^[A-Za-z0-9._-]+$') {
        Throw-Error "Invalid name: '$Name' (allowed: letters, numbers, dot, underscore, hyphen)."
    }

    Setup-ConfigRepos

    $difyTemplate = Join-Path $TemplatesDir "dify/app-template.yaml"
    $n8nTemplate = Join-Path $TemplatesDir "n8n/workflow-template.json"

    if ($Mode -in @("all", "dify")) {
        if (-not (Test-Path $difyTemplate)) {
            Throw-Error "Missing Dify template: $difyTemplate"
        }

        $difyName = if ($Name) { $Name } else { "example-dify-app" }
        $difyTarget = Join-Path $ConfigReposDir "dify-config/apps/$difyName.yaml"
        if (Test-Path $difyTarget) {
            Write-Log "Dify scaffold target already exists, skipping: $difyTarget"
        }
        else {
            $content = Get-Content -Path $difyTemplate -Raw
            $content = $content.Replace("APP_NAME_PLACEHOLDER", $difyName)
            $content = $content.Replace("MODEL_NAME_PLACEHOLDER", "claude-3.7-sonnet-reasoning-gemma3-12B")
            Set-Content -Path $difyTarget -Value $content -Encoding UTF8
            Write-Log "Created Dify config from template: $difyTarget"
        }
    }

    if ($Mode -in @("all", "n8n")) {
        if (-not (Test-Path $n8nTemplate)) {
            Throw-Error "Missing n8n template: $n8nTemplate"
        }

        $n8nName = if ($Name) { $Name } else { "example-n8n-workflow" }
        $n8nTarget = Join-Path $ConfigReposDir "n8n-config/workflows/$n8nName.json"
        if (Test-Path $n8nTarget) {
            Write-Log "n8n scaffold target already exists, skipping: $n8nTarget"
        }
        else {
            $workflowId = [guid]::NewGuid().ToString()
            $content = Get-Content -Path $n8nTemplate -Raw
            $content = $content.Replace("WORKFLOW_NAME_PLACEHOLDER", $n8nName)
            $content = $content.Replace("WORKFLOW_ID_PLACEHOLDER", $workflowId)
            Set-Content -Path $n8nTarget -Value $content -Encoding UTF8
            Write-Log "Created n8n workflow from template: $n8nTarget"
        }
    }
}

function Setup-All {
    Require-Command podman
    Require-Command curl
    Require-Command jq
    Normalize-HermesDashboard
    Test-FirecrawlPort
    Test-OpenClawPorts
    Test-HermesPorts

    Ensure-PodmanMachine
    Ensure-SharedNetwork
    Setup-OracleWalletDir
    Prepare-VaultRuntimeSecrets
    Pull-OracleDbImage
    Pull-OrdsSqlclImages
    Write-N8nCompose
    Write-OpenWebUiCompose
    Write-OpenVscodeCompose
    Write-MongodbCompose
    Write-AppsmithCompose
    Write-RedisCompose
    Write-RabbitMqCompose
    Write-VaultCompose
    Write-FirecrawlCompose
    Write-PgvectorCompose
    Write-MilvusCompose
    Write-OpenSearchCompose
    Write-OpenMetadataCompose
    Write-TraefikCompose
    Write-OracleDbCompose
    Write-OrdsCompose
    Write-SqlclCompose
    Write-SqlclMcpConfig
    Setup-HonchoRepo
    Setup-OpenApiServersRepo
    Write-OpenApiServersOpenWebUiTemplate
    Write-HonchoCompose
    Setup-OpenClawRuntime
    Write-OpenClawCompose
    Write-HermesCompose
    if (-not (Test-Path $OracleNodeApiComposeFile)) {
        Throw-Error "Oracle Node API compose file not found: $OracleNodeApiComposeFile"
    }
    Setup-DifyRepo

    Write-Log "Setup complete"
    Write-Log "Base directory: $BaseDir"
    Write-Log "Oracle wallet directory: $OracleWalletDir"
    Write-Log "SQLcl MCP config: $SqlclMcpConfigFile"
}

function Import-N8nWorkflows {
    Ensure-PodmanMachine
    $importer = Join-Path $DevEnvDir "n8n-config/import-n8n-workflows.sh"
    if (-not (Test-Path $importer)) {
        Throw-Error "n8n importer script not found: $importer"
    }
    if (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
        Throw-Error "bash is required to run the n8n workflow importer on Windows. Use Git Bash or WSL."
    }

    Start-Vault
    Unseal-Vault
    Write-N8nCompose
    Start-N8nStack

    $previousApiUrl = $env:N8N_API_URL
    try {
        if (-not $env:N8N_API_URL) {
            $env:N8N_API_URL = "http://127.0.0.1:5678/api/v1"
        }
        if (-not $env:N8N_API_KEY) {
            Write-Log "N8N_API_KEY is not available; importer will use local n8n CLI activation if needed"
        }
        & bash $importer
        if ($LASTEXITCODE -ne 0) {
            Throw-Error "n8n workflow importer failed"
        }
    }
    finally {
        if ($null -eq $previousApiUrl) {
            Remove-Item Env:N8N_API_URL -ErrorAction SilentlyContinue
        }
        else {
            $env:N8N_API_URL = $previousApiUrl
        }
    }
}

function Start-N8nStack {
    if ((Test-ContainerRunning -Name "fortisai-n8n") -and (Test-ContainerRunning -Name "fortisai-n8n-workflow-runner")) {
        return
    }

    if ((Test-ContainerExists -Name "fortisai-n8n") -or (Test-ContainerExists -Name "fortisai-n8n-workflow-runner")) {
        & podman rm -f fortisai-n8n fortisai-n8n-workflow-runner *> $null
        Start-Sleep -Seconds 2
    }

    Refresh-ContainerVaultRuntimeEnv -Name "fortisai-n8n" -ComposeFile $N8nComposeFile
    Invoke-Compose -Args @("-f", $N8nComposeFile, "up", "-d")
}

function Start-All {
    Setup-All

    Start-Vault
    Unseal-Vault
    Sync-VaultRuntimeSecrets

    Write-Log "Starting Oracle AI Database Free"
    Invoke-Compose -Args @("-f", $OracleDbComposeFile, "up", "-d")

    Wait-OracleDbReady
    Initialize-OrdsConfig

    Write-Log "Starting n8n"
    Start-N8nStack

    Write-Log "Starting OpenWebUI"
    Start-OpenWebUi

    Write-Log "Starting OpenVSCode"
    Start-OpenVscode

    Write-Log "Starting MongoDB"
    Invoke-Compose -Args @("-f", $MongodbComposeFile, "up", "-d")

    Ensure-MongodbReplicaSet

    Write-Log "Starting Appsmith"
    Refresh-ContainerVaultRuntimeEnv -Name $AppsmithContainerName -ComposeFile $AppsmithComposeFile
    Invoke-Compose -Args @("-f", $AppsmithComposeFile, "up", "-d")

    Write-Log "Starting OpenAPI servers"
    Refresh-ContainerVaultRuntimeEnv -Name "fortisai-openapi-filesystem" -ComposeFile $OpenApiServersComposeFile
    Refresh-ContainerVaultRuntimeEnv -Name "fortisai-openapi-memory" -ComposeFile $OpenApiServersComposeFile
    Refresh-ContainerVaultRuntimeEnv -Name "fortisai-openapi-time" -ComposeFile $OpenApiServersComposeFile
    Invoke-Compose -Args @("-f", $OpenApiServersComposeFile, "up", "-d")
    Sync-RepoOpenApiServersIntoOpenWebUi

    Write-Log "Starting Redis"
    Invoke-Compose -Args @("-f", $RedisComposeFile, "up", "-d")

    Write-Log "Starting RabbitMQ"
    Invoke-Compose -Args @("-f", $RabbitMqComposeFile, "up", "-d")

    Write-Log "Starting pgvector"
    Invoke-Compose -Args @("-f", $PgvectorComposeFile, "up", "-d")

    Ensure-FirecrawlDatabase

    Write-Log "Starting Firecrawl"
    Refresh-ContainerVaultRuntimeEnv -Name $FirecrawlContainerName -ComposeFile $FirecrawlComposeFile
    Invoke-Compose -Args @("-f", $FirecrawlComposeFile, "up", "-d")

    Ensure-HonchoDatabase

    Write-Log "Starting Honcho (API + deriver)"
    Refresh-ContainerVaultRuntimeEnv -Name $HonchoApiContainerName -ComposeFile $HonchoComposeFile
    Refresh-ContainerVaultRuntimeEnv -Name $HonchoDeriverContainerName -ComposeFile $HonchoComposeFile
    Invoke-Compose -Args @("-f", $HonchoComposeFile, "up", "-d", "--build")

    Write-Log "Starting Dify (qdrant profile; shared Redis + pgvector)"
    Refresh-DifyVaultRuntimeEnv
    Push-Location $DifyDockerDir
    $difyComposeArgs = @(Get-DifyComposeFileArgs)
    Invoke-Compose -Args ($difyComposeArgs + @("--profile", "qdrant", "up", "-d"))
    Pop-Location

    Write-Log "Starting ORDS"
    Invoke-Compose -Args @("-f", $OrdsComposeFile, "up", "-d")

    Write-Log "Starting SQLcl sidecar"
    Invoke-Compose -Args @("-f", $SqlclComposeFile, "up", "-d")

    Write-Log "Starting Oracle Node API"
    Refresh-ContainerVaultRuntimeEnv -Name $OracleNodeApiContainerName -ComposeFile $OracleNodeApiComposeFile
    Invoke-Compose -Args @("-f", $OracleNodeApiComposeFile, "up", "-d", "--build")

    Write-Log "SQLcl MCP config ready: $SqlclMcpConfigFile"

    Write-Log "All services started"
}

function Stop-All {
    Ensure-PodmanMachine

    if (Test-Path $OracleDbComposeFile) {
        Write-Log "Stopping Oracle AI Database Free"
        Invoke-Compose -Args @("-f", $OracleDbComposeFile, "down")
    }

    if (Test-Path $N8nComposeFile) {
        Write-Log "Stopping n8n"
        Invoke-Compose -Args @("-f", $N8nComposeFile, "down")
    }

    if (Test-Path $OpenWebUiComposeFile) {
        Write-Log "Stopping OpenWebUI"
        Stop-OpenWebUi
    }

    if (Test-Path $OpenVscodeComposeFile) {
        Write-Log "Stopping OpenVSCode"
        Stop-OpenVscode
    }

    if (Test-Path $AppsmithComposeFile) {
        Write-Log "Stopping Appsmith"
        Invoke-Compose -Args @("-f", $AppsmithComposeFile, "down")
    }

    if (Test-Path $MongodbComposeFile) {
        Write-Log "Stopping MongoDB"
        Invoke-Compose -Args @("-f", $MongodbComposeFile, "down")
    }

    if (Test-Path $OpenApiServersComposeFile) {
        Write-Log "Stopping OpenAPI servers"
        Invoke-Compose -Args @("-f", $OpenApiServersComposeFile, "down")
    }

    if (Test-Path $RedisComposeFile) {
        Write-Log "Stopping Redis"
        Invoke-Compose -Args @("-f", $RedisComposeFile, "down")
    }

    if (Test-Path $RabbitMqComposeFile) {
        Write-Log "Stopping RabbitMQ"
        Invoke-Compose -Args @("-f", $RabbitMqComposeFile, "down")
    }

    if (Test-Path $VaultComposeFile) {
        Write-Log "Stopping HashiCorp Vault"
        Invoke-Compose -Args @("-f", $VaultComposeFile, "down")
    }

    if (Test-Path $FirecrawlComposeFile) {
        Write-Log "Stopping Firecrawl"
        Invoke-Compose -Args @("-f", $FirecrawlComposeFile, "down")
    }

    if (Test-Path $PgvectorComposeFile) {
        Write-Log "Stopping pgvector"
        Invoke-Compose -Args @("-f", $PgvectorComposeFile, "down")
    }

    if (Test-Path $HonchoComposeFile) {
        Write-Log "Stopping Honcho"
        Invoke-Compose -Args @("-f", $HonchoComposeFile, "down")
    }

    if (Test-Path (Join-Path $DifyDockerDir "docker-compose.yml") -or (Test-Path (Join-Path $DifyDockerDir "docker-compose.yaml"))) {
        Write-Log "Stopping Dify"
        Push-Location $DifyDockerDir
        $difyComposeArgs = @(Get-DifyComposeFileArgs)
        Invoke-Compose -Args ($difyComposeArgs + @("--profile", "qdrant", "down"))
        Pop-Location
    }

    if (Test-Path $OrdsComposeFile) {
        Write-Log "Stopping ORDS"
        Invoke-Compose -Args @("-f", $OrdsComposeFile, "down")
    }

    if (Test-Path $SqlclComposeFile) {
        Write-Log "Stopping SQLcl sidecar"
        Invoke-Compose -Args @("-f", $SqlclComposeFile, "down")
    }

    if (Test-Path $OracleNodeApiComposeFile) {
        Write-Log "Stopping Oracle Node API"
        Invoke-Compose -Args @("-f", $OracleNodeApiComposeFile, "down")
    }

    Write-Log "All services stopped"
}

function Start-FullStack {
    Prepare-VaultRuntimeSecrets
    Start-All
    Start-CodeIndexer
    Start-OpenMetadata
    Start-McpUp
    Start-OpenClaw
    Start-Hermes
    Start-Daytona
    Start-Traefik
    Write-Log "all-up completed successfully"
}

function Stop-FullStack {
    Stop-Traefik
    Stop-Daytona
    Stop-McpDown
    Stop-Hermes
    Stop-OpenClaw
    Stop-OpenMetadata
    Stop-CodeIndexer
    Stop-All
    Write-Log "all-down completed successfully"
}

function Show-Status {
    Ensure-PodmanMachine
    & podman ps --format "table {{.Names}}`t{{.Status}}`t{{.Ports}}"
    if (Test-Path $SqlclMcpConfigFile) {
        Write-Host "sqlcl_mcp_config: $SqlclMcpConfigFile"
    }
    else {
        Write-Host "sqlcl_mcp_config: not-generated"
    }
    if (Test-Path $OpenApiServersJsonTemplateFile) {
        Write-Host "openapi_openwebui_template: $OpenApiServersJsonTemplateFile"
    }
    else {
        Write-Host "openapi_openwebui_template: not-generated"
    }
}

function Show-Logs {
    param([string]$LogTarget)

    Ensure-PodmanMachine

    switch ($LogTarget.ToLowerInvariant()) {
        "oracle-db" { & podman logs -f $OracleDbContainerName }
        "n8n" { & podman logs -f fortisai-n8n }
        "openwebui" { & podman logs -f fortisai-openwebui }
        "openvscode" { & podman logs -f $OpenVscodeContainerName }
        "appsmith" { & podman logs -f $AppsmithContainerName }
        "mongodb" { & podman logs -f $MongodbContainerName }
        "redis" { & podman logs -f $RedisContainerName }
        "rabbitmq" { & podman logs -f $RabbitMqContainerName }
        "vault" { & podman logs -f $VaultContainerName }
        "firecrawl" { & podman logs -f $FirecrawlContainerName }
        "pgvector" { & podman logs -f $PgvectorContainerName }
        "traefik" { & podman logs -f $TraefikContainerName }
        "codeindexer" { & podman logs -f $CodeIndexerBridgeContainerName }
        "milvus" { & podman logs -f $MilvusContainerName }
        "openmetadata" { & podman logs -f $OpenMetadataContainerName }
        "opensearch" { & podman logs -f $OpenSearchContainerName }
        "honcho" { Invoke-Compose -Args @("-f", $HonchoComposeFile, "logs", "-f", "api", "deriver") }
        "openapi-servers" { Invoke-Compose -Args @("-f", $OpenApiServersComposeFile, "logs", "-f", "filesystem-server", "memory-server", "time-server") }
        "openclaw" { & podman logs -f $OpenClawContainerName }
        "hermes" { & podman logs -f $HermesContainerName }
        "qdrant" {
            Push-Location $DifyDockerDir
            $difyComposeArgs = @(Get-DifyComposeFileArgs)
            Invoke-Compose -Args ($difyComposeArgs + @("logs", "-f", "qdrant"))
            Pop-Location
        }
        "dify" {
            Push-Location $DifyDockerDir
            $difyComposeArgs = @(Get-DifyComposeFileArgs)
            Invoke-Compose -Args ($difyComposeArgs + @("logs", "-f"))
            Pop-Location
        }
        "daytona" {
            Push-Location $DaytonaRepoDir
            Invoke-Compose -Args @("-f", $DaytonaRuntimeFile, "logs", "-f")
            Pop-Location
        }
        "ords" { & podman logs -f $OrdsContainerName }
        "sqlcl" { & podman logs -f $SqlclContainerName }
        "oracle-node-api" { & podman logs -f $OracleNodeApiContainerName }
        default { Throw-Error "Unknown logs target: $LogTarget. Use oracle-db, mongodb, redis, rabbitmq, vault, firecrawl, pgvector, honcho, openapi-servers, openclaw, hermes, n8n, openwebui, openvscode, appsmith, qdrant, dify, daytona, traefik, codeindexer, milvus, openmetadata, opensearch, ords, sqlcl, or oracle-node-api." }
    }
}

function Test-Http {
    param([string]$Url, [string]$Name)

    try {
        $response = Invoke-WebRequest -Uri $Url -Method Head -TimeoutSec 10
        Write-Host "$Name HTTP $($response.StatusCode)"
    }
    catch {
        $statusCode = $null
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }

        if ($statusCode) {
            Write-Host "$Name HTTP $statusCode"
        }
        else {
            Write-Host "$Name HTTP unavailable"
        }
    }
}

function Check-Services {
    Write-Log "Checking Oracle AI Database Free on port $OracleDbHostPort"
    if (Test-ContainerRunning -Name $OracleDbContainerName) {
        try {
            $null = & podman exec $OracleDbContainerName bash -lc "printf 'select 1 from dual;`nexit`n' | sqlplus -L pdbadmin/$OracleDbPassword@FREEPDB1" 2>$null
            Write-Host "oracle-db SQL check passed"
        }
        catch {
            Write-Host "oracle-db SQL check unavailable"
        }
    }
    else {
        Write-Host "oracle-db not running"
    }

    Write-Log "Checking n8n: $N8nUrl"
    Test-Http -Url $N8nUrl -Name "n8n"

    Write-Log "Checking OpenWebUI: $OpenWebUiUrl"
    Test-Http -Url $OpenWebUiUrl -Name "openwebui"

    Write-Log "Checking Appsmith: $AppsmithUrl"
    Test-Http -Url $AppsmithUrl -Name "appsmith"

    Write-Log "Checking MongoDB: $MongodbContainerName"
    if (Test-ContainerRunning -Name $MongodbContainerName) {
        try {
            & podman exec $MongodbContainerName mongosh --quiet --eval 'db.adminCommand({ ping: 1 }).ok' *> $null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "mongodb ping passed"
            }
            else {
                Write-Host "mongodb ping unavailable"
            }
        }
        catch {
            Write-Host "mongodb ping unavailable"
        }
    }
    else {
        Write-Host "mongodb not running"
    }

    Write-Log "Checking Redis: $RedisContainerName"
    if (Test-ContainerRunning -Name $RedisContainerName) {
        try {
            $ping = (& podman exec $RedisContainerName redis-cli ping 2>$null | Select-Object -First 1).Trim()
            if ($ping -eq "PONG") {
                Write-Host "redis ping passed"
            }
            else {
                Write-Host "redis ping unavailable"
            }
        }
        catch {
            Write-Host "redis ping unavailable"
        }
    }
    else {
        Write-Host "redis not running"
    }

    Write-Log "Checking RabbitMQ: $RabbitMqContainerName"
    if (Test-ContainerRunning -Name $RabbitMqContainerName) {
        try {
            & podman exec $RabbitMqContainerName rabbitmq-diagnostics -q ping *> $null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "rabbitmq ping passed"
            }
            else {
                Write-Host "rabbitmq ping unavailable"
            }
        }
        catch {
            Write-Host "rabbitmq ping unavailable"
        }
    }
    else {
        Write-Host "rabbitmq not running"
    }

    Write-Log "Checking RabbitMQ management URL: $RabbitMqManagementUrl"
    Test-Http -Url $RabbitMqManagementUrl -Name "rabbitmq_mgmt"

    Write-Log "Checking Vault: $VaultUrl/v1/sys/health"
    Test-Http -Url "$VaultUrl/v1/sys/health" -Name "vault"

    Write-Log "Checking Firecrawl: $FirecrawlContainerName"
    if (Test-ContainerRunning -Name $FirecrawlContainerName) {
        Test-Http -Url "$FirecrawlUrl/health" -Name "firecrawl"
    }
    else {
        Write-Host "firecrawl not running"
    }

    Write-Log "Checking Traefik: $TraefikDashboardUrl"
    Test-Http -Url $TraefikDashboardUrl -Name "traefik_dashboard"

    Write-Log "Checking CodeIndexer bridge: $CodeIndexerOpenApiUrl/healthz"
    Test-Http -Url "$CodeIndexerOpenApiUrl/healthz" -Name "codeindexer_bridge"

    Write-Log "Checking Milvus: $MilvusUrl"
    Test-Http -Url $MilvusUrl -Name "milvus"

    Write-Log "Checking OpenMetadata: $OpenMetadataUrl/api/v1/system/version"
    Test-Http -Url "$OpenMetadataUrl/api/v1/system/version" -Name "openmetadata"

    Write-Log "Checking OpenSearch: $OpenSearchUrl"
    Test-Http -Url $OpenSearchUrl -Name "opensearch"

    Write-Log "Checking pgvector: $PgvectorContainerName"
    if (Test-ContainerRunning -Name $PgvectorContainerName) {
        try {
            & podman exec $PgvectorContainerName pg_isready -U $PgvectorUser -d $PgvectorDb *> $null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "pgvector SQL check passed"
            }
            else {
                Write-Host "pgvector SQL check unavailable"
            }
        }
        catch {
            Write-Host "pgvector SQL check unavailable"
        }
    }
    else {
        Write-Host "pgvector not running"
    }

    Write-Log "Checking Honcho: $HonchoUrl/health"
    Test-Http -Url "$HonchoUrl/health" -Name "honcho"

    Write-Log "Checking OpenClaw: $OpenClawContainerName"
    if (Test-ContainerRunning -Name $OpenClawContainerName) {
        Test-Http -Url "$OpenClawUrl/health" -Name "openclaw"
    }
    else {
        Write-Host "openclaw not running (optional service)"
    }

    Write-Log "Checking Hermes: $HermesContainerName"
    if (Test-ContainerRunning -Name $HermesContainerName) {
        Test-Http -Url "$HermesUrl/health" -Name "hermes"
    }
    else {
        Write-Host "hermes not running (optional service)"
    }

    Write-Log "Checking Dify: $DifyUrl"
    Test-Http -Url $DifyUrl -Name "dify"

    Write-Log "Checking Qdrant: $QdrantUrl/collections"
    try {
        $response = Invoke-WebRequest -Uri "$QdrantUrl/collections" -Headers @{ 'api-key' = $QdrantApiKey } -TimeoutSec 10
        Write-Host "qdrant HTTP $($response.StatusCode)"
    }
    catch {
        Write-Host "qdrant HTTP unavailable"
    }

    Write-Log "Checking ORDS: $OrdsUrl"
    Test-Http -Url $OrdsUrl -Name "ords"

    Write-Log "Checking Oracle Node API: $OracleNodeApiUrl/health"
    Test-Http -Url "$OracleNodeApiUrl/health" -Name "oracle-node-api"

    Write-Log "Checking SQLcl sidecar: $SqlclContainerName"
    if (& podman ps --format "{{.Names}}" | Select-String -Quiet -Pattern "^$SqlclContainerName$") {
        Write-Host "sqlcl container running"
    }
    else {
        Write-Host "sqlcl container not running"
    }

    Write-Log "Checking SQLcl MCP config: $SqlclMcpConfigFile"
    if (Test-Path $SqlclMcpConfigFile) {
        Write-Host "sqlcl MCP config ready"
    }
    else {
        Write-Host "sqlcl MCP config not generated"
    }
}

function Start-SqlclShell {
    Ensure-PodmanMachine

    if (-not (Test-ContainerRunning -Name $SqlclContainerName)) {
        Throw-Error "SQLcl container is not running. Start it with: .\fortisai-dev-helper.ps1 up"
    }

    & podman exec -it $SqlclContainerName /bin/sh -lc 'if [ -f /opt/oracle/wallet/oracle-db.env ]; then . /opt/oracle/wallet/oracle-db.env; fi; export TNS_ADMIN="${TNS_ADMIN:-/opt/oracle/wallet}"; sql /nolog'
}

function Start-OpenClawShell {
    Ensure-PodmanMachine

    if (-not (Test-ContainerRunning -Name $OpenClawContainerName)) {
        Throw-Error "OpenClaw container is not running. Start it with: .\fortisai-dev-helper.ps1 openclaw-up"
    }

    Write-Log "Opening shell in $OpenClawContainerName"
    & podman exec -it $OpenClawContainerName /bin/sh -lc 'if command -v bash >/dev/null 2>&1; then exec bash; else exec sh; fi'
}

function Start-OpenWebUiShell {
    Ensure-PodmanMachine

    if (-not (Test-ContainerRunning -Name "fortisai-openwebui")) {
        Throw-Error "OpenWebUI container is not running. Start it with: .\fortisai-dev-helper.ps1 up"
    }

    Write-Log "Opening shell in fortisai-openwebui"
    & podman exec -it fortisai-openwebui /bin/sh -lc 'if command -v bash >/dev/null 2>&1; then exec bash; else exec sh; fi'
}

function Start-OpenVscodeShell {
    param([string]$User = "")
    Ensure-PodmanMachine

    $containerName = Get-OpenVscodeContainerForUser -User $User
    if (-not $containerName) { Throw-Error "Unknown OpenVSCode user: $(if ($User) { $User } else { 'default' })" }

    if (-not (Test-ContainerRunning -Name $containerName)) {
        Throw-Error "OpenVSCode container is not running: $containerName. Start it with: .\fortisai-dev-helper.ps1 openvscode-up"
    }

    Write-Log "Opening shell in $containerName"
    & podman exec -it $containerName /bin/sh -lc 'if command -v bash >/dev/null 2>&1; then exec bash; else exec sh; fi'
}

function Update-OpenWebUiDifyBridgeConnection {
    if (-not (Test-ContainerRunning -Name "fortisai-openwebui")) {
        Write-Log "Skipping OpenWebUI wiring (fortisai-openwebui is not running)"
        return
    }

    $containerOpenApiUrl = $McpDifyOpenApiUrl -replace '127\.0\.0\.1', 'fortisai-mcp-openapi-dify'
    $containerOpenApiUrl = $containerOpenApiUrl -replace 'localhost', 'fortisai-mcp-openapi-dify'
    $pythonScript = @'
import json
import os
import sqlite3

db_path = "/app/backend/data/webui.db"
openapi_url = os.environ["MCP_DIFY_OPENAPI_URL"]
base_url = openapi_url.replace("/openapi.json", "")

conn = sqlite3.connect(db_path)
try:
    cur = conn.cursor()
    row = cur.execute("SELECT id, data FROM config ORDER BY id DESC LIMIT 1").fetchone()
    if not row:
        raise SystemExit("OpenWebUI config row not found")

    config_id, config_json = row
    data = json.loads(config_json or "{}")
    tool_server = data.setdefault("tool_server", {})
    connections = tool_server.setdefault("connections", [])

    replacement = {
        "url": base_url,
        "path": "openapi.json",
        "type": "openapi",
        "auth_type": "bearer",
        "headers": None,
        "key": "",
        "config": {
            "enable": True,
            "function_name_filter_list": "",
            "access_grants": [],
        },
        "info": {
            "id": "",
            "name": "mcp-dify-server",
            "description": "Dify MCP OpenAPI bridge",
        },
        "spec_type": "url",
        "spec": "",
    }

    replaced = False
    for idx, entry in enumerate(connections):
        if not isinstance(entry, dict):
            continue
        entry_name = (entry.get("info") or {}).get("name") or entry.get("name")
        if entry_name == "mcp-dify-server":
            connections[idx] = replacement
            replaced = True
            break

    if not replaced:
        connections.append(replacement)

    cur.execute("UPDATE config SET data = ? WHERE id = ?", (json.dumps(data), config_id))
    conn.commit()
    print("OpenWebUI tool_server connection upserted: mcp-dify-server")
finally:
    conn.close()
'@

    Write-Log "Wiring Dify bridge into OpenWebUI tool_server.connections"
    & podman exec -e "MCP_DIFY_OPENAPI_URL=$containerOpenApiUrl" fortisai-openwebui python -c $pythonScript

    if ($LASTEXITCODE -ne 0) {
        Write-Log "Dify OpenWebUI tool reload skipped; OpenWebUI config is not initialized yet"
        return
    }
}

function Update-OpenWebUiCodeIndexerBridgeConnection {
    if (-not (Test-ContainerRunning -Name $OpenWebUiContainerName)) {
        Write-Log "Skipping OpenWebUI CodeIndexer wiring ($OpenWebUiContainerName is not running)"
        return
    }

    $containerOpenApiUrl = $McpCodeIndexerOpenApiUrl -replace '127\.0\.0\.1', 'fortisai-mcp-openapi-codeindexer'
    $containerOpenApiUrl = $containerOpenApiUrl -replace 'localhost', 'fortisai-mcp-openapi-codeindexer'
    $pythonScript = @'
import json
import os
import sqlite3

db_path = "/app/backend/data/webui.db"
openapi_url = os.environ["MCP_CODEINDEXER_OPENAPI_URL"]
base_url = openapi_url.replace("/openapi.json", "")

conn = sqlite3.connect(db_path)
try:
    cur = conn.cursor()
    row = cur.execute("SELECT id, data FROM config ORDER BY id DESC LIMIT 1").fetchone()
    if not row:
        raise SystemExit("OpenWebUI config row not found")

    config_id, config_json = row
    data = json.loads(config_json or "{}")
    tool_server = data.setdefault("tool_server", {})
    connections = tool_server.setdefault("connections", [])

    replacement = {
        "url": base_url,
        "path": "openapi.json",
        "type": "openapi",
        "auth_type": "none",
        "headers": None,
        "key": "",
        "config": {
            "enable": True,
            "function_name_filter_list": "",
            "access_grants": [],
        },
        "info": {
            "id": "",
            "name": "mcp-codeindexer-server",
            "description": "CodeIndexer MCP OpenAPI bridge",
        },
        "spec_type": "url",
        "spec": "",
    }

    replaced = False
    for idx, entry in enumerate(connections):
        if not isinstance(entry, dict):
            continue
        entry_name = (entry.get("info") or {}).get("name") or entry.get("name")
        if entry_name == "mcp-codeindexer-server":
            connections[idx] = replacement
            replaced = True
            break

    if not replaced:
        connections.append(replacement)

    cur.execute("UPDATE config SET data = ? WHERE id = ?", (json.dumps(data), config_id))
    conn.commit()
    print("OpenWebUI tool_server connection upserted: mcp-codeindexer-server")
finally:
    conn.close()
'@

    Write-Log "Wiring CodeIndexer bridge into OpenWebUI tool_server.connections"
    & podman exec -e "MCP_CODEINDEXER_OPENAPI_URL=$containerOpenApiUrl" $OpenWebUiContainerName python -c $pythonScript
    if ($LASTEXITCODE -ne 0) {
        Write-Log "CodeIndexer OpenWebUI tool reload skipped; OpenWebUI config is not initialized yet"
        return
    }

    if ((Get-Command bash -ErrorAction SilentlyContinue) -and (Test-Path $CodeIndexerOpenWebUiSkillCreateFile)) {
        $previousContainer = $env:OPENWEBUI_CONTAINER
        $previousUrl = $env:OPENWEBUI_URL
        try {
            $env:OPENWEBUI_CONTAINER = $OpenWebUiContainerName
            $env:OPENWEBUI_URL = $OpenWebUiUrl
            & bash (Join-Path $McpRootDir "create-openwebui-skill.sh") $CodeIndexerOpenWebUiSkillCreateFile
            if ($LASTEXITCODE -ne 0) {
                Write-Log "CodeIndexer OpenWebUI skill import did not complete; payload remains importable at $CodeIndexerOpenWebUiSkillCreateFile"
            }
        }
        finally {
            $env:OPENWEBUI_CONTAINER = $previousContainer
            $env:OPENWEBUI_URL = $previousUrl
        }
    }
    else {
        Write-Log "CodeIndexer OpenWebUI skill payload remains importable at $CodeIndexerOpenWebUiSkillCreateFile"
    }
}

function Test-OpenWebUiCoreDnsActive {
    $running = & podman inspect $FortisAiCoreDnsContainerName --format '{{.State.Running}}' 2>$null
    return ($LASTEXITCODE -eq 0 -and $running -eq "true")
}

function New-OpenWebUiRuntimeToolImportPayload {
    param(
        [Parameter(Mandatory = $true)][string]$ImportFile
    )

    $runtimeFile = Join-Path ([System.IO.Path]::GetTempPath()) ("fortisai-openwebui-tool-{0}.json" -f ([System.Guid]::NewGuid().ToString("N")))
    $payload = Get-Content -Raw -Path $ImportFile | ConvertFrom-Json
    $corednsActive = Test-OpenWebUiCoreDnsActive
    $zone = $FortisAiCalicoDnsZone
    $services = [ordered]@{
        "filesystem-server" = "8000"
        "memory-server" = "8000"
        "time-server" = "8000"
        "fortisai-mcp-openapi-sqlcl" = "8091"
        "fortisai-mcp-openapi-n8n" = "8092"
        "fortisai-mcp-openapi-dify" = "8093"
        "fortisai-mcp-openapi-debug" = "8094"
        "fortisai-mcp-openapi-proxmox" = "8095"
        "fortisai-mcp-openapi-codeindexer" = "8096"
        "fortisai-hermes" = "8642"
        "fortisai-claw-gateway" = "18789"
    }

    function Convert-OpenWebUiRuntimeUrl {
        param([string]$Value)
        foreach ($service in $services.Keys) {
            $port = $services[$service]
            $short = "http://${service}:${port}"
            $fqdn = "http://${service}.${zone}:${port}"
            $targetHost = if ($corednsActive) { "${service}.${zone}" } else { $service }
            $target = "http://${targetHost}:${port}"
            if ($Value.StartsWith($short)) {
                return $target + $Value.Substring($short.Length)
            }
            if ($Value.StartsWith($fqdn)) {
                return $target + $Value.Substring($fqdn.Length)
            }
        }
        return $Value
    }

    function Update-OpenWebUiRuntimePayloadValue {
        param($Value)
        if ($null -eq $Value) { return $null }
        if ($Value -is [string]) { return Convert-OpenWebUiRuntimeUrl -Value $Value }
        if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string]) -and -not ($Value -is [System.Management.Automation.PSCustomObject])) {
            return @($Value | ForEach-Object { Update-OpenWebUiRuntimePayloadValue -Value $_ })
        }
        if ($Value -is [System.Management.Automation.PSCustomObject]) {
            foreach ($property in $Value.PSObject.Properties) {
                $property.Value = Update-OpenWebUiRuntimePayloadValue -Value $property.Value
            }
        }
        return $Value
    }

    $payload = Update-OpenWebUiRuntimePayloadValue -Value $payload
    $payload | ConvertTo-Json -Depth 32 | Set-Content -Path $runtimeFile -Encoding UTF8
    return $runtimeFile
}

function Import-OpenWebUiToolConnectionFromPayload {
    param(
        [Parameter(Mandatory = $true)][string]$ImportFile,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if (-not (Test-ContainerRunning -Name $OpenWebUiContainerName)) {
        Write-Log "Skipping OpenWebUI $Label tool wiring ($OpenWebUiContainerName is not running)"
        return $false
    }

    if (-not (Test-Path $ImportFile)) {
        Throw-Error "OpenWebUI $Label tool import payload not found: $ImportFile"
    }

    if (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
        Write-Log "Skipping OpenWebUI $Label tool import because bash is not available; payload remains importable at $ImportFile"
        return $false
    }

    $runtimeImportFile = New-OpenWebUiRuntimeToolImportPayload -ImportFile $ImportFile
    Write-Log "Wiring $Label bridge into OpenWebUI tool_server.connections"
    $previousContainer = $env:OPENWEBUI_CONTAINER
    try {
        $env:OPENWEBUI_CONTAINER = $OpenWebUiContainerName
        $scriptOutput = & bash (Join-Path $McpRootDir "reload-openwebui-tool-connection.sh") $runtimeImportFile 2>&1
        $scriptExitCode = $LASTEXITCODE
        foreach ($line in $scriptOutput) {
            Write-Host $line
        }
        if ($scriptExitCode -ne 0) {
            Write-Log "$Label OpenWebUI tool reload skipped; OpenWebUI container exec/API is not available"
            return $false
        }
        return $true
    }
    finally {
        $env:OPENWEBUI_CONTAINER = $previousContainer
        if ($runtimeImportFile -and (Test-Path $runtimeImportFile)) {
            Remove-Item -Force $runtimeImportFile -ErrorAction SilentlyContinue
        }
    }
}

function Import-OpenWebUiSkillFromPayload {
    param(
        [Parameter(Mandatory = $true)][string]$SkillFile,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if (-not (Test-ContainerRunning -Name $OpenWebUiContainerName)) {
        Write-Log "Skipping OpenWebUI $Label skill import ($OpenWebUiContainerName is not running)"
        return $false
    }

    if (-not (Test-Path $SkillFile)) {
        Throw-Error "OpenWebUI $Label skill payload not found: $SkillFile"
    }

    if (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
        Write-Log "Skipping OpenWebUI $Label skill import because bash is not available; payload remains importable at $SkillFile"
        return $false
    }

    Write-Log "Importing $Label skill into OpenWebUI"
    $previousContainer = $env:OPENWEBUI_CONTAINER
    $previousUrl = $env:OPENWEBUI_URL
    try {
        $env:OPENWEBUI_CONTAINER = $OpenWebUiContainerName
        $env:OPENWEBUI_URL = $OpenWebUiUrl
        $scriptOutput = & bash (Join-Path $McpRootDir "create-openwebui-skill.sh") $SkillFile 2>&1
        $scriptExitCode = $LASTEXITCODE
        foreach ($line in $scriptOutput) {
            Write-Host $line
        }
        if ($scriptExitCode -ne 0) {
            Write-Log "$Label OpenWebUI skill import did not complete; the payload remains importable at $SkillFile"
            return $false
        }
        return $true
    }
    finally {
        $env:OPENWEBUI_CONTAINER = $previousContainer
        $env:OPENWEBUI_URL = $previousUrl
    }
}

function Sync-OpenWebUiToolAndSkill {
    param(
        [Parameter(Mandatory = $true)][string]$ImportFile,
        [Parameter(Mandatory = $true)][string]$SkillFile,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if (Import-OpenWebUiToolConnectionFromPayload -ImportFile $ImportFile -Label $Label) {
        Import-OpenWebUiSkillFromPayload -SkillFile $SkillFile -Label $Label | Out-Null
    }
}

function Sync-RepoOpenApiServersIntoOpenWebUi {
    Sync-OpenWebUiToolAndSkill -ImportFile $RepoFilesystemOpenWebUiToolsImportFile -SkillFile $RepoFilesystemOpenWebUiSkillCreateFile -Label "Repo filesystem"
    Sync-OpenWebUiToolAndSkill -ImportFile $RepoMemoryOpenWebUiToolsImportFile -SkillFile $RepoMemoryOpenWebUiSkillCreateFile -Label "Repo memory"
    Sync-OpenWebUiToolAndSkill -ImportFile $RepoTimeOpenWebUiToolsImportFile -SkillFile $RepoTimeOpenWebUiSkillCreateFile -Label "Repo time"
}

function Sync-McpOpenApiBridgesIntoOpenWebUi {
    Sync-OpenWebUiToolAndSkill -ImportFile $SqlclOpenWebUiToolsImportFile -SkillFile $SqlclOpenWebUiSkillCreateFile -Label "SQLcl"
    Sync-OpenWebUiToolAndSkill -ImportFile $N8nOpenWebUiToolsImportFile -SkillFile $N8nOpenWebUiSkillCreateFile -Label "n8n"
    Sync-OpenWebUiToolAndSkill -ImportFile $DifyOpenWebUiToolsImportFile -SkillFile $DifyOpenWebUiSkillCreateFile -Label "Dify"
    Sync-OpenWebUiToolAndSkill -ImportFile $CodeIndexerOpenWebUiToolsImportFile -SkillFile $CodeIndexerOpenWebUiSkillCreateFile -Label "CodeIndexer"
    Sync-OpenWebUiToolAndSkill -ImportFile $ProxmoxOpenWebUiToolsImportFile -SkillFile $ProxmoxOpenWebUiSkillCreateFile -Label "Proxmox"
}

function Start-HermesShell {
    Ensure-PodmanMachine

    if (-not (Test-ContainerRunning -Name $HermesContainerName)) {
        Throw-Error "Hermes container is not running. Start it with: .\fortisai-dev-helper.ps1 hermes-up"
    }

    Write-Log "Opening shell in $HermesContainerName"
    & podman exec -it $HermesContainerName /bin/sh -lc 'if command -v bash >/dev/null 2>&1; then exec bash; else exec sh; fi'
}

function Start-SqlclMcp {
    Require-Command $SqlclMcpPythonCmd

    if (-not (Test-Path $SqlclMcpServerFile)) {
        Throw-Error "SQLcl MCP server entrypoint not found: $SqlclMcpServerFile"
    }

    $previousValues = @{
        FORTISAI_DEV_HOME = $env:FORTISAI_DEV_HOME
        SQLCL_CONTAINER_NAME = $env:SQLCL_CONTAINER_NAME
        ORACLE_DB_WALLET_ENV_FILE = $env:ORACLE_DB_WALLET_ENV_FILE
        ORACLE_DB_HOST = $env:ORACLE_DB_HOST
        ORACLE_DB_PORT = $env:ORACLE_DB_PORT
        ORACLE_DB_SERVICE_NAME = $env:ORACLE_DB_SERVICE_NAME
        ORACLE_DB_USER = $env:ORACLE_DB_USER
        ORACLE_DB_PASSWORD = $env:ORACLE_DB_PASSWORD
    }

    try {
        $env:FORTISAI_DEV_HOME = $BaseDir
        $env:SQLCL_CONTAINER_NAME = $SqlclContainerName
        $env:ORACLE_DB_WALLET_ENV_FILE = $OracleDbWalletEnvFile
        $env:ORACLE_DB_HOST = $OracleDbContainerName
        $env:ORACLE_DB_PORT = "$OracleDbHostPort"
        $env:ORACLE_DB_SERVICE_NAME = $OracleDbPdb
        $env:ORACLE_DB_USER = $OracleDbUser
        $env:ORACLE_DB_PASSWORD = $OracleDbPassword

        & $SqlclMcpPythonCmd $SqlclMcpServerFile
    }
    finally {
        foreach ($entry in $previousValues.GetEnumerator()) {
            if ($null -eq $entry.Value) {
                Remove-Item "Env:$($entry.Key)" -ErrorAction SilentlyContinue
            }
            else {
                Set-Item "Env:$($entry.Key)" $entry.Value
            }
        }
    }
}

function Start-SqlclMcpSmoke {
    Require-Command $SqlclMcpPythonCmd

    if (-not (Test-Path $SqlclMcpConfigFile)) {
        Throw-Error "SQLcl MCP config not found: $SqlclMcpConfigFile. Run .\fortisai-dev-helper.ps1 setup"
    }

    $previousConfig = $env:SQLCL_MCP_CONFIG_FILE
    try {
        $env:SQLCL_MCP_CONFIG_FILE = $SqlclMcpConfigFile
        & $SqlclMcpPythonCmd -c @'
import json
import os
import subprocess
import sys
from pathlib import Path

config = json.loads(Path(os.environ["SQLCL_MCP_CONFIG_FILE"]).read_text())
server = config["mcpServers"]["fortisai-sqlcl"]
env = dict(os.environ)
env.update(server.get("env", {}))

proc = subprocess.Popen(
    [server["command"], *server["args"]],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    env=env,
)

def send(message):
    body = json.dumps(message).encode("utf-8")
    proc.stdin.write(f"Content-Length: {len(body)}\r\n\r\n".encode("ascii") + body)
    proc.stdin.flush()

def recv():
    headers = {}
    while True:
        line = proc.stdout.readline()
        if not line:
            raise RuntimeError("MCP server closed stdout")
        if line in (b"\r\n", b"\n"):
            break
        key, value = line.decode("utf-8").split(":", 1)
        headers[key.strip().lower()] = value.strip()
    body = proc.stdout.read(int(headers["content-length"]))
    return json.loads(body.decode("utf-8"))

send({
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
        "protocolVersion": "2024-11-05",
        "capabilities": {},
        "clientInfo": {"name": "fortisai-sqlcl-mcp-smoke", "version": "1.0"},
    },
})
init_response = recv()
send({"jsonrpc": "2.0", "method": "notifications/initialized", "params": {}})
send({
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {"name": "sqlcl_connection_info", "arguments": {}},
})
tool_response = recv()

print(json.dumps(init_response, indent=2))
print(json.dumps(tool_response, indent=2))

proc.terminate()
proc.wait(timeout=5)

stderr = proc.stderr.read().decode("utf-8").strip()
if stderr:
    print(stderr, file=sys.stderr)
'@
    }
    finally {
        if ($null -eq $previousConfig) {
            Remove-Item Env:SQLCL_MCP_CONFIG_FILE -ErrorAction SilentlyContinue
        }
        else {
            $env:SQLCL_MCP_CONFIG_FILE = $previousConfig
        }
    }
}

function Get-N8nApiKeyForMcp {
    if ($env:N8N_API_KEY -and $env:N8N_API_KEY.Trim()) {
        return $env:N8N_API_KEY.Trim()
    }

    if (-not (Test-Path $SqlclMcpConfigFile)) {
        return ""
    }

    try {
        $raw = Get-Content -Path $SqlclMcpConfigFile -Raw
        $obj = $raw | ConvertFrom-Json
        $key = $obj.mcpServers.'fortisai-n8n'.env.N8N_API_KEY
        if ($null -ne $key) {
            return "$key".Trim()
        }
    }
    catch {
        return ""
    }

    return ""
}

function Get-HttpStatusCode {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [int]$TimeoutSec = 5
    )

    try {
        $response = Invoke-WebRequest -Uri $Url -Method Get -TimeoutSec $TimeoutSec
        return [int]$response.StatusCode
    }
    catch {
        return 0
    }
}

function Start-McpBridgeContainer {
    param(
        [Parameter(Mandatory = $true)][string]$ContainerName,
        [Parameter(Mandatory = $true)][int]$HostPort,
        [Parameter(Mandatory = $true)][int]$BridgePort,
        [Parameter(Mandatory = $true)][string]$BridgeScriptRelativePath,
        [Parameter(Mandatory = $true)][string]$PipPackages,
        [Parameter(Mandatory = $true)][hashtable]$EnvMap,
        [Parameter(Mandatory = $true)][string]$RepoRoot
    )

    & podman rm -f $ContainerName *> $null

    $runArgs = @(
        "run", "-d",
        "--name", $ContainerName,
        "--restart", "unless-stopped",
        "--network", $FortisaiSharedNetwork,
        "-p", "$HostPort`:$BridgePort",
        "-v", "$RepoRoot`:/workspace:ro",
        "-e", "PYTHONDONTWRITEBYTECODE=1",
        "-e", "PYTHONUNBUFFERED=1"
    )

    foreach ($entry in $EnvMap.GetEnumerator()) {
        $runArgs += @("-e", "$($entry.Key)=$($entry.Value)")
    }

    $command = "pip install --no-cache-dir $PipPackages >/tmp/pip.log 2>&1 && python /workspace/$BridgeScriptRelativePath"
    $runArgs += @("docker.io/python:3.11-slim", "sh", "-lc", $command)

    & podman @runArgs *> $null
    if ($LASTEXITCODE -ne 0) {
        Throw-Error "Failed to start bridge container: $ContainerName"
    }

    Write-Log "Started $ContainerName"
}

function Start-CodeIndexerMcpBridgeContainer {
    param([Parameter(Mandatory = $true)][string]$RepoRoot)

    & podman rm -f $CodeIndexerBridgeContainerName *> $null

    $repoRootHost = $RepoRoot.Replace('\', '/')
    $codeIndexerRepoHost = $CodeIndexerRepoDir.Replace('\', '/')
    $codeIndexerStateHost = $CodeIndexerStateDir.Replace('\', '/')

    $runArgs = @(
        "run", "-d",
        "--name", $CodeIndexerBridgeContainerName,
        "--restart", "unless-stopped",
        "--network", $FortisaiSharedNetwork,
        "-p", "${CodeIndexerBridgeHostPort}:8096",
        "-v", "$repoRootHost`:/workspace:ro",
        "-v", "$codeIndexerRepoHost`:/codeindexer",
        "-v", "$codeIndexerStateHost`:/codeindexer-state",
        "-e", "CODEINDEXER_BRIDGE_PORT=8096",
        "-e", "CODEINDEXER_REPO_DIR=/codeindexer",
        "-e", "CODEINDEXER_STATE_DIR=/codeindexer-state",
        "-e", "CODEINDEXER_WORKSPACE=/workspace",
        "-e", "CODEINDEXER_HOST_WORKSPACE=$RepoRoot",
        "-e", "MILVUS_ADDRESS=$CodeIndexerMilvusAddress",
        "-e", "MILVUS_TOKEN=$CodeIndexerMilvusToken",
        "-e", "OPENAI_BASE_URL=$CodeIndexerOpenAiBaseUrl",
        "-e", "OPENAI_API_KEY=$CodeIndexerOpenAiApiKey",
        "-e", "OPENAI_EMBEDDING_MODEL=$CodeIndexerOpenAiEmbeddingModel",
        "-e", "OPENAI_EMBEDDING_DIMENSION=$CodeIndexerOpenAiEmbeddingDimension",
        "-e", "CODEINDEXER_MCP_TIMEOUT_MS=$CodeIndexerMcpTimeoutMs",
        "-e", "FORTISAI_VAULT_ADDR=$VaultInternalUrl",
        "-e", "VAULT_ADDR=$VaultInternalUrl",
        "-e", "VAULT_TOKEN=$VaultToken",
        "docker.io/node:20-bookworm",
        "node", "/workspace/Development_Environment/mcp/codeindexer-mcp/codeindexer-openapi-bridge.mjs"
    )

    & podman @runArgs *> $null
    if ($LASTEXITCODE -ne 0) {
        Throw-Error "Failed to start bridge container: $CodeIndexerBridgeContainerName"
    }

    Write-Log "Started $CodeIndexerBridgeContainerName"
}

function Start-ProxmoxMcpBridgeContainers {
    param([Parameter(Mandatory = $true)][bool]$ExpectProxmox)

    if (-not $ExpectProxmox) {
        Write-Log "Skipped fortisai-mcp-openapi-proxmox (Proxmox config not detected; set PROXMOX_BRIDGE_ENABLED=true to force)"
        return
    }

    $upstreamContainer = "fortisai-mcp-openapi-proxmox-upstream"
    $facadeContainer = "fortisai-mcp-openapi-proxmox"
    $upstreamUrl = "http://${upstreamContainer}:8811"

    & podman rm -f $facadeContainer *> $null
    & podman rm -f $upstreamContainer *> $null

    $upstreamArgs = @(
        "run", "-d",
        "--name", $upstreamContainer,
        "--restart", "unless-stopped",
        "--network", $FortisaiSharedNetwork,
        "-e", "FORTISAI_DEV_HOME=$BaseDir",
        "-e", "FORTISAI_VAULT_ADDR=$VaultInternalUrl",
        "-e", "VAULT_ADDR=$VaultInternalUrl",
        "-e", "VAULT_TOKEN=$VaultToken",
        "-e", "PROXMOX_MCP_MODE=openapi",
        "-e", "API_HOST=0.0.0.0",
        "-e", "API_PORT=8811",
        "-e", "PROXMOX_API_KEY=$ProxmoxApiKey",
        "-e", "PROXMOX_API_STRICT_AUTH=$ProxmoxApiStrictAuth"
    )

    $optionalEnv = @{
        PROXMOX_HOST = $ProxmoxHost
        PROXMOX_PORT = $ProxmoxPort
        PROXMOX_USER = $ProxmoxUser
        PROXMOX_TOKEN_NAME = $ProxmoxTokenName
        PROXMOX_TOKEN_VALUE = $ProxmoxTokenValue
        PROXMOX_VERIFY_SSL = $ProxmoxVerifySsl
        PROXMOX_DEV_MODE = $ProxmoxDevMode
        PROXMOX_SERVICE = $ProxmoxService
        LOG_LEVEL = $ProxmoxLogLevel
    }

    foreach ($entry in $optionalEnv.GetEnumerator()) {
        if ($entry.Value) {
            $upstreamArgs += @("-e", "$($entry.Key)=$($entry.Value)")
        }
    }

    if (Test-Path $ProxmoxMcpConfigFile) {
        $upstreamArgs += @(
            "-v", "$ProxmoxMcpConfigFile`:/app/proxmox-config/config.json:ro",
            "-e", "PROXMOX_MCP_CONFIG=/app/proxmox-config/config.json"
        )
    }

    $upstreamArgs += @("ghcr.io/rekklesna/proxmoxmcp-plus:latest")

    & podman @upstreamArgs *> $null
    if ($LASTEXITCODE -ne 0) {
        Throw-Error "Failed to start Proxmox MCP upstream container"
    }
    Write-Log "Started $upstreamContainer"

    $facadeCommand = @'
python - <<'PY'
import http.server
import json
import os
import socketserver
import urllib.error
import urllib.request

UPSTREAM = os.environ.get('PROXMOX_UPSTREAM_URL', 'http://fortisai-mcp-openapi-proxmox-upstream:8811').rstrip('/')
API_KEY = os.environ.get('PROXMOX_API_KEY', '')
PORT = int(os.environ.get('PROXMOX_PROXY_PORT', '8095'))
HOP_BY_HOP = {'connection', 'host', 'keep-alive', 'proxy-authenticate', 'proxy-authorization', 'te', 'trailer', 'transfer-encoding', 'upgrade'}

def public_openapi(payload):
    try:
        spec = json.loads(payload.decode('utf-8'))
    except Exception:
        return payload, 'application/json'

    spec.pop('security', None)
    components = spec.get('components')
    if isinstance(components, dict):
        components.pop('securitySchemes', None)

    paths = spec.get('paths')
    if isinstance(paths, dict):
        for path_item in paths.values():
            if not isinstance(path_item, dict):
                continue
            for operation in path_item.values():
                if isinstance(operation, dict):
                    operation.pop('security', None)

    return (json.dumps(spec, separators=(',', ':')).encode('utf-8'), 'application/json')

class Handler(http.server.BaseHTTPRequestHandler):
    protocol_version = 'HTTP/1.1'

    def log_message(self, fmt, *args):
        return

    def _proxy(self):
        body = None
        if self.command in {'POST', 'PUT', 'PATCH', 'DELETE'}:
            length = int(self.headers.get('Content-Length', '0') or '0')
            body = self.rfile.read(length) if length else b''

        headers = {
            key: value
            for key, value in self.headers.items()
            if key.lower() not in HOP_BY_HOP and key.lower() != 'authorization'
        }
        if API_KEY:
            headers['Authorization'] = 'Bearer ' + API_KEY

        request = urllib.request.Request(UPSTREAM + self.path, data=body, headers=headers, method=self.command)
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                payload = response.read()
                status = getattr(response, 'status', 200)
                content_type = response.headers.get('Content-Type', 'application/json')
        except urllib.error.HTTPError as exc:
            payload = exc.read()
            status = exc.code
            content_type = exc.headers.get('Content-Type', 'application/json')
        except Exception as exc:
            payload = json.dumps({'detail': 'Proxmox upstream unavailable', 'error': type(exc).__name__}).encode('utf-8')
            status = 502
            content_type = 'application/json'

        if self.command == 'GET' and self.path.split('?', 1)[0] == '/openapi.json' and status == 200:
            payload, content_type = public_openapi(payload)

        self.send_response(status)
        self.send_header('Content-Type', content_type)
        self.send_header('Content-Length', str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def do_GET(self):
        self._proxy()

    def do_POST(self):
        self._proxy()

    def do_PUT(self):
        self._proxy()

    def do_PATCH(self):
        self._proxy()

    def do_DELETE(self):
        self._proxy()

class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True

with ReusableTCPServer(('0.0.0.0', PORT), Handler) as server:
    server.serve_forever()
PY
'@

    $facadeArgs = @(
        "run", "-d",
        "--name", $facadeContainer,
        "--restart", "unless-stopped",
        "--network", $FortisaiSharedNetwork,
        "-p", "8095:8095",
        "-e", "FORTISAI_VAULT_ADDR=$VaultInternalUrl",
        "-e", "VAULT_ADDR=$VaultInternalUrl",
        "-e", "VAULT_TOKEN=$VaultToken",
        "-e", "PYTHONDONTWRITEBYTECODE=1",
        "-e", "PYTHONUNBUFFERED=1",
        "-e", "PROXMOX_PROXY_PORT=8095",
        "-e", "PROXMOX_UPSTREAM_URL=$upstreamUrl",
        "-e", "PROXMOX_API_KEY=$ProxmoxApiKey",
        "docker.io/python:3.11-slim",
        "sh", "-lc", $facadeCommand
    )

    & podman @facadeArgs *> $null
    if ($LASTEXITCODE -ne 0) {
        Throw-Error "Failed to start Proxmox MCP facade container"
    }

    Write-Log "Started $facadeContainer"
}

function Start-McpUp {
    Ensure-PodmanMachine
    Ensure-SharedNetwork

    if (-not (Test-Path $DifyMcpSqlclBridgeScript)) {
        Throw-Error "SQLcl bridge script not found: $DifyMcpSqlclBridgeScript"
    }
    if (-not (Test-Path $DifyMcpN8nBridgeScript)) {
        Throw-Error "n8n bridge script not found: $DifyMcpN8nBridgeScript"
    }
    if (-not (Test-Path $DifyMcpDifyBridgeScript)) {
        Throw-Error "Dify bridge script not found: $DifyMcpDifyBridgeScript"
    }
    if (-not (Test-Path $DifyMcpDebugBridgeScript)) {
        Throw-Error "Debug bridge script not found: $DifyMcpDebugBridgeScript"
    }
    $codeIndexerBridgeScript = Join-Path $CodeIndexerMcpDir "codeindexer-openapi-bridge.mjs"
    if (-not (Test-Path $codeIndexerBridgeScript)) {
        Throw-Error "CodeIndexer bridge script not found: $codeIndexerBridgeScript"
    }

    Prepare-VaultRuntimeSecrets

    $n8nApiKey = Get-N8nApiKeyForMcp
    if (-not $n8nApiKey) {
        Throw-Error "N8N_API_KEY is required. Set N8N_API_KEY or configure it in $SqlclMcpConfigFile under mcpServers.fortisai-n8n.env.N8N_API_KEY"
    }

    $expectProxmox = Test-ProxmoxMcpConfigured

    $repoRoot = Split-Path -Parent $DevEnvDir
    $n8nBaseUrl = if ($env:N8N_BASE_URL) { $env:N8N_BASE_URL } else { "http://fortisai-n8n:5678" }
    $difyBaseUrl = if ($env:DIFY_BASE_URL) { $env:DIFY_BASE_URL } else { "http://docker_api_1:5001" }
    Load-DifyApiKeyFromJson
    $difyApiKey = if ($env:DIFY_API_KEY) { $env:DIFY_API_KEY } else { "" }
    $adminApiKey = Resolve-DifyRuntimeAdminApiKey
    if (-not $adminApiKey) {
        $adminApiKey = if ($env:DIFY_ADMIN_API_KEY) { $env:DIFY_ADMIN_API_KEY } else { "" }
    }
    if (-not $adminApiKey) {
        $adminApiKey = if ($env:ADMIN_API_KEY) { $env:ADMIN_API_KEY } else { "" }
    }
    $adminWorkspaceId = Resolve-DifyRuntimeWorkspaceId
    if (-not $adminWorkspaceId) {
        $adminWorkspaceId = if ($env:DIFY_ADMIN_WORKSPACE_ID) { $env:DIFY_ADMIN_WORKSPACE_ID } else { "" }
    }

    Write-Log "Starting MCP OpenAPI bridge services for Dify"

    Start-McpBridgeContainer `
        -ContainerName "fortisai-mcp-openapi-sqlcl" `
        -HostPort 8091 `
        -BridgePort 8091 `
        -BridgeScriptRelativePath "Development_Environment/mcp/sqlcl-mcp/sqlcl-openapi-bridge.py" `
        -PipPackages "fastapi uvicorn oracledb" `
        -RepoRoot $repoRoot `
        -EnvMap @{
            FORTISAI_VAULT_ADDR = $VaultInternalUrl
            VAULT_ADDR = $VaultInternalUrl
            VAULT_TOKEN = $VaultToken
            FORTISAI_DEV_HOME = $BaseDir
            SQLCL_BRIDGE_PORT = "8091"
            ORACLE_DB_WALLET_ENV_FILE = $OracleDbWalletEnvFile
            ORACLE_DB_HOST = "fortisai-oracle-db"
            ORACLE_DB_PORT = "$OracleDbHostPort"
            ORACLE_DB_SERVICE_NAME = $OracleDbPdb
            ORACLE_DB_USER = $OracleDbUser
            ORACLE_DB_PASSWORD = $OracleDbPassword
        }

    Start-McpBridgeContainer `
        -ContainerName "fortisai-mcp-openapi-n8n" `
        -HostPort 8092 `
        -BridgePort 8092 `
        -BridgeScriptRelativePath "Development_Environment/mcp/n8n-mcp/n8n-openapi-bridge.py" `
        -PipPackages "fastapi uvicorn" `
        -RepoRoot $repoRoot `
        -EnvMap @{
            FORTISAI_VAULT_ADDR = $VaultInternalUrl
            VAULT_ADDR = $VaultInternalUrl
            VAULT_TOKEN = $VaultToken
            N8N_BRIDGE_PORT = "8092"
            N8N_BASE_URL = $n8nBaseUrl
            N8N_API_KEY = $n8nApiKey
            N8N_BASIC_AUTH_USER = $N8nBasicAuthUser
            N8N_BASIC_AUTH_PASSWORD = $N8nBasicAuthPassword
        }

    Start-McpBridgeContainer `
        -ContainerName "fortisai-mcp-openapi-dify" `
        -HostPort 8093 `
        -BridgePort 8093 `
        -BridgeScriptRelativePath "Development_Environment/mcp/dify-mcp/dify-openapi-bridge.py" `
        -PipPackages "fastapi uvicorn" `
        -RepoRoot $repoRoot `
        -EnvMap @{
            FORTISAI_VAULT_ADDR = $VaultInternalUrl
            VAULT_ADDR = $VaultInternalUrl
            VAULT_TOKEN = $VaultToken
            DIFY_BRIDGE_PORT = "8093"
            DIFY_BASE_URL = $difyBaseUrl
            ADMIN_API_KEY_ENABLE = "true"
            DIFY_API_KEY = $difyApiKey
            DIFY_ADMIN_API_KEY = $adminApiKey
            DIFY_ADMIN_WORKSPACE_ID = $adminWorkspaceId
            ADMIN_API_KEY = $adminApiKey
            KNOWLEDGE_API_KEY = $(if ($env:KNOWLEDGE_API_KEY) { $env:KNOWLEDGE_API_KEY } else { "" })
        }

    Start-McpBridgeContainer `
        -ContainerName "fortisai-mcp-openapi-debug" `
        -HostPort 8094 `
        -BridgePort 8094 `
        -BridgeScriptRelativePath "Development_Environment/mcp/debug-mcp/debug-openapi-bridge.py" `
        -PipPackages "fastapi uvicorn" `
        -RepoRoot $repoRoot `
        -EnvMap @{
            FORTISAI_VAULT_ADDR = $VaultInternalUrl
            VAULT_ADDR = $VaultInternalUrl
            VAULT_TOKEN = $VaultToken
            DEBUG_BRIDGE_PORT = "8094"
            DEBUG_SQLCL_OPENAPI_URL = "http://fortisai-mcp-openapi-sqlcl:8091/openapi.json"
            DEBUG_N8N_OPENAPI_URL = "http://fortisai-mcp-openapi-n8n:8092/openapi.json"
            DEBUG_DIFY_OPENAPI_URL = "http://fortisai-mcp-openapi-dify:8093/openapi.json"
        }

    Start-CodeIndexerMcpBridgeContainer -RepoRoot $repoRoot

    Start-ProxmoxMcpBridgeContainers -ExpectProxmox $expectProxmox

    Write-Log "Validating MCP bridge OpenAPI specs"
    $maxAttempts = 20
    $sqlStatus = 0
    $n8nStatus = 0
    $difyStatus = 0
    $debugStatus = 0
    $codeIndexerStatus = 0
    $proxmoxStatus = 0
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        $sqlStatus = Get-HttpStatusCode -Url $McpSqlclOpenApiUrl
        $n8nStatus = Get-HttpStatusCode -Url $McpN8nOpenApiUrl
        $difyStatus = Get-HttpStatusCode -Url $McpDifyOpenApiUrl
        $debugStatus = Get-HttpStatusCode -Url $McpDebugOpenApiUrl
        $codeIndexerStatus = Get-HttpStatusCode -Url $McpCodeIndexerOpenApiUrl
        if ($expectProxmox) {
            $proxmoxStatus = Get-HttpStatusCode -Url $McpProxmoxOpenApiUrl
        }
        else {
            $proxmoxStatus = 200
        }
        if ($sqlStatus -eq 200 -and $n8nStatus -eq 200 -and $difyStatus -eq 200 -and $debugStatus -eq 200 -and $codeIndexerStatus -eq 200 -and $proxmoxStatus -eq 200) {
            break
        }
        Start-Sleep -Seconds 1
    }

    if ($sqlStatus -ne 200) {
        Throw-Error "SQLcl MCP bridge OpenAPI check failed: $McpSqlclOpenApiUrl (HTTP $sqlStatus)"
    }
    if ($n8nStatus -ne 200) {
        Throw-Error "n8n MCP bridge OpenAPI check failed: $McpN8nOpenApiUrl (HTTP $n8nStatus)"
    }
    if ($difyStatus -ne 200) {
        Throw-Error "Dify MCP bridge OpenAPI check failed: $McpDifyOpenApiUrl (HTTP $difyStatus)"
    }
    if ($debugStatus -ne 200) {
        Throw-Error "Debug MCP bridge OpenAPI check failed: $McpDebugOpenApiUrl (HTTP $debugStatus)"
    }
    if ($codeIndexerStatus -ne 200) {
        Throw-Error "CodeIndexer MCP bridge OpenAPI check failed: $McpCodeIndexerOpenApiUrl (HTTP $codeIndexerStatus). Run: .\fortisai-dev-helper.ps1 codeindexer-up"
    }
    if ($expectProxmox -and $proxmoxStatus -ne 200) {
        Throw-Error "Proxmox MCP bridge OpenAPI check failed: $McpProxmoxOpenApiUrl (HTTP $proxmoxStatus). Provide Proxmox config at $ProxmoxMcpConfigFile or export PROXMOX_HOST/PROXMOX_USER/PROXMOX_TOKEN_NAME/PROXMOX_TOKEN_VALUE"
    }

    Write-Log "Running debug bridge status smoke test"
    $debugStatusUrl = ($McpDebugOpenApiUrl -replace '/openapi\.json$', '/debug_bridge_status')
    $debugResponse = Invoke-RestMethod -Uri $debugStatusUrl -Method Get
    if (-not $debugResponse.ok) {
        Throw-Error "Debug bridge status smoke test failed"
    }

    Write-Log "Running SQL bridge query smoke test"
    $sqlQueryUrl = $McpSqlclOpenApiUrl -replace '/openapi\.json$', '/sqlcl_query'
    $sqlBody = @{ sql = "select 1 as ok from dual" } | ConvertTo-Json -Compress
    $sqlResponse = Invoke-RestMethod -Uri $sqlQueryUrl -Method Post -ContentType "application/json" -Body $sqlBody
    if (-not $sqlResponse.ok) {
        Throw-Error "SQLcl bridge query smoke test failed"
    }

    Write-Log "Running n8n bridge workflow-list smoke test"
    $n8nListUrl = ($McpN8nOpenApiUrl -replace '/openapi\.json$', '/n8n_list_workflows?limit=2')
    $n8nResponse = Invoke-RestMethod -Uri $n8nListUrl -Method Get
    if ([int]$n8nResponse.status -ne 200) {
        Throw-Error "n8n bridge workflow-list smoke test failed"
    }

    Write-Log "Running Dify bridge connection-info smoke test"
    $difyInfoUrl = ($McpDifyOpenApiUrl -replace '/openapi\.json$', '/dify_connection_info')
    $difyResponse = Invoke-RestMethod -Uri $difyInfoUrl -Method Get
    if (-not $difyResponse.base_url) {
        Throw-Error "Dify bridge connection-info smoke test failed"
    }

    Write-Log "Running CodeIndexer bridge connection-info smoke test"
    $codeIndexerInfoUrl = ($McpCodeIndexerOpenApiUrl -replace '/openapi\.json$', '/codeindexer_connection_info')
    $codeIndexerResponse = Invoke-RestMethod -Uri $codeIndexerInfoUrl -Method Get
    if (-not ($codeIndexerResponse.mcp_built -or $codeIndexerResponse.mcpExecutableExists)) {
        Throw-Error "CodeIndexer bridge connection-info smoke test failed"
    }

    if ($expectProxmox) {
        Write-Log "Running Proxmox bridge livez smoke test"
        $proxmoxLivezUrl = ($McpProxmoxOpenApiUrl -replace '/openapi\.json$', '/livez')
        $proxmoxLivezStatus = Get-HttpStatusCode -Url $proxmoxLivezUrl
        if ($proxmoxLivezStatus -ne 200) {
            Throw-Error "Proxmox bridge livez smoke test failed (HTTP $proxmoxLivezStatus)"
        }
    }

    if (Test-ContainerRunning -Name "docker_api_1") {
        Write-Log "Validating Dify API container can reach OpenAPI bridge endpoints"
        $probeTargets = @(
            "('sqlcl','http://fortisai-mcp-openapi-sqlcl:8091/openapi.json')",
            "('n8n','http://fortisai-mcp-openapi-n8n:8092/openapi.json')",
            "('dify','http://fortisai-mcp-openapi-dify:8093/openapi.json')",
            "('debug','http://fortisai-mcp-openapi-debug:8094/openapi.json')",
            "('codeindexer','http://fortisai-mcp-openapi-codeindexer:8096/openapi.json')"
        )
        if ($expectProxmox) {
            $probeTargets += "('proxmox','http://fortisai-mcp-openapi-proxmox:8095/openapi.json')"
        }
        $probeTargetText = $probeTargets -join ","
        & podman exec docker_api_1 python -c "import urllib.request as u; urls=[$probeTargetText]; [print(n, u.urlopen(url, timeout=8).status) for n, url in urls]"
        if ($LASTEXITCODE -ne 0) {
            Throw-Error "Dify API container bridge reachability check failed"
        }
    }
    else {
        Write-Log "Skipping Dify container reachability check (docker_api_1 is not running)"
    }

    Sync-McpOpenApiBridgesIntoOpenWebUi

    Write-Log "mcp-up completed successfully"
    Write-Log "SQLcl OpenAPI: $McpSqlclOpenApiUrl"
    Write-Log "n8n OpenAPI: $McpN8nOpenApiUrl"
    Write-Log "dify OpenAPI: $McpDifyOpenApiUrl"
    Write-Log "debug OpenAPI: $McpDebugOpenApiUrl"
    Write-Log "CodeIndexer OpenAPI: $McpCodeIndexerOpenApiUrl"
    if ($expectProxmox) {
        Write-Log "proxmox OpenAPI: $McpProxmoxOpenApiUrl"
    }
    else {
        Write-Log "proxmox OpenAPI: skipped (no Proxmox config detected)"
    }
}

function Stop-McpDown {
    Ensure-PodmanMachine
    Write-Log "Stopping MCP OpenAPI bridge services"

    $containers = @(
        "fortisai-mcp-openapi-sqlcl",
        "fortisai-mcp-openapi-n8n",
        "fortisai-mcp-openapi-dify",
        "fortisai-mcp-openapi-debug",
        $CodeIndexerBridgeContainerName,
        "fortisai-mcp-openapi-proxmox",
        "fortisai-mcp-openapi-proxmox-upstream"
    )

    foreach ($container in $containers) {
        & podman container exists $container *> $null
        if ($LASTEXITCODE -eq 0) {
            & podman rm -f $container *> $null
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Stopped $container"
            }
            else {
                Throw-Error "Failed to stop $container"
            }
        }
        else {
            Write-Log "Skipped $container (not found)"
        }
    }

    Write-Log "mcp-down completed successfully"
}

function Require-RunningOracleAndOrds {
    if (-not (Test-ContainerRunning -Name $OracleDbContainerName)) {
        Throw-Error "Oracle DB container is not running. Start it with: .\fortisai-dev-helper.ps1 up"
    }

    if (-not (Test-ContainerRunning -Name $OrdsContainerName)) {
        Throw-Error "ORDS container is not running. Start it with: .\fortisai-dev-helper.ps1 up"
    }
}

function Prepare-ApexBundle {
    Require-Command curl
    New-Item -ItemType Directory -Force -Path $ApexWorkDir | Out-Null

    $apexInstallScript = Join-Path $ApexWorkDir "apex/apexins.sql"
    if (Test-Path $apexInstallScript) {
        Write-Log "APEX bundle already prepared at $(Join-Path $ApexWorkDir 'apex')"
        return
    }

    $zipPath = Join-Path $ApexWorkDir "apex.zip"
    Write-Log "Downloading APEX bundle from $ApexDownloadUrl"
    & curl -fsSL $ApexDownloadUrl -o $zipPath
    if ($LASTEXITCODE -ne 0) {
        Throw-Error "Failed to download APEX bundle from $ApexDownloadUrl"
    }

    $extractDir = Join-Path $ApexWorkDir "apex"
    if (Test-Path $extractDir) {
        Remove-Item -Recurse -Force $extractDir
    }

    Write-Log "Extracting APEX bundle"
    Expand-Archive -Path $zipPath -DestinationPath $ApexWorkDir -Force

    if (-not (Test-Path $apexInstallScript)) {
        Throw-Error "APEX bundle extraction failed: apexins.sql not found"
    }
}

function Test-ApexInstalled {
    $query = @"
set heading off feedback off pages 0 verify off
alter session set container=$OracleDbPdb;
select count(*) from dba_registry where comp_id = 'APEX' and status = 'VALID';
exit
"@

    $result = $query | & podman exec -i $OracleDbContainerName bash -lc "sqlplus -s -L '/ as sysdba'" 2>$null
    if ($LASTEXITCODE -ne 0) {
        return $false
    }

    $numericLine = $result | Where-Object { $_ -match '^\s*[0-9]+\s*$' } | Select-Object -Last 1
    if (-not $numericLine) {
        return $false
    }

    return ([int]$numericLine.Trim() -gt 0)
}

function Configure-ApexRest {
    $dbConnectString = "localhost:$OracleDbHostPort/$OracleDbPdb"

    if (Test-Path $OracleDbWalletEnvFile) {
        Get-Content $OracleDbWalletEnvFile | ForEach-Object {
            if ($_ -match '^ORACLE_DB_CONNECT_STRING=(.*)$') { $dbConnectString = $Matches[1] }
        }
    }

    & podman exec $OracleDbContainerName bash -lc "test -f /tmp/apex/apex_rest_config.sql" *> $null
    if ($LASTEXITCODE -ne 0) {
        & podman exec $OracleDbContainerName bash -lc "rm -rf /tmp/apex" *> $null
        & podman cp (Join-Path $ApexWorkDir "apex") "$OracleDbContainerName`:/tmp/"
    }

    Write-Log "Configuring APEX REST users"
    $restSql = @"
whenever sqlerror exit failure rollback;
alter session set container=$OracleDbPdb;
@apex_rest_config.sql "$OracleDbPassword" "$OracleDbPassword"
exit
"@
    $restSql | & podman exec -i $OracleDbContainerName bash -lc "cd /tmp/apex && sqlplus -L '/ as sysdba'" *> $null

    Write-Log "Configuring ORDS gateway settings for APEX"
    & podman exec $OrdsContainerName bash -lc "ords --config /etc/ords/config config set plsql.gateway.mode proxied --db-pool default" *> $null
    & podman exec $OrdsContainerName bash -lc "ords --config /etc/ords/config config set security.requestValidationFunction '' --db-pool default" *> $null
}

function Sync-ApexOrdsStatic {
    Write-Log "Copying APEX static images into ORDS config"
    & podman exec $OrdsContainerName bash -lc "mkdir -p /etc/ords/config/global/doc_root/i && rm -rf /tmp/apex-images" *> $null
    & podman cp (Join-Path $ApexWorkDir "apex/images") "$OrdsContainerName`:/tmp/apex-images"
    & podman exec $OrdsContainerName bash -lc "cp -R /tmp/apex-images/. /etc/ords/config/global/doc_root/i/ && rm -rf /tmp/apex-images" *> $null
    & podman exec $OrdsContainerName bash -lc "ords --config /etc/ords/config config set standalone.doc.root /etc/ords/config/global/doc_root" *> $null

    Write-Log "Restarting ORDS to load APEX static content"
    Invoke-Compose -Args @("-f", $OrdsComposeFile, "restart", "ords") *> $null
}

function Set-ApexAdminPassword {
    $dbConnectString = "localhost:$OracleDbHostPort/$OracleDbPdb"

    if (Test-Path $OracleDbWalletEnvFile) {
        Get-Content $OracleDbWalletEnvFile | ForEach-Object {
            if ($_ -match '^ORACLE_DB_CONNECT_STRING=(.*)$') { $dbConnectString = $Matches[1] }
        }
    }

    # Escape SQL single quotes to safely embed the password as a SQL literal.
    $apexAdminPasswordSql = $ApexAdminPassword.Replace("'", "''")

    Write-Log "Setting APEX ADMIN password"
    $setAdminSql = @"
whenever sqlerror exit failure rollback;
alter session set container=$OracleDbPdb;
begin
  apex_instance_admin.create_or_update_admin_user(
    p_username => 'ADMIN',
    p_email    => 'admin@fortisai.local',
    p_password => '$apexAdminPasswordSql'
  );
  commit;
end;
/
exit
"@
    $setAdminSql | & podman exec -i $OracleDbContainerName bash -lc "sqlplus -L \"sys/$OracleDbPassword@$dbConnectString as sysdba\"" *> $null
}

function Install-Apex {
    Ensure-PodmanMachine
    Require-RunningOracleAndOrds
    Prepare-ApexBundle

    $dbConnectString = "localhost:$OracleDbHostPort/$OracleDbPdb"

    if (Test-Path $OracleDbWalletEnvFile) {
        Get-Content $OracleDbWalletEnvFile | ForEach-Object {
            if ($_ -match '^ORACLE_DB_CONNECT_STRING=(.*)$') { $dbConnectString = $Matches[1] }
        }
    }

    if (Test-ApexInstalled) {
        Write-Log "APEX is already installed in $OracleDbPdb"
    }
    else {
        Write-Log "Copying APEX installer into Oracle DB container"
                & podman exec $OracleDbContainerName bash -lc "rm -rf /tmp/apex" *> $null

        $apexDir = Join-Path $ApexWorkDir "apex"
                & podman cp $apexDir "$OracleDbContainerName`:/tmp/"

        $sqlFile = Join-Path $env:TEMP "fortisai-apex-install.sql"
        @"
whenever sqlerror exit failure rollback;
declare
    v_count number;
begin
    for u in (select 'APEX_PUBLIC_USER' username from dual
                        union all select 'APEX_LISTENER' from dual
                        union all select 'APEX_REST_PUBLIC_USER' from dual) loop
        select count(*) into v_count from dba_users where username = u.username;
        if v_count > 0 then
            execute immediate 'alter user ' || u.username || ' identified by ""$OracleDbPassword"" account unlock';
        end if;
    end loop;
end;
/
exit
"@ | Set-Content -Path $sqlFile -Encoding UTF8

        Write-Log "Installing APEX in $OracleDbPdb (this can take several minutes)"
        & podman cp $sqlFile "$OracleDbContainerName`:/tmp/fortisai-apex-install.sql"
        Remove-Item $sqlFile -ErrorAction SilentlyContinue

                & podman exec $OracleDbContainerName bash -lc "cd /tmp/apex && sqlplus -L \"sys/$OracleDbPassword@$dbConnectString as sysdba\" @apexins.sql SYSAUX SYSAUX TEMP /i/ && sqlplus -L \"sys/$OracleDbPassword@$dbConnectString as sysdba\" @/tmp/fortisai-apex-install.sql"

                if (-not (Test-ApexInstalled)) {
                        Throw-Error "APEX installer completed but APEX component is not VALID in $OracleDbPdb"
                }

                Configure-ApexRest
                Set-ApexAdminPassword
    }

        Configure-ApexRest

    Sync-ApexOrdsStatic

    Check-Apex
    Write-Log "APEX install workflow complete"
    Write-Log "APEX URL: $ApexUrl"
}

function Reset-Apex {
    Ensure-PodmanMachine
    Require-RunningOracleAndOrds

    $dbConnectString = "localhost:$OracleDbHostPort/$OracleDbPdb"

    if (Test-Path $OracleDbWalletEnvFile) {
        Get-Content $OracleDbWalletEnvFile | ForEach-Object {
            if ($_ -match '^ORACLE_DB_CONNECT_STRING=(.*)$') { $dbConnectString = $Matches[1] }
        }
    }

    if (-not (Test-ApexInstalled)) {
        Throw-Error "APEX is not installed in $OracleDbPdb. Run: .\fortisai-dev-helper.ps1 apex-install"
    }

    Prepare-ApexBundle

    Write-Log "Resetting APEX runtime users and admin password"
    $resetSql = @"
whenever sqlerror exit failure rollback;
declare
    v_count number;
begin
    for u in (select 'APEX_PUBLIC_USER' username from dual
                        union all select 'APEX_LISTENER' from dual
                        union all select 'APEX_REST_PUBLIC_USER' from dual) loop
        select count(*) into v_count from dba_users where username = u.username;
        if v_count > 0 then
            execute immediate 'alter user ' || u.username || ' identified by ""$OracleDbPassword"" account unlock';
        end if;
    end loop;
end;
/
begin
  apex_instance_admin.set_parameter('IMAGE_PREFIX','/i/');
  commit;
end;
/
exit
"@
    $resetSql | & podman exec -i $OracleDbContainerName bash -lc "sqlplus -L \"sys/$OracleDbPassword@$dbConnectString as sysdba\"" *> $null

        & podman exec $OracleDbContainerName bash -lc "test -f /tmp/apex/apex_rest_config.sql" *> $null
    if ($LASTEXITCODE -ne 0) {
                & podman exec $OracleDbContainerName bash -lc "rm -rf /tmp/apex" *> $null
                & podman cp (Join-Path $ApexWorkDir "apex") "$OracleDbContainerName`:/tmp/"
    }

        Configure-ApexRest
        Set-ApexAdminPassword

    Sync-ApexOrdsStatic
    Check-Apex
    Write-Log "APEX reset workflow complete"
    Write-Log "APEX URL: $ApexUrl"
}

function Check-Apex {
    Ensure-PodmanMachine

    if ((Test-ContainerRunning -Name $OracleDbContainerName) -and (Test-ApexInstalled)) {
        Write-Log "apex install status: installed"
    }
    else {
        Write-Log "apex install status: not installed (or database not running)"
    }

    Write-Log "Checking APEX URL via ORDS: $ApexUrl"
    Test-Http -Url $ApexUrl -Name "apex"
}

function Setup-LMStudio {
    $appPath1 = Join-Path $env:LOCALAPPDATA "Programs\LM Studio\LM Studio.exe"
    $appPath2 = Join-Path $env:ProgramFiles "LM Studio\LM Studio.exe"

    if ((Test-Path $appPath1) -or (Test-Path $appPath2)) {
        Write-Log "LM Studio is already installed"
        return
    }

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Throw-Error "winget is required to auto-install LM Studio. Install App Installer from Microsoft Store or install LM Studio manually from https://lmstudio.ai"
    }

    $packageIds = @(
        "LMStudio.LMStudio",
        "ElementLabs.LMStudio"
    )

    $installed = $false
    foreach ($id in $packageIds) {
        Write-Log "Attempting LM Studio install with winget id: $id"
        & winget install --id $id -e --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -eq 0) {
            $installed = $true
            break
        }
    }

    if (-not $installed) {
        Throw-Error "Unable to install LM Studio with winget package IDs. Install manually from https://lmstudio.ai"
    }

    Write-Log "LM Studio install complete"
}

function Start-LMStudio {
    Setup-LMStudio

    $candidatePaths = @(
        (Join-Path $env:LOCALAPPDATA "Programs\LM Studio\LM Studio.exe"),
        (Join-Path $env:ProgramFiles "LM Studio\LM Studio.exe")
    )

    foreach ($path in $candidatePaths) {
        if (Test-Path $path) {
            Write-Log "Starting LM Studio"
            Start-Process -FilePath $path | Out-Null
            Write-Log "In LM Studio, load a model and enable Developer > Local Server"
            return
        }
    }

    Throw-Error "LM Studio executable not found after install. Launch it manually from Start menu and verify installation path."
}

function Check-LMStudio {
    Write-Log "Checking LM Studio local API: $LmStudioModelsUrl"
    try {
        $response = Invoke-WebRequest -Uri $LmStudioModelsUrl -Method Get -TimeoutSec 10
        Write-Host "lmstudio HTTP $($response.StatusCode)"
    }
    catch {
        Write-Host "lmstudio HTTP unavailable"
    }
}

function Start-Daytona {
    Ensure-PodmanMachine
    Ensure-SharedNetwork
    Setup-DaytonaRepo

    if (Test-DockerComposeAvailable) {
        Write-Log "Starting Daytona (self-hosted OSS) with Docker Compose for runner stability"
        Push-Location $DaytonaRepoDir
        & docker compose -f $DaytonaRuntimeFile up -d
        Pop-Location
    }
    else {
        Write-Log "Docker Compose not detected; falling back to detected compose runner."
        Write-Log "Warning: Daytona runner may restart continuously under Podman-only runtime."
        Push-Location $DaytonaRepoDir
        Invoke-Compose -Args @("-f", $DaytonaRuntimeFile, "up", "-d")
        Pop-Location
    }

    Write-Log "Daytona dashboard: $DaytonaUrl"
}

function Stop-Daytona {
    Ensure-PodmanMachine

    if (-not (Test-Path $DaytonaComposeFile)) {
        Write-Log "Daytona not initialized; nothing to stop"
        return
    }

    if (Test-DockerComposeAvailable) {
        Write-Log "Stopping Daytona with Docker Compose"
        Push-Location $DaytonaRepoDir
        & docker compose -f $DaytonaRuntimeFile down
        Pop-Location
    }
    else {
        Write-Log "Stopping Daytona"
        Push-Location $DaytonaRepoDir
        Invoke-Compose -Args @("-f", $DaytonaRuntimeFile, "down")
        Pop-Location
    }
}

function Check-Daytona {
    Write-Log "Checking Daytona dashboard: $DaytonaUrl"
    try {
        $response = Invoke-WebRequest -Uri $DaytonaUrl -Method Get -TimeoutSec 10
        Write-Host "daytona HTTP $($response.StatusCode)"
    }
    catch {
        Write-Host "daytona HTTP unavailable"
    }

    $restartCount = (& podman inspect daytona_runner_1 --format "{{.RestartCount}}" 2>$null | Select-Object -First 1)
    if (-not $restartCount) {
        $restartCount = "not-found"
    }
    Write-Host "daytona_runner_restarts: $restartCount"
    if ($restartCount -match '^\d+$' -and [int]$restartCount -gt 5) {
        Write-Log "Runner restart count is elevated. Use '.\fortisai-dev-helper.ps1 daytona-docker-smoke' for compatibility validation."
    }
}

function Invoke-DaytonaDockerSmoke {
    Require-Command docker
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Throw-Error "Docker Desktop is required for this workflow."
    }

    try {
        & docker compose version *> $null
    }
    catch {
        Throw-Error "Docker Compose is required for this workflow."
    }

    Setup-DaytonaRepo
    Ensure-SharedNetwork

    Write-Log "Starting Daytona with Docker Compose for runner compatibility"
    Push-Location $DaytonaRepoDir
    & docker compose -f $DaytonaRuntimeFile down *> $null
    & docker compose -f $DaytonaRuntimeFile up -d
    Pop-Location

    Write-Log "Checking Daytona endpoints"
    try {
        $r1 = Invoke-WebRequest -Uri $DaytonaUrl -Method Get -TimeoutSec 10
        Write-Host "daytona_root HTTP $($r1.StatusCode)"
    }
    catch {
        Write-Host "daytona_root HTTP unavailable"
    }

    try {
        $r2 = Invoke-WebRequest -Uri "$DaytonaUrl/api/health" -Method Get -TimeoutSec 10
        Write-Host "daytona_health HTTP $($r2.StatusCode)"
    }
    catch {
        Write-Host "daytona_health HTTP unavailable"
    }

    $runner = (& docker ps --format "{{.Names}} {{.Status}}" | Select-String -Pattern "daytona_runner" | Select-Object -First 1)
    if ($runner) {
        Write-Host "daytona_runner_status: $runner"
    }
    else {
        Write-Host "daytona_runner_status: not-found"
    }

    if ($env:DAYTONA_API_KEY -and $env:DAYTONA_ORG_ID) {
        Write-Log "Running sandbox create smoke request using DAYTONA_API_KEY and DAYTONA_ORG_ID"
        $payload = @{ name = 'docker-smoke-sandbox'; target = 'us' } | ConvertTo-Json -Compress
        try {
            $resp = Invoke-RestMethod -Uri "$DaytonaUrl/api/sandbox" -Method Post -Headers @{
                Authorization = "Bearer $($env:DAYTONA_API_KEY)"
                'X-Daytona-Organization-ID' = $env:DAYTONA_ORG_ID
                'Content-Type' = 'application/json'
            } -Body $payload
            ($resp | ConvertTo-Json -Depth 8) | Write-Host
        }
        catch {
            Write-Host $_.Exception.Message
        }
    }
    else {
        Write-Log "Set DAYTONA_API_KEY and DAYTONA_ORG_ID to include API sandbox-create smoke validation"
    }
}

function Set-DaytonaAdminCreds {
    param([string]$NewEmail, [string]$NewPassword)

    if (-not $NewEmail -or -not $NewPassword) {
        Throw-Error "Usage: .\fortisai-dev-helper.ps1 daytona-set-admin-creds <email> <password>"
    }

    $dexConfig = Join-Path $DaytonaRepoDir "docker/dex/config.yaml"
    if (-not (Test-Path $dexConfig)) {
        Throw-Error "Dex config not found at $dexConfig - run daytona-setup first."
    }

    if (-not (Get-Command htpasswd -ErrorAction SilentlyContinue)) {
        Throw-Error "'htpasswd' not found. Install Apache tools or use WSL/Git Bash which includes it."
    }

    $newHash = ("$NewPassword" | htpasswd -BinC 10 admin 2>$null) -split ':' | Select-Object -Last 1
    if (-not $newHash) {
        Throw-Error "Failed to generate bcrypt hash. Ensure htpasswd is available."
    }

    $content = Get-Content $dexConfig -Raw
    # Replace email
    $content = $content -replace "email: '([^']+)'", "email: '$NewEmail'"
    # Replace hash
    $content = $content -replace "hash: '([^']+)'", "hash: '$newHash'"
    Set-Content $dexConfig $content -NoNewline

    Write-Log "Daytona admin credentials updated in $dexConfig"
    Write-Log "  Email:    $NewEmail"
    Write-Log "  Password: (bcrypt hash written)"
    Write-Log "Restart the Daytona stack to apply: .\fortisai-dev-helper.ps1 daytona-down then daytona-up"
}

function Revoke-DaytonaApiKey {
    param([string]$ApiKeyName)

    if (-not $ApiKeyName) {
        Throw-Error "Usage: .\fortisai-dev-helper.ps1 daytona-revoke-key <key-name>"
    }

    if (-not $env:DAYTONA_API_KEY) {
        Throw-Error "DAYTONA_API_KEY is required to revoke API keys."
    }

    $headers = @{ Authorization = "Bearer $($env:DAYTONA_API_KEY)" }
    if ($env:DAYTONA_ORG_ID) {
        $headers['X-Daytona-Organization-ID'] = $env:DAYTONA_ORG_ID
    }

    try {
        Invoke-WebRequest -Uri "$DaytonaUrl/api/api-keys/$ApiKeyName" -Method Delete -Headers $headers -TimeoutSec 20 | Out-Null
        Write-Log "Revoked Daytona API key: $ApiKeyName"
    }
    catch {
        Throw-Error "Failed to revoke Daytona API key '$ApiKeyName': $($_.Exception.Message)"
    }
}

function Write-ProdTemplate {
    New-Item -ItemType Directory -Force -Path $BaseDir | Out-Null

    @"
# Copy this file to $ProdEnvFile and set real values.

OCI_CLI_PROFILE=DEFAULT
OCI_REGION=us-phoenix-1

BASTION_SERVICE_ID=ocid1.bastion.oc1..<replace>
BASTION_TARGET_SUBNET_ID=ocid1.subnet.oc1..<replace>
BASTION_SSH_PUBLIC_KEY_PATH=$HOME/.ssh/id_ed25519.pub
BASTION_SESSION_TTL=10800

PROD_GENAI_PRIVATE_IP=10.0.10.25
PROD_GENAI_PORT=443

PROD_LLAMA_PRIVATE_IP=10.0.11.40
PROD_LLAMA_PORT=8000

PROD_GITHUB_PRIVATE_IP=
PROD_GITHUB_PORT=443

OCI_DEVOPS_GIT_USERNAME_SECRET_ID=ocid1.vaultsecret.oc1..<replace>
OCI_DEVOPS_GIT_TOKEN_SECRET_ID=ocid1.vaultsecret.oc1..<replace>
GENAI_OCI_CREDENTIALS_SECRET_ID=ocid1.vaultsecret.oc1..<replace>
"@ | Set-Content -Path $ProdEnvExampleFile -Encoding UTF8

    Write-Log "Wrote production link template: $ProdEnvExampleFile"
}

function Read-ProdEnv {
    $data = @{}

    if (Test-Path $ProdEnvFile) {
        Get-Content -Path $ProdEnvFile | ForEach-Object {
            $line = $_.Trim()
            if (-not $line -or $line.StartsWith("#")) { return }
            $parts = $line.Split("=", 2)
            if ($parts.Count -eq 2) {
                $data[$parts[0].Trim()] = $parts[1].Trim()
            }
        }
    }

    return $data
}

function Get-ProdValue {
    param(
        [hashtable]$Data,
        [string]$Name
    )

    if ($Data.ContainsKey($Name) -and $Data[$Name]) { return $Data[$Name] }
    $envValue = [Environment]::GetEnvironmentVariable($Name)
    if ($envValue) { return $envValue }
    return ""
}

function Test-OcidLike {
    param([string]$Value)
    return ($Value -match "^ocid1\.[a-zA-Z0-9._-]+\..+")
}

function Validate-Prod {
    Require-Command oci
    Require-Command jq

    if (-not (Test-Path $ProdEnvFile)) {
        Throw-Error "Production env file not found: $ProdEnvFile. Run prod-template first."
    }

    $prod = Read-ProdEnv
    $required = @(
        "OCI_CLI_PROFILE",
        "OCI_REGION",
        "BASTION_SERVICE_ID",
        "BASTION_SSH_PUBLIC_KEY_PATH",
        "PROD_GENAI_PRIVATE_IP",
        "PROD_LLAMA_PRIVATE_IP",
        "OCI_DEVOPS_GIT_USERNAME_SECRET_ID",
        "OCI_DEVOPS_GIT_TOKEN_SECRET_ID",
        "GENAI_OCI_CREDENTIALS_SECRET_ID"
    )

    $hasError = $false

    foreach ($name in $required) {
        $value = Get-ProdValue -Data $prod -Name $name
        if (-not $value) {
            Write-Host "[fortisai-dev] ERROR: Missing required variable in ${ProdEnvFile}: $name"
            $hasError = $true
        }
    }

    $sshKey = Get-ProdValue -Data $prod -Name "BASTION_SSH_PUBLIC_KEY_PATH"
    if ($sshKey -and -not (Test-Path $sshKey)) {
        Write-Host "[fortisai-dev] ERROR: SSH public key file does not exist: $sshKey"
        $hasError = $true
    }

    foreach ($ocidName in @("BASTION_SERVICE_ID", "OCI_DEVOPS_GIT_USERNAME_SECRET_ID", "OCI_DEVOPS_GIT_TOKEN_SECRET_ID", "GENAI_OCI_CREDENTIALS_SECRET_ID")) {
        $v = Get-ProdValue -Data $prod -Name $ocidName
        if ($v -and -not (Test-OcidLike -Value $v)) {
            Write-Host "[fortisai-dev] ERROR: $ocidName does not look like a valid OCID: $v"
            $hasError = $true
        }
    }

    if ($hasError) {
        Throw-Error "Production config validation failed. Fix values in $ProdEnvFile and retry."
    }

    Write-Log "Production config validation passed"
}

function New-BastionPortForwardSession {
    param(
        [string]$DisplayName,
        [string]$TargetIp,
        [string]$TargetPort,
        [hashtable]$Prod
    )

    $bastionId = Get-ProdValue -Data $Prod -Name "BASTION_SERVICE_ID"
    $sshPubKey = Get-ProdValue -Data $Prod -Name "BASTION_SSH_PUBLIC_KEY_PATH"
    $ttl = Get-ProdValue -Data $Prod -Name "BASTION_SESSION_TTL"
    if (-not $ttl) { $ttl = "10800" }

    Write-Log "Creating bastion port-forward session for $DisplayName -> ${TargetIp}:$TargetPort"

    $sessionJson = & oci bastion session create-port-forwarding `
        --bastion-id $bastionId `
        --display-name $DisplayName `
        --target-private-ip $TargetIp `
        --target-port $TargetPort `
        --ssh-public-key-file $sshPubKey `
        --session-ttl $ttl `
        --wait-for-state SUCCEEDED `
        --output json

    $session = $sessionJson | ConvertFrom-Json
    $sessionId = $session.data.id
    if (-not $sessionId) {
        Throw-Error "Failed to create bastion session for $DisplayName"
    }

    $sshCommand = & oci bastion session get --session-id $sessionId --query 'data."ssh-metadata".command' --raw-output

    Write-Host ""
    Write-Host "[$DisplayName]"
    Write-Host "session_id=$sessionId"
    Write-Host "ssh_command=$sshCommand"
    Write-Host ""
}

function Link-Prod {
    Validate-Prod
    $prod = Read-ProdEnv

    $genAiIp = Get-ProdValue -Data $prod -Name "PROD_GENAI_PRIVATE_IP"
    $genAiPort = Get-ProdValue -Data $prod -Name "PROD_GENAI_PORT"
    if (-not $genAiPort) { $genAiPort = "443" }

    $llamaIp = Get-ProdValue -Data $prod -Name "PROD_LLAMA_PRIVATE_IP"
    $llamaPort = Get-ProdValue -Data $prod -Name "PROD_LLAMA_PORT"
    if (-not $llamaPort) { $llamaPort = "8000" }

    New-BastionPortForwardSession -DisplayName "fortisai-genai-link" -TargetIp $genAiIp -TargetPort $genAiPort -Prod $prod
    New-BastionPortForwardSession -DisplayName "fortisai-llama-link" -TargetIp $llamaIp -TargetPort $llamaPort -Prod $prod

    $ghIp = Get-ProdValue -Data $prod -Name "PROD_GITHUB_PRIVATE_IP"
    $ghPort = Get-ProdValue -Data $prod -Name "PROD_GITHUB_PORT"
    if (-not $ghPort) { $ghPort = "443" }

    if ($ghIp) {
        New-BastionPortForwardSession -DisplayName "fortisai-github-link" -TargetIp $ghIp -TargetPort $ghPort -Prod $prod
    }
    else {
        Write-Log "Skipping GitHub bastion session (PROD_GITHUB_PRIVATE_IP not set)."
    }
}

function Show-Help {
    @"
FortisAI local dev helper (Windows)

Usage:
  .\fortisai-dev-helper.ps1 setup
    .\fortisai-dev-helper.ps1 oracle-db-pull
  .\fortisai-dev-helper.ps1 up
  .\fortisai-dev-helper.ps1 down
  .\fortisai-dev-helper.ps1 all-up
  .\fortisai-dev-helper.ps1 all-down
    .\fortisai-dev-helper.ps1 openclaw-up
    .\fortisai-dev-helper.ps1 openclaw-down
    .\fortisai-dev-helper.ps1 openclaw-shell
        .\fortisai-dev-helper.ps1 openwebui-shell
        .\fortisai-dev-helper.ps1 openvscode-up
        .\fortisai-dev-helper.ps1 openvscode-down
        .\fortisai-dev-helper.ps1 openvscode-users
        .\fortisai-dev-helper.ps1 openvscode-shell [user]
        .\fortisai-dev-helper.ps1 openvscode-list-extensions [user]
        .\fortisai-dev-helper.ps1 openvscode-install-extension [user] <extension-id-or-vsix>
        .\fortisai-dev-helper.ps1 openvscode-uninstall-extension [user] <extension-id>
        .\fortisai-dev-helper.ps1 hermes-up
        .\fortisai-dev-helper.ps1 hermes-down
        .\fortisai-dev-helper.ps1 hermes-shell
        .\fortisai-dev-helper.ps1 traefik-up|traefik-down|traefik-check
        .\fortisai-dev-helper.ps1 codeindexer-up|codeindexer-down|codeindexer-check
        .\fortisai-dev-helper.ps1 milvus-up|milvus-down
        .\fortisai-dev-helper.ps1 opensearch-up|opensearch-down
        .\fortisai-dev-helper.ps1 openmetadata-up|openmetadata-down|openmetadata-check
        .\fortisai-dev-helper.ps1 vault-up
        .\fortisai-dev-helper.ps1 vault-down
        .\fortisai-dev-helper.ps1 vault-init
        .\fortisai-dev-helper.ps1 vault-unseal
        .\fortisai-dev-helper.ps1 vault-status
        .\fortisai-dev-helper.ps1 vault-read <path>
        .\fortisai-dev-helper.ps1 vault-write <path> <value>
        .\fortisai-dev-helper.ps1 vault-del <path>
  .\fortisai-dev-helper.ps1 status
                .\fortisai-dev-helper.ps1 logs oracle-db|mongodb|redis|rabbitmq|vault|firecrawl|pgvector|honcho|openapi-servers|openclaw|hermes|n8n|openwebui|openvscode|appsmith|qdrant|dify|daytona|traefik|codeindexer|milvus|openmetadata|opensearch|ords|sqlcl|oracle-node-api
  .\fortisai-dev-helper.ps1 check
        .\fortisai-dev-helper.ps1 sqlcl-shell
        .\fortisai-dev-helper.ps1 sqlcl-mcp
                .\fortisai-dev-helper.ps1 sqlcl-mcp-smoke
            .\fortisai-dev-helper.ps1 n8n-import-workflows
            .\fortisai-dev-helper.ps1 mcp-up
            .\fortisai-dev-helper.ps1 mcp-down
      .\fortisai-dev-helper.ps1 apex-install
      .\fortisai-dev-helper.ps1 apex-check
        .\fortisai-dev-helper.ps1 apex-reset
    .\fortisai-dev-helper.ps1 daytona-setup
    .\fortisai-dev-helper.ps1 daytona-up  (prefers Docker Compose for runner stability)
    .\fortisai-dev-helper.ps1 daytona-down
    .\fortisai-dev-helper.ps1 daytona-check
    .\fortisai-dev-helper.ps1 daytona-docker-smoke
    .\fortisai-dev-helper.ps1 daytona-set-admin-creds <email> <password>
    .\fortisai-dev-helper.ps1 daytona-revoke-key <key-name>
  .\fortisai-dev-helper.ps1 scaffold-config-repos
    .\fortisai-dev-helper.ps1 scaffold-templates [all|dify|n8n] [name]
    .\fortisai-dev-helper.ps1 lmstudio-setup
    .\fortisai-dev-helper.ps1 lmstudio-start
    .\fortisai-dev-helper.ps1 lmstudio-check
  .\fortisai-dev-helper.ps1 prod-template
  .\fortisai-dev-helper.ps1 validate-prod
  .\fortisai-dev-helper.ps1 link-prod
  .\fortisai-dev-helper.ps1 help

The default up/down flow includes Oracle AI Database Free, MongoDB, Redis, RabbitMQ, HashiCorp Vault, pgvector, Honcho, OpenAPI servers, Dify, Qdrant, n8n, OpenWebUI, OpenVSCode, Appsmith, ORDS, SQLcl sidecar, Oracle Node API, and generated SQLcl MCP config on the shared fortisai-dev-net network.

all-up/all-down add the Linux parity sequence: CodeIndexer + Milvus, OpenMetadata + OpenSearch, MCP OpenAPI bridges, OpenClaw, Hermes, Daytona, and Traefik.

mcp-up starts SQLcl, n8n, Dify, debug, CodeIndexer, and optional Proxmox MCP OpenAPI bridge containers. Proxmox starts when Development_Environment\mcp\proxmox\proxmox-config.json exists, when PROXMOX_* values are set, or when PROXMOX_BRIDGE_ENABLED=true.

Environment overrides:
  FORTISAI_DEV_HOME (default: $HOME\fortisai-dev)
  PODMAN_CPUS (default: 6)
  PODMAN_MEMORY_MB (default: 12288)
  PODMAN_DISK_GB (default: 80)
    FORTISAI_SHARED_NETWORK (default: fortisai-dev-net)
    ORACLE_DB_HOST_PORT (default: 1521)
    ORACLE_DB_CONTAINER_NAME (default: fortisai-oracle-db)
    ORACLE_DB_IMAGE (default: container-registry.oracle.com/database/free:latest)
    ORACLE_DB_PDB (default: FREEPDB1)
    ORACLE_DB_USER (default: pdbadmin)
    ORACLE_DB_PASSWORD (default: FortisAI26ai!2026)
    ORDS_CONTAINER_NAME (default: fortisai-ords)
    ORDS_IMAGE (default: container-registry.oracle.com/database/ords:latest)
    ORDS_HOST_PORT (default: 8181)
    ORDS_CONFIG_VOLUME (default: fortisai-ords-config)
    ORDS_DB_USER (default: ORDS_PUBLIC_USER)
    ORDS_DB_PASSWORD (default: ORACLE_DB_PASSWORD)
    SQLCL_CONTAINER_NAME (default: fortisai-sqlcl)
    SQLCL_IMAGE (default: container-registry.oracle.com/database/sqlcl:latest)
    ORACLE_NODE_API_CONTAINER_NAME (default: fortisai-oracle-node-api)
    APPSMITH_CONTAINER_NAME (default: fortisai-appsmith)
    APPSMITH_IMAGE (default: appsmith/appsmith-ce:latest)
    APPSMITH_HOST_PORT (default: 18080)
    OPENVSCODE_CONTAINER_NAME (default: fortisai-openvscode)
    OPENVSCODE_IMAGE (default: gitpod/openvscode-server:latest)
    OPENVSCODE_HOST_PORT (default: 13000)
    OPENVSCODE_USERS (default: current user; entries: user[:port[:token[:workspace]]], comma or space separated)
    OPENVSCODE_CONNECTION_TOKEN (default: fortisai-openvscode-dev-token)
    OPENVSCODE_WORKSPACE_DIR (default: HOME)
    OPENVSCODE_WORKSPACE_MOUNT_PATH (default: /workspace)
    OPENVSCODE_USER_DATA_DIR (container path for per-user settings)
    OPENVSCODE_EXTENSIONS_DIR (container path for per-user extensions)
    APPSMITH_DB_URL (default: mongodb://fortisai-mongodb:27017/appsmith?replicaSet=rs0)
    APPSMITH_POSTGRES_DB_URL (default: postgresql://fortisai:fortisai@fortisai-pgvector:5432/fortisai)
    APPSMITH_REDIS_URL (default: redis://fortisai-redis:6379)
    APPSMITH_DISABLE_TELEMETRY (default: true)
    APPSMITH_SEGMENT_CE_KEY (default: disabled)
    APPSMITH_PYLON_APP_ID (default: disabled)
    APPSMITH_BETTERBUGS_API_KEY (default: disabled)
    APPSMITH_CLOUD_SERVICES_BASE_URL (default: empty/image default)
    MONGODB_CONTAINER_NAME (default: fortisai-mongodb)
    MONGODB_IMAGE (default: mongo:7)
    MONGODB_HOST_PORT (default: 27017)
    MONGODB_DB (default: appsmith)
    MONGODB_REPLICA_SET (default: rs0)
    REDIS_CONTAINER_NAME (default: fortisai-redis)
    REDIS_IMAGE (default: redis:7-alpine)
    REDIS_HOST_PORT (default: 6379)
    RABBITMQ_CONTAINER_NAME (default: fortisai-rabbitmq)
    RABBITMQ_IMAGE (default: rabbitmq:3.13-management-alpine)
    RABBITMQ_HOST_PORT (default: 5672)
    RABBITMQ_MANAGEMENT_HOST_PORT (default: 15672)
    RABBITMQ_DEFAULT_USER (default: fortisai)
    RABBITMQ_DEFAULT_PASSWORD (default: fortisai)
    VAULT_URL (default: http://127.0.0.1:8200)
    VAULT_CONTAINER_NAME (default: fortisai-vault)
    VAULT_IMAGE (default: docker.io/hashicorp/vault:latest)
    VAULT_HOST_PORT (default: 8200)
    VAULT_INTERNAL_URL (default: http://fortisai-vault:8200)
    VAULT_KEYS_FILE (default: FORTISAI_DEV_HOME\vault\vault-init.json)
    VAULT_TOKEN (optional override; helper auto-creates a read-only service token)
    PGVECTOR_CONTAINER_NAME (default: fortisai-pgvector)
    PGVECTOR_IMAGE (default: pgvector/pgvector:pg16)
    PGVECTOR_HOST_PORT (default: 5432)
    PGVECTOR_DB (default: fortisai)
    PGVECTOR_USER (default: fortisai)
    PGVECTOR_PASSWORD (default: fortisai)
    HONCHO_DB (default: honcho)
    HONCHO_API_CONTAINER_NAME (default: fortisai-honcho-api)
    HONCHO_DERIVER_CONTAINER_NAME (default: fortisai-honcho-deriver)
    HONCHO_HOST_PORT (default: 8010)
    HONCHO_LLM_OPENAI_API_KEY (default: lmstudio)
    HONCHO_LMSTUDIO_BASE_URL (default: http://host.docker.internal:1234/v1)
    HONCHO_LMSTUDIO_MODELS_URL (default: LMSTUDIO_MODELS_URL)
    HONCHO_LMSTUDIO_MODEL (default: auto)
    HONCHO_EMBED_MESSAGES (default: false)
    OPENCLAW_URL (default: http://127.0.0.1:18789)
    HERMES_URL (default: http://127.0.0.1:8642)
    FIRECRAWL_URL (default: http://127.0.0.1:3002)
    TRAEFIK_URL (default: http://127.0.0.1:18000)
    TRAEFIK_DASHBOARD_URL (default: http://127.0.0.1:18088/dashboard/)
    CODEINDEXER_OPENAPI_URL (default: http://127.0.0.1:8096)
    MILVUS_URL (default: http://127.0.0.1:19091/healthz)
    OPENMETADATA_URL (default: http://127.0.0.1:18585)
    OPENSEARCH_URL (default: http://127.0.0.1:9200)
    OPENAPI_FILESYSTEM_URL (default: http://127.0.0.1:8081)
    OPENAPI_MEMORY_URL (default: http://127.0.0.1:8082)
    OPENAPI_TIME_URL (default: http://127.0.0.1:8083)
    OPENAPI_OPENWEBUI_HOST_BASE (default: http://host.containers.internal)
    OPENAPI_FILESYSTEM_OPENWEBUI_URL (default: OPENAPI_OPENWEBUI_HOST_BASE:8081)
    OPENAPI_MEMORY_OPENWEBUI_URL (default: OPENAPI_OPENWEBUI_HOST_BASE:8082)
    OPENAPI_TIME_OPENWEBUI_URL (default: OPENAPI_OPENWEBUI_HOST_BASE:8083)
    OPENCLAW_CONTAINER_NAME (default: fortisai-claw-gateway)
    OPENCLAW_IMAGE (default: docker.io/library/node:24-bookworm)
    OPENCLAW_GATEWAY_PORT (default: 18789)
    OPENCLAW_BRIDGE_PORT (default: 18790)
    OPENCLAW_GATEWAY_BIND (default: 0.0.0.0)
    OPENCLAW_GATEWAY_TOKEN (default: fortisai-claw-gateway-dev-token)
    OPENCLAW_GATEWAY_PASSWORD (optional)
    FORTISAI_PROXY_OPENAI_BASE_URL (default: http://fortisai-mcp-openapi-dify:8093/v1)
    FORTISAI_PROXY_OPENAI_MODEL (default: fortisai)
    OPENCLAW_LMSTUDIO_BASE_URL (default: FORTISAI_PROXY_OPENAI_BASE_URL)
    OPENCLAW_LMSTUDIO_MODEL (default: FORTISAI_PROXY_OPENAI_MODEL)
    OPENCLAW_OPENAI_API_KEY (default: FORTISAI_PROXY_OPENAI_API_KEY)
    OPENCLAW_HONCHO_PLUGIN_PACKAGE (default: @honcho-ai/openclaw-honcho)
    OPENCLAW_HONCHO_BASE_URL (default: http://fortisai-honcho-api:8000)
    OPENCLAW_HONCHO_WORKSPACE_ID (default: openclaw)
    OPENCLAW_HONCHO_API_KEY (default: empty for local Honcho)
    HERMES_CONTAINER_NAME (default: fortisai-hermes)
    HERMES_IMAGE (default: nousresearch/hermes-agent:latest)
    HERMES_GATEWAY_PORT (default: 8642)
    HERMES_DASHBOARD_PORT (default: 9119)
    HERMES_DASHBOARD (default: 1, forced during startup)
    HERMES_API_SERVER_ENABLED (default: true)
    HERMES_API_SERVER_HOST (default: 0.0.0.0)
    HERMES_API_SERVER_KEY (default: fortisai-hermes-dev-api-key)
    HERMES_API_SERVER_CORS_ORIGINS (default: *)
    HERMES_HONCHO_BASE_URL (default: http://fortisai-honcho-api:8000)
    HERMES_HONCHO_WORKSPACE_ID (default: hermes)
    HERMES_HONCHO_API_KEY (default: empty)
    HERMES_DAYTONA_DASHBOARD_URL (default: DAYTONA_URL)
    HERMES_DAYTONA_API_URL (default: http://host.docker.internal:DAYTONA_API_HOST_PORT)
    HERMES_OPENAI_BASE_URL (default: FORTISAI_PROXY_OPENAI_BASE_URL)
    HERMES_OPENAI_MODEL (default: FORTISAI_PROXY_OPENAI_MODEL)
    HERMES_WHATSAPP_ENABLED (default: false; set true only after pairing WhatsApp)
    FIRECRAWL_CONTAINER_NAME (default: fortisai-firecrawl)
    FIRECRAWL_IMAGE (default: ghcr.io/firecrawl/firecrawl:latest)
    FIRECRAWL_HOST_PORT (default: 3002)
    FIRECRAWL_API_KEY (default: fortisai-firecrawl-dev-api-key)
    FIRECRAWL_INTERNAL_URL (default: http://fortisai-firecrawl:3002)
    FIRECRAWL_DB_NAME (default: firecrawl)
    FIRECRAWL_DB_USER (default: firecrawl)
    FIRECRAWL_DB_PASSWORD (default: firecrawl)
    FIRECRAWL_DATABASE_URL (default: postgresql://fortisai:fortisai@fortisai-pgvector:5432/firecrawl)
    FIRECRAWL_RABBITMQ_USER (default: fortisai)
    FIRECRAWL_RABBITMQ_PASSWORD (default: fortisai)
    FIRECRAWL_RABBITMQ_URL (default: amqp://fortisai:fortisai@fortisai-rabbitmq:5672)
    FIRECRAWL_REDIS_URL (default: redis://fortisai-redis:6379)
    FIRECRAWL_REDIS_EVICT_URL (default: FIRECRAWL_REDIS_URL)
    FIRECRAWL_REDIS_RATE_LIMIT_URL (default: FIRECRAWL_REDIS_URL)
    FIRECRAWL_NUQ_SQL_URL (default: https://raw.githubusercontent.com/firecrawl/firecrawl/main/apps/nuq-postgres/nuq.sql)
    TRAEFIK_CONTAINER_NAME (default: fortisai-traefik)
    TRAEFIK_IMAGE (default: docker.io/library/traefik:latest)
    TRAEFIK_WEB_HOST_PORT (default: 18000)
    TRAEFIK_DASHBOARD_HOST_PORT (default: 18088)
    CODEINDEXER_BRIDGE_CONTAINER_NAME (default: fortisai-mcp-openapi-codeindexer)
    CODEINDEXER_BRIDGE_HOST_PORT (default: 8096)
    CODEINDEXER_OPENAI_BASE_URL (default: http://fortisai-mcp-openapi-dify:8093/v1)
    CODEINDEXER_OPENAI_EMBEDDING_MODEL (default: fortisai)
    CODEINDEXER_OPENAI_EMBEDDING_DIMENSION (default: 1536)
    MILVUS_CONTAINER_NAME (default: fortisai-milvus)
    MILVUS_HOST_PORT (default: 19530)
    MILVUS_HEALTH_HOST_PORT (default: 19091)
    OPENMETADATA_CONTAINER_NAME (default: fortisai-openmetadata)
    OPENMETADATA_HOST_PORT (default: 18585)
    OPENMETADATA_ADMIN_HOST_PORT (default: 18586)
    OPENSEARCH_CONTAINER_NAME (default: fortisai-opensearch)
    OPENSEARCH_HOST_PORT (default: 9200)
    OPENWEBUI_LLM_BACKEND (default: hermes; options: openclaw|hermes)
    SQLCL_MCP_PYTHON_CMD (default: python)
    APEX_DOWNLOAD_URL (default: https://download.oracle.com/otn_software/apex/apex-latest.zip)
    APEX_WORK_DIR (default: ORACLE_DB_DIR/apex)
    APEX_ADMIN_PASSWORD (default: ORACLE_DB_PASSWORD)
    OCR_REGISTRY (default: container-registry.oracle.com)
    OCR_USERNAME (optional: OCR username)
    OCR_AUTH_TOKEN (optional: OCR auth token)
  N8N_URL (default: http://localhost:5678)
  OPENWEBUI_URL (default: http://localhost:3000)
        OPENVSCODE_URL (default: http://localhost:13000)
        APPSMITH_URL (default: http://localhost:18080)
    MONGODB_URL (default: mongodb://127.0.0.1:27017/appsmith?replicaSet=rs0)
    DIFY_URL (default: http://localhost:18081)
        REDIS_URL (default: redis://127.0.0.1:6379)
        RABBITMQ_URL (default: amqp://fortisai:fortisai@127.0.0.1:5672)
        RABBITMQ_MANAGEMENT_URL (default: http://127.0.0.1:15672)
        PGVECTOR_URL (default: postgresql://fortisai:fortisai@127.0.0.1:5432/fortisai)
        QDRANT_URL (default: http://127.0.0.1:6333)
        QDRANT_INTERNAL_URL (default: http://qdrant:6333)
        QDRANT_API_KEY (default: difyai123456)
        QDRANT_HOST_PORT (default: 6333)
        QDRANT_GRPC_HOST_PORT (default: 6334)
    ORDS_URL (default: http://127.0.0.1:8181/ords/)
        HONCHO_URL (default: http://127.0.0.1:8010)
        ORACLE_NODE_API_URL (default: http://127.0.0.1:8090)
        APEX_URL (default: http://127.0.0.1:8181/ords/apex)
    DAYTONA_URL (default: http://localhost:3300)
    LMSTUDIO_MODELS_URL (default: http://localhost:1234/v1/models)
    DAYTONA_API_HOST_PORT (default: 3300)
    DAYTONA_PROXY_HOST_PORT (default: 4400)
    DAYTONA_SSH_HOST_PORT (default: 2223)
    DAYTONA_DEX_HOST_PORT (default: 5556)
    DAYTONA_PGADMIN_HOST_PORT (default: 55050)
    DAYTONA_REGISTRY_UI_HOST_PORT (default: 55100)
    DAYTONA_REGISTRY_HOST_PORT (default: 56000)
    DAYTONA_MAILDEV_HOST_PORT (default: 11080)
    DAYTONA_MINIO_CONSOLE_HOST_PORT (default: 59001)
    DAYTONA_JAEGER_HOST_PORT (default: 16687)
    DAYTONA_API_KEY (required for daytona-revoke-key; optional for daytona-docker-smoke API test)
    DAYTONA_ORG_ID (optional for daytona-revoke-key; required for daytona-docker-smoke API test)
    APP_API_KEY (default: loaded from $DifyApiKeyJsonFile)
    KNOWLEDGE_API_KEY (default: loaded from $DifyApiKeyJsonFile)
    ADMIN_API_KEY_ENABLE (default: true)
    ADMIN_API_KEY (default: auto-resolved from running Dify API container for MCP admin routes)
    DIFY_ADMIN_API_KEY (optional override for MCP admin routes)
    DIFY_ADMIN_WORKSPACE_ID (optional override; auto-resolved from tenant table when unset)
    PROXMOX_BRIDGE_ENABLED (default: auto; true to force Proxmox MCP bridge startup)
    PROXMOX_HOST, PROXMOX_PORT, PROXMOX_USER, PROXMOX_TOKEN_NAME, PROXMOX_TOKEN_VALUE (optional Proxmox MCP config; synced to Vault)
    PROXMOX_API_KEY (default: fortisai-proxmox-openapi-dev-key; synced to Vault for Proxmox OpenAPI bearer auth)
    PROXMOX_API_STRICT_AUTH (default: false)
"@ | Write-Host
}

switch ($Command.ToLowerInvariant()) {
    "setup" { Setup-All }
    "oracle-db-pull" { Pull-OracleDbImage }
    "up" { Start-All }
    "down" { Stop-All }
    "all-up" { Start-FullStack }
    "all-down" { Stop-FullStack }
    "openclaw-up" { Start-OpenClaw }
    "openclaw-down" { Stop-OpenClaw }
    "openclaw-shell" { Start-OpenClawShell }
    "openwebui-shell" { Start-OpenWebUiShell }
    "openvscode-up" { Start-OpenVscode }
    "openvscode-down" { Stop-OpenVscode }
    "openvscode-users" { Show-OpenVscodeUsers }
    "openvscode-shell" { Start-OpenVscodeShell -User $Target }
    "openvscode-list-extensions" { List-OpenVscodeExtensions -User $Target }
    "openvscode-install-extension" { Install-OpenVscodeExtension -TargetOrExtension $Target -MaybeExtension $Name }
    "openvscode-uninstall-extension" { Uninstall-OpenVscodeExtension -TargetOrExtension $Target -MaybeExtension $Name }
    "hermes-up" { Start-Hermes }
    "hermes-down" { Stop-Hermes }
    "hermes-shell" { Start-HermesShell }
    "traefik-up" { Start-Traefik }
    "traefik-down" { Stop-Traefik }
    "traefik-check" { Check-Traefik }
    "codeindexer-up" { Start-CodeIndexer }
    "codeindexer-down" { Stop-CodeIndexer }
    "codeindexer-check" { Check-CodeIndexer }
    "milvus-up" { Start-Milvus }
    "milvus-down" { Stop-Milvus }
    "opensearch-up" { Start-OpenSearch }
    "opensearch-down" { Stop-OpenSearch }
    "openmetadata-up" { Start-OpenMetadata }
    "openmetadata-down" { Stop-OpenMetadata }
    "openmetadata-check" { Check-OpenMetadata }
    "vault-up" { Start-Vault }
    "vault-down" { Stop-Vault }
    "vault-init" { Initialize-Vault }
    "vault-unseal" { Unseal-Vault }
    "vault-status" { Show-VaultStatus }
    "vault-read" { Read-VaultSecret -Path $Target }
    "vault-write" { Write-VaultSecret -Path $Target -Value $Name }
    "vault-del" { Remove-VaultSecret -Path $Target }
    "status" { Show-Status }
    "logs" {
        if (-not $Target) { Throw-Error "Missing logs target. Use oracle-db, mongodb, redis, rabbitmq, vault, firecrawl, pgvector, honcho, openclaw, hermes, n8n, openwebui, openvscode, appsmith, qdrant, dify, daytona, traefik, codeindexer, milvus, openmetadata, opensearch, ords, sqlcl, or oracle-node-api." }
        Show-Logs -LogTarget $Target
    }
    "check" { Check-Services }
    "sqlcl-shell" { Start-SqlclShell }
    "sqlcl-mcp" { Start-SqlclMcp }
    "sqlcl-mcp-smoke" { Start-SqlclMcpSmoke }
    "n8n-import-workflows" { Import-N8nWorkflows }
    "mcp-up" { Start-McpUp }
    "mcp-down" { Stop-McpDown }
    "apex-install" { Install-Apex }
    "apex-check" { Check-Apex }
    "apex-reset" { Reset-Apex }
    "daytona-setup" { Setup-DaytonaRepo }
    "daytona-up" { Start-Daytona }
    "daytona-down" { Stop-Daytona }
    "daytona-check" { Check-Daytona }
    "daytona-docker-smoke" { Invoke-DaytonaDockerSmoke }
    "daytona-set-admin-creds" { Set-DaytonaAdminCreds -NewEmail $Target -NewPassword $Name }
    "daytona-revoke-key" { Revoke-DaytonaApiKey -ApiKeyName $Target }
    "scaffold-config-repos" { Setup-ConfigRepos }
    "scaffold-templates" { Scaffold-Templates -Mode $(if ($Target) { $Target } else { "all" }) -Name $Name }
    "lmstudio-setup" { Setup-LMStudio }
    "lmstudio-start" { Start-LMStudio }
    "lmstudio-check" { Check-LMStudio }
    "prod-template" { Write-ProdTemplate }
    "validate-prod" { Validate-Prod }
    "link-prod" { Link-Prod }
    "help" { Show-Help }
    default {
        Throw-Error "Unknown command: $Command"
    }
}
