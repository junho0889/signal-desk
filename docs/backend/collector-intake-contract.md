# Collector Intake Contract

## Purpose
Define the backend-facing intake contract for payloads shipped from the collector spool to the central host.

## Scope
- central intake endpoint behavior
- acknowledgement semantics
- idempotency behavior
- retry vs rejection rules

## Baseline Central Host
- target host IP in current private network: `192.168.0.200`

## Endpoint
- method: `POST`
- path: `/internal/v1/collector/raw-ingest-batches`
- host target in current private network: `192.168.0.200`
- audience: collector shipper only (not mobile-facing API)

## Request Contract
Top-level request object:
- `batch_id` (`string`, required): collector-generated stable id for this ship attempt group
- `collector_node_id` (`string`, required): stable node identifier
- `sent_at` (`string`, required): RFC3339 UTC timestamp
- `items` (`array`, required, non-empty)

`items[]` envelope (required unless noted):
- `spool_item_id` (`string`): collector-local stable record id for correlation
- `source_id` (`string`)
- `collected_at` (`string`): collector receive timestamp in UTC
- `upstream_event_at` (`string`, nullable): event timestamp from source when available
- `payload_hash` (`string`): deterministic content hash from collector
- `payload_version` (`string`): parser/schema revision for payload format
- `payload_json` (`object`): raw normalized JSON blob as captured by collector
- `retry_count` (`integer`): current collector retry counter
- `transport_status` (`string`, optional): collector-side state at send time

## Intake Response Classes
Per item, backend must return exactly one class:
- `accepted`
  - raw payload persisted centrally
  - safe for collector to mark delivered
- `duplicate`
  - payload already known centrally under the same idempotency scope
  - safe for collector to mark delivered
- `rejected`
  - structurally invalid or violates non-retryable rules
  - collector should move to dead-letter, not retry as-is
- `retryable_failure`
  - transient backend failure prevented durable persistence
  - collector should retry with backoff

Top-level response fields:
- `request_id` (`string`, nullable)
- `batch_id` (`string`, required)
- `batch_status` (`accepted|partially_accepted|rejected|retryable_failure`, required)
- `summary` (`object`, required):
  - `received_count`
  - `accepted_count`
  - `duplicate_count`
  - `rejected_count`
  - `retryable_failure_count`
- `items` (`array`, required): one row per submitted `spool_item_id` (or index fallback)

`items[]` result fields:
- `spool_item_id` (`string`, nullable)
- `payload_hash` (`string`, required)
- `status` (`accepted|duplicate|rejected|retryable_failure`, required)
- `reason_code` (`string`, required)
- `message` (`string`, nullable)
- `ingest_ref` (`string`, nullable): central ingest identifier when known

## Idempotency
- item-level idempotency key: `collector_node_id + source_id + payload_hash + payload_version`
- batch-level replay key: `collector_node_id + batch_id`
- resubmitting an identical batch must return stable per-item outcomes (`accepted` may become `duplicate`)
- duplicate detection must not create additional canonical raw rows

## Acknowledgement Classes And Retry Policy
Collector action by class:
- `accepted`: mark delivered, prune per collector retention rules
- `duplicate`: mark delivered, prune per collector retention rules
- `rejected`: mark `dead_letter` (non-retryable as-is)
- `retryable_failure`: keep pending and retry with backoff

Retryability by backend outcome:
- retryable:
  - network timeout / connection reset
  - HTTP `429`
  - HTTP `500`, `502`, `503`, `504`
  - per-item `retryable_failure`
- non-retryable as-is:
  - HTTP `400` with schema/validation errors
  - HTTP `401`/`403` credential or authorization failures (requires operator/config fix)
  - HTTP `413` payload too large (requires split/batch-size adjustment)
  - per-item `rejected`

## Batch And Partial-Success Expectations
- backend may return mixed per-item statuses in one batch
- collector must process acknowledgement per item, not only top-level batch status
- if response is non-2xx or unreadable, collector retries the full batch idempotently
- if response is 2xx with `items[]`, collector retries only `retryable_failure` items

## Backend/Storage Coordination Notes
Central raw-ingest persistence must retain these logical fields (table/schema names stay open to BE-004):
- collector envelope fields (`collector_node_id`, `spool_item_id`, `source_id`, timestamps, `payload_version`, `payload_hash`)
- raw payload body (`payload_json`)
- ingest processing metadata (`ingest_ref`, first_seen/last_seen, duplicate counter, last_status, last_reason_code)
- batch replay metadata (`batch_id`, request timestamp, request_id when available)

This contract intentionally avoids freezing:
- final PostgreSQL schema/table names
- exact partitioning strategy
- final authentication mechanism implementation details
