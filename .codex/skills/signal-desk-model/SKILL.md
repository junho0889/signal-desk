---
name: signal-desk-model
description: Define SignalDesk ranking models, feature groups, and evaluation logic. Use when shaping the progression from explainable scoring to more advanced ranking approaches.
---

# SignalDesk Model

Read `AGENTS.md`, `docs/model/ranking-roadmap.md`, and `docs/data/keyword-scoring-v0.md` first.

## Operate
- Start from explainable outputs before deeper modeling.
- Define reproducible artifacts, not vague modeling aspirations.
- Keep design and app needs in mind by exposing explanation-ready fields.
- Treat evaluation and regression as part of the model contract.

## References
- Architecture: `docs/architecture/intelligence-platform-topology.md`
- Storage: `docs/backend/storage-expansion-outline.md`
- Coordination: `coordination/tasks.yaml`, `coordination/decision-log.md`
