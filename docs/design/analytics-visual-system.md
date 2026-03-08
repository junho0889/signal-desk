# Analytics Visual System

## Scope (Frozen)
This freeze is limited to visible mobile surfaces APP will build now:
- Ranking
- Keyword Detail
- Chart entry points on those surfaces
- Loading, Error, Stale, Trust states

## Non-Negotiables
- no generic finance styling
- no row layout shifts
- one obvious primary action per surface
- no chart requiring legend-first interpretation
- no Korean/English overflow breakage

## Core Tokens
- spacing scale only: `4, 8, 12, 16, 24, 32`
- horizontal screen padding: `16dp`
- section gap: `16dp`
- card padding: `12dp`
- primary radius: `14dp`, secondary radius: `10dp`
- minimum tap target: `44dp`

## Typography and Formatting
- `hero_value`: 24/28 semibold, tabular numerals
- `section_title`: 17/22 semibold
- `body`: 14/19 medium
- `label`: 12/16 medium
- `micro`: 11/14 medium
- no all-caps
- `score`: 2 decimals
- `delta_1d`: signed, 2 decimals
- `confidence`: one global percent precision rule
- null display: `-` or `insufficient data`
- truncation: keyword/source 1 line, evidence title 2 lines

## Ranking Surface Contract
- collapsed row min height: `104dp`
- row gap: `8dp`
- fixed order:
  1. rank + keyword
  2. movement (`score`, `delta_1d`)
  3. trust/freshness cue
  4. evidence cue (`reason_tags`, related sector)
- primary action: full-row tap
- secondary actions: sticky `period/market/sector` filters
- score/delta/trust positions never move across rows

## Detail Surface Contract
Top fold order is frozen:
1. movement card (`score`, `delta_1d`)
2. trust + freshness cards (two-column)
3. contradiction card (conditional)
4. trend chart entry point

Rules:
- top fold above deep evidence content
- primary action: trailing `Add/Remove Watchlist` button (`44dp` h min, `120dp` w min)
- same action persists as sticky bottom action after first major scroll break

## Chart Entry Points (Frozen)

### CE1 Ranking Sparkline
- location: ranking row movement zone
- data: `score`, `delta_1d` (optional additive points)
- size: `88x28dp`
- fallback: dotted neutral + `insufficient data`

### CE2 Detail Trend Chart
- location: detail top fold after trust/contradiction block
- data: `timeseries.score`, `timeseries.confidence`
- size: full width, `168dp` height
- title format: `Score and confidence over {period}`
- start/end values visible at minimum

### CE3 Detail Contribution Entry
- location: first evidence block below top fold
- data: `dimension_mentions`, `dimension_trends`, `dimension_market`, `dimension_events`, `dimension_persistence`
- fixed 5-row order, never re-sorted per keyword

## Trust State Contract
- `strong`: high confidence, no severe flags
- `watch`: medium confidence or moderate flags
- `fragile`: low confidence, stale-source risk, or contradiction risk
- each state includes one-line reason
- contradiction indicators remain visible even when score is rising

## State Contract (Ranking + Detail)

### Loading
- skeleton geometry matches final row/card geometry
- no animated width changes that shift layout

### Error
- error summary and retry in same card
- retry control min `44x44dp`

### Stale
- stale age shown in context rail
- calm interpretation note shown in trust/freshness zone

## Readability Gate
- first chart must answer a user question immediately
- labels are readable at phone width
- trust/freshness/contradiction never rely on color alone
- primary action is identifiable within ~3 seconds
