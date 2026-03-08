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

## Collector Local Test-DB Workflow

### Purpose
This workflow is the required local smoke path for collector ingest on this PC. It must be runnable without touching the main app stack and without changing Windows system settings.

### Required Project Boundary
- compose file path: `infra/collector/docker-compose.yml`
- env file path for local smoke: `infra/collector/.env.example`
- stack separation:
  - do not reuse `infra/local/docker-compose.yml`
  - do not reuse `infra/local/.env`
  - do not share main app PostgreSQL volumes

### Boot Commands
Validate config:
```powershell
docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example config
```

Start the collector test database:
```powershell
docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example up -d collector-db
```

Check status:
```powershell
docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example ps
docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example logs collector-db --tail=120
```

### Reset Commands
Destructive reset:
```powershell
docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example down -v --remove-orphans
docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example up -d collector-db
```

The reset must produce a clean test database with no residual spool rows before the next fixture run.

### Fixture Ingest Commands
Run schema bootstrap:
```powershell
docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example run --rm collector-bootstrap
```

Run the deterministic fixture ingest:
```powershell
docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example run --rm collector-runner
```

Query spool evidence:
```powershell
Get-Content -Raw 'infra/collector/queries/spool-evidence.sql' | docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example exec -T collector-db psql -U collector -d signaldesk_collector -f -
```

Run shipper simulation:
```powershell
docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example run --rm collector-shipper
```

Restart DB and rerun fixture ingest:
```powershell
docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example restart collector-db
docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example run --rm collector-runner
```

Query idempotency evidence:
```powershell
Get-Content -Raw 'infra/collector/queries/spool-idempotency.sql' | docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example exec -T collector-db psql -U collector -d signaldesk_collector -f -
```

Optional local metrics snapshot:
```powershell
docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example run --rm collector-monitor
```

Reset helper:
```powershell
powershell -ExecutionPolicy Bypass -File infra/collector/reset-test-db.ps1 -StartDb
```

### Expected Results
- `collector-bootstrap` completes successfully
- first runner execution reads `2` fixture rows and inserts `2` spool rows
- shipper simulation touches the same rows and records `last_error_code=central_offline_simulated`
- rerunning `collector-runner` after restart does not increase logical row count and instead increases `ingest_count`
- `spool-evidence.sql` and `spool-idempotency.sql` remain the required inspection surface for local smoke

### Restart And Cleanup
Restart runtime services only:
```powershell
docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example restart collector-db
```

Stop test stack:
```powershell
docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example down
```

Destructive cleanup:
```powershell
docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example down -v --remove-orphans
```

### Implementation Freeze Notes
- the command surface above now matches the actual `COL-003` implementation
- if collector implementation changes later, update OPS-006 before QA review
- no Windows system changes should be required for this test path

## Collector Deployment Path For Raspberry Pi 192.168.0.33

### Purpose
Promote the same collector stack from local PC smoke to the Raspberry Pi collector node at `192.168.0.33` with minimal drift.

### Required Pi Identity
- collector host IP: `192.168.0.33`
- collector node id should change from `collector-dev-node` to a Pi-specific value such as `collector-pi-192-168-0-33`
- central host targeting remains a separate concern from the collector host IP

### Minimal Pi Preparation
1. check out the repo on the Pi or copy only:
   - `infra/collector/`
   - `services/collector/`
2. copy the example env file:
   - `cp infra/collector/.env.example infra/collector/.env`
3. update only the Pi-specific values:
   - `SIGNALDESK_COLLECTOR_NODE_ID=collector-pi-192-168-0-33`
   - any future central-host URL or auth values once backend integration is frozen

### Minimal Pi Commands
Bootstrap and ingest:
```bash
docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env up -d collector-db
docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env run --rm collector-bootstrap
docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env run --rm collector-runner
```

Inspect evidence:
```bash
cat infra/collector/queries/spool-evidence.sql | docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env exec -T collector-db psql -U collector -d signaldesk_collector -f -
```

### Minimal Pi Operational Rule
- keep the Pi deployment path command-compatible with the local smoke path
- change only node identity, host-local env, and future central-target settings
- do not redesign the stack on the Pi before the local smoke path and shipper behavior are stable

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
