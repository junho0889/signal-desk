# Analytics Visual System

## Purpose
Define a premium, mobile-first analytics visual system for SignalDesk that keeps ranking movement, trust posture, freshness, and evidence depth readable in one glance.

## Scope and Assumptions
- this spec stays within MVP app boundaries and read-only intelligence workflows
- current API fields drive v1 UI (`score`, `delta_1d`, `confidence`, `risk_flags`, `reason_tags`, `timeseries[]`)
- pending model and trust lanes may add richer trust outputs; components below are designed so new fields can plug in without layout redesign

## Visual Intent
- tone: research console, not retail trading hype
- density: compact but legible, optimized for 6.1 to 6.7 inch devices
- hierarchy: movement first, trust second, evidence third, actions last
- contrast: meaningful color reserved for signal state, not decorative chrome

## Core Design Tokens

### Semantic Color Channels
- `momentum_up`: teal 500 for positive movement and improving rank
- `momentum_down`: coral 500 for negative movement and rank decay
- `trust_high`: cyan 500 for high-confidence and multi-source alignment
- `trust_mid`: amber 500 for partial confidence or limited coverage
- `trust_low`: red 500 for low confidence, stale, or contradiction-heavy windows
- `fresh_recent`: mint 500 for fresh evidence windows
- `fresh_stale`: slate 500 for aging windows where recency risk increases
- `risk_flag`: orange/red scale reserved for contradiction and misinformation risk flags
- `base_surface`: graphite/ink neutral stack for cards, chart backdrops, and dividers

### Type Scale (Mobile)
- `display_compact` 24/28 semi-bold for score hero values
- `title` 17/22 semi-bold for keyword and section labels
- `body` 14/19 medium for standard metric labels and evidence snippets
- `meta` 12/16 medium for tags, timestamps, and source labels
- tabular numerals are required for score, delta, rank, and confidence values

### Spacing and Shape
- base spacing unit: 4dp
- card padding: 12dp (list cards), 16dp (detail hero cards)
- corner radius: 14dp for primary cards, 10dp for chips
- chart grid stroke: 1dp subtle neutral; emphasis strokes 2dp
- minimum touch target: 44dp

## Chart Block Library

### C1. Rank Momentum Sparkline (Ranking rows)
Purpose: show short-window movement direction without opening detail.
- v1 data: `score` + `delta_1d` rendered as a two-segment momentum micro-line
- additive-ready data: optional `mini_trend_points[]` can replace the two-segment fallback later
- visual: thin line with filled baseline glow; endpoint marker uses trust channel tint
- size: 88x28dp inline block
- states:
  - positive: teal line, upward endpoint
  - negative: coral line, downward endpoint
  - insufficient: dotted neutral line with `insufficient data`

### C2. Score and Confidence Twin-Line (Detail hero)
Purpose: separate raw movement from certainty trend.
- data: `timeseries.score`, `timeseries.confidence`
- visual: primary score line + secondary confidence line; no dual y-axis labels in MVP
- size: full-width card, 168dp height
- overlays:
  - freshness markers on x-axis checkpoints
  - contradiction window highlight bands when risk flags indicate disagreement

### C3. Dimension Contribution Bar Stack (Detail explainability)
Purpose: make model contribution readable by dimension.
- data: `dimension_mentions`, `dimension_trends`, `dimension_market`, `dimension_events`, `dimension_persistence`
- visual: horizontal bars with positive/negative direction and contribution magnitude
- size: full-width card, 5 fixed rows
- rule: keep dimension order stable across all keywords

### C4. Source Mix Ribbon (Evidence screen)
Purpose: show evidence diversity and over-reliance risk.
- v1 data source: inferred from related evidence metadata where available
- trust-ready mapping: source reliability and duplication intensity map to ribbon segments
- visual: 100% stacked ribbon with source-type buckets and concentration warning notch
- size: full-width compact card, 64dp height

### C5. Event Timeline Ladder (Evidence screen)
Purpose: present catalyst sequence and recency decay.
- data: `related_news[]`, disclosure/event timestamps, major score turns
- visual: vertical ladder with timestamp rail, event nodes, and confidence/freshness side tags
- size: adaptive list section
- states: conflicting-source nodes get contradiction icon and warning accent

### C6. Relationship Pulse Matrix (Detail -> related stocks/sectors)
Purpose: preserve stock and sector context without heavy chart load.
- data: `related_stocks[]`, `related_sectors[]`, movement metadata when available
- visual: two-row mini heat matrix (stocks on top, sectors below) with tap targets
- size: 2xN chips in a single scroll row per relation type

## Stat Card Patterns

### S1. Movement Card
- fields: `score`, `delta_1d`, optional rank change
- layout: dominant score left, delta and rank chip right
- color: momentum channel only

### S2. Trust Card
- v1 fields: `confidence`, `risk_flags`, `is_alert_eligible`
- trust-ready fields: `trust_score`, `coverage_score`, `contradiction_flag`, `low_confidence_mapping_flag`
- layout: confidence meter + trust posture label (`strong`, `watch`, `fragile`)

### S3. Freshness Card
- v1 fields: latest `snapshot_at`, latest evidence timestamp
- trust-ready fields: stale-source output
- layout: elapsed-time badge + freshness band (`live`, `recent`, `aging`, `stale`)

### S4. Contradiction Card
- v1 trigger: presence of contradiction-like `risk_flags`
- trust-ready trigger: contradiction and misinformation-risk flags
- layout: conflict summary count + top conflicting evidence preview
- interaction: tap opens contradiction-focused timeline filter

## Trust, Freshness, and Contradiction Presentation Rules

### Trust Ladder
- `strong`: high confidence with no severe risk flags
- `watch`: medium confidence or moderate flags
- `fragile`: low confidence, stale sources, or contradiction risk
- every ladder state must include a "why" line using reason tags or trust outputs

### Freshness Bands
- `live`: <= 2 hours
- `recent`: > 2 hours and <= 12 hours
- `aging`: > 12 hours and <= 24 hours
- `stale`: > 24 hours
- stale state always pairs with a neutral warning chip; never hide under secondary tabs

### Contradiction Escalation
- low: subtle amber indicator in row/card
- medium: contradiction badge + evidence timeline highlights
- high: top-of-screen risk banner in detail with direct jump to conflicting items
- contradiction indicators must be visible even when score is rising

## Ranking Screen Pattern
- row template order (fixed):
  1) rank, keyword, trust ladder micro-badge
  2) movement card mini (`score`, `delta_1d`)
  3) C1 sparkline
  4) reason tags + risk chips
  5) freshness micro-label (right-aligned)
- rows support high-density scan: max two text lines before truncation

## Detail Screen Pattern
- top fold stack:
  1) movement card (S1)
  2) trust/freshness split cards (S2 + S3)
  3) contradiction card (S4) only when active
  4) C2 twin-line chart
- below fold:
  - C3 contribution stack
  - reason and risk explanation block
  - C6 relationship pulse matrix

## Evidence Screen Pattern (Detail subview)
- top: freshness and source concentration summary
- body:
  - C4 source mix ribbon
  - C5 event timeline ladder
  - related evidence list grouped by source type
- default sort: newest first, with contradiction markers pinned to top within group

## Motion and Interaction Rules
- list row expand/collapse animation <= 180ms; no chart redraw shimmer on simple filter changes
- chart transitions should morph data paths, not cross-fade entire cards
- risk state changes animate chip/border only; avoid full-screen flash treatments

## Accessibility and Readability
- color is never the only state signal; pair with icon, label, or pattern
- minimum contrast: WCAG AA for all numeric and status labels
- support dynamic type up to at least 120% without hiding trust/freshness state

## Freeze Targets for APP-006
- token groups: semantic color channels, trust ladder labels, freshness bands, contradiction severity styles
- chart blocks: C1 through C6 data contracts and default heights
- stat cards: S1 through S4 field order and fallback states
- screen zones: ranking row order, detail top fold stack, evidence timeline + source mix pairing
- implementation should freeze these primitives before feature-level UI coding begins
