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

## Premium Brief Translation For APP-007
This section converts the premium mobile brief and UI quality gate into executable mobile guidance without changing frozen contracts.

### APP-007 Package Contract (Exact)
APP-007 implementation should use only the following package changes:
- add `flex_color_scheme` for Material 3 theme shaping and tokenized color roles
- add `fl_chart` for trend and movement chart rendering
- add `flutter_localizations` (SDK) for bilingual shell localization wiring
- add `intl` for localized numeric/date formatting
- keep existing network and repository stack unchanged (`http` + current client/repository files)
- do not introduce additional state-management or UI-framework packages in APP-007

### APP-007 Component Contract (Exact)
APP-007 should implement a shared analytics UI layer with these component responsibilities:
- `SignalDeskMetricRow`: fixed reading order for rank/name/movement/score/trust/freshness
- `SignalDeskTrustStrip`: confidence + alert eligibility + risk-chip group with stable placement
- `SignalDeskFreshnessBadge`: timestamp age treatment with calm stale-state emphasis
- `SignalDeskTrendChartCard`: compact line chart container with title, interval label, and null-data state
- `SignalDeskRiskCallout`: contradiction or risk emphasis block that cannot be visually suppressed
- `SignalDeskSectionCard`: reusable section shell for chart/evidence/trust blocks with stable padding and heading behavior
- `SignalDeskStateSurface`: loading/empty/error/stale wrappers aligned to quality-gate state rules

### APP-007 Screen-Shell Contract (Exact)
APP-007 should implement one shell pattern and apply it consistently across primary surfaces:
- preserve `SignalDeskShell` as the route-level scaffold; extend it for stable app-bar hierarchy and action placement
- enforce spacing scale `4, 8, 12, 16, 24, 32` at shell and section boundaries
- keep one dominant primary action per screen, with secondary actions visually demoted
- keep list-row geometry fixed across Ranking and Watchlist to prevent scan-order drift
- keep chart blocks above secondary evidence lists on detail surfaces
- keep stale/retry states as first-class shell-level surfaces, not ad hoc inlined text

### APP-007 Screen Delivery Scope (No Improvisation)
APP-007 should implement exactly this visual/system layer scope:
1. app shell and theme
- apply tokenized theme setup with `flex_color_scheme`
- wire localization delegates and locale selection from APP-005 language mode

2. shared components
- implement the component set listed in `APP-007 Component Contract (Exact)`
- migrate screen-specific duplicated metric/trust formatting into shared components

3. screen-shell upgrades using only current `v1` data
- Home: premium card structure for top keywords, sectors, and alert summary with trust/freshness slots
- Ranking: fixed-order row shell with trust/freshness cues and chart placeholder slot
- Detail: top narrative section + trend chart card + trust/risk zone + evidence section cards
- Watchlist: row shell parity with ranking metric order and severity/trust emphasis
- Alerts: severity-first row shell with freshness and trust warning slots

4. localization and formatting
- apply Korean/English copy keys for all chrome labels introduced by APP-007
- localize numeric/date rendering through one formatting helper path backed by `intl`
- enforce truncation/overflow rules for keyword names and evidence snippets in both locales

5. quality gate implementation baseline
- implement loading/empty/error/stale states using shared state surfaces on all primary screens
- ensure trust/freshness cues remain visible in collapsed list states

### APP-007 Explicit Non-Scope
- no repository/API contract refactor
- no backend endpoint or schema changes
- no new transport literals or enum changes
- no source-mix/evidence-timeline rendering that depends on unfrozen payload shapes
- no design improvisation outside the package/component/shell contract above

### APP-007 Readiness And Acceptance Checklist
APP-007 is ready to start only when:
- APP-005 language toggle baseline is merged
- APP-004 stale-data and pagination behavior is available to preserve in upgraded shells
- mobile worker acknowledges that BE-004/TRUST-001/MODEL-001 fields remain optional and unfrozen

APP-007 is done when:
- package contract, component contract, and screen-shell contract are implemented exactly as scoped
- all primary screens pass mobile UI quality-gate checks for trust/freshness readability and locale-safe layout
- current `v1` contract compatibility is preserved with additive-only assumptions documented

## Non-Goals For This Planning Note
- final production visual polish
- personalization and account features
- offline mode
- changing or versioning the frozen `v1` API contract within APP-006
