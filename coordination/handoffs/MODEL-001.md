## Task
- id: MODEL-001
- owner: signal-desk-model
- status: done

## What Changed
- rewrote `docs/model/ranking-roadmap.md` from a starter outline into a concrete ranking contract
- defined phased roadmap `P0` through `P4` with model family, label strategy, explainability requirements, and promotion gates
- defined feature groups (`A` to `F`) spanning freshness, attention, market, events, persistence/regime, and trust signals
- defined output artifacts and field-level contracts for:
  - `ranking_publish_v1` (shipping-compatible)
  - `ranking_publish_v1_plus` (additive next fields)
  - `explanation_artifact_v1`
  - `ranking_run_manifest_v1`
  - `evaluation_snapshot_v1`
- added evaluation and regression plan with phase-specific metrics, promotion thresholds, and reproducibility rules

## Current State
- ranking roadmap now documents explainable-first delivery and non-breaking evolution path to learned ranking
- additive fields are explicitly marked provisional until `BE-004` freezes storage schema
- downstream lanes now have named output artifacts and required metadata to plan UI and API integration

## Verification
- commands:
  - `git -C E:\source\signal-desk-worktrees\model-001 diff --check`
  - consistency review against:
    - `docs/data/keyword-scoring-v0.md`
    - `docs/backend/storage-expansion-outline.md`
    - `docs/backend/api-contract.md`
- result:
  - `git diff --check` passed with no whitespace errors
  - roadmap keeps existing v1 scoring fields/semantics intact and introduces only additive next fields
  - roadmap dependencies and artifact families align with storage expansion outline

## Blockers
- `BE-004` handoff not yet available; physical persistence details for new artifacts remain provisional
- `TRUST-001` pending for trust-feature group finalization

## Next Step
- backend/storage lane should freeze tables for run manifests, evaluation snapshots, and explanation artifacts during `BE-004`
- design/app lanes can start from these expected next fields:
  - `run_id`
  - `model_version`
  - `ranking_phase`
  - `score_components`
  - `confidence_components`
  - `freshness_minutes`
  - `evidence_counts`
  - `summary_reason`
  - `top_factors[]`

## Files Touched
- `docs/model/ranking-roadmap.md`
- `coordination/tasks.yaml`
- `coordination/handoffs/MODEL-001.md`
- `coordination/resume/MODEL-001.md`
