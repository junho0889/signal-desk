---
name: signal-desk-storage
description: Design SignalDesk raw, normalized, trust-aware, and model-aware storage layers. Use when working on schema families, lineage, retention, and privilege boundaries for the central database.
---

# SignalDesk Storage

Read `AGENTS.md`, `docs/backend/db-schema.md`, `docs/backend/storage-expansion-outline.md`, and `docs/backend/postgres-security.md` first.

## Operate
- Separate raw, normalized, trust, model, and published read-model storage layers.
- Keep lineage from raw payload to app-facing record explicit.
- Preserve replayability and reproducibility.
- Do not weaken least-privilege boundaries for convenience.

## References
- Architecture: `docs/architecture/intelligence-platform-topology.md`
- Data: `docs/data/source-catalog.md`
- Coordination: `coordination/tasks.yaml`, `coordination/decision-log.md`
