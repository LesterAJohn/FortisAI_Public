#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="${FORTISAI_DEV_HOME:-$HOME/fortisai-dev}"
CONFIG_REPOS_DIR="$BASE_DIR/config-repos"
N8N_DIR="$BASE_DIR/n8n"
OPENWEBUI_DIR="$BASE_DIR/openwebui"
OPENVSCODE_DIR="$BASE_DIR/openvscode"
APPSMITH_DIR="$BASE_DIR/appsmith"
MONGODB_DIR="$BASE_DIR/mongodb"
REDIS_DIR="$BASE_DIR/redis"
RABBITMQ_DIR="$BASE_DIR/rabbitmq"
VAULT_DIR="$BASE_DIR/vault"
PGVECTOR_DIR="$BASE_DIR/pgvector"
ORACLE_DB_DIR="$BASE_DIR/oracle-db"
ORDS_DIR="$BASE_DIR/ords"
SQLCL_DIR="$BASE_DIR/sqlcl"
SQLCL_MCP_DIR="$BASE_DIR/sqlcl-mcp"
HONCHO_DIR="$BASE_DIR/honcho"
HONCHO_REPO_DIR="$HONCHO_DIR/repo"
OPENCLAW_DIR="$BASE_DIR/claw-gateway"
HERMES_DIR="$BASE_DIR/hermes-agent"
FIRECRAWL_DIR="$BASE_DIR/firecrawl"
TRAEFIK_DIR="$BASE_DIR/traefik"
CODEINDEXER_DIR="$BASE_DIR/codeindexer"
CODEINDEXER_REPO_DIR="$CODEINDEXER_DIR/repo"
CODEINDEXER_STATE_DIR="$CODEINDEXER_DIR/state"
MILVUS_DIR="$BASE_DIR/milvus"
OPENMETADATA_DIR="$BASE_DIR/openmetadata"
OPENSEARCH_DIR="$BASE_DIR/opensearch"
OPENAPI_SERVERS_DIR="$BASE_DIR/openapi-servers"
OPENAPI_SERVERS_REPO_DIR="$OPENAPI_SERVERS_DIR/repo"
DIFY_REPO_DIR="$BASE_DIR/dify"
DIFY_DOCKER_DIR="$DIFY_REPO_DIR/docker"
DIFY_VAULT_COMPOSE_FILE="$DIFY_DOCKER_DIR/docker-compose.fortisai-vault.yaml"
DIFY_UP_SCRIPT="$DIFY_DOCKER_DIR/start-postgresql-podman.sh"
DAYTONA_REPO_DIR="$BASE_DIR/daytona"
DAYTONA_COMPOSE_FILE="$DAYTONA_REPO_DIR/docker/docker-compose.yaml"
DAYTONA_RUNTIME_FILE="$DAYTONA_REPO_DIR/docker/docker-compose.fortisai.runtime.yaml"
DAYTONA_GPU_MODE="${DAYTONA_GPU_MODE:-auto}"
LOCAL_DIFY_CONFIG_REPO_DIR="$CONFIG_REPOS_DIR/dify-config"
LOCAL_N8N_CONFIG_REPO_DIR="$CONFIG_REPOS_DIR/n8n-config"
PROD_ENV_FILE="$BASE_DIR/.prod-link.env"
PROD_ENV_EXAMPLE_FILE="$BASE_DIR/.prod-link.env.example"
DEV_ENV_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT_DIR="$(cd "$DEV_ENV_DIR/.." && pwd)"
TEMPLATES_DIR="$DEV_ENV_DIR/templates"
ORACLE_NODE_API_DIR="$DEV_ENV_DIR/oracle-node-api"
MCP_ROOT_DIR="$DEV_ENV_DIR/mcp"
DIFY_MCP_DIR="$MCP_ROOT_DIR/dify-mcp"
DIFY_KEYS_JSON_FILE="$DIFY_MCP_DIR/dify-api-key.json"
DIFY_MCP_UP_SCRIPT="$MCP_ROOT_DIR/start-mcp-openapi-bridges.sh"
DIFY_MCP_DOWN_SCRIPT="$MCP_ROOT_DIR/stop-mcp-openapi-bridges.sh"
PROXMOX_MCP_DIR="$MCP_ROOT_DIR/proxmox"
PROXMOX_MCP_CONFIG_FILE="$PROXMOX_MCP_DIR/proxmox-config.json"
N8N_MCP_DIR="$MCP_ROOT_DIR/n8n-mcp"
N8N_MCP_SERVER_FILE="$N8N_MCP_DIR/n8n-mcp-server.py"
CODEINDEXER_MCP_DIR="$MCP_ROOT_DIR/codeindexer-mcp"
FORTISAI_CALICO_DNS_ZONE="${FORTISAI_CALICO_DNS_ZONE:-fortisai.local}"
FORTISAI_COREDNS_CONTAINER_NAME="${FORTISAI_COREDNS_CONTAINER_NAME:-fortisai-coredns}"
SQLCL_OPENWEBUI_TOOLS_IMPORT_FILE="$MCP_ROOT_DIR/sqlcl-mcp/openwebui-sqlcl-mcp-tools.import.json"
SQLCL_OPENWEBUI_SKILL_CREATE_FILE="$MCP_ROOT_DIR/sqlcl-mcp/openwebui-sqlcl-mcp-skill.create.json"
N8N_OPENWEBUI_TOOLS_IMPORT_FILE="$N8N_MCP_DIR/openwebui-n8n-mcp-tools.import.json"
N8N_OPENWEBUI_SKILL_CREATE_FILE="$N8N_MCP_DIR/openwebui-n8n-mcp-skill.create.json"
CODEINDEXER_OPENWEBUI_TOOLS_IMPORT_FILE="$CODEINDEXER_MCP_DIR/openwebui-codeindexer-mcp-tools.import.json"
CODEINDEXER_OPENWEBUI_SKILL_CREATE_FILE="$CODEINDEXER_MCP_DIR/openwebui-codeindexer-mcp-skill.create.json"
PROXMOX_OPENWEBUI_TOOLS_IMPORT_FILE="$PROXMOX_MCP_DIR/openwebui-proxmox-mcp-tools.import.json"
PROXMOX_OPENWEBUI_SKILL_CREATE_FILE="$PROXMOX_MCP_DIR/openwebui-proxmox-mcp-skill.create.json"
REPO_OPENAPI_MCP_DIR="$MCP_ROOT_DIR/repo-openapi"
REPO_FILESYSTEM_OPENWEBUI_TOOLS_IMPORT_FILE="$REPO_OPENAPI_MCP_DIR/openwebui-repo-filesystem-tools.import.json"
REPO_FILESYSTEM_OPENWEBUI_SKILL_CREATE_FILE="$REPO_OPENAPI_MCP_DIR/openwebui-repo-filesystem-skill.create.json"
REPO_MEMORY_OPENWEBUI_TOOLS_IMPORT_FILE="$REPO_OPENAPI_MCP_DIR/openwebui-repo-memory-tools.import.json"
REPO_MEMORY_OPENWEBUI_SKILL_CREATE_FILE="$REPO_OPENAPI_MCP_DIR/openwebui-repo-memory-skill.create.json"
REPO_TIME_OPENWEBUI_TOOLS_IMPORT_FILE="$REPO_OPENAPI_MCP_DIR/openwebui-repo-time-tools.import.json"
REPO_TIME_OPENWEBUI_SKILL_CREATE_FILE="$REPO_OPENAPI_MCP_DIR/openwebui-repo-time-skill.create.json"
DIFY_OPENWEBUI_TOOLS_IMPORT_FILE="$DIFY_MCP_DIR/openwebui-dify-mcp-tools.import.json"
DIFY_OPENWEBUI_SKILL_CREATE_FILE="$DIFY_MCP_DIR/openwebui-dify-mcp-skill.create.json"

N8N_COMPOSE_FILE="$N8N_DIR/docker-compose.yml"
OPENWEBUI_COMPOSE_FILE="$OPENWEBUI_DIR/docker-compose.yml"
OPENVSCODE_COMPOSE_FILE="$OPENVSCODE_DIR/docker-compose.yml"
APPSMITH_COMPOSE_FILE="$APPSMITH_DIR/docker-compose.yml"
MONGODB_COMPOSE_FILE="$MONGODB_DIR/docker-compose.yml"
REDIS_COMPOSE_FILE="$REDIS_DIR/docker-compose.yml"
RABBITMQ_COMPOSE_FILE="$RABBITMQ_DIR/docker-compose.yml"
VAULT_COMPOSE_FILE="$VAULT_DIR/docker-compose.yml"
VAULT_CONFIG_FILE="$VAULT_DIR/config/vault.hcl"
VAULT_KEYS_FILE="${VAULT_KEYS_FILE:-$VAULT_DIR/vault-init.json}"
PGVECTOR_COMPOSE_FILE="$PGVECTOR_DIR/docker-compose.yml"
ORACLE_DB_COMPOSE_FILE="$ORACLE_DB_DIR/docker-compose.yml"
ORACLE_DB_STARTUP_DIR="$ORACLE_DB_DIR/startup"
ORDS_COMPOSE_FILE="$ORDS_DIR/docker-compose.yml"
SQLCL_COMPOSE_FILE="$SQLCL_DIR/docker-compose.yml"
SQLCL_MCP_CONFIG_FILE="$SQLCL_MCP_DIR/mcp.json"
HONCHO_COMPOSE_FILE="$HONCHO_DIR/docker-compose.yml"
OPENCLAW_COMPOSE_FILE="$OPENCLAW_DIR/docker-compose.yml"
HERMES_COMPOSE_FILE="$HERMES_DIR/docker-compose.yml"
FIRECRAWL_COMPOSE_FILE="$FIRECRAWL_DIR/docker-compose.yml"
TRAEFIK_COMPOSE_FILE="$TRAEFIK_DIR/docker-compose.yml"
TRAEFIK_STATIC_CONFIG_FILE="$TRAEFIK_DIR/traefik.yml"
TRAEFIK_DYNAMIC_CONFIG_FILE="$TRAEFIK_DIR/dynamic.yml"
TRAEFIK_USERS_FILE="$TRAEFIK_DIR/users.htpasswd"
MILVUS_COMPOSE_FILE="$MILVUS_DIR/docker-compose.yml"
OPENMETADATA_COMPOSE_FILE="$OPENMETADATA_DIR/docker-compose.yml"
OPENSEARCH_COMPOSE_FILE="$OPENSEARCH_DIR/docker-compose.yml"
OPENAPI_SERVERS_COMPOSE_FILE="$OPENAPI_SERVERS_REPO_DIR/compose.yaml"
OPENCLAW_RUNTIME_CONFIG_FILE="$OPENCLAW_DIR/fortisai-claw-gateway.json"
ORACLE_NODE_API_COMPOSE_FILE="$ORACLE_NODE_API_DIR/docker-compose.yml"
OPENAPI_SERVERS_ENV_TEMPLATE_FILE="$OPENAPI_SERVERS_DIR/openwebui-openapi-tools.env.example"
OPENAPI_SERVERS_JSON_TEMPLATE_FILE="$OPENAPI_SERVERS_DIR/openwebui-openapi-tools.example.json"

N8N_URL="${N8N_URL:-http://localhost:5678}"
N8N_BASIC_AUTH_USER="${N8N_BASIC_AUTH_USER:-admin}"
N8N_BASIC_AUTH_PASSWORD="${N8N_BASIC_AUTH_PASSWORD:-change-me-n8n}"
OPENWEBUI_URL="${OPENWEBUI_URL:-http://localhost:3000}"
FORTISAI_OPENWEBUI_DEFAULT_API_KEY_USER="${FORTISAI_OPENWEBUI_DEFAULT_API_KEY_USER:-LesterAJohn@gmail.com}"
OPENWEBUI_API_USER="${OPENWEBUI_API_USER:-$FORTISAI_OPENWEBUI_DEFAULT_API_KEY_USER}"
OPENVSCODE_URL="${OPENVSCODE_URL:-http://localhost:13000}"
APPSMITH_URL="${APPSMITH_URL:-http://localhost:18080}"
MONGODB_URL="${MONGODB_URL:-mongodb://127.0.0.1:27017/appsmith?replicaSet=rs0}"
DIFY_URL="${DIFY_URL:-http://localhost:18081}"
DIFY_API_KEY="${DIFY_API_KEY:-}"
REDIS_URL="${REDIS_URL:-redis://127.0.0.1:6379}"
RABBITMQ_URL="${RABBITMQ_URL:-amqp://fortisai:fortisai@127.0.0.1:5672}"
RABBITMQ_MANAGEMENT_URL="${RABBITMQ_MANAGEMENT_URL:-http://127.0.0.1:15672}"
VAULT_URL="${VAULT_URL:-http://127.0.0.1:8200}"
PGVECTOR_URL="${PGVECTOR_URL:-postgresql://fortisai:fortisai@127.0.0.1:5432/fortisai}"
QDRANT_URL="${QDRANT_URL:-http://127.0.0.1:6333}"
QDRANT_INTERNAL_URL="${QDRANT_INTERNAL_URL:-http://qdrant:6333}"
QDRANT_API_KEY="${QDRANT_API_KEY:-difyai123456}"
QDRANT_HOST_PORT="${QDRANT_HOST_PORT:-6333}"
QDRANT_GRPC_HOST_PORT="${QDRANT_GRPC_HOST_PORT:-6334}"
DAYTONA_URL="${DAYTONA_URL:-http://localhost:3300}"
LMSTUDIO_MODELS_URL="${LMSTUDIO_MODELS_URL:-http://localhost:1234/v1/models}"
FORTISAI_LLAMA_SERVER_URL="${FORTISAI_LLAMA_SERVER_URL:-http://host.docker.internal:8011}"
FORTISAI_LLAMA_SERVER_BASE_URL="${FORTISAI_LLAMA_SERVER_BASE_URL:-$FORTISAI_LLAMA_SERVER_URL/v1}"
FORTISAI_LLAMA_OPENAI_BASE_URL="${FORTISAI_LLAMA_OPENAI_BASE_URL:-$FORTISAI_LLAMA_SERVER_BASE_URL}"
FORTISAI_LLAMA_OPENAI_API_KEY="${FORTISAI_LLAMA_OPENAI_API_KEY:-local-llama}"
ORDS_URL="${ORDS_URL:-http://127.0.0.1:8181/ords/}"
APEX_URL="${APEX_URL:-http://127.0.0.1:8181/ords/apex}"
ORACLE_NODE_API_URL="${ORACLE_NODE_API_URL:-http://127.0.0.1:8090}"
HONCHO_URL="${HONCHO_URL:-http://127.0.0.1:8010}"
OPENCLAW_URL="${OPENCLAW_URL:-http://127.0.0.1:18789}"
HERMES_URL="${HERMES_URL:-http://127.0.0.1:8642}"
FIRECRAWL_URL="${FIRECRAWL_URL:-http://127.0.0.1:3002}"
TRAEFIK_URL="${TRAEFIK_URL:-http://127.0.0.1:18000}"
TRAEFIK_DASHBOARD_URL="${TRAEFIK_DASHBOARD_URL:-http://127.0.0.1:18088/dashboard/}"
CODEINDEXER_OPENAPI_URL="${CODEINDEXER_OPENAPI_URL:-http://127.0.0.1:8096}"
MILVUS_URL="${MILVUS_URL:-http://127.0.0.1:19091/healthz}"
OPENMETADATA_URL="${OPENMETADATA_URL:-http://127.0.0.1:18585}"
OPENSEARCH_URL="${OPENSEARCH_URL:-http://127.0.0.1:9200}"
OPENAPI_FILESYSTEM_URL="${OPENAPI_FILESYSTEM_URL:-http://127.0.0.1:8081}"
OPENAPI_MEMORY_URL="${OPENAPI_MEMORY_URL:-http://127.0.0.1:8082}"
OPENAPI_TIME_URL="${OPENAPI_TIME_URL:-http://127.0.0.1:8083}"
OPENAPI_OPENWEBUI_HOST_BASE="${OPENAPI_OPENWEBUI_HOST_BASE:-http://host.containers.internal}"
OPENAPI_FILESYSTEM_OPENWEBUI_URL="${OPENAPI_FILESYSTEM_OPENWEBUI_URL:-$OPENAPI_OPENWEBUI_HOST_BASE:8081}"
OPENAPI_MEMORY_OPENWEBUI_URL="${OPENAPI_MEMORY_OPENWEBUI_URL:-$OPENAPI_OPENWEBUI_HOST_BASE:8082}"
OPENAPI_TIME_OPENWEBUI_URL="${OPENAPI_TIME_OPENWEBUI_URL:-$OPENAPI_OPENWEBUI_HOST_BASE:8083}"

FORTISAI_SHARED_NETWORK="${FORTISAI_SHARED_NETWORK:-fortisai-dev-net}"
ORACLE_DB_CONTAINER_NAME="${ORACLE_DB_CONTAINER_NAME:-fortisai-oracle-db}"
ORACLE_DB_IMAGE="${ORACLE_DB_IMAGE:-container-registry.oracle.com/database/free:latest}"
ORACLE_DB_HOST_PORT="${ORACLE_DB_HOST_PORT:-1521}"
ORACLE_DB_PDB="${ORACLE_DB_PDB:-FREEPDB1}"
ORACLE_DB_USER="${ORACLE_DB_USER:-pdbadmin}"
ORACLE_DB_PASSWORD="${ORACLE_DB_PASSWORD:-FortisAI26ai!2026}"
ORDS_CONTAINER_NAME="${ORDS_CONTAINER_NAME:-fortisai-ords}"
ORDS_IMAGE="${ORDS_IMAGE:-container-registry.oracle.com/database/ords:latest}"
ORDS_HOST_PORT="${ORDS_HOST_PORT:-8181}"
ORDS_CONFIG_VOLUME="${ORDS_CONFIG_VOLUME:-fortisai-ords-config}"
ORDS_DB_USER="${ORDS_DB_USER:-ORDS_PUBLIC_USER}"
ORDS_DB_PASSWORD="${ORDS_DB_PASSWORD:-$ORACLE_DB_PASSWORD}"
SQLCL_CONTAINER_NAME="${SQLCL_CONTAINER_NAME:-fortisai-sqlcl}"
SQLCL_IMAGE="${SQLCL_IMAGE:-container-registry.oracle.com/database/sqlcl:latest}"
ORACLE_NODE_API_CONTAINER_NAME="${ORACLE_NODE_API_CONTAINER_NAME:-fortisai-oracle-node-api}"
APPSMITH_CONTAINER_NAME="${APPSMITH_CONTAINER_NAME:-fortisai-appsmith}"
APPSMITH_IMAGE="${APPSMITH_IMAGE:-appsmith/appsmith-ce:latest}"
APPSMITH_HOST_PORT="${APPSMITH_HOST_PORT:-18080}"
OPENVSCODE_CONTAINER_NAME="${OPENVSCODE_CONTAINER_NAME:-fortisai-openvscode}"
OPENVSCODE_IMAGE="${OPENVSCODE_IMAGE:-gitpod/openvscode-server:latest}"
OPENVSCODE_HOST_PORT="${OPENVSCODE_HOST_PORT:-13000}"
OPENWEBUI_CONTAINER_NAME="${OPENWEBUI_CONTAINER_NAME:-fortisai-openwebui}"
OPENVSCODE_CONNECTION_TOKEN="${OPENVSCODE_CONNECTION_TOKEN:-fortisai-openvscode-dev-token}"
OPENVSCODE_WORKSPACE_DIR="${OPENVSCODE_WORKSPACE_DIR:-$HOME}"
OPENVSCODE_WORKSPACE_MOUNT_PATH="${OPENVSCODE_WORKSPACE_MOUNT_PATH:-/workspace}"
OPENVSCODE_USERS="${OPENVSCODE_USERS:-${USER:-aiuser}}"
OPENVSCODE_SERVER_BIN="${OPENVSCODE_SERVER_BIN:-/home/.openvscode-server/bin/openvscode-server}"
OPENVSCODE_USER_DATA_DIR="${OPENVSCODE_USER_DATA_DIR:-/home/openvscode-server/.openvscode-user-data}"
OPENVSCODE_EXTENSIONS_DIR="${OPENVSCODE_EXTENSIONS_DIR:-/home/openvscode-server/.openvscode-extensions}"
MONGODB_CONTAINER_NAME="${MONGODB_CONTAINER_NAME:-fortisai-mongodb}"
MONGODB_IMAGE="${MONGODB_IMAGE:-mongo:7}"
MONGODB_HOST_PORT="${MONGODB_HOST_PORT:-27017}"
MONGODB_DB="${MONGODB_DB:-appsmith}"
MONGODB_REPLICA_SET="${MONGODB_REPLICA_SET:-rs0}"
APPSMITH_DB_URL="${APPSMITH_DB_URL:-mongodb://$MONGODB_CONTAINER_NAME:27017/$MONGODB_DB?replicaSet=$MONGODB_REPLICA_SET}"
REDIS_CONTAINER_NAME="${REDIS_CONTAINER_NAME:-fortisai-redis}"
REDIS_IMAGE="${REDIS_IMAGE:-redis:7-alpine}"
REDIS_HOST_PORT="${REDIS_HOST_PORT:-6379}"
RABBITMQ_CONTAINER_NAME="${RABBITMQ_CONTAINER_NAME:-fortisai-rabbitmq}"
RABBITMQ_IMAGE="${RABBITMQ_IMAGE:-rabbitmq:3.13-management-alpine}"
RABBITMQ_HOST_PORT="${RABBITMQ_HOST_PORT:-5672}"
RABBITMQ_MANAGEMENT_HOST_PORT="${RABBITMQ_MANAGEMENT_HOST_PORT:-15672}"
RABBITMQ_DEFAULT_USER="${RABBITMQ_DEFAULT_USER:-fortisai}"
RABBITMQ_DEFAULT_PASSWORD="${RABBITMQ_DEFAULT_PASSWORD:-fortisai}"
VAULT_CONTAINER_NAME="${VAULT_CONTAINER_NAME:-fortisai-vault}"
VAULT_IMAGE="${VAULT_IMAGE:-docker.io/hashicorp/vault:latest}"
VAULT_HOST_PORT="${VAULT_HOST_PORT:-8200}"
VAULT_INTERNAL_URL="${VAULT_INTERNAL_URL:-http://$VAULT_CONTAINER_NAME:8200}"
VAULT_API_ADDR="${VAULT_API_ADDR:-http://127.0.0.1:$VAULT_HOST_PORT}"
VAULT_TOKEN="${VAULT_TOKEN:-}"
PGVECTOR_CONTAINER_NAME="${PGVECTOR_CONTAINER_NAME:-fortisai-pgvector}"
PGVECTOR_IMAGE="${PGVECTOR_IMAGE:-pgvector/pgvector:pg16}"
PGVECTOR_HOST_PORT="${PGVECTOR_HOST_PORT:-5432}"
PGVECTOR_DB="${PGVECTOR_DB:-fortisai}"
PGVECTOR_USER="${PGVECTOR_USER:-fortisai}"
PGVECTOR_PASSWORD="${PGVECTOR_PASSWORD:-fortisai}"
APPSMITH_POSTGRES_DB_URL="${APPSMITH_POSTGRES_DB_URL:-postgresql://$PGVECTOR_USER:$PGVECTOR_PASSWORD@$PGVECTOR_CONTAINER_NAME:5432/$PGVECTOR_DB}"
APPSMITH_REDIS_URL="${APPSMITH_REDIS_URL:-redis://$REDIS_CONTAINER_NAME:6379}"
APPSMITH_DISABLE_TELEMETRY="${APPSMITH_DISABLE_TELEMETRY:-true}"
APPSMITH_SEGMENT_CE_KEY="${APPSMITH_SEGMENT_CE_KEY:-disabled}"
APPSMITH_PYLON_APP_ID="${APPSMITH_PYLON_APP_ID:-disabled}"
APPSMITH_BETTERBUGS_API_KEY="${APPSMITH_BETTERBUGS_API_KEY:-disabled}"
APPSMITH_CLOUD_SERVICES_BASE_URL="${APPSMITH_CLOUD_SERVICES_BASE_URL:-}"
HONCHO_DB="${HONCHO_DB:-honcho}"
HONCHO_API_CONTAINER_NAME="${HONCHO_API_CONTAINER_NAME:-fortisai-honcho-api}"
HONCHO_DERIVER_CONTAINER_NAME="${HONCHO_DERIVER_CONTAINER_NAME:-fortisai-honcho-deriver}"
HONCHO_HOST_PORT="${HONCHO_HOST_PORT:-8010}"
HONCHO_LLM_OPENAI_API_KEY="${HONCHO_LLM_OPENAI_API_KEY:-lmstudio}"
HONCHO_LMSTUDIO_BASE_URL="${HONCHO_LMSTUDIO_BASE_URL:-http://host.docker.internal:1234/v1}"
HONCHO_LMSTUDIO_MODELS_URL="${HONCHO_LMSTUDIO_MODELS_URL:-$LMSTUDIO_MODELS_URL}"
HONCHO_LMSTUDIO_MODEL="${HONCHO_LMSTUDIO_MODEL:-auto}"
HONCHO_EMBED_MESSAGES="${HONCHO_EMBED_MESSAGES:-false}"
FORTISAI_PROXY_OPENAI_BASE_URL="${FORTISAI_PROXY_OPENAI_BASE_URL:-http://fortisai-mcp-openapi-dify:8093/v1}"
FORTISAI_PROXY_OPENAI_API_KEY="${FORTISAI_PROXY_OPENAI_API_KEY:-local-llama}"
FORTISAI_PROXY_OPENAI_MODEL="${FORTISAI_PROXY_OPENAI_MODEL:-fortisai}"
OPENCLAW_CONTAINER_NAME="${OPENCLAW_CONTAINER_NAME:-fortisai-claw-gateway}"
OPENCLAW_IMAGE="${OPENCLAW_IMAGE:-docker.io/library/node:24-bookworm}"
OPENCLAW_GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18789}"
OPENCLAW_BRIDGE_PORT="${OPENCLAW_BRIDGE_PORT:-18790}"
OPENCLAW_GATEWAY_BIND="${OPENCLAW_GATEWAY_BIND:-0.0.0.0}"
OPENCLAW_GATEWAY_TOKEN="${OPENCLAW_GATEWAY_TOKEN:-fortisai-claw-gateway-dev-token}"
OPENCLAW_GATEWAY_PASSWORD="${OPENCLAW_GATEWAY_PASSWORD:-}"
OPENCLAW_LMSTUDIO_BASE_URL="${OPENCLAW_LMSTUDIO_BASE_URL:-$FORTISAI_PROXY_OPENAI_BASE_URL}"
OPENCLAW_LMSTUDIO_MODEL="${OPENCLAW_LMSTUDIO_MODEL:-$FORTISAI_PROXY_OPENAI_MODEL}"
OPENCLAW_OPENAI_API_KEY="${OPENCLAW_OPENAI_API_KEY:-$FORTISAI_PROXY_OPENAI_API_KEY}"
OPENCLAW_HONCHO_PLUGIN_PACKAGE="${OPENCLAW_HONCHO_PLUGIN_PACKAGE:-@honcho-ai/openclaw-honcho}"
OPENCLAW_HONCHO_BASE_URL="${OPENCLAW_HONCHO_BASE_URL:-http://$HONCHO_API_CONTAINER_NAME:8000}"
OPENCLAW_HONCHO_WORKSPACE_ID="${OPENCLAW_HONCHO_WORKSPACE_ID:-openclaw}"
OPENCLAW_HONCHO_API_KEY="${OPENCLAW_HONCHO_API_KEY:-}"
HERMES_CONTAINER_NAME="${HERMES_CONTAINER_NAME:-fortisai-hermes}"
HERMES_IMAGE="${HERMES_IMAGE:-nousresearch/hermes-agent:latest}"
HERMES_GATEWAY_PORT="${HERMES_GATEWAY_PORT:-8642}"
HERMES_DASHBOARD_PORT="${HERMES_DASHBOARD_PORT:-9119}"
HERMES_DASHBOARD="${HERMES_DASHBOARD:-1}"
HERMES_API_SERVER_ENABLED="${HERMES_API_SERVER_ENABLED:-true}"
HERMES_API_SERVER_HOST="${HERMES_API_SERVER_HOST:-0.0.0.0}"
HERMES_API_SERVER_KEY="${HERMES_API_SERVER_KEY:-fortisai-hermes-dev-api-key}"
HERMES_API_SERVER_CORS_ORIGINS="${HERMES_API_SERVER_CORS_ORIGINS:-*}"
HERMES_HONCHO_BASE_URL="${HERMES_HONCHO_BASE_URL:-http://$HONCHO_API_CONTAINER_NAME:8000}"
HERMES_HONCHO_WORKSPACE_ID="${HERMES_HONCHO_WORKSPACE_ID:-hermes}"
HERMES_HONCHO_API_KEY="${HERMES_HONCHO_API_KEY:-}"
HERMES_DAYTONA_DASHBOARD_URL="${HERMES_DAYTONA_DASHBOARD_URL:-$DAYTONA_URL}"
HERMES_DAYTONA_API_URL="${HERMES_DAYTONA_API_URL:-http://host.docker.internal:${DAYTONA_API_HOST_PORT:-3300}}"
HERMES_OPENAI_BASE_URL="${HERMES_OPENAI_BASE_URL:-$FORTISAI_PROXY_OPENAI_BASE_URL}"
HERMES_OPENAI_API_KEY="${HERMES_OPENAI_API_KEY:-$FORTISAI_PROXY_OPENAI_API_KEY}"
HERMES_OPENAI_MODEL="${HERMES_OPENAI_MODEL:-$FORTISAI_PROXY_OPENAI_MODEL}"
HERMES_WHATSAPP_ENABLED="${HERMES_WHATSAPP_ENABLED:-false}"
FIRECRAWL_CONTAINER_NAME="${FIRECRAWL_CONTAINER_NAME:-fortisai-firecrawl}"
FIRECRAWL_IMAGE="${FIRECRAWL_IMAGE:-ghcr.io/firecrawl/firecrawl:latest}"
FIRECRAWL_HOST_PORT="${FIRECRAWL_HOST_PORT:-3002}"
FIRECRAWL_API_KEY="${FIRECRAWL_API_KEY:-fortisai-firecrawl-dev-api-key}"
FIRECRAWL_INTERNAL_URL="${FIRECRAWL_INTERNAL_URL:-http://$FIRECRAWL_CONTAINER_NAME:3002}"
FIRECRAWL_DB_NAME="${FIRECRAWL_DB_NAME:-firecrawl}"
FIRECRAWL_DB_USER="${FIRECRAWL_DB_USER:-$PGVECTOR_USER}"
FIRECRAWL_DB_PASSWORD="${FIRECRAWL_DB_PASSWORD:-$PGVECTOR_PASSWORD}"
FIRECRAWL_DATABASE_URL="${FIRECRAWL_DATABASE_URL:-postgresql://$FIRECRAWL_DB_USER:$FIRECRAWL_DB_PASSWORD@$PGVECTOR_CONTAINER_NAME:5432/$FIRECRAWL_DB_NAME}"
FIRECRAWL_RABBITMQ_USER="${FIRECRAWL_RABBITMQ_USER:-$RABBITMQ_DEFAULT_USER}"
FIRECRAWL_RABBITMQ_PASSWORD="${FIRECRAWL_RABBITMQ_PASSWORD:-$RABBITMQ_DEFAULT_PASSWORD}"
FIRECRAWL_RABBITMQ_URL="${FIRECRAWL_RABBITMQ_URL:-amqp://$FIRECRAWL_RABBITMQ_USER:$FIRECRAWL_RABBITMQ_PASSWORD@$RABBITMQ_CONTAINER_NAME:5672}"
FIRECRAWL_REDIS_URL="${FIRECRAWL_REDIS_URL:-redis://$REDIS_CONTAINER_NAME:6379}"
FIRECRAWL_REDIS_EVICT_URL="${FIRECRAWL_REDIS_EVICT_URL:-$FIRECRAWL_REDIS_URL}"
FIRECRAWL_REDIS_RATE_LIMIT_URL="${FIRECRAWL_REDIS_RATE_LIMIT_URL:-$FIRECRAWL_REDIS_URL}"
FIRECRAWL_NUQ_SQL_URL="${FIRECRAWL_NUQ_SQL_URL:-https://raw.githubusercontent.com/firecrawl/firecrawl/main/apps/nuq-postgres/nuq.sql}"
TRAEFIK_CONTAINER_NAME="${TRAEFIK_CONTAINER_NAME:-fortisai-traefik}"
TRAEFIK_IMAGE="${TRAEFIK_IMAGE:-docker.io/library/traefik:latest}"
TRAEFIK_WEB_HOST_PORT="${TRAEFIK_WEB_HOST_PORT:-18000}"
TRAEFIK_DASHBOARD_HOST_PORT="${TRAEFIK_DASHBOARD_HOST_PORT:-18088}"
TRAEFIK_DASHBOARD_USER="${TRAEFIK_DASHBOARD_USER:-fortisai}"
TRAEFIK_DASHBOARD_PASSWORD="${TRAEFIK_DASHBOARD_PASSWORD:-}"
CODEINDEXER_REPO_URL="${CODEINDEXER_REPO_URL:-https://github.com/Indiejayk8s/CodeIndexer.git}"
CODEINDEXER_BRIDGE_CONTAINER_NAME="${CODEINDEXER_BRIDGE_CONTAINER_NAME:-fortisai-mcp-openapi-codeindexer}"
CODEINDEXER_BRIDGE_HOST_PORT="${CODEINDEXER_BRIDGE_HOST_PORT:-8096}"
CODEINDEXER_OPENAI_BASE_URL="${CODEINDEXER_OPENAI_BASE_URL:-http://fortisai-mcp-openapi-dify:8093/v1}"
CODEINDEXER_OPENAI_API_KEY="${CODEINDEXER_OPENAI_API_KEY:-local-llama}"
CODEINDEXER_OPENAI_EMBEDDING_MODEL="${CODEINDEXER_OPENAI_EMBEDDING_MODEL:-fortisai}"
CODEINDEXER_OPENAI_EMBEDDING_DIMENSION="${CODEINDEXER_OPENAI_EMBEDDING_DIMENSION:-1536}"
CODEINDEXER_MILVUS_ADDRESS="${CODEINDEXER_MILVUS_ADDRESS:-fortisai-milvus:19530}"
CODEINDEXER_MILVUS_TOKEN="${CODEINDEXER_MILVUS_TOKEN:-}"
CODEINDEXER_MCP_TIMEOUT_MS="${CODEINDEXER_MCP_TIMEOUT_MS:-900000}"
MILVUS_ETCD_CONTAINER_NAME="${MILVUS_ETCD_CONTAINER_NAME:-fortisai-milvus-etcd}"
MILVUS_MINIO_CONTAINER_NAME="${MILVUS_MINIO_CONTAINER_NAME:-fortisai-milvus-minio}"
MILVUS_CONTAINER_NAME="${MILVUS_CONTAINER_NAME:-fortisai-milvus}"
MILVUS_IMAGE="${MILVUS_IMAGE:-docker.io/milvusdb/milvus:v2.4.15}"
MILVUS_ETCD_IMAGE="${MILVUS_ETCD_IMAGE:-quay.io/coreos/etcd:v3.5.18}"
MILVUS_MINIO_IMAGE="${MILVUS_MINIO_IMAGE:-docker.io/minio/minio:latest}"
MILVUS_HOST_PORT="${MILVUS_HOST_PORT:-19530}"
MILVUS_HEALTH_HOST_PORT="${MILVUS_HEALTH_HOST_PORT:-19091}"
MILVUS_MINIO_ROOT_USER="${MILVUS_MINIO_ROOT_USER:-minioadmin}"
MILVUS_MINIO_ROOT_PASSWORD="${MILVUS_MINIO_ROOT_PASSWORD:-minioadmin}"
OPENMETADATA_CONTAINER_NAME="${OPENMETADATA_CONTAINER_NAME:-fortisai-openmetadata}"
OPENMETADATA_IMAGE="${OPENMETADATA_IMAGE:-docker.io/openmetadata/server:1.12.6}"
OPENMETADATA_HOST_PORT="${OPENMETADATA_HOST_PORT:-18585}"
OPENMETADATA_ADMIN_HOST_PORT="${OPENMETADATA_ADMIN_HOST_PORT:-18586}"
OPENMETADATA_DB_NAME="${OPENMETADATA_DB_NAME:-openmetadata_db}"
OPENMETADATA_FERNET_KEY="${OPENMETADATA_FERNET_KEY:-}"
OPENMETADATA_JWT_KEY_ID="${OPENMETADATA_JWT_KEY_ID:-fortisai-local-dev}"
OPENMETADATA_HEAP_OPTS="${OPENMETADATA_HEAP_OPTS:--Xmx1G -Xms1G}"
OPENSEARCH_CONTAINER_NAME="${OPENSEARCH_CONTAINER_NAME:-fortisai-opensearch}"
OPENSEARCH_IMAGE="${OPENSEARCH_IMAGE:-docker.io/opensearchproject/opensearch:2}"
OPENSEARCH_HOST_PORT="${OPENSEARCH_HOST_PORT:-9200}"
OPENSEARCH_PERFORMANCE_HOST_PORT="${OPENSEARCH_PERFORMANCE_HOST_PORT:-9600}"
OPENSEARCH_JAVA_OPTS="${OPENSEARCH_JAVA_OPTS:--Xms512m -Xmx512m}"
OPENWEBUI_LLM_BACKEND="${OPENWEBUI_LLM_BACKEND:-hermes}"
OPENWEBUI_AIOHTTP_CLIENT_TIMEOUT="${OPENWEBUI_AIOHTTP_CLIENT_TIMEOUT-}"
SQLCL_MCP_PYTHON_CMD="${SQLCL_MCP_PYTHON_CMD:-python3}"
APEX_DOWNLOAD_URL="${APEX_DOWNLOAD_URL:-https://download.oracle.com/otn_software/apex/apex-latest.zip}"
APEX_WORK_DIR="${APEX_WORK_DIR:-$ORACLE_DB_DIR/apex}"
APEX_ADMIN_PASSWORD="${APEX_ADMIN_PASSWORD:-$ORACLE_DB_PASSWORD}"
OCR_REGISTRY="${OCR_REGISTRY:-container-registry.oracle.com}"
OCR_USERNAME="${OCR_USERNAME:-}"
OCR_AUTH_TOKEN="${OCR_AUTH_TOKEN:-}"
ORACLE_WALLET_DIR="${ORACLE_WALLET_DIR:-$BASE_DIR/oracle-wallet}"
ORACLE_WALLET_ENV_FILE="${ORACLE_WALLET_ENV_FILE:-$ORACLE_WALLET_DIR/wallet-env.sh}"
ORACLE_WALLET_SETUP_FILE="${ORACLE_WALLET_SETUP_FILE:-$ORACLE_WALLET_DIR/wallet-setup.sh}"
ORACLE_WALLET_CREDENTIALS_HELP_FILE="${ORACLE_WALLET_CREDENTIALS_HELP_FILE:-$ORACLE_WALLET_DIR/oracle-wallet-credentials.sh}"
ORACLE_DB_WALLET_ENV_FILE="${ORACLE_DB_WALLET_ENV_FILE:-$ORACLE_WALLET_DIR/oracle-db.env}"
ORACLE_DB_WALLET_SCRIPT_FILE="${ORACLE_DB_WALLET_SCRIPT_FILE:-$ORACLE_WALLET_DIR/oracle-db-info.sh}"
SQLCL_MCP_SERVER_FILE="${SQLCL_MCP_SERVER_FILE:-$MCP_ROOT_DIR/sqlcl-mcp/sqlcl-mcp-server.py}"
MCP_SQLCL_OPENAPI_URL="${MCP_SQLCL_OPENAPI_URL:-http://127.0.0.1:8091/openapi.json}"
MCP_N8N_OPENAPI_URL="${MCP_N8N_OPENAPI_URL:-http://127.0.0.1:8092/openapi.json}"
MCP_DIFY_OPENAPI_URL="${MCP_DIFY_OPENAPI_URL:-http://127.0.0.1:8093/openapi.json}"
MCP_DEBUG_OPENAPI_URL="${MCP_DEBUG_OPENAPI_URL:-http://127.0.0.1:8094/openapi.json}"
MCP_PROXMOX_OPENAPI_URL="${MCP_PROXMOX_OPENAPI_URL:-http://127.0.0.1:8095/openapi.json}"
MCP_CODEINDEXER_OPENAPI_URL="${MCP_CODEINDEXER_OPENAPI_URL:-http://127.0.0.1:8096/openapi.json}"
PROXMOX_BRIDGE_ENABLED="${PROXMOX_BRIDGE_ENABLED:-auto}"
PROXMOX_HOST="${PROXMOX_HOST:-}"
PROXMOX_PORT="${PROXMOX_PORT:-}"
PROXMOX_USER="${PROXMOX_USER:-}"
PROXMOX_TOKEN_NAME="${PROXMOX_TOKEN_NAME:-}"
PROXMOX_TOKEN_VALUE="${PROXMOX_TOKEN_VALUE:-}"
PROXMOX_VERIFY_SSL="${PROXMOX_VERIFY_SSL:-}"
PROXMOX_DEV_MODE="${PROXMOX_DEV_MODE:-}"
PROXMOX_SERVICE="${PROXMOX_SERVICE:-}"
PROXMOX_API_KEY="${PROXMOX_API_KEY:-fortisai-proxmox-openapi-dev-key}"
PROXMOX_API_STRICT_AUTH="${PROXMOX_API_STRICT_AUTH:-false}"

DAYTONA_API_HOST_PORT="${DAYTONA_API_HOST_PORT:-3300}"
DAYTONA_PROXY_HOST_PORT="${DAYTONA_PROXY_HOST_PORT:-4400}"
DAYTONA_SSH_HOST_PORT="${DAYTONA_SSH_HOST_PORT:-2223}"
DAYTONA_DEX_HOST_PORT="${DAYTONA_DEX_HOST_PORT:-5556}"
DAYTONA_PGADMIN_HOST_PORT="${DAYTONA_PGADMIN_HOST_PORT:-55050}"
DAYTONA_REGISTRY_UI_HOST_PORT="${DAYTONA_REGISTRY_UI_HOST_PORT:-55100}"
DAYTONA_REGISTRY_HOST_PORT="${DAYTONA_REGISTRY_HOST_PORT:-56000}"
DAYTONA_MAILDEV_HOST_PORT="${DAYTONA_MAILDEV_HOST_PORT:-11080}"
DAYTONA_MINIO_CONSOLE_HOST_PORT="${DAYTONA_MINIO_CONSOLE_HOST_PORT:-59001}"
DAYTONA_JAEGER_HOST_PORT="${DAYTONA_JAEGER_HOST_PORT:-16687}"

PODMAN_CPUS="${PODMAN_CPUS:-6}"
PODMAN_MEMORY_MB="${PODMAN_MEMORY_MB:-12288}"
PODMAN_DISK_GB="${PODMAN_DISK_GB:-80}"

SCRIPT_NAME="$(basename "$0")"

log() {
  printf '%s\n' "[fortisai-dev] $*"
}

err() {
  printf '%s\n' "[fortisai-dev] ERROR: $*" >&2
}

upsert_env_var() {
  local file="$1"
  local key="$2"
  local value="$3"

  if grep -q "^${key}=" "$file"; then
    awk -v key="$key" -v value="$value" '
      BEGIN {updated=0}
      $0 ~ "^" key "=" {print key "=" value; updated=1; next}
      {print}
      END {if (updated==0) print key "=" value}
    ' "$file" > "$file.tmp"
    mv "$file.tmp" "$file"
  else
    printf '%s=%s\n' "$key" "$value" >> "$file"
  fi
}

remove_env_var() {
  local file="$1"
  local key="$2"
  if [[ -f "$file" ]]; then
    awk -v key="$key" -F= '$1 != key { print }' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  fi
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    err "Missing required command: $cmd"
    exit 1
  fi
}

load_prod_env() {
  if [[ -f "$PROD_ENV_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$PROD_ENV_FILE"
  fi
}

env_var_exported() {
  local name="$1"
  local decl
  decl="$(declare -p "$name" 2>/dev/null || true)"
  [[ "$decl" == declare\ -x* ]]
}

set_runtime_var() {
  local name="$1"
  local value="$2"
  printf -v "$name" '%s' "$value"
  export "$name"
}

random_urlsafe_secret() {
  local bytes="${1:-32}"
  python3 - "$bytes" <<'PY'
import base64
import os
import sys

count = int(sys.argv[1])
print(base64.urlsafe_b64encode(os.urandom(count)).decode("ascii").rstrip("="))
PY
}

env_file_value() {
  local file="$1"
  local key="$2"

  [[ -f "$file" ]] || return 1
  awk -v key="$key" '
    BEGIN { FS = "=" }
    $1 == key {
      sub(/^[^=]*=/, "")
      print
      found = 1
      exit
    }
    END { if (!found) exit 1 }
  ' "$file"
}

oracle_db_wallet_value() {
  env_file_value "$ORACLE_DB_WALLET_ENV_FILE" "$1"
}

vault_root_token() {
  if [[ ! -f "$VAULT_KEYS_FILE" ]]; then
    return 1
  fi

  VAULT_KEYS_FILE="$VAULT_KEYS_FILE" python3 - <<'PY'
import json
import os
from pathlib import Path

payload = json.loads(Path(os.environ["VAULT_KEYS_FILE"]).read_text())
print(str(payload.get("root_token", "")).strip())
PY
}

vault_cli() {
  local root_token
  root_token="$(vault_root_token)" || return 1
  if [[ -z "$root_token" ]]; then
    return 1
  fi

  podman exec \
    -e VAULT_ADDR=http://127.0.0.1:8200 \
    -e VAULT_TOKEN="$root_token" \
    "$VAULT_CONTAINER_NAME" vault "$@"
}

vault_token_valid() {
  local token="$1"
  [[ -n "$token" ]] || return 1

  podman exec \
    -e VAULT_ADDR=http://127.0.0.1:8200 \
    -e VAULT_TOKEN="$token" \
    "$VAULT_CONTAINER_NAME" vault token lookup >/dev/null 2>&1
}

vault_kv_ready() {
  if vault_cli secrets list -format=json 2>/dev/null | grep -q '"secret/"'; then
    return 0
  fi
  vault_cli secrets enable -path=secret kv-v2 >/dev/null 2>&1 || true
}

vault_get_secret_value() {
  local path="$1"
  vault_cli kv get -field=value "secret/fortisai/dev/$path" 2>/dev/null || true
}

vault_put_secret_value() {
  local path="$1"
  local value="$2"

  [[ -n "$value" ]] || return 0
  vault_cli kv put "secret/fortisai/dev/$path" value="$value" >/dev/null
}

vault_delete_secret_value() {
  local path="$1"

  vault_cli kv metadata delete "secret/fortisai/dev/$path" >/dev/null
}

vault_normalize_secret_path() {
  local path="${1:-}"
  path="${path#/}"
  path="${path#secret/data/fortisai/dev/}"
  path="${path#secret/fortisai/dev/}"
  path="${path#fortisai/dev/}"

  if [[ -z "$path" || "$path" == *".."* || "$path" == /* ]]; then
    err "Invalid Vault path. Use a path under secret/fortisai/dev, for example: hermes/api_server_key"
    return 1
  fi

  printf '%s' "$path"
}

vault_prepare_operator_access() {
  require_cmd python3
  if ! container_running "$VAULT_CONTAINER_NAME"; then
    vault_up
  fi

  wait_for_vault

  if ! vault_initialized; then
    err "Vault is not initialized. Run: $SCRIPT_NAME vault-init"
    return 1
  fi

  if vault_sealed; then
    vault_unseal
  fi

  vault_kv_ready
}

vault_read() {
  local raw_path="${1:-}"
  local path value

  if [[ -z "$raw_path" ]]; then
    err "Missing Vault path. Usage: $SCRIPT_NAME vault-read <path>"
    return 1
  fi

  path="$(vault_normalize_secret_path "$raw_path")" || return 1
  vault_prepare_operator_access
  value="$(vault_get_secret_value "$path")"

  if [[ -z "$value" ]]; then
    err "Vault secret not found or empty: secret/fortisai/dev/$path"
    return 1
  fi

  printf '%s\n' "$value"
}

vault_write() {
  local raw_path="${1:-}"
  local value="${2:-}"
  local path

  if [[ -z "$raw_path" ]]; then
    err "Missing Vault path. Usage: $SCRIPT_NAME vault-write <path> <value>"
    return 1
  fi

  if [[ -z "$value" ]] && [[ ! -t 0 ]]; then
    value="$(cat)"
    value="${value%$'\n'}"
  fi

  if [[ -z "$value" ]]; then
    err "Missing Vault value. Pass it as the second argument or pipe it on stdin."
    return 1
  fi

  path="$(vault_normalize_secret_path "$raw_path")" || return 1
  vault_prepare_operator_access
  vault_put_secret_value "$path" "$value"
  log "Wrote Vault secret: secret/fortisai/dev/$path"
}

vault_del() {
  local raw_path="${1:-}"
  local path

  if [[ -z "$raw_path" ]]; then
    err "Missing Vault path. Usage: $SCRIPT_NAME vault-del <path>"
    return 1
  fi

  path="$(vault_normalize_secret_path "$raw_path")" || return 1
  vault_prepare_operator_access
  vault_delete_secret_value "$path"
  log "Deleted Vault secret metadata and all versions: secret/fortisai/dev/$path"
}

vault_resolve_runtime_secret() {
  local env_name="$1"
  local vault_path="$2"
  local current_value="${!env_name:-}"
  local vault_value=""

  if env_var_exported "$env_name" && [[ -n "$current_value" ]]; then
    vault_put_secret_value "$vault_path" "$current_value"
    return 0
  fi

  vault_value="$(vault_get_secret_value "$vault_path")"
  if [[ -n "$vault_value" ]]; then
    set_runtime_var "$env_name" "$vault_value"
    return 0
  fi

  if [[ -n "$current_value" ]]; then
    vault_put_secret_value "$vault_path" "$current_value"
  fi
}

openwebui_user_secret_segment() {
  local value="${1:-}"
  VALUE="$value" python3 - <<'PY'
import os
import re

value = os.environ.get("VALUE", "").strip().lower()
print(re.sub(r"[^a-z0-9]+", "_", value).strip("_"), end="")
PY
}

vault_ensure_service_token() {
  if env_var_exported VAULT_TOKEN && [[ -n "$VAULT_TOKEN" ]]; then
    return 0
  fi

  local existing_token
  existing_token="$(vault_get_secret_value "vault/service_token")"
  if vault_token_valid "$existing_token"; then
    set_runtime_var VAULT_TOKEN "$existing_token"
    return 0
  fi

  local root_token token_json service_token
  root_token="$(vault_root_token)" || return 1

  podman exec -i \
    -e VAULT_ADDR=http://127.0.0.1:8200 \
    -e VAULT_TOKEN="$root_token" \
    "$VAULT_CONTAINER_NAME" vault policy write fortisai-dev-read - >/dev/null <<'HCL'
path "secret/data/fortisai/dev/*" {
  capabilities = ["read"]
}

path "secret/metadata/fortisai/dev/*" {
  capabilities = ["list", "read"]
}
HCL

  token_json="$(vault_cli token create -policy=fortisai-dev-read -ttl=720h -renewable=true -format=json)"
  service_token="$(TOKEN_JSON="$token_json" python3 - <<'PY'
import json
import os
import sys

payload = json.loads(os.environ["TOKEN_JSON"])
print(payload.get("auth", {}).get("client_token", ""))
PY
)"

  if [[ -z "$service_token" ]]; then
    err "Could not create Vault service token for local components"
    return 1
  fi

  set_runtime_var VAULT_TOKEN "$service_token"
  vault_put_secret_value "vault/service_token" "$service_token"
}

vault_require_secret_value() {
  local path="$1"

  if [[ -z "$(vault_get_secret_value "$path")" ]]; then
    err "Vault secret missing after sync: secret/fortisai/dev/$path"
    return 1
  fi
}

vault_ensure_runtime_secret_value() {
  local env_name="$1"
  local path="$2"
  local current_value="${!env_name:-}"

  if [[ -z "$(vault_get_secret_value "$path")" ]] && [[ -n "$current_value" ]]; then
    vault_put_secret_value "$path" "$current_value"
  fi
  vault_require_secret_value "$path"
}

vault_verify_runtime_secrets() {
  vault_ensure_runtime_secret_value "N8N_BASIC_AUTH_PASSWORD" "n8n/basic_auth_password"
  vault_ensure_runtime_secret_value "ORACLE_DB_PASSWORD" "oracle/db_password"
  vault_ensure_runtime_secret_value "RABBITMQ_DEFAULT_PASSWORD" "rabbitmq/default_password"
  vault_ensure_runtime_secret_value "PGVECTOR_PASSWORD" "pgvector/password"
  vault_ensure_runtime_secret_value "ORDS_DB_PASSWORD" "oracle/ords_db_password"
  vault_ensure_runtime_secret_value "APEX_ADMIN_PASSWORD" "oracle/apex_admin_password"
  vault_ensure_runtime_secret_value "QDRANT_API_KEY" "qdrant/api_key"
  vault_ensure_runtime_secret_value "OPENVSCODE_CONNECTION_TOKEN" "openvscode/connection_token"
  vault_ensure_runtime_secret_value "APPSMITH_BETTERBUGS_API_KEY" "appsmith/betterbugs_api_key"
  vault_ensure_runtime_secret_value "HONCHO_LLM_OPENAI_API_KEY" "honcho/llm_openai_api_key"
  vault_ensure_runtime_secret_value "OPENCLAW_GATEWAY_TOKEN" "claw-gateway/gateway_token"
  vault_ensure_runtime_secret_value "OPENCLAW_OPENAI_API_KEY" "claw-gateway/openai_api_key"
  vault_ensure_runtime_secret_value "HERMES_API_SERVER_KEY" "hermes/api_server_key"
  vault_ensure_runtime_secret_value "FIRECRAWL_API_KEY" "firecrawl/api_key"
  vault_ensure_runtime_secret_value "TRAEFIK_DASHBOARD_PASSWORD" "traefik/dashboard_password"
  vault_ensure_runtime_secret_value "CODEINDEXER_OPENAI_API_KEY" "codeindexer/openai_api_key"
  vault_ensure_runtime_secret_value "MILVUS_MINIO_ROOT_PASSWORD" "milvus/minio_root_password"
  vault_ensure_runtime_secret_value "OPENMETADATA_FERNET_KEY" "openmetadata/fernet_key"
  vault_ensure_runtime_secret_value "APP_API_KEY" "dify/app_api_key"
  vault_ensure_runtime_secret_value "KNOWLEDGE_API_KEY" "dify/knowledge_api_key"
  vault_ensure_runtime_secret_value "DIFY_API_KEY" "dify/api_key"
  vault_require_secret_value "vault/service_token"
}

normalize_runtime_secret_defaults() {
  : "${N8N_BASIC_AUTH_PASSWORD:=change-me-n8n}"
  : "${ORACLE_DB_PASSWORD:=FortisAI26ai!2026}"
  : "${RABBITMQ_DEFAULT_PASSWORD:=fortisai}"
  : "${PGVECTOR_PASSWORD:=fortisai}"
  : "${QDRANT_API_KEY:=difyai123456}"
  : "${OPENVSCODE_CONNECTION_TOKEN:=fortisai-openvscode-dev-token}"
  : "${APPSMITH_BETTERBUGS_API_KEY:=disabled}"
  : "${HONCHO_LLM_OPENAI_API_KEY:=lmstudio}"
  : "${OPENCLAW_GATEWAY_TOKEN:=fortisai-claw-gateway-dev-token}"
  : "${OPENCLAW_OPENAI_API_KEY:=lmstudio}"
  : "${HERMES_API_SERVER_KEY:=fortisai-hermes-dev-api-key}"
  : "${FIRECRAWL_API_KEY:=fortisai-firecrawl-dev-api-key}"
  : "${CODEINDEXER_OPENAI_API_KEY:=local-llama}"
  : "${MILVUS_MINIO_ROOT_PASSWORD:=minioadmin}"
  if [[ -z "${TRAEFIK_DASHBOARD_PASSWORD:-}" ]]; then
    TRAEFIK_DASHBOARD_PASSWORD="$(random_urlsafe_secret 24)"
  fi
  if [[ -z "${OPENMETADATA_FERNET_KEY:-}" ]]; then
    OPENMETADATA_FERNET_KEY="$(random_urlsafe_secret 32)"
  fi
}

refresh_derived_secret_values() {
  if ! env_var_exported ORDS_DB_PASSWORD; then
    ORDS_DB_PASSWORD="$ORACLE_DB_PASSWORD"
  fi
  if ! env_var_exported APEX_ADMIN_PASSWORD; then
    APEX_ADMIN_PASSWORD="$ORACLE_DB_PASSWORD"
  fi
  if ! env_var_exported FIRECRAWL_DB_PASSWORD; then
    FIRECRAWL_DB_PASSWORD="$PGVECTOR_PASSWORD"
  fi
  if ! env_var_exported FIRECRAWL_RABBITMQ_PASSWORD; then
    FIRECRAWL_RABBITMQ_PASSWORD="$RABBITMQ_DEFAULT_PASSWORD"
  fi
  if ! env_var_exported RABBITMQ_URL; then
    RABBITMQ_URL="amqp://$RABBITMQ_DEFAULT_USER:$RABBITMQ_DEFAULT_PASSWORD@127.0.0.1:5672"
  fi
  if ! env_var_exported PGVECTOR_URL; then
    PGVECTOR_URL="postgresql://$PGVECTOR_USER:$PGVECTOR_PASSWORD@127.0.0.1:5432/$PGVECTOR_DB"
  fi
  if ! env_var_exported APPSMITH_POSTGRES_DB_URL; then
    APPSMITH_POSTGRES_DB_URL="postgresql://$PGVECTOR_USER:$PGVECTOR_PASSWORD@$PGVECTOR_CONTAINER_NAME:5432/$PGVECTOR_DB"
  fi
  if ! env_var_exported FIRECRAWL_DATABASE_URL; then
    FIRECRAWL_DATABASE_URL="postgresql://$FIRECRAWL_DB_USER:$FIRECRAWL_DB_PASSWORD@$PGVECTOR_CONTAINER_NAME:5432/$FIRECRAWL_DB_NAME"
  fi
  if ! env_var_exported FIRECRAWL_RABBITMQ_URL; then
    FIRECRAWL_RABBITMQ_URL="amqp://$FIRECRAWL_RABBITMQ_USER:$FIRECRAWL_RABBITMQ_PASSWORD@$RABBITMQ_CONTAINER_NAME:5672"
  fi
  if ! env_var_exported CODEINDEXER_OPENAI_BASE_URL; then
    CODEINDEXER_OPENAI_BASE_URL="http://fortisai-mcp-openapi-dify:8093/v1"
  fi
  if ! env_var_exported CODEINDEXER_MILVUS_ADDRESS; then
    CODEINDEXER_MILVUS_ADDRESS="$MILVUS_CONTAINER_NAME:19530"
  fi
}

vault_sync_runtime_secrets() {
  local openwebui_user_segment

  require_cmd python3

  vault_kv_ready
  normalize_runtime_secret_defaults
  load_proxmox_config_from_json

  vault_resolve_runtime_secret "N8N_BASIC_AUTH_PASSWORD" "n8n/basic_auth_password"
  vault_resolve_runtime_secret "ORACLE_DB_PASSWORD" "oracle/db_password"
  vault_resolve_runtime_secret "RABBITMQ_DEFAULT_PASSWORD" "rabbitmq/default_password"
  vault_resolve_runtime_secret "PGVECTOR_PASSWORD" "pgvector/password"
  refresh_derived_secret_values

  vault_resolve_runtime_secret "ORDS_DB_PASSWORD" "oracle/ords_db_password"
  vault_resolve_runtime_secret "APEX_ADMIN_PASSWORD" "oracle/apex_admin_password"
  vault_resolve_runtime_secret "QDRANT_API_KEY" "qdrant/api_key"
  vault_resolve_runtime_secret "OPENVSCODE_CONNECTION_TOKEN" "openvscode/connection_token"
  vault_resolve_runtime_secret "APPSMITH_BETTERBUGS_API_KEY" "appsmith/betterbugs_api_key"
  vault_resolve_runtime_secret "HONCHO_LLM_OPENAI_API_KEY" "honcho/llm_openai_api_key"
  vault_resolve_runtime_secret "N8N_API_KEY" "n8n/api_key"
  openwebui_user_segment="$(openwebui_user_secret_segment "$OPENWEBUI_API_USER")"
  if [[ -n "$openwebui_user_segment" ]]; then
    vault_resolve_runtime_secret "OPENWEBUI_BEARER_TOKEN" "openwebui/users/$openwebui_user_segment/api_key"
  fi
  vault_resolve_runtime_secret "OCR_AUTH_TOKEN" "oracle/ocr_auth_token"
  vault_resolve_runtime_secret "DAYTONA_API_KEY" "daytona/api_key"
  vault_resolve_runtime_secret "OPENCLAW_GATEWAY_TOKEN" "claw-gateway/gateway_token"
  vault_resolve_runtime_secret "OPENCLAW_GATEWAY_PASSWORD" "claw-gateway/gateway_password"
  vault_resolve_runtime_secret "OPENCLAW_OPENAI_API_KEY" "claw-gateway/openai_api_key"
  vault_resolve_runtime_secret "OPENCLAW_HONCHO_API_KEY" "claw-gateway/honcho_api_key"
  vault_resolve_runtime_secret "HERMES_API_SERVER_KEY" "hermes/api_server_key"
  vault_resolve_runtime_secret "HERMES_HONCHO_API_KEY" "hermes/honcho_api_key"
  vault_resolve_runtime_secret "FIRECRAWL_API_KEY" "firecrawl/api_key"
  vault_resolve_runtime_secret "TRAEFIK_DASHBOARD_PASSWORD" "traefik/dashboard_password"
  vault_resolve_runtime_secret "CODEINDEXER_OPENAI_API_KEY" "codeindexer/openai_api_key"
  vault_resolve_runtime_secret "CODEINDEXER_MILVUS_TOKEN" "codeindexer/milvus_token"
  vault_resolve_runtime_secret "MILVUS_MINIO_ROOT_PASSWORD" "milvus/minio_root_password"
  vault_resolve_runtime_secret "OPENMETADATA_FERNET_KEY" "openmetadata/fernet_key"
  vault_resolve_runtime_secret "PROXMOX_HOST" "proxmox/host"
  vault_resolve_runtime_secret "PROXMOX_PORT" "proxmox/port"
  vault_resolve_runtime_secret "PROXMOX_USER" "proxmox/user"
  vault_resolve_runtime_secret "PROXMOX_TOKEN_NAME" "proxmox/token_name"
  vault_resolve_runtime_secret "PROXMOX_TOKEN_VALUE" "proxmox/token_value"
  vault_resolve_runtime_secret "PROXMOX_VERIFY_SSL" "proxmox/verify_ssl"
  vault_resolve_runtime_secret "PROXMOX_DEV_MODE" "proxmox/dev_mode"
  vault_resolve_runtime_secret "PROXMOX_SERVICE" "proxmox/service"
  vault_resolve_runtime_secret "PROXMOX_API_KEY" "proxmox/openapi_api_key"
  vault_resolve_runtime_secret "PROXMOX_API_STRICT_AUTH" "proxmox/openapi_strict_auth"
  vault_resolve_runtime_secret "LOG_LEVEL" "proxmox/log_level"

  load_dify_keys_from_json
  vault_resolve_runtime_secret "APP_API_KEY" "dify/app_api_key"
  vault_resolve_runtime_secret "KNOWLEDGE_API_KEY" "dify/knowledge_api_key"
  vault_resolve_runtime_secret "DIFY_API_KEY" "dify/api_key"
  vault_resolve_runtime_secret "DIFY_ADMIN_API_KEY" "dify/admin_api_key"
  vault_resolve_runtime_secret "DIFY_CONSOLE_ACCESS_TOKEN" "dify/console_access_token"
  set_runtime_var ADMIN_API_KEY "$DIFY_API_KEY"
  set_runtime_var ADMIN_API_KEY_ENABLE "true"
  load_dify_keys_from_json

  refresh_derived_secret_values
  vault_ensure_service_token
  vault_verify_runtime_secrets
  log "Vault-backed runtime secrets are ready"
}

prepare_vault_runtime_secrets() {
  ensure_machine
  ensure_shared_network
  write_vault_compose
  vault_up
  vault_unseal
  vault_sync_runtime_secrets
}

load_vault_runtime_secrets_if_available() {
  if [[ -f "$VAULT_KEYS_FILE" ]] && container_running "$VAULT_CONTAINER_NAME" && vault_initialized && ! vault_sealed; then
    vault_sync_runtime_secrets || log "Vault-backed runtime secret load skipped"
  fi
}

resolve_dify_runtime_api_key() {
  local api_running pg_running db_name db_user runtime_key

  api_running="$(podman inspect -f '{{.State.Running}}' docker_api_1 2>/dev/null || true)"
  pg_running="$(podman inspect -f '{{.State.Running}}' fortisai-pgvector 2>/dev/null || true)"
  if [[ "$api_running" != "true" || "$pg_running" != "true" ]]; then
    return 0
  fi

  db_name="$(podman exec docker_api_1 sh -lc 'printf %s "$DB_DATABASE"' 2>/dev/null || true)"
  db_user="$(podman exec docker_api_1 sh -lc 'printf %s "$DB_USERNAME"' 2>/dev/null || true)"
  if [[ -z "$db_name" || -z "$db_user" ]]; then
    return 0
  fi

  runtime_key="$(podman exec fortisai-pgvector psql -U "$db_user" -d "$db_name" -tAc "WITH target AS (SELECT id AS app_id, tenant_id FROM apps ORDER BY created_at DESC LIMIT 1), existing AS (SELECT token FROM api_tokens WHERE type='app' AND app_id=(SELECT app_id FROM target) ORDER BY created_at DESC LIMIT 1), inserted AS (INSERT INTO api_tokens (app_id, tenant_id, type, token) SELECT app_id, tenant_id, 'app', 'app-' || substring(md5(random()::text || clock_timestamp()::text) from 1 for 24) FROM target WHERE NOT EXISTS (SELECT 1 FROM existing) RETURNING token) SELECT COALESCE((SELECT token FROM existing), (SELECT token FROM inserted), '');" 2>/dev/null | tr -d '[:space:]' || true)"

  if [[ "$runtime_key" == app-* ]]; then
    printf '%s' "$runtime_key"
  fi
}

load_dify_keys_from_json() {
  mkdir -p "$DIFY_MCP_DIR"

  local json_exports
  json_exports="$(DIFY_KEYS_JSON_FILE="$DIFY_KEYS_JSON_FILE" python3 - <<'PY'
import json
import os
import secrets
from datetime import datetime, timezone
from pathlib import Path

cfg = Path(os.environ["DIFY_KEYS_JSON_FILE"])

try:
    data = json.loads(cfg.read_text(encoding="utf-8")) if cfg.exists() else {}
except Exception:
    data = {}

def ensure_key(raw: str) -> str:
  value = str(raw or "").strip()
  if value:
    return value
  return secrets.token_hex(16)

app_key = ensure_key(os.environ.get("APP_API_KEY") or str(data.get("dify_app_api_key", "")).strip())
knowledge_key = ensure_key(os.environ.get("KNOWLEDGE_API_KEY") or str(data.get("dify_knowledge_api_key", "")).strip())
api_key = ensure_key(
    os.environ.get("DIFY_API_KEY")
    or os.environ.get("ADMIN_API_KEY")
    or str(data.get("dify_api_key") or data.get("dify_admin_api_key") or data.get("admin_api_key") or "").strip()
)

payload = {
    "dify_app_api_key": app_key,
    "dify_knowledge_api_key": knowledge_key,
    "dify_api_key": api_key,
    "updated_at": datetime.now(timezone.utc).isoformat(),
}
cfg.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

print(f"APP_API_KEY={app_key}")
print(f"KNOWLEDGE_API_KEY={knowledge_key}")
print(f"DIFY_API_KEY={api_key}")
print(f"ADMIN_API_KEY={api_key}")
PY
)"

  while IFS='=' read -r key value; do
    [[ -z "$key" ]] && continue
    export "$key=$value"
  done <<< "$json_exports"

  local runtime_api_key
  runtime_api_key="$(resolve_dify_runtime_api_key || true)"
  if [[ -n "$runtime_api_key" && "$runtime_api_key" != "${DIFY_API_KEY:-}" ]]; then
    export APP_API_KEY="$runtime_api_key"
    export DIFY_API_KEY="$runtime_api_key"
    export ADMIN_API_KEY="$runtime_api_key"

    DIFY_KEYS_JSON_FILE="$DIFY_KEYS_JSON_FILE" DIFY_API_KEY_VALUE="$runtime_api_key" python3 - <<'PY'
import json
import os
from datetime import datetime, timezone
from pathlib import Path

cfg = Path(os.environ["DIFY_KEYS_JSON_FILE"])
key = os.environ["DIFY_API_KEY_VALUE"]
try:
    data = json.loads(cfg.read_text(encoding="utf-8")) if cfg.exists() else {}
except Exception:
    data = {}

data["dify_app_api_key"] = key
data["dify_api_key"] = key
data["updated_at"] = datetime.now(timezone.utc).isoformat()
cfg.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
  fi

  chmod 600 "$DIFY_KEYS_JSON_FILE" 2>/dev/null || true
}

validate_ocid_like() {
  local name="$1"
  local value="$2"
  if [[ -z "$value" || ! "$value" =~ ^ocid1\.[a-zA-Z0-9._-]+\..+ ]]; then
    err "$name does not look like a valid OCID: $value"
    return 1
  fi
}

validate_prod_config() {
  local strict="${1:-false}"
  local failed=0

  require_cmd oci
  require_cmd jq

  if [[ ! -f "$PROD_ENV_FILE" ]]; then
    err "Production env file not found: $PROD_ENV_FILE"
    err "Create it with: $SCRIPT_NAME prod-template"
    err "Then copy and edit: cp $PROD_ENV_EXAMPLE_FILE $PROD_ENV_FILE"
    return 1
  fi

  load_prod_env

  local required_vars
  required_vars=(
    OCI_CLI_PROFILE
    OCI_REGION
    BASTION_SERVICE_ID
    BASTION_SSH_PUBLIC_KEY_PATH
    PROD_GENAI_PRIVATE_IP
    PROD_LLAMA_PRIVATE_IP
    OCI_DEVOPS_GIT_USERNAME_SECRET_ID
    OCI_DEVOPS_GIT_TOKEN_SECRET_ID
    GENAI_OCI_CREDENTIALS_SECRET_ID
  )

  local var
  for var in "${required_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then
      err "Missing required variable in $PROD_ENV_FILE: $var"
      failed=1
    fi
  done

  if [[ -n "${BASTION_SSH_PUBLIC_KEY_PATH:-}" && ! -f "$BASTION_SSH_PUBLIC_KEY_PATH" ]]; then
    err "SSH public key file does not exist: $BASTION_SSH_PUBLIC_KEY_PATH"
    failed=1
  fi

  if [[ -n "${BASTION_SERVICE_ID:-}" ]]; then
    validate_ocid_like "BASTION_SERVICE_ID" "$BASTION_SERVICE_ID" || failed=1
  fi

  if [[ -n "${OCI_DEVOPS_GIT_USERNAME_SECRET_ID:-}" ]]; then
    validate_ocid_like "OCI_DEVOPS_GIT_USERNAME_SECRET_ID" "$OCI_DEVOPS_GIT_USERNAME_SECRET_ID" || failed=1
  fi

  if [[ -n "${OCI_DEVOPS_GIT_TOKEN_SECRET_ID:-}" ]]; then
    validate_ocid_like "OCI_DEVOPS_GIT_TOKEN_SECRET_ID" "$OCI_DEVOPS_GIT_TOKEN_SECRET_ID" || failed=1
  fi

  if [[ -n "${GENAI_OCI_CREDENTIALS_SECRET_ID:-}" ]]; then
    validate_ocid_like "GENAI_OCI_CREDENTIALS_SECRET_ID" "$GENAI_OCI_CREDENTIALS_SECRET_ID" || failed=1
  fi

  if [[ -n "${PROD_GITHUB_PRIVATE_IP:-}" && -z "${PROD_GITHUB_PORT:-}" ]]; then
    err "PROD_GITHUB_PRIVATE_IP is set but PROD_GITHUB_PORT is empty"
    failed=1
  fi

  if [[ "$strict" == "true" && -z "${BASTION_TARGET_SUBNET_ID:-}" ]]; then
    log "Warning: BASTION_TARGET_SUBNET_ID is empty (recommended for operator context)."
  fi

  if [[ "$failed" -ne 0 ]]; then
    err "Production config validation failed. Fix values in $PROD_ENV_FILE and retry."
    return 1
  fi

  log "Production config validation passed"
}

compose_cmd() {
  # Determine if podman compose is the native plugin or delegating to external podman-compose.
  # The delegation banner contains the word "podman-compose"; the native plugin output does not.
  local pc_out
  pc_out="$(podman compose version 2>/dev/null || true)"
  if printf '%s' "$pc_out" | grep -qiv 'podman-compose' && printf '%s' "$pc_out" | grep -qi 'version'; then
    # Native podman compose plugin - no known compatibility issues.
    echo "podman compose"
    return
  fi

  # podman is delegating to external podman-compose (or podman compose is unavailable).
  # Check the external binary's version: 1.5.x has bugs with Dify profiles/depends_on.
  if command -v podman-compose >/dev/null 2>&1; then
    local pc_ver pc_major pc_minor
    pc_ver="$(podman-compose version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)"
    pc_major="${pc_ver%%.*}"
    pc_minor="${pc_ver##*.}"
    if [[ "${pc_major:-0}" -ge 1 && "${pc_minor:-0}" -ge 5 ]]; then
      # podman-compose 1.5.x: strict network validation and profile/depends_on bugs break Dify.
      # Prefer docker compose (Docker Desktop) which handles profiles correctly.
      if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
        log "podman-compose $pc_ver has known Dify incompatibilities; using 'docker compose' instead"
        echo "docker compose"
        return
      fi
      err "podman-compose $pc_ver has known incompatibilities with Dify (profile/depends_on bugs)."
      err "Fix option 1 - install Docker Desktop (provides a compatible compose):"
      err "  https://www.docker.com/products/docker-desktop"
      err "Fix option 2 - downgrade podman-compose:"
      err "  brew uninstall podman-compose"
      err "  pip3 install --user 'podman-compose<1.5'"
      err "  export PATH=\"\$HOME/.local/bin:\$PATH\"  # add to ~/.zshrc"
      exit 1
    fi
    echo "podman-compose"
    return
  fi

  err "No compose implementation found."
  err "Install Docker Desktop or run: brew install podman-compose"
  exit 1
}

run_compose() {
  local compose
  compose="$(compose_cmd)"
  case "$compose" in
    "podman compose")  podman compose "$@" ;;
    "docker compose")  docker compose "$@" ;;
    *)                 podman-compose "$@" ;;
  esac
}

start_n8n_stack() {
  if container_running fortisai-n8n && container_running fortisai-n8n-workflow-runner; then
    return 0
  fi

  ensure_container_reusable fortisai-n8n || return 1
  ensure_container_reusable fortisai-n8n-workflow-runner || return 1

  if container_exists fortisai-n8n || container_exists fortisai-n8n-workflow-runner; then
    podman rm -f fortisai-n8n fortisai-n8n-workflow-runner >/dev/null 2>&1 || true
    wait_for_container_absence fortisai-n8n 10 || true
    wait_for_container_absence fortisai-n8n-workflow-runner 10 || true
  fi

  if run_compose -f "$N8N_COMPOSE_FILE" up -d >/dev/null 2>&1; then
    return 0
  fi
  err "Failed to start n8n stack; run '$SCRIPT_NAME logs n8n' for details"
  return 1
}

has_docker_compose() {
  command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1
}

resolve_podman_socket_path() {
  if [[ -n "${PODMAN_SOCKET_PATH:-}" ]]; then
    printf '%s\n' "$PODMAN_SOCKET_PATH"
    return
  fi

  local socket_path
  socket_path="$(podman info --format '{{.Host.RemoteSocket.Path}}' 2>/dev/null || true)"
  socket_path="${socket_path#unix://}"

  if [[ -z "$socket_path" ]]; then
    socket_path="/run/user/$(id -u)/podman/podman.sock"
  fi

  if podman machine ssh "test -S '$socket_path'" >/dev/null 2>&1; then
    printf '%s\n' "$socket_path"
    return
  fi

  err "Could not resolve Podman socket path for Oracle Node API."
  err "Set PODMAN_SOCKET_PATH before running the helper, for example:"
  err "  export PODMAN_SOCKET_PATH=/run/user/$(id -u)/podman/podman.sock"
  exit 1
}

ensure_machine() {
  require_cmd podman

  if ! podman machine list --format '{{.Name}}' | grep -q .; then
    log "Initializing Podman machine"
    podman machine init --cpus "$PODMAN_CPUS" --memory "$PODMAN_MEMORY_MB" --disk-size "$PODMAN_DISK_GB"
  fi

  log "Starting Podman machine"
  podman machine start >/dev/null 2>&1 || true

  if ! podman info >/dev/null 2>&1; then
    err "Podman machine is not ready. Run 'podman machine start' manually and retry."
    exit 1
  fi
}

ensure_shared_network() {
  if podman network exists "$FORTISAI_SHARED_NETWORK" >/dev/null 2>&1; then
    return
  fi

  log "Creating shared development network: $FORTISAI_SHARED_NETWORK"
  if ! podman network create "$FORTISAI_SHARED_NETWORK" >/dev/null 2>&1; then
    if podman network exists "$FORTISAI_SHARED_NETWORK" >/dev/null 2>&1; then
      return
    fi
    err "Failed to create shared development network: $FORTISAI_SHARED_NETWORK"
    exit 1
  fi
}

oracle_db_pull() {
  require_cmd podman

  if podman image exists "$ORACLE_DB_IMAGE" >/dev/null 2>&1; then
    log "Oracle DB image already present: $ORACLE_DB_IMAGE"
    return 0
  fi

  log "Oracle DB image not found locally; attempting pull: $ORACLE_DB_IMAGE"

  if [[ -n "$OCR_USERNAME" && -n "$OCR_AUTH_TOKEN" ]]; then
    log "Logging into OCR registry ($OCR_REGISTRY) with OCR_USERNAME and OCR_AUTH_TOKEN"
    if ! printf '%s' "$OCR_AUTH_TOKEN" | podman login "$OCR_REGISTRY" --username "$OCR_USERNAME" --password-stdin >/dev/null; then
      err "OCR login failed for $OCR_REGISTRY"
      err "Verify OCR_USERNAME/OCR_AUTH_TOKEN and confirm Oracle registry terms are accepted for this repository."
      return 1
    fi
  else
    log "OCR credentials not set (OCR_USERNAME/OCR_AUTH_TOKEN); trying anonymous pull"
  fi

  if ! podman pull "$ORACLE_DB_IMAGE"; then
    err "Failed to pull Oracle DB image: $ORACLE_DB_IMAGE"
    err "If this is your first pull, sign in and accept terms at https://container-registry.oracle.com/ords/ocr/ba/database/free"
    err "Then set OCR_USERNAME and OCR_AUTH_TOKEN before retrying."
    return 1
  fi

  log "Pulled Oracle DB image successfully: $ORACLE_DB_IMAGE"
}

pull_ords_sqlcl_images() {
  require_cmd podman

  if podman image exists "$ORDS_IMAGE" >/dev/null 2>&1; then
    log "ORDS image already present: $ORDS_IMAGE"
  else
    log "Pulling ORDS image: $ORDS_IMAGE"
    podman pull "$ORDS_IMAGE"
  fi

  if podman image exists "$SQLCL_IMAGE" >/dev/null 2>&1; then
    log "SQLcl image already present: $SQLCL_IMAGE"
  else
    log "Pulling SQLcl image: $SQLCL_IMAGE"
    podman pull "$SQLCL_IMAGE"
  fi
}

init_ords_config() {
  require_cmd podman

  podman volume create "$ORDS_CONFIG_VOLUME" >/dev/null 2>&1 || true

  local db_host="$ORACLE_DB_CONTAINER_NAME"
  local db_port="$ORACLE_DB_HOST_PORT"
  local db_service_name="$ORACLE_DB_PDB"

  if [[ -f "$ORACLE_DB_WALLET_ENV_FILE" ]]; then
    local wallet_value
    wallet_value="$(oracle_db_wallet_value ORACLE_DB_HOST || true)"
    [[ -n "$wallet_value" ]] && db_host="$wallet_value"
    wallet_value="$(oracle_db_wallet_value ORACLE_DB_PORT || true)"
    [[ -n "$wallet_value" ]] && db_port="$wallet_value"
    wallet_value="$(oracle_db_wallet_value ORACLE_DB_SERVICE_NAME || true)"
    [[ -n "$wallet_value" ]] && db_service_name="$wallet_value"
  fi

  local has_config
  has_config="$(podman run --rm -v "${ORDS_CONFIG_VOLUME}:/etc/ords/config" "$ORDS_IMAGE" /bin/sh -lc 'if [ -f /etc/ords/config/global/settings.xml ]; then echo 1; else echo 0; fi' 2>/dev/null || echo 0)"
  has_config="$(printf '%s\n' "$has_config" | grep -Eo '[0-9]+' | tail -1)"
  has_config="${has_config:-0}"
  if [[ "$has_config" -gt 0 ]]; then
    log "ORDS config already exists in volume: $ORDS_CONFIG_VOLUME"
    return
  fi

  log "Initializing ORDS config volume: $ORDS_CONFIG_VOLUME"

  # ORDS reads multiple passwords from stdin during non-interactive install.
  printf '%s\n%s\n%s\n%s\n%s\n' \
    "$ORACLE_DB_PASSWORD" \
    "$ORACLE_DB_PASSWORD" \
    "$ORDS_DB_PASSWORD" \
    "$ORDS_DB_PASSWORD" \
    "$ORDS_DB_PASSWORD" | \
    podman run -i --rm \
      --network "$FORTISAI_SHARED_NETWORK" \
      -v "${ORDS_CONFIG_VOLUME}:/etc/ords/config" \
      "$ORDS_IMAGE" \
      --config /etc/ords/config install \
      --admin-user SYS \
      --db-hostname "$db_host" \
      --db-port "$db_port" \
      --db-servicename "$db_service_name" \
      --db-user "$ORDS_DB_USER" \
      --proxy-user \
      --feature-sdw true \
      --password-stdin >/dev/null
}

wait_for_oracle_db() {
  local max_attempts=60
  local attempt=1

  log "Waiting for Oracle DB to accept connections"
  while (( attempt <= max_attempts )); do
    if podman exec "$ORACLE_DB_CONTAINER_NAME" bash -lc "printf 'select 1 from dual;\nexit\n' | sqlplus -L -s \"pdbadmin/${ORACLE_DB_PASSWORD}@${ORACLE_DB_PDB}\"" >/dev/null 2>&1; then
      log "Oracle DB is ready"
      return 0
    fi
    sleep 5
    attempt=$((attempt + 1))
  done

  err "Oracle DB did not become ready in time"
  return 1
}

write_n8n_compose() {
  mkdir -p "$N8N_DIR"
  cat > "$N8N_COMPOSE_FILE" <<YAML
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
      - N8N_BASIC_AUTH_USER=$N8N_BASIC_AUTH_USER
      - N8N_BASIC_AUTH_PASSWORD=$N8N_BASIC_AUTH_PASSWORD
      - FORTISAI_SHARED_NETWORK=$FORTISAI_SHARED_NETWORK
      - FORTISAI_ORACLE_DB_HOST=$ORACLE_DB_CONTAINER_NAME
      - FORTISAI_ORACLE_DB_PORT=$ORACLE_DB_HOST_PORT
      - FORTISAI_ORACLE_DB_PDB=$ORACLE_DB_PDB
      - FORTISAI_ORACLE_DB_USER=$ORACLE_DB_USER
      - FORTISAI_ORACLE_DB_PASSWORD=$ORACLE_DB_PASSWORD
      - FORTISAI_REDIS_URL=redis://$REDIS_CONTAINER_NAME:6379
      - FORTISAI_PGVECTOR_DSN=postgresql://$PGVECTOR_USER:$PGVECTOR_PASSWORD@$PGVECTOR_CONTAINER_NAME:5432/$PGVECTOR_DB
      - FORTISAI_QDRANT_URL=$QDRANT_INTERNAL_URL
      - FORTISAI_LLAMA_SERVER_URL=$FORTISAI_LLAMA_SERVER_URL
      - FORTISAI_LLAMA_SERVER_BASE_URL=$FORTISAI_LLAMA_SERVER_BASE_URL
      - FORTISAI_LLAMA_OPENAI_BASE_URL=$FORTISAI_LLAMA_OPENAI_BASE_URL
      - FORTISAI_LLAMA_OPENAI_API_KEY=$FORTISAI_LLAMA_OPENAI_API_KEY
      - FORTISAI_REPO_ROOT=/FortisAI
      - FORTISAI_N8N_CONFIG_DIR=/FortisAI/Development_Environment/n8n-config
      - FORTISAI_DIFY_CONFIG_DIR=/FortisAI/Development_Environment/dify-config
      - FORTISAI_VAULT_ADDR=$VAULT_INTERNAL_URL
      - VAULT_ADDR=$VAULT_INTERNAL_URL
      - VAULT_TOKEN=$VAULT_TOKEN
      - QDRANT_URL=$QDRANT_INTERNAL_URL
      - QDRANT_API_KEY=$QDRANT_API_KEY
    volumes:
      - n8n_data:/home/node/.n8n
      - "$DEV_ENV_DIR/n8n-config:/FortisAI/Development_Environment/n8n-config:rw"
      - "$DEV_ENV_DIR/dify-config:/FortisAI/Development_Environment/dify-config:rw"
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
      - FORTISAI_LLAMA_SERVER_URL=$FORTISAI_LLAMA_SERVER_URL
      - FORTISAI_LLAMA_SERVER_BASE_URL=$FORTISAI_LLAMA_SERVER_BASE_URL
      - FORTISAI_LLAMA_OPENAI_BASE_URL=$FORTISAI_LLAMA_OPENAI_BASE_URL
      - FORTISAI_LLAMA_OPENAI_API_KEY=$FORTISAI_LLAMA_OPENAI_API_KEY
    volumes:
      - "$DEV_ENV_DIR/n8n-config:/FortisAI/Development_Environment/n8n-config:rw"
      - "$DEV_ENV_DIR/dify-config:/FortisAI/Development_Environment/dify-config:rw"
volumes:
  n8n_data:
networks:
  default:
    name: $FORTISAI_SHARED_NETWORK
    external: true
YAML
}

write_openwebui_compose() {
  local openwebui_openai_base_url
  local openwebui_openai_api_key

  case "$OPENWEBUI_LLM_BACKEND" in
    hermes)
      openwebui_openai_base_url="http://$HERMES_CONTAINER_NAME:8642/v1"
      openwebui_openai_api_key="$HERMES_API_SERVER_KEY"
      ;;
    openclaw|"")
      openwebui_openai_base_url="http://$OPENCLAW_CONTAINER_NAME:18789/v1"
      openwebui_openai_api_key="$OPENCLAW_GATEWAY_TOKEN"
      ;;
    *)
      err "Unsupported OPENWEBUI_LLM_BACKEND: $OPENWEBUI_LLM_BACKEND (use openclaw or hermes)"
      exit 1
      ;;
  esac

  mkdir -p "$OPENWEBUI_DIR"
  cat > "$OPENWEBUI_COMPOSE_FILE" <<YAML
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
      - AIOHTTP_CLIENT_TIMEOUT=$OPENWEBUI_AIOHTTP_CLIENT_TIMEOUT
      - OPENAI_API_BASE_URL=$openwebui_openai_base_url
      - OPENAI_API_KEY=$openwebui_openai_api_key
      - FIRECRAWL_BASE_URL=$FIRECRAWL_INTERNAL_URL
      - FIRECRAWL_API_KEY=$FIRECRAWL_API_KEY
      - FORTISAI_SHARED_NETWORK=$FORTISAI_SHARED_NETWORK
      - FORTISAI_ORACLE_DB_HOST=$ORACLE_DB_CONTAINER_NAME
      - FORTISAI_ORACLE_DB_PORT=$ORACLE_DB_HOST_PORT
      - FORTISAI_ORACLE_DB_PDB=$ORACLE_DB_PDB
      - FORTISAI_ORACLE_DB_USER=$ORACLE_DB_USER
      - FORTISAI_ORACLE_DB_PASSWORD=$ORACLE_DB_PASSWORD
      - FORTISAI_REDIS_URL=redis://$REDIS_CONTAINER_NAME:6379
      - FORTISAI_PGVECTOR_DSN=postgresql://$PGVECTOR_USER:$PGVECTOR_PASSWORD@$PGVECTOR_CONTAINER_NAME:5432/$PGVECTOR_DB
      - FORTISAI_VAULT_ADDR=$VAULT_INTERNAL_URL
      - VAULT_ADDR=$VAULT_INTERNAL_URL
      - VAULT_TOKEN=$VAULT_TOKEN
    volumes:
      - openwebui_data:/app/backend/data
volumes:
  openwebui_data:
networks:
  default:
    name: $FORTISAI_SHARED_NETWORK
    external: true
YAML
}

openvscode_user_entries() {
  local entries="${OPENVSCODE_USERS:-${USER:-aiuser}}"

  entries="${entries//,/ }"
  for entry in $entries; do
    [[ -n "$entry" ]] && printf '%s\n' "$entry"
  done
}

openvscode_user_slug() {
  local value="${1:-user}"
  local slug

  slug="$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
  [[ -n "$slug" ]] || slug="user"
  printf '%s' "$slug"
}

openvscode_user_records() {
  local entries entry index seen_slugs
  local refresh_tokens="${1:-false}"

  entries="$(openvscode_user_entries)"
  if [[ -z "$entries" ]]; then
    entries="${USER:-aiuser}"
  fi

  index=0
  seen_slugs=""
  while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue

    local user_name user_port user_token user_workspace
    local slug user_dir token_file service_name container_name

    IFS=':' read -r user_name user_port user_token user_workspace _ <<< "$entry"
    user_name="${user_name:-${USER:-aiuser}}"
    slug="$(openvscode_user_slug "$user_name")"

    case " $seen_slugs " in
      *" $slug "*)
        err "Duplicate OpenVSCode user slug in OPENVSCODE_USERS: $slug"
        return 1
        ;;
    esac
    seen_slugs="$seen_slugs $slug"

    if [[ -z "${user_port:-}" ]]; then
      user_port="$((OPENVSCODE_HOST_PORT + index))"
    fi
    if ! [[ "$user_port" =~ ^[0-9]+$ ]]; then
      err "OpenVSCode port must be numeric for user '$user_name': $user_port"
      return 1
    fi

    if [[ -z "${user_workspace:-}" ]]; then
      user_workspace="$OPENVSCODE_WORKSPACE_DIR"
    fi

    if [[ "$index" -eq 0 ]]; then
      service_name="openvscode"
      container_name="$OPENVSCODE_CONTAINER_NAME"
    else
      service_name="openvscode-$slug"
      container_name="$OPENVSCODE_CONTAINER_NAME-$slug"
    fi

    user_dir="$OPENVSCODE_DIR/users/$slug"
    token_file="$user_dir/connection-token"
    mkdir -p "$user_dir" "$user_workspace"

    if [[ -n "${user_token:-}" && "$refresh_tokens" == "true" ]]; then
      printf '%s\n' "$user_token" > "$token_file"
    elif [[ "$index" -eq 0 && ! -s "$token_file" ]]; then
      printf '%s\n' "$OPENVSCODE_CONNECTION_TOKEN" > "$token_file"
    elif [[ "$index" -eq 0 && "$refresh_tokens" == "true" && "$OPENVSCODE_CONNECTION_TOKEN" != "fortisai-openvscode-dev-token" ]]; then
      printf '%s\n' "$OPENVSCODE_CONNECTION_TOKEN" > "$token_file"
    elif [[ ! -s "$token_file" ]]; then
      random_urlsafe_secret 24 > "$token_file"
    fi
    chmod 644 "$token_file" 2>/dev/null || true

    printf '%s|%s|%s|%s|%s|%s|%s|%s\n' \
      "$index" "$user_name" "$slug" "$user_port" "$token_file" "$user_workspace" "$container_name" "$service_name"
    index=$((index + 1))
  done <<< "$entries"
}

openvscode_container_for_user() {
  local target_user="${1:-}"
  local target_slug=""

  if [[ -n "$target_user" ]]; then
    target_slug="$(openvscode_user_slug "$target_user")"
  fi

  while IFS='|' read -r index user_name slug _port _token_file _workspace container_name _service_name; do
    if [[ -z "$target_user" && "$index" == "0" ]]; then
      printf '%s' "$container_name"
      return 0
    fi
    if [[ "$target_user" == "$user_name" || "$target_user" == "$slug" || "$target_slug" == "$slug" ]]; then
      printf '%s' "$container_name"
      return 0
    fi
  done < <(openvscode_user_records)

  return 1
}

openvscode_print_users() {
  printf '%-18s %-8s %-34s %-48s %s\n' "USER" "PORT" "CONTAINER" "TOKEN_FILE" "WORKSPACE"
  while IFS='|' read -r _index user_name _slug port token_file workspace container_name _service_name; do
    printf '%-18s %-8s %-34s %-48s %s\n' "$user_name" "$port" "$container_name" "$token_file" "$workspace"
  done < <(openvscode_user_records)
}

openvscode_users() {
  ensure_machine
  write_openvscode_compose
  openvscode_print_users
}

openvscode_list_extensions() {
  ensure_machine
  local target_user="${1:-}"
  local container_name

  container_name="$(openvscode_container_for_user "$target_user")" || {
    err "Unknown OpenVSCode user: ${target_user:-default}"
    exit 1
  }
  if ! container_running "$container_name"; then
    err "OpenVSCode container is not running: $container_name"
    exit 1
  fi

  podman exec "$container_name" "$OPENVSCODE_SERVER_BIN" \
    --user-data-dir "$OPENVSCODE_USER_DATA_DIR" \
    --extensions-dir "$OPENVSCODE_EXTENSIONS_DIR" \
    --list-extensions
}

openvscode_install_extension() {
  ensure_machine
  local target_user="" extension=""
  local container_name
  local container_extension=""
  local copied_extension=""

  case "$#" in
    1)
      extension="$1"
      ;;
    2)
      target_user="$1"
      extension="$2"
      ;;
    *)
      err "Usage: $SCRIPT_NAME openvscode-install-extension [user] <extension-id-or-vsix>"
      exit 1
      ;;
  esac

  container_name="$(openvscode_container_for_user "$target_user")" || {
    err "Unknown OpenVSCode user: ${target_user:-default}"
    exit 1
  }
  if ! container_running "$container_name"; then
    err "OpenVSCode container is not running: $container_name"
    exit 1
  fi

  container_extension="$extension"
  if [[ -f "$extension" ]]; then
    copied_extension="/tmp/$(basename "$extension")"
    podman cp "$extension" "$container_name:$copied_extension"
    container_extension="$copied_extension"
  fi

  podman exec "$container_name" "$OPENVSCODE_SERVER_BIN" \
    --user-data-dir "$OPENVSCODE_USER_DATA_DIR" \
    --extensions-dir "$OPENVSCODE_EXTENSIONS_DIR" \
    --install-extension "$container_extension" \
    --force

  if [[ -n "$copied_extension" ]]; then
    podman exec "$container_name" rm -f "$copied_extension" >/dev/null 2>&1 || true
  fi
}

openvscode_uninstall_extension() {
  ensure_machine
  local target_user="" extension=""
  local container_name

  case "$#" in
    1)
      extension="$1"
      ;;
    2)
      target_user="$1"
      extension="$2"
      ;;
    *)
      err "Usage: $SCRIPT_NAME openvscode-uninstall-extension [user] <extension-id>"
      exit 1
      ;;
  esac

  container_name="$(openvscode_container_for_user "$target_user")" || {
    err "Unknown OpenVSCode user: ${target_user:-default}"
    exit 1
  }
  if ! container_running "$container_name"; then
    err "OpenVSCode container is not running: $container_name"
    exit 1
  fi

  podman exec "$container_name" "$OPENVSCODE_SERVER_BIN" \
    --user-data-dir "$OPENVSCODE_USER_DATA_DIR" \
    --extensions-dir "$OPENVSCODE_EXTENSIONS_DIR" \
    --uninstall-extension "$extension"
}

write_openvscode_compose() {
  mkdir -p "$OPENVSCODE_DIR"
  local volume_lines=""

  cat > "$OPENVSCODE_COMPOSE_FILE" <<YAML
services:
YAML

  while IFS='|' read -r index user_name slug port token_file workspace container_name service_name; do
    local server_volume user_data_volume extensions_volume

    if [[ "$index" == "0" ]]; then
      server_volume="openvscode_data"
    else
      server_volume="openvscode_server_$slug"
    fi
    user_data_volume="openvscode_user_data_$slug"
    extensions_volume="openvscode_extensions_$slug"

    cat >> "$OPENVSCODE_COMPOSE_FILE" <<YAML
  $service_name:
    image: $OPENVSCODE_IMAGE
    container_name: $container_name
    restart: unless-stopped
    ports:
      - "$port:3000"
    environment:
      - OPENVSCODE_USER=$user_name
      - OPENVSCODE_USER_SLUG=$slug
      - OPENVSCODE_USER_DATA_DIR=$OPENVSCODE_USER_DATA_DIR
      - OPENVSCODE_EXTENSIONS_DIR=$OPENVSCODE_EXTENSIONS_DIR
      - FORTISAI_SHARED_NETWORK=$FORTISAI_SHARED_NETWORK
      - FORTISAI_VAULT_ADDR=$VAULT_INTERNAL_URL
      - VAULT_ADDR=$VAULT_INTERNAL_URL
      - VAULT_TOKEN=$VAULT_TOKEN
    entrypoint: $OPENVSCODE_SERVER_BIN
    command:
      - --host
      - 0.0.0.0
      - --port
      - "3000"
      - --connection-token-file
      - /run/fortisai-openvscode/connection-token
      - --telemetry-level
      - "off"
      - --user-data-dir
      - $OPENVSCODE_USER_DATA_DIR
      - --extensions-dir
      - $OPENVSCODE_EXTENSIONS_DIR
    volumes:
      - $server_volume:/home/.openvscode-server
      - $user_data_volume:$OPENVSCODE_USER_DATA_DIR
      - $extensions_volume:$OPENVSCODE_EXTENSIONS_DIR
      - $token_file:/run/fortisai-openvscode/connection-token:ro
      - $workspace:$OPENVSCODE_WORKSPACE_MOUNT_PATH
YAML
    volume_lines="${volume_lines}  $server_volume:
  $user_data_volume:
  $extensions_volume:
"
  done < <(openvscode_user_records true)

  cat >> "$OPENVSCODE_COMPOSE_FILE" <<YAML
volumes:
${volume_lines}networks:
  default:
    name: $FORTISAI_SHARED_NETWORK
    external: true
YAML
}

openvscode_runtime_volume_name() {
  local volume_name="$1"
  printf 'openvscode_%s' "$volume_name"
}

start_openvscode() {
  local container_name
  local waited

  while IFS='|' read -r index user_name slug port token_file workspace container_name service_name; do
    local server_volume user_data_volume extensions_volume
    local runtime_server_volume runtime_user_data_volume runtime_extensions_volume

    ensure_container_reusable "$container_name" || return 1

    if [[ "$index" == "0" ]]; then
      server_volume="openvscode_data"
    else
      server_volume="openvscode_server_$slug"
    fi
    user_data_volume="openvscode_user_data_$slug"
    extensions_volume="openvscode_extensions_$slug"
    runtime_server_volume="$(openvscode_runtime_volume_name "$server_volume")"
    runtime_user_data_volume="$(openvscode_runtime_volume_name "$user_data_volume")"
    runtime_extensions_volume="$(openvscode_runtime_volume_name "$extensions_volume")"

    if container_running "$container_name"; then
      continue
    fi

    podman rm -f "$container_name" >/dev/null 2>&1 || true
    podman run -d \
      --name "$container_name" \
      --restart unless-stopped \
      --network "$FORTISAI_SHARED_NETWORK" \
      --network-alias "$service_name" \
      -p "$port:3000" \
      -e "OPENVSCODE_USER=$user_name" \
      -e "OPENVSCODE_USER_SLUG=$slug" \
      -e "OPENVSCODE_USER_DATA_DIR=$OPENVSCODE_USER_DATA_DIR" \
      -e "OPENVSCODE_EXTENSIONS_DIR=$OPENVSCODE_EXTENSIONS_DIR" \
      -e "FORTISAI_SHARED_NETWORK=$FORTISAI_SHARED_NETWORK" \
      -e "FORTISAI_VAULT_ADDR=$VAULT_INTERNAL_URL" \
      -e "VAULT_ADDR=$VAULT_INTERNAL_URL" \
      -e "VAULT_TOKEN=$VAULT_TOKEN" \
      -v "$runtime_server_volume:/home/.openvscode-server" \
      -v "$runtime_user_data_volume:$OPENVSCODE_USER_DATA_DIR" \
      -v "$runtime_extensions_volume:$OPENVSCODE_EXTENSIONS_DIR" \
      -v "$token_file:/run/fortisai-openvscode/connection-token:ro" \
      -v "$workspace:$OPENVSCODE_WORKSPACE_MOUNT_PATH" \
      --entrypoint "$OPENVSCODE_SERVER_BIN" \
      "$OPENVSCODE_IMAGE" \
      --host 0.0.0.0 \
      --port 3000 \
      --connection-token-file /run/fortisai-openvscode/connection-token \
      --telemetry-level off \
      --user-data-dir "$OPENVSCODE_USER_DATA_DIR" \
      --extensions-dir "$OPENVSCODE_EXTENSIONS_DIR" >/dev/null

    waited=0
    while ! container_running "$container_name"; do
      if [[ "$waited" -ge 60 ]]; then
        break
      fi
      sleep 2
      waited=$((waited + 2))
    done
    if ! container_running "$container_name"; then
      err "OpenVSCode container is not running after startup attempt: $container_name"
      return 1
    fi
  done < <(openvscode_user_records)
}

stop_openvscode() {
  local container_name

  while IFS='|' read -r _index _user_name _slug _port _token_file _workspace container_name _service_name; do
    podman rm -f "$container_name" >/dev/null 2>&1 || true
  done < <(openvscode_user_records)

  podman rm -f "$OPENVSCODE_CONTAINER_NAME" >/dev/null 2>&1 || true
}

openvscode_up() {
  ensure_machine
  ensure_shared_network
  write_openvscode_compose
  start_openvscode
  openvscode_print_users
}

openvscode_down() {
  ensure_machine
  stop_openvscode
}

start_openwebui() {
  local openwebui_openai_base_url
  local openwebui_openai_api_key

  case "$OPENWEBUI_LLM_BACKEND" in
    hermes)
      openwebui_openai_base_url="http://$HERMES_CONTAINER_NAME:8642/v1"
      openwebui_openai_api_key="$HERMES_API_SERVER_KEY"
      ;;
    openclaw|"")
      openwebui_openai_base_url="http://$OPENCLAW_CONTAINER_NAME:18789/v1"
      openwebui_openai_api_key="$OPENCLAW_GATEWAY_TOKEN"
      ;;
    *)
      err "Unsupported OPENWEBUI_LLM_BACKEND: $OPENWEBUI_LLM_BACKEND (use openclaw or hermes)"
      exit 1
      ;;
  esac

  if container_running fortisai-openwebui; then
    if container_needs_vault_runtime_refresh fortisai-openwebui "$OPENWEBUI_COMPOSE_FILE"; then
      log "Recreating container to apply Vault runtime env: fortisai-openwebui"
      podman rm -f fortisai-openwebui >/dev/null 2>&1 || true
      wait_for_container_absence fortisai-openwebui 20 || true
    else
      return 0
    fi
  fi

  if container_exists fortisai-openwebui && container_needs_vault_runtime_refresh fortisai-openwebui "$OPENWEBUI_COMPOSE_FILE"; then
    log "Removing existing container to apply Vault runtime env: fortisai-openwebui"
    podman rm -f fortisai-openwebui >/dev/null 2>&1 || true
    wait_for_container_absence fortisai-openwebui 20 || true
  fi

  if run_compose -f "$OPENWEBUI_COMPOSE_FILE" up -d; then
    if container_running fortisai-openwebui; then
      return 0
    fi

    log "OpenWebUI compose completed without a running container; falling back to direct podman run"
  else
    log "OpenWebUI compose startup failed; falling back to direct podman run"
  fi

  podman rm -f fortisai-openwebui >/dev/null 2>&1 || true
  podman volume create fortisai-openwebui-data >/dev/null 2>&1 || true

  podman run -d \
    --name fortisai-openwebui \
    --restart unless-stopped \
    --network "$FORTISAI_SHARED_NETWORK" \
    -p "3000:8080" \
    -e WEBUI_AUTH=true \
    -e ENABLE_SIGNUP=true \
    -e ENABLE_OPENAI_API=true \
    -e AIOHTTP_CLIENT_TIMEOUT="$OPENWEBUI_AIOHTTP_CLIENT_TIMEOUT" \
    -e OPENAI_API_BASE_URL="$openwebui_openai_base_url" \
    -e OPENAI_API_KEY="$openwebui_openai_api_key" \
    -e FIRECRAWL_BASE_URL="$FIRECRAWL_INTERNAL_URL" \
    -e FIRECRAWL_API_KEY="$FIRECRAWL_API_KEY" \
    -e FORTISAI_SHARED_NETWORK="$FORTISAI_SHARED_NETWORK" \
    -e FORTISAI_ORACLE_DB_HOST="$ORACLE_DB_CONTAINER_NAME" \
    -e FORTISAI_ORACLE_DB_PORT="$ORACLE_DB_HOST_PORT" \
    -e FORTISAI_ORACLE_DB_PDB="$ORACLE_DB_PDB" \
    -e FORTISAI_ORACLE_DB_USER="$ORACLE_DB_USER" \
    -e FORTISAI_ORACLE_DB_PASSWORD="$ORACLE_DB_PASSWORD" \
    -e FORTISAI_REDIS_URL="redis://$REDIS_CONTAINER_NAME:6379" \
    -e FORTISAI_PGVECTOR_DSN="postgresql://$PGVECTOR_USER:$PGVECTOR_PASSWORD@$PGVECTOR_CONTAINER_NAME:5432/$PGVECTOR_DB" \
    -e FORTISAI_VAULT_ADDR="$VAULT_INTERNAL_URL" \
    -e VAULT_ADDR="$VAULT_INTERNAL_URL" \
    -e VAULT_TOKEN="$VAULT_TOKEN" \
    -v fortisai-openwebui-data:/app/backend/data \
    ghcr.io/open-webui/open-webui:main >/dev/null

  if ! container_running fortisai-openwebui; then
    err "OpenWebUI fallback runtime did not stay running"
    return 1
  fi

  log "OpenWebUI started using fallback runtime path"
}

stop_openwebui() {
  if [[ -f "$OPENWEBUI_COMPOSE_FILE" ]]; then
    run_compose -f "$OPENWEBUI_COMPOSE_FILE" down || true
  fi

  podman rm -f fortisai-openwebui >/dev/null 2>&1 || true
}

write_appsmith_compose() {
  mkdir -p "$APPSMITH_DIR"
  cat > "$APPSMITH_COMPOSE_FILE" <<YAML
services:
  appsmith:
    image: $APPSMITH_IMAGE
    container_name: $APPSMITH_CONTAINER_NAME
    restart: unless-stopped
    ports:
      - "$APPSMITH_HOST_PORT:80"
    environment:
      - APPSMITH_DB_URL=$APPSMITH_DB_URL
      - APPSMITH_MONGODB_URI=$APPSMITH_DB_URL
      - APPSMITH_POSTGRES_DB_URL=$APPSMITH_POSTGRES_DB_URL
      - APPSMITH_REDIS_URL=$APPSMITH_REDIS_URL
      - APPSMITH_DISABLE_TELEMETRY=$APPSMITH_DISABLE_TELEMETRY
      - APPSMITH_SEGMENT_CE_KEY=$APPSMITH_SEGMENT_CE_KEY
      - APPSMITH_PYLON_APP_ID=$APPSMITH_PYLON_APP_ID
      - APPSMITH_BETTERBUGS_API_KEY=$APPSMITH_BETTERBUGS_API_KEY
      - APPSMITH_CLOUD_SERVICES_BASE_URL=$APPSMITH_CLOUD_SERVICES_BASE_URL
      - FORTISAI_MONGODB_URL=$APPSMITH_DB_URL
      - FORTISAI_REDIS_URL=redis://$REDIS_CONTAINER_NAME:6379
      - FORTISAI_PGVECTOR_DSN=postgresql://$PGVECTOR_USER:$PGVECTOR_PASSWORD@$PGVECTOR_CONTAINER_NAME:5432/$PGVECTOR_DB
      - FORTISAI_VAULT_ADDR=$VAULT_INTERNAL_URL
      - VAULT_ADDR=$VAULT_INTERNAL_URL
      - VAULT_TOKEN=$VAULT_TOKEN
    volumes:
      - appsmith_stacks:/appsmith-stacks
    networks:
      - shared-net
volumes:
  appsmith_stacks:
networks:
  shared-net:
    name: $FORTISAI_SHARED_NETWORK
    external: true
YAML
}

write_mongodb_compose() {
  mkdir -p "$MONGODB_DIR"
  cat > "$MONGODB_COMPOSE_FILE" <<YAML
services:
  mongodb:
    image: $MONGODB_IMAGE
    container_name: $MONGODB_CONTAINER_NAME
    restart: unless-stopped
    command: ["mongod", "--bind_ip_all", "--replSet", "$MONGODB_REPLICA_SET"]
    ports:
      - "$MONGODB_HOST_PORT:27017"
    volumes:
      - mongodb_data:/data/db
    networks:
      - shared-net
volumes:
  mongodb_data:
networks:
  shared-net:
    name: $FORTISAI_SHARED_NETWORK
    external: true
YAML
}

wait_for_mongodb() {
  local attempts=30

  while (( attempts > 0 )); do
    if podman exec "$MONGODB_CONTAINER_NAME" mongosh --quiet --eval 'db.adminCommand({ ping: 1 }).ok' >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
    ((attempts--))
  done

  err "MongoDB did not become ready in time"
  return 1
}

ensure_mongodb_replica_set() {
  if ! container_running "$MONGODB_CONTAINER_NAME"; then
    err "MongoDB container is not running"
    return 1
  fi

  wait_for_mongodb || return 1

  if podman exec "$MONGODB_CONTAINER_NAME" mongosh --quiet --eval 'try { rs.status().ok } catch (e) { 0 }' | grep -q '^1$'; then
    return 0
  fi

  log "Initializing MongoDB replica set: $MONGODB_REPLICA_SET"
  podman exec "$MONGODB_CONTAINER_NAME" mongosh --quiet --eval "rs.initiate({_id: '$MONGODB_REPLICA_SET', members:[{_id: 0, host: '$MONGODB_CONTAINER_NAME:27017'}]})" >/dev/null 2>&1 || true

  local attempts=30
  while (( attempts > 0 )); do
    if podman exec "$MONGODB_CONTAINER_NAME" mongosh --quiet --eval 'try { rs.status().ok } catch (e) { 0 }' | grep -q '^1$'; then
      return 0
    fi
    sleep 2
    ((attempts--))
  done

  err "MongoDB replica set did not initialize in time"
  return 1
}

write_redis_compose() {
  mkdir -p "$REDIS_DIR"
  cat > "$REDIS_COMPOSE_FILE" <<YAML
services:
  redis:
    image: $REDIS_IMAGE
    container_name: $REDIS_CONTAINER_NAME
    restart: unless-stopped
    ports:
      - "$REDIS_HOST_PORT:6379"
    volumes:
      - redis_data:/data
    networks:
      - shared-net
volumes:
  redis_data:
networks:
  shared-net:
    name: $FORTISAI_SHARED_NETWORK
    external: true
YAML
}

write_rabbitmq_compose() {
  mkdir -p "$RABBITMQ_DIR"
  cat > "$RABBITMQ_COMPOSE_FILE" <<YAML
services:
  rabbitmq:
    image: $RABBITMQ_IMAGE
    container_name: $RABBITMQ_CONTAINER_NAME
    restart: unless-stopped
    ports:
      - "$RABBITMQ_HOST_PORT:5672"
      - "$RABBITMQ_MANAGEMENT_HOST_PORT:15672"
    environment:
      - RABBITMQ_DEFAULT_USER=$RABBITMQ_DEFAULT_USER
      - RABBITMQ_DEFAULT_PASS=$RABBITMQ_DEFAULT_PASSWORD
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
    networks:
      - shared-net
volumes:
  rabbitmq_data:
networks:
  shared-net:
    name: $FORTISAI_SHARED_NETWORK
    external: true
YAML
}

write_vault_compose() {
  mkdir -p "$VAULT_DIR/config" "$VAULT_DIR/file" "$VAULT_DIR/logs"
  chmod 700 "$VAULT_DIR" "$VAULT_DIR/file" 2>/dev/null || true

  cat > "$VAULT_CONFIG_FILE" <<HCL
ui = true
disable_mlock = true
api_addr = "$VAULT_API_ADDR"
cluster_addr = "http://$VAULT_CONTAINER_NAME:8201"

storage "file" {
  path = "/vault/file"
}

listener "tcp" {
  address = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  tls_disable = true
}
HCL

  cat > "$VAULT_COMPOSE_FILE" <<YAML
services:
  vault:
    image: $VAULT_IMAGE
    container_name: $VAULT_CONTAINER_NAME
    user: "0:0"
    restart: unless-stopped
    command: server
    ports:
      - "127.0.0.1:$VAULT_HOST_PORT:8200"
    environment:
      - VAULT_ADDR=http://127.0.0.1:8200
      - VAULT_API_ADDR=$VAULT_API_ADDR
      - SKIP_SETCAP=true
    volumes:
      - ./config:/vault/config
      - ./file:/vault/file
      - ./logs:/vault/logs
    networks:
      - shared-net
networks:
  shared-net:
    name: $FORTISAI_SHARED_NETWORK
    external: true
YAML
}

write_firecrawl_compose() {
  mkdir -p "$FIRECRAWL_DIR"
  cat > "$FIRECRAWL_COMPOSE_FILE" <<YAML
services:
  firecrawl:
    image: $FIRECRAWL_IMAGE
    container_name: $FIRECRAWL_CONTAINER_NAME
    restart: unless-stopped
    ports:
      - "$FIRECRAWL_HOST_PORT:3002"
    environment:
      - PORT=3002
      - HOST=0.0.0.0
      - FIRECRAWL_API_KEY=$FIRECRAWL_API_KEY
      - NUQ_DATABASE_URL=$FIRECRAWL_DATABASE_URL
      - NUQ_RABBITMQ_URL=$FIRECRAWL_RABBITMQ_URL
      - REDIS_URL=$FIRECRAWL_REDIS_URL
      - REDIS_EVICT_URL=$FIRECRAWL_REDIS_EVICT_URL
      - REDIS_RATE_LIMIT_URL=$FIRECRAWL_REDIS_RATE_LIMIT_URL
      - FORTISAI_VAULT_ADDR=$VAULT_INTERNAL_URL
      - VAULT_ADDR=$VAULT_INTERNAL_URL
      - VAULT_TOKEN=$VAULT_TOKEN
    networks:
      - shared-net
networks:
  shared-net:
    name: $FORTISAI_SHARED_NETWORK
    external: true
YAML
}

write_pgvector_compose() {
  mkdir -p "$PGVECTOR_DIR"
  cat > "$PGVECTOR_COMPOSE_FILE" <<YAML
services:
  pgvector:
    image: $PGVECTOR_IMAGE
    container_name: $PGVECTOR_CONTAINER_NAME
    restart: unless-stopped
    ports:
      - "$PGVECTOR_HOST_PORT:5432"
    environment:
      POSTGRES_DB: $PGVECTOR_DB
      POSTGRES_USER: $PGVECTOR_USER
      POSTGRES_PASSWORD: $PGVECTOR_PASSWORD
    volumes:
      - pgvector_data:/var/lib/postgresql/data
    networks:
      - shared-net
volumes:
  pgvector_data:
networks:
  shared-net:
    name: $FORTISAI_SHARED_NETWORK
    external: true
YAML
}

write_traefik_compose() {
  require_cmd openssl
  mkdir -p "$TRAEFIK_DIR"

  local dashboard_hash
  dashboard_hash="$(openssl passwd -apr1 "$TRAEFIK_DASHBOARD_PASSWORD")"
  printf '%s:%s\n' "$TRAEFIK_DASHBOARD_USER" "$dashboard_hash" > "$TRAEFIK_USERS_FILE"
  chmod 600 "$TRAEFIK_USERS_FILE" 2>/dev/null || true

  cat > "$TRAEFIK_STATIC_CONFIG_FILE" <<YAML
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
YAML

  cat > "$TRAEFIK_DYNAMIC_CONFIG_FILE" <<YAML
http:
  routers:
    dashboard:
      rule: "PathPrefix(\`/api\`) || PathPrefix(\`/dashboard\`)"
      entryPoints:
        - dashboard
      service: api@internal
      middlewares:
        - dashboard-auth
    openwebui:
      rule: "Host(\`openwebui.fortisai.localhost\`)"
      entryPoints:
        - web
      service: openwebui
    n8n:
      rule: "Host(\`n8n.fortisai.localhost\`)"
      entryPoints:
        - web
      service: n8n
    dify:
      rule: "Host(\`dify.fortisai.localhost\`)"
      entryPoints:
        - web
      service: dify
    codeindexer:
      rule: "Host(\`codeindexer.fortisai.localhost\`)"
      entryPoints:
        - web
      service: codeindexer
    openmetadata:
      rule: "Host(\`openmetadata.fortisai.localhost\`)"
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
          - url: "http://$OPENWEBUI_CONTAINER_NAME:8080"
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
          - url: "http://$CODEINDEXER_BRIDGE_CONTAINER_NAME:8096"
    openmetadata:
      loadBalancer:
        servers:
          - url: "http://$OPENMETADATA_CONTAINER_NAME:8585"
YAML

  cat > "$TRAEFIK_COMPOSE_FILE" <<YAML
services:
  traefik:
    image: $TRAEFIK_IMAGE
    container_name: $TRAEFIK_CONTAINER_NAME
    restart: unless-stopped
    ports:
      - "$TRAEFIK_WEB_HOST_PORT:8080"
      - "$TRAEFIK_DASHBOARD_HOST_PORT:8088"
    volumes:
      - ./traefik.yml:/etc/traefik/traefik.yml:ro
      - ./dynamic.yml:/etc/traefik/dynamic.yml:ro
      - ./users.htpasswd:/etc/traefik/users.htpasswd:ro
    environment:
      - FORTISAI_VAULT_ADDR=$VAULT_INTERNAL_URL
      - VAULT_ADDR=$VAULT_INTERNAL_URL
      - VAULT_TOKEN=$VAULT_TOKEN
    networks:
      - shared-net
networks:
  shared-net:
    name: $FORTISAI_SHARED_NETWORK
    external: true
YAML
}

write_milvus_compose() {
  mkdir -p "$MILVUS_DIR"
  cat > "$MILVUS_COMPOSE_FILE" <<YAML
services:
  etcd:
    image: $MILVUS_ETCD_IMAGE
    container_name: $MILVUS_ETCD_CONTAINER_NAME
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
    image: $MILVUS_MINIO_IMAGE
    container_name: $MILVUS_MINIO_CONTAINER_NAME
    restart: unless-stopped
    command: minio server /minio_data --console-address ":9001"
    environment:
      - MINIO_ROOT_USER=$MILVUS_MINIO_ROOT_USER
      - MINIO_ROOT_PASSWORD=$MILVUS_MINIO_ROOT_PASSWORD
    volumes:
      - milvus_minio:/minio_data
    networks:
      - shared-net

  milvus:
    image: $MILVUS_IMAGE
    container_name: $MILVUS_CONTAINER_NAME
    restart: unless-stopped
    command: ["milvus", "run", "standalone"]
    ports:
      - "$MILVUS_HOST_PORT:19530"
      - "$MILVUS_HEALTH_HOST_PORT:9091"
    environment:
      - ETCD_ENDPOINTS=$MILVUS_ETCD_CONTAINER_NAME:2379
      - MINIO_ADDRESS=$MILVUS_MINIO_CONTAINER_NAME:9000
      - FORTISAI_VAULT_ADDR=$VAULT_INTERNAL_URL
      - VAULT_ADDR=$VAULT_INTERNAL_URL
      - VAULT_TOKEN=$VAULT_TOKEN
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
    name: $FORTISAI_SHARED_NETWORK
    external: true
YAML
}

write_opensearch_compose() {
  mkdir -p "$OPENSEARCH_DIR"
  cat > "$OPENSEARCH_COMPOSE_FILE" <<YAML
services:
  opensearch:
    image: $OPENSEARCH_IMAGE
    container_name: $OPENSEARCH_CONTAINER_NAME
    restart: unless-stopped
    ports:
      - "$OPENSEARCH_HOST_PORT:9200"
      - "$OPENSEARCH_PERFORMANCE_HOST_PORT:9600"
    environment:
      - discovery.type=single-node
      - plugins.security.disabled=true
      - DISABLE_SECURITY_PLUGIN=true
      - OPENSEARCH_JAVA_OPTS=$OPENSEARCH_JAVA_OPTS
      - FORTISAI_VAULT_ADDR=$VAULT_INTERNAL_URL
      - VAULT_ADDR=$VAULT_INTERNAL_URL
      - VAULT_TOKEN=$VAULT_TOKEN
    volumes:
      - opensearch_data:/usr/share/opensearch/data
    networks:
      - shared-net
volumes:
  opensearch_data:
networks:
  shared-net:
    name: $FORTISAI_SHARED_NETWORK
    external: true
YAML
}

write_openmetadata_compose() {
  mkdir -p "$OPENMETADATA_DIR"
  cat > "$OPENMETADATA_COMPOSE_FILE" <<YAML
services:
  openmetadata:
    image: $OPENMETADATA_IMAGE
    container_name: $OPENMETADATA_CONTAINER_NAME
    restart: unless-stopped
    ports:
      - "$OPENMETADATA_HOST_PORT:8585"
      - "$OPENMETADATA_ADMIN_HOST_PORT:8586"
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
      - AUTHENTICATION_PUBLIC_KEYS=[http://$OPENMETADATA_CONTAINER_NAME:8585/api/v1/system/config/jwks]
      - PIPELINE_SERVICE_CLIENT_CLASS_NAME=org.openmetadata.service.clients.pipeline.noop.NoopClient
      - PIPELINE_SERVICE_CLIENT_ENDPOINT=http://$OPENMETADATA_CONTAINER_NAME:8585
      - SERVER_HOST_API_URL=http://$OPENMETADATA_CONTAINER_NAME:8585/api
      - DB_DRIVER_CLASS=org.postgresql.Driver
      - DB_SCHEME=postgresql
      - DB_PARAMS=sslmode=disable
      - DB_USE_SSL=false
      - DB_USER=$PGVECTOR_USER
      - DB_USER_PASSWORD=$PGVECTOR_PASSWORD
      - DB_HOST=$PGVECTOR_CONTAINER_NAME
      - DB_PORT=5432
      - OM_DATABASE=$OPENMETADATA_DB_NAME
      - ELASTICSEARCH_HOST=$OPENSEARCH_CONTAINER_NAME
      - ELASTICSEARCH_PORT=9200
      - ELASTICSEARCH_SCHEME=http
      - SEARCH_TYPE=opensearch
      - ELASTICSEARCH_USER=
      - ELASTICSEARCH_PASSWORD=
      - FERNET_KEY=$OPENMETADATA_FERNET_KEY
      - SECRET_MANAGER=db
      - OPENMETADATA_HEAP_OPTS=$OPENMETADATA_HEAP_OPTS
      - JWT_KEY_ID=$OPENMETADATA_JWT_KEY_ID
      - FORTISAI_VAULT_ADDR=$VAULT_INTERNAL_URL
      - VAULT_ADDR=$VAULT_INTERNAL_URL
      - VAULT_TOKEN=$VAULT_TOKEN
    networks:
      - shared-net
networks:
  shared-net:
    name: $FORTISAI_SHARED_NETWORK
    external: true
YAML
}

write_oracle_db_compose() {
  mkdir -p "$ORACLE_DB_STARTUP_DIR"

  if [[ ! -f "$ORACLE_DB_STARTUP_DIR/01-fortisai-app-user.sql" ]]; then
    cat > "$ORACLE_DB_STARTUP_DIR/01-fortisai-app-user.sql" <<'SQL'
whenever sqlerror exit failure rollback;
declare
  user_count integer;
begin
  select count(*) into user_count from dba_users where username = 'FORTISAI_APP';
  if user_count = 0 then
    execute immediate q'[create user fortisai_app identified by "FortisAI26ai!2026" default tablespace users temporary tablespace temp quota unlimited on users]';
    execute immediate 'grant create session, create table, create view, create sequence, create procedure to fortisai_app';
  end if;
end;
/
SQL
  fi

  mkdir -p "$ORACLE_DB_DIR"
  cat > "$ORACLE_DB_COMPOSE_FILE" <<YAML
services:
  oracle-db:
    image: $ORACLE_DB_IMAGE
    container_name: $ORACLE_DB_CONTAINER_NAME
    restart: unless-stopped
    ports:
      - "$ORACLE_DB_HOST_PORT:1521"
    environment:
      ORACLE_PWD: $ORACLE_DB_PASSWORD
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
    name: $FORTISAI_SHARED_NETWORK
    external: true
YAML
}

write_ords_compose() {
  mkdir -p "$ORDS_DIR"
  cat > "$ORDS_COMPOSE_FILE" <<YAML
services:
  ords:
    image: $ORDS_IMAGE
    container_name: $ORDS_CONTAINER_NAME
    restart: unless-stopped
    ports:
      - "$ORDS_HOST_PORT:8080"
    env_file:
      - $ORACLE_DB_WALLET_ENV_FILE
    environment:
      - ORACLE_WALLET_DIR=/opt/oracle/wallet
      - TNS_ADMIN=/opt/oracle/wallet
    volumes:
      - $ORDS_CONFIG_VOLUME:/etc/ords/config
      - $ORACLE_WALLET_DIR:/opt/oracle/wallet:ro
    networks:
      - shared-net
volumes:
  $ORDS_CONFIG_VOLUME:
    external: true
networks:
  shared-net:
    name: $FORTISAI_SHARED_NETWORK
    external: true
YAML
}

write_sqlcl_compose() {
  mkdir -p "$SQLCL_DIR"
  cat > "$SQLCL_COMPOSE_FILE" <<YAML
services:
  sqlcl:
    image: $SQLCL_IMAGE
    container_name: $SQLCL_CONTAINER_NAME
    restart: unless-stopped
    env_file:
      - $ORACLE_DB_WALLET_ENV_FILE
    environment:
      - ORACLE_WALLET_DIR=/opt/oracle/wallet
      - TNS_ADMIN=/opt/oracle/wallet
    entrypoint: ["/bin/sh", "-lc", "tail -f /dev/null"]
    volumes:
      - $ORACLE_WALLET_DIR:/opt/oracle/wallet:ro
    networks:
      - shared-net
networks:
  shared-net:
    name: $FORTISAI_SHARED_NETWORK
    external: true
YAML
}

write_honcho_compose() {
  mkdir -p "$HONCHO_DIR"
  cat > "$HONCHO_COMPOSE_FILE" <<YAML
services:
  api:
    build:
      context: $HONCHO_REPO_DIR
      dockerfile: Dockerfile
    container_name: $HONCHO_API_CONTAINER_NAME
    entrypoint: ["sh", "docker/entrypoint.sh"]
    restart: unless-stopped
    ports:
      - "$HONCHO_HOST_PORT:8000"
    env_file:
      - $HONCHO_REPO_DIR/.env
    environment:
      - DB_CONNECTION_URI=postgresql+psycopg://$PGVECTOR_USER:$PGVECTOR_PASSWORD@$PGVECTOR_CONTAINER_NAME:5432/$HONCHO_DB
      - CACHE_URL=redis://$REDIS_CONTAINER_NAME:6379/0?suppress=true
      - CACHE_ENABLED=true
      - VECTOR_STORE_TYPE=pgvector
      - FORTISAI_VAULT_ADDR=$VAULT_INTERNAL_URL
      - VAULT_ADDR=$VAULT_INTERNAL_URL
      - VAULT_TOKEN=$VAULT_TOKEN
    networks:
      - shared-net

  deriver:
    build:
      context: $HONCHO_REPO_DIR
      dockerfile: Dockerfile
    container_name: $HONCHO_DERIVER_CONTAINER_NAME
    entrypoint: ["/app/.venv/bin/python", "-m", "src.deriver"]
    restart: unless-stopped
    env_file:
      - $HONCHO_REPO_DIR/.env
    environment:
      - DB_CONNECTION_URI=postgresql+psycopg://$PGVECTOR_USER:$PGVECTOR_PASSWORD@$PGVECTOR_CONTAINER_NAME:5432/$HONCHO_DB
      - CACHE_URL=redis://$REDIS_CONTAINER_NAME:6379/0?suppress=true
      - CACHE_ENABLED=true
      - VECTOR_STORE_TYPE=pgvector
      - FORTISAI_VAULT_ADDR=$VAULT_INTERNAL_URL
      - VAULT_ADDR=$VAULT_INTERNAL_URL
      - VAULT_TOKEN=$VAULT_TOKEN
    networks:
      - shared-net

networks:
  shared-net:
    name: $FORTISAI_SHARED_NETWORK
    external: true
YAML
}

write_openclaw_compose() {
  mkdir -p "$OPENCLAW_DIR"
  local runtime_config_name
  runtime_config_name="$(basename "$OPENCLAW_RUNTIME_CONFIG_FILE")"
  cat > "$OPENCLAW_COMPOSE_FILE" <<YAML
services:
  claw-gateway:
    image: $OPENCLAW_IMAGE
    container_name: $OPENCLAW_CONTAINER_NAME
    restart: unless-stopped
    ports:
      - "$OPENCLAW_GATEWAY_PORT:18789"
      - "$OPENCLAW_BRIDGE_PORT:18790"
    environment:
      - OPENCLAW_CONFIG_PATH=/home/node/.openclaw/$runtime_config_name
      - OPENCLAW_GATEWAY_PORT=18789
      - OPENCLAW_BRIDGE_PORT=18790
      - OPENCLAW_GATEWAY_BIND=$OPENCLAW_GATEWAY_BIND
      - OPENCLAW_GATEWAY_TOKEN=$OPENCLAW_GATEWAY_TOKEN
      - OPENCLAW_GATEWAY_PASSWORD=$OPENCLAW_GATEWAY_PASSWORD
      - OPENAI_API_KEY=$OPENCLAW_OPENAI_API_KEY
      - OPENAI_BASE_URL=$OPENCLAW_LMSTUDIO_BASE_URL
      - FIRECRAWL_BASE_URL=$FIRECRAWL_INTERNAL_URL
      - FIRECRAWL_API_KEY=$FIRECRAWL_API_KEY
      - FORTISAI_VAULT_ADDR=$VAULT_INTERNAL_URL
      - VAULT_ADDR=$VAULT_INTERNAL_URL
      - VAULT_TOKEN=$VAULT_TOKEN
    volumes:
      - $OPENCLAW_DIR:/home/node/.openclaw
    entrypoint:
      - /bin/sh
      - -lc
      - |
        set -e
        a=open
        b=claw
        p="\${a}\${b}"
        command -v "\$p" >/dev/null 2>&1 || npm install -g "\$p" >/dev/null 2>&1
        if [ -n "$OPENCLAW_HONCHO_PLUGIN_PACKAGE" ] && ! npm list -g "$OPENCLAW_HONCHO_PLUGIN_PACKAGE" >/dev/null 2>&1; then
          timeout 120 npm install -g "$OPENCLAW_HONCHO_PLUGIN_PACKAGE" >/dev/null 2>&1 || true
        fi
        exec "\$p" gateway run --allow-unconfigured --token "\$OPENCLAW_GATEWAY_TOKEN"
    networks:
      - shared-net
networks:
  shared-net:
    name: $FORTISAI_SHARED_NETWORK
    external: true
YAML
}

write_hermes_compose() {
  mkdir -p "$HERMES_DIR"
  touch "$HERMES_DIR/.env"
  upsert_env_var "$HERMES_DIR/.env" "WHATSAPP_ENABLED" "$HERMES_WHATSAPP_ENABLED"
  chmod 600 "$HERMES_DIR/.env" >/dev/null 2>&1 || true
  cat > "$HERMES_COMPOSE_FILE" <<YAML
services:
  hermes:
    image: $HERMES_IMAGE
    container_name: $HERMES_CONTAINER_NAME
    restart: unless-stopped
    command:
      - gateway
      - run
    ports:
      - "$HERMES_GATEWAY_PORT:8642"
      - "$HERMES_DASHBOARD_PORT:9119"
    environment:
      - HERMES_DASHBOARD=$HERMES_DASHBOARD
      - HERMES_DASHBOARD_INSECURE=true
      - API_SERVER_ENABLED=$HERMES_API_SERVER_ENABLED
      - API_SERVER_HOST=$HERMES_API_SERVER_HOST
      - API_SERVER_KEY=$HERMES_API_SERVER_KEY
      - API_SERVER_CORS_ORIGINS=$HERMES_API_SERVER_CORS_ORIGINS
      - OPENAI_BASE_URL=$HERMES_OPENAI_BASE_URL
      - OPENAI_API_BASE_URL=$HERMES_OPENAI_BASE_URL
      - OPENAI_API_KEY=$HERMES_OPENAI_API_KEY
      - OPENAI_MODEL=$HERMES_OPENAI_MODEL
      - HERMES_OPENAI_BASE_URL=$HERMES_OPENAI_BASE_URL
      - HERMES_OPENAI_API_KEY=$HERMES_OPENAI_API_KEY
      - HERMES_OPENAI_MODEL=$HERMES_OPENAI_MODEL
      - WHATSAPP_ENABLED=$HERMES_WHATSAPP_ENABLED
      - FORTISAI_PROXY_OPENAI_BASE_URL=$FORTISAI_PROXY_OPENAI_BASE_URL
      - FORTISAI_PROXY_OPENAI_MODEL=$FORTISAI_PROXY_OPENAI_MODEL
      - FORTISAI_HONCHO_BASE_URL=$HERMES_HONCHO_BASE_URL
      - FORTISAI_HONCHO_WORKSPACE_ID=$HERMES_HONCHO_WORKSPACE_ID
      - FORTISAI_HONCHO_API_KEY=$HERMES_HONCHO_API_KEY
      - FORTISAI_DAYTONA_DASHBOARD_URL=$HERMES_DAYTONA_DASHBOARD_URL
      - FORTISAI_DAYTONA_API_URL=$HERMES_DAYTONA_API_URL
      - FORTISAI_FIRECRAWL_BASE_URL=$FIRECRAWL_INTERNAL_URL
      - FORTISAI_FIRECRAWL_API_KEY=$FIRECRAWL_API_KEY
      - FORTISAI_VAULT_ADDR=$VAULT_INTERNAL_URL
      - VAULT_ADDR=$VAULT_INTERNAL_URL
      - VAULT_TOKEN=$VAULT_TOKEN
    volumes:
      - $HERMES_DIR:/opt/data
    networks:
      - shared-net
networks:
  shared-net:
    name: $FORTISAI_SHARED_NETWORK
    external: true
YAML
}

setup_honcho_repo() {
  require_cmd git

  local honcho_model
  honcho_model="$HONCHO_LMSTUDIO_MODEL"

  mkdir -p "$HONCHO_DIR"
  if [[ ! -d "$HONCHO_REPO_DIR/.git" ]]; then
    log "Cloning Honcho repository"
    git clone https://github.com/plastic-labs/honcho.git "$HONCHO_REPO_DIR"
  else
    log "Honcho repository already exists at $HONCHO_REPO_DIR"
  fi

  if [[ ! -f "$HONCHO_REPO_DIR/.env" ]]; then
    if [[ -f "$HONCHO_REPO_DIR/.env.template" ]]; then
      log "Creating Honcho .env from template"
      cp "$HONCHO_REPO_DIR/.env.template" "$HONCHO_REPO_DIR/.env"
    else
      err "Honcho .env.template was not found in $HONCHO_REPO_DIR"
      exit 1
    fi
  fi

  upsert_env_var "$HONCHO_REPO_DIR/.env" "DB_CONNECTION_URI" "postgresql+psycopg://$PGVECTOR_USER:$PGVECTOR_PASSWORD@$PGVECTOR_CONTAINER_NAME:5432/$HONCHO_DB"
  upsert_env_var "$HONCHO_REPO_DIR/.env" "CACHE_ENABLED" "true"
  upsert_env_var "$HONCHO_REPO_DIR/.env" "CACHE_URL" "redis://$REDIS_CONTAINER_NAME:6379/0?suppress=true"
  upsert_env_var "$HONCHO_REPO_DIR/.env" "VECTOR_STORE_TYPE" "pgvector"
  upsert_env_var "$HONCHO_REPO_DIR/.env" "FORTISAI_VAULT_ADDR" "$VAULT_INTERNAL_URL"
  upsert_env_var "$HONCHO_REPO_DIR/.env" "VAULT_ADDR" "$VAULT_INTERNAL_URL"
  if [[ -n "$VAULT_TOKEN" ]]; then
    upsert_env_var "$HONCHO_REPO_DIR/.env" "VAULT_TOKEN" "$VAULT_TOKEN"
  fi
  upsert_env_var "$HONCHO_REPO_DIR/.env" "AUTH_USE_AUTH" "false"
  upsert_env_var "$HONCHO_REPO_DIR/.env" "LLM_OPENAI_API_KEY" "$HONCHO_LLM_OPENAI_API_KEY"

  if [[ -z "$honcho_model" || "$honcho_model" == "auto" ]]; then
    if command -v curl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
      honcho_model="$(curl -fsS "$HONCHO_LMSTUDIO_MODELS_URL" 2>/dev/null | jq -r '.data[0].id // empty' 2>/dev/null || true)"
    fi
  fi

  if [[ -z "$honcho_model" ]]; then
    honcho_model="local-model"
    log "LM Studio model auto-detection failed; using fallback model id: $honcho_model"
  else
    log "Using Honcho LM Studio model id: $honcho_model"
  fi

  upsert_env_var "$HONCHO_REPO_DIR/.env" "EMBED_MESSAGES" "$HONCHO_EMBED_MESSAGES"
  upsert_env_var "$HONCHO_REPO_DIR/.env" "DERIVER_MODEL_CONFIG__TRANSPORT" "openai"
  upsert_env_var "$HONCHO_REPO_DIR/.env" "DERIVER_MODEL_CONFIG__MODEL" "$honcho_model"
  upsert_env_var "$HONCHO_REPO_DIR/.env" "DERIVER_MODEL_CONFIG__OVERRIDES__BASE_URL" "$HONCHO_LMSTUDIO_BASE_URL"
  upsert_env_var "$HONCHO_REPO_DIR/.env" "SUMMARY_MODEL_CONFIG__TRANSPORT" "openai"
  upsert_env_var "$HONCHO_REPO_DIR/.env" "SUMMARY_MODEL_CONFIG__MODEL" "$honcho_model"
  upsert_env_var "$HONCHO_REPO_DIR/.env" "SUMMARY_MODEL_CONFIG__OVERRIDES__BASE_URL" "$HONCHO_LMSTUDIO_BASE_URL"
  upsert_env_var "$HONCHO_REPO_DIR/.env" "DREAM_DEDUCTION_MODEL_CONFIG__TRANSPORT" "openai"
  upsert_env_var "$HONCHO_REPO_DIR/.env" "DREAM_DEDUCTION_MODEL_CONFIG__MODEL" "$honcho_model"
  upsert_env_var "$HONCHO_REPO_DIR/.env" "DREAM_DEDUCTION_MODEL_CONFIG__OVERRIDES__BASE_URL" "$HONCHO_LMSTUDIO_BASE_URL"
  upsert_env_var "$HONCHO_REPO_DIR/.env" "DREAM_INDUCTION_MODEL_CONFIG__TRANSPORT" "openai"
  upsert_env_var "$HONCHO_REPO_DIR/.env" "DREAM_INDUCTION_MODEL_CONFIG__MODEL" "$honcho_model"
  upsert_env_var "$HONCHO_REPO_DIR/.env" "DREAM_INDUCTION_MODEL_CONFIG__OVERRIDES__BASE_URL" "$HONCHO_LMSTUDIO_BASE_URL"

  local dialectic_level
  for dialectic_level in minimal low medium high max; do
    upsert_env_var "$HONCHO_REPO_DIR/.env" "DIALECTIC_LEVELS__${dialectic_level}__MODEL_CONFIG__TRANSPORT" "openai"
    upsert_env_var "$HONCHO_REPO_DIR/.env" "DIALECTIC_LEVELS__${dialectic_level}__MODEL_CONFIG__MODEL" "$honcho_model"
    upsert_env_var "$HONCHO_REPO_DIR/.env" "DIALECTIC_LEVELS__${dialectic_level}__MODEL_CONFIG__OVERRIDES__BASE_URL" "$HONCHO_LMSTUDIO_BASE_URL"
  done
}

setup_openapi_servers_repo() {
  require_cmd git

  mkdir -p "$OPENAPI_SERVERS_DIR"
  if [[ ! -d "$OPENAPI_SERVERS_REPO_DIR/.git" ]]; then
    log "Cloning OpenAPI servers repository"
    git clone https://github.com/open-webui/openapi-servers.git "$OPENAPI_SERVERS_REPO_DIR"
  else
    log "OpenAPI servers repository already exists at $OPENAPI_SERVERS_REPO_DIR"
  fi

  if [[ ! -f "$OPENAPI_SERVERS_COMPOSE_FILE" ]]; then
    err "OpenAPI servers compose file not found: $OPENAPI_SERVERS_COMPOSE_FILE"
    exit 1
  fi
}

write_openapi_servers_openwebui_template() {
  mkdir -p "$OPENAPI_SERVERS_DIR"
  local mcp_sqlcl_base_url mcp_n8n_base_url mcp_dify_base_url mcp_codeindexer_base_url mcp_proxmox_base_url
  mcp_sqlcl_base_url="${MCP_SQLCL_OPENAPI_URL%/openapi.json}"
  mcp_n8n_base_url="${MCP_N8N_OPENAPI_URL%/openapi.json}"
  mcp_dify_base_url="${MCP_DIFY_OPENAPI_URL%/openapi.json}"
  mcp_codeindexer_base_url="${MCP_CODEINDEXER_OPENAPI_URL%/openapi.json}"
  mcp_proxmox_base_url="${MCP_PROXMOX_OPENAPI_URL%/openapi.json}"

  cat > "$OPENAPI_SERVERS_ENV_TEMPLATE_FILE" <<EOF
# Open WebUI OpenAPI Tool Servers template
OPENAPI_FILESYSTEM_URL=$OPENAPI_FILESYSTEM_URL
OPENAPI_MEMORY_URL=$OPENAPI_MEMORY_URL
OPENAPI_TIME_URL=$OPENAPI_TIME_URL
OPENAPI_FILESYSTEM_OPENWEBUI_URL=$OPENAPI_FILESYSTEM_OPENWEBUI_URL
OPENAPI_MEMORY_OPENWEBUI_URL=$OPENAPI_MEMORY_OPENWEBUI_URL
OPENAPI_TIME_OPENWEBUI_URL=$OPENAPI_TIME_OPENWEBUI_URL
OPENAPI_MCP_SQLCL_URL=$mcp_sqlcl_base_url
OPENAPI_MCP_N8N_URL=$mcp_n8n_base_url
OPENAPI_MCP_DIFY_URL=$mcp_dify_base_url
OPENAPI_MCP_CODEINDEXER_URL=$mcp_codeindexer_base_url
OPENAPI_MCP_PROXMOX_URL=$mcp_proxmox_base_url
EOF

  cat > "$OPENAPI_SERVERS_JSON_TEMPLATE_FILE" <<EOF
[
  {
    "name": "repo-filesystem-server",
    "base_url": "$OPENAPI_FILESYSTEM_OPENWEBUI_URL",
    "openapi_url": "$OPENAPI_FILESYSTEM_OPENWEBUI_URL/openapi.json"
  },
  {
    "name": "repo-memory-server",
    "base_url": "$OPENAPI_MEMORY_OPENWEBUI_URL",
    "openapi_url": "$OPENAPI_MEMORY_OPENWEBUI_URL/openapi.json"
  },
  {
    "name": "repo-time-server",
    "base_url": "$OPENAPI_TIME_OPENWEBUI_URL",
    "openapi_url": "$OPENAPI_TIME_OPENWEBUI_URL/openapi.json"
  },
  {
    "name": "mcp-sqlcl-server",
    "base_url": "$mcp_sqlcl_base_url",
    "openapi_url": "$MCP_SQLCL_OPENAPI_URL"
  },
  {
    "name": "mcp-n8n-server",
    "base_url": "$mcp_n8n_base_url",
    "openapi_url": "$MCP_N8N_OPENAPI_URL"
  },
  {
    "name": "mcp-dify-server",
    "base_url": "$mcp_dify_base_url",
    "openapi_url": "$MCP_DIFY_OPENAPI_URL"
  },
  {
    "name": "mcp-codeindexer-server",
    "base_url": "$mcp_codeindexer_base_url",
    "openapi_url": "$MCP_CODEINDEXER_OPENAPI_URL"
  },
  {
    "name": "mcp-proxmox-server",
    "base_url": "$mcp_proxmox_base_url",
    "openapi_url": "$MCP_PROXMOX_OPENAPI_URL"
  }
]
EOF

  log "Wrote OpenAPI server templates for Open WebUI:"
  log "- $OPENAPI_SERVERS_ENV_TEMPLATE_FILE"
  log "- $OPENAPI_SERVERS_JSON_TEMPLATE_FILE"
}

ensure_honcho_database() {
  if ! container_running "$PGVECTOR_CONTAINER_NAME"; then
    err "pgvector container is not running. Start it with: $SCRIPT_NAME up"
    exit 1
  fi

  local exists
  exists="$(podman exec "$PGVECTOR_CONTAINER_NAME" psql -U "$PGVECTOR_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${HONCHO_DB}';" 2>/dev/null | tr -d '[:space:]' || true)"

  if [[ "$exists" == "1" ]]; then
    log "Honcho database already exists: $HONCHO_DB"
    return
  fi

  log "Creating dedicated Honcho database in pgvector: $HONCHO_DB"
  podman exec "$PGVECTOR_CONTAINER_NAME" psql -U "$PGVECTOR_USER" -d postgres -c "CREATE DATABASE \"${HONCHO_DB}\" OWNER \"${PGVECTOR_USER}\";" >/dev/null
}

ensure_firecrawl_database() {
  if ! container_running "$PGVECTOR_CONTAINER_NAME"; then
    err "pgvector container is not running. Start it with: $SCRIPT_NAME up"
    exit 1
  fi

  local exists
  exists="$(podman exec "$PGVECTOR_CONTAINER_NAME" psql -U "$PGVECTOR_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${FIRECRAWL_DB_NAME}';" 2>/dev/null | tr -d '[:space:]' || true)"

  if [[ "$exists" == "1" ]]; then
    log "Firecrawl database already exists: $FIRECRAWL_DB_NAME"
  else
    log "Creating dedicated Firecrawl database in pgvector: $FIRECRAWL_DB_NAME"
    if ! podman exec "$PGVECTOR_CONTAINER_NAME" psql -U "$PGVECTOR_USER" -d postgres -c "CREATE DATABASE \"${FIRECRAWL_DB_NAME}\" OWNER \"${PGVECTOR_USER}\";" >/dev/null 2>&1; then
      local exists_after_create
      exists_after_create="$(podman exec "$PGVECTOR_CONTAINER_NAME" psql -U "$PGVECTOR_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${FIRECRAWL_DB_NAME}';" 2>/dev/null | tr -d '[:space:]' || true)"
      if [[ "$exists_after_create" == "1" ]]; then
        log "Firecrawl database already exists: $FIRECRAWL_DB_NAME"
      else
        err "Failed to create Firecrawl database: $FIRECRAWL_DB_NAME"
        return 1
      fi
    fi
  fi

  local nuq_sql_file
  nuq_sql_file="$FIRECRAWL_DIR/nuq.sql"
  log "Fetching Firecrawl NUQ schema: $FIRECRAWL_NUQ_SQL_URL"
  if curl -fsSL "$FIRECRAWL_NUQ_SQL_URL" -o "$nuq_sql_file"; then
    # Apply canonical NUQ schema; non-critical tuning/cron statements may fail on shared local Postgres.
    log "Applying Firecrawl NUQ schema to database: $FIRECRAWL_DB_NAME"
    podman exec -i "$PGVECTOR_CONTAINER_NAME" psql -U "$PGVECTOR_USER" -d "$FIRECRAWL_DB_NAME" < "$nuq_sql_file" >/dev/null 2>&1 || true
  else
    log "Unable to fetch NUQ schema; Firecrawl may restart if schema is missing"
  fi
}

ensure_postgres_database() {
  local db_name="$1"

  if ! container_running "$PGVECTOR_CONTAINER_NAME"; then
    err "pgvector container is not running. Start it with: $SCRIPT_NAME up"
    return 1
  fi

  local exists
  exists="$(podman exec "$PGVECTOR_CONTAINER_NAME" psql -U "$PGVECTOR_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${db_name}';" 2>/dev/null | tr -d '[:space:]' || true)"
  if [[ "$exists" == "1" ]]; then
    log "Postgres database already exists: $db_name"
    return 0
  fi

  log "Creating Postgres database in pgvector: $db_name"
  podman exec "$PGVECTOR_CONTAINER_NAME" psql -U "$PGVECTOR_USER" -d postgres -c "CREATE DATABASE \"${db_name}\" OWNER \"${PGVECTOR_USER}\";" >/dev/null
}

wait_for_http_status() {
  local url="$1"
  local label="$2"
  local expected="${3:-200}"
  local timeout_seconds="${4:-120}"
  local waited=0
  local status

  while (( waited < timeout_seconds )); do
    status="$(curl -sS -o /dev/null -w '%{http_code}' "$url" 2>/dev/null || echo 000)"
    if [[ "$status" == "$expected" ]]; then
      log "$label ready (HTTP $status)"
      return 0
    fi
    sleep 3
    waited=$((waited + 3))
  done

  log "$label did not report HTTP $expected within ${timeout_seconds}s"
  return 1
}

patch_codeindexer_for_fortisai() {
  local mcp_file="$CODEINDEXER_REPO_DIR/packages/mcp/src/index.ts"
  local openai_embedding_file="$CODEINDEXER_REPO_DIR/packages/core/src/embedding/openai-embedding.ts"

  [[ -f "$mcp_file" && -f "$openai_embedding_file" ]] || {
    err "CodeIndexer source files not found under $CODEINDEXER_REPO_DIR"
    return 1
  }

  CODEINDEXER_REPO_DIR="$CODEINDEXER_REPO_DIR" python3 - <<'PY'
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
PY
}

setup_codeindexer_repo() {
  require_cmd git
  mkdir -p "$CODEINDEXER_DIR" "$CODEINDEXER_STATE_DIR"
  if [[ ! -d "$CODEINDEXER_REPO_DIR/.git" ]]; then
    log "Cloning CodeIndexer repository"
    git clone "$CODEINDEXER_REPO_URL" "$CODEINDEXER_REPO_DIR"
  else
    log "CodeIndexer repository already exists at $CODEINDEXER_REPO_DIR"
  fi
  patch_codeindexer_for_fortisai
}

build_codeindexer_mcp() {
  setup_codeindexer_repo
  if [[ -f "$CODEINDEXER_REPO_DIR/packages/mcp/dist/index.js" ]]; then
    log "CodeIndexer MCP build already exists"
    return 0
  fi

  log "Building CodeIndexer MCP package with Node 20"
  podman run --rm \
    --network "$FORTISAI_SHARED_NETWORK" \
    -v "$CODEINDEXER_REPO_DIR:/codeindexer" \
    -w /codeindexer \
    docker.io/node:20-bookworm \
    sh -lc "corepack enable && corepack prepare pnpm@10.0.0 --activate && pnpm install --frozen-lockfile && pnpm --filter @code-indexer/mcp... build"
}

milvus_up() {
  ensure_machine
  ensure_shared_network
  write_milvus_compose
  if container_running "$MILVUS_ETCD_CONTAINER_NAME" &&
     container_running "$MILVUS_MINIO_CONTAINER_NAME" &&
     container_running "$MILVUS_CONTAINER_NAME"; then
    wait_for_http_status "$MILVUS_URL" "Milvus" "200" 180 || true
    return 0
  fi

  if container_exists "$MILVUS_ETCD_CONTAINER_NAME" ||
     container_exists "$MILVUS_MINIO_CONTAINER_NAME" ||
     container_exists "$MILVUS_CONTAINER_NAME"; then
    podman rm -f "$MILVUS_ETCD_CONTAINER_NAME" "$MILVUS_MINIO_CONTAINER_NAME" "$MILVUS_CONTAINER_NAME" >/dev/null 2>&1 || true
    wait_for_container_absence "$MILVUS_CONTAINER_NAME" 10 || true
  fi

  log "Starting Milvus for CodeIndexer"
  run_compose -f "$MILVUS_COMPOSE_FILE" up -d
  wait_for_http_status "$MILVUS_URL" "Milvus" "200" 180 || true
}

milvus_down() {
  ensure_machine
  if [[ -f "$MILVUS_COMPOSE_FILE" ]]; then
    log "Stopping Milvus"
    run_compose -f "$MILVUS_COMPOSE_FILE" down >/dev/null 2>&1 || true
  fi
}

codeindexer_up() {
  setup
  prepare_vault_runtime_secrets
  write_milvus_compose
  milvus_up
  build_codeindexer_mcp
  log "CodeIndexer MCP build ready; run mcp-up to start the OpenAPI bridge"
}

codeindexer_down() {
  ensure_machine
  podman rm -f "$CODEINDEXER_BRIDGE_CONTAINER_NAME" >/dev/null 2>&1 || true
  milvus_down
}

codeindexer_check() {
  require_cmd curl
  log "Checking CodeIndexer bridge: $CODEINDEXER_OPENAPI_URL/healthz"
  curl -sS -o /dev/null -w 'codeindexer_bridge HTTP %{http_code}\n' "$CODEINDEXER_OPENAPI_URL/healthz" || true
  log "Checking Milvus: $MILVUS_URL"
  curl -sS -o /dev/null -w 'milvus HTTP %{http_code}\n' "$MILVUS_URL" || true
}

opensearch_up() {
  ensure_machine
  ensure_shared_network
  write_opensearch_compose
  log "Starting OpenSearch for OpenMetadata"
  start_compose_container "$OPENSEARCH_COMPOSE_FILE" "$OPENSEARCH_CONTAINER_NAME"
  wait_for_http_status "$OPENSEARCH_URL" "OpenSearch" "200" 180 || true
}

opensearch_down() {
  ensure_machine
  if [[ -f "$OPENSEARCH_COMPOSE_FILE" ]]; then
    log "Stopping OpenSearch"
    run_compose -f "$OPENSEARCH_COMPOSE_FILE" down >/dev/null 2>&1 || true
  fi
}

openmetadata_migrate() {
  log "Running OpenMetadata database migration"
  podman rm -f fortisai-openmetadata-migrate >/dev/null 2>&1 || true
  podman run --rm --name fortisai-openmetadata-migrate \
    --network "$FORTISAI_SHARED_NETWORK" \
    -e DB_DRIVER_CLASS=org.postgresql.Driver \
    -e DB_SCHEME=postgresql \
    -e DB_PARAMS=sslmode=disable \
    -e DB_USE_SSL=false \
    -e DB_USER="$PGVECTOR_USER" \
    -e DB_USER_PASSWORD="$PGVECTOR_PASSWORD" \
    -e DB_HOST="$PGVECTOR_CONTAINER_NAME" \
    -e DB_PORT=5432 \
    -e OM_DATABASE="$OPENMETADATA_DB_NAME" \
    -e ELASTICSEARCH_HOST="$OPENSEARCH_CONTAINER_NAME" \
    -e ELASTICSEARCH_PORT=9200 \
    -e ELASTICSEARCH_SCHEME=http \
    -e SEARCH_TYPE=opensearch \
    -e FERNET_KEY="$OPENMETADATA_FERNET_KEY" \
    -e PIPELINE_SERVICE_CLIENT_CLASS_NAME=org.openmetadata.service.clients.pipeline.noop.NoopClient \
    "$OPENMETADATA_IMAGE" ./bootstrap/openmetadata-ops.sh migrate
}

openmetadata_up() {
  setup
  prepare_vault_runtime_secrets
  write_pgvector_compose
  start_compose_container "$PGVECTOR_COMPOSE_FILE" "$PGVECTOR_CONTAINER_NAME"
  ensure_postgres_database "$OPENMETADATA_DB_NAME"
  opensearch_up
  write_openmetadata_compose
  openmetadata_migrate
  log "Starting OpenMetadata"
  start_compose_container "$OPENMETADATA_COMPOSE_FILE" "$OPENMETADATA_CONTAINER_NAME"
  wait_for_http_status "$OPENMETADATA_URL/api/v1/system/version" "OpenMetadata" "200" 240 || true
}

openmetadata_down() {
  ensure_machine
  if [[ -f "$OPENMETADATA_COMPOSE_FILE" ]]; then
    log "Stopping OpenMetadata"
    run_compose -f "$OPENMETADATA_COMPOSE_FILE" down >/dev/null 2>&1 || true
  fi
  opensearch_down
}

openmetadata_check() {
  require_cmd curl
  log "Checking OpenMetadata: $OPENMETADATA_URL/api/v1/system/version"
  curl -sS -o /dev/null -w 'openmetadata HTTP %{http_code}\n' "$OPENMETADATA_URL/api/v1/system/version" || true
  log "Checking OpenSearch: $OPENSEARCH_URL"
  curl -sS -o /dev/null -w 'opensearch HTTP %{http_code}\n' "$OPENSEARCH_URL" || true
}

traefik_up() {
  setup
  prepare_vault_runtime_secrets
  write_traefik_compose
  log "Starting Traefik"
  start_compose_container "$TRAEFIK_COMPOSE_FILE" "$TRAEFIK_CONTAINER_NAME"
  wait_for_http_status "$TRAEFIK_DASHBOARD_URL" "Traefik dashboard" "401" 60 || true
}

traefik_down() {
  ensure_machine
  if [[ -f "$TRAEFIK_COMPOSE_FILE" ]]; then
    log "Stopping Traefik"
    run_compose -f "$TRAEFIK_COMPOSE_FILE" down >/dev/null 2>&1 || true
  fi
}

traefik_check() {
  require_cmd curl
  log "Checking Traefik web entrypoint: $TRAEFIK_URL"
  curl -sS -o /dev/null -w 'traefik_web HTTP %{http_code}\n' "$TRAEFIK_URL" || true
  log "Checking Traefik dashboard auth challenge: $TRAEFIK_DASHBOARD_URL"
  curl -sS -o /dev/null -w 'traefik_dashboard HTTP %{http_code}\n' "$TRAEFIK_DASHBOARD_URL" || true
}

validate_openclaw_ports() {
  if [[ "$OPENCLAW_GATEWAY_PORT" == "$OPENCLAW_BRIDGE_PORT" ]]; then
    err "OPENCLAW_GATEWAY_PORT and OPENCLAW_BRIDGE_PORT must be different"
    exit 1
  fi

  local reserved_port
  for reserved_port in "$HONCHO_HOST_PORT" "$ORACLE_DB_HOST_PORT" "$ORDS_HOST_PORT" "$APPSMITH_HOST_PORT" "$REDIS_HOST_PORT" "$RABBITMQ_HOST_PORT" "$RABBITMQ_MANAGEMENT_HOST_PORT" "$PGVECTOR_HOST_PORT" "$QDRANT_HOST_PORT" "$QDRANT_GRPC_HOST_PORT" "$FIRECRAWL_HOST_PORT" "$DAYTONA_API_HOST_PORT" "$DAYTONA_PROXY_HOST_PORT" "$DAYTONA_SSH_HOST_PORT" "$DAYTONA_DEX_HOST_PORT" "$DAYTONA_PGADMIN_HOST_PORT" "$DAYTONA_REGISTRY_UI_HOST_PORT" "$DAYTONA_REGISTRY_HOST_PORT" "$DAYTONA_MAILDEV_HOST_PORT" "$DAYTONA_MINIO_CONSOLE_HOST_PORT" "$DAYTONA_JAEGER_HOST_PORT"; do
    if [[ "$OPENCLAW_GATEWAY_PORT" == "$reserved_port" || "$OPENCLAW_BRIDGE_PORT" == "$reserved_port" ]]; then
      err "OpenClaw port conflict detected. OPENCLAW_GATEWAY_PORT=$OPENCLAW_GATEWAY_PORT OPENCLAW_BRIDGE_PORT=$OPENCLAW_BRIDGE_PORT overlaps an existing service port ($reserved_port)."
      exit 1
    fi
  done
}

validate_hermes_ports() {
  if [[ "$HERMES_GATEWAY_PORT" == "$HERMES_DASHBOARD_PORT" ]]; then
    err "HERMES_GATEWAY_PORT and HERMES_DASHBOARD_PORT must be different"
    exit 1
  fi

  local reserved_port
  for reserved_port in "$HONCHO_HOST_PORT" "$ORACLE_DB_HOST_PORT" "$ORDS_HOST_PORT" "$APPSMITH_HOST_PORT" "$REDIS_HOST_PORT" "$RABBITMQ_HOST_PORT" "$RABBITMQ_MANAGEMENT_HOST_PORT" "$PGVECTOR_HOST_PORT" "$QDRANT_HOST_PORT" "$QDRANT_GRPC_HOST_PORT" "$OPENCLAW_GATEWAY_PORT" "$OPENCLAW_BRIDGE_PORT" "$FIRECRAWL_HOST_PORT" "$DAYTONA_API_HOST_PORT" "$DAYTONA_PROXY_HOST_PORT" "$DAYTONA_SSH_HOST_PORT" "$DAYTONA_DEX_HOST_PORT" "$DAYTONA_PGADMIN_HOST_PORT" "$DAYTONA_REGISTRY_UI_HOST_PORT" "$DAYTONA_REGISTRY_HOST_PORT" "$DAYTONA_MAILDEV_HOST_PORT" "$DAYTONA_MINIO_CONSOLE_HOST_PORT" "$DAYTONA_JAEGER_HOST_PORT"; do
    if [[ "$HERMES_GATEWAY_PORT" == "$reserved_port" || "$HERMES_DASHBOARD_PORT" == "$reserved_port" ]]; then
      err "Hermes port conflict detected. HERMES_GATEWAY_PORT=$HERMES_GATEWAY_PORT HERMES_DASHBOARD_PORT=$HERMES_DASHBOARD_PORT overlaps an existing service port ($reserved_port)."
      exit 1
    fi
  done
}

validate_firecrawl_port() {
  local reserved_port
  for reserved_port in 5678 3000 8081 "$HONCHO_HOST_PORT" "$ORACLE_DB_HOST_PORT" "$ORDS_HOST_PORT" "$APPSMITH_HOST_PORT" "$REDIS_HOST_PORT" "$RABBITMQ_HOST_PORT" "$RABBITMQ_MANAGEMENT_HOST_PORT" "$PGVECTOR_HOST_PORT" "$QDRANT_HOST_PORT" "$QDRANT_GRPC_HOST_PORT" "$OPENCLAW_GATEWAY_PORT" "$OPENCLAW_BRIDGE_PORT" "$HERMES_GATEWAY_PORT" "$HERMES_DASHBOARD_PORT" "$DAYTONA_API_HOST_PORT" "$DAYTONA_PROXY_HOST_PORT" "$DAYTONA_SSH_HOST_PORT" "$DAYTONA_DEX_HOST_PORT" "$DAYTONA_PGADMIN_HOST_PORT" "$DAYTONA_REGISTRY_UI_HOST_PORT" "$DAYTONA_REGISTRY_HOST_PORT" "$DAYTONA_MAILDEV_HOST_PORT" "$DAYTONA_MINIO_CONSOLE_HOST_PORT" "$DAYTONA_JAEGER_HOST_PORT"; do
    if [[ "$FIRECRAWL_HOST_PORT" == "$reserved_port" ]]; then
      err "Firecrawl port conflict detected. FIRECRAWL_HOST_PORT=$FIRECRAWL_HOST_PORT overlaps an existing service port ($reserved_port)."
      exit 1
    fi
  done
}

normalize_hermes_dashboard() {
  local raw_value="${HERMES_DASHBOARD:-}"
  local lowered
  lowered="$(printf '%s' "$raw_value" | tr '[:upper:]' '[:lower:]')"

  case "$lowered" in
    1|true|yes|on)
      HERMES_DASHBOARD="1"
      ;;
    0|false|no|off|"")
      log "HERMES_DASHBOARD=$raw_value is not allowed during startup; forcing HERMES_DASHBOARD=1"
      HERMES_DASHBOARD="1"
      ;;
    *)
      log "HERMES_DASHBOARD=$raw_value is invalid; forcing HERMES_DASHBOARD=1"
      HERMES_DASHBOARD="1"
      ;;
  esac
}

setup_openclaw_runtime() {
  mkdir -p "$OPENCLAW_DIR/workspace"

  local openclaw_model="$OPENCLAW_LMSTUDIO_MODEL"
  local openclaw_base_url="$OPENCLAW_LMSTUDIO_BASE_URL"
  local openclaw_alias="LM Studio Local"

  if [[ "$openclaw_base_url" == "$FORTISAI_PROXY_OPENAI_BASE_URL" && "$openclaw_model" == "$FORTISAI_PROXY_OPENAI_MODEL" ]]; then
    openclaw_alias="FortisAI Proxy"
  fi

  if [[ -z "$openclaw_model" || "$openclaw_model" == "auto" ]]; then
    openclaw_model="local-model"
    log "No OpenAI-compatible model override supplied for OpenClaw; using fallback model id: $openclaw_model"
  fi

  cat > "$OPENCLAW_RUNTIME_CONFIG_FILE" <<JSON
{
  "gateway": {
    "port": 18789,
    "bind": "$OPENCLAW_GATEWAY_BIND",
    "auth": {
      "mode": "token",
      "token": "$OPENCLAW_GATEWAY_TOKEN"
    }
  },
  "env": {
    "OPENAI_API_KEY": "$OPENCLAW_OPENAI_API_KEY",
    "OPENAI_BASE_URL": "$openclaw_base_url"
  },
  "agents": {
    "defaults": {
      "workspace": "/home/node/.openclaw/workspace",
      "model": {
        "primary": "lmstudio/$openclaw_model"
      },
      "models": {
        "lmstudio/$openclaw_model": {
          "alias": "$openclaw_alias"
        }
      }
    }
  },
  "models": {
    "mode": "merge",
    "providers": {
      "lmstudio": {
        "baseUrl": "$openclaw_base_url",
        "apiKey": "\${OPENAI_API_KEY}",
        "api": "openai-completions",
        "models": [
          {
            "id": "$openclaw_model",
            "name": "$openclaw_alias",
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
          "baseUrl": "$OPENCLAW_HONCHO_BASE_URL",
          "workspaceId": "$OPENCLAW_HONCHO_WORKSPACE_ID",
          "apiKey": "$OPENCLAW_HONCHO_API_KEY"
        }
      }
    }
  }
}
JSON
}

write_sqlcl_mcp_config() {
  mkdir -p "$SQLCL_MCP_DIR"
  local n8n_api_key="${N8N_API_KEY:-}"

  if [[ -z "$n8n_api_key" && -f "$SQLCL_MCP_CONFIG_FILE" ]]; then
    n8n_api_key="$(SQLCL_MCP_CONFIG_FILE="$SQLCL_MCP_CONFIG_FILE" python3 - <<'PY'
import json
import os
from pathlib import Path

cfg = Path(os.environ["SQLCL_MCP_CONFIG_FILE"])
try:
    data = json.loads(cfg.read_text())
except Exception:
    print("")
    raise SystemExit(0)

print(data.get("mcpServers", {}).get("fortisai-n8n", {}).get("env", {}).get("N8N_API_KEY", "").strip())
PY
)"
  fi

  cat > "$SQLCL_MCP_CONFIG_FILE" <<EOF
{
  "mcpServers": {
    "fortisai-sqlcl": {
      "command": "$SQLCL_MCP_PYTHON_CMD",
      "args": [
        "$SQLCL_MCP_SERVER_FILE"
      ],
      "env": {
        "FORTISAI_DEV_HOME": "$BASE_DIR",
        "SQLCL_CONTAINER_NAME": "$SQLCL_CONTAINER_NAME",
        "ORACLE_DB_WALLET_ENV_FILE": "$ORACLE_DB_WALLET_ENV_FILE",
        "ORACLE_DB_HOST": "$ORACLE_DB_CONTAINER_NAME",
        "ORACLE_DB_PORT": "$ORACLE_DB_HOST_PORT",
        "ORACLE_DB_SERVICE_NAME": "$ORACLE_DB_PDB",
        "ORACLE_DB_USER": "$ORACLE_DB_USER",
        "ORACLE_DB_PASSWORD": "$ORACLE_DB_PASSWORD"
      }
    },
    "fortisai-n8n": {
      "command": "$SQLCL_MCP_PYTHON_CMD",
      "args": [
        "$N8N_MCP_SERVER_FILE"
      ],
      "env": {
        "N8N_BASE_URL": "$N8N_URL",
        "N8N_API_KEY": "$n8n_api_key"
      }
    }
  }
}
EOF
}

sqlcl_shell() {
  ensure_machine
  if ! podman ps --format '{{.Names}}' | grep -qx "$SQLCL_CONTAINER_NAME"; then
    err "SQLcl container is not running. Start it with: $SCRIPT_NAME up"
    exit 1
  fi
  podman exec -it "$SQLCL_CONTAINER_NAME" /bin/sh -lc 'if [ -f /opt/oracle/wallet/oracle-db.env ]; then . /opt/oracle/wallet/oracle-db.env; fi; export TNS_ADMIN="${TNS_ADMIN:-/opt/oracle/wallet}"; sql /nolog'
}

openclaw_shell() {
  ensure_machine
  if ! container_running "$OPENCLAW_CONTAINER_NAME"; then
    err "OpenClaw container is not running. Start it with: $SCRIPT_NAME openclaw-up"
    exit 1
  fi

  log "Opening shell in $OPENCLAW_CONTAINER_NAME"
  podman exec -it "$OPENCLAW_CONTAINER_NAME" /bin/sh -lc 'if command -v bash >/dev/null 2>&1; then exec bash; else exec sh; fi'
}

openwebui_shell() {
  ensure_machine
  if ! container_running "fortisai-openwebui"; then
    err "OpenWebUI container is not running. Start it with: $SCRIPT_NAME up"
    exit 1
  fi

  log "Opening shell in fortisai-openwebui"
  podman exec -it "fortisai-openwebui" /bin/sh -lc 'if command -v bash >/dev/null 2>&1; then exec bash; else exec sh; fi'
}

openvscode_shell() {
  ensure_machine
  local target_user="${1:-}"
  local container_name

  container_name="$(openvscode_container_for_user "$target_user")" || {
    err "Unknown OpenVSCode user: ${target_user:-default}"
    exit 1
  }
  if ! container_running "$container_name"; then
    err "OpenVSCode container is not running: $container_name. Start it with: $SCRIPT_NAME openvscode-up"
    exit 1
  fi

  log "Opening shell in $container_name"
  podman exec -it "$container_name" /bin/sh -lc 'if command -v bash >/dev/null 2>&1; then exec bash; else exec sh; fi'
}

wire_dify_bridge_into_openwebui() {
  if ! container_running "fortisai-openwebui"; then
    log "Skipping OpenWebUI wiring (fortisai-openwebui is not running)"
    return 0
  fi

  local container_openapi_url
  container_openapi_url="${MCP_DIFY_OPENAPI_URL/127.0.0.1/fortisai-mcp-openapi-dify}"
  container_openapi_url="${container_openapi_url/localhost/fortisai-mcp-openapi-dify}"

  log "Wiring Dify bridge into OpenWebUI tool_server.connections"
  if ! podman exec -i -e MCP_DIFY_OPENAPI_URL="$container_openapi_url" fortisai-openwebui python - <<'PY'
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
PY
  then
    log "Dify OpenWebUI tool reload skipped; OpenWebUI config is not initialized yet"
  fi
}

openwebui_coredns_active() {
  command -v podman >/dev/null 2>&1 && \
    [[ "$(podman inspect "$FORTISAI_COREDNS_CONTAINER_NAME" --format '{{.State.Running}}' 2>/dev/null || true)" == "true" ]]
}

openwebui_runtime_tool_import_payload() {
  local import_file="$1"
  local runtime_file
  local coredns_active="false"

  runtime_file="$(mktemp "${TMPDIR:-/tmp}/fortisai-openwebui-tool.XXXXXX.json")" || return 1
  if openwebui_coredns_active; then
    coredns_active="true"
  fi

  OPENWEBUI_COREDNS_ACTIVE="$coredns_active" \
  FORTISAI_CALICO_DNS_ZONE="$FORTISAI_CALICO_DNS_ZONE" \
  python3 - "$import_file" "$runtime_file" <<'PY'
import json
import os
import sys

source_path, target_path = sys.argv[1], sys.argv[2]
zone = os.environ.get("FORTISAI_CALICO_DNS_ZONE", "fortisai.local")
coredns_active = os.environ.get("OPENWEBUI_COREDNS_ACTIVE") == "true"

services = {
    "filesystem-server": "8000",
    "memory-server": "8000",
    "time-server": "8000",
    "fortisai-mcp-openapi-sqlcl": "8091",
    "fortisai-mcp-openapi-n8n": "8092",
    "fortisai-mcp-openapi-dify": "8093",
    "fortisai-mcp-openapi-debug": "8094",
    "fortisai-mcp-openapi-proxmox": "8095",
    "fortisai-mcp-openapi-codeindexer": "8096",
    "fortisai-hermes": "8642",
    "fortisai-claw-gateway": "18789",
}

def runtime_url(service, port):
    host = f"{service}.{zone}" if coredns_active else service
    return f"http://{host}:{port}"

replacements = {}
for service, port in services.items():
    replacements[f"http://{service}:{port}"] = runtime_url(service, port)
    replacements[f"http://{service}.{zone}:{port}"] = runtime_url(service, port)

def rewrite(value):
    if isinstance(value, str):
        for old, new in replacements.items():
            if value.startswith(old):
                return new + value[len(old):]
        return value
    if isinstance(value, list):
        return [rewrite(item) for item in value]
    if isinstance(value, dict):
        return {key: rewrite(item) for key, item in value.items()}
    return value

with open(source_path, "r", encoding="utf-8") as handle:
    payload = json.load(handle)

with open(target_path, "w", encoding="utf-8") as handle:
    json.dump(rewrite(payload), handle, indent=2)
    handle.write("\n")
PY

  printf '%s\n' "$runtime_file"
}

reload_openwebui_tool_connection() {
  local import_file="$1"
  local label="$2"
  local runtime_import_file=""

  if ! container_running "$OPENWEBUI_CONTAINER_NAME"; then
    log "Skipping OpenWebUI $label tool import ($OPENWEBUI_CONTAINER_NAME is not running)"
    return 0
  fi

  if [[ ! -f "$import_file" ]]; then
    err "OpenWebUI $label tool import payload not found: $import_file"
    return 1
  fi

  runtime_import_file="$(openwebui_runtime_tool_import_payload "$import_file")" || return 1
  log "Wiring $label bridge into OpenWebUI tool_server.connections"
  local reload_status=0
  OPENWEBUI_CONTAINER="$OPENWEBUI_CONTAINER_NAME" bash "$MCP_ROOT_DIR/reload-openwebui-tool-connection.sh" "$runtime_import_file" || reload_status=$?
  rm -f "$runtime_import_file" >/dev/null 2>&1 || true
  return "$reload_status"
}

create_openwebui_skill_from_payload() {
  local skill_file="$1"
  local label="$2"

  if ! container_running "$OPENWEBUI_CONTAINER_NAME"; then
    log "Skipping OpenWebUI $label skill import ($OPENWEBUI_CONTAINER_NAME is not running)"
    return 0
  fi

  if [[ ! -f "$skill_file" ]]; then
    err "OpenWebUI $label skill payload not found: $skill_file"
    return 1
  fi

  log "Importing $label skill into OpenWebUI"
  OPENWEBUI_CONTAINER="$OPENWEBUI_CONTAINER_NAME" OPENWEBUI_URL="$OPENWEBUI_URL" bash "$MCP_ROOT_DIR/create-openwebui-skill.sh" "$skill_file"
}

wire_codeindexer_bridge_into_openwebui() {
  reload_openwebui_tool_connection "$CODEINDEXER_OPENWEBUI_TOOLS_IMPORT_FILE" "CodeIndexer"
  create_openwebui_skill_from_payload "$CODEINDEXER_OPENWEBUI_SKILL_CREATE_FILE" "CodeIndexer" || \
    log "CodeIndexer OpenWebUI skill import did not complete; the payload remains importable at $CODEINDEXER_OPENWEBUI_SKILL_CREATE_FILE"
}

wire_openwebui_tool_and_skill() {
  local import_file="$1"
  local skill_file="$2"
  local label="$3"

  if reload_openwebui_tool_connection "$import_file" "$label"; then
    create_openwebui_skill_from_payload "$skill_file" "$label" || \
      log "$label OpenWebUI skill import did not complete; the payload remains importable at $skill_file"
  else
    log "$label OpenWebUI tool reload skipped; OpenWebUI container exec/API is not available"
  fi
}

wire_mcp_openapi_bridges_into_openwebui() {
  wire_openwebui_tool_and_skill "$SQLCL_OPENWEBUI_TOOLS_IMPORT_FILE" "$SQLCL_OPENWEBUI_SKILL_CREATE_FILE" "SQLcl"
  wire_openwebui_tool_and_skill "$N8N_OPENWEBUI_TOOLS_IMPORT_FILE" "$N8N_OPENWEBUI_SKILL_CREATE_FILE" "n8n"
  wire_openwebui_tool_and_skill "$DIFY_OPENWEBUI_TOOLS_IMPORT_FILE" "$DIFY_OPENWEBUI_SKILL_CREATE_FILE" "Dify"
  wire_openwebui_tool_and_skill "$CODEINDEXER_OPENWEBUI_TOOLS_IMPORT_FILE" "$CODEINDEXER_OPENWEBUI_SKILL_CREATE_FILE" "CodeIndexer"
  wire_openwebui_tool_and_skill "$PROXMOX_OPENWEBUI_TOOLS_IMPORT_FILE" "$PROXMOX_OPENWEBUI_SKILL_CREATE_FILE" "Proxmox"
}

wire_repo_openapi_servers_into_openwebui() {
  wire_openwebui_tool_and_skill "$REPO_FILESYSTEM_OPENWEBUI_TOOLS_IMPORT_FILE" "$REPO_FILESYSTEM_OPENWEBUI_SKILL_CREATE_FILE" "Repo filesystem"
  wire_openwebui_tool_and_skill "$REPO_MEMORY_OPENWEBUI_TOOLS_IMPORT_FILE" "$REPO_MEMORY_OPENWEBUI_SKILL_CREATE_FILE" "Repo memory"
  wire_openwebui_tool_and_skill "$REPO_TIME_OPENWEBUI_TOOLS_IMPORT_FILE" "$REPO_TIME_OPENWEBUI_SKILL_CREATE_FILE" "Repo time"
}

hermes_shell() {
  ensure_machine
  if ! container_running "$HERMES_CONTAINER_NAME"; then
    err "Hermes container is not running. Start it with: $SCRIPT_NAME hermes-up"
    exit 1
  fi

  log "Opening shell in $HERMES_CONTAINER_NAME"
  podman exec -it "$HERMES_CONTAINER_NAME" /bin/sh -lc 'if command -v bash >/dev/null 2>&1; then exec bash; else exec sh; fi'
}

sqlcl_mcp() {
  require_cmd "$SQLCL_MCP_PYTHON_CMD"

  if [[ ! -f "$SQLCL_MCP_SERVER_FILE" ]]; then
    err "SQLcl MCP server entrypoint not found: $SQLCL_MCP_SERVER_FILE"
    exit 1
  fi

  FORTISAI_DEV_HOME="$BASE_DIR" \
  SQLCL_CONTAINER_NAME="$SQLCL_CONTAINER_NAME" \
  ORACLE_DB_WALLET_ENV_FILE="$ORACLE_DB_WALLET_ENV_FILE" \
  ORACLE_DB_HOST="$ORACLE_DB_CONTAINER_NAME" \
  ORACLE_DB_PORT="$ORACLE_DB_HOST_PORT" \
  ORACLE_DB_SERVICE_NAME="$ORACLE_DB_PDB" \
  ORACLE_DB_USER="$ORACLE_DB_USER" \
  ORACLE_DB_PASSWORD="$ORACLE_DB_PASSWORD" \
    "$SQLCL_MCP_PYTHON_CMD" "$SQLCL_MCP_SERVER_FILE"
}

sqlcl_mcp_smoke() {
  require_cmd "$SQLCL_MCP_PYTHON_CMD"

  if [[ ! -f "$SQLCL_MCP_CONFIG_FILE" ]]; then
    err "SQLcl MCP config not found: $SQLCL_MCP_CONFIG_FILE"
    err "Run: $SCRIPT_NAME setup"
    exit 1
  fi

  SQLCL_MCP_CONFIG_FILE="$SQLCL_MCP_CONFIG_FILE" "$SQLCL_MCP_PYTHON_CMD" <<'PY'
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
PY
}

load_n8n_api_key() {
  local key="${N8N_API_KEY:-}"

  if [[ -n "$key" ]]; then
    printf '%s' "$key"
    return 0
  fi

  if [[ ! -f "$SQLCL_MCP_CONFIG_FILE" ]]; then
    printf '%s' ""
    return 0
  fi

  key="$(SQLCL_MCP_CONFIG_FILE="$SQLCL_MCP_CONFIG_FILE" python3 - <<'PY'
import json
import os
from pathlib import Path

cfg = Path(os.environ["SQLCL_MCP_CONFIG_FILE"])
try:
    data = json.loads(cfg.read_text())
except Exception:
    print("")
    raise SystemExit(0)

print(data.get("mcpServers", {}).get("fortisai-n8n", {}).get("env", {}).get("N8N_API_KEY", "").strip())
PY
)"

  printf '%s' "$key"
}

load_proxmox_config_from_json() {
  if [[ ! -f "$PROXMOX_MCP_CONFIG_FILE" ]]; then
    return 0
  fi

  local config_exports
  config_exports="$(PROXMOX_MCP_CONFIG_FILE="$PROXMOX_MCP_CONFIG_FILE" python3 - <<'PY'
import json
import os
from pathlib import Path

cfg = Path(os.environ["PROXMOX_MCP_CONFIG_FILE"])
try:
    data = json.loads(cfg.read_text(encoding="utf-8"))
except Exception:
    raise SystemExit(0)

proxmox = data.get("proxmox", {}) if isinstance(data, dict) else {}
auth = data.get("auth", {}) if isinstance(data, dict) else {}
logging = data.get("logging", {}) if isinstance(data, dict) else {}
security = data.get("security", {}) if isinstance(data, dict) else {}

def emit(name, value):
    if value is None:
        return
    if isinstance(value, bool):
        value = "true" if value else "false"
    value = str(value).strip()
    if value:
        print(f"{name}={value}")

emit("PROXMOX_HOST", proxmox.get("host"))
emit("PROXMOX_PORT", proxmox.get("port"))
emit("PROXMOX_VERIFY_SSL", proxmox.get("verify_ssl"))
emit("PROXMOX_SERVICE", proxmox.get("service"))
emit("PROXMOX_USER", auth.get("user"))
emit("PROXMOX_TOKEN_NAME", auth.get("token_name"))
emit("PROXMOX_TOKEN_VALUE", auth.get("token_value"))
emit("LOG_LEVEL", logging.get("level"))
emit("PROXMOX_DEV_MODE", security.get("dev_mode"))
PY
)"

  local key value
  while IFS='=' read -r key value; do
    [[ -n "$key" ]] || continue
    if ! env_var_exported "$key"; then
      set_runtime_var "$key" "$value"
    fi
  done <<< "$config_exports"
}

proxmox_mcp_is_configured() {
  local mode
  mode="$(printf '%s' "${PROXMOX_BRIDGE_ENABLED:-auto}" | tr '[:upper:]' '[:lower:]')"

  case "$mode" in
    1|true|yes|on)
      return 0
      ;;
    0|false|no|off)
      return 1
      ;;
  esac

  if [[ -f "$PROXMOX_MCP_CONFIG_FILE" ]]; then
    return 0
  fi

  [[ -n "${PROXMOX_HOST:-}" && -n "${PROXMOX_USER:-}" && -n "${PROXMOX_TOKEN_NAME:-}" && -n "${PROXMOX_TOKEN_VALUE:-}" ]]
}

mcp_up() {
  ensure_machine
  ensure_shared_network
  require_cmd curl
  require_cmd python3

  if [[ ! -f "$DIFY_MCP_UP_SCRIPT" ]]; then
    err "Dify MCP bridge launcher not found: $DIFY_MCP_UP_SCRIPT"
    err "Expected files under: $DIFY_MCP_DIR"
    exit 1
  fi

  prepare_vault_runtime_secrets

  local n8n_api_key
  n8n_api_key="$(load_n8n_api_key)"
  if [[ -z "$n8n_api_key" ]]; then
    err "N8N_API_KEY is required for mcp-up"
    err "Set N8N_API_KEY in your environment or configure it in $SQLCL_MCP_CONFIG_FILE under mcpServers.fortisai-n8n.env.N8N_API_KEY"
    exit 1
  fi

  local expect_proxmox="false"
  local proxmox_bridge_api_key="${PROXMOX_API_KEY:-fortisai-proxmox-openapi-dev-key}"
  if proxmox_mcp_is_configured; then
    expect_proxmox="true"
  fi

  log "Starting MCP OpenAPI bridge services for Dify"
  N8N_API_KEY="$n8n_api_key" \
  DIFY_BASE_URL="${DIFY_BASE_URL:-http://docker_api_1:5001}" \
  DIFY_API_KEY="${DIFY_API_KEY:-}" \
  DIFY_ADMIN_API_KEY="${DIFY_ADMIN_API_KEY:-${ADMIN_API_KEY:-}}" \
  DIFY_CONSOLE_ACCESS_TOKEN="${DIFY_CONSOLE_ACCESS_TOKEN:-}" \
  DIFY_ADMIN_WORKSPACE_ID="${DIFY_ADMIN_WORKSPACE_ID:-}" \
  ADMIN_API_KEY="${ADMIN_API_KEY:-}" \
  KNOWLEDGE_API_KEY="${KNOWLEDGE_API_KEY:-}" \
  ORACLE_DB_HOST="$ORACLE_DB_CONTAINER_NAME" \
  ORACLE_DB_PORT="$ORACLE_DB_HOST_PORT" \
  ORACLE_DB_SERVICE_NAME="$ORACLE_DB_PDB" \
  ORACLE_DB_USER="$ORACLE_DB_USER" \
  ORACLE_DB_PASSWORD="$ORACLE_DB_PASSWORD" \
  N8N_BASIC_AUTH_USER="${N8N_BASIC_AUTH_USER:-admin}" \
  N8N_BASIC_AUTH_PASSWORD="$N8N_BASIC_AUTH_PASSWORD" \
  PROXMOX_MCP_CONFIG_FILE="$PROXMOX_MCP_CONFIG_FILE" \
  PROXMOX_BRIDGE_ENABLED="$expect_proxmox" \
  PROXMOX_HOST="${PROXMOX_HOST:-}" \
  PROXMOX_PORT="${PROXMOX_PORT:-}" \
  PROXMOX_USER="${PROXMOX_USER:-}" \
  PROXMOX_TOKEN_NAME="${PROXMOX_TOKEN_NAME:-}" \
  PROXMOX_TOKEN_VALUE="${PROXMOX_TOKEN_VALUE:-}" \
  PROXMOX_VERIFY_SSL="${PROXMOX_VERIFY_SSL:-}" \
  PROXMOX_DEV_MODE="${PROXMOX_DEV_MODE:-}" \
  PROXMOX_SERVICE="${PROXMOX_SERVICE:-}" \
  PROXMOX_API_KEY="$proxmox_bridge_api_key" \
  PROXMOX_API_STRICT_AUTH="${PROXMOX_API_STRICT_AUTH:-false}" \
  LOG_LEVEL="${LOG_LEVEL:-INFO}" \
  FORTISAI_VAULT_ADDR="$VAULT_INTERNAL_URL" \
  VAULT_ADDR="$VAULT_INTERNAL_URL" \
  VAULT_TOKEN="$VAULT_TOKEN" \
  FORTISAI_DEV_HOME="$BASE_DIR" \
  FORTISAI_SHARED_NETWORK="$FORTISAI_SHARED_NETWORK" \
  CODEINDEXER_REPO_DIR="$CODEINDEXER_REPO_DIR" \
  CODEINDEXER_STATE_DIR="$CODEINDEXER_STATE_DIR" \
  CODEINDEXER_HOST_WORKSPACE="$REPO_ROOT_DIR" \
  CODEINDEXER_MILVUS_ADDRESS="$CODEINDEXER_MILVUS_ADDRESS" \
  CODEINDEXER_MILVUS_TOKEN="$CODEINDEXER_MILVUS_TOKEN" \
  CODEINDEXER_OPENAI_BASE_URL="$CODEINDEXER_OPENAI_BASE_URL" \
  CODEINDEXER_OPENAI_API_KEY="$CODEINDEXER_OPENAI_API_KEY" \
  CODEINDEXER_OPENAI_EMBEDDING_MODEL="$CODEINDEXER_OPENAI_EMBEDDING_MODEL" \
  CODEINDEXER_OPENAI_EMBEDDING_DIMENSION="$CODEINDEXER_OPENAI_EMBEDDING_DIMENSION" \
  CODEINDEXER_MCP_TIMEOUT_MS="$CODEINDEXER_MCP_TIMEOUT_MS" \
    bash "$DIFY_MCP_UP_SCRIPT"

  log "Validating MCP bridge OpenAPI specs"
  local sqlcl_status n8n_status dify_status debug_status codeindexer_status proxmox_status max_attempts attempt
  max_attempts=20
  sqlcl_status="000"
  n8n_status="000"
  dify_status="000"
  debug_status="000"
  codeindexer_status="000"
  proxmox_status="000"

  for ((attempt=1; attempt<=max_attempts; attempt++)); do
    sqlcl_status="$(curl -sS -o /dev/null -w '%{http_code}' "$MCP_SQLCL_OPENAPI_URL" 2>/dev/null || echo 000)"
    n8n_status="$(curl -sS -o /dev/null -w '%{http_code}' "$MCP_N8N_OPENAPI_URL" 2>/dev/null || echo 000)"
    dify_status="$(curl -sS -o /dev/null -w '%{http_code}' "$MCP_DIFY_OPENAPI_URL" 2>/dev/null || echo 000)"
    debug_status="$(curl -sS -o /dev/null -w '%{http_code}' "$MCP_DEBUG_OPENAPI_URL" 2>/dev/null || echo 000)"
    codeindexer_status="$(curl -sS -o /dev/null -w '%{http_code}' "$MCP_CODEINDEXER_OPENAPI_URL" 2>/dev/null || echo 000)"
    if [[ "$expect_proxmox" == "true" ]]; then
      proxmox_status="$(curl -sS -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $proxmox_bridge_api_key" "$MCP_PROXMOX_OPENAPI_URL" 2>/dev/null || echo 000)"
    else
      proxmox_status="200"
    fi

    if [[ "$sqlcl_status" == "200" && "$n8n_status" == "200" && "$dify_status" == "200" && "$debug_status" == "200" && "$codeindexer_status" == "200" && "$proxmox_status" == "200" ]]; then
      break
    fi

    sleep 1
  done

  if [[ "$sqlcl_status" == "200" ]]; then
    :
  elif [[ "$sqlcl_status" == "000" ]]; then
    log "SQLcl MCP bridge not responding; Oracle DB not configured in this environment (skipped)"
  else
    err "SQLcl MCP bridge OpenAPI check failed: $MCP_SQLCL_OPENAPI_URL (HTTP $sqlcl_status)"
    exit 1
  fi
  if [[ "$n8n_status" == "200" ]]; then
    :
  elif [[ "$n8n_status" == "401" || "$n8n_status" == "000" ]]; then
    log "n8n MCP bridge OpenAPI check skipped: backend auth/connectivity is not available in this environment"
  else
    err "n8n MCP bridge OpenAPI check failed: $MCP_N8N_OPENAPI_URL (HTTP $n8n_status)"
    exit 1
  fi
  if [[ "$dify_status" != "200" ]]; then
    err "Dify MCP bridge OpenAPI check failed: $MCP_DIFY_OPENAPI_URL (HTTP $dify_status)"
    exit 1
  fi
  if [[ "$debug_status" == "200" ]]; then
    :
  elif [[ "$debug_status" == "000" ]]; then
    log "Debug MCP bridge OpenAPI check skipped: debug backend is not reachable in this environment"
  else
    err "Debug MCP bridge OpenAPI check failed: $MCP_DEBUG_OPENAPI_URL (HTTP $debug_status)"
    exit 1
  fi
  if [[ "$codeindexer_status" != "200" ]]; then
    err "CodeIndexer MCP bridge OpenAPI check failed: $MCP_CODEINDEXER_OPENAPI_URL (HTTP $codeindexer_status)"
    err "Run: $SCRIPT_NAME codeindexer-up"
    exit 1
  fi
  if [[ "$expect_proxmox" == "true" && "$proxmox_status" != "200" ]]; then
    err "Proxmox MCP bridge OpenAPI check failed: $MCP_PROXMOX_OPENAPI_URL (HTTP $proxmox_status)"
    err "Provide Proxmox config at $PROXMOX_MCP_CONFIG_FILE or export PROXMOX_HOST/PROXMOX_USER/PROXMOX_TOKEN_NAME/PROXMOX_TOKEN_VALUE"
    exit 1
  fi

  log "Running debug bridge status smoke test"
  local debug_status_response
  debug_status_response="$(curl -sS "${MCP_DEBUG_OPENAPI_URL%/openapi.json}/debug_bridge_status" || true)"
  if [[ "$debug_status_response" == *'"ok":true'* ]]; then
    :
  elif [[ "$debug_status_response" == *'Name or service not known'* || "$debug_status_response" == *'Connection refused'* || "$debug_status_response" == *'could not translate host name'* ]]; then
    log "Debug bridge status smoke test skipped: debug backend is not reachable in this environment"
    printf '%s\n' "$debug_status_response"
  else
    err "Debug bridge status smoke test failed"
    printf '%s\n' "$debug_status_response"
    exit 1
  fi

  log "Running SQL bridge query smoke test"
  local sqlcl_query_response
  sqlcl_query_response="$(curl -sS -X POST "${MCP_SQLCL_OPENAPI_URL%/openapi.json}/sqlcl_query" \
    -H 'Content-Type: application/json' \
    -d '{"sql":"select 1 as ok from dual"}' || true)"
  if [[ "$sqlcl_query_response" == *'"ok":true'* ]]; then
    :
  elif [[ "$sqlcl_query_response" == *'Name or service not known'* || "$sqlcl_query_response" == *'Connection refused'* || "$sqlcl_query_response" == *'could not translate host name'* ]]; then
    log "SQLcl bridge query smoke test skipped: Oracle DB backend is not reachable in this environment"
    printf '%s\n' "$sqlcl_query_response"
  else
    err "SQLcl bridge query smoke test failed"
    printf '%s\n' "$sqlcl_query_response"
    exit 1
  fi

  log "Running n8n bridge workflow-list smoke test"
  local n8n_list_response
  n8n_list_response="$(curl -sS "${MCP_N8N_OPENAPI_URL%/openapi.json}/n8n_list_workflows?limit=2" || true)"
  if [[ "$n8n_list_response" == *'"status":200'* ]]; then
    :
  elif [[ "$n8n_list_response" == *'"status":401'* || "$n8n_list_response" == *'unauthorized'* || "$n8n_list_response" == *'Name or service not known'* || "$n8n_list_response" == *'Connection refused'* || "$n8n_list_response" == *'could not translate host name'* ]]; then
    log "n8n bridge workflow-list smoke test skipped: n8n backend auth/connectivity is not available in this environment"
    printf '%s\n' "$n8n_list_response"
  else
    err "n8n bridge workflow-list smoke test failed"
    printf '%s\n' "$n8n_list_response"
    exit 1
  fi

  log "Running Dify bridge connection-info smoke test"
  local dify_info_response
  dify_info_response="$(curl -sS "${MCP_DIFY_OPENAPI_URL%/openapi.json}/dify_connection_info" || true)"
  if [[ "$dify_info_response" != *'"base_url"'* ]]; then
    err "Dify bridge connection-info smoke test failed"
    printf '%s\n' "$dify_info_response"
    exit 1
  fi

  log "Running CodeIndexer bridge connection-info smoke test"
  local codeindexer_info_response
  codeindexer_info_response="$(curl -sS "${MCP_CODEINDEXER_OPENAPI_URL%/openapi.json}/codeindexer_connection_info" || true)"
  if [[ "$codeindexer_info_response" != *'"mcp_built":true'* && "$codeindexer_info_response" != *'"mcp_built": true'* && "$codeindexer_info_response" != *'"mcpExecutableExists":true'* && "$codeindexer_info_response" != *'"mcpExecutableExists": true'* ]]; then
    err "CodeIndexer bridge connection-info smoke test failed"
    printf '%s\n' "$codeindexer_info_response"
    exit 1
  fi

  if [[ "$expect_proxmox" == "true" ]]; then
    log "Running Proxmox bridge livez smoke test"
    local proxmox_livez_status
    proxmox_livez_status="$(curl -sS -o /dev/null -w '%{http_code}' "${MCP_PROXMOX_OPENAPI_URL%/openapi.json}/livez" 2>/dev/null || echo 000)"
    if [[ "$proxmox_livez_status" != "200" ]]; then
      err "Proxmox bridge livez smoke test failed (HTTP $proxmox_livez_status)"
      exit 1
    fi
  fi

  if container_running "docker_api_1"; then
    log "Validating Dify API container can reach OpenAPI bridge endpoints"
    local dify_probe_targets
    if [[ "$expect_proxmox" == "true" ]]; then
      dify_probe_targets="sqlcl=${MCP_SQLCL_OPENAPI_URL/127.0.0.1/fortisai-mcp-openapi-sqlcl} n8n=${MCP_N8N_OPENAPI_URL/127.0.0.1/fortisai-mcp-openapi-n8n} dify=${MCP_DIFY_OPENAPI_URL/127.0.0.1/fortisai-mcp-openapi-dify} debug=${MCP_DEBUG_OPENAPI_URL/127.0.0.1/fortisai-mcp-openapi-debug} codeindexer=${MCP_CODEINDEXER_OPENAPI_URL/127.0.0.1/fortisai-mcp-openapi-codeindexer} proxmox=${MCP_PROXMOX_OPENAPI_URL/127.0.0.1/fortisai-mcp-openapi-proxmox}"
    else
      dify_probe_targets="sqlcl=${MCP_SQLCL_OPENAPI_URL/127.0.0.1/fortisai-mcp-openapi-sqlcl} n8n=${MCP_N8N_OPENAPI_URL/127.0.0.1/fortisai-mcp-openapi-n8n} dify=${MCP_DIFY_OPENAPI_URL/127.0.0.1/fortisai-mcp-openapi-dify} debug=${MCP_DEBUG_OPENAPI_URL/127.0.0.1/fortisai-mcp-openapi-debug} codeindexer=${MCP_CODEINDEXER_OPENAPI_URL/127.0.0.1/fortisai-mcp-openapi-codeindexer}"
    fi

    podman exec -e FORTISAI_MCP_PROBE_TARGETS="$dify_probe_targets" docker_api_1 python - <<'PY' >/tmp/fortisai-mcp-up-dify-check.log 2>&1 || {
import os
import urllib.request

targets = []
for item in os.environ.get("FORTISAI_MCP_PROBE_TARGETS", "").split():
    name, url = item.split("=", 1)
    targets.append((name, url))

failures = 0
for name, url in targets:
    try:
        with urllib.request.urlopen(url, timeout=8) as response:
            print(f"{name} {getattr(response, 'status', 200)}")
    except Exception as exc:
        failures += 1
        print(f"ERROR {name} {type(exc).__name__}: {exc}")

raise SystemExit(1 if failures else 0)
PY
      if grep -qiE 'Connection refused|Name or service not known|could not translate host name|\b401\b|unauthorized|HTTP Error 401' /tmp/fortisai-mcp-up-dify-check.log; then
        log "Skipping Dify API container bridge reachability check: backend auth/connectivity is not available in this environment"
      else
        err "Dify API container bridge reachability check failed"
        cat /tmp/fortisai-mcp-up-dify-check.log
        exit 1
      fi
    }
    grep -Ei '^(sqlcl|n8n|dify|debug|codeindexer|proxmox) |ERROR' /tmp/fortisai-mcp-up-dify-check.log || true
  else
    log "Skipping Dify container reachability check (docker_api_1 is not running)"
  fi

  wire_mcp_openapi_bridges_into_openwebui

  log "mcp-up completed successfully"
  log "SQLcl OpenAPI: $MCP_SQLCL_OPENAPI_URL"
  log "n8n OpenAPI: $MCP_N8N_OPENAPI_URL"
  log "dify OpenAPI: $MCP_DIFY_OPENAPI_URL"
  log "debug OpenAPI: $MCP_DEBUG_OPENAPI_URL"
  log "CodeIndexer OpenAPI: $MCP_CODEINDEXER_OPENAPI_URL"
  if [[ "$expect_proxmox" == "true" ]]; then
    log "proxmox OpenAPI: $MCP_PROXMOX_OPENAPI_URL"
  else
    log "proxmox OpenAPI: skipped (no Proxmox config detected)"
  fi
}

mcp_down() {
  ensure_machine

  if [[ ! -f "$DIFY_MCP_DOWN_SCRIPT" ]]; then
    err "Dify MCP bridge shutdown script not found: $DIFY_MCP_DOWN_SCRIPT"
    err "Expected files under: $DIFY_MCP_DIR"
    exit 1
  fi

  log "Stopping MCP OpenAPI bridge services"
  FORTISAI_SHARED_NETWORK="$FORTISAI_SHARED_NETWORK" bash "$DIFY_MCP_DOWN_SCRIPT"
  log "mcp-down completed successfully"
}

require_running_oracle_and_ords() {
  if ! container_running "$ORACLE_DB_CONTAINER_NAME"; then
    err "Oracle DB container is not running. Start it with: $SCRIPT_NAME up"
    exit 1
  fi
  if ! container_running "$ORDS_CONTAINER_NAME"; then
    err "ORDS container is not running. Start it with: $SCRIPT_NAME up"
    exit 1
  fi
}

container_running() {
  local name="$1"
  local state

  state="$(podman inspect -f '{{.State.Running}}' "$name" 2>/dev/null || true)"
  [[ "$state" == "true" ]]
}

container_status() {
  local name="$1"

  podman inspect -f '{{.State.Status}}' "$name" 2>/dev/null || true
}

container_has_vault_runtime_env() {
  local name="$1"
  local env_lines

  env_lines="$(podman inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "$name" 2>/dev/null || true)"
  printf '%s\n' "$env_lines" | grep -q '^VAULT_TOKEN=.' &&
    printf '%s\n' "$env_lines" | grep -q '^VAULT_ADDR=.' &&
    printf '%s\n' "$env_lines" | grep -q '^FORTISAI_VAULT_ADDR=.'
}

container_needs_vault_runtime_refresh() {
  local name="$1"
  local compose_file="$2"

  [[ -n "${VAULT_TOKEN:-}" ]] || return 1
  container_exists "$name" || return 1
  [[ -f "$compose_file" ]] || return 1
  grep -q 'VAULT_TOKEN' "$compose_file" || return 1
  ! container_has_vault_runtime_env "$name"
}

container_exists() {
  local name="$1"
  podman container exists "$name" >/dev/null 2>&1
}

wait_for_container_absence() {
  local name="$1"
  local timeout_seconds="${2:-15}"
  local waited=0

  while container_exists "$name"; do
    if [[ "$waited" -ge "$timeout_seconds" ]]; then
      return 1
    fi
    sleep 1
    waited=$((waited + 1))
  done

  return 0
}

ensure_container_reusable() {
  local container_name="$1"
  local state

  if ! container_exists "$container_name"; then
    return 0
  fi

  state="$(container_status "$container_name")"
  if [[ "$state" != "removing" ]]; then
    return 0
  fi

  log "Waiting for lingering removal to finish: $container_name"
  if wait_for_container_absence "$container_name" 10; then
    return 0
  fi

  log "Force removing lingering container: $container_name"
  podman rm -f "$container_name" >/dev/null 2>&1 || true
  if wait_for_container_absence "$container_name" 20; then
    return 0
  fi

  err "Container is still stuck in Podman removal state: $container_name"
  return 1
}

start_compose_container() {
  local compose_file="$1"
  local container_name="$2"
  shift 2

  ensure_container_reusable "$container_name" || return 1

  if container_running "$container_name"; then
    if container_needs_vault_runtime_refresh "$container_name" "$compose_file"; then
      log "Recreating container to apply Vault runtime env: $container_name"
      podman rm -f "$container_name" >/dev/null 2>&1 || true
      wait_for_container_absence "$container_name" 20 || true
    else
      return 0
    fi
  fi

  if container_exists "$container_name" && container_needs_vault_runtime_refresh "$container_name" "$compose_file"; then
    log "Removing existing container to apply Vault runtime env: $container_name"
    podman rm -f "$container_name" >/dev/null 2>&1 || true
    wait_for_container_absence "$container_name" 20 || true
  fi

  if container_exists "$container_name"; then
    if podman start "$container_name" >/dev/null 2>&1; then
      sleep 1
      if container_running "$container_name"; then
        return 0
      fi
      log "Removing existing container that did not stay running: $container_name"
    else
      log "Removing non-startable existing container: $container_name"
    fi
    podman rm -f "$container_name" >/dev/null 2>&1 || true
    wait_for_container_absence "$container_name" 20 || true
  fi

  run_compose -f "$compose_file" up -d "$@"

  if ! container_running "$container_name"; then
    err "Container is not running after startup attempt: $container_name"
    return 1
  fi

  return 0
}

all_containers_running() {
  local container_name

  for container_name in "$@"; do
    if ! container_running "$container_name"; then
      return 1
    fi
  done

  return 0
}

start_existing_containers() {
  local container_name

  for container_name in "$@"; do
    ensure_container_reusable "$container_name" || return 1
    if container_running "$container_name"; then
      continue
    fi
    if container_exists "$container_name"; then
      podman start "$container_name" >/dev/null 2>&1 || true
    fi
  done
}

remove_stopped_existing_containers() {
  local container_name

  for container_name in "$@"; do
    if container_exists "$container_name" && ! container_running "$container_name"; then
      log "Removing non-startable existing container: $container_name"
      podman rm -f "$container_name" >/dev/null 2>&1 || true
      wait_for_container_absence "$container_name" 20 || true
    fi
  done
}

start_openapi_servers_stack() {
  local containers=(
    "repo_filesystem-server_1"
    "repo_memory-server_1"
    "repo_time-server_1"
  )

  if all_containers_running "${containers[@]}"; then
    return 0
  fi

  start_existing_containers "${containers[@]}"
  if all_containers_running "${containers[@]}"; then
    return 0
  fi

  remove_stopped_existing_containers "${containers[@]}"
  run_compose -f "$OPENAPI_SERVERS_COMPOSE_FILE" up -d
}

start_honcho_stack() {
  local containers=(
    "$HONCHO_API_CONTAINER_NAME"
    "$HONCHO_DERIVER_CONTAINER_NAME"
  )

  if all_containers_running "${containers[@]}"; then
    if container_needs_vault_runtime_refresh "$HONCHO_API_CONTAINER_NAME" "$HONCHO_COMPOSE_FILE" ||
       container_needs_vault_runtime_refresh "$HONCHO_DERIVER_CONTAINER_NAME" "$HONCHO_COMPOSE_FILE"; then
      log "Recreating Honcho containers to apply Vault runtime env"
      podman rm -f "${containers[@]}" >/dev/null 2>&1 || true
    else
      return 0
    fi
  fi

  start_existing_containers "${containers[@]}"
  if all_containers_running "${containers[@]}"; then
    if container_needs_vault_runtime_refresh "$HONCHO_API_CONTAINER_NAME" "$HONCHO_COMPOSE_FILE" ||
       container_needs_vault_runtime_refresh "$HONCHO_DERIVER_CONTAINER_NAME" "$HONCHO_COMPOSE_FILE"; then
      log "Recreating Honcho containers to apply Vault runtime env"
      podman rm -f "${containers[@]}" >/dev/null 2>&1 || true
    else
      return 0
    fi
  fi

  remove_stopped_existing_containers "${containers[@]}"
  run_compose -f "$HONCHO_COMPOSE_FILE" up -d --build
}

prepare_apex_bundle() {
  require_cmd curl
  require_cmd unzip

  mkdir -p "$APEX_WORK_DIR"
  if [[ -f "$APEX_WORK_DIR/apex/apexins.sql" ]]; then
    log "APEX bundle already prepared at $APEX_WORK_DIR/apex"
    return
  fi

  log "Downloading APEX bundle from $APEX_DOWNLOAD_URL"
  curl -fL "$APEX_DOWNLOAD_URL" -o "$APEX_WORK_DIR/apex.zip"

  rm -rf "$APEX_WORK_DIR/apex"
  log "Extracting APEX bundle"
  unzip -oq "$APEX_WORK_DIR/apex.zip" -d "$APEX_WORK_DIR"

  if [[ ! -f "$APEX_WORK_DIR/apex/apexins.sql" ]]; then
    err "APEX bundle extraction failed: apexins.sql not found"
    exit 1
  fi
}

apex_installed() {
  local raw
  raw="$(podman exec "$ORACLE_DB_CONTAINER_NAME" bash -lc "sqlplus -s -L '/ as sysdba' <<'SQL'
set heading off feedback off pages 0 verify off
alter session set container=${ORACLE_DB_PDB};
select count(*) from dba_registry where comp_id = 'APEX' and status = 'VALID';
exit
SQL" 2>/dev/null || true)"
  raw="$(printf '%s\n' "$raw" | grep -E '^[[:space:]]*[0-9]+[[:space:]]*$' | tail -1 | tr -d '[:space:]')"
  raw="${raw:-0}"
  [[ "$raw" -gt 0 ]]
}

apex_sync_ords_static() {
  log "Copying APEX static images into ORDS config"
  podman exec "$ORDS_CONTAINER_NAME" bash -lc 'mkdir -p /etc/ords/config/global/doc_root/i && rm -rf /tmp/apex-images'
  podman cp "$APEX_WORK_DIR/apex/images" "$ORDS_CONTAINER_NAME:/tmp/apex-images"
  podman exec "$ORDS_CONTAINER_NAME" bash -lc 'cp -R /tmp/apex-images/. /etc/ords/config/global/doc_root/i/ && rm -rf /tmp/apex-images'
  podman exec "$ORDS_CONTAINER_NAME" bash -lc 'ords --config /etc/ords/config config set standalone.doc.root /etc/ords/config/global/doc_root' >/dev/null

  log "Restarting ORDS to load APEX static content"
  run_compose -f "$ORDS_COMPOSE_FILE" restart ords >/dev/null
}

apex_configure_rest() {
  local db_connect_string="localhost:${ORACLE_DB_HOST_PORT}/${ORACLE_DB_PDB}"

  if [[ -f "$ORACLE_DB_WALLET_ENV_FILE" ]]; then
    local wallet_value
    wallet_value="$(oracle_db_wallet_value ORACLE_DB_CONNECT_STRING || true)"
    [[ -n "$wallet_value" ]] && db_connect_string="$wallet_value"
  fi

  if ! podman exec "$ORACLE_DB_CONTAINER_NAME" bash -lc 'test -f /tmp/apex/apex_rest_config.sql' >/dev/null 2>&1; then
    podman exec "$ORACLE_DB_CONTAINER_NAME" bash -lc 'rm -rf /tmp/apex'
    podman cp "$APEX_WORK_DIR/apex" "$ORACLE_DB_CONTAINER_NAME:/tmp/"
  fi

  log "Configuring APEX REST users"
  podman exec -i "$ORACLE_DB_CONTAINER_NAME" bash -lc "cd /tmp/apex && sqlplus -L '/ as sysdba'" <<SQL >/dev/null
whenever sqlerror exit failure rollback;
alter session set container=${ORACLE_DB_PDB};
@apex_rest_config.sql "${ORACLE_DB_PASSWORD}" "${ORACLE_DB_PASSWORD}"
exit
SQL

  log "Configuring ORDS gateway settings for APEX"
  podman exec "$ORDS_CONTAINER_NAME" bash -lc "ords --config /etc/ords/config config set plsql.gateway.mode proxied --db-pool default" >/dev/null
  podman exec "$ORDS_CONTAINER_NAME" bash -lc "ords --config /etc/ords/config config set security.requestValidationFunction '' --db-pool default" >/dev/null
}

apex_set_admin_password() {
  local db_connect_string="localhost:${ORACLE_DB_HOST_PORT}/${ORACLE_DB_PDB}"
  local apex_admin_password_sql

  if [[ -f "$ORACLE_DB_WALLET_ENV_FILE" ]]; then
    local wallet_value
    wallet_value="$(oracle_db_wallet_value ORACLE_DB_CONNECT_STRING || true)"
    [[ -n "$wallet_value" ]] && db_connect_string="$wallet_value"
  fi

  # Escape SQL single quotes to safely embed the password as a SQL literal.
  apex_admin_password_sql="${APEX_ADMIN_PASSWORD//\'/\'\'}"

  log "Setting APEX ADMIN password"
  podman exec -i "$ORACLE_DB_CONTAINER_NAME" bash -lc "sqlplus -L \"sys/${ORACLE_DB_PASSWORD}@${db_connect_string} as sysdba\"" <<SQL >/dev/null
whenever sqlerror exit failure rollback;
alter session set container=${ORACLE_DB_PDB};
begin
  apex_instance_admin.create_or_update_admin_user(
    p_username => 'ADMIN',
    p_email    => 'admin@fortisai.local',
    p_password => '${apex_admin_password_sql}'
  );
  commit;
end;
/
exit
SQL
}

apex_install() {
  ensure_machine
  require_running_oracle_and_ords
  prepare_apex_bundle

  local db_connect_string="localhost:${ORACLE_DB_HOST_PORT}/${ORACLE_DB_PDB}"

  if [[ -f "$ORACLE_DB_WALLET_ENV_FILE" ]]; then
    local wallet_value
    wallet_value="$(oracle_db_wallet_value ORACLE_DB_CONNECT_STRING || true)"
    [[ -n "$wallet_value" ]] && db_connect_string="$wallet_value"
  fi

  if apex_installed; then
    log "APEX is already installed in $ORACLE_DB_PDB"
  else
    log "Copying APEX installer into Oracle DB container"
    podman exec "$ORACLE_DB_CONTAINER_NAME" bash -lc 'rm -rf /tmp/apex'
    podman cp "$APEX_WORK_DIR/apex" "$ORACLE_DB_CONTAINER_NAME:/tmp/"

    log "Installing APEX in $ORACLE_DB_PDB (this can take several minutes)"
    podman exec -i "$ORACLE_DB_CONTAINER_NAME" bash -lc "cd /tmp/apex && sqlplus -L \"sys/${ORACLE_DB_PASSWORD}@${db_connect_string} as sysdba\"" <<SQL
whenever sqlerror exit failure rollback;
@apexins.sql SYSAUX SYSAUX TEMP /i/
declare
  v_count number;
begin
  for u in (select 'APEX_PUBLIC_USER' username from dual
            union all select 'APEX_LISTENER' from dual
            union all select 'APEX_REST_PUBLIC_USER' from dual) loop
    select count(*) into v_count from dba_users where username = u.username;
    if v_count > 0 then
      execute immediate 'alter user ' || u.username || ' identified by "${ORACLE_DB_PASSWORD}" account unlock';
    end if;
  end loop;
end;
/
exit
SQL

    if ! apex_installed; then
      err "APEX installer completed but APEX component is not VALID in $ORACLE_DB_PDB"
      return 1
    fi

    apex_configure_rest

    apex_set_admin_password
  fi

  apex_sync_ords_static

  apex_check
  log "APEX install workflow complete"
  log "APEX URL: $APEX_URL"
}

apex_reset() {
  ensure_machine
  require_running_oracle_and_ords

  local db_connect_string="localhost:${ORACLE_DB_HOST_PORT}/${ORACLE_DB_PDB}"

  if [[ -f "$ORACLE_DB_WALLET_ENV_FILE" ]]; then
    local wallet_value
    wallet_value="$(oracle_db_wallet_value ORACLE_DB_CONNECT_STRING || true)"
    [[ -n "$wallet_value" ]] && db_connect_string="$wallet_value"
  fi

  if ! apex_installed; then
    err "APEX is not installed in $ORACLE_DB_PDB. Run: $SCRIPT_NAME apex-install"
    exit 1
  fi

  prepare_apex_bundle

  log "Resetting APEX runtime users and admin password"
  podman exec -i "$ORACLE_DB_CONTAINER_NAME" bash -lc "sqlplus -L \"sys/${ORACLE_DB_PASSWORD}@${db_connect_string} as sysdba\"" <<SQL
whenever sqlerror exit failure rollback;
declare
  v_count number;
begin
  for u in (select 'APEX_PUBLIC_USER' username from dual
            union all select 'APEX_LISTENER' from dual
            union all select 'APEX_REST_PUBLIC_USER' from dual) loop
    select count(*) into v_count from dba_users where username = u.username;
    if v_count > 0 then
      execute immediate 'alter user ' || u.username || ' identified by "${ORACLE_DB_PASSWORD}" account unlock';
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
SQL

  if ! podman exec "$ORACLE_DB_CONTAINER_NAME" bash -lc 'test -f /tmp/apex/apex_rest_config.sql' >/dev/null 2>&1; then
    podman exec "$ORACLE_DB_CONTAINER_NAME" bash -lc 'rm -rf /tmp/apex'
    podman cp "$APEX_WORK_DIR/apex" "$ORACLE_DB_CONTAINER_NAME:/tmp/"
  fi

  apex_configure_rest
  apex_set_admin_password

  apex_sync_ords_static
  apex_check
  log "APEX reset workflow complete"
  log "APEX URL: $APEX_URL"
}

apex_check() {
  ensure_machine
  require_cmd curl

  if container_running "$ORACLE_DB_CONTAINER_NAME" && apex_installed; then
    log "apex install status: installed"
  else
    log "apex install status: not installed (or database not running)"
  fi

  log "Checking APEX URL via ORDS: $APEX_URL"
  curl -sS -o /dev/null -w 'apex HTTP %{http_code}\n' "$APEX_URL" || true
}


daytona_gpu_normalize_mode() {
  printf '%s' "${DAYTONA_GPU_MODE:-auto}" | tr '[:upper:]' '[:lower:]'
}

daytona_gpu_effective_mode() {
  local mode
  mode="$(daytona_gpu_normalize_mode)"
  case "$mode" in
    off|false|0|none|disabled)
      printf '%s\n' "off"
      ;;
    apple|apple-silicon|metal|mps)
      printf '%s\n' "apple-silicon"
      ;;
    nvidia|cuda)
      printf '%s\n' "nvidia"
      ;;
    auto)
      if [[ "$(uname -s)" == "Darwin" && "$(uname -m)" == "arm64" ]]; then
        printf '%s\n' "apple-silicon"
      else
        printf '%s\n' "off"
      fi
      ;;
    *)
      printf '%s\n' "$mode"
      ;;
  esac
}

daytona_apply_gpu_runtime_compose() {
  local mode tmp_file
  mode="$(daytona_gpu_effective_mode)"

  if [[ "$mode" != "apple-silicon" ]]; then
    return 0
  fi

  if ! grep -q 'FORTISAI_DAYTONA_GPU_MODE=' "$DAYTONA_RUNTIME_FILE"; then
    tmp_file="$(mktemp)"
    awk '
      {print}
      /DAYTONA_RUNNER_TOKEN=/{
        print "      - FORTISAI_DAYTONA_GPU_MODE=apple-silicon"
        print "      - FORTISAI_DAYTONA_GPU_CONTAINER_PASSTHROUGH=unsupported"
      }
    ' "$DAYTONA_RUNTIME_FILE" > "$tmp_file"
    mv "$tmp_file" "$DAYTONA_RUNTIME_FILE"
  fi
}

daytona_log_gpu_mode() {
  local mode
  mode="$(daytona_gpu_effective_mode)"
  case "$mode" in
    apple-silicon)
      log "Daytona GPU mode: Apple Silicon host GPU detected; Linux Daytona containers remain CPU-only because Metal/MPS is not exposed to Docker/Podman Linux containers."
      ;;
    nvidia)
      log "Daytona GPU mode: NVIDIA requested, but macOS Daytona does not expose NVIDIA devices."
      ;;
    off)
      log "Daytona GPU mode: off"
      ;;
    *)
      log "Daytona GPU mode: $mode"
      ;;
  esac
}

daytona_gpu_check() {
  local mode
  mode="$(daytona_gpu_effective_mode)"
  printf '%s\n' "daytona_gpu_mode: $mode"

  case "$mode" in
    apple-silicon)
      if command -v system_profiler >/dev/null 2>&1; then
        system_profiler SPDisplaysDataType 2>/dev/null | awk -F': ' '/Chipset Model|Type|Total Number of Cores|Metal/{gsub(/^[ \t]+/, "", $1); print "daytona_host_gpu_" $1 ": " $2}'
      fi
      printf '%s\n' "daytona_container_gpu_passthrough: unsupported"
      printf '%s\n' "daytona_gpu_status: host Apple GPU available; Daytona Linux sandboxes are CPU-only on macOS"
      ;;
    nvidia)
      printf '%s\n' "daytona_container_gpu_passthrough: unsupported-on-macos"
      printf '%s\n' "daytona_gpu_status: cpu-only"
      ;;
    *)
      printf '%s\n' "daytona_gpu_status: cpu-only"
      ;;
  esac
}

write_daytona_runtime_compose() {
  mkdir -p "$(dirname "$DAYTONA_RUNTIME_FILE")"

  sed -E \
    -e "s@(^[[:space:]]*-[[:space:]]*)3000:3000@\\1${DAYTONA_API_HOST_PORT}:3000@" \
    -e "s@(^[[:space:]]*-[[:space:]]*)4000:4000@\\1${DAYTONA_PROXY_HOST_PORT}:4000@" \
    -e "s@(^[[:space:]]*-[[:space:]]*)2222:2222@\\1${DAYTONA_SSH_HOST_PORT}:2222@" \
    -e "s@(^[[:space:]]*-[[:space:]]*)5556:5556@\\1${DAYTONA_DEX_HOST_PORT}:5556@" \
    -e "s@(^[[:space:]]*-[[:space:]]*)5050:80@\\1${DAYTONA_PGADMIN_HOST_PORT}:80@" \
    -e "s@(^[[:space:]]*-[[:space:]]*)5100:80@\\1${DAYTONA_REGISTRY_UI_HOST_PORT}:80@" \
    -e "s@(^[[:space:]]*-[[:space:]]*)6000:6000@\\1${DAYTONA_REGISTRY_HOST_PORT}:6000@" \
    -e "s@(^[[:space:]]*-[[:space:]]*)1080:1080@\\1${DAYTONA_MAILDEV_HOST_PORT}:1080@" \
    -e "s@(^[[:space:]]*-[[:space:]]*)9001:9001@\\1${DAYTONA_MINIO_CONSOLE_HOST_PORT}:9001@" \
    -e "s@(^[[:space:]]*-[[:space:]]*)16686:16686@\\1${DAYTONA_JAEGER_HOST_PORT}:16686@" \
    -e "s@DASHBOARD_URL=http://localhost:3000/dashboard@DASHBOARD_URL=http://localhost:${DAYTONA_API_HOST_PORT}/dashboard@" \
    -e "s@DASHBOARD_BASE_API_URL=http://localhost:3000@DASHBOARD_BASE_API_URL=http://localhost:${DAYTONA_API_HOST_PORT}@" \
    -e "s@PUBLIC_OIDC_DOMAIN=http://localhost:5556/dex@PUBLIC_OIDC_DOMAIN=http://localhost:${DAYTONA_DEX_HOST_PORT}/dex@" \
    -e "s@OIDC_PUBLIC_DOMAIN=http://localhost:5556/dex@OIDC_PUBLIC_DOMAIN=http://localhost:${DAYTONA_DEX_HOST_PORT}/dex@" \
    -e "s@PROXY_DOMAIN=proxy.localhost:4000@PROXY_DOMAIN=proxy.localhost:${DAYTONA_PROXY_HOST_PORT}@" \
    -e "s@PROXY_TEMPLATE_URL=http://\{\{PORT\}\}-\{\{sandboxId\}\}\.proxy\.localhost:4000@PROXY_TEMPLATE_URL=http://{{PORT}}-{{sandboxId}}.proxy.localhost:${DAYTONA_PROXY_HOST_PORT}@" \
    -e "s@SSH_GATEWAY_URL=localhost:2222@SSH_GATEWAY_URL=localhost:${DAYTONA_SSH_HOST_PORT}@" \
    -e "s|SSH_GATEWAY_COMMAND=ssh -p 2222 \{\{TOKEN\}\}@localhost|SSH_GATEWAY_COMMAND=ssh -p ${DAYTONA_SSH_HOST_PORT} {{TOKEN}}@localhost|" \
    "$DAYTONA_COMPOSE_FILE" > "$DAYTONA_RUNTIME_FILE"

  if ! grep -q 'DOCKER_IGNORE_BR_NETFILTER_ERROR=' "$DAYTONA_RUNTIME_FILE"; then
    local tmp_file
    tmp_file="$(mktemp)"
    awk '
      {print}
      /DAYTONA_RUNNER_TOKEN=/{
        print "      - DOCKER_IGNORE_BR_NETFILTER_ERROR=1"
      }
    ' "$DAYTONA_RUNTIME_FILE" > "$tmp_file"
    mv "$tmp_file" "$DAYTONA_RUNTIME_FILE"
  fi

  daytona_apply_gpu_runtime_compose

  if ! grep -q '^networks:' "$DAYTONA_RUNTIME_FILE"; then
    cat >> "$DAYTONA_RUNTIME_FILE" <<YAML

networks:
  default:
    name: $FORTISAI_SHARED_NETWORK
    external: true
YAML
  fi
}

setup_daytona_repo() {
  require_cmd git

  mkdir -p "$BASE_DIR"
  if [[ ! -d "$DAYTONA_REPO_DIR/.git" ]]; then
    log "Cloning Daytona repository"
    git clone https://github.com/daytonaio/daytona.git "$DAYTONA_REPO_DIR"
  else
    log "Daytona repository already exists at $DAYTONA_REPO_DIR"
  fi

  if [[ ! -f "$DAYTONA_COMPOSE_FILE" ]]; then
    err "Daytona compose file not found: $DAYTONA_COMPOSE_FILE"
    err "Ensure the repository contains docker/docker-compose.yaml"
    exit 1
  fi

  local dex_config="$DAYTONA_REPO_DIR/docker/dex/config.yaml"
  if [[ -f "$dex_config" ]]; then
    if ! grep -q "http://localhost:${DAYTONA_API_HOST_PORT}'" "$dex_config"; then
      sed -i.bak "/http:\/\/localhost:3000'/a\\
      - 'http://localhost:${DAYTONA_API_HOST_PORT}'" "$dex_config"
      rm -f "$dex_config.bak"
    fi

    if ! grep -q "http://localhost:${DAYTONA_API_HOST_PORT}/api/oauth2-redirect.html'" "$dex_config"; then
      sed -i.bak "/http:\/\/localhost:3000\/api\/oauth2-redirect.html'/a\\
      - 'http://localhost:${DAYTONA_API_HOST_PORT}/api/oauth2-redirect.html'" "$dex_config"
      rm -f "$dex_config.bak"
    fi
  fi

  write_daytona_runtime_compose

  log "Prepared Daytona runtime compose file: $DAYTONA_RUNTIME_FILE"
  log "Optional but recommended for Daytona preview URLs:"
  log "  cd $DAYTONA_REPO_DIR && ./scripts/setup-proxy-dns.sh"
}

setup_dify_repo() {
  require_cmd git

  # Ensure Dify app/knowledge/admin keys are available for .env injection during setup.
  load_dify_keys_from_json

  mkdir -p "$BASE_DIR"
  if [[ ! -d "$DIFY_REPO_DIR/.git" ]]; then
    log "Cloning Dify repository"
    git clone https://github.com/langgenius/dify.git "$DIFY_REPO_DIR"
  else
    log "Dify repository already exists at $DIFY_REPO_DIR"
  fi

  if [[ ! -f "$DIFY_DOCKER_DIR/.env" ]]; then
    log "Creating Dify .env from template"
    cp "$DIFY_DOCKER_DIR/.env.example" "$DIFY_DOCKER_DIR/.env"
  fi

  upsert_env_var "$DIFY_DOCKER_DIR/.env" "EXPOSE_NGINX_PORT" "18081"
  upsert_env_var "$DIFY_DOCKER_DIR/.env" "EXPOSE_NGINX_SSL_PORT" "4433"
  upsert_env_var "$DIFY_DOCKER_DIR/.env" "DB_TYPE" "postgresql"
  upsert_env_var "$DIFY_DOCKER_DIR/.env" "DB_HOST" "$PGVECTOR_CONTAINER_NAME"
  upsert_env_var "$DIFY_DOCKER_DIR/.env" "DB_PORT" "5432"
  upsert_env_var "$DIFY_DOCKER_DIR/.env" "DB_DATABASE" "$PGVECTOR_DB"
  upsert_env_var "$DIFY_DOCKER_DIR/.env" "DB_USERNAME" "$PGVECTOR_USER"
  upsert_env_var "$DIFY_DOCKER_DIR/.env" "DB_PASSWORD" "$PGVECTOR_PASSWORD"
  upsert_env_var "$DIFY_DOCKER_DIR/.env" "REDIS_HOST" "$REDIS_CONTAINER_NAME"
  upsert_env_var "$DIFY_DOCKER_DIR/.env" "REDIS_PORT" "6379"
  upsert_env_var "$DIFY_DOCKER_DIR/.env" "REDIS_PASSWORD" ""
  upsert_env_var "$DIFY_DOCKER_DIR/.env" "CELERY_BROKER_URL" "redis://$REDIS_CONTAINER_NAME:6379/1"
  upsert_env_var "$DIFY_DOCKER_DIR/.env" "EVENT_BUS_REDIS_URL" "redis://$REDIS_CONTAINER_NAME:6379/2"
  upsert_env_var "$DIFY_DOCKER_DIR/.env" "VECTOR_STORE" "qdrant"
  upsert_env_var "$DIFY_DOCKER_DIR/.env" "QDRANT_URL" "$QDRANT_INTERNAL_URL"
  upsert_env_var "$DIFY_DOCKER_DIR/.env" "QDRANT_API_KEY" "$QDRANT_API_KEY"
  upsert_env_var "$DIFY_DOCKER_DIR/.env" "QDRANT_CLIENT_TIMEOUT" "20"
  upsert_env_var "$DIFY_DOCKER_DIR/.env" "QDRANT_GRPC_ENABLED" "false"
  upsert_env_var "$DIFY_DOCKER_DIR/.env" "QDRANT_GRPC_PORT" "6334"
  upsert_env_var "$DIFY_DOCKER_DIR/.env" "FORTISAI_LLAMA_SERVER_URL" "$FORTISAI_LLAMA_SERVER_URL"
  upsert_env_var "$DIFY_DOCKER_DIR/.env" "FORTISAI_LLAMA_SERVER_BASE_URL" "$FORTISAI_LLAMA_SERVER_BASE_URL"
  upsert_env_var "$DIFY_DOCKER_DIR/.env" "FORTISAI_LLAMA_OPENAI_BASE_URL" "$FORTISAI_LLAMA_OPENAI_BASE_URL"
  upsert_env_var "$DIFY_DOCKER_DIR/.env" "FORTISAI_LLAMA_OPENAI_API_KEY" "$FORTISAI_LLAMA_OPENAI_API_KEY"
  if [[ -n "${APP_API_KEY:-}" ]]; then
    upsert_env_var "$DIFY_DOCKER_DIR/.env" "APP_API_KEY" "$APP_API_KEY"
  fi
  if [[ -n "${KNOWLEDGE_API_KEY:-}" ]]; then
    upsert_env_var "$DIFY_DOCKER_DIR/.env" "KNOWLEDGE_API_KEY" "$KNOWLEDGE_API_KEY"
  fi
  if [[ -n "${ADMIN_API_KEY:-}" ]]; then
    upsert_env_var "$DIFY_DOCKER_DIR/.env" "ADMIN_API_KEY_ENABLE" "true"
    upsert_env_var "$DIFY_DOCKER_DIR/.env" "ADMIN_API_KEY" "$ADMIN_API_KEY"
  fi

  # -------------------------------------------------------------------------
  # podman-compose (all versions) does not honour `required: false` in
  # depends_on when the referenced service is profile-gated.  Dify's compose
  # file has api, worker, worker_beat, and plugin_daemon depending on several
  # alternative database containers (db_postgres, db_mysql, oceanbase, seekdb)
  # with required: false.  This causes a KeyError at startup with podman-compose.
  #
  # Fix: patch docker-compose.yaml in-place (once, with a .orig backup) to
  # remove those profile-gated depends_on entries and any depends_on: blocks
  # that are left empty after the removal.
  # -------------------------------------------------------------------------
  local compose_file="$DIFY_DOCKER_DIR/docker-compose.yaml"
  if [[ -f "$compose_file" ]]; then
    log "Patching Dify docker-compose.yaml for podman-compose compatibility"
    python3 - "$compose_file" <<'PYEOF'
import os, re, sys, shutil
f = sys.argv[1]
bak = f + '.orig'
if not os.path.exists(bak):
    shutil.copy2(f, bak)
with open(f) as fp:
    content = fp.read()
for svc in ('db_postgres', 'db_mysql', 'oceanbase', 'seekdb'):
    pattern = rf'      {svc}:\n        condition: service_healthy\n        required: false\n'
    content = re.sub(pattern, '', content)
content = re.sub(r'      redis:\n        condition: service_started\n', '', content)

redis_service_pattern = r'\n  redis:\n(?:    .*\n)*?(?=\n  [A-Za-z0-9_-]+:)'
content = re.sub(redis_service_pattern, '\n', content, count=1)

redis_comment_block_pattern = r'\n  # The redis cache\.\n(?:  #.*\n)*  redis:\n(?:    .*\n)*?(?=\n  # The DifySandbox)'
content = re.sub(redis_comment_block_pattern, '\n', content, count=1)

content = re.sub(r'    depends_on:\n(?=\s{0,4}\S|\s*\n)', '', content)

# Ensure Dify services resolve shared FortisAI service names.
content = content.replace(
    'networks:\n  default:\n    driver: bridge\n',
    'networks:\n  default:\n    name: fortisai-dev-net\n    external: true\n'
)
with open(f, 'w') as fp:
    fp.write(content)
print('docker-compose.yaml patched; original saved as docker-compose.yaml.orig')
PYEOF
  fi

  if [[ -f "$compose_file" ]] && ! grep -q 'QDRANT_HOST_PORT' "$compose_file"; then
    python3 - "$compose_file" <<'PYEOF'
import sys

compose_file = sys.argv[1]
with open(compose_file, encoding='utf-8') as handle:
    content = handle.read()

needle = "    volumes:\n      - ./volumes/qdrant:/qdrant/storage\n"
replacement = needle + "    ports:\n      - \"${QDRANT_HOST_PORT:-6333}:6333\"\n      - \"${QDRANT_GRPC_HOST_PORT:-6334}:6334\"\n"

if needle in content and "QDRANT_HOST_PORT" not in content:
    content = content.replace(needle, replacement, 1)

with open(compose_file, 'w', encoding='utf-8') as handle:
    handle.write(content)
PYEOF
  fi

  if ! grep -q '^FORTISAI_ORACLE_DB_HOST=' "$DIFY_DOCKER_DIR/.env"; then
    cat >> "$DIFY_DOCKER_DIR/.env" <<EOF

# FortisAI local Oracle AI Database Free connection details
FORTISAI_SHARED_NETWORK=$FORTISAI_SHARED_NETWORK
FORTISAI_ORACLE_DB_HOST=fortisai-oracle-db
FORTISAI_ORACLE_DB_PORT=$ORACLE_DB_HOST_PORT
FORTISAI_ORACLE_DB_PDB=$ORACLE_DB_PDB
FORTISAI_ORACLE_DB_USER=$ORACLE_DB_USER
FORTISAI_ORACLE_DB_PASSWORD=$ORACLE_DB_PASSWORD
FORTISAI_VAULT_ADDR=$VAULT_INTERNAL_URL
VAULT_ADDR=$VAULT_INTERNAL_URL
EOF
  fi

  if [[ -n "$VAULT_TOKEN" ]]; then
    upsert_env_var "$DIFY_DOCKER_DIR/.env" "VAULT_TOKEN" "$VAULT_TOKEN"
  fi
  upsert_env_var "$DIFY_DOCKER_DIR/.env" "FORTISAI_VAULT_ADDR" "$VAULT_INTERNAL_URL"
  upsert_env_var "$DIFY_DOCKER_DIR/.env" "VAULT_ADDR" "$VAULT_INTERNAL_URL"

  if [[ -f "$compose_file" ]]; then
    python3 - "$compose_file" "$DIFY_VAULT_COMPOSE_FILE" "$VAULT_INTERNAL_URL" "$VAULT_TOKEN" "$FORTISAI_LLAMA_SERVER_URL" "$FORTISAI_LLAMA_SERVER_BASE_URL" "$FORTISAI_LLAMA_OPENAI_BASE_URL" "$FORTISAI_LLAMA_OPENAI_API_KEY" <<'PYEOF'
import json
import re
import sys
from pathlib import Path

(
    compose_file,
    override_file,
    vault_addr,
    vault_token,
    llama_server_url,
    llama_server_base_url,
    llama_openai_base_url,
    llama_openai_api_key,
) = sys.argv[1:9]
content = Path(compose_file).read_text(encoding="utf-8")
services = set(re.findall(r"(?m)^  ([A-Za-z0-9_-]+):\s*$", content))
targets = [name for name in ("api", "worker", "worker_beat", "web", "plugin_daemon", "sandbox") if name in services]
override_path = Path(override_file)

if not targets:
    if override_path.exists():
        override_path.unlink()
    sys.exit(0)

lines = ["services:"]
for service in targets:
    lines.extend([
        f"  {service}:",
        "    environment:",
        f"      FORTISAI_VAULT_ADDR: {json.dumps(vault_addr)}",
        f"      VAULT_ADDR: {json.dumps(vault_addr)}",
        f"      VAULT_TOKEN: {json.dumps(vault_token)}",
        f"      FORTISAI_LLAMA_SERVER_URL: {json.dumps(llama_server_url)}",
        f"      FORTISAI_LLAMA_SERVER_BASE_URL: {json.dumps(llama_server_base_url)}",
        f"      FORTISAI_LLAMA_OPENAI_BASE_URL: {json.dumps(llama_openai_base_url)}",
        f"      FORTISAI_LLAMA_OPENAI_API_KEY: {json.dumps(llama_openai_api_key)}",
    ])

override_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
PYEOF
  fi

  log "Creating Dify shared-services launcher script"
  cat > "$DIFY_UP_SCRIPT" <<'BASH'
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yaml"
VAULT_COMPOSE_FILE="$SCRIPT_DIR/docker-compose.fortisai-vault.yaml"
VECTOR_PROFILE="qdrant"
compose_args=(-f "$COMPOSE_FILE")
if [[ -f "$VAULT_COMPOSE_FILE" ]]; then
  compose_args+=(-f "$VAULT_COMPOSE_FILE")
fi

if [[ -n "${DIFY_KEYS_JSON_FILE:-}" && -f "$DIFY_KEYS_JSON_FILE" ]]; then
  eval "$(DIFY_KEYS_JSON_FILE="$DIFY_KEYS_JSON_FILE" python3 - <<'PY'
import json
import os
from pathlib import Path

cfg = Path(os.environ["DIFY_KEYS_JSON_FILE"])
try:
    data = json.loads(cfg.read_text(encoding="utf-8"))
except Exception:
    data = {}

app = str(data.get("dify_app_api_key") or "").strip()
knowledge = str(data.get("dify_knowledge_api_key") or "").strip()
api = str(data.get("dify_api_key") or data.get("dify_admin_api_key") or data.get("admin_api_key") or "").strip()

print(f'export APP_API_KEY="{app}"')
print(f'export KNOWLEDGE_API_KEY="{knowledge}"')
print(f'export ADMIN_API_KEY_ENABLE="true"')
print(f'export DIFY_API_KEY="{api}"')
print(f'export ADMIN_API_KEY="{api}"')
PY
)"
fi

echo "[fortisai-dev] Starting Dify (${VECTOR_PROFILE} profile, shared Redis + pgvector)"

required_services="docker_api_1 docker_worker_1 docker_worker_beat_1 docker_nginx_1"
vault_services="docker_api_1 docker_worker_1 docker_worker_beat_1 docker_web_1 docker_sandbox_1 docker_plugin_daemon_1"
all_dify_containers="docker_web_1 docker_sandbox_1 docker_plugin_daemon_1 docker_ssrf_proxy_1 docker_qdrant_1 docker_api_1 docker_worker_1 docker_worker_beat_1 docker_nginx_1 docker_init_permissions_1"

container_has_vault_runtime_env() {
  local container="$1"
  local env_lines
  env_lines="$(podman inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "$container" 2>/dev/null || true)"
  printf '%s\n' "$env_lines" | grep -q '^VAULT_TOKEN=.' &&
    printf '%s\n' "$env_lines" | grep -q '^VAULT_ADDR=.' &&
    printf '%s\n' "$env_lines" | grep -q '^FORTISAI_VAULT_ADDR=.'
}

vault_runtime_refresh_needed=false
if [[ -f "$VAULT_COMPOSE_FILE" ]]; then
  for svc in $vault_services; do
    if podman ps --format '{{.Names}}' | grep -qx "$svc" && ! container_has_vault_runtime_env "$svc"; then
      vault_runtime_refresh_needed=true
      break
    fi
  done
fi

all_required_running=true
for svc in $required_services; do
  if ! podman ps --format '{{.Names}}' | grep -qx "$svc"; then
    all_required_running=false
    break
  fi
done

if [ "$all_required_running" = true ] && [ "$vault_runtime_refresh_needed" = false ]; then
  echo "[fortisai-dev] Dify core services are already running"
  exit 0
fi

if [ "$vault_runtime_refresh_needed" = true ]; then
  echo "[fortisai-dev] Recreating Dify containers to apply Vault runtime env"
  podman-compose "${compose_args[@]}" --profile "$VECTOR_PROFILE" down --remove-orphans >/dev/null 2>&1 || true
fi

for container in $all_dify_containers; do
  if podman container exists "$container" && ! podman ps --format '{{.Names}}' | grep -qx "$container"; then
    podman start "$container" >/dev/null 2>&1 || true
  fi
done

all_required_running=true
for svc in $required_services; do
  if ! podman ps --format '{{.Names}}' | grep -qx "$svc"; then
    all_required_running=false
    break
  fi
done

if [ "$all_required_running" = true ] && [ "$vault_runtime_refresh_needed" = false ]; then
  echo "[fortisai-dev] Dify core services were restarted from existing containers"
  exit 0
fi

echo "[fortisai-dev] Recreating Dify containers from compose"
podman-compose "${compose_args[@]}" --profile "$VECTOR_PROFILE" down --remove-orphans >/dev/null 2>&1 || true
for container in $all_dify_containers; do
  if podman container exists "$container"; then
    podman rm -f "$container" >/dev/null 2>&1 || true
    waited=0
    while podman container exists "$container"; do
      if [ "$waited" -ge 20 ]; then
        echo "[fortisai-dev] Timed out waiting for Dify container removal: $container" >&2
        exit 1
      fi
      sleep 1
      waited=$((waited + 1))
    done
  fi
done

echo "[fortisai-dev] Preflight: validating compose file"
if ! podman-compose "${compose_args[@]}" --profile "$VECTOR_PROFILE" config >/dev/null; then
  echo "[fortisai-dev] Compose preflight failed. Fix compose/network config and retry." >&2
  exit 1
fi

echo "[fortisai-dev] Preflight passed"
if ! podman-compose "${compose_args[@]}" --profile "$VECTOR_PROFILE" up -d --no-recreate; then
  echo "[fortisai-dev] Compose up returned non-zero; attempting recovery for transient libpod failures"
fi

created_containers="$(podman ps -a --format '{{.Names}} {{.Status}}' | awk '/^docker_/ && $0 ~ /^.* Created( |$)/ {print $1}')"
if [ -n "$created_containers" ]; then
  echo "[fortisai-dev] Recovering Created containers: $created_containers"
  while IFS= read -r container; do
    [ -z "$container" ] && continue
    recovered=false
    for _ in 1 2 3; do
      if podman start "$container" >/dev/null; then
        recovered=true
        break
      fi
    done

    if [ "$recovered" = false ]; then
      service_name="$container"
      service_name="${service_name#docker_}"
      service_name="${service_name%_1}"
      echo "[fortisai-dev] Recreating stubborn container via service '$service_name'"
      podman rm -f "$container" >/dev/null 2>&1 || true
      podman-compose "${compose_args[@]}" --profile "$VECTOR_PROFILE" up -d --no-deps "$service_name" >/dev/null || true
    fi
  done <<< "$created_containers"
fi

missing_services=""
max_wait_seconds=180
wait_step_seconds=3
elapsed_seconds=0

while true; do
  missing_services=""
  for svc in $required_services; do
    if ! podman ps --format '{{.Names}}' | grep -qx "$svc"; then
      missing_services="$missing_services $svc"
    fi
  done

  if [ -z "$missing_services" ]; then
    break
  fi

  if [ "$elapsed_seconds" -ge "$max_wait_seconds" ]; then
    break
  fi

  sleep "$wait_step_seconds"
  elapsed_seconds=$((elapsed_seconds + wait_step_seconds))
done

if [ -z "$missing_services" ]; then
  echo "[fortisai-dev] Dify start command completed"
else
  echo "[fortisai-dev] Some required services are not running after ${max_wait_seconds}s:$missing_services" >&2
  echo "[fortisai-dev] Tip: run podman ps -a --format 'table {{.Names}}\t{{.Status}}' | grep docker_" >&2
  exit 1
fi
BASH
  chmod +x "$DIFY_UP_SCRIPT"
}

setup_oracle_wallet_dir() {
  mkdir -p "$ORACLE_WALLET_DIR"

  if [[ ! -f "$ORACLE_DB_WALLET_ENV_FILE" ]]; then
    cat > "$ORACLE_DB_WALLET_ENV_FILE" <<EOF
ORACLE_DB_HOST=$ORACLE_DB_CONTAINER_NAME
ORACLE_DB_PORT=$ORACLE_DB_HOST_PORT
ORACLE_DB_SERVICE_NAME=$ORACLE_DB_PDB
ORACLE_DB_USER=$ORACLE_DB_USER
ORACLE_DB_PASSWORD=$ORACLE_DB_PASSWORD
ORACLE_DB_CONNECT_STRING=localhost:$ORACLE_DB_HOST_PORT/$ORACLE_DB_PDB
ORACLE_WALLET_DIR=/opt/oracle/wallet
TNS_ADMIN=/opt/oracle/wallet
EOF
    chmod 600 "$ORACLE_DB_WALLET_ENV_FILE"
  fi

  if [[ ! -f "$ORACLE_DB_WALLET_SCRIPT_FILE" ]]; then
    cat > "$ORACLE_DB_WALLET_SCRIPT_FILE" <<'BASH'
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ ! -f "$SCRIPT_DIR/oracle-db.env" ]]; then
  echo "Missing wallet env file: $SCRIPT_DIR/oracle-db.env" >&2
  exit 1
fi

# shellcheck disable=SC1091
source "$SCRIPT_DIR/oracle-db.env"

cat <<EOF
ORACLE_DB_HOST=$ORACLE_DB_HOST
ORACLE_DB_PORT=$ORACLE_DB_PORT
ORACLE_DB_SERVICE_NAME=$ORACLE_DB_SERVICE_NAME
ORACLE_DB_USER=$ORACLE_DB_USER
ORACLE_DB_PASSWORD=$ORACLE_DB_PASSWORD
ORACLE_WALLET_DIR=$ORACLE_WALLET_DIR
TNS_ADMIN=$TNS_ADMIN
EOF
BASH
    chmod +x "$ORACLE_DB_WALLET_SCRIPT_FILE"
  fi

  if [[ ! -f "$ORACLE_WALLET_ENV_FILE" ]]; then
    cat > "$ORACLE_WALLET_ENV_FILE" <<'BASH'
#!/usr/bin/env bash
set -euo pipefail

export ORACLE_WALLET_DIR="${ORACLE_WALLET_DIR:-$HOME/fortisai-dev/oracle-wallet}"
export ORACLE_WALLET_ZIP="${ORACLE_WALLET_ZIP:-$ORACLE_WALLET_DIR/oracle-wallet.zip}"
export ORACLE_WALLET_UNZIP_DIR="${ORACLE_WALLET_UNZIP_DIR:-$ORACLE_WALLET_DIR/unzipped}"
export TNS_ADMIN="${TNS_ADMIN:-$ORACLE_WALLET_UNZIP_DIR}"
BASH
    chmod +x "$ORACLE_WALLET_ENV_FILE"
  fi

  if [[ ! -f "$ORACLE_WALLET_SETUP_FILE" ]]; then
    cat > "$ORACLE_WALLET_SETUP_FILE" <<'BASH'
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$SCRIPT_DIR/unzipped"

echo "Oracle wallet directory ready: $SCRIPT_DIR"
echo "Place an OCI wallet zip at: $SCRIPT_DIR/oracle-wallet.zip"
echo "Source this file to export wallet variables: . $SCRIPT_DIR/wallet-env.sh"
echo "Run the credentials helper for DB inputs and ewallet.p12 generation: $SCRIPT_DIR/oracle-wallet-credentials.sh --help"
BASH
    chmod +x "$ORACLE_WALLET_SETUP_FILE"
  fi

  if [[ ! -f "$ORACLE_WALLET_CREDENTIALS_HELP_FILE" ]]; then
    cat > "$ORACLE_WALLET_CREDENTIALS_HELP_FILE" <<'BASH'
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

mkdir -p "$wallet_dir"

db_host="$(prompt_value "Oracle DB host" "$db_host")"
db_port="$(prompt_value "Oracle DB port" "$db_port")"
db_service_name="$(prompt_value "Oracle DB service name" "$db_service_name")"
db_user="$(prompt_value "Oracle DB user" "$db_user")"
db_password="$(prompt_value "Oracle DB password" "$db_password" true)"
connect_string="$(prompt_value "Oracle DB connect string" "$connect_string")"

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
    p12_password="$(prompt_value "ewallet.p12 password" "$p12_password" true)"
  fi

  if ! command -v openssl >/dev/null 2>&1; then
    echo "openssl is required to build ewallet.p12 from certificate and private key files." >&2
    exit 1
  fi

  openssl pkcs12 -export \
    -in "$certificate_file" \
    -inkey "$private_key_file" \
    -out "$p12_output" \
    -name "$alias_name" \
    -passout "pass:$p12_password"
fi

cat > "$wallet_dir/oracle-wallet-credentials.env" <<EOF
ORACLE_DB_HOST=$db_host
ORACLE_DB_PORT=$db_port
ORACLE_DB_SERVICE_NAME=$db_service_name
ORACLE_DB_USER=$db_user
ORACLE_DB_PASSWORD=$db_password
ORACLE_DB_CONNECT_STRING=$connect_string
ORACLE_WALLET_DIR=$wallet_dir
ORACLE_WALLET_P12=${p12_output:-$wallet_dir/ewallet.p12}
ORACLE_WALLET_CERTIFICATE_FILE=$certificate_file
ORACLE_WALLET_PRIVATE_KEY_FILE=$private_key_file
EOF

chmod 600 "$wallet_dir/oracle-wallet-credentials.env" 2>/dev/null || true

cat <<EOF
Oracle wallet credential helper complete.
Wallet directory: $wallet_dir
Credential env file: $wallet_dir/oracle-wallet-credentials.env
EOF
BASH
    chmod +x "$ORACLE_WALLET_CREDENTIALS_HELP_FILE"
  fi
}

setup() {
  require_cmd podman
  require_cmd curl
  require_cmd jq
  normalize_hermes_dashboard
  validate_firecrawl_port
  validate_openclaw_ports
  validate_hermes_ports

  ensure_machine
  ensure_shared_network
  setup_oracle_wallet_dir
  prepare_vault_runtime_secrets
  oracle_db_pull
  pull_ords_sqlcl_images
  write_n8n_compose
  write_openwebui_compose
  write_openvscode_compose
  write_mongodb_compose
  write_appsmith_compose
  write_redis_compose
  write_rabbitmq_compose
  write_vault_compose
  write_firecrawl_compose
  write_pgvector_compose
  write_milvus_compose
  write_opensearch_compose
  write_openmetadata_compose
  write_traefik_compose
  write_oracle_db_compose
  write_ords_compose
  write_sqlcl_compose
  write_sqlcl_mcp_config
  setup_honcho_repo
  setup_openapi_servers_repo
  write_openapi_servers_openwebui_template
  write_honcho_compose
  setup_openclaw_runtime
  write_openclaw_compose
  write_hermes_compose
  if [[ ! -f "$ORACLE_NODE_API_COMPOSE_FILE" ]]; then
    err "Oracle Node API compose file not found: $ORACLE_NODE_API_COMPOSE_FILE"
    err "Expected project path: $DEV_ENV_DIR/oracle-node-api"
    exit 1
  fi
  setup_dify_repo

  log "Setup complete"
  log "Base directory: $BASE_DIR"
  log "Oracle wallet directory: $ORACLE_WALLET_DIR"
  log "SQLcl MCP config: $SQLCL_MCP_CONFIG_FILE"
}

n8n_import_workflows() {
  ensure_machine
  local importer="$DEV_ENV_DIR/n8n-config/import-n8n-workflows.sh"
  [[ -x "$importer" ]] || { err "n8n importer script not found: $importer"; return 1; }
  vault_up
  vault_unseal
  if [[ -z "${N8N_API_KEY:-}" ]]; then
    log "N8N_API_KEY is not available; importer will use local n8n CLI activation if needed"
  fi
  write_n8n_compose
  start_n8n_stack
  N8N_API_KEY="${N8N_API_KEY:-}" N8N_API_URL="${N8N_API_URL:-http://127.0.0.1:$N8N_HOST_PORT/api/v1}" "$importer" "$@"
}

setup_openclaw() {
  require_cmd podman
  validate_openclaw_ports

  ensure_machine
  ensure_shared_network
  write_vault_compose
  setup_openclaw_runtime
  write_openclaw_compose
}

up() {
  setup

  log "Starting Vault"
  vault_up
  vault_unseal
  vault_sync_runtime_secrets

  log "Starting Oracle AI Database Free"
  start_compose_container "$ORACLE_DB_COMPOSE_FILE" "$ORACLE_DB_CONTAINER_NAME"

  wait_for_oracle_db
  init_ords_config

  log "Starting n8n"
  start_n8n_stack

  log "Starting OpenWebUI"
  start_openwebui

  log "Starting OpenVSCode"
  start_openvscode

  log "Starting MongoDB"
  start_compose_container "$MONGODB_COMPOSE_FILE" "$MONGODB_CONTAINER_NAME"

  ensure_mongodb_replica_set

  log "Starting Appsmith"
  start_compose_container "$APPSMITH_COMPOSE_FILE" "$APPSMITH_CONTAINER_NAME"

  log "Starting OpenAPI servers"
  start_openapi_servers_stack
  wire_repo_openapi_servers_into_openwebui

  log "Starting Redis"
  start_compose_container "$REDIS_COMPOSE_FILE" "$REDIS_CONTAINER_NAME"

  log "Starting RabbitMQ"
  start_compose_container "$RABBITMQ_COMPOSE_FILE" "$RABBITMQ_CONTAINER_NAME"

  log "Starting pgvector"
  start_compose_container "$PGVECTOR_COMPOSE_FILE" "$PGVECTOR_CONTAINER_NAME"

  ensure_firecrawl_database

  log "Starting Firecrawl"
  start_compose_container "$FIRECRAWL_COMPOSE_FILE" "$FIRECRAWL_CONTAINER_NAME"

  ensure_honcho_database

  log "Starting Honcho (API + deriver)"
  start_honcho_stack

  log "Starting Dify (qdrant profile; shared Redis + pgvector)"
  DIFY_KEYS_JSON_FILE="$DIFY_KEYS_JSON_FILE" "$DIFY_UP_SCRIPT"

  log "Starting ORDS"
  start_compose_container "$ORDS_COMPOSE_FILE" "$ORDS_CONTAINER_NAME"

  log "Starting SQLcl sidecar"
  start_compose_container "$SQLCL_COMPOSE_FILE" "$SQLCL_CONTAINER_NAME"

  log "Starting Oracle Node API"
  local podman_socket_path
  podman_socket_path="$(resolve_podman_socket_path)"
  PODMAN_SOCKET_PATH="$podman_socket_path" start_compose_container "$ORACLE_NODE_API_COMPOSE_FILE" "$ORACLE_NODE_API_CONTAINER_NAME" --build

  log "SQLcl MCP config ready: $SQLCL_MCP_CONFIG_FILE"

  log "All services started"
}

down() {
  ensure_machine

  if [[ -f "$ORACLE_DB_COMPOSE_FILE" ]]; then
    log "Stopping Oracle AI Database Free"
    run_compose -f "$ORACLE_DB_COMPOSE_FILE" down
  fi

  if [[ -f "$N8N_COMPOSE_FILE" ]]; then
    log "Stopping n8n"
    run_compose -f "$N8N_COMPOSE_FILE" down
  fi

  if [[ -f "$OPENWEBUI_COMPOSE_FILE" ]]; then
    log "Stopping OpenWebUI"
    stop_openwebui
  fi

  if [[ -f "$OPENVSCODE_COMPOSE_FILE" ]]; then
    log "Stopping OpenVSCode"
    stop_openvscode
  fi

  if [[ -f "$APPSMITH_COMPOSE_FILE" ]]; then
    log "Stopping Appsmith"
    run_compose -f "$APPSMITH_COMPOSE_FILE" down
  fi

  if [[ -f "$MONGODB_COMPOSE_FILE" ]]; then
    log "Stopping MongoDB"
    run_compose -f "$MONGODB_COMPOSE_FILE" down
  fi

  if [[ -f "$OPENAPI_SERVERS_COMPOSE_FILE" ]]; then
    log "Stopping OpenAPI servers"
    run_compose -f "$OPENAPI_SERVERS_COMPOSE_FILE" down
  fi

  if [[ -f "$REDIS_COMPOSE_FILE" ]]; then
    log "Stopping Redis"
    run_compose -f "$REDIS_COMPOSE_FILE" down
  fi

  if [[ -f "$RABBITMQ_COMPOSE_FILE" ]]; then
    log "Stopping RabbitMQ"
    run_compose -f "$RABBITMQ_COMPOSE_FILE" down
  fi

  if [[ -f "$VAULT_COMPOSE_FILE" ]]; then
    log "Stopping HashiCorp Vault"
    run_compose -f "$VAULT_COMPOSE_FILE" down
  fi

  if [[ -f "$FIRECRAWL_COMPOSE_FILE" ]]; then
    log "Stopping Firecrawl"
    run_compose -f "$FIRECRAWL_COMPOSE_FILE" down
  fi

  if [[ -f "$PGVECTOR_COMPOSE_FILE" ]]; then
    log "Stopping pgvector"
    run_compose -f "$PGVECTOR_COMPOSE_FILE" down
  fi

  if [[ -f "$HONCHO_COMPOSE_FILE" ]]; then
    log "Stopping Honcho"
    run_compose -f "$HONCHO_COMPOSE_FILE" down
  fi

  if [[ -f "$DIFY_DOCKER_DIR/docker-compose.yaml" || -f "$DIFY_DOCKER_DIR/docker-compose.yml" ]]; then
    log "Stopping Dify"
    (
      cd "$DIFY_DOCKER_DIR"
      run_compose --profile qdrant down
    )
  fi

  if [[ -f "$ORDS_COMPOSE_FILE" ]]; then
    log "Stopping ORDS"
    run_compose -f "$ORDS_COMPOSE_FILE" down
  fi

  if [[ -f "$SQLCL_COMPOSE_FILE" ]]; then
    log "Stopping SQLcl sidecar"
    run_compose -f "$SQLCL_COMPOSE_FILE" down
  fi

  if [[ -f "$ORACLE_NODE_API_COMPOSE_FILE" ]]; then
    log "Stopping Oracle Node API"
    run_compose -f "$ORACLE_NODE_API_COMPOSE_FILE" down
  fi

  log "All services stopped"
}

openclaw_up() {
  prepare_vault_runtime_secrets
  setup_openclaw
  vault_up
  vault_unseal
  log "Starting OpenClaw"
  start_compose_container "$OPENCLAW_COMPOSE_FILE" "$OPENCLAW_CONTAINER_NAME"
}

openclaw_down() {
  ensure_machine
  if [[ -f "$OPENCLAW_COMPOSE_FILE" ]]; then
    log "Stopping OpenClaw"
    run_compose -f "$OPENCLAW_COMPOSE_FILE" down
  elif container_exists "$OPENCLAW_CONTAINER_NAME"; then
    log "Stopping OpenClaw"
    podman rm -f "$OPENCLAW_CONTAINER_NAME" >/dev/null 2>&1 || true
  fi
}

hermes_up() {
  prepare_vault_runtime_secrets
  setup
  log "Starting Hermes Agent"
  run_compose -f "$HERMES_COMPOSE_FILE" up -d
}

hermes_down() {
  ensure_machine
  if [[ -f "$HERMES_COMPOSE_FILE" ]]; then
    log "Stopping Hermes Agent"
    run_compose -f "$HERMES_COMPOSE_FILE" down
  fi
}

vault_up() {
  ensure_machine
  ensure_shared_network
  write_vault_compose
  log "Starting HashiCorp Vault"
  start_compose_container "$VAULT_COMPOSE_FILE" "$VAULT_CONTAINER_NAME"
  log "Vault URL: $VAULT_URL"
}

vault_down() {
  ensure_machine
  if [[ -f "$VAULT_COMPOSE_FILE" ]]; then
    log "Stopping HashiCorp Vault"
    run_compose -f "$VAULT_COMPOSE_FILE" down
  fi
}

wait_for_vault() {
  local attempts=30
  while (( attempts > 0 )); do
    local status_code=0
    podman exec -e VAULT_ADDR=http://127.0.0.1:8200 "$VAULT_CONTAINER_NAME" vault status >/dev/null 2>&1 || status_code=$?
    if [[ "$status_code" == "0" || "$status_code" == "2" ]]; then
      return 0
    fi
    sleep 2
    ((attempts--))
  done

  err "Vault did not become reachable in time"
  return 1
}

vault_initialized() {
  local status_json
  status_json="$(podman exec -e VAULT_ADDR=http://127.0.0.1:8200 "$VAULT_CONTAINER_NAME" vault status -format=json 2>/dev/null || true)"
  grep -q '"initialized"[[:space:]]*:[[:space:]]*true' <<<"$status_json"
}

vault_sealed() {
  local status_json
  status_json="$(podman exec -e VAULT_ADDR=http://127.0.0.1:8200 "$VAULT_CONTAINER_NAME" vault status -format=json 2>/dev/null || true)"
  grep -q '"sealed"[[:space:]]*:[[:space:]]*true' <<<"$status_json"
}

vault_init() {
  require_cmd python3
  if ! container_running "$VAULT_CONTAINER_NAME"; then
    vault_up
  fi

  wait_for_vault

  if vault_initialized; then
    log "Vault is already initialized"
    log "Init key file: $VAULT_KEYS_FILE"
    return
  fi

  if [[ -f "$VAULT_KEYS_FILE" ]]; then
    err "Vault is uninitialized, but key file already exists: $VAULT_KEYS_FILE"
    err "Move that file aside before reinitializing."
    exit 1
  fi

  log "Initializing Vault with one local unseal key"
  umask 077
  podman exec -e VAULT_ADDR=http://127.0.0.1:8200 "$VAULT_CONTAINER_NAME" \
    vault operator init -key-shares=1 -key-threshold=1 -format=json > "$VAULT_KEYS_FILE"
  chmod 600 "$VAULT_KEYS_FILE" 2>/dev/null || true

  log "Vault init credentials saved to $VAULT_KEYS_FILE"
  log "Keep this file local; it contains the root token and unseal key."
  vault_unseal
}

vault_unseal() {
  require_cmd python3
  if ! container_running "$VAULT_CONTAINER_NAME"; then
    err "Vault container is not running. Start it with: $SCRIPT_NAME vault-up"
    exit 1
  fi

  wait_for_vault

  if ! vault_initialized; then
    err "Vault is not initialized. Run: $SCRIPT_NAME vault-init"
    exit 1
  fi

  if ! vault_sealed; then
    log "Vault is already unsealed"
    return
  fi

  if [[ ! -f "$VAULT_KEYS_FILE" ]]; then
    err "Vault init key file not found: $VAULT_KEYS_FILE"
    err "Run: $SCRIPT_NAME vault-init"
    exit 1
  fi

  local unseal_key
  unseal_key="$(VAULT_KEYS_FILE="$VAULT_KEYS_FILE" python3 - <<'PY'
import json
import os
from pathlib import Path

payload = json.loads(Path(os.environ["VAULT_KEYS_FILE"]).read_text())
keys = payload.get("unseal_keys_b64") or payload.get("unseal_keys_hex") or []
print(keys[0] if keys else "")
PY
)"

  if [[ -z "$unseal_key" ]]; then
    err "Could not read unseal key from $VAULT_KEYS_FILE"
    exit 1
  fi

  podman exec -e VAULT_ADDR=http://127.0.0.1:8200 "$VAULT_CONTAINER_NAME" vault operator unseal "$unseal_key" >/dev/null
  log "Vault unsealed"
}

vault_status() {
  ensure_machine
  if ! container_running "$VAULT_CONTAINER_NAME"; then
    log "Vault container is not running"
    return
  fi
  podman exec -e VAULT_ADDR=http://127.0.0.1:8200 "$VAULT_CONTAINER_NAME" vault status || true
}

status() {
  ensure_machine
  podman ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
  if [[ -f "$SQLCL_MCP_CONFIG_FILE" ]]; then
    printf '%s\n' "sqlcl_mcp_config: $SQLCL_MCP_CONFIG_FILE"
  else
    printf '%s\n' "sqlcl_mcp_config: not-generated"
  fi
  if [[ -f "$OPENAPI_SERVERS_JSON_TEMPLATE_FILE" ]]; then
    printf '%s\n' "openapi_openwebui_template: $OPENAPI_SERVERS_JSON_TEMPLATE_FILE"
  else
    printf '%s\n' "openapi_openwebui_template: not-generated"
  fi
}

logs() {
  local target="${1:-all}"
  ensure_machine

  case "$target" in
    oracle-db)
      podman logs -f "$ORACLE_DB_CONTAINER_NAME"
      ;;
    n8n)
      podman logs -f fortisai-n8n
      ;;
    openwebui)
      podman logs -f fortisai-openwebui
      ;;
    openvscode)
      podman logs -f "$OPENVSCODE_CONTAINER_NAME"
      ;;
    appsmith)
      podman logs -f "$APPSMITH_CONTAINER_NAME"
      ;;
    mongodb)
      podman logs -f "$MONGODB_CONTAINER_NAME"
      ;;
    redis)
      podman logs -f "$REDIS_CONTAINER_NAME"
      ;;
    rabbitmq)
      podman logs -f "$RABBITMQ_CONTAINER_NAME"
      ;;
    vault)
      podman logs -f "$VAULT_CONTAINER_NAME"
      ;;
    firecrawl)
      podman logs -f "$FIRECRAWL_CONTAINER_NAME"
      ;;
    traefik)
      podman logs -f "$TRAEFIK_CONTAINER_NAME"
      ;;
    codeindexer)
      podman logs -f "$CODEINDEXER_BRIDGE_CONTAINER_NAME"
      ;;
    milvus)
      podman logs -f "$MILVUS_CONTAINER_NAME"
      ;;
    openmetadata)
      podman logs -f "$OPENMETADATA_CONTAINER_NAME"
      ;;
    opensearch)
      podman logs -f "$OPENSEARCH_CONTAINER_NAME"
      ;;
    pgvector)
      podman logs -f "$PGVECTOR_CONTAINER_NAME"
      ;;
    honcho)
      run_compose -f "$HONCHO_COMPOSE_FILE" logs -f api deriver
      ;;
    openapi-servers)
      run_compose -f "$OPENAPI_SERVERS_COMPOSE_FILE" logs -f filesystem-server memory-server time-server
      ;;
    openclaw)
      podman logs -f "$OPENCLAW_CONTAINER_NAME"
      ;;
    hermes)
      podman logs -f "$HERMES_CONTAINER_NAME"
      ;;
    qdrant)
      (
        cd "$DIFY_DOCKER_DIR"
        run_compose logs -f qdrant
      )
      ;;
    dify)
      (
        cd "$DIFY_DOCKER_DIR"
        run_compose logs -f
      )
      ;;
    daytona)
      (
        cd "$DAYTONA_REPO_DIR"
        run_compose -f "$DAYTONA_RUNTIME_FILE" logs -f
      )
      ;;
    ords)
      podman logs -f "$ORDS_CONTAINER_NAME"
      ;;
    sqlcl)
      podman logs -f "$SQLCL_CONTAINER_NAME"
      ;;
    oracle-node-api)
      podman logs -f "$ORACLE_NODE_API_CONTAINER_NAME"
      ;;
    sqlcl-mcp)
      err "SQLcl MCP uses stdio, not container logs. Run: $SCRIPT_NAME sqlcl-mcp"
      ;;
    all)
      log "Use one target: oracle-db | mongodb | redis | rabbitmq | vault | firecrawl | pgvector | honcho | openapi-servers | openclaw | hermes | n8n | openwebui | appsmith | qdrant | dify | daytona | traefik | codeindexer | milvus | openmetadata | opensearch | ords | sqlcl | oracle-node-api | sqlcl-mcp"
      ;;
    *)
      err "Unknown logs target: $target"
      usage
      exit 1
      ;;
  esac
}

check() {
  require_cmd curl

  log "Checking Oracle AI Database Free on port $ORACLE_DB_HOST_PORT"
  if container_running "$ORACLE_DB_CONTAINER_NAME"; then
    podman exec "$ORACLE_DB_CONTAINER_NAME" bash -lc "printf 'select 1 from dual;\nexit\n' | sqlplus -L pdbadmin/${ORACLE_DB_PASSWORD}@FREEPDB1" >/dev/null 2>&1 \
      && log "oracle-db SQL check passed" \
      || log "oracle-db SQL check unavailable"
  else
    log "oracle-db not running"
  fi

  log "Checking n8n: $N8N_URL"
  curl -sS -o /dev/null -w 'n8n HTTP %{http_code}\n' "$N8N_URL" || true

  log "Checking OpenWebUI: $OPENWEBUI_URL"
  curl -sS -o /dev/null -w 'openwebui HTTP %{http_code}\n' "$OPENWEBUI_URL" || true

  log "Checking Appsmith: $APPSMITH_URL"
  curl -sS -o /dev/null -w 'appsmith HTTP %{http_code}\n' "$APPSMITH_URL" || true

  log "Checking MongoDB: $MONGODB_CONTAINER_NAME"
  if container_running "$MONGODB_CONTAINER_NAME"; then
    podman exec "$MONGODB_CONTAINER_NAME" mongosh --quiet --eval 'db.adminCommand({ ping: 1 }).ok' >/dev/null 2>&1 \
      && log "mongodb ping passed" \
      || log "mongodb ping unavailable"
  else
    log "mongodb not running"
  fi

  log "Checking Redis: $REDIS_CONTAINER_NAME"
  if container_running "$REDIS_CONTAINER_NAME"; then
    podman exec "$REDIS_CONTAINER_NAME" redis-cli ping >/dev/null 2>&1 \
      && log "redis ping passed" \
      || log "redis ping unavailable"
  else
    log "redis not running"
  fi

  log "Checking RabbitMQ: $RABBITMQ_CONTAINER_NAME"
  if container_running "$RABBITMQ_CONTAINER_NAME"; then
    podman exec "$RABBITMQ_CONTAINER_NAME" rabbitmq-diagnostics -q ping >/dev/null 2>&1 \
      && log "rabbitmq ping passed" \
      || log "rabbitmq ping unavailable"
  else
    log "rabbitmq not running"
  fi

  log "Checking RabbitMQ management URL: $RABBITMQ_MANAGEMENT_URL"
  curl -sS -o /dev/null -w 'rabbitmq_mgmt HTTP %{http_code}\n' "$RABBITMQ_MANAGEMENT_URL" || true

  log "Checking Vault: $VAULT_URL/v1/sys/health"
  local vault_status
  vault_status="$(curl -sS -o /dev/null -w '%{http_code}' "$VAULT_URL/v1/sys/health" || echo 000)"
  case "$vault_status" in
    200|429|472|473)
      log "vault reachable (HTTP $vault_status)"
      ;;
    501)
      log "vault reachable but uninitialized (HTTP 501); run: $SCRIPT_NAME vault-init"
      ;;
    503)
      log "vault reachable but sealed (HTTP 503); run: $SCRIPT_NAME vault-unseal"
      ;;
    *)
      log "vault HTTP $vault_status"
      ;;
  esac

  log "Checking Firecrawl: $FIRECRAWL_CONTAINER_NAME"
  if container_running "$FIRECRAWL_CONTAINER_NAME"; then
    local firecrawl_status
    firecrawl_status="$(curl -sS -o /dev/null -w '%{http_code}' "$FIRECRAWL_URL/health" || echo 000)"
    if [[ "$firecrawl_status" == "000" ]]; then
      log "firecrawl HTTP unavailable"
    else
      log "firecrawl reachable (HTTP $firecrawl_status)"
    fi
  else
    log "firecrawl not running"
  fi

  log "Checking Traefik: $TRAEFIK_DASHBOARD_URL"
  curl -sS -o /dev/null -w 'traefik_dashboard HTTP %{http_code}\n' "$TRAEFIK_DASHBOARD_URL" || true

  log "Checking CodeIndexer bridge: $CODEINDEXER_OPENAPI_URL/healthz"
  curl -sS -o /dev/null -w 'codeindexer_bridge HTTP %{http_code}\n' "$CODEINDEXER_OPENAPI_URL/healthz" || true

  log "Checking Milvus: $MILVUS_URL"
  curl -sS -o /dev/null -w 'milvus HTTP %{http_code}\n' "$MILVUS_URL" || true

  log "Checking OpenMetadata: $OPENMETADATA_URL/api/v1/system/version"
  curl -sS -o /dev/null -w 'openmetadata HTTP %{http_code}\n' "$OPENMETADATA_URL/api/v1/system/version" || true

  log "Checking OpenSearch: $OPENSEARCH_URL"
  curl -sS -o /dev/null -w 'opensearch HTTP %{http_code}\n' "$OPENSEARCH_URL" || true

  log "Checking pgvector: $PGVECTOR_CONTAINER_NAME"
  if container_running "$PGVECTOR_CONTAINER_NAME"; then
    podman exec "$PGVECTOR_CONTAINER_NAME" pg_isready -U "$PGVECTOR_USER" -d "$PGVECTOR_DB" >/dev/null 2>&1 \
      && log "pgvector SQL check passed" \
      || log "pgvector SQL check unavailable"
  else
    log "pgvector not running"
  fi

  log "Checking Honcho: $HONCHO_URL/health"
  curl -sS -o /dev/null -w 'honcho HTTP %{http_code}\n' "$HONCHO_URL/health" || true

  log "Checking OpenClaw: $OPENCLAW_CONTAINER_NAME"
  if container_running "$OPENCLAW_CONTAINER_NAME"; then
    curl -sS -o /dev/null -w 'openclaw HTTP %{http_code}\n' "$OPENCLAW_URL/health" || true
  else
    log "openclaw not running (optional service)"
  fi

  log "Checking Hermes: $HERMES_CONTAINER_NAME"
  if container_running "$HERMES_CONTAINER_NAME"; then
    curl -sS -o /dev/null -w 'hermes HTTP %{http_code}\n' "$HERMES_URL/health" || true
  else
    log "hermes not running (optional service)"
  fi

  log "Checking Dify: $DIFY_URL"
  curl -sS -o /dev/null -w 'dify HTTP %{http_code}\n' "$DIFY_URL" || true

  log "Checking Qdrant: $QDRANT_URL/collections"
  curl -sS -H "api-key: $QDRANT_API_KEY" -o /dev/null -w 'qdrant HTTP %{http_code}\n' "$QDRANT_URL/collections" || true

  log "Checking ORDS: $ORDS_URL"
  curl -sS -o /dev/null -w 'ords HTTP %{http_code}\n' "$ORDS_URL" || true

  log "Checking Oracle Node API: $ORACLE_NODE_API_URL/health"
  curl -sS -o /dev/null -w 'oracle-node-api HTTP %{http_code}\n' "$ORACLE_NODE_API_URL/health" || true

  log "Checking SQLcl sidecar: $SQLCL_CONTAINER_NAME"
  if podman ps --format '{{.Names}}' | grep -qx "$SQLCL_CONTAINER_NAME"; then
    log "sqlcl container running"
  else
    log "sqlcl container not running"
  fi

  log "Checking SQLcl MCP config: $SQLCL_MCP_CONFIG_FILE"
  if [[ -f "$SQLCL_MCP_CONFIG_FILE" ]]; then
    log "sqlcl MCP config ready"
  else
    log "sqlcl MCP config not generated"
  fi
}

setup_lmstudio() {
  require_cmd open

  if [[ -d "/Applications/LM Studio.app" || -d "$HOME/Applications/LM Studio.app" ]]; then
    log "LM Studio app already installed"
    return
  fi

  if ! command -v brew >/dev/null 2>&1; then
    err "Homebrew is required to auto-install LM Studio on macOS"
    err "Install Homebrew first: https://brew.sh"
    err "Or install LM Studio manually from https://lmstudio.ai"
    exit 1
  fi

  log "Installing LM Studio via Homebrew cask"
  brew install --cask lm-studio
  log "LM Studio installed"
}

start_lmstudio() {
  setup_lmstudio
  log "Starting LM Studio"
  open -a "LM Studio"
  log "In LM Studio, load a model and enable the Local Server tab"
}

check_lmstudio() {
  require_cmd curl
  log "Checking LM Studio local API: $LMSTUDIO_MODELS_URL"
  curl -sS -o /dev/null -w 'lmstudio HTTP %{http_code}\n' "$LMSTUDIO_MODELS_URL" || true
}


daytona_wait_dashboard_ready() {
  require_cmd curl

  local max_wait="${DAYTONA_READY_TIMEOUT_SECONDS:-90}"
  local interval="${DAYTONA_READY_POLL_SECONDS:-3}"
  local elapsed=0
  local status=""

  while [[ "$elapsed" -lt "$max_wait" ]]; do
    status="$(curl -sS -o /dev/null -w '%{http_code}' "$DAYTONA_URL" 2>/dev/null || true)"
    case "$status" in
      200|301|302|307|308|401|403|404)
        log "Daytona dashboard HTTP status: $status"
        return 0
        ;;
    esac
    sleep "$interval"
    elapsed=$((elapsed + interval))
  done

  log "Daytona dashboard not ready after ${max_wait}s (status=${status:-unknown})"
}

daytona_up() {
  ensure_machine
  ensure_shared_network
  setup_daytona_repo
  daytona_log_gpu_mode

  if has_docker_compose; then
    log "Starting Daytona (self-hosted OSS) with Docker Compose for runner stability"
    (
      cd "$DAYTONA_REPO_DIR"
      docker compose -f "$DAYTONA_RUNTIME_FILE" up -d
    )
  else
    log "Docker Compose not detected; falling back to $(compose_cmd)."
    log "Warning: Daytona runner may restart continuously under Podman-only runtime."
    (
      cd "$DAYTONA_REPO_DIR"
      run_compose -f "$DAYTONA_RUNTIME_FILE" up -d
    )
  fi

  daytona_wait_dashboard_ready || true
  log "Daytona dashboard: $DAYTONA_URL"
}

daytona_down() {
  ensure_machine

  if [[ ! -f "$DAYTONA_COMPOSE_FILE" ]]; then
    log "Daytona not initialized; nothing to stop"
    return
  fi

  if has_docker_compose; then
    log "Stopping Daytona with Docker Compose"
    (
      cd "$DAYTONA_REPO_DIR"
      docker compose -f "$DAYTONA_RUNTIME_FILE" down
    )
  else
    log "Stopping Daytona"
    (
      cd "$DAYTONA_REPO_DIR"
      run_compose -f "$DAYTONA_RUNTIME_FILE" down
    )
  fi
}

daytona_check() {
  require_cmd curl
  log "Checking Daytona dashboard: $DAYTONA_URL"
  curl -sS -o /dev/null -w 'daytona HTTP %{http_code}\n' "$DAYTONA_URL" || true

  local restart_count
  restart_count="$(podman inspect daytona_runner_1 --format '{{.RestartCount}}' 2>/dev/null || echo not-found)"
  printf '%s\n' "daytona_runner_restarts: $restart_count"
  if [[ "$restart_count" != "not-found" && "$restart_count" =~ ^[0-9]+$ && "$restart_count" -gt 5 ]]; then
    log "Runner restart count is elevated. Use '$SCRIPT_NAME daytona-docker-smoke' for compatibility validation."
  fi

  daytona_gpu_check || true
}

daytona_docker_smoke() {
  require_cmd docker
  require_cmd curl

  if ! docker compose version >/dev/null 2>&1; then
    err "Docker Compose is required for this workflow (Docker Desktop recommended)."
    exit 1
  fi

  setup_daytona_repo
  ensure_shared_network

  log "Starting Daytona with Docker Compose for runner compatibility"
  (
    cd "$DAYTONA_REPO_DIR"
    docker compose -f "$DAYTONA_RUNTIME_FILE" down >/dev/null 2>&1 || true
    docker compose -f "$DAYTONA_RUNTIME_FILE" up -d
  )

  log "Checking Daytona endpoints"
  curl -sS -o /dev/null -w 'daytona_root HTTP %{http_code}\n' "$DAYTONA_URL" || true
  curl -sS -o /dev/null -w 'daytona_health HTTP %{http_code}\n' "$DAYTONA_URL/api/health" || true

  local runner_status
  runner_status="$(docker ps --format '{{.Names}} {{.Status}}' | awk '/daytona_runner/ {print $0; exit}')"
  if [[ -n "$runner_status" ]]; then
    printf '%s\n' "daytona_runner_status: $runner_status"
  else
    printf '%s\n' "daytona_runner_status: not-found"
  fi

  if [[ -n "${DAYTONA_API_KEY:-}" && -n "${DAYTONA_ORG_ID:-}" ]]; then
    log "Running sandbox create smoke request using DAYTONA_API_KEY and DAYTONA_ORG_ID"
    local payload
    payload='{"name":"docker-smoke-sandbox","target":"us"}'
    curl -sS -X POST "$DAYTONA_URL/api/sandbox" \
      -H "Authorization: Bearer $DAYTONA_API_KEY" \
      -H "X-Daytona-Organization-ID: $DAYTONA_ORG_ID" \
      -H 'Content-Type: application/json' \
      -d "$payload" | head -c 700
    printf '\n'
  else
    log "Set DAYTONA_API_KEY and DAYTONA_ORG_ID to include API sandbox-create smoke validation"
  fi
}

daytona_set_admin_creds() {
  local new_email="${1:-}"
  local new_password="${2:-}"

  if [[ -z "$new_email" || -z "$new_password" ]]; then
    err "Usage: $SCRIPT_NAME daytona-set-admin-creds <email> <password>"
    exit 1
  fi

  local dex_config="$DAYTONA_REPO_DIR/docker/dex/config.yaml"
  if [[ ! -f "$dex_config" ]]; then
    err "Dex config not found at $dex_config — run daytona-setup first."
    exit 1
  fi

  require_cmd htpasswd || { err "'htpasswd' not found. Install it with: brew install httpd"; exit 1; }

  local new_hash
  new_hash="$(printf '%s' "$new_password" | htpasswd -BinC 10 admin 2>/dev/null | cut -d: -f2)"
  if [[ -z "$new_hash" ]]; then
    err "Failed to generate bcrypt hash. Ensure htpasswd (apache2-utils / httpd) is installed."
    exit 1
  fi

  # Get current values for replacement
  local current_email
  current_email="$(grep "email:" "$dex_config" | head -1 | sed "s/.*email: *'//" | sed "s/'$//")"
  local current_hash
  current_hash="$(grep "hash:" "$dex_config" | head -1 | sed "s/.*hash: *'//" | sed "s/'$//")"

  if [[ -z "$current_email" || -z "$current_hash" ]]; then
    err "Could not parse current email/hash from $dex_config — verify the file format."
    exit 1
  fi

  # Replace email and hash in-place
  sed -i '' "s|email: '$current_email'|email: '$new_email'|g" "$dex_config"
  sed -i '' "s|hash: '.*'|hash: '$new_hash'|" "$dex_config"

  log "Daytona admin credentials updated in $dex_config"
  log "  Email:    $new_email"
  log "  Password: (bcrypt hash written)"
  log "Restart the Daytona stack to apply changes: $SCRIPT_NAME daytona-down && $SCRIPT_NAME daytona-up"
}

daytona_revoke_api_key() {
  local key_name="${1:-}"

  require_cmd curl
  if [[ -z "$key_name" ]]; then
    err "Usage: $SCRIPT_NAME daytona-revoke-key <key-name>"
    exit 1
  fi

  if [[ -z "${DAYTONA_API_KEY:-}" ]]; then
    err "DAYTONA_API_KEY is required to revoke API keys."
    exit 1
  fi

  local org_header=()
  if [[ -n "${DAYTONA_ORG_ID:-}" ]]; then
    org_header=(-H "X-Daytona-Organization-ID: $DAYTONA_ORG_ID")
  fi

  local status
  status="$(curl -sS -o /tmp/daytona_revoke_key_resp.json -w '%{http_code}' \
    -X DELETE "$DAYTONA_URL/api/api-keys/$key_name" \
    -H "Authorization: Bearer $DAYTONA_API_KEY" \
    "${org_header[@]}")"

  if [[ "$status" == "204" ]]; then
    log "Revoked Daytona API key: $key_name"
  else
    err "Failed to revoke Daytona API key ($key_name), HTTP $status"
    cat /tmp/daytona_revoke_key_resp.json || true
    exit 1
  fi
}

write_prod_link_template() {
  mkdir -p "$BASE_DIR"
  cat > "$PROD_ENV_EXAMPLE_FILE" <<'EOF'
# Copy this file to ~/.fortisai-dev/.prod-link.env or $FORTISAI_DEV_HOME/.prod-link.env
# Then update values before running bastion commands.

# OCI CLI context
export OCI_CLI_PROFILE=DEFAULT
export OCI_REGION=us-phoenix-1

# Bastion configuration (from landing-zone/network outputs)
export BASTION_SERVICE_ID=ocid1.bastion.oc1..<replace>
export BASTION_TARGET_SUBNET_ID=ocid1.subnet.oc1..<replace>
export BASTION_SSH_PUBLIC_KEY_PATH=$HOME/.ssh/id_ed25519.pub
export BASTION_SESSION_TTL=10800

# Production targets reachable via bastion (private IP + port)
export PROD_GENAI_PRIVATE_IP=10.0.10.25
export PROD_GENAI_PORT=443

export PROD_LLAMA_PRIVATE_IP=10.0.11.40
export PROD_LLAMA_PORT=8000

# If GitHub Enterprise is private, set these. If using public github.com, leave empty.
export PROD_GITHUB_PRIVATE_IP=
export PROD_GITHUB_PORT=443

# OCI DevOps Git credentials in Vault (from pipeline outputs)
export OCI_DEVOPS_GIT_USERNAME_SECRET_ID=ocid1.vaultsecret.oc1..<replace>
export OCI_DEVOPS_GIT_TOKEN_SECRET_ID=ocid1.vaultsecret.oc1..<replace>

# GenAI credential secret in Vault (from landing-zone outputs)
export GENAI_OCI_CREDENTIALS_SECRET_ID=ocid1.vaultsecret.oc1..<replace>
EOF

  log "Wrote production link template: $PROD_ENV_EXAMPLE_FILE"
}

write_file_if_missing() {
  local target_file="$1"
  local file_content="$2"

  if [[ ! -f "$target_file" ]]; then
    printf '%s' "$file_content" > "$target_file"
  fi
}

ensure_git_repo() {
  local repo_dir="$1"

  if [[ ! -d "$repo_dir/.git" ]]; then
    (
      cd "$repo_dir"
      git init -q
      git branch -M main
    )
  fi
}

scaffold_config_repos() {
  require_cmd git

  mkdir -p "$LOCAL_DIFY_CONFIG_REPO_DIR/apps"
  mkdir -p "$LOCAL_DIFY_CONFIG_REPO_DIR/prompts"
  mkdir -p "$LOCAL_DIFY_CONFIG_REPO_DIR/datasets"

  mkdir -p "$LOCAL_N8N_CONFIG_REPO_DIR/workflows"
  mkdir -p "$LOCAL_N8N_CONFIG_REPO_DIR/credentials"
  mkdir -p "$LOCAL_N8N_CONFIG_REPO_DIR/metadata"

  write_file_if_missing "$LOCAL_DIFY_CONFIG_REPO_DIR/README.md" '# dify-config

Git-managed Dify configuration repository.

Recommended naming:

- apps/<domain>-<capability>.yaml
- prompts/<domain>-<purpose>.yaml
- datasets/<domain>-<dataset>.yaml
'

  write_file_if_missing "$LOCAL_N8N_CONFIG_REPO_DIR/README.md" '# n8n-config

Git-managed n8n workflow configuration repository.

Recommended naming:

- workflows/<domain>-<workflow>.json
- metadata/<domain>-tags.json
- credentials/README.md
'

  write_file_if_missing "$LOCAL_DIFY_CONFIG_REPO_DIR/apps/customer-support-agent.yaml" 'app:
  name: customer-support-agent
  environment: dev
  notes: replace this starter file with an exported Dify YAML artifact
'

  write_file_if_missing "$LOCAL_N8N_CONFIG_REPO_DIR/workflows/lead-intake.json" '{
  "name": "lead-intake",
  "active": false,
  "nodes": [],
  "connections": {},
  "meta": {
    "notes": "replace this starter file with an exported n8n workflow JSON artifact"
  }
}
'

  write_file_if_missing "$LOCAL_N8N_CONFIG_REPO_DIR/credentials/README.md" '# credentials

Do not commit exported secrets or live credential payloads.
Store only documentation or placeholder references in this directory.
'

  ensure_git_repo "$LOCAL_DIFY_CONFIG_REPO_DIR"
  ensure_git_repo "$LOCAL_N8N_CONFIG_REPO_DIR"

  log "Scaffolded config repositories under $CONFIG_REPOS_DIR"
  log "Dify repo: $LOCAL_DIFY_CONFIG_REPO_DIR"
  log "n8n repo: $LOCAL_N8N_CONFIG_REPO_DIR"
}

scaffold_templates() {
  local target="${1:-all}"
  local name_override="${2:-}"

  if [[ "$target" != "all" && "$target" != "dify" && "$target" != "n8n" ]]; then
    err "Unknown scaffold target: $target (expected: all | dify | n8n)"
    exit 1
  fi

  if [[ -n "$name_override" && ! "$name_override" =~ ^[A-Za-z0-9._-]+$ ]]; then
    err "Invalid name: '$name_override' (allowed: letters, numbers, dot, underscore, hyphen)"
    exit 1
  fi

  scaffold_config_repos

  local dify_template="$TEMPLATES_DIR/dify/app-template.yaml"
  local n8n_template="$TEMPLATES_DIR/n8n/workflow-template.json"

  if [[ "$target" == "all" || "$target" == "dify" ]]; then
    if [[ ! -f "$dify_template" ]]; then
      err "Missing Dify template: $dify_template"
      exit 1
    fi

    local dify_name
    dify_name="${name_override:-example-dify-app}"
    local dify_target="$LOCAL_DIFY_CONFIG_REPO_DIR/apps/$dify_name.yaml"

    if [[ -f "$dify_target" ]]; then
      log "Dify scaffold target already exists, skipping: $dify_target"
    else
      cp "$dify_template" "$dify_target"
      sed -i.bak \
        -e "s/APP_NAME_PLACEHOLDER/$dify_name/g" \
        -e "s/MODEL_NAME_PLACEHOLDER/claude-3.7-sonnet-reasoning-gemma3-12B/g" \
        "$dify_target"
      rm -f "$dify_target.bak"
      log "Created Dify config from template: $dify_target"
    fi
  fi

  if [[ "$target" == "all" || "$target" == "n8n" ]]; then
    if [[ ! -f "$n8n_template" ]]; then
      err "Missing n8n template: $n8n_template"
      exit 1
    fi

    local n8n_name
    n8n_name="${name_override:-example-n8n-workflow}"
    local n8n_target="$LOCAL_N8N_CONFIG_REPO_DIR/workflows/$n8n_name.json"
    local workflow_id
    workflow_id="$(uuidgen 2>/dev/null || echo "$n8n_name-$(date +%s)")"

    if [[ -f "$n8n_target" ]]; then
      log "n8n scaffold target already exists, skipping: $n8n_target"
    else
      cp "$n8n_template" "$n8n_target"
      sed -i.bak \
        -e "s/WORKFLOW_NAME_PLACEHOLDER/$n8n_name/g" \
        -e "s/WORKFLOW_ID_PLACEHOLDER/$workflow_id/g" \
        "$n8n_target"
      rm -f "$n8n_target.bak"
      log "Created n8n workflow from template: $n8n_target"
    fi
  fi

}

bastion_create_port_forward_session() {
  local display_name="$1"
  local target_ip="$2"
  local target_port="$3"

  require_cmd oci
  require_cmd jq

  load_prod_env

  if [[ -z "${BASTION_SERVICE_ID:-}" ]]; then
    err "BASTION_SERVICE_ID is not set. Configure $PROD_ENV_FILE first."
    exit 1
  fi
  if [[ -z "${BASTION_SSH_PUBLIC_KEY_PATH:-}" ]]; then
    err "BASTION_SSH_PUBLIC_KEY_PATH is not set. Configure $PROD_ENV_FILE first."
    exit 1
  fi
  if [[ ! -f "$BASTION_SSH_PUBLIC_KEY_PATH" ]]; then
    err "SSH public key file not found: $BASTION_SSH_PUBLIC_KEY_PATH"
    exit 1
  fi

  local session_ttl
  session_ttl="${BASTION_SESSION_TTL:-10800}"

  log "Creating bastion port-forward session for $display_name -> $target_ip:$target_port"
  local session_json session_id
  session_json="$(oci bastion session create-port-forwarding \
    --bastion-id "$BASTION_SERVICE_ID" \
    --display-name "$display_name" \
    --target-private-ip "$target_ip" \
    --target-port "$target_port" \
    --ssh-public-key-file "$BASTION_SSH_PUBLIC_KEY_PATH" \
    --session-ttl "$session_ttl" \
    --wait-for-state SUCCEEDED \
    --output json)"

  session_id="$(printf '%s' "$session_json" | jq -r '.data.id')"
  if [[ -z "$session_id" || "$session_id" == "null" ]]; then
    err "Failed to create bastion session for $display_name"
    exit 1
  fi

  local ssh_command
  ssh_command="$(oci bastion session get \
    --session-id "$session_id" \
    --query 'data."ssh-metadata".command' \
    --raw-output)"

  printf '\n[%s]\n' "$display_name"
  printf 'session_id=%s\n' "$session_id"
  printf 'ssh_command=%s\n\n' "$ssh_command"
}

link_prod_via_bastion() {
  validate_prod_config true
  load_prod_env

  bastion_create_port_forward_session "fortisai-genai-link" "${PROD_GENAI_PRIVATE_IP:?PROD_GENAI_PRIVATE_IP is required}" "${PROD_GENAI_PORT:-443}"
  bastion_create_port_forward_session "fortisai-llama-link" "${PROD_LLAMA_PRIVATE_IP:?PROD_LLAMA_PRIVATE_IP is required}" "${PROD_LLAMA_PORT:-8000}"

  if [[ -n "${PROD_GITHUB_PRIVATE_IP:-}" ]]; then
    bastion_create_port_forward_session "fortisai-github-link" "$PROD_GITHUB_PRIVATE_IP" "${PROD_GITHUB_PORT:-443}"
  else
    log "Skipping GitHub bastion session (PROD_GITHUB_PRIVATE_IP not set)."
    log "Use direct HTTPS for public github.com or set private GitHub Enterprise IP in $PROD_ENV_FILE."
  fi
}

dify_api() {
  local change_key_choice=""
  local dify_api_key=""
  local dify_api_key_confirm=""
  local existing_key=""

  if [[ ! -t 0 ]]; then
    err "Manual Dify API prompt flow is disabled; keys are auto-generated via helper startup"
    exit 1
  fi

  if [[ -f "$DIFY_KEYS_JSON_FILE" ]]; then
    existing_key="$(DIFY_KEYS_JSON_FILE="$DIFY_KEYS_JSON_FILE" python3 - <<'PY'
import json
import os
from pathlib import Path

cfg = Path(os.environ["DIFY_KEYS_JSON_FILE"])
try:
    data = json.loads(cfg.read_text())
except Exception:
    print("")
    raise SystemExit(0)

print(str(data.get("dify_api_key") or data.get("dify_admin_api_key") or data.get("admin_api_key") or "").strip())
PY
)"

    if [[ -n "$existing_key" ]]; then
      read -r -p "Dify API key file already exists. Change key? [y/N]: " change_key_choice
      if [[ ! "$change_key_choice" =~ ^[Yy]$ ]]; then
        log "Keeping existing Dify API key in $DIFY_KEYS_JSON_FILE"
        export DIFY_API_KEY="$existing_key"
        export ADMIN_API_KEY="$existing_key"
        export ADMIN_API_KEY_ENABLE="true"
        return
      fi
    fi
  fi

  read -r -s -p "Dify app API key (from Dify app -> API Access): " dify_api_key
  printf '\n'

  if [[ -z "$dify_api_key" ]]; then
    err "Dify API key cannot be empty"
    exit 1
  fi

  read -r -s -p "Confirm Dify app API key: " dify_api_key_confirm
  printf '\n'

  if [[ "$dify_api_key" != "$dify_api_key_confirm" ]]; then
    err "Dify API key values do not match"
    exit 1
  fi

  mkdir -p "$DIFY_MCP_DIR"
  DIFY_KEYS_JSON_FILE="$DIFY_KEYS_JSON_FILE" DIFY_API_KEY_VALUE="$dify_api_key" python3 - <<'PY'
import json
import os
from datetime import datetime, timezone
from pathlib import Path

path = Path(os.environ["DIFY_KEYS_JSON_FILE"])
key = os.environ["DIFY_API_KEY_VALUE"]
try:
    payload = json.loads(path.read_text())
except Exception:
    payload = {}
payload["dify_api_key"] = key
payload["updated_at"] = datetime.now(timezone.utc).isoformat()
path.write_text(json.dumps(payload, indent=2) + "\n")
PY

  chmod 600 "$DIFY_KEYS_JSON_FILE" 2>/dev/null || true

  export DIFY_API_KEY="$dify_api_key"
  export ADMIN_API_KEY="$dify_api_key"
  export ADMIN_API_KEY_ENABLE="true"
  log "Saved Dify API key to $DIFY_KEYS_JSON_FILE"
  log "DIFY_API_KEY is now available to helper commands in this run"
  log "Other helper commands auto-load DIFY_API_KEY from this JSON file"
}

usage() {
  cat <<EOF
FortisAI local dev helper

Usage:
  $SCRIPT_NAME setup          Prepare local files, Podman machine, and Dify repo
  $SCRIPT_NAME oracle-db-pull Pull Oracle AI Database image from OCR (auto-login if creds set)
  $SCRIPT_NAME up             Setup and start Oracle DB, MongoDB, Redis, RabbitMQ, Vault, pgvector, Honcho, OpenAPI servers, Dify, Qdrant, n8n, OpenWebUI, OpenVSCode, Appsmith, ORDS, SQLcl sidecar, Oracle Node API, and SQLcl MCP config
  $SCRIPT_NAME down           Stop Oracle DB, MongoDB, Redis, RabbitMQ, Vault, pgvector, Honcho, OpenAPI servers, Dify, Qdrant, n8n, OpenWebUI, OpenVSCode, Appsmith, ORDS, SQLcl sidecar, and Oracle Node API
  $SCRIPT_NAME openclaw-up    Setup (if needed) and start OpenClaw only
  $SCRIPT_NAME openclaw-down  Stop OpenClaw only
  $SCRIPT_NAME all-up         Run full startup sequence: up, codeindexer-up, openmetadata-up, mcp-up, openclaw-up, hermes-up, daytona-up, traefik-up
  $SCRIPT_NAME all-down       Run full shutdown sequence: traefik-down, daytona-down, mcp-down, hermes-down, openclaw-down, openmetadata-down, codeindexer-down, down
  $SCRIPT_NAME openclaw-shell Open interactive shell in OpenClaw container
  $SCRIPT_NAME openwebui-shell
                              Open interactive shell in OpenWebUI container
  $SCRIPT_NAME openvscode-up  Start OpenVSCode user containers
  $SCRIPT_NAME openvscode-down
                              Stop OpenVSCode user containers
  $SCRIPT_NAME openvscode-users
                              Show configured OpenVSCode users, ports, token files, and workspaces
  $SCRIPT_NAME openvscode-shell
                              Open interactive shell in OpenVSCode container; optional user argument
  $SCRIPT_NAME openvscode-list-extensions [user]
                              List extensions installed for one OpenVSCode user
  $SCRIPT_NAME openvscode-install-extension [user] <extension-id-or-vsix>
                              Install an extension for one OpenVSCode user
  $SCRIPT_NAME openvscode-uninstall-extension [user] <extension-id>
                              Uninstall an extension for one OpenVSCode user
  $SCRIPT_NAME hermes-up      Setup (if needed) and start Hermes Agent only
  $SCRIPT_NAME hermes-down    Stop Hermes Agent only
  $SCRIPT_NAME hermes-shell   Open interactive shell in Hermes container
  $SCRIPT_NAME traefik-up     Setup (if needed) and start Traefik load balancer/dashboard
  $SCRIPT_NAME traefik-down   Stop Traefik only
  $SCRIPT_NAME traefik-check  Check Traefik web entrypoint and dashboard auth
  $SCRIPT_NAME codeindexer-up Setup CodeIndexer, build its MCP server, and start Milvus
  $SCRIPT_NAME codeindexer-down
                              Stop the CodeIndexer OpenAPI bridge and Milvus
  $SCRIPT_NAME codeindexer-check
                              Check CodeIndexer bridge and Milvus health
  $SCRIPT_NAME milvus-up      Start Milvus only for CodeIndexer
  $SCRIPT_NAME milvus-down    Stop Milvus only
  $SCRIPT_NAME opensearch-up  Start OpenSearch only for OpenMetadata
  $SCRIPT_NAME opensearch-down
                              Stop OpenSearch only
  $SCRIPT_NAME openmetadata-up
                              Start OpenMetadata with shared pgvector Postgres and OpenSearch
  $SCRIPT_NAME openmetadata-down
                              Stop OpenMetadata and OpenSearch
  $SCRIPT_NAME openmetadata-check
                              Check OpenMetadata and OpenSearch health
  $SCRIPT_NAME vault-up       Setup (if needed) and start HashiCorp Vault only
  $SCRIPT_NAME vault-down     Stop HashiCorp Vault only
  $SCRIPT_NAME vault-init     Initialize persistent local Vault and save init JSON locally
  $SCRIPT_NAME vault-unseal   Unseal Vault using the saved local init JSON
  $SCRIPT_NAME vault-status   Show Vault seal/init status
  $SCRIPT_NAME vault-read <path>
                              Read secret/fortisai/dev/<path> from local Vault
  $SCRIPT_NAME vault-write <path> <value>
                              Write secret/fortisai/dev/<path> in local Vault
  $SCRIPT_NAME vault-del <path>
                              Permanently delete secret/fortisai/dev/<path> from local Vault
  $SCRIPT_NAME status         Show running containers
  $SCRIPT_NAME logs <target>  Stream logs for oracle-db, mongodb, redis, rabbitmq, vault, firecrawl, pgvector, honcho, openapi-servers, openclaw, hermes, n8n, openwebui, openvscode, appsmith, qdrant, dify, daytona, traefik, codeindexer, milvus, openmetadata, opensearch, ords, sqlcl, or oracle-node-api
  $SCRIPT_NAME check          Run HTTP and database health checks
  $SCRIPT_NAME sqlcl-shell    Open SQLcl in the running SQLcl sidecar
  $SCRIPT_NAME sqlcl-mcp      Run the SQLcl MCP stdio server in the foreground
  $SCRIPT_NAME sqlcl-mcp-smoke
                              Run MCP initialize + sqlcl_connection_info against generated config
  $SCRIPT_NAME n8n-import-workflows
                              Import and activate Development_Environment/n8n-config workflows into n8n
  $SCRIPT_NAME mcp-up         Start SQLcl, n8n, Dify, debug, CodeIndexer, and optional Proxmox MCP OpenAPI bridge services and validate connectivity
  $SCRIPT_NAME mcp-down       Stop SQLcl, n8n, Dify, debug, CodeIndexer, and Proxmox MCP OpenAPI bridge services
  $SCRIPT_NAME apex-install   Install Oracle APEX into FREEPDB1 and wire static files to ORDS
  $SCRIPT_NAME apex-check     Check Oracle APEX install state and HTTP endpoint via ORDS
  $SCRIPT_NAME apex-reset     Reset APEX runtime users/static content without uninstalling APEX
  $SCRIPT_NAME daytona-setup  Prepare Daytona OSS repo + runtime compose with safe host ports
  $SCRIPT_NAME daytona-up     Start Daytona OSS stack (prefers Docker Compose for runner stability)
  $SCRIPT_NAME daytona-down   Stop Daytona OSS stack
  $SCRIPT_NAME daytona-check  Run Daytona dashboard HTTP health check
  $SCRIPT_NAME daytona-gpu-check
                              Report Daytona GPU support status for this host
  $SCRIPT_NAME daytona-docker-smoke
                              Automate Docker-based Daytona startup and smoke checks (step 1)
  $SCRIPT_NAME daytona-set-admin-creds <email> <password>
                              Update Daytona dashboard admin email and password (rewrites Dex config)
  $SCRIPT_NAME daytona-revoke-key <key-name>
                              Revoke a Daytona API key by name (step 2)
  $SCRIPT_NAME scaffold-config-repos
                              Create local dify-config and n8n-config repo layouts
  $SCRIPT_NAME scaffold-templates [all|dify|n8n] [name]
                              Copy starter templates into local config repos
  $SCRIPT_NAME lmstudio-setup Install LM Studio app (macOS Homebrew cask)
  $SCRIPT_NAME lmstudio-start Install (if needed) and open LM Studio
  $SCRIPT_NAME lmstudio-check Check LM Studio local API endpoint
  $SCRIPT_NAME prod-template  Create production link env template
  $SCRIPT_NAME validate-prod  Validate production env and OCID settings
  $SCRIPT_NAME link-prod      Create bastion sessions for GenAI, Llama, and optional GitHub
  $SCRIPT_NAME help           Show this help

Environment overrides:
  FORTISAI_DEV_HOME (default: ~/fortisai-dev)
  PODMAN_CPUS (default: 6)
  PODMAN_MEMORY_MB (default: 12288)
  PODMAN_DISK_GB (default: 80)
  N8N_URL (default: http://localhost:5678)
  OPENWEBUI_URL (default: http://localhost:3000)
  OPENVSCODE_URL (default: http://localhost:13000)
  APPSMITH_URL (default: http://localhost:18080)
  MONGODB_URL (default: mongodb://127.0.0.1:27017/appsmith?replicaSet=rs0)
  DIFY_URL (default: http://localhost:18081)
  REDIS_URL (default: redis://127.0.0.1:6379)
  RABBITMQ_URL (default: amqp://fortisai:fortisai@127.0.0.1:5672)
  RABBITMQ_MANAGEMENT_URL (default: http://127.0.0.1:15672)
  VAULT_URL (default: http://127.0.0.1:8200)
  PGVECTOR_URL (default: postgresql://fortisai:fortisai@127.0.0.1:5432/fortisai)
  QDRANT_URL (default: http://127.0.0.1:6333)
  QDRANT_INTERNAL_URL (default: http://qdrant:6333)
  QDRANT_API_KEY (default: difyai123456)
  QDRANT_HOST_PORT (default: 6333)
  QDRANT_GRPC_HOST_PORT (default: 6334)
  DAYTONA_URL (default: http://localhost:3300)
  LMSTUDIO_MODELS_URL (default: http://localhost:1234/v1/models)
  ORDS_URL (default: http://127.0.0.1:8181/ords/)
  APEX_URL (default: http://127.0.0.1:8181/ords/apex)
  ORACLE_NODE_API_URL (default: http://127.0.0.1:8090)
  HONCHO_URL (default: http://127.0.0.1:8010)
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
  APPSMITH_DB_URL (default: mongodb://fortisai-mongodb:27017/appsmith?replicaSet=rs0)
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
  VAULT_CONTAINER_NAME (default: fortisai-vault)
  VAULT_IMAGE (default: docker.io/hashicorp/vault:latest)
  VAULT_HOST_PORT (default: 8200)
  VAULT_INTERNAL_URL (default: http://fortisai-vault:8200)
  VAULT_KEYS_FILE (default: FORTISAI_DEV_HOME/vault/vault-init.json)
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
  OPENWEBUI_LLM_BACKEND (default: hermes; options: openclaw|hermes)
  SQLCL_MCP_PYTHON_CMD (default: python3)
  APEX_DOWNLOAD_URL (default: https://download.oracle.com/otn_software/apex/apex-latest.zip)
  APEX_WORK_DIR (default: ORACLE_DB_DIR/apex)
  APEX_ADMIN_PASSWORD (default: ORACLE_DB_PASSWORD)
  OCR_REGISTRY (default: container-registry.oracle.com)
  OCR_USERNAME (optional: OCR username)
  OCR_AUTH_TOKEN (optional: OCR auth token)
  APP_API_KEY (default: auto-loaded/generated from $DIFY_KEYS_JSON_FILE)
  KNOWLEDGE_API_KEY (default: auto-loaded/generated from $DIFY_KEYS_JSON_FILE)
  DIFY_API_KEY (default: loaded from $DIFY_KEYS_JSON_FILE)
  ADMIN_API_KEY (default: auto-resolved from running Dify API container for MCP admin routes)
  DIFY_ADMIN_API_KEY (optional override for MCP admin routes)
  DIFY_ADMIN_WORKSPACE_ID (optional override; auto-resolved during MCP bridge startup when unset)
  PROXMOX_BRIDGE_ENABLED (default: auto; true to force Proxmox MCP bridge startup)
  PROXMOX_HOST, PROXMOX_PORT, PROXMOX_USER, PROXMOX_TOKEN_NAME, PROXMOX_TOKEN_VALUE (optional Proxmox MCP config; synced to Vault)
  PROXMOX_API_KEY (default: fortisai-proxmox-openapi-dev-key; synced to Vault for Proxmox OpenAPI bearer auth)
  PROXMOX_API_STRICT_AUTH (default: false)
  DAYTONA_API_KEY (required for daytona-revoke-key; optional for daytona-docker-smoke API test)
  DAYTONA_ORG_ID (optional for daytona-revoke-key; required for daytona-docker-smoke API test)
  PROD env file (optional): ${FORTISAI_DEV_HOME:-~/fortisai-dev}/.prod-link.env
EOF
}

main() {
  local cmd="${1:-help}"

  case "$cmd" in
    setup)
      setup
      ;;
    oracle-db-pull)
      oracle_db_pull
      ;;
    up)
      up
      ;;
    down)
      down
      ;;
    openclaw-up)
      openclaw_up
      ;;
    openclaw-down)
      openclaw_down
      ;;
    all-up)
      prepare_vault_runtime_secrets
      up
      codeindexer_up
      openmetadata_up
      mcp_up
      openclaw_up
      hermes_up
      daytona_up
      traefik_up
      log "all-up completed successfully"
      ;;
    all-down)
      traefik_down
      daytona_down
      mcp_down
      hermes_down
      openclaw_down
      openmetadata_down
      codeindexer_down
      down
      log "all-down completed successfully"
      ;;
    openclaw-shell)
      openclaw_shell
      ;;
    openwebui-shell)
      openwebui_shell
      ;;
    openvscode-up)
      openvscode_up
      ;;
    openvscode-down)
      openvscode_down
      ;;
    openvscode-users)
      openvscode_users
      ;;
    openvscode-shell)
      openvscode_shell "${2:-}"
      ;;
    openvscode-list-extensions)
      openvscode_list_extensions "${2:-}"
      ;;
    openvscode-install-extension)
      shift
      openvscode_install_extension "$@"
      ;;
    openvscode-uninstall-extension)
      shift
      openvscode_uninstall_extension "$@"
      ;;
    hermes-up)
      hermes_up
      ;;
    hermes-down)
      hermes_down
      ;;
    hermes-shell)
      hermes_shell
      ;;
    traefik-up)
      traefik_up
      ;;
    traefik-down)
      traefik_down
      ;;
    traefik-check)
      traefik_check
      ;;
    codeindexer-up)
      codeindexer_up
      ;;
    codeindexer-down)
      codeindexer_down
      ;;
    codeindexer-check)
      codeindexer_check
      ;;
    milvus-up)
      milvus_up
      ;;
    milvus-down)
      milvus_down
      ;;
    opensearch-up)
      opensearch_up
      ;;
    opensearch-down)
      opensearch_down
      ;;
    openmetadata-up)
      openmetadata_up
      ;;
    openmetadata-down)
      openmetadata_down
      ;;
    openmetadata-check)
      openmetadata_check
      ;;
    vault-up)
      vault_up
      ;;
    vault-down)
      vault_down
      ;;
    vault-init)
      vault_init
      ;;
    vault-unseal)
      vault_unseal
      ;;
    vault-status)
      vault_status
      ;;
    vault-read)
      vault_read "${2:-}"
      ;;
    vault-write)
      vault_write "${2:-}" "${3:-}"
      ;;
    vault-del)
      vault_del "${2:-}"
      ;;
    status)
      status
      ;;
    logs)
      logs "${2:-all}"
      ;;
    check)
      check
      ;;
    sqlcl-shell)
      sqlcl_shell
      ;;
    sqlcl-mcp)
      sqlcl_mcp
      ;;
    sqlcl-mcp-smoke)
      sqlcl_mcp_smoke
      ;;
    n8n-import-workflows)
      shift
      n8n_import_workflows "$@"
      ;;
    mcp-up)
      mcp_up
      ;;
    mcp-down)
      mcp_down
      ;;
    apex-install)
      apex_install
      ;;
    apex-check)
      apex_check
      ;;
    apex-reset)
      apex_reset
      ;;
    daytona-setup)
      setup_daytona_repo
      ;;
    daytona-up)
      daytona_up
      ;;
    daytona-down)
      daytona_down
      ;;
    daytona-check)
      daytona_check
      ;;
    daytona-gpu-check)
      daytona_gpu_check
      ;;
    daytona-docker-smoke)
      daytona_docker_smoke
      ;;
    daytona-set-admin-creds)
      daytona_set_admin_creds "${2:-}" "${3:-}"
      ;;
    daytona-revoke-key)
      daytona_revoke_api_key "${2:-}"
      ;;
    scaffold-config-repos)
      scaffold_config_repos
      ;;
    scaffold-templates)
      scaffold_templates "${2:-all}" "${3:-}"
      ;;
    lmstudio-setup)
      setup_lmstudio
      ;;
    lmstudio-start)
      start_lmstudio
      ;;
    lmstudio-check)
      check_lmstudio
      ;;
    prod-template)
      write_prod_link_template
      ;;
    validate-prod)
      validate_prod_config true
      ;;
    link-prod)
      link_prod_via_bastion
      ;;
    help|-h|--help)
      usage
      ;;
    *)
      err "Unknown command: $cmd"
      usage
      exit 1
      ;;
  esac
}

main "$@"
