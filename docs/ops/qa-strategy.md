# QA Strategy

## Purpose
QA exists to find defects, contradictions, missing tests, and broken assumptions before work is considered complete.

## QA Responsibilities
- review diffs and handoffs for risk
- reproduce reported bugs when practical
- run required checks and targeted regression checks
- report defects with severity and reproduction notes
- confirm that fixes were retested

## QA Trigger Points
- after any user-facing screen or flow changes
- after API or database contract changes
- before Docker or deployment changes are marked ready
- before orchestrator gives project completion sign-off

## Defect Severity
- `sev-1`: blocks progress or corrupts data
- `sev-2`: major behavior mismatch or missing verification
- `sev-3`: minor defect, copy issue, or low-risk inconsistency

## QA Output
- handoff note with commands run and results
- blocker note when a defect prevents acceptance
- follow-up task ids when broader regression work is needed

## Minimum Regression Areas
- product docs remain consistent with architecture and contracts
- backend contract changes are reflected in data and design docs
- Docker and database setup instructions still match checked-in files
- app flows map to existing API payloads
