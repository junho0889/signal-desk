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

## Collector Runtime Responsibilities
- per-source scheduler
- source adapter execution
- raw payload spool writes
- delivery retry queue
- heartbeat and queue depth logs

## Delivery Modes To Support
- direct central intake API
- file or object upload into a shared intake location
- deferred resend when central network is unavailable

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
