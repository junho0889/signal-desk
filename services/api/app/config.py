from __future__ import annotations

import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Settings:
    app_database_url: str
    default_limit: int = 20
    max_limit: int = 100


def load_settings() -> Settings:
    app_database_url = os.getenv(
        "SIGNALDESK_APP_DATABASE_URL",
        "postgresql://signaldesk_app:change-this-app-password@127.0.0.1:5432/signaldesk",
    )
    return Settings(app_database_url=app_database_url)
