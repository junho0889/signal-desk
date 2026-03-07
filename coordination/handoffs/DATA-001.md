## Task
- id: DATA-001
- owner: signal-desk-data
- status: in_progress (deliverables complete, awaiting orchestrator review)

## What Changed
- Replaced `docs/data/source-catalog.md` with a stable v0 source contract including:
  - source inventory (fields, cadence, constraints, fallback behavior)
  - canonical timestamp/idempotency rules
  - normalization/entity mapping requirements
  - derived dataset outputs for downstream schema/API work
  - quality controls and explicit non-goals
- Replaced `docs/data/keyword-scoring-v0.md` with a backend-implementable scoring specification including:
  - output contract fields and types
  - normalized dimension definitions and formulas
  - final weighted score and confidence model
  - alert eligibility gates and anti-noise guardrails
  - runtime cadence and known risks

## Verification
- commands:
  - `Select-String -Path .\\docs\\data\\source-catalog.md -Pattern "ranking|detail|watchlist|alert|server-side|derived"`
  - `Select-String -Path .\\docs\\data\\keyword-scoring-v0.md -Pattern "Home|Ranking|Detail|watchlist|alert|server-side|is_alert_eligible|reason_tags"`
  - `Select-String -Path .\\docs\\product\\mvp-scope.md -Pattern "Home dashboard|Keyword ranking|Keyword detail|watchlist|Alert rules|Out of Scope"`
  - `Select-String -Path .\\docs\\architecture\\system-overview.md -Pattern "API reads stable derived data|Notification rules are evaluated server-side|Jobs write derived data"`
- result:
  - Scoring inputs/outputs align with MVP ranking/detail/watchlist/alerts workflows.
  - Contracts align with architecture boundary (jobs write derived data, API reads derived data, alerts evaluated server-side).

## Backend Pressure Points For BE-001
- **Schema pressure**
  - Need stable tables/materialized views for `keyword_signal_timeslice`, `keyword_evidence_event`, and `keyword_entity_link`.
  - Must support arrays/enums for `reason_tags` and `risk_flags` in score snapshots.
  - Need deterministic idempotency keys and uniqueness constraints by source grain.
  - Need numeric precision choices consistent with defined score/confidence ranges.
- **API pressure**
  - Ranking endpoints must expose per-dimension values, `score_delta_24h`, `confidence`, `reason_tags`, and `risk_flags`.
  - Detail endpoints must provide evidence timeline references (`event_type`, `event_ref_id`, `source_name`, `summary_text`).
  - Watchlist/alert surfaces must consume `is_alert_eligible` and hard risk flags.
- **Job orchestration pressure**
  - 30-minute scoring cadence plus daily backfill implies scheduler + idempotent upsert design.
  - Partial-source failures need explicit publish/suppress logic in jobs to avoid noisy alerts.

## Blockers
- None.

## Next Step
- `BE-001` freezes DB schema and API contracts directly from these data contracts.

## Files Touched
- docs/data/source-catalog.md
- docs/data/keyword-scoring-v0.md
- coordination/handoffs/DATA-001.md
- coordination/resume/DATA-001.md
