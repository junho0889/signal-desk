from __future__ import annotations

import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Settings:
    migrator_database_url: str
    app_database_url: str
    alert_delta_threshold: float


def load_settings() -> Settings:
    return Settings(
        migrator_database_url=os.getenv(
            "SIGNALDESK_MIGRATOR_DATABASE_URL",
            "postgresql://signaldesk_migrator:change-this-migrator-password@127.0.0.1:5432/signaldesk",
        ),
        app_database_url=os.getenv(
            "SIGNALDESK_APP_DATABASE_URL",
            "postgresql://signaldesk_app:change-this-app-password@127.0.0.1:5432/signaldesk",
        ),
        alert_delta_threshold=float(os.getenv("SIGNALDESK_ALERT_DELTA_THRESHOLD", "2.0")),
    )
