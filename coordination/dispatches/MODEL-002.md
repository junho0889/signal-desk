# Dispatch MODEL-002

## Task
- id: MODEL-002
- owner role: signal-desk-model
- priority: high

## Objective
Define the first production-safe model system for SignalDesk, including the online ranking pipeline, offline research boundary, explainability contract, and required artifacts.

## Required Reads
- `AGENTS.md`
- `coordination/working-agreement.md`
- `docs/data/keyword-scoring-v0.md`
- `docs/model/ranking-roadmap.md`
- `docs/model/model-system-v1.md`
- `docs/backend/storage-expansion-outline.md`
- `docs/trust/trust-framework.md`
- `docs/backend/collector-intake-contract.md`
- `coordination/handoffs/MODEL-001.md` when available
- `coordination/handoffs/BE-004.md` when available
- `coordination/handoffs/TRUST-001.md` when available

## Files You Own
- `docs/model/model-system-v1.md`
- `docs/model/ranking-roadmap.md`

## Deliverables
- explicit online path from normalized inputs to immutable publish runs
- explainable shipping-model definition and offline research boundary
- label strategy, evaluation artifacts, and publish-safety rules that downstream lanes can implement against

## Constraints
- keep phase-one production ranking explainable and reproducible
- do not treat deep learning as the shipping baseline
- define outputs that app, backend, and QA can verify without hidden state

## Verification
- document consistency review against storage, trust, and collector contracts
- `git diff --check`

## Handoff
- identify which artifacts, thresholds, and run states `BE-006`, `BE-007`, and `QA-006` should assume next
