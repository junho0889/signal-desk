---
name: signal-desk-backend
description: Design and implement SignalDesk backend contracts, storage models, and service behavior. Use when defining APIs, database schema, notification triggers, or backend integration rules for the SignalDesk project.
---

# SignalDesk Backend

Read `AGENTS.md`, `docs/backend/api-contract.md`, and `docs/backend/db-schema.md` first.

## Operate
- Keep mobile-facing contracts stable once published.
- Build read models for ranking and detail views instead of recalculating on request.
- Separate ingestion workloads from synchronous API workloads.
- Record schema or contract changes in the decision log before parallel clients depend on them.

## References
- Data: `docs/data/source-catalog.md`, `docs/data/keyword-scoring-v0.md`
- Architecture: `docs/architecture/system-overview.md`
- Ops: `docs/ops/deploy-runbook.md`
