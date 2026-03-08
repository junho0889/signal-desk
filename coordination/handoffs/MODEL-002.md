## Task
- id: MODEL-002
- owner: signal-desk-model
- status: done

## What Changed
- created `docs/model/model-system-v1.md` as the v1 production model contract
- updated `docs/model/ranking-roadmap.md` to align phase promotion with online publish-safety gates
- froze online pipeline stages from normalized/trust inputs through immutable publish runs
- defined offline research boundary and promotion requirements
- defined required artifact families, run-state machine, publish-safety thresholds, and regression rules

## Current State
- explainable shipping model path is explicit and deterministic
- model outputs are now specified as manifest-backed artifacts instead of implicit score rows
- publish behavior is constrained by terminal run states (`published`, `published_degraded`, `blocked`)

## Assumptions For Downstream Lanes

### `BE-006` should assume:
- required persisted artifacts:
  - `feature_snapshot`
  - `feature_run_manifest`
  - `ranking_score_record`
  - `ranking_run_manifest`
  - `explanation_artifact`
  - `evaluation_snapshot`
  - `publish_run_manifest`
- required run states:
  - `feature_run`: `scheduled|running|completed|failed`
  - `ranking_run`: `pending_feature_run|running|completed|failed`
  - `publish_run`: `pending_gate|published|published_degraded|blocked|failed`
- terminal run states are immutable; reruns create new run ids

### `BE-007` should assume:
- only terminal publish runs are API-visible (`published`, `published_degraded`)
- additive publish metadata is required for UI/ops:
  - `publish_state`
  - `degraded_reasons[]`
- existing alias semantics stay frozen:
  - `score`
  - `delta_1d`

### `QA-006` should assume:
- publish-safety threshold registry exists and must be validated:
  - `min_active_keywords_for_publish = 30`
  - `confidence_min_for_alert = 0.55`
  - `max_source_staleness_minutes_critical = 360`
  - `max_missing_trust_ratio_for_full_publish = 0.10`
  - `max_missing_trust_ratio_for_degraded_publish = 0.35`
  - `explanation_coverage_min_ratio = 1.00`
- hard-block behavior and degraded publish behavior both require explicit test coverage
- canonical `risk_flags` literals must be enforced in publishable outputs

## Verification
- commands:
  - `git -C E:\source\signal-desk-worktrees\model-002 diff --check`
  - consistency review against:
    - `docs/backend/storage-expansion-outline.md`
    - `docs/trust/trust-framework.md`
    - `docs/backend/collector-intake-contract.md`
- result:
  - `git diff --check` passed (no whitespace errors)
  - model docs align with storage artifact families, trust-aware gating, and collector freshness/watermark assumptions

## Blockers
- `BE-004` not accepted yet, so artifact persistence is contract-frozen but not yet physically implemented
- `TRUST-001` not accepted yet, so trust feature details may still refine while preserving this publish-state contract

## Next Step
- orchestrator should dispatch implementation and verification lanes in order:
  - `BE-006` artifact persistence and run-state implementation
  - `BE-007` API/read-model exposure for terminal publish states
  - `QA-006` publish-safety and explainability contract verification

## Files Touched
- `docs/model/model-system-v1.md`
- `docs/model/ranking-roadmap.md`
- `coordination/tasks.yaml`
- `coordination/dispatches/MODEL-002.md`
- `coordination/handoffs/MODEL-002.md`
- `coordination/resume/MODEL-002.md`
