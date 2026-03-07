# Dispatch DATA-001

## Task
- id: DATA-001
- owner role: signal-desk-data
- priority: high

## Objective
Define a stable source catalog and scoring model v0 that backend contract work can implement without changing product scope assumptions.

## Required Reads
- `AGENTS.md`
- `coordination/working-agreement.md`
- `coordination/checkpoint-policy.md`
- `coordination/resume-template.md`
- `.codex/skills/signal-desk-data/SKILL.md`
- `docs/product/vision.md`
- `docs/product/mvp-scope.md`
- `docs/data/source-catalog.md`
- `docs/data/keyword-scoring-v0.md`
- `docs/backend/postgres-security.md`

## Files You Own
- `docs/data/source-catalog.md`
- `docs/data/keyword-scoring-v0.md`

## Dependencies
- `PROD-001` complete
- `SEC-001` complete

## Deliverables
- source list with cadence, ingestion constraints, and fallback behavior
- scoring dimensions with normalization approach and weight rationale
- explicit quality risks, confidence rules, and anti-noise guardrails

## Verification
- run: manual consistency review against `docs/product/mvp-scope.md` and `docs/architecture/system-overview.md`
- expected: scoring inputs and output fields support MVP ranking, detail, watchlist, and alert workflows without adding out-of-scope features

## Checkpoint And Push Requirements
- create a checkpoint commit after any substantial source change, feature addition, or defect fix
- use commit messages that start with `DATA-001`
- push every reviewable checkpoint before pausing unless blocked, then record the exact command and error

## Pause And Resume Requirements
- before pausing, write a handoff in `coordination/handoffs/` with current state, blockers, and next step
- before pausing an unfinished task, update `coordination/resume/DATA-001.md` using `coordination/resume-template.md`

## Handoff
- summarize catalog and scoring changes
- flag inputs that create schema or API pressure for `BE-001`
- report verification commands and outcomes
- report unresolved assumptions or blockers
