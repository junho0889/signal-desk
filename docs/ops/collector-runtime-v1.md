# Collector Runtime V1

## Purpose
Define the first real collector runtime that can be developed on the current PC and later packaged for Ubuntu on Raspberry Pi 4B 8GB.

## V1 Decisions
- no RabbitMQ
- local PostgreSQL spool database on the collector host
- Docker Compose as the runtime boundary
- central delivery target is the main server at `192.168.0.200`
- collector must retain undelivered payloads for up to 30 days

## Why No RabbitMQ In V1
- local spool durability and replayability matter more than broker semantics right now
- raw payload auditability is simpler with explicit database state
- the main problem is long offline windows on the central host, which the spool database handles directly
- avoid introducing another stateful service before the collector contract is proven

## Runtime Components
- `collector-db`
  - local PostgreSQL instance for spool and delivery state
- `collector-runner`
  - executes source adapters on schedule
- `collector-shipper`
  - batches pending spool items and ships them to central intake
- optional `collector-monitor`
  - exposes queue depth, oldest pending age, and last successful ship

## Local Development Target
- run on this PC as a separate Compose project from the main app stack
- keep networks and volumes isolated from `infra/local/docker-compose.yml`
- use this environment to verify restart behavior, offline buffering, and replay

## Promotion Path
- keep container images and env vars portable
- avoid host assumptions that break on Ubuntu ARM
- later replace only:
  - host paths
  - build target or image platform
  - deployment runbook

## Spool Storage Requirements
- store raw payload envelope plus payload hash
- track delivery state transitions:
  - `pending`
  - `shipping`
  - `accepted`
  - `duplicate`
  - `rejected`
  - `dead_letter`
- track:
  - first collected timestamp
  - last ship attempt
  - retry count
  - last error
  - prune eligibility

## Retention
- retain undelivered and dead-letter records for up to 30 days
- accepted and duplicate records may be pruned earlier only after central acknowledgement rules are satisfied

## Required Backend Coordination
- central intake API contract
- acknowledgement semantics
- central idempotency expectations
- raw ingest persistence fields
- error classes that should trigger retry vs dead-letter

## COL-003 Local Test Stack (Implemented)
The collector dev stack now runs in `infra/collector/` and remains isolated from the main app stack.

### Compose Services
- `collector-db`: local PostgreSQL spool database
- `collector-bootstrap`: one-shot schema migration
- `collector-runner`: one-shot fixture ingest
- `collector-shipper`: one-shot shipper simulation (offline mode by default)
- optional `collector-monitor`: one-shot spool metrics view

### Bootstrap Commands
```powershell
docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example up -d collector-db
docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example run --rm collector-bootstrap
```

### Fixture Ingest Command
```powershell
docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example run --rm collector-runner
```

### Query Evidence Commands
```powershell
Get-Content -Raw 'infra/collector/queries/spool-evidence.sql' | docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example exec -T collector-db psql -U collector -d signaldesk_collector -f -
Get-Content -Raw 'infra/collector/queries/spool-idempotency.sql' | docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example exec -T collector-db psql -U collector -d signaldesk_collector -f -
```

### Restart And Idempotent Re-Run
```powershell
docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example restart collector-db
docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example run --rm collector-runner
```

Expected evidence:
- row count remains stable by `idempotency_key`
- `ingest_count` increments on re-run
- spool rows retain `status`, `ingest_status`, `quality_state`, `retry_count`, `reason_code`, and `last_intake_status`
- shipper offline simulation records `last_intake_status=retryable_failure` and a non-empty `last_error_code`

### Reset Flow
```powershell
powershell -ExecutionPolicy Bypass -File infra/collector/reset-test-db.ps1 -StartDb
```
