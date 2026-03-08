# Collector Runtime V1

## Purpose
Define the collector v1 runtime as a PC-first Docker Compose stack with local PostgreSQL spool durability, no RabbitMQ, and a later promotion path to Ubuntu on Raspberry Pi 4B 8GB.

## Frozen V1 Decisions (COL-002)
- run collector v1 first on the current PC as an isolated Docker Compose project group
- use local PostgreSQL as the only spool and delivery-state store
- do not add RabbitMQ in v1
- central delivery target host is `192.168.0.200`
- central host can be offline for long windows; collector continues collecting and buffering
- retain undelivered and dead-letter spool records for 30 days
- keep runtime boundaries portable so the same stack can be packaged on Ubuntu for Raspberry Pi 4B 8GB

## Why No RabbitMQ In V1
- local spool durability and replayability matter more than broker semantics right now
- raw payload auditability is simpler with explicit database state
- the main risk is long offline windows on the central host, which spool tables handle directly
- avoid introducing another stateful service before the collector contract is proven

## Runtime Components (Compose Services)
- `collector-db`
  - local PostgreSQL instance for spool records and shipping state transitions
  - stores 30-day retryable/dead-letter history and prune metadata
- `collector-runner`
  - executes source adapters on source-specific schedule
  - writes raw payload envelope rows into `collector-db`
- `collector-shipper`
  - leases pending rows, calls central intake, and applies acknowledgement responses
  - manages retry scheduling and dead-letter transitions
- optional `collector-monitor`
  - surfaces queue depth, oldest pending age, retry pressure, and last successful acknowledgement time

No broker service is part of v1.

## Local Development Target
- run on this PC as a separate Compose project from the main app stack
- keep networks and volumes isolated from `infra/local/docker-compose.yml`
- use this environment to verify restart behavior, offline buffering, and replay

## Spool Database Contract (Local PostgreSQL)
Spool state is recorded in `collector-db` with mutable status plus immutable payload identity.

### Required Envelope And State Fields
- `spool_id` (UUID)
- `source_id`
- `collected_at_utc`
- `upstream_event_ts_utc` (nullable)
- `idempotency_key`
- `payload_hash_sha256`
- `payload_version`
- `payload_json`
- `retry_count`
- `last_attempt_at_utc` (nullable)
- `next_attempt_at_utc`
- `last_error_code` (nullable)
- `status` (`pending`, `shipping`, `accepted`, `duplicate`, `rejected`, `dead_letter`)
- `ack_code` (`accepted`, `duplicate`, `rejected`, `retryable_failure`, nullable before response)
- `ack_id` (nullable)
- `acked_at_utc` (nullable)
- `prune_after_utc`

### State Transition Rules
- `pending -> shipping`: shipper acquires lease for delivery attempt.
- `shipping -> accepted|duplicate`: central acknowledgement proves durable or idempotent success.
- `shipping -> pending`: timeout or `retryable_failure` response.
- `shipping -> rejected`: non-retryable contract violation from central intake.
- `pending|shipping -> dead_letter`: retry budget exhausted before success.

## Retention
- retain `pending`, `shipping`, `rejected`, and `dead_letter` rows for up to 30 days from `collected_at_utc`
- `accepted` and `duplicate` rows may be pruned earlier, but only after central acknowledgement is persisted
- prune jobs must not delete rows younger than 30 days when status is not centrally acknowledged success

## Offline Central Host Behavior (`192.168.0.200`)
- collection cycles continue while central host is unreachable
- `collector-shipper` retries with bounded backoff and jitter
- oldest pending age and queue depth are treated as primary health indicators
- when backlog pressure rises, system prioritizes primary polling and can defer non-critical backfill cycles

## Required Backend Coordination
- align to backend intake response classes in `docs/backend/collector-intake-contract.md`:
  - `accepted`
  - `duplicate`
  - `rejected`
  - `retryable_failure`
- preserve central idempotency and acknowledgement identity expectations
- keep collector role separated from central ranking/API/database authority

## Promotion Path To Ubuntu On Raspberry Pi
Keep collector runtime packaging compatible between PC and Pi by changing deployment context, not service boundaries.

### Keep Stable
- Compose service split: `collector-db`, `collector-runner`, `collector-shipper`, optional `collector-monitor`
- spool schema and state machine
- environment variable contract and secrets model

### Change For Pi Packaging
- image platform target for ARM where required
- host path mappings and volume sizing
- systemd or runbook wrapper for boot-time Compose startup on Ubuntu
