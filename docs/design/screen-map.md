# Screen Map

## Purpose
Provide implementation-ready mobile screen blueprints that map API payloads to fixed zones, spacing, typography behavior, and action placement.

## Global Mobile Blueprint (Applies to All Primary Screens)
- viewport target: phone-first (`360dp` to `430dp` width)
- horizontal padding: `16dp`
- section gap: `16dp`
- card padding: `12dp`
- minimum touch target: `44dp`
- zone stack order is fixed and cannot be rearranged by screen state

## Global Zone Contract
- `Z0 Context Rail`: generated time, period/market context, freshness age
- `Z1 Signal Header`: title/target identity + rank or severity headline
- `Z2 Trust and Risk Strip`: trust ladder, freshness band, contradiction cues
- `Z3 Primary Analytics`: first chart or primary metric card answering "why now"
- `Z4 Evidence Stack`: reason tags, timeline, linked context
- `Z5 Actions`: primary and secondary actions in frozen positions

## Action Placement Rules
- one primary action per screen only
- primary actions on list-driven screens are full-row taps
- button-based primary action appears in `Z5` trailing position
- filter controls always sit below `Z0` and above list content
- retry controls are located in the lower half of the visible state card

## Home
Purpose: fast first-pass triage after app open.

API mapping:
- `GET /dashboard.generated_at` -> `Z0`
- `GET /dashboard.top_keywords[]` -> hero ranking cards (`Z1` to `Z3` compact)
- `GET /dashboard.hot_sectors[]` -> `Z4`
- `GET /dashboard.risk_alerts[]` -> `Z4`

Layout blueprint:
- `Z0`: single-row context rail, min height `32dp`
- `Z1`: top keyword title + rank/movement summary, min height `56dp`
- `Z2`: compact trust/freshness/risk chips, min height `28dp`
- `Z3`: C1 micro-line + score cluster, min height `44dp`
- `Z4`: sector movers block above alert summary block
- `Z5`: shortcut row to Ranking/Watchlist/Alerts (text+icon buttons)

Primary action:
- full-card tap on top keyword card opens Keyword Detail

Secondary actions:
- shortcut taps in `Z5`

## Keyword Ranking
Purpose: stable and dense ranking exploration.

API mapping:
- `GET /keywords.generated_at` -> `Z0`
- `GET /keywords.items[]` -> row list (`Z1` to `Z4` per row)
- `GET /keywords.next_cursor` -> pagination footer
- query controls: `period`, `market`, `sector`, `limit`, `cursor`

Layout blueprint:
- `Z0`: sticky context rail with generated time and period scope
- filter strip: sticky chips directly under `Z0`, min height `44dp`
- row blueprint (collapsed, frozen):
  1) `Z1`: `rank_position` + `keyword` (1 line clamp)
  2) `Z2`: trust/freshness micro badges (`confidence`, risk cue)
  3) `Z3`: movement mini card (`score`, `delta_1d`) + C1
  4) `Z4`: reason tags + related sector snippet
- collapsed row min height: `104dp`
- row-to-row gap: `8dp`

Primary action:
- full-row tap opens Keyword Detail

Secondary actions:
- filter chips and pagination trigger

Implementation lock:
- score, delta, trust/freshness positions cannot swap between rows
- row height must remain stable regardless of keyword length (truncate, do not push zones down)

## Keyword Detail
Purpose: explain why the signal matters now.

API mapping:
- `GET /keywords/{keyword_id}.generated_at` -> `Z0`
- `score_summary` -> S1, S2, S3, C3
- `timeseries[]` -> C2
- `reason_block`, `risk_flags` -> `Z2` and `Z4`
- `related_stocks[]`, `related_sectors[]` -> C6
- `POST /watchlist` -> `Z5`

Layout blueprint:
- `Z0`: context rail with freshness age
- `Z1`: keyword title + rank context + S1 movement card
- `Z2`: S2 trust card and S3 freshness card in a two-column row
- `Z3`: conditional S4 contradiction card, then C2 chart
- `Z4`: C3 contribution stack, reason block, C6 matrix
- `Z5`: primary watchlist action area

Primary action:
- `Add to Watchlist` / `Remove from Watchlist` filled button in `Z5` trailing position
- button size: min `44dp` height, min `120dp` width
- after first scroll break, same action persists as sticky bottom bar action

Secondary actions:
- contradiction jump link in S4
- related entity taps in C6

Implementation lock:
- top fold must include S1, S2/S3, and C2 before evidence list content
- contradiction card appears between trust/freshness cards and chart when active

## Keyword Detail - Evidence View
Purpose: deep evidence review without losing trust context.

API mapping:
- `related_news[]` -> C5 event timeline and evidence rows
- `risk_flags` -> contradiction/stale markers
- `generated_at` + `published_at` -> freshness displays
- `related_stocks[]`, `related_sectors[]` -> linked context chips

Layout blueprint:
- `Z1`: evidence header with period and freshness summary
- `Z2`: trust/freshness/contradiction strip
- `Z3`: C4 source mix ribbon
- `Z4`: C5 timeline ladder + grouped evidence rows
- `Z5`: row trailing source-open controls

Primary action:
- open source link from evidence row trailing action

Secondary actions:
- contradiction filter toggle
- related context chip taps

Implementation lock:
- evidence sort is newest first
- contradiction-marked rows stay pinned to top within source group

## Watchlist
Purpose: focused follow-up queue for tracked targets.

API mapping:
- `GET /watchlist.generated_at` -> `Z0`
- `GET /watchlist.keywords[]`, `stocks[]` -> row content
- `POST /watchlist` -> row remove/add behavior

Layout blueprint:
- `Z0`: context rail with generated time
- `Z1`: segmented control (Keywords/Stocks)
- `Z2`: per-row trust/risk strip
- `Z3`: per-row movement summary (keywords)
- `Z4`: per-row reason/severity context
- `Z5`: row-level remove action placement

Primary action:
- full-row tap on keyword row to open Keyword Detail

Secondary actions:
- row trailing remove action
- tab switch control in `Z1`

Implementation lock:
- keywords and stocks share visual rhythm even with different fields
- empty state includes one clear next step back to Ranking

## Alerts
Purpose: triage and route quickly to detail context.

API mapping:
- `GET /alerts.generated_at` -> `Z0`
- `GET /alerts.items[]` -> alert rows
- `GET /alerts.next_cursor` -> pagination
- query control: `severity`

Layout blueprint:
- `Z0`: context rail with freshness
- `Z1`: sticky severity filter strip
- `Z2`: row severity + trust/risk marker
- `Z3`: row message + target label + trigger time
- `Z4`: contradiction cue when linked keyword has risk flags
- `Z5`: route affordance (chevron + tap target)

Primary action:
- full-row tap opens Keyword Detail when `keyword_id` exists

Secondary actions:
- severity filter chips

Implementation lock:
- severity marker stays in same horizontal slot across all rows
- time label alignment is fixed regardless of message length

## State Blueprints (All Screens)

### Loading
- skeleton matches zone geometry and row heights exactly
- no changing widths that imply broken layout

### Empty
- one explanation sentence
- one next-step action centered in `Z5`

### Error
- error summary in `Z3`
- retry button in `Z5`, centered horizontally, min `44dp` height

### Stale
- stale indicator shown in `Z0`
- supporting interpretation note shown in `Z2` or hero card area

## Korean and English Safety Rules
- no fixed-width labels that assume English length
- all ranking names and source labels are clamped with ellipsis
- chips and buttons maintain vertical rhythm under Korean glyph density

## Cross-Screen Navigation Rules
- Home -> Detail: max 2 taps
- Ranking -> Detail: 1 tap
- Watchlist -> Detail: 1 tap for keyword rows
- Alerts -> Detail: 1 tap when `keyword_id` exists

## Out-of-Scope (Release-1)
- no broker/trade execution surfaces
- no social, sharing, or leaderboard surfaces
- no chat assistant panels
- no client-side model/trust recomputation

## Freeze Summary For Publisher and APP Lanes
Publishers and implementers must treat this document and `docs/design/analytics-visual-system.md` as the canonical source for:
- spacing and layout geometry
- typography and truncation behavior
- chart block placement and readability behavior
- primary/secondary action placement
- state design behavior

No additional layout or button-placement conventions may be invented in implementation without a new design handoff.
