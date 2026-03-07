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
- `reason_tags` (`string[]`, non-null, may be empty)

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
- `score` (`number`, non-null)
- `delta_1d` (`number`, nullable)
- `confidence` (`number`, non-null)
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
- `mention_velocity` (`number`, nullable)
- `trend_velocity` (`number`, nullable)
- `market_reaction` (`number`, nullable)
- `event_weight` (`number`, nullable)
- `persistence` (`number`, nullable)

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
- keyword detail: `reason_block`, `score_summary.delta_1d`, all score component fields in `score_summary` except `score` and `confidence`, `related_news[].relevance_score`, `related_stocks[].sector`, `related_stocks[].link_confidence`
- watchlist: `keywords[].score`, `keywords[].delta_1d`, `keywords[].severity`, `stocks[].severity`, `POST /watchlist` response `watchlist_item_id`
- alerts: `next_cursor`, `items[].keyword_id`

## DATA-001 Assumptions Locked For BE-001
- scoring dimensions and formula remain as documented in `docs/data/keyword-scoring-v0.md`
- `score` and `confidence` remain numeric scalar values
- `reason_tags`, `risk_flags`, and sector labels are delivered as string arrays until taxonomy tables are introduced

## Compatibility Rules
- additive fields are allowed
- existing field names and enum literals are frozen in `v1`
- removing or renaming fields requires `v2`
