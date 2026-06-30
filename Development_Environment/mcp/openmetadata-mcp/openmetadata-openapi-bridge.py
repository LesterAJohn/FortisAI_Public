#!/usr/bin/env python3
"""FortisAI OpenAPI bridge for OpenMetadata catalog and source onboarding."""

from __future__ import annotations

import os
from typing import Any, Dict, Optional

import requests
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field


APP = FastAPI(title="fortisai-openmetadata-openapi-bridge", version="1.0.0")

OPENMETADATA_BASE_URL = os.getenv(
    "OPENMETADATA_BASE_URL", "http://fortisai-openmetadata.fortisai.local:8585/api"
).rstrip("/")
OPENMETADATA_API_TOKEN = os.getenv("OPENMETADATA_API_TOKEN", "").strip()
OPENMETADATA_ALLOW_WRITE = os.getenv("OPENMETADATA_ALLOW_WRITE", "true").lower() in {"1", "true", "yes", "on"}
OPENMETADATA_ALLOW_SAMPLE_DATA = os.getenv("OPENMETADATA_ALLOW_SAMPLE_DATA", "false").lower() in {"1", "true", "yes", "on"}
VAULT_ADDR = os.getenv("FORTISAI_VAULT_ADDR") or os.getenv("VAULT_ADDR") or ""
VAULT_TOKEN = os.getenv("VAULT_TOKEN", "").strip()


def _vault_read(path: str) -> Optional[str]:
    if not VAULT_ADDR or not VAULT_TOKEN:
        return None
    url = f"{VAULT_ADDR.rstrip('/')}/v1/secret/data/fortisai/dev/{path.strip('/')}"
    try:
        response = requests.get(url, headers={"X-Vault-Token": VAULT_TOKEN}, timeout=8)
        if response.status_code == 404:
            return None
        response.raise_for_status()
        data = response.json().get("data", {}).get("data", {})
        value = data.get("value")
        if value is None and len(data) == 1:
            value = next(iter(data.values()))
        return str(value) if value is not None else None
    except Exception:
        return None


def _api_token() -> str:
    return OPENMETADATA_API_TOKEN or _vault_read("openmetadata/api_token") or ""


def _headers() -> Dict[str, str]:
    headers = {"Content-Type": "application/json", "Accept": "application/json"}
    token = _api_token()
    if token:
        headers["Authorization"] = f"Bearer {token}"
    return headers


def _om_request(method: str, path: str, **kwargs: Any) -> Dict[str, Any]:
    url = f"{OPENMETADATA_BASE_URL}{path}"
    response = requests.request(method, url, headers=_headers(), timeout=120, **kwargs)
    if response.status_code == 204:
        return {"ok": True, "status": 204}
    try:
        body: Any = response.json()
    except Exception:
        body = {"raw": response.text[:4000]}
    if response.status_code >= 400:
        raise HTTPException(status_code=response.status_code, detail=body)
    return {"ok": True, "status": response.status_code, "data": body}


def _require_write() -> None:
    if not OPENMETADATA_ALLOW_WRITE:
        raise HTTPException(status_code=403, detail="OpenMetadata write/onboarding operations are disabled.")


def _source_secret(alias: str, key: str) -> Optional[str]:
    return _vault_read(f"openmetadata/sources/{alias}/{key}") or _vault_read(f"tradeengine/{alias}/{key}")


class SearchRequest(BaseModel):
    query: str
    index: str = "all"
    size: int = Field(default=10, ge=1, le=50)
    from_: int = Field(default=0, alias="from", ge=0)


class EntityByNameRequest(BaseModel):
    entity_type: str
    fqn: str
    fields: str = "owners,tags,domains,description,columns"


class LineageRequest(BaseModel):
    entity: str
    fqn: str
    upstream_depth: int = Field(default=1, ge=0, le=5)
    downstream_depth: int = Field(default=1, ge=0, le=5)


class ServiceRequest(BaseModel):
    service_category: str = "databaseServices"
    name: str
    service_type: str
    description: str = ""
    connection: Dict[str, Any] = Field(default_factory=dict)


class SourceAliasRequest(BaseModel):
    source: str


class IngestionPipelineRequest(BaseModel):
    source: str
    name: Optional[str] = None
    pipeline_type: str = "metadata"
    source_config: Dict[str, Any] = Field(default_factory=lambda: {"config": {"type": "DatabaseMetadata"}})
    airflow_config: Dict[str, Any] = Field(default_factory=lambda: {"pausePipeline": False})


class PipelineIdRequest(BaseModel):
    id: Optional[str] = None
    fqn: Optional[str] = None


@APP.get("/openmetadata_connection_info")
def connection_info() -> Dict[str, Any]:
    info = {
        "ok": True,
        "base_url": OPENMETADATA_BASE_URL,
        "has_api_token": bool(_api_token()),
        "allow_write": OPENMETADATA_ALLOW_WRITE,
        "allow_sample_data": OPENMETADATA_ALLOW_SAMPLE_DATA,
        "vault_configured": bool(VAULT_ADDR and VAULT_TOKEN),
    }
    try:
        version = _om_request("GET", "/v1/system/version")
        info["openmetadata_status"] = version.get("status")
        info["version"] = version.get("data")
    except HTTPException as exc:
        info["openmetadata_status"] = exc.status_code
    return info


@APP.post("/openmetadata_search")
def search(request: SearchRequest) -> Dict[str, Any]:
    params = {"q": request.query, "index": request.index, "size": request.size, "from": request.from_}
    return _om_request("GET", "/v1/search/query", params=params)


@APP.post("/openmetadata_get_entity_by_name")
def get_entity_by_name(request: EntityByNameRequest) -> Dict[str, Any]:
    entity = request.entity_type.strip("/")
    return _om_request("GET", f"/v1/{entity}/name/{request.fqn}", params={"fields": request.fields})


@APP.post("/openmetadata_get_lineage")
def get_lineage(request: LineageRequest) -> Dict[str, Any]:
    params = {
        "upstreamDepth": request.upstream_depth,
        "downstreamDepth": request.downstream_depth,
    }
    return _om_request("GET", f"/v1/lineage/{request.entity}/name/{request.fqn}", params=params)


@APP.get("/openmetadata_supported_service_types")
def supported_service_types() -> Dict[str, Any]:
    return {
        "databaseServices": ["MongoDB", "CustomDatabase", "Oracle", "Postgres", "Mysql", "Mssql", "Snowflake", "BigQuery"],
        "dashboardServices": ["Superset", "Tableau", "PowerBI", "Looker"],
        "storageServices": ["S3", "ADLS", "GCS"],
        "messagingServices": ["Kafka", "Pulsar"],
        "pipelineServices": ["Airflow", "Dbt", "Dagster"],
        "initial_aliases": ["tradeenginedb0_mongodb", "tradeenginedb_influxdb"],
    }


@APP.post("/openmetadata_create_or_update_service")
def create_or_update_service(request: ServiceRequest) -> Dict[str, Any]:
    _require_write()
    payload = {
        "name": request.name,
        "serviceType": request.service_type,
        "description": request.description,
        "connection": request.connection,
    }
    return _om_request("PUT", f"/v1/services/{request.service_category}", json=payload)


def _alias_service_payload(source: str) -> ServiceRequest:
    if source == "tradeenginedb0_mongodb":
        uri = _vault_read("openmetadata/sources/tradeenginedb0_mongodb/connection_uri") or _vault_read("tradeengine/mongodb/connection_uri")
        if not uri:
            raise HTTPException(status_code=400, detail="Missing Vault secret: openmetadata/sources/tradeenginedb0_mongodb/connection_uri")
        return ServiceRequest(
            name="tradeenginedb0_mongodb",
            service_type="MongoDB",
            description="TradeEngineDB0 MongoDB catalog source managed by FortisAI.",
            connection={"config": {"type": "MongoDB", "connectionURI": uri}},
        )
    if source == "tradeenginedb_influxdb":
        url = _vault_read("openmetadata/sources/tradeenginedb_influxdb/url") or _vault_read("tradeengine/influxdb/url")
        org = _vault_read("openmetadata/sources/tradeenginedb_influxdb/org") or _vault_read("tradeengine/influxdb/org")
        token = _vault_read("openmetadata/sources/tradeenginedb_influxdb/token") or _vault_read("tradeengine/influxdb/token")
        missing = [name for name, value in {"url": url, "org": org, "token": token}.items() if not value]
        if missing:
            raise HTTPException(status_code=400, detail=f"Missing Vault secrets for tradeenginedb_influxdb: {', '.join(missing)}")
        return ServiceRequest(
            name="tradeenginedb_influxdb",
            service_type="CustomDatabase",
            description="TradeEngineDB InfluxDB catalog source managed by FortisAI. OpenMetadata 1.12.6 does not advertise a native InfluxDB database service type, so this is registered as CustomDatabase.",
            connection={"config": {"type": "CustomDatabase", "source": "InfluxDB", "url": url, "org": org, "token": token}},
        )
    raise HTTPException(status_code=404, detail=f"Unknown source alias: {source}")


@APP.post("/openmetadata_create_or_update_source")
def create_or_update_source(request: SourceAliasRequest) -> Dict[str, Any]:
    return create_or_update_service(_alias_service_payload(request.source))


@APP.post("/openmetadata_test_source_connection")
def test_source_connection(request: SourceAliasRequest) -> Dict[str, Any]:
    service = _alias_service_payload(request.source)
    result = _om_request("GET", f"/v1/services/databaseServices/name/{service.name}")
    data = result.get("data", {})
    service_id = data.get("id")
    if not service_id:
        return {"ok": False, "status": result.get("status"), "message": "Service exists check did not return an id.", "data": data}
    test_result = _om_request("GET", f"/v1/services/databaseServices/{service_id}/testConnectionResult")
    return {"ok": True, "service_id": service_id, "test_connection_result": test_result}


@APP.post("/openmetadata_create_or_update_ingestion_pipeline")
def create_or_update_ingestion_pipeline(request: IngestionPipelineRequest) -> Dict[str, Any]:
    _require_write()
    service_request = _alias_service_payload(request.source)
    service_result = _om_request("GET", f"/v1/services/databaseServices/name/{service_request.name}")
    service = service_result.get("data", {})
    service_id = service.get("id")
    if not service_id:
        raise HTTPException(status_code=404, detail=f"OpenMetadata service was not found: {service_request.name}")
    payload = {
        "name": request.name or f"{request.source}_metadata",
        "pipelineType": request.pipeline_type,
        "sourceConfig": request.source_config,
        "airflowConfig": request.airflow_config,
        "service": {"id": service_id, "type": "databaseService", "name": service_request.name},
        "loggerLevel": "INFO",
        "provider": "user",
        "enableStreamableLogs": True,
    }
    return _om_request("PUT", "/v1/services/ingestionPipelines", json=payload)


def _pipeline_id(request: PipelineIdRequest) -> str:
    if request.id:
        return request.id
    if request.fqn:
        result = _om_request("GET", f"/v1/services/ingestionPipelines/name/{request.fqn}")
        pipeline_id = result.get("data", {}).get("id")
        if pipeline_id:
            return pipeline_id
    raise HTTPException(status_code=400, detail="Provide pipeline id or fqn.")


@APP.post("/openmetadata_deploy_ingestion_pipeline")
def deploy_ingestion_pipeline(request: PipelineIdRequest) -> Dict[str, Any]:
    _require_write()
    return _om_request("POST", f"/v1/services/ingestionPipelines/deploy/{_pipeline_id(request)}")


@APP.post("/openmetadata_trigger_ingestion_pipeline")
def trigger_ingestion_pipeline(request: PipelineIdRequest) -> Dict[str, Any]:
    _require_write()
    return _om_request("POST", f"/v1/services/ingestionPipelines/trigger/{_pipeline_id(request)}")


@APP.post("/openmetadata_get_ingestion_status")
def get_ingestion_status(request: PipelineIdRequest) -> Dict[str, Any]:
    return _om_request("GET", f"/v1/services/ingestionPipelines/{_pipeline_id(request)}/pipelineStatus")


@APP.post("/openmetadata_get_ingestion_logs")
def get_ingestion_logs(request: PipelineIdRequest) -> Dict[str, Any]:
    pipeline_id = _pipeline_id(request)
    return _om_request("GET", f"/v1/services/ingestionPipelines/logs/{pipeline_id}/last")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(APP, host="0.0.0.0", port=int(os.getenv("OPENMETADATA_BRIDGE_PORT", "8100")))
