# Deploy Runbook

## Main App Runtime

### Initial Target
- Mobile: personal Android APK distribution
- API: Docker service (`api`) on private internal network
- Jobs bootstrap: one-time Docker service (`jobs-bootstrap`) for migration, seed, and first alert evaluation
- Jobs runtime: long-running Docker service (`jobs`) on private internal network
- DB: PostgreSQL Docker service (`postgres`) with persistent volume
- Orchestration: Docker Compose on one host

### Current Stack State
- compose file (`infra/local/docker-compose.yml`) defines `postgres`, `jobs-bootstrap`, `api`, `jobs`
- PostgreSQL bootstrap init scripts are mounted from `infra/local/postgres-init`
- API and jobs images are built from repo source (`services/api`, `services/jobs`)
- recurring jobs no longer reuse the `run-once` bootstrap path

### Prerequisites
- Docker Desktop (or Docker Engine + Compose plugin)
- local env file from `infra/local/.env.example`
- non-placeholder credentials for `postgres`, `signaldesk_migrator`, `signaldesk_app`, `signaldesk_readonly`

### Startup Sequence (Deterministic)
1. create env file:
   - `Copy-Item infra/local/.env.example infra/local/.env`
   - replace all placeholder passwords
2. validate compose config:
   - `docker compose -f infra/local/docker-compose.yml --env-file infra/local/.env config`
3. bring up stack:
   - `docker compose -f infra/local/docker-compose.yml --env-file infra/local/.env up -d --build`
4. verify bootstrap and runtime state:
   - `docker compose -f infra/local/docker-compose.yml --env-file infra/local/.env ps`
   - `docker compose -f infra/local/docker-compose.yml --env-file infra/local/.env ps -a jobs-bootstrap`
   - expect `jobs-bootstrap` to finish with `Exited (0)`
   - expect `postgres`, `api`, and `jobs` to become `healthy`
5. inspect logs (startup only):
   - `docker compose -f infra/local/docker-compose.yml --env-file infra/local/.env logs postgres --tail=120`
   - `docker compose -f infra/local/docker-compose.yml --env-file infra/local/.env logs jobs-bootstrap --tail=120`
   - `docker compose -f infra/local/docker-compose.yml --env-file infra/local/.env logs api --tail=120`
   - `docker compose -f infra/local/docker-compose.yml --env-file infra/local/.env logs jobs --tail=120`

## Collector Runtime On This PC

### Purpose
Collector v1 runs as a separate Compose project on this PC so queueing, delivery retry, and offline-central-host scenarios can be tested independently from the main app runtime.

### Planned Collector Compose Group
- planned compose file path: `infra/collector/docker-compose.yml`
- planned env file path: `infra/collector/.env`
- planned project name: `signaldesk-collector`
- planned services:
  - `collector-db`
  - `collector-runner`
  - `collector-shipper`
  - optional `collector-monitor`

### Central Host Assumptions
- central host baseline IP remains `192.168.0.200`
- collector delivery traffic should target the central intake contract on that host, not the main app stack Docker network
- collector runtime must expect the central host to be unavailable for long workday windows and continue spooling locally
- no Windows system settings changes are required or assumed for local collector development

### Collector Startup Sequence (Planned)
1. create collector env file:
   - `Copy-Item infra/collector/.env.example infra/collector/.env`
   - set collector-local credentials and `SIGNALDESK_CENTRAL_BASE_URL` for `192.168.0.200`
2. validate collector compose config:
   - `docker compose -p signaldesk-collector -f infra/collector/docker-compose.yml --env-file infra/collector/.env config`
3. start spool database first:
   - `docker compose -p signaldesk-collector -f infra/collector/docker-compose.yml --env-file infra/collector/.env up -d collector-db`
4. start collector runtime:
   - `docker compose -p signaldesk-collector -f infra/collector/docker-compose.yml --env-file infra/collector/.env up -d collector-runner collector-shipper`
5. optional telemetry:
   - `docker compose -p signaldesk-collector -f infra/collector/docker-compose.yml --env-file infra/collector/.env up -d collector-monitor`

### Collector Verification Flow (Planned)
- config validation:
  - `docker compose -p signaldesk-collector -f infra/collector/docker-compose.yml --env-file infra/collector/.env config`
- service status:
  - `docker compose -p signaldesk-collector -f infra/collector/docker-compose.yml --env-file infra/collector/.env ps`
- startup logs:
  - `docker compose -p signaldesk-collector -f infra/collector/docker-compose.yml --env-file infra/collector/.env logs collector-db --tail=120`
  - `docker compose -p signaldesk-collector -f infra/collector/docker-compose.yml --env-file infra/collector/.env logs collector-runner --tail=120`
  - `docker compose -p signaldesk-collector -f infra/collector/docker-compose.yml --env-file infra/collector/.env logs collector-shipper --tail=120`
- expected checks:
  - `collector-db` becomes healthy
  - `collector-runner` logs show source cycles writing to the local spool
  - `collector-shipper` logs show delivery attempts to `192.168.0.200`
  - central-host outages increase queue depth without dropping spool rows
  - restarting `collector-runner` or `collector-shipper` preserves backlog and retry state

### Collector Restart And Retention Rules
- stop collector stack only:
  - `docker compose -p signaldesk-collector -f infra/collector/docker-compose.yml --env-file infra/collector/.env down`
- destructive collector reset:
  - `docker compose -p signaldesk-collector -f infra/collector/docker-compose.yml --env-file infra/collector/.env down -v`
- restart runtime services only:
  - `docker compose -p signaldesk-collector -f infra/collector/docker-compose.yml --env-file infra/collector/.env restart collector-runner collector-shipper`
- retention baseline:
  - keep undelivered and dead-letter spool rows for up to 30 days
  - keep accepted and duplicate rows only until central acknowledgement and replay requirements are satisfied
- restart behavior:
  - `collector-db`, `collector-runner`, and `collector-shipper` should use `unless-stopped`
  - restart must not wipe spool state or reset retry counters

### Separation From Main App Stack
- do not add collector services to `infra/local/docker-compose.yml`
- do not share the main app PostgreSQL volume or env file with the collector stack
- do not rely on Docker cross-project DNS between the main app stack and collector stack
- if the collector needs to talk to central intake locally, use the explicit host/IP contract rather than a Compose service alias

## Promotion Path To Ubuntu On Raspberry Pi 4B 8GB

### Promotion Goal
Move the same collector container boundary from this PC to Ubuntu on Raspberry Pi 4B 8GB with only environment, host path, and image-platform adjustments.

### What Must Stay The Same
- the Compose project remains separate from the main app stack
- service boundaries remain:
  - `collector-db`
  - `collector-runner`
  - `collector-shipper`
  - optional `collector-monitor`
- spool-state retention and replay rules remain the same
- central host target remains `192.168.0.200` unless the private-network baseline changes deliberately

### What Changes On Ubuntu Pi
- use Ubuntu on Raspberry Pi as the host OS
- prefer SSD-backed storage for the collector database volume
- replace Windows-oriented path handling with Linux paths in env or bind mounts
- use ARM-compatible images or multi-arch builds for collector services
- run Docker Engine plus Compose plugin on the Pi instead of Docker Desktop

### Pi Deployment Sequence (Planned)
1. install Docker Engine and Compose plugin on Ubuntu running on Raspberry Pi 4B 8GB
2. provision the collector env file on the Pi with the same logical keys used on this PC
3. confirm the Pi can reach `192.168.0.200` on the required central intake port
4. start `collector-db`
5. start `collector-runner` and `collector-shipper`
6. confirm local spool persistence survives a container restart and a host reboot
7. confirm delivery resumes automatically when the central host returns

### Pi Operational Notes
- prefer wired Ethernet
- prefer UPS-backed power when possible
- keep spool data on persistent storage, not ephemeral container layers
- monitor:
  - queue depth
  - oldest pending age
  - last successful ship timestamp
  - local disk usage for spool storage

### Open Freeze Points
- exact central intake HTTP path, auth, and batch semantics still depend on backend follow-up
- exact collector runner cadence and source list still depend on collector-lane follow-up
- update the runbook again after `COL-002` and `BE-005` handoffs exist

## Bring-Down / Cleanup
- stop stack:
  - `docker compose -f infra/local/docker-compose.yml --env-file infra/local/.env down`
- stop + remove volumes (destructive):
  - `docker compose -f infra/local/docker-compose.yml --env-file infra/local/.env down -v`

## Minimum Runtime Checks
- `postgres` health is `healthy`
- `jobs-bootstrap` completed with exit code `0` (`docker compose ... ps -a jobs-bootstrap`)
- `api` health is `healthy` and `GET /healthz` returns `200`
- `jobs` health is `healthy`
- `jobs` logs show recurring `evaluate-alerts` work only, not migration or demo seed repeats
- role bootstrap completed (`signaldesk_migrator`, `signaldesk_app`, `signaldesk_readonly`)
- latest `keyword_snapshots.as_of_ts` freshness is within 60 minutes
- alerts table receives events after job cycle

## Contract Smoke Checks
- `Invoke-RestMethod "http://127.0.0.1:$env:API_PORT/v1/dashboard"`
- `Invoke-RestMethod "http://127.0.0.1:$env:API_PORT/v1/keywords?period=daily&market=all&limit=20"`
- `Invoke-RestMethod "http://127.0.0.1:$env:API_PORT/v1/watchlist"`
- `Invoke-RestMethod "http://127.0.0.1:$env:API_PORT/v1/alerts?limit=20"`

## Restart And Re-Bootstrap Procedure
- restart runtime services only:
  - `docker compose -f infra/local/docker-compose.yml --env-file infra/local/.env restart api jobs`
- rerun one-time bootstrap after a destructive reset or empty database:
  - `docker compose -f infra/local/docker-compose.yml --env-file infra/local/.env up jobs-bootstrap`
- if postgres is recreated from scratch, bring the full stack up again and confirm `jobs-bootstrap` exits `0`

## Backup And Restore Baseline
Backup (logical dump):
- `docker exec signaldesk-postgres pg_dump -U postgres -d signaldesk -Fc -f /tmp/signaldesk.dump`
- `docker cp signaldesk-postgres:/tmp/signaldesk.dump .\backups\signaldesk-<date>.dump`

Restore (local recovery drill):
1. `docker compose ... down`
2. start postgres only
3. restore dump into `signaldesk`
4. rerun `jobs-bootstrap`
5. bring up `api` + `jobs`
6. rerun API contract smoke checks

Retention baseline:
- keep at least 7 daily logical dumps locally
- verify one restore drill per month

## Rollback Checklist
- rollback application/config via previous git commit
- rebuild/redeploy compose stack from last known-good revision
- if migration/data issue occurs, restore latest logical dump and rerun runtime checks

## Security Checks
- no real secrets in repo
- app runtime uses `signaldesk_app` only
- migration path uses `signaldesk_migrator`
- postgres host binding remains localhost-only (`127.0.0.1`)
- init scripts are mounted read-only (`./postgres-init:/docker-entrypoint-initdb.d:ro`)

## Operational Escalation
- if snapshot freshness > 60 minutes: treat ranking output as degraded
- if jobs cycle fails twice consecutively: pause release and investigate
- if role privilege drift is detected: block deploy until corrected
- if API error rate spikes: investigate DB connectivity and recent bootstrap or jobs logs first
