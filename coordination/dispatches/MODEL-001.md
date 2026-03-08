# Dispatch MODEL-001

## Task
- id: MODEL-001
- owner role: signal-desk-model
- priority: high

## Objective
Define the ranking lane from explainable baseline scoring through later model evolution, including feature groups, output contracts, and evaluation.

## Required Reads
- `AGENTS.md`
- `coordination/working-agreement.md`
- `docs/data/keyword-scoring-v0.md`
- `docs/model/ranking-roadmap.md`
- `docs/architecture/intelligence-platform-topology.md`
- `docs/backend/storage-expansion-outline.md`
- `coordination/handoffs/BE-004.md` when available

## Files You Own
- `docs/model/ranking-roadmap.md`

## Deliverables
- ranking phase plan from rules to learned ranking
- feature groups and output artifacts
- evaluation, regression, and reproducibility guidance

## Constraints
- keep the first shipping model explainable
- do not assume deep learning is phase one
- define outputs in a way that design and app lanes can surface clearly

## Verification
- document consistency review against data and storage docs
- `git diff --check`

## Handoff
- identify which feature and output fields downstream lanes should expect next
