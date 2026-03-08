# Screen Map

## Purpose
Define mobile-first screen zones and data mapping so implementation can apply the analytics visual system consistently.

## Shared Mobile Zone Model
- `Z0 Context Rail`: generated time, market/period scope, and global freshness hint
- `Z1 Signal Header`: keyword or target identity with rank/movement summary
- `Z2 Trust and Risk Strip`: trust ladder, freshness state, contradiction/risk chips
- `Z3 Primary Analytics`: one chart or stat block that explains movement quickly
- `Z4 Evidence Stack`: reason tags, evidence timeline, related entities
- `Z5 Actions`: watchlist mutation and navigation actions

Rule: all primary screens keep `Z1` through `Z3` above the first major scroll break.

## Home
Purpose: fast first-pass triage after app open.

API mapping:
- `GET /dashboard.generated_at` -> `Z0 Context Rail`
- `GET /dashboard.top_keywords[]` -> top keyword cards (`Z1`/`Z2`/`Z3` compact)
- `GET /dashboard.hot_sectors[]` -> sector movers module
- `GET /dashboard.risk_alerts[]` -> alert summary queue

Zone layout:
- `Z0`: last update timestamp and freshness chip
- `Z1`: top keyword label + score/delta cluster
- `Z2`: confidence/trust micro-badge + risk chips
- `Z3`: compact momentum micro-line (C1 fallback)
- `Z4`: sector movers and alert summary list
- `Z5`: navigation shortcuts to Ranking, Watchlist, Alerts

Interaction:
- tap top keyword card -> Keyword Detail (`keyword_id` route)
- tap alert row -> Alerts list or direct Keyword Detail when `keyword_id` exists

## Keyword Ranking
Purpose: sortable and filterable ranking exploration.

API mapping:
- `GET /keywords.generated_at` -> `Z0`
- `GET /keywords.items[]` -> ranking rows
- `GET /keywords.next_cursor` -> infinite pagination footer
- query controls: `period` (required), `market`, `sector`, `limit`, `cursor`

Zone layout:
- `Z0`: sticky generated time + filter scope chip
- sticky filter bar (period/market/sector)
- row composition (fixed order):
  1) `Z1`: `rank_position`, `keyword`
  2) `Z2`: trust ladder micro-badge from `confidence` + `risk_flags`
  3) `Z3`: movement mini card (`score`, `delta_1d`) + C1 micro-line
  4) `Z4`: `reason_tags`, `related_sectors`, contradiction/risk chips
  5) right edge freshness micro-label from list generation age

Interaction:
- tap row -> Keyword Detail
- filter change resets cursor and reloads first page
- long lists must preserve stable row height and field order

## Keyword Detail
Purpose: explain why a keyword moved and whether follow-up is warranted.

API mapping:
- `GET /keywords/{keyword_id}.generated_at` -> `Z0`
- `score_summary` -> movement and trust cards (S1, S2)
- `timeseries[]` -> C2 twin-line chart
- `reason_block`, `risk_flags` -> contradiction/trust explanation
- `related_stocks[]`, `related_sectors[]` -> C6 relationship pulse matrix
- watchlist mutation -> `POST /watchlist`

Zone layout:
- `Z0`: generated time + freshness band
- `Z1`: keyword title, rank context (if navigated from ranking), movement card S1
- `Z2`: trust card S2 + freshness card S3 side-by-side
- `Z3`: contradiction card S4 (conditional) + C2 twin-line chart
- `Z4`: C3 dimension contribution bars, reason block, relationship matrix
- `Z5`: add/remove watchlist action

Interaction:
- watchlist action remains visible near top and in sticky footer variant after deep scroll
- contradiction card tap opens Evidence view with contradiction filter applied

## Keyword Detail - Evidence View
Purpose: deep review of evidence depth, freshness, and contradiction.

API mapping:
- `related_news[]` -> event timeline rows and source groups
- `risk_flags` -> contradiction and stale-source warnings
- `generated_at` + latest `published_at` -> freshness state
- `related_stocks[]` + `related_sectors[]` -> context chips

Zone layout:
- `Z1`: evidence headline and freshness summary
- `Z2`: trust/freshness/contradiction strip
- `Z3`: C4 source mix ribbon
- `Z4`: C5 event timeline ladder + grouped evidence list
- `Z5`: deep links to external sources (read-only)

Interaction:
- default sort newest first
- contradiction-flagged evidence stays pinned at top within source group
- source links open external browser and return to same scroll position

## Watchlist
Purpose: focused follow-up queue for tracked keywords and stocks.

API mapping:
- `GET /watchlist.generated_at` -> `Z0`
- `GET /watchlist.keywords[]`, `stocks[]` -> row lists
- `POST /watchlist` -> row mutation

Zone layout:
- `Z0`: generated time and freshness chip
- `Z1`: segmented tabs (Keywords / Stocks)
- `Z2`: per-row trust/risk strip (`is_alert_eligible`, `risk_flags`, `severity`)
- `Z3`: movement mini card for keyword rows
- `Z4`: concise reason/risk label cluster and empty-state routes
- `Z5`: add/remove actions (keyword detail and row-level gestures)

Interaction:
- keyword row tap -> Keyword Detail
- stock row tap -> stock-linked keyword detail when available, else stock context placeholder

## Alerts
Purpose: review triggered events and route quickly to context.

API mapping:
- `GET /alerts.generated_at` -> `Z0`
- `GET /alerts.items[]` -> alert feed
- `GET /alerts.next_cursor` -> pagination
- query control: `severity`

Zone layout:
- `Z0`: generated time + freshness state
- `Z1`: severity filter chips
- `Z2`: per-row severity and trust/risk indicator
- `Z3`: alert message with target label and triggered time
- `Z4`: contradiction marker when linked keyword currently has risk flags
- `Z5`: route-to-detail affordance

Interaction:
- alert row tap -> Keyword Detail when `keyword_id` exists
- severity filter preserves scroll position when possible

## Cross-Screen Rules
- Home -> Detail within 2 taps
- Ranking, Watchlist, Alerts -> Detail within 1 tap when keyword context exists
- trust/freshness surfaces are always visible above fold on Ranking rows and Detail top fold
- contradiction visibility cannot be hidden behind optional tabs when active

## Mobile Density Rules
- no horizontal scrolling for primary analytics blocks
- top fold must show movement + trust + freshness together before evidence list
- use fixed row template for list screens to reduce scan variance
- each row supports truncation with stable baseline height rather than variable expansion by default

## Out of Scope Screen Behavior (Release-1)
- no portfolio analytics, broker actions, or order-entry UI
- no social feeds, shared lists, or copy-trading UI
- no conversational assistant panels
- no client-side recalculation of ranking or trust model outputs
