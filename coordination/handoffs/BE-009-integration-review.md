## BE-009 Integration Review Scope
Review only these BE-009 contract areas:
- item-level intake validation outcomes
- quarantine behavior
- replay/resubmission behavior

Out of scope for this review:
- auth implementation details
- physical DB table naming
- collector scheduling/runtime orchestration
- mobile/public `/v1` endpoint redesign

## Frozen Contract References
- intake validation stages and rules:
  - `docs/backend/collector-intake-contract.md`
  - sections: `Validation Stages`, `Metadata Validation Rules (V1)`
- item-level response contract:
  - `docs/backend/collector-intake-contract.md`
  - section: `Batch Response Contract`
- collector action per status and replay semantics:
  - `docs/backend/collector-intake-contract.md`
  - sections: `Collector Action Expectations By Status`, `Replay And Resubmission Semantics`
- mirrored internal API assumptions:
  - `docs/backend/api-contract.md`
  - section: `Internal Collector Intake API`

## Item-Level Outcome Matrix To Validate
- `accepted`: valid and persisted, non-retry
- `accepted_degraded`: persisted with downgrade, non-retry
- `duplicate`: idempotent replay, non-retry
- `quarantined`: persisted for audit/replay, non-retry blind loop
- `rejected`: dead-letter path, non-retry as-is
- `retryable_failure`: transient failure, retry with backoff

## Required QA/Integration Assertions
- each item has explicit `status`, `reason_code`, `retryable`
- non-accepted items never rely on generic error reasons
- quarantined and rejected items remain replay-auditable
- duplicate submissions do not create duplicate canonical raw records
- top-level batch status never overrides item-level decisions
