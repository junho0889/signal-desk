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

## Required Collector Envelope
- `source_id`
- `collected_at`
- `upstream_event_at` when available
- `payload_hash`
- `payload_version`
- `payload_json`
- `retry_count`
- `collector_node_id`

## Intake Response Classes
- `accepted`
  - payload persisted centrally and is safe to mark delivered
- `duplicate`
  - payload already exists centrally; collector can mark delivered without retry
- `rejected`
  - payload is structurally invalid or violates a non-retryable rule
- `retryable_failure`
  - central host could not safely persist; collector should retry later

## Idempotency
- central intake must key on `payload_hash` plus source-level scope needed to avoid accidental collisions
- the same payload submitted multiple times must not create duplicate canonical raw records

## Open Design Questions For Backend Lane
- HTTP path and auth shape
- batch size and partial-success response format
- whether raw storage lands in the same PostgreSQL cluster as normalized storage or a dedicated raw-ingest schema
