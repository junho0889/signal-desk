# Local Docker Stack

## Main App Stack

### Services
- `postgres`: PostgreSQL 16 with persistent volume and bootstrap init script
- `api`: FastAPI service, planned to use `signaldesk_app`
- `jobs`: ingestion and scoring worker, planned to use `signaldesk_app`

### Network Rules
- create one private Docker network for all main app services
- expose the API port only when needed for local app testing
- bind PostgreSQL to `127.0.0.1` only if host tools need access
- do not expose PostgreSQL on a public interface

### Secret Rules
- keep real values in `infra/local/.env`
- commit only `infra/local/.env.example`
- use distinct passwords for bootstrap, migrator, app, and readonly roles

### Persistent Data
- keep PostgreSQL data in a named Docker volume
- do not store database state inside the repository tree
- document backup commands once the schema and migration tooling exist

### Bootstrap Flow
1. copy `infra/local/.env.example` to `infra/local/.env`
2. change all placeholder passwords
3. run `docker compose -f infra/local/docker-compose.yml up -d postgres`
4. confirm the `001-bootstrap.sh` init completed on first startup
5. connect using the readonly or migrator role, not the superuser, for normal work

## Collector Local Test Stack

### Purpose
Collector ingest testing on this PC must run as a separate Docker Compose project from the main app stack.

OPS-006 freezes the exact local test surface from `COL-003`:
- `infra/collector/docker-compose.yml`
- `infra/collector/.env.example`
- `infra/collector/reset-test-db.ps1`
- `infra/collector/queries/spool-evidence.sql`
- `infra/collector/queries/spool-idempotency.sql`

### Required Services
- `collector-db`
  - local PostgreSQL spool database
- `collector-bootstrap`
  - schema bootstrap via `python -m signaldesk_collector.main migrate`
- `collector-runner`
  - fixture ingest via `python -m signaldesk_collector.main ingest-fixture`
- `collector-shipper`
  - one-shot shipper simulation via `python -m signaldesk_collector.main ship-once`
- `collector-monitor`
  - metrics snapshot via `python -m signaldesk_collector.main metrics`

### Required Separation
- keep the collector stack out of `infra/local/docker-compose.yml`
- keep collector credentials out of `infra/local/.env`
- keep collector data in its own named volume `collector-postgres-data`
- do not require Windows system changes for the local smoke path

### Local Test Inputs
Use the collector-owned env keys and defaults already frozen in `COL-003`:
- `COMPOSE_PROJECT_NAME=signaldesk_collector`
- `COLLECTOR_POSTGRES_PORT=55432`
- `COLLECTOR_POSTGRES_DB=signaldesk_collector`
- `COLLECTOR_POSTGRES_USER=collector`
- `COLLECTOR_POSTGRES_PASSWORD=collector`
- `SIGNALDESK_COLLECTOR_NODE_ID=collector-dev-node`
- `SIGNALDESK_COLLECTOR_SHIPPER_MODE=simulate-offline`
- `SIGNALDESK_COLLECTOR_SHIPPER_BATCH_SIZE=20`

### Exact Local Smoke Commands
Start clean:
```powershell
docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example down -v --remove-orphans
```

Start the test DB:
```powershell
docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example up -d collector-db
```

Bootstrap schema:
```powershell
docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example run --rm collector-bootstrap
```

Run fixture ingest:
```powershell
docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example run --rm collector-runner
```

Inspect spool evidence:
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

Inspect idempotency:
```powershell
Get-Content -Raw 'infra/collector/queries/spool-idempotency.sql' | docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example exec -T collector-db psql -U collector -d signaldesk_collector -f -
```

Reset with helper:
```powershell
powershell -ExecutionPolicy Bypass -File infra/collector/reset-test-db.ps1 -StartDb
```

### Expected Local Evidence
- first runner execution inserts fixture rows into `spool_items`
- rerunning the same fixture does not create extra logical rows; it increases `ingest_count`
- shipper simulation leaves rows in `pending` with `last_error_code=central_offline_simulated`
- the local stack remains isolated from the main app stack during all of the above

### Raspberry Pi Promotion Boundary
- keep the same service split and CLI entrypoints on the Pi
- treat Raspberry Pi `192.168.0.33` as the collector host identity, not the central target
- keep the central host contract separate; do not collapse collector and central runtime into one Compose project

### Future Additions
- once collector assets merge into this branch, rerun the exact commands above and replace branch-derived evidence with direct OPS-006 runtime evidence
- if collector implementation changes service names or query file locations, update OPS-006 before QA review
