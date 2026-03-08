# Raspberry Pi Collector Node

## Purpose
Provide a dedicated always-on collection node using Raspberry Pi 4B 8GB, separate from the central database and API host.

## Role
- run source collectors 24/7
- spool raw payloads into local PostgreSQL before central delivery
- retry failed deliveries without losing collection evidence
- expose health, backlog, and last-success telemetry
- stay collector-only; never host central ranking, API, or canonical storage

## Recommended Node Profile
- Raspberry Pi 4B 8GB
- SSD-backed storage preferred over SD-card-only operation
- wired Ethernet preferred
- UPS or equivalent power resilience preferred for overnight collection

## Explicit Non-Goals
- do not run the primary PostgreSQL instance on the Pi
- do not run heavy ranking/model workloads on the Pi
- do not make the Pi the only copy of raw collected payloads
- do not introduce RabbitMQ in collector v1

## V1 Runtime Shape (PC First, Then Pi)
Collector v1 is implemented first on the current PC using a dedicated Docker Compose group, then promoted to Ubuntu on Raspberry Pi with the same service split.

### Required Services
- `collector-db`: local PostgreSQL spool state
- `collector-runner`: source polling/webhook handling and spool inserts
- `collector-shipper`: transfer retries and central acknowledgement processing
- optional `collector-monitor`: queue and delivery health output

No RabbitMQ service is part of v1.

## Delivery Modes To Support
- direct central intake API
- file or object upload into a shared intake location
- deferred resend when central network is unavailable

## Central Host Baseline
- main server target IP: `192.168.0.200`
- collector should tolerate the central host being offline for long workday windows
- local spool retention baseline: 30 days before prune eligibility for unacknowledged or dead-letter rows

## Spool State Baseline
- local spool is PostgreSQL-backed, not file queue or broker-backed
- expected state values:
  - `pending`
  - `shipping`
  - `accepted`
  - `duplicate`
  - `rejected`
  - `dead_letter`
- central response classes must map to:
  - `accepted` -> delivered success
  - `duplicate` -> delivered idempotent success
  - `rejected` -> non-retryable failure
  - `retryable_failure` or timeout -> retry path back to `pending`

## Retention And Prune Baseline
- keep undelivered (`pending`/`shipping`) and dead-letter rows for 30 days from collection time
- allow earlier pruning for `accepted` and `duplicate` only after acknowledgement metadata is stored
- never prune by age alone if acknowledgement outcome is unresolved

## Operational Signals
- spool database size
- oldest unshipped payload age
- source success rate
- source error rate
- last successful ship timestamp
- dead-letter count
- retry-exhaustion count over rolling 24h

## Security Notes
- Pi holds only the minimum credentials required to ship payloads centrally
- central authority remains on the main host
- secrets must stay outside version control

## Promotion To Ubuntu On Raspberry Pi
- preserve the same Compose boundaries used in PC-first development
- port by changing only platform-specific settings (ARM image target, host paths, startup wrapper)
- keep runtime behavior, spool schema, and central acknowledgement semantics identical between PC and Pi
