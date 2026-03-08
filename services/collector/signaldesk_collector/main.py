from __future__ import annotations

import argparse
from datetime import datetime, timedelta, timezone
import hashlib
import json
from pathlib import Path
from urllib.parse import urlparse
import uuid

from .config import load_settings
from .db import connect, migrate, reset


SPOOL_NAMESPACE = uuid.UUID("5e22fc76-2efd-4d0f-830c-6a6305f17338")


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


def _parse_upstream_ts(raw_value: str | None) -> datetime | None:
    if not raw_value:
        return None
    value = raw_value.replace("Z", "+00:00")
    return datetime.fromisoformat(value).astimezone(timezone.utc)


def _normalize_title(title: str) -> str:
    return " ".join(title.strip().lower().split())


def _idempotency_key(source_name: str, title: str, published_at: str) -> str:
    material = f"{source_name}|{_normalize_title(title)}|{published_at}"
    return hashlib.sha1(material.encode("utf-8")).hexdigest()


def _payload_hash(payload: dict) -> str:
    canonical = json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def _load_fixture(path: str) -> list[dict]:
    fixture_path = Path(path)
    if not fixture_path.exists():
        raise FileNotFoundError(f"Fixture not found: {fixture_path}")
    return json.loads(fixture_path.read_text(encoding="utf-8"))


def command_migrate() -> None:
    settings = load_settings()
    migrate(settings.db_url)
    print("migrate: ok")


def command_reset_db() -> None:
    settings = load_settings()
    reset(settings.db_url)
    print("reset-db: ok")


def command_ingest_fixture(fixture_path: str | None) -> None:
    settings = load_settings()
    use_path = fixture_path or settings.fixture_path
    fixture_rows = _load_fixture(use_path)
    now = _utcnow()
    inserted = 0
    upserted = 0

    sql = """
        INSERT INTO spool_items (
            spool_id,
            source_id,
            source_category,
            collector_node_id,
            collected_at_utc,
            upstream_event_at_utc,
            publisher_name,
            publisher_domain,
            canonical_url,
            external_id,
            payload_hash_sha256,
            payload_version,
            language,
            market_scope,
            title,
            raw_payload_json,
            idempotency_key,
            quality_state,
            status,
            retry_count,
            ingest_count,
            last_ship_attempt_at_utc,
            last_error_code,
            prune_after_utc,
            updated_at_utc
        )
        VALUES (
            %(spool_id)s,
            %(source_id)s,
            %(source_category)s,
            %(collector_node_id)s,
            %(collected_at_utc)s,
            %(upstream_event_at_utc)s,
            %(publisher_name)s,
            %(publisher_domain)s,
            %(canonical_url)s,
            %(external_id)s,
            %(payload_hash_sha256)s,
            %(payload_version)s,
            %(language)s,
            %(market_scope)s,
            %(title)s,
            %(raw_payload_json)s::jsonb,
            %(idempotency_key)s,
            %(quality_state)s,
            %(status)s,
            %(retry_count)s,
            %(ingest_count)s,
            %(last_ship_attempt_at_utc)s,
            %(last_error_code)s,
            %(prune_after_utc)s,
            %(updated_at_utc)s
        )
        ON CONFLICT (idempotency_key)
        DO UPDATE SET
            payload_hash_sha256 = EXCLUDED.payload_hash_sha256,
            raw_payload_json = EXCLUDED.raw_payload_json,
            ingest_count = spool_items.ingest_count + 1,
            status = 'pending',
            updated_at_utc = EXCLUDED.updated_at_utc
        RETURNING (xmax = 0) AS inserted_row;
    """

    with connect(settings.db_url) as conn:
        with conn.cursor() as cur:
            for row in fixture_rows:
                url = row["url"]
                publisher_name = row["source_name"]
                published_at = row["published_at"]
                idem_key = _idempotency_key(publisher_name, row["title"], published_at)
                payload_hash = _payload_hash(row)

                params = {
                    "spool_id": str(uuid.uuid5(SPOOL_NAMESPACE, idem_key)),
                    "source_id": settings.source_id,
                    "source_category": settings.source_category,
                    "collector_node_id": settings.collector_node_id,
                    "collected_at_utc": now,
                    "upstream_event_at_utc": _parse_upstream_ts(published_at),
                    "publisher_name": publisher_name,
                    "publisher_domain": (urlparse(url).hostname or "").lower(),
                    "canonical_url": url,
                    "external_id": row.get("external_id"),
                    "payload_hash_sha256": payload_hash,
                    "payload_version": "v1",
                    "language": row.get("language", settings.default_language),
                    "market_scope": row.get("market_scope", settings.default_market_scope),
                    "title": row["title"],
                    "raw_payload_json": json.dumps(row, ensure_ascii=False),
                    "idempotency_key": idem_key,
                    "quality_state": "accepted",
                    "status": "pending",
                    "retry_count": 0,
                    "ingest_count": 1,
                    "last_ship_attempt_at_utc": None,
                    "last_error_code": None,
                    "prune_after_utc": now + timedelta(days=30),
                    "updated_at_utc": now,
                }
                cur.execute(sql, params)
                was_inserted = cur.fetchone()[0]
                if was_inserted:
                    inserted += 1
                else:
                    upserted += 1
        conn.commit()

    print(
        json.dumps(
            {
                "fixture_path": use_path,
                "rows_read": len(fixture_rows),
                "inserted": inserted,
                "upserted": upserted,
            }
        )
    )


def command_ship_once() -> None:
    settings = load_settings()
    mode = settings.shipper_mode

    with connect(settings.db_url) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                WITH batch AS (
                    SELECT spool_id
                    FROM spool_items
                    WHERE status = 'pending'
                    ORDER BY collected_at_utc
                    LIMIT %s
                )
                UPDATE spool_items AS s
                SET
                    retry_count = s.retry_count + 1,
                    last_ship_attempt_at_utc = now(),
                    last_error_code = CASE
                        WHEN %s = 'simulate-offline' THEN 'central_offline_simulated'
                        ELSE NULL
                    END,
                    status = CASE
                        WHEN %s = 'simulate-offline' THEN 'pending'
                        ELSE 'shipping'
                    END,
                    updated_at_utc = now()
                FROM batch
                WHERE s.spool_id = batch.spool_id
                RETURNING s.spool_id::text;
                """,
                (settings.shipper_batch_size, mode, mode),
            )
            rows = [row[0] for row in cur.fetchall()]
        conn.commit()

    print(
        json.dumps(
            {
                "mode": mode,
                "batch_size": settings.shipper_batch_size,
                "touched_rows": len(rows),
                "spool_ids": rows,
            }
        )
    )


def command_metrics() -> None:
    settings = load_settings()
    with connect(settings.db_url) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT
                    COALESCE(status, 'none') AS status,
                    COUNT(*) AS row_count
                FROM spool_items
                GROUP BY status
                ORDER BY status;
                """
            )
            counts = [{"status": row[0], "count": row[1]} for row in cur.fetchall()]
            cur.execute(
                """
                SELECT
                    MIN(collected_at_utc) FILTER (WHERE status = 'pending') AS oldest_pending_utc,
                    MAX(updated_at_utc) AS last_updated_utc
                FROM spool_items;
                """
            )
            row = cur.fetchone()
    print(
        json.dumps(
            {
                "counts": counts,
                "oldest_pending_utc": row[0].isoformat() if row and row[0] else None,
                "last_updated_utc": row[1].isoformat() if row and row[1] else None,
            }
        )
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="SignalDesk collector CLI")
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("migrate")
    subparsers.add_parser("reset-db")

    ingest_parser = subparsers.add_parser("ingest-fixture")
    ingest_parser.add_argument(
        "--fixture-path",
        dest="fixture_path",
        help="Path to a JSON fixture array.",
    )

    subparsers.add_parser("ship-once")
    subparsers.add_parser("metrics")
    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()

    if args.command == "migrate":
        command_migrate()
    elif args.command == "reset-db":
        command_reset_db()
    elif args.command == "ingest-fixture":
        command_ingest_fixture(args.fixture_path)
    elif args.command == "ship-once":
        command_ship_once()
    elif args.command == "metrics":
        command_metrics()
    else:
        parser.error(f"Unknown command: {args.command}")


if __name__ == "__main__":
    main()

