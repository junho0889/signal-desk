from dataclasses import dataclass
import os


@dataclass(frozen=True)
class Settings:
    db_url: str
    fixture_path: str
    collector_node_id: str
    source_id: str
    source_category: str
    default_language: str
    default_market_scope: str
    adapter_version: str
    retrieval_status: str
    source_cursor: str | None
    source_expects_upstream_event_at: bool
    max_future_skew_seconds: int
    central_host: str
    shipper_mode: str
    shipper_batch_size: int
    simulated_intake_status: str
    simulated_reason_code: str


def _to_bool(value: str | None, default: bool) -> bool:
    if value is None:
        return default
    return value.strip().lower() in ("1", "true", "yes", "on")


def load_settings() -> Settings:
    return Settings(
        db_url=os.environ.get(
            "SIGNALDESK_COLLECTOR_DB_URL",
            "postgresql://collector:collector@collector-db:5432/signaldesk_collector",
        ),
        fixture_path=os.environ.get(
            "SIGNALDESK_COLLECTOR_FIXTURE_PATH",
            "signaldesk_collector/fixtures/news_primary.json",
        ),
        collector_node_id=os.environ.get(
            "SIGNALDESK_COLLECTOR_NODE_ID",
            "collector-dev-node",
        ),
        source_id=os.environ.get("SIGNALDESK_COLLECTOR_SOURCE_ID", "news_primary"),
        source_category=os.environ.get(
            "SIGNALDESK_COLLECTOR_SOURCE_CATEGORY",
            "news",
        ),
        default_language=os.environ.get("SIGNALDESK_COLLECTOR_DEFAULT_LANGUAGE", "en"),
        default_market_scope=os.environ.get("SIGNALDESK_COLLECTOR_MARKET_SCOPE", "KRX"),
        adapter_version=os.environ.get("SIGNALDESK_COLLECTOR_ADAPTER_VERSION", "collector-v1"),
        retrieval_status=os.environ.get("SIGNALDESK_COLLECTOR_RETRIEVAL_STATUS", "ok"),
        source_cursor=os.environ.get("SIGNALDESK_COLLECTOR_SOURCE_CURSOR"),
        source_expects_upstream_event_at=_to_bool(
            os.environ.get("SIGNALDESK_COLLECTOR_EXPECTS_UPSTREAM_EVENT_AT"),
            True,
        ),
        max_future_skew_seconds=int(
            os.environ.get("SIGNALDESK_COLLECTOR_MAX_FUTURE_SKEW_SECONDS", "600")
        ),
        central_host=os.environ.get("SIGNALDESK_COLLECTOR_CENTRAL_HOST", "192.168.0.200"),
        shipper_mode=os.environ.get("SIGNALDESK_COLLECTOR_SHIPPER_MODE", "simulate-offline"),
        shipper_batch_size=int(
            os.environ.get("SIGNALDESK_COLLECTOR_SHIPPER_BATCH_SIZE", "20")
        ),
        simulated_intake_status=os.environ.get(
            "SIGNALDESK_COLLECTOR_SIMULATED_INTAKE_STATUS",
            "retryable_failure",
        ),
        simulated_reason_code=os.environ.get(
            "SIGNALDESK_COLLECTOR_SIMULATED_REASON_CODE",
            "storage_unavailable",
        ),
    )

