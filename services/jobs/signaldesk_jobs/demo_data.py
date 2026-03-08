from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any

import psycopg

KEYWORDS = [
    {
        "id": "00000000-0000-0000-0000-000000000101",
        "canonical_name": "AI Infrastructure",
        "market_scope": "us",
        "sector_hint": "Semiconductors",
    },
    {
        "id": "00000000-0000-0000-0000-000000000102",
        "canonical_name": "Battery Supply Chain",
        "market_scope": "all",
        "sector_hint": "Energy Storage",
    },
    {
        "id": "00000000-0000-0000-0000-000000000103",
        "canonical_name": "Robotics Automation",
        "market_scope": "kr",
        "sector_hint": "Industrial Automation",
    },
]

STOCKS = [
    {
        "id": "00000000-0000-0000-0000-000000000201",
        "ticker": "NVDA",
        "name": "NVIDIA",
        "market": "us",
        "sector": "Semiconductors",
    },
    {
        "id": "00000000-0000-0000-0000-000000000202",
        "ticker": "TSLA",
        "name": "Tesla",
        "market": "us",
        "sector": "Automotive",
    },
    {
        "id": "00000000-0000-0000-0000-000000000203",
        "ticker": "005930",
        "name": "Samsung Electronics",
        "market": "kr",
        "sector": "Semiconductors",
    },
]


def _upsert_keywords(conn: psycopg.Connection) -> int:
    for keyword in KEYWORDS:
        conn.execute(
            """
            INSERT INTO keywords (id, canonical_name, market_scope, sector_hint)
            VALUES (%(id)s::uuid, %(canonical_name)s, %(market_scope)s, %(sector_hint)s)
            ON CONFLICT (id) DO UPDATE
            SET canonical_name = EXCLUDED.canonical_name,
                market_scope = EXCLUDED.market_scope,
                sector_hint = EXCLUDED.sector_hint
            """,
            keyword,
        )
    return len(KEYWORDS)


def _upsert_snapshots(conn: psycopg.Connection) -> int:
    now_hour = datetime.now(timezone.utc).replace(minute=0, second=0, microsecond=0)
    prev_hour = now_hour - timedelta(hours=1)

    snapshots: list[dict[str, Any]] = [
        {
            "keyword_id": KEYWORDS[0]["id"],
            "as_of_ts": prev_hour,
            "score_total": 78.20,
            "score_delta_24h": 2.90,
            "confidence": 0.760,
            "rank_position": 1,
            "dimension_mentions": 83.00,
            "dimension_trends": 76.00,
            "dimension_market": 73.00,
            "dimension_events": 68.00,
            "dimension_persistence": 70.00,
            "is_alert_eligible": True,
            "reason_tags": ["mentions_accelerating", "price_volume_confirmation"],
            "risk_flags": [],
        },
        {
            "keyword_id": KEYWORDS[0]["id"],
            "as_of_ts": now_hour,
            "score_total": 82.40,
            "score_delta_24h": 5.20,
            "confidence": 0.810,
            "rank_position": 1,
            "dimension_mentions": 88.00,
            "dimension_trends": 79.00,
            "dimension_market": 76.00,
            "dimension_events": 65.00,
            "dimension_persistence": 71.00,
            "is_alert_eligible": True,
            "reason_tags": ["mentions_accelerating", "search_confirmation", "price_volume_confirmation"],
            "risk_flags": [],
        },
        {
            "keyword_id": KEYWORDS[1]["id"],
            "as_of_ts": prev_hour,
            "score_total": 72.10,
            "score_delta_24h": 1.20,
            "confidence": 0.640,
            "rank_position": 2,
            "dimension_mentions": 70.00,
            "dimension_trends": 67.00,
            "dimension_market": 71.00,
            "dimension_events": 60.00,
            "dimension_persistence": 69.00,
            "is_alert_eligible": False,
            "reason_tags": ["persistent_multi_window"],
            "risk_flags": ["event_coverage_partial"],
        },
        {
            "keyword_id": KEYWORDS[1]["id"],
            "as_of_ts": now_hour,
            "score_total": 73.60,
            "score_delta_24h": -1.40,
            "confidence": 0.670,
            "rank_position": 2,
            "dimension_mentions": 72.00,
            "dimension_trends": 68.00,
            "dimension_market": 70.00,
            "dimension_events": 59.00,
            "dimension_persistence": 72.00,
            "is_alert_eligible": False,
            "reason_tags": ["persistent_multi_window"],
            "risk_flags": ["event_coverage_partial"],
        },
        {
            "keyword_id": KEYWORDS[2]["id"],
            "as_of_ts": prev_hour,
            "score_total": 66.40,
            "score_delta_24h": 0.80,
            "confidence": 0.620,
            "rank_position": 3,
            "dimension_mentions": 62.00,
            "dimension_trends": 64.00,
            "dimension_market": 63.00,
            "dimension_events": 58.00,
            "dimension_persistence": 67.00,
            "is_alert_eligible": False,
            "reason_tags": ["persistent_multi_window"],
            "risk_flags": [],
        },
        {
            "keyword_id": KEYWORDS[2]["id"],
            "as_of_ts": now_hour,
            "score_total": 68.90,
            "score_delta_24h": 2.10,
            "confidence": 0.650,
            "rank_position": 3,
            "dimension_mentions": 66.00,
            "dimension_trends": 65.00,
            "dimension_market": 64.00,
            "dimension_events": 60.00,
            "dimension_persistence": 68.00,
            "is_alert_eligible": True,
            "reason_tags": ["mentions_accelerating", "persistent_multi_window"],
            "risk_flags": [],
        },
    ]

    for snapshot in snapshots:
        conn.execute(
            """
            INSERT INTO keyword_snapshots (
              keyword_id,
              as_of_ts,
              score_total,
              score_delta_24h,
              confidence,
              rank_position,
              dimension_mentions,
              dimension_trends,
              dimension_market,
              dimension_events,
              dimension_persistence,
              is_alert_eligible,
              reason_tags,
              risk_flags
            )
            VALUES (
              %(keyword_id)s::uuid,
              %(as_of_ts)s,
              %(score_total)s,
              %(score_delta_24h)s,
              %(confidence)s,
              %(rank_position)s,
              %(dimension_mentions)s,
              %(dimension_trends)s,
              %(dimension_market)s,
              %(dimension_events)s,
              %(dimension_persistence)s,
              %(is_alert_eligible)s,
              %(reason_tags)s,
              %(risk_flags)s
            )
            ON CONFLICT (keyword_id, as_of_ts) DO UPDATE
            SET
              score_total = EXCLUDED.score_total,
              score_delta_24h = EXCLUDED.score_delta_24h,
              confidence = EXCLUDED.confidence,
              rank_position = EXCLUDED.rank_position,
              dimension_mentions = EXCLUDED.dimension_mentions,
              dimension_trends = EXCLUDED.dimension_trends,
              dimension_market = EXCLUDED.dimension_market,
              dimension_events = EXCLUDED.dimension_events,
              dimension_persistence = EXCLUDED.dimension_persistence,
              is_alert_eligible = EXCLUDED.is_alert_eligible,
              reason_tags = EXCLUDED.reason_tags,
              risk_flags = EXCLUDED.risk_flags
            """,
            snapshot,
        )

    return len(snapshots)


def _upsert_reference_data(conn: psycopg.Connection) -> dict[str, int]:
    sector_links = [
        {"keyword_id": KEYWORDS[0]["id"], "sector": "Semiconductors", "link_confidence": 0.920},
        {"keyword_id": KEYWORDS[0]["id"], "sector": "Cloud", "link_confidence": 0.810},
        {"keyword_id": KEYWORDS[1]["id"], "sector": "Energy Storage", "link_confidence": 0.860},
        {"keyword_id": KEYWORDS[2]["id"], "sector": "Industrial Automation", "link_confidence": 0.770},
    ]

    for stock in STOCKS:
        conn.execute(
            """
            INSERT INTO stocks (id, ticker, name, market, sector)
            VALUES (%(id)s::uuid, %(ticker)s, %(name)s, %(market)s, %(sector)s)
            ON CONFLICT (id) DO UPDATE
            SET ticker = EXCLUDED.ticker,
                name = EXCLUDED.name,
                market = EXCLUDED.market,
                sector = EXCLUDED.sector
            """,
            stock,
        )

    stock_links = [
        {"keyword_id": KEYWORDS[0]["id"], "stock_id": STOCKS[0]["id"], "link_confidence": 0.930},
        {"keyword_id": KEYWORDS[1]["id"], "stock_id": STOCKS[1]["id"], "link_confidence": 0.720},
        {"keyword_id": KEYWORDS[0]["id"], "stock_id": STOCKS[2]["id"], "link_confidence": 0.660},
        {"keyword_id": KEYWORDS[2]["id"], "stock_id": STOCKS[2]["id"], "link_confidence": 0.780},
    ]

    for link in sector_links:
        conn.execute(
            """
            INSERT INTO keyword_sector_links (keyword_id, sector, link_confidence)
            VALUES (%(keyword_id)s::uuid, %(sector)s, %(link_confidence)s)
            ON CONFLICT (keyword_id, sector) DO UPDATE
            SET link_confidence = EXCLUDED.link_confidence
            """,
            link,
        )

    for link in stock_links:
        conn.execute(
            """
            INSERT INTO keyword_stock_links (keyword_id, stock_id, link_confidence)
            VALUES (%(keyword_id)s::uuid, %(stock_id)s::uuid, %(link_confidence)s)
            ON CONFLICT (keyword_id, stock_id) DO UPDATE
            SET link_confidence = EXCLUDED.link_confidence
            """,
            link,
        )

    news_items = [
        {
            "id": "00000000-0000-0000-0000-000000000301",
            "source_name": "MarketWire",
            "published_at": datetime.now(timezone.utc).replace(minute=5, second=0, microsecond=0),
            "title": "AI infrastructure demand strengthens in latest enterprise cycle",
            "url": "https://example.com/news/ai-infra-demand",
            "normalized_hash": "hash-ai-infra-demand-v1",
        },
        {
            "id": "00000000-0000-0000-0000-000000000302",
            "source_name": "EnergyWatch",
            "published_at": datetime.now(timezone.utc).replace(minute=15, second=0, microsecond=0),
            "title": "Battery supply chain volatility persists despite demand rebound",
            "url": "https://example.com/news/battery-supply-volatility",
            "normalized_hash": "hash-battery-volatility-v1",
        },
    ]

    for item in news_items:
        conn.execute(
            """
            INSERT INTO news_items (id, source_name, published_at, title, url, normalized_hash)
            VALUES (%(id)s::uuid, %(source_name)s, %(published_at)s, %(title)s, %(url)s, %(normalized_hash)s)
            ON CONFLICT (id) DO UPDATE
            SET source_name = EXCLUDED.source_name,
                published_at = EXCLUDED.published_at,
                title = EXCLUDED.title,
                url = EXCLUDED.url,
                normalized_hash = EXCLUDED.normalized_hash
            """,
            item,
        )

    news_links = [
        {"keyword_id": KEYWORDS[0]["id"], "news_item_id": news_items[0]["id"], "relevance_score": 0.84},
        {"keyword_id": KEYWORDS[1]["id"], "news_item_id": news_items[1]["id"], "relevance_score": 0.71},
    ]

    for link in news_links:
        conn.execute(
            """
            INSERT INTO keyword_news_links (keyword_id, news_item_id, relevance_score)
            VALUES (%(keyword_id)s::uuid, %(news_item_id)s::uuid, %(relevance_score)s)
            ON CONFLICT (keyword_id, news_item_id) DO UPDATE
            SET relevance_score = EXCLUDED.relevance_score
            """,
            link,
        )

    return {
        "stocks": len(STOCKS),
        "sector_links": len(sector_links),
        "stock_links": len(stock_links),
        "news_items": len(news_items),
        "news_links": len(news_links),
    }


def _upsert_watchlist_baseline(conn: psycopg.Connection) -> int:
    watch_targets = [
        {"target_type": "keyword", "target_id": KEYWORDS[0]["id"]},
        {"target_type": "stock", "target_id": STOCKS[0]["id"]},
    ]

    count = 0
    for target in watch_targets:
        row = conn.execute(
            """
            INSERT INTO watchlist_items (target_type, target_id)
            VALUES (%(target_type)s, %(target_id)s::uuid)
            ON CONFLICT (target_type, target_id) DO UPDATE
            SET target_type = EXCLUDED.target_type
            RETURNING id
            """,
            target,
        ).fetchone()

        watchlist_item_id = row["id"]
        conn.execute(
            """
            INSERT INTO watchlist_alert_rules (watchlist_item_id, is_enabled, min_severity, cooldown_minutes)
            VALUES (%s, true, 'medium', 60)
            ON CONFLICT (watchlist_item_id) DO UPDATE
            SET is_enabled = EXCLUDED.is_enabled,
                min_severity = EXCLUDED.min_severity,
                cooldown_minutes = EXCLUDED.cooldown_minutes,
                updated_at = now()
            """,
            (watchlist_item_id,),
        )
        count += 1

    return count


def seed_demo_data(conn: psycopg.Connection) -> dict[str, Any]:
    with conn.transaction():
        keyword_count = _upsert_keywords(conn)
        snapshot_count = _upsert_snapshots(conn)
        ref_counts = _upsert_reference_data(conn)
        watchlist_count = _upsert_watchlist_baseline(conn)

    return {
        "keywords": keyword_count,
        "snapshots": snapshot_count,
        "watchlist_items": watchlist_count,
        **ref_counts,
    }
