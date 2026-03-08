# Raspberry Pi Collector Node

## Purpose
Provide a dedicated always-on collection node using Raspberry Pi 4B 8GB, separate from the central database and API host.

## Role
- run source collectors 24/7
- spool raw payloads locally before central delivery
- retry failed deliveries without losing collection evidence
- expose health, backlog, and last-success telemetry

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

## Collector Runtime Responsibilities
- per-source scheduler
- source adapter execution
- raw payload spool writes into local PostgreSQL
- delivery retry queue
- heartbeat and queue depth logs

## Delivery Modes To Support
- direct central intake API
- file or object upload into a shared intake location
- deferred resend when central network is unavailable

## Central Host Baseline
- main server target IP: `192.168.0.200`
- collector should tolerate the central host being offline for long workday windows
- local spool retention baseline: up to 30 days before pruning or operator intervention

## Development First
- first runtime target is the current PC using a separate Docker Compose project group
- later deployment target is Ubuntu on Raspberry Pi with the same container boundaries
- keep the runtime packaging close enough that the PC compose stack can be promoted to Pi with environment and path changes only

## Operational Signals
- spool directory size
- oldest unshipped payload age
- source success rate
- source error rate
- last successful ship timestamp

## Security Notes
- Pi holds only the minimum credentials required to ship payloads centrally
- central authority remains on the main host
- secrets must stay outside version control
