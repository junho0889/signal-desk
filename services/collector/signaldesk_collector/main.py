from __future__ import annotations

import argparse
from datetime import datetime, timedelta, timezone
import hashlib
import json
from pathlib import Path
from typing import Any
from urllib.parse import urlparse
import uuid

from .config import Settings, load_settings
from .db import connect, migrate, reset


SPOOL_NAMESPACE = uuid.UUID("5e22fc76-2efd-4d0f-830c-6a6305f17338")
KNOWN_LANGUAGES = {"en", "ko", "ja", "zh", "de", "fr", "es"}
STALE_THRESHOLDS_HOURS = {
    "news_primary": 72,
    "search_trends": 6,
    "market_ohlcv": 6,
    "dart_disclosures": 24 * 7,
}


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


def _parse_upstream_ts(raw_value: str | None) -> datetime | None:
    if not raw_value:
        return None
    value = raw_value.replace("Z", "+00:00")
    return datetime.fromisoformat(value).astimezone(timezone.utc)


def _normalize_title(title: str) -> str:
    return " ".join(title.strip().lower().split())


def _idempotency_key(source_id: str, row: dict[str, Any]) -> str:
    if source_id == "news_primary":
        material = f"{row.get('source_name', '')}|{_normalize_title(row.get('title', ''))}|{row.get('published_at', '')}"
    elif source_id == "search_trends":
        material = f"{row.get('keyword', '')}|{row.get('region', '')}|{row.get('window_end', '')}"
    elif source_id == "market_ohlcv":
        material = f"{row.get('symbol', '')}|{row.get('ts', '')}"
    elif source_id == "dart_disclosures":
        material = str(row.get("filing_id", ""))
    else:
        canonical = json.dumps(row, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
        material = canonical
    return hashlib.sha1(material.encode("utf-8")).hexdigest()


def _payload_hash(payload: dict[str, Any]) -> str:
    canonical = json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def _load_fixture(path: str) -> list[dict[str, Any]]:
    fixture_path = Path(path)
    if not fixture_path.exists():
        raise FileNotFoundError(f"Fixture not found: {fixture_path}")
    return json.loads(fixture_path.read_text(encoding="utf-8"))


def _infer_upstream_event_raw(source_id: str, row: dict[str, Any]) -> str | None:
    if source_id == "news_primary":
        return row.get("published_at")
    if source_id == "search_trends":
        return row.get("window_end")
    if source_id == "market_ohlcv":
        return row.get("ts")
    if source_id == "dart_disclosures":
        return row.get("filed_at")
    return row.get("upstream_event_at")


def _validate_envelope(row: dict[str, Any], settings: Settings, now: datetime) -> dict[str, Any]:
    required_payload_fields = ("source_name", "title", "url")
    missing = [key for key in required_payload_fields if not row.get(key)]
    if missing:
        return {
            "ingest_status": "rejected",
            "quality_state": "dead_letter",
            "reason_code": "missing_required_field",
            "last_error_code": f"missing:{','.join(missing)}",
            "upstream_event_at": None,
            "publisher_domain": "",
        }

    url = str(row["url"])
    publisher_domain = (urlparse(url).hostname or "").lower()
    if not publisher_domain:
        return {
            "ingest_status": "rejected",
            "quality_state": "dead_letter",
            "reason_code": "invalid_canonical_url",
            "last_error_code": "invalid_canonical_url",
            "upstream_event_at": None,
            "publisher_domain": "",
        }

    upstream_raw = _infer_upstream_event_raw(settings.source_id, row)
    try:
        upstream_event_at = _parse_upstream_ts(upstream_raw)
    except ValueError:
        return {
            "ingest_status": "rejected",
            "quality_state": "dead_letter",
            "reason_code": "invalid_timestamp",
            "last_error_code": "invalid_timestamp",
            "upstream_event_at": None,
            "publisher_domain": publisher_domain,
        }

    ingest_status = "accepted"
    quality_state = "accepted"
    reason_code = None
    last_error_code = None

    if settings.source_expects_upstream_event_at and upstream_event_at is None:
        quality_state = "accepted_degraded"
        reason_code = "metadata_incomplete"

    language = str(row.get("language", settings.default_language)).lower()
    if language not in KNOWN_LANGUAGES and quality_state == "accepted":
        quality_state = "accepted_degraded"
        reason_code = "unknown_language"

    if upstream_event_at:
        if upstream_event_at > now + timedelta(seconds=settings.max_future_skew_seconds):
            quality_state = "quarantined"
            reason_code = "timestamp_future"
        else:
            stale_hours = STALE_THRESHOLDS_HOURS.get(settings.source_id)
            if stale_hours and now - upstream_event_at > timedelta(hours=stale_hours):
                quality_state = "stale_source"
                reason_code = "stale_source"

    return {
        "ingest_status": ingest_status,
        "quality_state": quality_state,
        "reason_code": reason_code,
        "last_error_code": last_error_code,
        "upstream_event_at": upstream_event_at,
        "publisher_domain": publisher_domain,
    }


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
            collected_at,
            upstream_event_at,
            publisher_name,
            publisher_domain,
            canonical_url,
            external_id,
            payload_hash,
            payload_version,
            language,
            market_scope,
            title,
            raw_payload_json,
            idempotency_key,
            ingest_status,
            quality_state,
            status,
            adapter_version,
            retrieval_status,
            source_cursor,
            retry_count,
            ingest_count,
            transport_status,
            reason_code,
            last_intake_status,
            last_ship_attempt_at,
            last_error_code,
            prune_after,
            updated_at
        )
        VALUES (
            %(spool_id)s,
            %(source_id)s,
            %(source_category)s,
            %(collector_node_id)s,
            %(collected_at)s,
            %(upstream_event_at)s,
            %(publisher_name)s,
            %(publisher_domain)s,
            %(canonical_url)s,
            %(external_id)s,
            %(payload_hash)s,
            %(payload_version)s,
            %(language)s,
            %(market_scope)s,
            %(title)s,
            %(raw_payload_json)s::jsonb,
            %(idempotency_key)s,
            %(ingest_status)s,
            %(quality_state)s,
            %(status)s,
            %(adapter_version)s,
            %(retrieval_status)s,
            %(source_cursor)s,
            %(retry_count)s,
            %(ingest_count)s,
            %(transport_status)s,
            %(reason_code)s,
            %(last_intake_status)s,
            %(last_ship_attempt_at)s,
            %(last_error_code)s,
            %(prune_after)s,
            %(updated_at)s
        )
        ON CONFLICT (idempotency_key)
        DO UPDATE SET
            payload_hash = EXCLUDED.payload_hash,
            raw_payload_json = EXCLUDED.raw_payload_json,
            ingest_status = 'accepted',
            quality_state = 'duplicate',
            status = 'pending',
            ingest_count = spool_items.ingest_count + 1,
            transport_status = 'spooled',
            reason_code = 'duplicate_payload',
            updated_at = EXCLUDED.updated_at
        RETURNING (xmax = 0) AS inserted_row;
    """

    with connect(settings.db_url) as conn:
        with conn.cursor() as cur:
            for row in fixture_rows:
                validator = _validate_envelope(row, settings, now)
                idem_key = _idempotency_key(settings.source_id, row)
                payload_hash = _payload_hash(row)

                params = {
                    "spool_id": str(uuid.uuid5(SPOOL_NAMESPACE, idem_key)),
                    "source_id": settings.source_id,
                    "source_category": settings.source_category,
                    "collector_node_id": settings.collector_node_id,
                    "collected_at": now,
                    "upstream_event_at": validator["upstream_event_at"],
                    "publisher_name": row.get("source_name", "unknown"),
                    "publisher_domain": validator["publisher_domain"],
                    "canonical_url": row.get("url", ""),
                    "external_id": row.get("external_id"),
                    "payload_hash": payload_hash,
                    "payload_version": "v1",
                    "language": row.get("language", settings.default_language).lower(),
                    "market_scope": row.get("market_scope", settings.default_market_scope),
                    "title": row.get("title", "missing_title"),
                    "raw_payload_json": json.dumps(row, ensure_ascii=False),
                    "idempotency_key": idem_key,
                    "ingest_status": validator["ingest_status"],
                    "quality_state": validator["quality_state"],
                    "status": "pending"
                    if validator["ingest_status"] == "accepted"
                    else "dead_letter",
                    "adapter_version": settings.adapter_version,
                    "retrieval_status": settings.retrieval_status,
                    "source_cursor": settings.source_cursor,
                    "retry_count": 0,
                    "ingest_count": 1,
                    "transport_status": "spooled",
                    "reason_code": validator["reason_code"],
                    "last_intake_status": None,
                    "last_ship_attempt_at": None,
                    "last_error_code": validator["last_error_code"],
                    "prune_after": now + timedelta(days=30),
                    "updated_at": now,
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


def _shipper_outcome(settings: Settings) -> dict[str, Any]:
    if settings.shipper_mode == "simulate-offline":
        return {
            "status": "pending",
            "quality_state": None,
            "ingest_status": None,
            "last_intake_status": "retryable_failure",
            "last_error_code": f"central_offline_{settings.central_host}",
            "reason_code": "storage_unavailable",
            "transport_status": "offline_retry",
        }

    if settings.shipper_mode == "simulate-intake":
        status_map = {
            "accepted": "accepted",
            "accepted_degraded": "accepted",
            "duplicate": "duplicate",
            "quarantined": "accepted",
            "rejected": "dead_letter",
            "retryable_failure": "pending",
        }
        quality_map = {
            "accepted": "accepted",
            "accepted_degraded": "accepted_degraded",
            "duplicate": "duplicate",
            "quarantined": "quarantined",
            "rejected": "dead_letter",
            "retryable_failure": None,
        }
        ingest_status_map = {
            "accepted": "accepted",
            "accepted_degraded": "accepted",
            "duplicate": "accepted",
            "quarantined": "accepted",
            "rejected": "rejected",
            "retryable_failure": None,
        }
        intake_status = settings.simulated_intake_status
        return {
            "status": status_map.get(intake_status, "pending"),
            "quality_state": quality_map.get(intake_status),
            "ingest_status": ingest_status_map.get(intake_status),
            "last_intake_status": intake_status,
            "last_error_code": settings.simulated_reason_code
            if intake_status in ("rejected", "retryable_failure")
            else None,
            "reason_code": settings.simulated_reason_code,
            "transport_status": "intake_response",
        }

    return {
        "status": "shipping",
        "quality_state": None,
        "ingest_status": None,
        "last_intake_status": None,
        "last_error_code": None,
        "reason_code": None,
        "transport_status": "shipping",
    }


def command_ship_once() -> None:
    settings = load_settings()

    with connect(settings.db_url) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT spool_id::text
                FROM spool_items
                WHERE status = 'pending'
                ORDER BY collected_at
                LIMIT %s;
                """,
                (settings.shipper_batch_size,),
            )
            spool_ids = [row[0] for row in cur.fetchall()]

            outcome = _shipper_outcome(settings)
            for spool_id in spool_ids:
                cur.execute(
                    """
                    UPDATE spool_items
                    SET
                        retry_count = retry_count + 1,
                        last_ship_attempt_at = now(),
                        status = %(status)s,
                        quality_state = COALESCE(%(quality_state)s, quality_state),
                        ingest_status = COALESCE(%(ingest_status)s, ingest_status),
                        last_intake_status = %(last_intake_status)s,
                        last_error_code = %(last_error_code)s,
                        reason_code = %(reason_code)s,
                        transport_status = %(transport_status)s,
                        updated_at = now()
                    WHERE spool_id = %(spool_id)s::uuid;
                    """,
                    {
                        "spool_id": spool_id,
                        "status": outcome["status"],
                        "quality_state": outcome["quality_state"],
                        "ingest_status": outcome["ingest_status"],
                        "last_intake_status": outcome["last_intake_status"],
                        "last_error_code": outcome["last_error_code"],
                        "reason_code": outcome["reason_code"],
                        "transport_status": outcome["transport_status"],
                    },
                )
        conn.commit()

    print(
        json.dumps(
            {
                "mode": settings.shipper_mode,
                "batch_size": settings.shipper_batch_size,
                "simulated_intake_status": settings.simulated_intake_status,
                "touched_rows": len(spool_ids),
                "spool_ids": spool_ids,
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
                    status,
                    quality_state,
                    COUNT(*) AS row_count
                FROM spool_items
                GROUP BY status, quality_state
                ORDER BY status, quality_state;
                """
            )
            counts = [
                {"status": row[0], "quality_state": row[1], "count": row[2]}
                for row in cur.fetchall()
            ]
            cur.execute(
                """
                SELECT
                    MIN(collected_at) FILTER (WHERE status = 'pending') AS oldest_pending,
                    MAX(updated_at) AS last_updated
                FROM spool_items;
                """
            )
            row = cur.fetchone()
    print(
        json.dumps(
            {
                "counts": counts,
                "oldest_pending": row[0].isoformat() if row and row[0] else None,
                "last_updated": row[1].isoformat() if row and row[1] else None,
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
