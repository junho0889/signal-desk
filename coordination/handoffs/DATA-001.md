## Task
- id: DATA-001
- owner: signal-desk-data
- status: in_progress (QA blocker fixes applied; awaiting re-review)

## What Changed
- Updated `docs/data/source-catalog.md`:
  - aligned `keyword_signal_timeslice` grain to 30-minute cadence (matching scoring cadence)
  - kept explicit contract enums for `event_type`, `quality_flag`, and `risk_flag`
  - clarified that source-catalog `risk_flag` baseline must match the scoring canonical output list
- Updated `docs/data/keyword-scoring-v0.md`:
  - added canonical allowed-value list for scoring output `risk_flags`
  - kept stable threshold parameters and backend contract notes for clamping/idempotent uniqueness (`keyword_id`, `as_of_ts`)
- Updated this handoff and resume note with explicit manual consistency-review assertions (not keyword-match evidence only)

## Changed Files
- docs/data/source-catalog.md
- docs/data/keyword-scoring-v0.md
- coordination/handoffs/DATA-001.md
- coordination/resume/DATA-001.md

## Verification
- commands:
  - `Select-String -Path .\docs\data\source-catalog.md -Pattern "30-minute|Contract Enums|risk_flag|event_type|quality_flag|must match scoring output canonical list"`
  - `Select-String -Path .\docs\data\keyword-scoring-v0.md -Pattern "Canonical.*Allowed Values|Contract Notes For Backend|is_alert_eligible|reason_tags|risk_flags"`
  - `Select-String -Path .\docs\product\mvp-scope.md -Pattern "Keyword ranking|Keyword detail|watchlist|Alert rules|Out of Scope"`
  - `Select-String -Path .\docs\architecture\system-overview.md -Pattern "Jobs write derived data|API reads stable derived data|Notification rules are evaluated server-side"`
- result:
  - expected contract phrases and cadence/enums anchors are present in both data docs.
- manual consistency review assertions:
  - MVP workflow fit checked directly: ranking uses `score_total/score_delta_24h`, detail uses `dimension_*` + `reason_tags/risk_flags`, watchlist and alerts use `is_alert_eligible` with documented thresholds.
  - MVP exclusions preserved: no broker execution, no chat guidance, no client-side recompute added in data contracts.
  - Architecture boundary checks passed: jobs produce derived snapshots/events, API reads stable derived data, alert decision remains server-side.
  - Canonical `risk_flags` list is now frozen in one authoritative scoring section and mirrored in source catalog, reducing BE-001 enum drift risk.

## Blockers
- None.

## BE-001 Contract Pressure / Schema Impact
- Introduce enum domains or controlled-value constraints for `event_type`, `quality_flag`, and scoring output `risk_flags`.
- Ensure score snapshot uniqueness on (`keyword_id`, `as_of_ts`) for idempotent score publishes.
- Keep scoring snapshot numeric precision aligned with documented types (`numeric(5,2)`, `numeric(4,3)`).
- Preserve array support for `reason_tags` and `risk_flags` in both schema and API payloads.
- Maintain cadence compatibility: 30-minute timeslice grain and scoring publish schedule.

## Exact Next Step
- QA re-runs DATA-001 review against this handoff and confirms blocker closure.

