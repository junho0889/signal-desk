from __future__ import annotations

import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Settings:
    app_database_url: str
    cors_allow_origins: tuple[str, ...]
    cors_allow_origin_regex: str
    default_limit: int = 20
    max_limit: int = 100


def load_settings() -> Settings:
    app_database_url = os.getenv(
        "SIGNALDESK_APP_DATABASE_URL",
        "postgresql://signaldesk_app:change-this-app-password@127.0.0.1:5432/signaldesk",
    )
    raw_cors = os.getenv("SIGNALDESK_CORS_ALLOW_ORIGINS", "http://127.0.0.1:7357,http://localhost:7357")
    cors_allow_origins = tuple(
        origin.strip() for origin in raw_cors.split(",") if origin.strip()
    )
    cors_allow_origin_regex = os.getenv(
        "SIGNALDESK_CORS_ALLOW_ORIGIN_REGEX",
        r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
    )
    return Settings(
        app_database_url=app_database_url,
        cors_allow_origins=cors_allow_origins,
        cors_allow_origin_regex=cors_allow_origin_regex,
    )
