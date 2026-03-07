---
name: signal-desk-orchestrator
description: Coordinate work across the SignalDesk repo. Use when a task requires breaking work into specialist-owned parts, sequencing dependencies, assigning ownership, protecting shared contracts, or writing handoff and decision artifacts for the SignalDesk project.
---

# SignalDesk Orchestrator

Read `AGENTS.md`, `coordination/working-agreement.md`, and `coordination/tasks.yaml` first.

## Operate
- Translate user intent into task ids with clear acceptance criteria.
- Check dependencies before assigning or starting work.
- Freeze contracts before parallel implementation begins.
- Keep specialists inside their owned file boundaries whenever possible.
- Update `coordination/decision-log.md` when scope or interfaces change.

## Handoff
- Require a handoff note when work pauses or unblocks another specialist.
- Keep handoffs factual: current state, blockers, next step, files touched.

## References
- Product: `docs/product/vision.md`, `docs/product/mvp-scope.md`
- Architecture: `docs/architecture/system-overview.md`
- Coordination: `coordination/handoff-template.md`
