from __future__ import annotations

import psycopg


SCHEMA_SQL = """
CREATE TABLE IF NOT EXISTS spool_items (
    spool_id UUID PRIMARY KEY,
    source_id TEXT NOT NULL,
    source_category TEXT NOT NULL,
    collector_node_id TEXT NOT NULL,
    collected_at TIMESTAMPTZ NOT NULL,
    upstream_event_at TIMESTAMPTZ NULL,
    publisher_name TEXT NOT NULL,
    publisher_domain TEXT NOT NULL,
    canonical_url TEXT NOT NULL,
    external_id TEXT NULL,
    payload_hash TEXT NOT NULL,
    payload_version TEXT NOT NULL,
    language TEXT NOT NULL,
    market_scope TEXT NOT NULL,
    title TEXT NOT NULL,
    raw_payload_json JSONB NOT NULL,
    idempotency_key TEXT NOT NULL UNIQUE,
    ingest_status TEXT NOT NULL CHECK (ingest_status IN ('accepted', 'rejected')),
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
    adapter_version TEXT NOT NULL,
    retrieval_status TEXT NOT NULL CHECK (retrieval_status IN ('ok', 'partial', 'error')),
    source_cursor TEXT NULL,
    retry_count INTEGER NOT NULL DEFAULT 0,
    ingest_count INTEGER NOT NULL DEFAULT 1,
    transport_status TEXT NULL,
    reason_code TEXT NULL,
    last_intake_status TEXT NULL CHECK (
        last_intake_status IN (
            'accepted',
            'accepted_degraded',
            'duplicate',
            'quarantined',
            'rejected',
            'retryable_failure'
        )
    ),
    last_ship_attempt_at TIMESTAMPTZ NULL,
    last_error_code TEXT NULL,
    prune_after TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_spool_items_status ON spool_items (status);
CREATE INDEX IF NOT EXISTS idx_spool_items_collected_at ON spool_items (collected_at);
"""


MIGRATION_SQL = """
ALTER TABLE spool_items ADD COLUMN IF NOT EXISTS collected_at TIMESTAMPTZ;
ALTER TABLE spool_items ADD COLUMN IF NOT EXISTS upstream_event_at TIMESTAMPTZ;
ALTER TABLE spool_items ADD COLUMN IF NOT EXISTS payload_hash TEXT;
ALTER TABLE spool_items ADD COLUMN IF NOT EXISTS ingest_status TEXT DEFAULT 'accepted';
ALTER TABLE spool_items ADD COLUMN IF NOT EXISTS adapter_version TEXT DEFAULT 'collector-v1';
ALTER TABLE spool_items ADD COLUMN IF NOT EXISTS retrieval_status TEXT DEFAULT 'ok';
ALTER TABLE spool_items ADD COLUMN IF NOT EXISTS source_cursor TEXT;
ALTER TABLE spool_items ADD COLUMN IF NOT EXISTS transport_status TEXT;
ALTER TABLE spool_items ADD COLUMN IF NOT EXISTS reason_code TEXT;
ALTER TABLE spool_items ADD COLUMN IF NOT EXISTS last_intake_status TEXT;
ALTER TABLE spool_items ADD COLUMN IF NOT EXISTS last_ship_attempt_at TIMESTAMPTZ;
ALTER TABLE spool_items ADD COLUMN IF NOT EXISTS prune_after TIMESTAMPTZ;
ALTER TABLE spool_items ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT now();
ALTER TABLE spool_items ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'spool_items' AND column_name = 'collected_at_utc'
    ) THEN
        EXECUTE 'UPDATE spool_items SET collected_at = COALESCE(collected_at, collected_at_utc) WHERE collected_at IS NULL';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'spool_items' AND column_name = 'upstream_event_at_utc'
    ) THEN
        EXECUTE 'UPDATE spool_items SET upstream_event_at = COALESCE(upstream_event_at, upstream_event_at_utc) WHERE upstream_event_at IS NULL';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'spool_items' AND column_name = 'payload_hash_sha256'
    ) THEN
        EXECUTE 'UPDATE spool_items SET payload_hash = COALESCE(payload_hash, payload_hash_sha256) WHERE payload_hash IS NULL';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'spool_items' AND column_name = 'last_ship_attempt_at_utc'
    ) THEN
        EXECUTE 'UPDATE spool_items SET last_ship_attempt_at = COALESCE(last_ship_attempt_at, last_ship_attempt_at_utc) WHERE last_ship_attempt_at IS NULL';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'spool_items' AND column_name = 'prune_after_utc'
    ) THEN
        EXECUTE 'UPDATE spool_items SET prune_after = COALESCE(prune_after, prune_after_utc) WHERE prune_after IS NULL';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'spool_items' AND column_name = 'created_at_utc'
    ) THEN
        EXECUTE 'UPDATE spool_items SET created_at = COALESCE(created_at, created_at_utc) WHERE created_at IS NULL';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'spool_items' AND column_name = 'updated_at_utc'
    ) THEN
        EXECUTE 'UPDATE spool_items SET updated_at = COALESCE(updated_at, updated_at_utc) WHERE updated_at IS NULL';
    END IF;
END $$;
"""


def connect(db_url: str) -> psycopg.Connection:
    return psycopg.connect(db_url)


def migrate(db_url: str) -> None:
    with connect(db_url) as conn:
        with conn.cursor() as cur:
            cur.execute(SCHEMA_SQL)
            cur.execute(MIGRATION_SQL)
        conn.commit()


def reset(db_url: str) -> None:
    with connect(db_url) as conn:
        with conn.cursor() as cur:
            cur.execute("TRUNCATE TABLE spool_items;")
        conn.commit()

