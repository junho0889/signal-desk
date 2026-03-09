# Screen Map

## Scope
Frozen map for production-polish mobile implementation:
- Home
- Keyword Ranking
- Keyword Detail
- Watchlist
- Alerts
- shared Loading/Error/Stale/Retry behavior

## Shared Layout Rules
- horizontal padding: `16dp`
- section gap: `16dp`
- card padding: `12dp`
- minimum touch target: `44dp`
- row gap: `8dp`
- fixed zone order:
  - `Z0` context rail (generated time + freshness)
  - `Z1` hero/header
  - `Z2` trust/freshness summary
  - `Z3` chart or trend entry
  - `Z4` evidence or list body
  - `Z5` primary actions

## Breakpoint Rules
- `BP-compact` (`320-360dp`):
  - keep two-column cards only when each card remains `>= 148dp`
  - otherwise stack to one column
- `BP-standard` (`361-412dp`):
  - default two-column trust/freshness layout allowed
- `BP-wide` (`413dp+`):
  - keep same information order; only increase whitespace, not slot order

Text-fit rules at all breakpoints:
- keyword/sector/source labels: `maxLines=1`
- alert message and reason summary: `maxLines=2`
- use ellipsis for overflow; no clipping

## Home

API mapping:
- `GET /dashboard.generated_at` -> `Z0`
- `top_keywords[]` -> `Z1` + `Z2`
- top-keyword evidence preview:
  - v1 fallback: `GET /keywords/{keyword_id}.related_news[0]`
  - additive target: compact evidence block on dashboard payload
- `hot_sectors[]` -> `Z3`
- `risk_alerts[]` -> `Z4`

Layout blueprint:
- `Z0`: sticky freshness rail
- `Z1`: top-keyword hero list (top 3)
- `Z2`: trust and risk strip for hero items
- `Z3`: sector movers list + chart entry hint
- `Z4`: `EV1` evidence preview row directly under each visible hero keyword
- `Z5`: recent alerts list then primary action (`View full ranking`)

Concrete zone mapping example (Home first hero):
1. `Z1`: `AI Infrastructure` hero movement card
2. `Z2`: trust and freshness chips
3. `Z4`: `EV1` (`Ked Global | kedglobal.com | 12m ago` + headline + `Open source`)
4. `Z5`: primary action (`View full ranking`)

Action contract:
- primary: navigate to ranking from `Z5`
- secondary: tap keyword card to detail, or tap `EV1` `Open source`

## Keyword Ranking

API mapping:
- `GET /keywords.generated_at` -> `Z0`
- `GET /keywords.items[]` -> `Z4`
- `GET /keywords.next_cursor` -> pagination zone

Layout blueprint:
- `Z0`: sticky generated-time + freshness rail
- under `Z0`: sticky filter strip (`period`, `market`, `sector`)
- `Z4`: fixed-order ranking rows (`min-height: 104dp`)
  1. rank + keyword
  2. movement (`score`, `delta_1d`) + CE1 sparkline
  3. trust/freshness cue
  4. compact evidence cue (`publisher/time` from `EV1`) + link icon

Action contract:
- primary: full-row tap -> keyword detail
- secondary: sticky filter controls
- chart entry: tapping CE1 opens detail anchored to `Z3` chart block

## Keyword Detail

API mapping:
- `GET /keywords/{keyword_id}.generated_at` -> `Z0`
- `score_summary` -> `Z1` + `Z2` + CE3 inputs
- `timeseries[]` -> `Z3` CE2 chart
- `reason_block`, `risk_flags`, `related_news[]` -> `Z4`
- additive target in `Z4`: evidence list fields (`publisher_name`, `publisher_domain`, `canonical_url`, `summary_text` or `excerpt_text`, `published_at`, `outbound_links[]`)
- `POST /watchlist` -> `Z5`

Layout blueprint:
- `Z0`: context rail (freshness age + source status)
- `Z1`: keyword header + movement card
- `Z2`: trust/freshness cards (2-col on standard/wide, 1-col on compact)
- `Z3`: contradiction card (conditional) + CE2 trend chart
- `Z4`: contribution entry + reason summary + `EV2` evidence list (latest first)
- `Z5`: watchlist primary action (top fold trailing + sticky bottom)

Concrete zone mapping example (Detail top evidence row):
1. `Z4` row header: `Reuters | reuters.com | 2026-03-09 08:12 (18m ago)`
2. `Z4` row body: headline (2 lines) + summary (up to 3 lines)
3. `Z4` row actions: `Open source` + `View references (3)` when available

Action contract:
- primary: `Add/Remove Watchlist` always visible in top fold and sticky bottom
- secondary: contradiction jump link to evidence block
- evidence link action: `Open source` from each `EV2` row

## Watchlist

API mapping:
- `GET /watchlist.generated_at` -> `Z0`
- `keywords[]` and `stocks[]` -> `Z4`

Layout blueprint:
- `Z0`: freshness rail
- `Z1`: segmented control (`Keywords`, `Stocks`)
- `Z2`: severity summary strip (`critical/high/medium/low`)
- `Z4`: rows grouped by severity desc, each row includes:
  - label
  - movement or market cue
  - risk/eligibility cue
  - trailing manage action
- `Z5`: optional bulk-manage action slot

Action contract:
- primary: row tap to detail (keywords) or linked keyword detail (stocks when available)
- secondary: trailing remove/manage control

## Alerts

API mapping:
- `GET /alerts.generated_at` -> `Z0`
- `GET /alerts.items[]` -> `Z4`
- `GET /alerts.next_cursor` -> pagination

Layout blueprint:
- `Z0`: freshness rail
- `Z1`: severity filter strip (sticky chips/dropdown)
- `Z4`: alert cards sorted by trigger time desc:
  - severity badge
  - message (2-line clamp)
  - target metadata
  - trigger timestamp (human-readable relative + absolute secondary)
- `Z5`: quick action row (`Open detail`, optional `Mark reviewed`)

Action contract:
- primary: alert row tap opens target detail when resolvable
- secondary: quick filter and review actions

## Shared State Behavior

### Loading
- skeleton geometry must match final card/list geometry
- evidence skeleton must include publisher/time line, headline block, and action strip placeholders

### Error
- summary and retry in one card
- retry control must meet `44x44dp` minimum
- evidence-list error remains in `Z4` and does not replace `Z1-Z3`

### Stale
- stale age appears in `Z0`
- interpretation note appears in `Z2` or top-of-list context
- evidence stale cue appears inside each evidence row time slot

## Mobile Acceptance Checks
- hierarchy:
  - each screen has one clear primary action visible without deep scroll
- readability:
  - score, delta, trust, and risk are scannable in under 3 seconds
- spacing:
  - shared padding and gaps follow token rules with no ad hoc exceptions
- button placement:
  - primary action position is consistent per screen blueprint
- Korean text fit:
  - no clipping with long Korean strings in title, reason, or alert message fields
- chart clarity:
  - CE1 and CE2 render with title, start/end value context, and non-color-only differentiation
- evidence placement:
  - Home and Detail both render visible evidence entry surfaces without opening a secondary tab
- link affordance:
  - source link action is visible, labeled, and reachable in one tap on every evidence row

## Trust Visibility Rules
- trust state remains visible in ranking rows, detail top fold, watchlist rows, and alerts metadata
- contradiction cannot be hidden behind secondary tabs
- trust and contradiction cues use icon + label, not color only
