# Screen Map

## Home
Purpose: fast first-pass triage after app open.

Primary blocks and API mapping:
- Top Keywords rail (`GET /dashboard` -> `top_keywords[]`): `keyword_id`, `keyword`, `score`, `delta_1d`, `confidence`, `is_alert_eligible`, `reason_tags`, `risk_flags`
- Sector Movers (`GET /dashboard` -> `hot_sectors[]`): `sector`, `keyword_count`, `avg_score`, `delta_1d`
- Alert Summary (`GET /dashboard` -> `risk_alerts[]`): `alert_id`, `target_type`, `target_id`, `severity`, `message`, `triggered_at`
- Quick navigation: Ranking, Watchlist, Alerts entry points

Interaction:
- tap keyword card -> Keyword Detail (`keyword_id` route)
- tap alert summary row -> Alerts list or target detail

## Keyword Ranking
Purpose: sortable/filterable ranking exploration.

API mapping:
- List data (`GET /keywords`): `items[]` with `rank_position`, `score`, `delta_1d`, `confidence`, `is_alert_eligible`, `reason_tags`, `risk_flags`, `related_sectors`
- Pagination (`GET /keywords`): `next_cursor`
- Query controls: `period` (required), `market`, `sector`, `limit`, `cursor`

UI structure:
- sticky filter bar: `period`, `market`, `sector`
- ranked list rows with fixed field order:
  1) rank + keyword
  2) score + delta
  3) confidence + alert eligibility
  4) reason tags + risk flags

Interaction:
- tap list row -> Keyword Detail
- filter change resets cursor and reloads from first page

## Keyword Detail
Purpose: explain why a keyword moved and whether follow-up is warranted.

API mapping:
- Header summary (`GET /keywords/{keyword_id}` -> `score_summary`): `score`, `delta_1d`, `confidence`, `is_alert_eligible`
- Dimension breakdown (`score_summary`): `dimension_mentions`, `dimension_trends`, `dimension_market`, `dimension_events`, `dimension_persistence`
- Explainability and risk: `reason_block`, top-level `risk_flags`
- Trend chart (`timeseries[]`): `snapshot_at`, `score`, `confidence`
- Evidence lists: `related_news[]`, `related_stocks[]`, `related_sectors[]`

Interaction:
- watchlist add/remove action (`POST /watchlist`) from header area
- deep links from related stocks/news remain read-only in MVP

## Watchlist
Purpose: focused follow-up queue for tracked keywords and stocks.

API mapping:
- Watchlist payload (`GET /watchlist`): `keywords[]`, `stocks[]`
- Keyword rows: `keyword`, `score`, `delta_1d`, `is_alert_eligible`, `risk_flags`, `severity`
- Stock rows: `ticker`, `name`, `market`, `severity`
- Mutation (`POST /watchlist`): add/remove by `target_type` + `target_id`

UI structure:
- segmented tabs: Keywords / Stocks
- per-row severity and risk emphasis
- empty-state prompts that route back to Ranking/Detail

## Alerts
Purpose: review triggered events and route quickly to context.

API mapping:
- Alerts feed (`GET /alerts`): `items[]`, `next_cursor`
- fields: `severity`, `message`, `triggered_at`, `target_type`, `target_id`, `target_label`, optional `keyword_id`
- controls: `severity`, `limit`, `cursor`

Interaction:
- severity filter chips on top
- tap alert row -> Keyword Detail (if keyword target or linked keyword exists)

## Cross-Screen Navigation Rules
- Home -> Detail: max 2 taps
- Ranking -> Detail: 1 tap
- Watchlist -> Detail: 1 tap for keyword rows
- Alerts -> Detail: 1 tap when keyword context exists

## Out-of-Scope Screen Behavior (Release-1)
- no order placement or broker account actions
- no social or shared watchlist flows
- no chat assistant panels
- no client-side alert rule editing beyond backend-supported toggles
