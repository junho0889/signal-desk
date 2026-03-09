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
- `hot_sectors[]` -> `Z3`
- `risk_alerts[]` -> `Z4`

Layout blueprint:
- `Z0`: sticky freshness rail
- `Z1`: top-keyword hero list (top 3)
- `Z2`: trust and risk strip for hero items
- `Z3`: sector movers list
- `Z4`: recent alerts list
- `Z5`: primary action (`View full ranking`)

Action contract:
- primary: navigate to ranking from `Z5`
- secondary: tap keyword card to detail

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
  4. evidence cue (`reason_tags`, related sector)

Action contract:
- primary: full-row tap -> keyword detail
- secondary: sticky filter controls

## Keyword Detail

API mapping:
- `GET /keywords/{keyword_id}.generated_at` -> `Z0`
- `score_summary` -> `Z1` + `Z2` + CE3 inputs
- `timeseries[]` -> `Z3` CE2 chart
- `reason_block`, `risk_flags` -> `Z4`
- `POST /watchlist` -> `Z5`

Layout blueprint:
- `Z0`: context rail (freshness age + source status)
- `Z1`: keyword header + movement card
- `Z2`: trust/freshness cards (2-col on standard/wide, 1-col on compact)
- `Z3`: contradiction card (conditional) + CE2 trend chart
- `Z4`: contribution entry + reason summary + related entities
- `Z5`: watchlist primary action (top fold trailing + sticky bottom)

Action contract:
- primary: `Add/Remove Watchlist` always visible in top fold and sticky bottom
- secondary: contradiction jump link to evidence block

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

### Error
- summary and retry in one card
- retry control must meet `44x44dp` minimum

### Stale
- stale age appears in `Z0`
- interpretation note appears in `Z2` or top-of-list context

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

## Trust Visibility Rules
- trust state remains visible in ranking rows, detail top fold, watchlist rows, and alerts metadata
- contradiction cannot be hidden behind secondary tabs
- trust and contradiction cues use icon + label, not color only
