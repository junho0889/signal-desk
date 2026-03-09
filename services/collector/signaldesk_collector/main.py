from __future__ import annotations

import argparse
from datetime import datetime, timedelta, timezone
import hashlib
import json
from pathlib import Path
import time
from typing import Any
from urllib.parse import urlparse, urlunparse
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
REQUIRED_FIELDS_BY_SOURCE = {
    "news_primary": ("source_name", "title", "published_at"),
    "search_trends": ("keyword", "region", "window_end"),
    "market_ohlcv": ("symbol", "ts"),
    "dart_disclosures": ("filing_id", "filed_at", "title"),
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


def _normalize_whitespace(value: Any) -> str:
    if value is None:
        return ""
    return " ".join(str(value).strip().split())


def _normalize_timestamp_literal(raw_value: Any) -> str:
    raw = _normalize_whitespace(raw_value)
    if not raw:
        return ""
    try:
        parsed = _parse_upstream_ts(raw)
    except (TypeError, ValueError):
        return raw
    if parsed is None:
        return ""
    return parsed.replace(microsecond=0).isoformat()


def _normalize_url(raw_url: Any) -> str:
    value = _normalize_whitespace(raw_url)
    if not value:
        return ""
    parsed = urlparse(value)
    host = (parsed.hostname or "").lower()
    scheme = (parsed.scheme or "https").lower()
    path = parsed.path or "/"
    if path != "/" and path.endswith("/"):
        path = path.rstrip("/")
    return urlunparse((scheme, host, path, "", "", ""))


def _synthetic_url(source_id: str, row: dict[str, Any]) -> str:
    if source_id == "search_trends":
        key = "|".join(
            (
                _normalize_whitespace(row.get("keyword")).lower(),
                _normalize_whitespace(row.get("region")).lower(),
                _normalize_timestamp_literal(row.get("window_end")),
            )
        )
    elif source_id == "market_ohlcv":
        key = "|".join(
            (
                _normalize_whitespace(row.get("symbol")).upper(),
                _normalize_timestamp_literal(row.get("ts")),
            )
        )
    elif source_id == "dart_disclosures":
        key = _normalize_whitespace(row.get("filing_id"))
    else:
        key = _normalize_whitespace(row.get("external_id")) or _normalize_whitespace(
            row.get("title")
        )
    key_hash = hashlib.sha1(key.encode("utf-8")).hexdigest()[:16]
    return f"https://synthetic.signaldesk.local/{source_id}/{key_hash}"


def _normalize_market_scope(raw_scope: Any, default_scope: str) -> str:
    value = _normalize_whitespace(raw_scope).upper()
    if not value:
        return default_scope.upper()
    aliases = {
        "KOSPI": "KRX",
        "KOSDAQ": "KRX",
        "NASDAQ": "US",
        "NYSE": "US",
        "AMEX": "US",
    }
    return aliases.get(value, value)


def _normalize_row(settings: Settings, row: dict[str, Any]) -> dict[str, Any]:
    normalized = dict(row)
    normalized["source_name"] = _normalize_whitespace(
        row.get("source_name") or row.get("issuer") or settings.source_id
    )
    normalized["title"] = _normalize_whitespace(row.get("title"))
    normalized["language"] = _normalize_whitespace(
        row.get("language", settings.default_language)
    ).lower()
    normalized["market_scope"] = _normalize_market_scope(
        row.get("market_scope", settings.default_market_scope),
        settings.default_market_scope,
    )
    normalized["external_id"] = _normalize_whitespace(row.get("external_id"))
    normalized["published_at"] = _normalize_timestamp_literal(row.get("published_at"))
    normalized["window_end"] = _normalize_timestamp_literal(row.get("window_end"))
    normalized["ts"] = _normalize_timestamp_literal(row.get("ts"))
    normalized["filed_at"] = _normalize_timestamp_literal(row.get("filed_at"))
    normalized["url"] = _normalize_url(row.get("url")) or _synthetic_url(
        settings.source_id, row
    )
    return normalized


def _idempotency_key(source_id: str, row: dict[str, Any]) -> str:
    if source_id == "news_primary":
        material = "|".join(
            (
                _normalize_whitespace(row.get("source_name")).lower(),
                _normalize_title(str(row.get("title", ""))),
                _normalize_url(row.get("url")),
                _normalize_timestamp_literal(row.get("published_at")),
            )
        )
    elif source_id == "search_trends":
        material = "|".join(
            (
                _normalize_whitespace(row.get("keyword")).lower(),
                _normalize_whitespace(row.get("region")).lower(),
                _normalize_timestamp_literal(row.get("window_end")),
            )
        )
    elif source_id == "market_ohlcv":
        material = "|".join(
            (
                _normalize_whitespace(row.get("symbol")).upper(),
                _normalize_timestamp_literal(row.get("ts")),
            )
        )
    elif source_id == "dart_disclosures":
        material = _normalize_whitespace(row.get("filing_id"))
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


def _format_utc_z(value: datetime) -> str:
    return value.astimezone(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def _stream_fixture_rows(
    settings: Settings,
    fixture_rows: list[dict[str, Any]],
    cycle: int,
) -> list[dict[str, Any]]:
    if cycle <= 1 or not settings.daemon_stream_mode:
        return fixture_rows

    offset = timedelta(minutes=settings.daemon_event_step_minutes * (cycle - 1))
    streamed: list[dict[str, Any]] = []
    timestamp_field_by_source = {
        "news_primary": "published_at",
        "search_trends": "window_end",
        "market_ohlcv": "ts",
        "dart_disclosures": "filed_at",
    }
    ts_field = timestamp_field_by_source.get(settings.source_id)

    for row in fixture_rows:
        row_copy = dict(row)
        if settings.source_id == "news_primary":
            row_copy["title"] = f"{_normalize_whitespace(row.get('title'))} [cycle-{cycle}]".strip()
        if ts_field:
            raw_ts = row.get(ts_field)
            parsed = _parse_upstream_ts(str(raw_ts)) if raw_ts else None
            if parsed:
                row_copy[ts_field] = _format_utc_z(parsed + offset)
        streamed.append(row_copy)
    return streamed


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
    required_payload_fields = REQUIRED_FIELDS_BY_SOURCE.get(
        settings.source_id,
        ("source_name", "title"),
    )
    missing = [key for key in required_payload_fields if not _normalize_whitespace(row.get(key))]
    if missing:
        return {
            "ingest_status": "rejected",
            "quality_state": "dead_letter",
            "reason_code": "missing_required_field",
            "last_error_code": f"missing:{','.join(missing)}",
            "upstream_event_at": None,
            "publisher_domain": "",
        }

    url = _normalize_url(row.get("url"))
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
    except (TypeError, ValueError):
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

    language = _normalize_whitespace(row.get("language", settings.default_language)).lower()
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


def _ingest_rows(settings: Settings, fixture_rows: list[dict[str, Any]], now: datetime) -> dict[str, Any]:
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
            publisher_domain = EXCLUDED.publisher_domain,
            canonical_url = EXCLUDED.canonical_url,
            language = EXCLUDED.language,
            market_scope = EXCLUDED.market_scope,
            title = EXCLUDED.title,
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
                normalized_row = _normalize_row(settings, row)
                validator = _validate_envelope(normalized_row, settings, now)
                idem_key = _idempotency_key(settings.source_id, normalized_row)
                payload_hash = _payload_hash(normalized_row)

                params = {
                    "spool_id": str(uuid.uuid5(SPOOL_NAMESPACE, idem_key)),
                    "source_id": settings.source_id,
                    "source_category": settings.source_category,
                    "collector_node_id": settings.collector_node_id,
                    "collected_at": now,
                    "upstream_event_at": validator["upstream_event_at"],
                    "publisher_name": normalized_row.get("source_name", "unknown"),
                    "publisher_domain": validator["publisher_domain"],
                    "canonical_url": normalized_row.get("url", ""),
                    "external_id": normalized_row.get("external_id") or None,
                    "payload_hash": payload_hash,
                    "payload_version": "v1",
                    "language": normalized_row.get("language", settings.default_language).lower(),
                    "market_scope": normalized_row.get(
                        "market_scope", settings.default_market_scope
                    ),
                    "title": normalized_row.get("title", "missing_title"),
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

    return {
        "rows_read": len(fixture_rows),
        "inserted": inserted,
        "upserted": upserted,
    }


def command_ingest_fixture(fixture_path: str | None) -> None:
    settings = load_settings()
    use_path = fixture_path or settings.fixture_path
    fixture_rows = _load_fixture(use_path)
    now = _utcnow()
    ingest_result = _ingest_rows(settings, fixture_rows, now)

    print(
        json.dumps(
            {
                "fixture_path": use_path,
                "rows_read": ingest_result["rows_read"],
                "inserted": ingest_result["inserted"],
                "upserted": ingest_result["upserted"],
            }
        )
    )


def command_run_daemon() -> None:
    settings = load_settings()
    cycle = 0
    while True:
        cycle += 1
        cycle_started_at = _utcnow()
        cycle_result: dict[str, Any] = {
            "mode": "daemon",
            "cycle": cycle,
            "started_at": cycle_started_at.isoformat(),
            "ingest": None,
            "ship": None,
            "error": None,
        }
        try:
            base_fixture_rows = _load_fixture(settings.fixture_path)
            cycle_fixture_rows = _stream_fixture_rows(settings, base_fixture_rows, cycle)
            cycle_result["ingest"] = _ingest_rows(settings, cycle_fixture_rows, cycle_started_at)
            if settings.daemon_ship_every_cycles > 0 and cycle % settings.daemon_ship_every_cycles == 0:
                command_ship_once()
                cycle_result["ship"] = {
                    "executed": True,
                    "ship_every_cycles": settings.daemon_ship_every_cycles,
                }
            else:
                cycle_result["ship"] = {"executed": False}
        except Exception as exc:
            cycle_result["error"] = str(exc)

        print(json.dumps(cycle_result))

        if settings.daemon_max_cycles > 0 and cycle >= settings.daemon_max_cycles:
            break
        time.sleep(max(1, settings.daemon_interval_seconds))


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
            "increment_retry": True,
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
        transport_map = {
            "accepted": "delivered",
            "accepted_degraded": "delivered",
            "duplicate": "delivered",
            "quarantined": "intake_response",
            "rejected": "intake_response",
            "retryable_failure": "offline_retry",
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
            "transport_status": transport_map.get(intake_status, "intake_response"),
            "increment_retry": intake_status == "retryable_failure",
        }

    return {
        "status": "shipping",
        "quality_state": None,
        "ingest_status": None,
        "last_intake_status": None,
        "last_error_code": None,
        "reason_code": None,
        "transport_status": "shipping",
        "increment_retry": False,
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
                        retry_count = CASE WHEN %(increment_retry)s THEN retry_count + 1 ELSE retry_count END,
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
                        "increment_retry": outcome["increment_retry"],
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
    subparsers.add_parser("run-daemon")
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
    elif args.command == "run-daemon":
        command_run_daemon()
    else:
        parser.error(f"Unknown command: {args.command}")


if __name__ == "__main__":
    main()
