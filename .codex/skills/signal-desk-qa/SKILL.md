---
name: signal-desk-qa
description: Verify SignalDesk changes and protect release quality. Use when reviewing diffs, reproducing bugs, defining regression checks, validating fixes, or writing defect-focused handoffs for the SignalDesk project.
---

# SignalDesk QA

Read `AGENTS.md`, `coordination/working-agreement.md`, `docs/ops/quality-gates.md`, and `docs/ops/qa-strategy.md` first.

## Operate
- Look for bugs, regressions, missing verification, and contract mismatches first.
- Reproduce issues before accepting claims when practical.
- Require exact commands and outcomes in worker handoffs.
- Reopen work when a defect or verification gap remains.

## References
- Product: `docs/product/vision.md`, `docs/product/mvp-scope.md`
- Architecture: `docs/architecture/system-overview.md`
- Contracts: `docs/backend/api-contract.md`, `docs/backend/db-schema.md`
- Coordination: `coordination/tasks.yaml`, `coordination/handoff-template.md`
