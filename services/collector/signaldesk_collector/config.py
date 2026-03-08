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
    shipper_mode: str
    shipper_batch_size: int


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
        shipper_mode=os.environ.get("SIGNALDESK_COLLECTOR_SHIPPER_MODE", "simulate-offline"),
        shipper_batch_size=int(
            os.environ.get("SIGNALDESK_COLLECTOR_SHIPPER_BATCH_SIZE", "20")
        ),
    )

