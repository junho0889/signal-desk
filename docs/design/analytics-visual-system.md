# Analytics Visual System

## Scope (DESIGN-002 Freeze)
This spec is intentionally limited to APP build needs for:
- ranking surfaces
- keyword detail surfaces
- chart blocks used by ranking/detail/evidence
- loading/empty/error/stale states

Other screens follow prior baseline docs and are not redefined here.

## Non-Negotiable Constraints
- no layout shift between ranking rows
- no floating or ambiguous actions
- one primary action per surface
- no chart that requires legend decoding before understanding
- no text overflow under Korean/English strings

## Core Tokens (Frozen)

### Spacing and Shape
- spacing scale only: `4, 8, 12, 16, 24, 32`
- screen horizontal padding: `16dp`
- section gap: `16dp`
- card padding: `12dp`
- primary card radius: `14dp`
- secondary/chip radius: `10dp`
- min touch target: `44dp`

### Typography
- `hero_value`: 24/28 semibold, tabular
- `section_title`: 17/22 semibold
- `body`: 14/19 medium
- `label`: 12/16 medium
- `micro`: 11/14 medium

Rules:
- no all-caps labels
- score/delta/rank/confidence use tabular numerals
- truncation: keyword/source 1 line, evidence title 2 lines, reason block 4 lines max

### Numeric Formatting
- `score`: 2 decimals
- `delta_1d`: signed, 2 decimals
- `confidence`: percent with one global precision rule (0 or 1 decimal)
- nulls: `-` or `insufficient data`

## Ranking Surface Contract

### Row Structure (Frozen)
Collapsed row min height: `104dp`, row gap: `8dp`.

Fixed order:
1. rank + keyword
2. movement (`score`, `delta_1d`)
3. trust/freshness cue
4. evidence cue (`reason_tags`, related sector)

Implementation rules:
- score/delta/trust positions never move between rows
- collapsed row must already explain why item matters
- long text truncates, never pushes row geometry

### Ranking Actions
- primary action: full-row tap -> keyword detail
- secondary actions: sticky filters (`period`, `market`, `sector`) below context rail

## Detail Surface Contract

### Top Fold (Frozen Order)
1. S1 movement card (`score`, `delta_1d`)
2. S2 trust card + S3 freshness card (two-column)
3. S4 contradiction card (conditional)
4. C2 score-vs-confidence chart

All items above must appear before deep evidence list.

### Detail Actions
- primary action: `Add/Remove Watchlist` button in trailing action slot
- button min size: `44dp` height, `120dp` width
- same action persists as sticky bottom action after first major scroll break

## Chart Surface Contract

### C1 Rank Micro-Line (Ranking)
- data: `score`, `delta_1d` (optional additive `mini_trend_points[]`)
- size: `88x28dp`
- fallback: dotted neutral line + `insufficient data`

### C2 Score vs Confidence (Detail Hero)
- data: `timeseries.score`, `timeseries.confidence`
- size: full width, `168dp` height
- title format: `Score and confidence over {period}`
- show start/end value labels at minimum

### C3 Contribution Stack
- data: `dimension_mentions`, `dimension_trends`, `dimension_market`, `dimension_events`, `dimension_persistence`
- fixed 5-row order; never re-sort per keyword

### C4 Source Mix Ribbon
- purpose: source concentration view for evidence quality
- fixed `64dp` height
- concentration warning notch when one source dominates

### C5 Event Timeline Ladder
- newest-first evidence order
- contradiction markers shown inline
- fixed timestamp column

## State Surface Contract (All Ranking/Detail Surfaces)

### Loading
- skeleton geometry matches final row/card structure
- no width animation that shifts layout

### Empty
- one explanatory sentence
- one next-step action

### Error
- error summary + retry in same card
- retry control min `44x44dp`

### Stale
- show data age in context rail
- add calm interpretation note in trust/freshness zone

## Readability Gate (Must Pass)
- first chart answers a real user question
- labels/axes readable on phone viewport
- critical states (trust/freshness/contradiction) never rely on color alone
- primary action identifiable within ~3 seconds
