from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any
from uuid import UUID

import psycopg

from .errors import APIError


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def period_window_start(period: str) -> datetime:
    now = utc_now()
    if period == "intraday":
        return now - timedelta(hours=6)
    if period == "daily":
        return now - timedelta(days=1)
    if period == "weekly":
        return now - timedelta(days=7)
    raise APIError(
        status_code=400,
        code="invalid_argument",
        message="period must be one of intraday,daily,weekly",
        details={"field": "period"},
    )


def parse_cursor(cursor: str | None) -> int:
    if cursor is None or cursor == "":
        return 0
    if not cursor.isdigit():
        raise APIError(
            status_code=400,
            code="invalid_argument",
            message="cursor must be a numeric offset token",
            details={"field": "cursor"},
        )
    return int(cursor)


def _next_cursor(offset: int, limit: int, fetched_count: int) -> str | None:
    return str(offset + limit) if fetched_count > limit else None


def _fetch_generated_at(conn: psycopg.Connection, sql: str, params: tuple[Any, ...] | dict[str, Any] | None = None) -> datetime:
    row = conn.execute(sql, params).fetchone()
    generated_at = row["generated_at"] if row else None
    if isinstance(generated_at, datetime):
        return generated_at
    return utc_now()


def get_dashboard(conn: psycopg.Connection) -> dict[str, Any]:
    generated_at = _fetch_generated_at(
        conn,
        "SELECT MAX(as_of_ts) AS generated_at FROM keyword_snapshots",
    )

    top_keywords = conn.execute(
        """
        WITH latest AS (
          SELECT MAX(as_of_ts) AS as_of_ts
          FROM keyword_snapshots
        )
        SELECT
          k.id::text AS keyword_id,
          k.canonical_name AS keyword,
          ks.score_total::float8 AS score,
          ks.score_delta_24h::float8 AS delta_1d,
          ks.confidence::float8 AS confidence,
          ks.is_alert_eligible,
          ks.reason_tags,
          ks.risk_flags
        FROM keyword_snapshots ks
        JOIN latest l ON l.as_of_ts = ks.as_of_ts
        JOIN keywords k ON k.id = ks.keyword_id
        ORDER BY ks.score_total DESC, k.id
        LIMIT 10
        """
    ).fetchall()

    hot_sectors = conn.execute(
        """
        WITH latest AS (
          SELECT MAX(as_of_ts) AS as_of_ts
          FROM keyword_snapshots
        )
        SELECT
          ksl.sector,
          COUNT(DISTINCT ks.keyword_id)::int AS keyword_count,
          AVG(ks.score_total)::float8 AS avg_score,
          CASE
            WHEN COUNT(ks.score_delta_24h) = 0 THEN NULL
            ELSE AVG(ks.score_delta_24h)::float8
          END AS delta_1d
        FROM keyword_snapshots ks
        JOIN latest l ON l.as_of_ts = ks.as_of_ts
        JOIN keyword_sector_links ksl
          ON ksl.keyword_id = ks.keyword_id
         AND (ksl.snapshot_id = ks.id OR ksl.snapshot_id IS NULL)
        GROUP BY ksl.sector
        ORDER BY avg_score DESC NULLS LAST, ksl.sector
        LIMIT 10
        """
    ).fetchall()

    risk_alerts = conn.execute(
        """
        SELECT
          a.id::text AS alert_id,
          a.target_type,
          a.target_id::text AS target_id,
          a.severity,
          a.message,
          a.triggered_at
        FROM alerts a
        ORDER BY a.triggered_at DESC, a.id DESC
        LIMIT 10
        """
    ).fetchall()

    return {
        "generated_at": generated_at,
        "top_keywords": top_keywords,
        "hot_sectors": hot_sectors,
        "risk_alerts": risk_alerts,
    }


def list_keywords(
    conn: psycopg.Connection,
    *,
    period: str,
    market: str,
    sector: str | None,
    limit: int,
    cursor: str | None,
) -> dict[str, Any]:
    window_start = period_window_start(period)
    offset = parse_cursor(cursor)

    rows = conn.execute(
        """
        WITH latest_per_keyword AS (
          SELECT
            ks.keyword_id,
            MAX(ks.as_of_ts) AS as_of_ts
          FROM keyword_snapshots ks
          WHERE ks.as_of_ts >= %(window_start)s
          GROUP BY ks.keyword_id
        ),
        latest_rows AS (
          SELECT
            ks.id AS snapshot_id,
            ks.keyword_id,
            ks.as_of_ts,
            ks.score_total,
            ks.score_delta_24h,
            ks.confidence,
            ks.rank_position,
            ks.is_alert_eligible,
            ks.reason_tags,
            ks.risk_flags
          FROM keyword_snapshots ks
          JOIN latest_per_keyword lk
            ON lk.keyword_id = ks.keyword_id
           AND lk.as_of_ts = ks.as_of_ts
        )
        SELECT
          k.id::text AS keyword_id,
          k.canonical_name AS keyword,
          lr.rank_position,
          lr.score_total::float8 AS score,
          lr.score_delta_24h::float8 AS delta_1d,
          lr.confidence::float8 AS confidence,
          lr.is_alert_eligible,
          lr.reason_tags,
          lr.risk_flags,
          COALESCE(
            array_agg(DISTINCT ksl.sector) FILTER (WHERE ksl.sector IS NOT NULL),
            '{}'::text[]
          ) AS related_sectors,
          MAX(lr.as_of_ts) AS as_of_ts
        FROM latest_rows lr
        JOIN keywords k ON k.id = lr.keyword_id
        LEFT JOIN keyword_sector_links ksl
          ON ksl.keyword_id = lr.keyword_id
         AND (ksl.snapshot_id = lr.snapshot_id OR ksl.snapshot_id IS NULL)
        WHERE (%(market)s = 'all' OR k.market_scope = %(market)s)
          AND (
            %(sector)s::text IS NULL
            OR EXISTS (
              SELECT 1
              FROM keyword_sector_links ksl2
              WHERE ksl2.keyword_id = lr.keyword_id
                AND ksl2.sector = %(sector)s::text
                AND (ksl2.snapshot_id = lr.snapshot_id OR ksl2.snapshot_id IS NULL)
            )
          )
        GROUP BY
          k.id,
          k.canonical_name,
          lr.rank_position,
          lr.score_total,
          lr.score_delta_24h,
          lr.confidence,
          lr.is_alert_eligible,
          lr.reason_tags,
          lr.risk_flags
        ORDER BY lr.score_total DESC, k.id
        LIMIT %(limit_plus_one)s OFFSET %(offset)s
        """,
        {
            "window_start": window_start,
            "market": market,
            "sector": sector,
            "limit_plus_one": limit + 1,
            "offset": offset,
        },
    ).fetchall()

    generated_at = _fetch_generated_at(
        conn,
        "SELECT MAX(as_of_ts) AS generated_at FROM keyword_snapshots WHERE as_of_ts >= %(window_start)s",
        {"window_start": window_start},
    )

    next_cursor = _next_cursor(offset, limit, len(rows))
    items = rows[:limit]

    return {
        "generated_at": generated_at,
        "items": items,
        "next_cursor": next_cursor,
    }


def get_keyword_detail(
    conn: psycopg.Connection,
    *,
    keyword_id: str,
    period: str,
    points: int,
) -> dict[str, Any]:
    keyword_uuid = _parse_uuid(keyword_id, field="keyword_id")
    window_start = period_window_start(period)

    snapshot = conn.execute(
        """
        SELECT
          ks.id AS snapshot_id,
          ks.as_of_ts AS generated_at,
          k.id::text AS keyword_id,
          k.canonical_name AS keyword,
          ks.score_total::float8 AS score,
          ks.score_delta_24h::float8 AS delta_1d,
          ks.confidence::float8 AS confidence,
          ks.is_alert_eligible,
          ks.dimension_mentions::float8 AS dimension_mentions,
          ks.dimension_trends::float8 AS dimension_trends,
          ks.dimension_market::float8 AS dimension_market,
          ks.dimension_events::float8 AS dimension_events,
          ks.dimension_persistence::float8 AS dimension_persistence,
          ks.reason_tags,
          ks.risk_flags
        FROM keyword_snapshots ks
        JOIN keywords k ON k.id = ks.keyword_id
        WHERE ks.keyword_id = %(keyword_id)s
        ORDER BY ks.as_of_ts DESC
        LIMIT 1
        """,
        {"keyword_id": keyword_uuid},
    ).fetchone()

    if not snapshot:
        raise APIError(
            status_code=404,
            code="not_found",
            message="keyword not found",
            details={"keyword_id": keyword_id},
        )

    timeseries = conn.execute(
        """
        SELECT
          ks.as_of_ts AS snapshot_at,
          ks.score_total::float8 AS score,
          ks.confidence::float8 AS confidence
        FROM keyword_snapshots ks
        WHERE ks.keyword_id = %(keyword_id)s
          AND ks.as_of_ts >= %(window_start)s
        ORDER BY ks.as_of_ts DESC
        LIMIT %(points)s
        """,
        {
            "keyword_id": keyword_uuid,
            "window_start": window_start,
            "points": points,
        },
    ).fetchall()
    timeseries.reverse()

    related_news = conn.execute(
        """
        SELECT
          ni.id::text AS news_id,
          ni.source_name,
          ni.published_at,
          ni.title,
          ni.url,
          knl.relevance_score::float8 AS relevance_score
        FROM keyword_news_links knl
        JOIN news_items ni ON ni.id = knl.news_item_id
        WHERE knl.keyword_id = %(keyword_id)s
          AND (knl.snapshot_id = %(snapshot_id)s OR knl.snapshot_id IS NULL)
        ORDER BY ni.published_at DESC, ni.id DESC
        LIMIT 20
        """,
        {
            "keyword_id": keyword_uuid,
            "snapshot_id": snapshot["snapshot_id"],
        },
    ).fetchall()

    related_stocks = conn.execute(
        """
        SELECT
          s.id::text AS stock_id,
          s.ticker,
          s.name,
          s.market,
          s.sector,
          ksl.link_confidence::float8 AS link_confidence
        FROM keyword_stock_links ksl
        JOIN stocks s ON s.id = ksl.stock_id
        WHERE ksl.keyword_id = %(keyword_id)s
          AND (ksl.snapshot_id = %(snapshot_id)s OR ksl.snapshot_id IS NULL)
        ORDER BY ksl.link_confidence DESC NULLS LAST, s.ticker
        LIMIT 20
        """,
        {
            "keyword_id": keyword_uuid,
            "snapshot_id": snapshot["snapshot_id"],
        },
    ).fetchall()

    related_sectors = [
        row["sector"]
        for row in conn.execute(
            """
            SELECT DISTINCT ksl.sector
            FROM keyword_sector_links ksl
            WHERE ksl.keyword_id = %(keyword_id)s
              AND (ksl.snapshot_id = %(snapshot_id)s OR ksl.snapshot_id IS NULL)
            ORDER BY ksl.sector
            """,
            {
                "keyword_id": keyword_uuid,
                "snapshot_id": snapshot["snapshot_id"],
            },
        ).fetchall()
    ]

    reason_tags = snapshot["reason_tags"] or []
    reason_block = None
    if reason_tags:
        reason_block = "Signals: " + ", ".join(reason_tags)

    return {
        "generated_at": snapshot["generated_at"],
        "keyword_id": snapshot["keyword_id"],
        "keyword": snapshot["keyword"],
        "score_summary": {
            "score": snapshot["score"],
            "delta_1d": snapshot["delta_1d"],
            "confidence": snapshot["confidence"],
            "is_alert_eligible": snapshot["is_alert_eligible"],
            "dimension_mentions": snapshot["dimension_mentions"],
            "dimension_trends": snapshot["dimension_trends"],
            "dimension_market": snapshot["dimension_market"],
            "dimension_events": snapshot["dimension_events"],
            "dimension_persistence": snapshot["dimension_persistence"],
        },
        "reason_block": reason_block,
        "timeseries": timeseries,
        "related_news": related_news,
        "related_stocks": related_stocks,
        "related_sectors": related_sectors,
        "risk_flags": snapshot["risk_flags"] or [],
    }


def get_watchlist(conn: psycopg.Connection) -> dict[str, Any]:
    generated_at = _fetch_generated_at(
        conn,
        """
        SELECT GREATEST(
          COALESCE((SELECT MAX(as_of_ts) FROM keyword_snapshots), now()),
          COALESCE((SELECT MAX(triggered_at) FROM alerts), now())
        ) AS generated_at
        """,
    )

    keyword_items = conn.execute(
        """
        WITH latest_snapshot AS (
          SELECT DISTINCT ON (ks.keyword_id)
            ks.keyword_id,
            ks.score_total,
            ks.score_delta_24h,
            ks.is_alert_eligible,
            ks.risk_flags,
            ks.as_of_ts
          FROM keyword_snapshots ks
          ORDER BY ks.keyword_id, ks.as_of_ts DESC
        ),
        latest_alert AS (
          SELECT DISTINCT ON (a.target_id)
            a.target_id,
            a.severity
          FROM alerts a
          WHERE a.target_type = 'keyword'
          ORDER BY a.target_id, a.triggered_at DESC
        )
        SELECT
          wi.id::text AS watchlist_item_id,
          k.id::text AS keyword_id,
          k.canonical_name AS keyword,
          ls.score_total::float8 AS score,
          ls.score_delta_24h::float8 AS delta_1d,
          ls.is_alert_eligible,
          COALESCE(ls.risk_flags, '{}'::text[]) AS risk_flags,
          la.severity
        FROM watchlist_items wi
        JOIN keywords k
          ON wi.target_type = 'keyword'
         AND wi.target_id = k.id
        LEFT JOIN latest_snapshot ls ON ls.keyword_id = k.id
        LEFT JOIN latest_alert la ON la.target_id = wi.target_id
        ORDER BY wi.created_at DESC, wi.id DESC
        """
    ).fetchall()

    stock_items = conn.execute(
        """
        WITH latest_alert AS (
          SELECT DISTINCT ON (a.target_id)
            a.target_id,
            a.severity
          FROM alerts a
          WHERE a.target_type = 'stock'
          ORDER BY a.target_id, a.triggered_at DESC
        )
        SELECT
          wi.id::text AS watchlist_item_id,
          s.id::text AS stock_id,
          s.ticker,
          s.name,
          s.market,
          la.severity
        FROM watchlist_items wi
        JOIN stocks s
          ON wi.target_type = 'stock'
         AND wi.target_id = s.id
        LEFT JOIN latest_alert la ON la.target_id = wi.target_id
        ORDER BY wi.created_at DESC, wi.id DESC
        """
    ).fetchall()

    return {
        "generated_at": generated_at,
        "keywords": keyword_items,
        "stocks": stock_items,
    }


def mutate_watchlist(
    conn: psycopg.Connection,
    *,
    op: str,
    target_type: str,
    target_id: str,
) -> dict[str, Any]:
    target_uuid = _parse_uuid(target_id, field="target_id")

    if target_type == "keyword":
        exists = conn.execute(
            "SELECT 1 FROM keywords WHERE id = %s",
            (target_uuid,),
        ).fetchone()
    elif target_type == "stock":
        exists = conn.execute(
            "SELECT 1 FROM stocks WHERE id = %s",
            (target_uuid,),
        ).fetchone()
    else:
        raise APIError(
            status_code=400,
            code="invalid_argument",
            message="target_type must be one of keyword,stock",
            details={"field": "target_type"},
        )

    if not exists:
        raise APIError(
            status_code=404,
            code="not_found",
            message="target not found",
            details={"target_type": target_type, "target_id": target_id},
        )

    if op == "add":
        with conn.transaction():
            row = conn.execute(
                """
                INSERT INTO watchlist_items (target_type, target_id)
                VALUES (%s, %s)
                ON CONFLICT (target_type, target_id) DO NOTHING
                RETURNING id
                """,
                (target_type, target_uuid),
            ).fetchone()

            if row:
                watchlist_item_id = row["id"]
            else:
                existing = conn.execute(
                    """
                    SELECT id
                    FROM watchlist_items
                    WHERE target_type = %s AND target_id = %s
                    """,
                    (target_type, target_uuid),
                ).fetchone()
                watchlist_item_id = existing["id"]

            conn.execute(
                """
                INSERT INTO watchlist_alert_rules (watchlist_item_id)
                VALUES (%s)
                ON CONFLICT (watchlist_item_id) DO NOTHING
                """,
                (watchlist_item_id,),
            )

        return {
            "ok": True,
            "watchlist_item_id": str(watchlist_item_id),
        }

    if op == "remove":
        with conn.transaction():
            conn.execute(
                """
                DELETE FROM watchlist_items
                WHERE target_type = %s AND target_id = %s
                """,
                (target_type, target_uuid),
            )
        return {
            "ok": True,
            "watchlist_item_id": None,
        }

    raise APIError(
        status_code=400,
        code="invalid_argument",
        message="op must be one of add,remove",
        details={"field": "op"},
    )


def list_alerts(
    conn: psycopg.Connection,
    *,
    severity: str | None,
    limit: int,
    cursor: str | None,
) -> dict[str, Any]:
    offset = parse_cursor(cursor)

    rows = conn.execute(
        """
        SELECT
          a.id::text AS alert_id,
          a.target_type,
          a.target_id::text AS target_id,
          COALESCE(
            k.canonical_name,
            CASE
              WHEN s.ticker IS NULL THEN a.target_id::text
              ELSE s.ticker || ' | ' || s.name
            END
          ) AS target_label,
          a.severity,
          a.message,
          a.triggered_at,
          a.keyword_id::text AS keyword_id
        FROM alerts a
        LEFT JOIN keywords k
          ON a.target_type = 'keyword'
         AND k.id = a.target_id
        LEFT JOIN stocks s
          ON a.target_type = 'stock'
         AND s.id = a.target_id
        WHERE (%(severity)s::text IS NULL OR a.severity = %(severity)s::text)
        ORDER BY a.triggered_at DESC, a.id DESC
        LIMIT %(limit_plus_one)s OFFSET %(offset)s
        """,
        {
            "severity": severity,
            "limit_plus_one": limit + 1,
            "offset": offset,
        },
    ).fetchall()

    generated_at = _fetch_generated_at(
        conn,
        "SELECT MAX(triggered_at) AS generated_at FROM alerts",
    )

    next_cursor = _next_cursor(offset, limit, len(rows))
    items = rows[:limit]

    return {
        "generated_at": generated_at,
        "items": items,
        "next_cursor": next_cursor,
    }


def _parse_uuid(value: str, *, field: str) -> UUID:
    try:
        return UUID(value)
    except ValueError as exc:
        raise APIError(
            status_code=400,
            code="invalid_argument",
            message=f"{field} must be a UUID string",
            details={"field": field},
        ) from exc

