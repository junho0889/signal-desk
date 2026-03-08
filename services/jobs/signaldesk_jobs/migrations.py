from __future__ import annotations

from pathlib import Path

import psycopg


def apply_migrations(conn: psycopg.Connection) -> list[str]:
    migrations_dir = Path(__file__).resolve().parents[1] / "migrations"
    applied: list[str] = []

    for path in sorted(migrations_dir.glob("*.sql")):
        sql = path.read_text(encoding="utf-8")
        with conn.transaction():
            conn.execute(sql)
        applied.append(path.name)

    return applied
