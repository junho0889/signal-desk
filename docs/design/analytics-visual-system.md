# Analytics Visual System

## Purpose
Freeze a premium mobile analytics visual system for SignalDesk so implementation teams can build without inventing layout, spacing, typography, button placement, or chart interpretation behavior.

## Non-Negotiable Inputs
This document is bound to the following coordination inputs and must not conflict with them:
- `coordination/premium-mobile-brief.md`
- `coordination/mobile-ui-quality-gate.md`

## Implementation Baseline
- UI foundation: Flutter Material 3 shell with SignalDesk-owned tokens/components.
- Planned shaping libraries: `flex_color_scheme` for theme shaping and `fl_chart` for charts.
- Third-party UI kits are reference-only and cannot replace SignalDesk shell patterns.

## Freeze Level Definition
A component is considered frozen when all items below are specified:
- data fields and fallback behavior
- container geometry (padding, radius, min height)
- typography roles and line clamp/truncation
- action placement and touch target
- loading, empty, error, stale treatments

## Hard Constraints
- no generic finance-app clone styling
- no floating or hidden "mystery" actions
- no row layout shifts between ranking items
- no chart that depends on legend decoding before message comprehension
- no text treatment that overflows under Korean or English strings

## Design Tokens (Frozen)

### Spacing Scale
Only this scale is allowed: `4, 8, 12, 16, 24, 32`.

Usage contract:
- screen horizontal padding: `16dp` on all primary surfaces
- section-to-section vertical gap: `16dp`
- card internal padding: `12dp`
- dense in-card gap: `8dp`
- chip and icon gap: `4dp`
- hero block separation: `24dp`
- bottom safe-area inset: `16dp` + device safe area

No ad hoc spacing values are permitted.

### Shape and Stroke
- primary card radius: `14dp`
- secondary card/chip radius: `10dp`
- pill chip radius: `999dp`
- default border stroke: `1dp`
- emphasis stroke for risk/contradiction: `2dp`
- minimum touch target: `44dp` height and width

### Color Channels
- `momentum_up`: positive movement and improving rank
- `momentum_down`: negative movement and rank decay
- `trust_high`: high confidence and multi-source alignment
- `trust_mid`: medium confidence or partial coverage
- `trust_low`: low confidence, stale, or contradiction-heavy windows
- `fresh_live`: <=2h windows
- `fresh_recent`: >2h and <=12h windows
- `fresh_aging`: >12h and <=24h windows
- `fresh_stale`: >24h windows
- `risk_flag`: contradiction and misinformation-risk emphasis only
- `base_surface`: neutral surfaces and dividers

Important distinctions must never rely on color alone.

## Typography Contract (Frozen)

### Font Families
- primary: `Pretendard Variable`
- fallback: `Noto Sans KR`, `Roboto`, sans-serif

### Type Roles
- `hero_value`: 24/28, semibold, tabular numerals
- `screen_title`: 20/26, semibold
- `section_title`: 17/22, semibold
- `body`: 14/19, medium
- `label`: 12/16, medium
- `micro`: 11/14, medium

Rules:
- no all-caps labels
- score, delta, rank, confidence use tabular numerals
- numeric precision is fixed per metric family across all screens

### Truncation Rules (Korean + English)
- ranking keyword name: 1 line, tail ellipsis
- source name: 1 line, tail ellipsis
- reason tag label: 1 line, clip at chip boundary
- evidence headline/title: max 2 lines, tail ellipsis
- detail reason block: max 4 lines before "show more"

No marquee/auto-scroll text treatments are allowed.

## Numeric Formatting Rules
- `score`: signed-free decimal, 2 digits after decimal
- `delta_1d`: always signed (`+`/`-`), 2 digits after decimal
- `confidence`: percent display with 0 or 1 decimal (implementation uses one global rule)
- timestamps: locale-safe absolute+relative pairing (`2026-03-08 14:20` + `2h ago`)
- null values: explicit placeholder `-` or `insufficient data`

## Chart Block Library (Frozen)

### C1. Rank Momentum Micro-Line (Ranking Row)
- purpose: immediate movement cue before detail open
- v1 data: `score` + `delta_1d`
- additive field: optional `mini_trend_points[]`
- container: `88x28dp`
- title requirement: none in row context; row headline carries meaning
- fallback: dotted neutral line + `insufficient data` micro-label

### C2. Score vs Confidence Twin-Line (Detail Hero)
- purpose: answer "did score move with confidence support?"
- data: `timeseries.score`, `timeseries.confidence`
- container: full width, `168dp` height
- title template: `Score and confidence over {period}`
- labels: start/end value labels visible at minimum
- contradiction/high-risk overlays: shaded bands when active

### C3. Dimension Contribution Stack
- purpose: answer "what drove the current score"
- data: `dimension_mentions`, `dimension_trends`, `dimension_market`, `dimension_events`, `dimension_persistence`
- container: full width, 5 fixed rows
- order is frozen and cannot be re-sorted per keyword
- each row includes dimension label, signed contribution, and magnitude bar

### C4. Source Mix Ribbon
- purpose: answer "how concentrated is this evidence"
- v1 mapping: inferred source categories from available evidence metadata
- trust-ready mapping: reliability/diversity/duplication segments
- container: full width, `64dp` height
- warning notch appears when one source type dominates

### C5. Event Timeline Ladder
- purpose: answer "what happened first and how recent is it"
- data: `related_news[]` plus event timestamps
- structure: vertical rail with fixed timestamp column
- contradiction markers are shown inline on conflicting items
- newest-first ordering is frozen

### C6. Relationship Pulse Matrix
- purpose: answer "which stocks/sectors are linked right now"
- data: `related_stocks[]`, `related_sectors[]`
- structure: two fixed rows (stocks then sectors)
- each chip is tappable and uses consistent size/style per row

## Stat Card Library (Frozen)

### S1 Movement Card
- fields: `score`, `delta_1d`, optional rank change
- layout: left value block + right movement badges
- min height: `84dp`

### S2 Trust Card
- v1 fields: `confidence`, `risk_flags`, `is_alert_eligible`
- trust-ready fields: `trust_score`, `coverage_score`, `contradiction_flag`, `low_confidence_mapping_flag`
- layout: trust posture label + confidence meter + why line
- min height: `84dp`

### S3 Freshness Card
- fields: latest snapshot/evidence timestamp
- layout: freshness band + elapsed-time badge + interpretation line
- min height: `84dp`

### S4 Contradiction Card
- trigger: contradiction-like `risk_flags` in v1, trust flags when available
- layout: severity, conflict count, top conflicting cue, jump action
- min height: `72dp`

## Trust, Freshness, Contradiction Rules (Frozen)

### Trust Ladder
- `strong`: high confidence with no severe risk flags
- `watch`: medium confidence or moderate risk
- `fragile`: low confidence, stale-source risk, or contradiction risk
- each state must include one-line "why" explanation

### Freshness Bands
- `live`: <= 2h
- `recent`: > 2h and <= 12h
- `aging`: > 12h and <= 24h
- `stale`: > 24h

### Contradiction Escalation
- low: inline amber marker
- medium: contradiction badge + timeline highlight
- high: top-of-detail risk banner + direct jump to conflicting evidence

Contradiction visibility cannot be hidden when score is rising.

## Action and Button Placement Contract

### Global Rules
- one visually dominant primary action per screen
- secondary actions must be text or tonal, never stronger than primary
- no floating action button on primary intelligence screens
- retry actions are always within thumb reach in the lower half of the viewport

### Primary Action Placement
- Home: primary action is top-keyword card tap target (full-card hit area)
- Ranking: primary action is row tap target (entire row)
- Detail: primary button is `Add/Remove Watchlist`, right side of `Z5`, sticky after first scroll break
- Evidence: primary action is source open CTA on selected evidence item (row trailing)
- Watchlist: primary action is keyword row tap target
- Alerts: primary action is alert row tap target

### Secondary Action Placement
- filter controls: pinned in top control strip below context rail
- refresh/retry: bottom-centered within state card or sticky lower action bar
- share/export actions: not allowed in MVP surfaces

## State Surface Contract

### Loading
- skeletons must mirror final geometry per zone
- no skeleton shimmer that changes layout width between frames

### Empty
- include one next-step action and one explanatory sentence
- empty card uses same padding/radius as populated card

### Error
- include error summary + retry action in same card
- retry control minimum size `44x44dp`

### Stale
- show data age and safe interpretation note
- stale badge appears in `Z0` and any hero trust/freshness card

## Ranking Row Blueprint (Frozen)
- row outer padding: `12dp`
- row gap: `8dp`
- fixed order:
  1) rank + keyword
  2) movement cue (`score`, `delta_1d`)
  3) trust/freshness cue
  4) evidence context (`reason_tags`, sector)
- row min height: `104dp` collapsed
- expanded rows may add evidence, but collapsed state must already answer why item matters

## Detail Top-Fold Blueprint (Frozen)
- order:
  1) S1 movement card
  2) S2/S3 two-column trust/freshness cards
  3) conditional S4 contradiction card
  4) C2 twin-line chart
- all four blocks must appear before deep evidence list content

## Chart Readability Gate (Must Pass)
- first chart on each screen must answer a user question, not fill space
- chart titles describe change and period, not only metric names
- axis/labels must remain legible on phone viewport width
- shape or labels must encode status in addition to color

## Anti-Patterns (Blocked)
- swapping score/trust positions between rows
- multiple competing primary buttons on one screen
- hiding contradiction in secondary tabs only
- using modal/bottom sheet for essential evidence reading
- introducing ad hoc spacing or alternate type roles

## Freeze Targets for APP-006 and APP-007
- token system: spacing, shape, color channels, typography roles, numeric formatting
- chart blocks: C1 through C6 with fixed geometry and title/readability rules
- stat cards: S1 through S4 with field order and min heights
- action placement: global + per-screen primary/secondary action positions
- state surfaces: loading/empty/error/stale geometry and controls

Implementation is not allowed to improvise new spacing, hierarchy, or button-placement behavior beyond this freeze set.
