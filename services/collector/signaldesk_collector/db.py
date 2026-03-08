from __future__ import annotations

import psycopg


SCHEMA_SQL = """
CREATE TABLE IF NOT EXISTS spool_items (
    spool_id UUID PRIMARY KEY,
    source_id TEXT NOT NULL,
    source_category TEXT NOT NULL,
    collector_node_id TEXT NOT NULL,
    collected_at_utc TIMESTAMPTZ NOT NULL,
    upstream_event_at_utc TIMESTAMPTZ NULL,
    publisher_name TEXT NOT NULL,
    publisher_domain TEXT NOT NULL,
    canonical_url TEXT NOT NULL,
    external_id TEXT NULL,
    payload_hash_sha256 TEXT NOT NULL,
    payload_version TEXT NOT NULL,
    language TEXT NOT NULL,
    market_scope TEXT NOT NULL,
    title TEXT NOT NULL,
    raw_payload_json JSONB NOT NULL,
    idempotency_key TEXT NOT NULL UNIQUE,
    quality_state TEXT NOT NULL CHECK (
        quality_state IN (
            'accepted',
            'accepted_degraded',
            'duplicate',
            'stale_source',
            'metadata_incomplete',
            'mapping_low_confidence',
            'quarantined',
            'dead_letter'
        )
    ),
    status TEXT NOT NULL CHECK (
        status IN ('pending', 'shipping', 'accepted', 'duplicate', 'rejected', 'dead_letter')
    ),
    retry_count INTEGER NOT NULL DEFAULT 0,
    ingest_count INTEGER NOT NULL DEFAULT 1,
    last_ship_attempt_at_utc TIMESTAMPTZ NULL,
    last_error_code TEXT NULL,
    prune_after_utc TIMESTAMPTZ NOT NULL,
    created_at_utc TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at_utc TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_spool_items_status ON spool_items (status);
CREATE INDEX IF NOT EXISTS idx_spool_items_collected_at_utc ON spool_items (collected_at_utc);
"""


def connect(db_url: str) -> psycopg.Connection:
    return psycopg.connect(db_url)


def migrate(db_url: str) -> None:
    with connect(db_url) as conn:
        with conn.cursor() as cur:
            cur.execute(SCHEMA_SQL)
        conn.commit()


def reset(db_url: str) -> None:
    with connect(db_url) as conn:
        with conn.cursor() as cur:
            cur.execute("TRUNCATE TABLE spool_items;")
        conn.commit()

