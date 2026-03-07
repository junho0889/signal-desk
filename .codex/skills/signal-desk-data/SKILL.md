---
name: signal-desk-data
description: Design SignalDesk data ingestion, normalization, entity mapping, and scoring logic. Use when working on keyword sources, scoring formulas, derived datasets, refresh cadence, or data quality rules for the SignalDesk project.
---

# SignalDesk Data

Read `AGENTS.md`, `docs/data/source-catalog.md`, and `docs/data/keyword-scoring-v0.md` first.

## Operate
- Favor explainable, auditable rules before adding complex models.
- Separate raw ingestion from derived ranking outputs.
- Track confidence and risk flags, not only headline scores.
- Treat entity resolution and duplicate suppression as first-class quality problems.

## References
- Architecture: `docs/architecture/system-overview.md`
- Backend contracts: `docs/backend/db-schema.md`, `docs/backend/api-contract.md`
- Coordination: `coordination/tasks.yaml`, `coordination/decision-log.md`
