# Mobile Next-Phase Plan

## Purpose
Guide the mobile lane as the platform evolves from MVP read models to a richer analytics product.

## APP-006 Planning Status
- planning only; no mobile feature implementation in this task
- `v1` API contract remains frozen, with additive-only candidates listed as open
- final execution order depends on upstream outputs from `APP-005`, `BE-004`, `MODEL-001`, `TRUST-001`, and `DESIGN-002`

## Stable Baseline Available Today
The following mobile-facing inputs are already stable enough to design against:
- charts: keyword detail `timeseries[]` (`snapshot_at`, `score`, `confidence`)
- trust and risk: `confidence`, `risk_flags`, `is_alert_eligible`
- freshness: endpoint-level `generated_at`, evidence-level `published_at`, alert-level `triggered_at`
- multilingual baseline: no contract-level localization fields in `v1`; UI copy localization remains client-owned

## Integration Principles
- preserve fast scan flow from `Home -> Ranking -> Detail` without adding extra taps
- show risk/trust context before secondary analytics detail
- treat unknown or nullable values as explicit placeholders, never inferred values
- avoid freezing new payload fields before storage/model/trust/design contracts are published
- keep mobile changes additive to APP-004 pagination/staleness behavior and APP-005 language toggle baseline

## Phased Mobile Integration Plan
1. Phase A: Foundation alignment
- consume APP-005 app-wide language mode as the base for future analytics copy localization
- maintain APP-004 cursor and stale-data patterns as default list behavior
- prepare extension points in view models for charts/trust/freshness blocks without changing API calls yet

2. Phase B: Chart surfaces with current contracts
- promote existing detail `timeseries[]` into a first-class trend block in Keyword Detail
- add chart container patterns on Home/Ranking using placeholder states when chart payload is absent
- defer ranking-row sparkline rendering until additive list/chart fields are contract-ready

3. Phase C: Trust and freshness surfaces
- standardize trust strip rendering:
  - primary: `confidence`
  - warning chips: `risk_flags`
  - eligibility badge: `is_alert_eligible`
- add freshness badges driven by current timestamps:
  - screen freshness from `generated_at`
  - evidence freshness from `published_at`
- reserve space for future contradiction/coverage outputs without binding to names yet

4. Phase D: Multilingual analytics behavior
- localize all UI chrome and analytics labels in-app (`en`/`ko`) using fixed string keys
- keep machine enums and literals (`risk_flags`, `reason_tags`, severity) unchanged in transport
- map transport literals to localized labels client-side until backend localization fields are frozen
- keep keyword/entity proper nouns untranslated unless an explicit localized display field is introduced

5. Phase E: Post-freeze enrichment
- after BE-004, MODEL-001, TRUST-001, and DESIGN-002 outputs are accepted, adopt additive payloads for:
  - list-level mini trend charts
  - trust dimension summaries and contradiction visibility
  - evidence timelines and source-mix visualizations

## Screen Integration Outline
### Home
- stable now: top keyword score/delta/confidence/risk snapshot
- next phase: compact movement and trust summary card with optional trend micro-chart
- open contract dependency: chart point payload for rail cards

### Ranking
- stable now: sortable/filterable list with confidence and risk flags
- next phase: row-level trust/freshness badges and optional sparkline slot
- open contract dependency: list-friendly compact trend payload

### Keyword Detail
- stable now: score summary, timeseries, reason block, related evidence lists
- next phase: richer chart controls, trust panel, evidence timeline section
- open contract dependency: trust-dimension outputs, timeline/event payload

### Watchlist
- stable now: severity and risk-driven follow-up queue
- next phase: freshness/trust quick badges for watch items
- open contract dependency: watch-target trust/freshness rollups

### Alerts
- stable now: severity feed with target navigation
- next phase: contradiction/freshness snippets in alert rows
- open contract dependency: alert-level trust context fields

## Candidate Payload Additions (Open, Not Frozen)
These are request candidates for backend/storage/model/trust design. Names are placeholders until upstream lanes freeze contracts.

- `GET /dashboard`:
  - `top_keywords[].trend_points` (recent score path for mini chart)
  - `top_keywords[].freshness_minutes` (client badge simplification)
- `GET /keywords`:
  - `items[].trend_points` (compact row sparkline)
  - `items[].freshness_minutes`
  - `items[].trust_level` (coarse bucket derived server-side)
- `GET /keywords/{keyword_id}`:
  - `trust_summary` object (trust/coverage/contradiction/staleness dimensions)
  - `timeseries[].trust_score` and `timeseries[].coverage_score`
  - `evidence_timeline[]` (time-ordered explanation events)
  - `source_mix[]` (source diversity breakdown)
- `GET /alerts`:
  - `items[].trust_flags` (alert-specific trust warnings)
  - `items[].freshness_minutes`
- cross-endpoint localization candidate:
  - optional `label_overrides` map for server-approved display labels (only if backend decides transport-level localization is needed)

## Contract Readiness Gates
- gate 1 (stable now): existing `v1` fields, APP-004 behavior, APP-005 language mode
- gate 2 (open): DESIGN-002 chart/card pattern freeze
- gate 3 (open): BE-004 storage and lineage fields available for read-model publication
- gate 4 (open): MODEL-001 explanation outputs and TRUST-001 warning outputs mapped to mobile payloads
- gate 5 (implementation start): QA confirms no regression risk to current MVP read flows

## Non-Goals For This Planning Note
- final production visual polish
- personalization and account features
- offline mode
- changing or versioning the frozen `v1` API contract within APP-006
