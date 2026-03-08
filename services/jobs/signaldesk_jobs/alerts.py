from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

import psycopg

SEVERITY_RANK = {
    "low": 0,
    "medium": 1,
    "high": 2,
    "critical": 3,
}


def _derive_severity(delta_1d: float) -> str:
    magnitude = abs(delta_1d)
    if magnitude >= 8.0:
        return "critical"
    if magnitude >= 5.0:
        return "high"
    if magnitude >= 3.0:
        return "medium"
    return "low"


def _passes_min_severity(actual: str, minimum: str) -> bool:
    return SEVERITY_RANK[actual] >= SEVERITY_RANK[minimum]


def _is_cooled_down(conn: psycopg.Connection, watchlist_item_id: Any, cooldown_minutes: int) -> bool:
    row = conn.execute(
        """
        SELECT 1
        FROM alerts
        WHERE watchlist_item_id = %(watchlist_item_id)s
          AND triggered_at >= now() - (%(cooldown_minutes)s::text || ' minutes')::interval
        LIMIT 1
        """,
        {
            "watchlist_item_id": watchlist_item_id,
            "cooldown_minutes": cooldown_minutes,
        },
    ).fetchone()
    return row is not None


def evaluate_alerts(conn: psycopg.Connection, *, delta_threshold: float) -> dict[str, Any]:
    created: list[dict[str, Any]] = []
    triggered_at = datetime.now(timezone.utc)

    keyword_rows = conn.execute(
        """
        SELECT
          wi.id AS watchlist_item_id,
          wi.target_id AS keyword_id,
          war.min_severity,
          war.cooldown_minutes,
          k.canonical_name,
          ks.score_delta_24h,
          ks.score_total,
          ks.is_alert_eligible
        FROM watchlist_items wi
        JOIN watchlist_alert_rules war
          ON war.watchlist_item_id = wi.id
         AND war.is_enabled = true
        JOIN keywords k
          ON wi.target_type = 'keyword'
         AND wi.target_id = k.id
        JOIN LATERAL (
          SELECT
            ks.score_delta_24h,
            ks.score_total,
            ks.is_alert_eligible
          FROM keyword_snapshots ks
          WHERE ks.keyword_id = wi.target_id
          ORDER BY ks.as_of_ts DESC
          LIMIT 1
        ) ks ON true
        WHERE wi.target_type = 'keyword'
        """
    ).fetchall()

    stock_rows = conn.execute(
        """
        SELECT
          wi.id AS watchlist_item_id,
          wi.target_id AS stock_id,
          war.min_severity,
          war.cooldown_minutes,
          s.ticker,
          s.name,
          candidate.keyword_id,
          candidate.keyword_name,
          candidate.score_delta_24h,
          candidate.score_total,
          candidate.is_alert_eligible
        FROM watchlist_items wi
        JOIN watchlist_alert_rules war
          ON war.watchlist_item_id = wi.id
         AND war.is_enabled = true
        JOIN stocks s
          ON wi.target_type = 'stock'
         AND wi.target_id = s.id
        JOIN LATERAL (
          SELECT
            ks.keyword_id,
            k.canonical_name AS keyword_name,
            ks.score_delta_24h,
            ks.score_total,
            ks.is_alert_eligible
          FROM keyword_stock_links ksl
          JOIN keyword_snapshots ks ON ks.keyword_id = ksl.keyword_id
          JOIN keywords k ON k.id = ks.keyword_id
          WHERE ksl.stock_id = wi.target_id
          ORDER BY ks.as_of_ts DESC, ks.score_delta_24h DESC NULLS LAST
          LIMIT 1
        ) candidate ON true
        WHERE wi.target_type = 'stock'
        """
    ).fetchall()

    with conn.transaction():
        for row in keyword_rows:
            delta = float(row["score_delta_24h"] or 0.0)
            if not bool(row["is_alert_eligible"]) or abs(delta) < delta_threshold:
                continue

            severity = _derive_severity(delta)
            if not _passes_min_severity(severity, row["min_severity"]):
                continue
            if _is_cooled_down(conn, row["watchlist_item_id"], int(row["cooldown_minutes"])):
                continue

            message = (
                f"{row['canonical_name']} moved {delta:+.2f} in 24h "
                f"(score {float(row['score_total']):.2f})"
            )
            inserted = conn.execute(
                """
                INSERT INTO alerts (
                  target_type,
                  target_id,
                  keyword_id,
                  watchlist_item_id,
                  triggered_at,
                  severity,
                  message
                )
                VALUES ('keyword', %(target_id)s, %(keyword_id)s, %(watchlist_item_id)s, %(triggered_at)s, %(severity)s, %(message)s)
                RETURNING id
                """,
                {
                    "target_id": row["keyword_id"],
                    "keyword_id": row["keyword_id"],
                    "watchlist_item_id": row["watchlist_item_id"],
                    "triggered_at": triggered_at,
                    "severity": severity,
                    "message": message,
                },
            ).fetchone()

            created.append(
                {
                    "alert_id": str(inserted["id"]),
                    "target_type": "keyword",
                    "target_id": str(row["keyword_id"]),
                    "target_label": row["canonical_name"],
                    "keyword_id": str(row["keyword_id"]),
                    "severity": severity,
                    "message": message,
                    "triggered_at": triggered_at.isoformat().replace("+00:00", "Z"),
                }
            )

        for row in stock_rows:
            delta = float(row["score_delta_24h"] or 0.0)
            if not bool(row["is_alert_eligible"]) or abs(delta) < delta_threshold:
                continue

            severity = _derive_severity(delta)
            if not _passes_min_severity(severity, row["min_severity"]):
                continue
            if _is_cooled_down(conn, row["watchlist_item_id"], int(row["cooldown_minutes"])):
                continue

            message = (
                f"{row['ticker']} | {row['name']} linked keyword {row['keyword_name']} "
                f"moved {delta:+.2f} in 24h"
            )
            inserted = conn.execute(
                """
                INSERT INTO alerts (
                  target_type,
                  target_id,
                  keyword_id,
                  watchlist_item_id,
                  triggered_at,
                  severity,
                  message
                )
                VALUES ('stock', %(target_id)s, %(keyword_id)s, %(watchlist_item_id)s, %(triggered_at)s, %(severity)s, %(message)s)
                RETURNING id
                """,
                {
                    "target_id": row["stock_id"],
                    "keyword_id": row["keyword_id"],
                    "watchlist_item_id": row["watchlist_item_id"],
                    "triggered_at": triggered_at,
                    "severity": severity,
                    "message": message,
                },
            ).fetchone()

            created.append(
                {
                    "alert_id": str(inserted["id"]),
                    "target_type": "stock",
                    "target_id": str(row["stock_id"]),
                    "target_label": row["ticker"],
                    "keyword_id": str(row["keyword_id"]),
                    "severity": severity,
                    "message": message,
                    "triggered_at": triggered_at.isoformat().replace("+00:00", "Z"),
                }
            )

    return {
        "inserted": len(created),
        "items": created,
    }
