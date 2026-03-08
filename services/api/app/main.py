from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from fastapi import FastAPI, Query
from pydantic import BaseModel

from .config import Settings, load_settings
from .db import get_connection
from .errors import APIError, register_error_handlers
from .repository import (
    get_dashboard,
    get_keyword_detail,
    get_watchlist,
    list_alerts,
    list_keywords,
    mutate_watchlist,
)

VALID_MARKETS = {"kr", "us", "all"}
VALID_PERIODS = {"intraday", "daily", "weekly"}
VALID_SEVERITIES = {"low", "medium", "high", "critical"}
VALID_TARGET_TYPES = {"keyword", "stock"}
VALID_OPS = {"add", "remove"}

settings: Settings = load_settings()
app = FastAPI(title="SignalDesk API", version="v1")
register_error_handlers(app)


class WatchlistMutationRequest(BaseModel):
    op: str
    target_type: str
    target_id: str


def _to_rfc3339(value: datetime) -> str:
    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def _serialize(payload: Any) -> Any:
    if isinstance(payload, datetime):
        return _to_rfc3339(payload)
    if isinstance(payload, list):
        return [_serialize(item) for item in payload]
    if isinstance(payload, dict):
        return {key: _serialize(value) for key, value in payload.items()}
    return payload


def _validate_period(period: str | None) -> str:
    if period is None:
        raise APIError(
            status_code=400,
            code="invalid_argument",
            message="period must be one of intraday,daily,weekly",
            details={"field": "period"},
        )
    if period not in VALID_PERIODS:
        raise APIError(
            status_code=400,
            code="invalid_argument",
            message="period must be one of intraday,daily,weekly",
            details={"field": "period"},
        )
    return period


def _validate_market(market: str) -> str:
    if market not in VALID_MARKETS:
        raise APIError(
            status_code=400,
            code="invalid_argument",
            message="market must be one of kr,us,all",
            details={"field": "market"},
        )
    return market


def _validate_limit(limit: int) -> int:
    if limit < 1 or limit > settings.max_limit:
        raise APIError(
            status_code=400,
            code="invalid_argument",
            message=f"limit must be between 1 and {settings.max_limit}",
            details={"field": "limit"},
        )
    return limit


def _validate_points(points: int) -> int:
    if points < 1 or points > 240:
        raise APIError(
            status_code=400,
            code="invalid_argument",
            message="points must be between 1 and 240",
            details={"field": "points"},
        )
    return points


@app.get("/healthz")
def healthz() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/v1/dashboard")
def dashboard() -> dict[str, Any]:
    with get_connection(settings) as conn:
        payload = get_dashboard(conn)
    return _serialize(payload)


@app.get("/v1/keywords")
def keywords(
    period: str | None = Query(default=None),
    market: str = Query(default="all"),
    sector: str | None = Query(default=None),
    limit: int = Query(default=settings.default_limit),
    cursor: str | None = Query(default=None),
) -> dict[str, Any]:
    checked_period = _validate_period(period)
    checked_market = _validate_market(market)
    checked_limit = _validate_limit(limit)

    with get_connection(settings) as conn:
        payload = list_keywords(
            conn,
            period=checked_period,
            market=checked_market,
            sector=sector,
            limit=checked_limit,
            cursor=cursor,
        )
    return _serialize(payload)


@app.get("/v1/keywords/{keyword_id}")
def keyword_detail(
    keyword_id: str,
    period: str = Query(default="daily"),
    points: int = Query(default=24),
) -> dict[str, Any]:
    checked_period = _validate_period(period)
    checked_points = _validate_points(points)

    with get_connection(settings) as conn:
        payload = get_keyword_detail(
            conn,
            keyword_id=keyword_id,
            period=checked_period,
            points=checked_points,
        )
    return _serialize(payload)


@app.get("/v1/watchlist")
def watchlist() -> dict[str, Any]:
    with get_connection(settings) as conn:
        payload = get_watchlist(conn)
    return _serialize(payload)


@app.post("/v1/watchlist")
def watchlist_mutation(body: WatchlistMutationRequest) -> dict[str, Any]:
    if body.op not in VALID_OPS:
        raise APIError(
            status_code=400,
            code="invalid_argument",
            message="op must be one of add,remove",
            details={"field": "op"},
        )
    if body.target_type not in VALID_TARGET_TYPES:
        raise APIError(
            status_code=400,
            code="invalid_argument",
            message="target_type must be one of keyword,stock",
            details={"field": "target_type"},
        )

    with get_connection(settings) as conn:
        payload = mutate_watchlist(
            conn,
            op=body.op,
            target_type=body.target_type,
            target_id=body.target_id,
        )
        conn.commit()
    return _serialize(payload)


@app.get("/v1/alerts")
def alerts(
    limit: int = Query(default=settings.default_limit),
    cursor: str | None = Query(default=None),
    severity: str | None = Query(default=None),
) -> dict[str, Any]:
    checked_limit = _validate_limit(limit)
    if severity is not None and severity not in VALID_SEVERITIES:
        raise APIError(
            status_code=400,
            code="invalid_argument",
            message="severity must be one of low,medium,high,critical",
            details={"field": "severity"},
        )

    with get_connection(settings) as conn:
        payload = list_alerts(
            conn,
            limit=checked_limit,
            cursor=cursor,
            severity=severity,
        )
    return _serialize(payload)
