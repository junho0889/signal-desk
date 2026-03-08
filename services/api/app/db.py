from __future__ import annotations

from contextlib import contextmanager
from typing import Iterator

import psycopg
from psycopg.rows import dict_row

from .config import Settings


@contextmanager
def get_connection(settings: Settings) -> Iterator[psycopg.Connection]:
    conn = psycopg.connect(settings.app_database_url, row_factory=dict_row)
    try:
        yield conn
    finally:
        conn.close()
