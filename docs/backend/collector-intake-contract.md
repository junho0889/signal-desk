# Collector Intake Contract

## Purpose
Define the backend-facing intake contract for payloads shipped from the collector spool to the central host.

## Scope
- central intake endpoint behavior
- acknowledgement semantics
- idempotency behavior
- retry vs rejection rules
- metadata validation, downgrade, and quarantine behavior

## Baseline Central Host
- target host IP in current private network: `192.168.0.200`

## Endpoint
- method: `POST`
- path: `/internal/v1/collector/raw-ingest-batches`
- audience: collector shipper only (internal contract, not mobile/public API)

## Request Contract
Top-level request fields:
- `batch_id` (`string`, required)
- `collector_node_id` (`string`, required)
- `sent_at` (`string`, required, RFC3339 UTC)
- `items` (`array`, required, non-empty)

`items[]` envelope fields:
- `spool_item_id` (`string`, required)
- `source_id` (`string`, required)
- `source_category` (`string`, required)
- `collected_at` (`string`, required, RFC3339 UTC)
- `upstream_event_at` (`string`, nullable)
- `publisher_name` (`string`, required)
- `publisher_domain` (`string`, required)
- `canonical_url` (`string`, required)
- `external_id` (`string`, nullable)
- `payload_hash` (`string`, required)
- `payload_version` (`string`, required)
- `language` (`string`, required)
- `market_scope` (`string`, required)
- `title` (`string`, required)
- `raw_payload_json` (`object`, required)
- `retry_count` (`integer`, required)
- `transport_status` (`string`, nullable)

## Intake Response Classes
- `accepted`
  - payload passed validation and persisted as normal-quality evidence
- `accepted_degraded`
  - payload persisted but downgraded due to weak metadata quality
  - collector marks delivered; central quality state remains degraded for downstream trust/ranking
- `duplicate`
  - payload already exists under idempotency scope
  - collector can mark delivered without retry
- `quarantined`
  - payload persisted in quarantine state for audit/replay, excluded from normal publish path
  - collector marks delivered (do not retry same payload blindly)
- `rejected`
  - payload failed structural or mandatory metadata validation
  - collector marks dead-letter (non-retryable as-is)
- `retryable_failure`
  - transient backend or storage issue prevented durable persistence
  - collector retries with backoff

## Validation Stages
Central intake evaluates each item in order:
1. envelope/schema validation
2. metadata completeness and quality validation
3. idempotency/duplicate check
4. persistence decision (normal, degraded, quarantine, dead-letter, retry)

Validation decisions must be item-level and explicit in response payload.

## Metadata Validation Rules (V1)
Hard reject rules (`rejected`):
- missing: `source_id`, `collected_at`, `publisher_name`, `canonical_url`, or `payload_hash`
- malformed timestamp or invalid JSON envelope shape
- malformed URL with no recoverable canonical form

Downgrade rules (`accepted_degraded`):
- missing `upstream_event_at` for a source that is expected to provide it
- unknown/unsupported `language`
- incomplete optional metadata that does not break replayability

Quarantine rules (`quarantined`):
- metadata is present but indicates high-risk ambiguity (for example domain mismatch, inconsistent source identity, or unresolved mapping-critical fields)
- payload must remain audit-visible and replayable

Duplicate rules (`duplicate`):
- matching idempotency key and previously persisted intake state
- duplicate does not create a second canonical raw row

Transient backend rules (`retryable_failure`):
- storage timeout/unavailable, transaction abort, lock timeout, or temporary dependency failure

## Idempotency
- item-level key: `collector_node_id + source_id + payload_hash + payload_version`
- batch replay key: `collector_node_id + batch_id`
- resubmitting the same item must return stable behavior:
  - `accepted` may transition to `duplicate`
  - `accepted_degraded` may transition to `duplicate` unless metadata changed under a new payload hash/version
  - `quarantined` may remain `quarantined` until operator/policy clears it
- no duplicate canonical raw rows for the same idempotency key

## Batch Response Contract
Top-level response fields:
- `request_id` (`string`, nullable)
- `batch_id` (`string`, required)
- `batch_status` (`accepted|partially_accepted|rejected|retryable_failure`, required)
- `summary` (`object`, required):
  - `received_count`
  - `accepted_count`
  - `accepted_degraded_count`
  - `duplicate_count`
  - `quarantined_count`
  - `rejected_count`
  - `retryable_failure_count`
- `items` (`array`, required)

`items[]` response fields:
- `spool_item_id` (`string`, required)
- `payload_hash` (`string`, required)
- `status` (`accepted|accepted_degraded|duplicate|quarantined|rejected|retryable_failure`, required)
- `quality_state` (`accepted|accepted_degraded|duplicate|stale_source|metadata_incomplete|mapping_low_confidence|quarantined|dead_letter`, nullable)
- `reason_code` (`string`, required, machine-readable and non-generic)
- `retryable` (`boolean`, required)
- `message` (`string`, nullable, user-safe/operator-readable)
- `ingest_ref` (`string`, nullable)

## Required Reason-Code Behavior
- every non-`accepted` item must return a specific `reason_code`
- examples:
  - `missing_required_field`
  - `invalid_timestamp`
  - `invalid_canonical_url`
  - `metadata_incomplete`
  - `source_identity_mismatch`
  - `duplicate_payload`
  - `storage_timeout`
  - `storage_unavailable`
- do not collapse validation outcomes into one generic code

## Collector Action Expectations By Status
- `accepted`, `accepted_degraded`, `duplicate`, `quarantined`:
  - mark delivered (no blind retry loop)
- `rejected`:
  - mark dead-letter and do not retry as-is
- `retryable_failure`:
  - keep pending and retry with backoff

## Replay And Resubmission Semantics
- quarantined and rejected payloads must retain enough metadata for audit and deterministic replay decisions
- resubmission is allowed after metadata correction using a new payload hash/version
- publish pipelines must ignore quarantined/dead-letter evidence unless explicitly replay-cleared

## Alignment With Storage Quality States
Central intake status must map to storage quality states used by downstream lanes:
- `accepted` -> `accepted`
- `accepted_degraded` -> `accepted_degraded` or `metadata_incomplete`
- `duplicate` -> `duplicate`
- `quarantined` -> `quarantined`
- `rejected` -> `dead_letter`
- `retryable_failure` -> no terminal quality state until persistence succeeds

Storage table names and physical schema remain BE-008 implementation details, but this mapping is frozen for backend/collector/QA contract testing.
