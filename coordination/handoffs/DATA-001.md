## Task
- id: DATA-001
- owner: signal-desk-data
- status: in_progress (deliverables updated, awaiting orchestrator acceptance)

## What Changed
- Updated `docs/data/source-catalog.md`:
  - aligned `keyword_signal_timeslice` grain to 30-minute cadence (matching scoring cadence)
  - added explicit contract enums for `event_type`, `quality_flag`, and baseline `risk_flag`
- Updated `docs/data/keyword-scoring-v0.md`:
  - added stable threshold parameter section for backend config defaults
  - added backend contract notes for clamping and idempotent uniqueness (`keyword_id`, `as_of_ts`)

## Changed Files
- docs/data/source-catalog.md
- docs/data/keyword-scoring-v0.md
- coordination/handoffs/DATA-001.md
- coordination/resume/DATA-001.md

## Verification
- commands:
  - `Select-String -Path .\\docs\\data\\source-catalog.md -Pattern "30-minute|Contract Enums|risk_flag|event_type|quality_flag"`
  - `Select-String -Path .\\docs\\data\\keyword-scoring-v0.md -Pattern "Stable Threshold Parameters|Contract Notes For Backend|is_alert_eligible|reason_tags|risk_flags"`
  - `Select-String -Path .\\docs\\product\\mvp-scope.md -Pattern "Keyword ranking|Keyword detail|watchlist|Alert rules|Out of Scope"`
  - `Select-String -Path .\\docs\\architecture\\system-overview.md -Pattern "Jobs write derived data|API reads stable derived data|Notification rules are evaluated server-side"`
- result:
  - Data docs remain consistent with MVP ranking/detail/watchlist/alert workflows.
  - Data docs remain consistent with architecture boundary rules (jobs derive/write; API reads derived; alerts server-side).

## Blockers
- None.

## BE-001 Contract Pressure / Schema Impact
- Introduce enum domains or controlled-value constraints for `event_type`, `quality_flag`, and `risk_flag` to prevent drift.
- Ensure score snapshot uniqueness on (`keyword_id`, `as_of_ts`) for idempotent score publishes.
- Keep scoring snapshot numeric precision aligned with documented types (`numeric(5,2)`, `numeric(4,3)`).
- Preserve array support for `reason_tags` and `risk_flags` in both schema and API payloads.
- Maintain cadence compatibility: 30-minute timeslice grain and scoring publish schedule.

## Exact Next Step
- Orchestrator/BE-001 reviews the two data docs and freezes DB/API contracts using these field/type/enum definitions.
