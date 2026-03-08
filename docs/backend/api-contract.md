# API Contract

## Version
- contract version: `v1`
- status: frozen for BE-001 (additive changes only)

## Common Rules
- base path: `/v1`
- content type: `application/json; charset=utf-8`
- timestamps: RFC 3339 UTC (`YYYY-MM-DDTHH:MM:SSZ`)
- market enum: `kr|us|all`
- period enum: `intraday|daily|weekly`
- default sort for rankings: `score DESC`
- default page size for list endpoints: `20`
- max page size for list endpoints: `100`
- canonical `risk_flags` literals: `data_freshness_degraded|event_coverage_partial|mapping_unstable|thin_cohort`
- canonical `reason_tags` literals: `mentions_accelerating|search_confirmation|price_volume_confirmation|disclosure_backed|persistent_multi_window|low_source_diversity|stale_input_risk|weak_market_confirmation`

API field aliases for mobile readability:
- `score` maps to DATA `score_total`
- `delta_1d` maps to DATA `score_delta_24h`

## Error Shape
All non-2xx responses use:
- `error.code`: stable machine-readable code
- `error.message`: user-safe summary
- `error.details`: nullable object for validation fields
- `request_id`: nullable trace id

Example:
```json
{
  "error": {
    "code": "invalid_argument",
    "message": "period must be one of intraday,daily,weekly",
    "details": { "field": "period" }
  },
  "request_id": null
}
```

## Endpoints

### `GET /dashboard`
Return Home screen payload.

Response fields:
- `generated_at` (`string`, non-null): UTC generation timestamp
- `top_keywords` (`array`, non-null): up to 10 keyword cards
- `hot_sectors` (`array`, non-null): up to 10 sector cards
- `risk_alerts` (`array`, non-null): up to 10 recent high-priority alerts

`top_keywords[]`:
- `keyword_id` (`string`, non-null)
- `keyword` (`string`, non-null)
- `score` (`number`, non-null)
- `delta_1d` (`number`, nullable)
- `confidence` (`number`, non-null)
- `is_alert_eligible` (`boolean`, non-null)
- `reason_tags` (`string[]`, non-null, may be empty)
- `risk_flags` (`string[]`, non-null, may be empty)

`hot_sectors[]`:
- `sector` (`string`, non-null)
- `keyword_count` (`integer`, non-null)
- `avg_score` (`number`, non-null)
- `delta_1d` (`number`, nullable)

`risk_alerts[]`:
- `alert_id` (`string`, non-null)
- `target_type` (`keyword|stock`, non-null)
- `target_id` (`string`, non-null)
- `severity` (`low|medium|high|critical`, non-null)
- `message` (`string`, non-null)
- `triggered_at` (`string`, non-null)

### `GET /keywords`
Return ranking list for Keyword Ranking screen.

Query params:
- `period` (`intraday|daily|weekly`, required)
- `market` (`kr|us|all`, default `all`)
- `sector` (`string`, nullable)
- `limit` (`integer`, default `20`, max `100`)
- `cursor` (`string`, nullable)

Response fields:
- `generated_at` (`string`, non-null)
- `items` (`array`, non-null)
- `next_cursor` (`string`, nullable)

`items[]`:
- `keyword_id` (`string`, non-null)
- `keyword` (`string`, non-null)
- `rank_position` (`integer`, non-null)
- `score` (`number`, non-null)
- `delta_1d` (`number`, nullable)
- `confidence` (`number`, non-null)
- `is_alert_eligible` (`boolean`, non-null)
- `reason_tags` (`string[]`, non-null, may be empty)
- `risk_flags` (`string[]`, non-null, may be empty)
- `related_sectors` (`string[]`, non-null, may be empty)

### `GET /keywords/{keyword_id}`
Return Keyword Detail screen payload.

Path params:
- `keyword_id` (`string`, required)

Query params:
- `period` (`intraday|daily|weekly`, default `daily`)
- `points` (`integer`, default `24`, max `240`)

Response fields:
- `generated_at` (`string`, non-null)
- `keyword_id` (`string`, non-null)
- `keyword` (`string`, non-null)
- `score_summary` (`object`, non-null)
- `reason_block` (`string`, nullable)
- `timeseries` (`array`, non-null)
- `related_news` (`array`, non-null)
- `related_stocks` (`array`, non-null)
- `related_sectors` (`string[]`, non-null, may be empty)
- `risk_flags` (`string[]`, non-null, may be empty)

`score_summary`:
- `score` (`number`, non-null)
- `delta_1d` (`number`, nullable)
- `confidence` (`number`, non-null)
- `is_alert_eligible` (`boolean`, non-null)
- `dimension_mentions` (`number`, nullable)
- `dimension_trends` (`number`, nullable)
- `dimension_market` (`number`, nullable)
- `dimension_events` (`number`, nullable)
- `dimension_persistence` (`number`, nullable)

`timeseries[]`:
- `snapshot_at` (`string`, non-null)
- `score` (`number`, non-null)
- `confidence` (`number`, non-null)

`related_news[]`:
- `news_id` (`string`, non-null)
- `source_name` (`string`, non-null)
- `published_at` (`string`, non-null)
- `title` (`string`, non-null)
- `url` (`string`, non-null)
- `relevance_score` (`number`, nullable)

`related_stocks[]`:
- `stock_id` (`string`, non-null)
- `ticker` (`string`, non-null)
- `name` (`string`, non-null)
- `market` (`kr|us`, non-null)
- `sector` (`string`, nullable)
- `link_confidence` (`number`, nullable)

### `GET /watchlist`
Return Watchlist screen payload.

Response fields:
- `generated_at` (`string`, non-null)
- `keywords` (`array`, non-null)
- `stocks` (`array`, non-null)

`keywords[]`:
- `watchlist_item_id` (`string`, non-null)
- `keyword_id` (`string`, non-null)
- `keyword` (`string`, non-null)
- `score` (`number`, nullable)
- `delta_1d` (`number`, nullable)
- `is_alert_eligible` (`boolean`, nullable)
- `risk_flags` (`string[]`, non-null, may be empty)
- `severity` (`low|medium|high|critical`, nullable)

`stocks[]`:
- `watchlist_item_id` (`string`, non-null)
- `stock_id` (`string`, non-null)
- `ticker` (`string`, non-null)
- `name` (`string`, non-null)
- `market` (`kr|us`, non-null)
- `severity` (`low|medium|high|critical`, nullable)

### `POST /watchlist`
Create or delete a watch target.

Request body:
- `op` (`add|remove`, non-null)
- `target_type` (`keyword|stock`, non-null)
- `target_id` (`string`, non-null)

Response fields:
- `ok` (`boolean`, non-null)
- `watchlist_item_id` (`string`, nullable)

### `GET /alerts`
Return Alerts screen payload.

Query params:
- `limit` (`integer`, default `20`, max `100`)
- `cursor` (`string`, nullable)
- `severity` (`low|medium|high|critical`, nullable)

Response fields:
- `generated_at` (`string`, non-null)
- `items` (`array`, non-null)
- `next_cursor` (`string`, nullable)

`items[]`:
- `alert_id` (`string`, non-null)
- `target_type` (`keyword|stock`, non-null)
- `target_id` (`string`, non-null)
- `target_label` (`string`, non-null)
- `severity` (`low|medium|high|critical`, non-null)
- `message` (`string`, non-null)
- `triggered_at` (`string`, non-null)
- `keyword_id` (`string`, nullable): present when alert is stock-linked to a keyword

## Nullable Field Summary
Explicit nullable fields in v1:
- dashboard: `top_keywords[].delta_1d`, `hot_sectors[].delta_1d`
- keywords list: `next_cursor`, `items[].delta_1d`
- keyword detail: `reason_block`, `score_summary.delta_1d`, all `score_summary.dimension_*` fields, `related_news[].relevance_score`, `related_stocks[].sector`, `related_stocks[].link_confidence`
- watchlist: `keywords[].score`, `keywords[].delta_1d`, `keywords[].is_alert_eligible`, `keywords[].severity`, `stocks[].severity`, `POST /watchlist` response `watchlist_item_id`
- alerts: `next_cursor`, `items[].keyword_id`

## DATA-001 Assumptions Locked For BE-001
- scoring snapshot uniqueness key is (`keyword_id`, `as_of_ts`)
- scoring precision follows DATA contract (`score_total`/`score_delta_24h`/`dimension_*` = `numeric(5,2)`, `confidence` = `numeric(4,3)`)
- `risk_flags` must remain within canonical literals declared in DATA docs
- `reason_tags` and `risk_flags` stay as array fields in DB/API payloads
- `is_alert_eligible` comes from server-side scoring/guardrail logic and is never computed on client

## Compatibility Rules
- additive fields are allowed
- existing field names and enum literals are frozen in `v1`
- removing or renaming fields requires `v2`
- alias semantics (`score`, `delta_1d`) are frozen for mobile compatibility in `v1`

## Internal Notification Payload
Watchlist alert evaluation can emit notification-ready payloads for downstream delivery adapters.
This is an internal backend contract, not a public mobile API endpoint.

Payload fields:
- `delivery_id` (`string`, non-null): stable per-channel identifier (`<alert_id>:push`)
- `channel` (`push`, non-null)
- `title` (`string`, non-null): formatted from notification title prefix + severity
- `body` (`string`, non-null): user-visible alert summary
- `route.name` (`keyword_detail|alerts`, non-null)
- `route.params.keyword_id` (`string`, nullable): keyword detail target when available
- `meta.alert_id` (`string`, non-null)
- `meta.target_type` (`keyword|stock`, non-null)
- `meta.target_id` (`string`, non-null)
- `meta.target_label` (`string`, non-null)
- `meta.keyword_id` (`string`, nullable)
- `meta.severity` (`low|medium|high|critical`, non-null)
- `meta.triggered_at` (`string`, non-null)

Example:
```json
{
  "delivery_id": "0c722c67-9186-4fa8-898f-4f0529a363f4:push",
  "channel": "push",
  "title": "SignalDesk | HIGH alert",
  "body": "AI Infrastructure moved +5.20 in 24h (score 82.40)",
  "route": {
    "name": "keyword_detail",
    "params": { "keyword_id": "00000000-0000-0000-0000-000000000101" }
  },
  "meta": {
    "alert_id": "0c722c67-9186-4fa8-898f-4f0529a363f4",
    "target_type": "keyword",
    "target_id": "00000000-0000-0000-0000-000000000101",
    "target_label": "AI Infrastructure",
    "keyword_id": "00000000-0000-0000-0000-000000000101",
    "severity": "high",
    "triggered_at": "2026-03-08T06:22:40Z"
  }
}
```
