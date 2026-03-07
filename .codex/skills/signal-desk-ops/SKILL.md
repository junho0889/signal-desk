---
name: signal-desk-ops
description: Operate and ship the SignalDesk service. Use when planning deployment, runtime topology, schedules, monitoring, release checks, or operational tradeoffs for the SignalDesk project.
---

# SignalDesk Ops

Read `AGENTS.md`, `docs/ops/deploy-runbook.md`, and `docs/ops/service-model.md` first.

## Operate
- Prefer low-overhead managed services while the product remains personal-use.
- Monitor freshness of derived data, not only host uptime.
- Treat job reliability and contract stability as release blockers.
- Keep release steps deterministic and reversible.

## References
- Architecture: `docs/architecture/system-overview.md`
- Backend: `docs/backend/api-contract.md`, `docs/backend/db-schema.md`
- Coordination: `coordination/tasks.yaml`, `coordination/decision-log.md`
