# Dispatch PROD-001

## Task
- id: PROD-001
- owner role: signal-desk-product
- priority: high

## Objective
Lock the product vision and MVP boundaries tightly enough that data, backend, and design work can proceed without re-litigating scope.

## Required Reads
- `AGENTS.md`
- `coordination/working-agreement.md`
- `.codex/skills/signal-desk-product/SKILL.md`
- `docs/product/vision.md`
- `docs/product/mvp-scope.md`
- `docs/architecture/system-overview.md`

## Files You Own
- `docs/product/vision.md`
- `docs/product/mvp-scope.md`

## Dependencies
- `ORCH-002` complete

## Deliverables
- clarified primary user and review workflow
- explicit MVP feature boundaries
- explicit non-goals and release-1 exclusions

## Verification
- run: review docs for contradictions with `docs/architecture/system-overview.md`
- expected: product scope does not conflict with current system direction

## Checkpoint And Push Requirements
- create a checkpoint commit after any substantial source change, feature addition, or defect fix
- use commit messages that start with `PROD-001`
- push every reviewable checkpoint before pausing unless blocked, then record the exact command and error

## Pause And Resume Requirements
- before pausing, write a handoff in `coordination/handoffs/` with current state, blockers, and next step
- before pausing an unfinished task, update `coordination/resume/<TASK-ID>.md` using `coordination/resume-template.md`

## Handoff
- summarize scope changes
- flag anything that blocks `DATA-001` or `UX-001`
- report what remains uncertain

