# Collector Dev Stack (COL-003)

Local collector stack for fixture-driven spool verification.

## Services
- `collector-db`: local PostgreSQL spool database
- `collector-bootstrap`: one-shot schema migration
- `collector-runner`: one-shot fixture ingest
- `collector-shipper`: one-shot shipper simulation
- `collector-monitor`: one-shot metrics output

## Quick Start
```powershell
docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example up -d collector-db
docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example run --rm collector-bootstrap
docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example run --rm collector-runner
```

## Reset Test DB
```powershell
powershell -ExecutionPolicy Bypass -File infra/collector/reset-test-db.ps1 -StartDb
```

## Evidence Queries
```powershell
Get-Content -Raw 'infra/collector/queries/spool-evidence.sql' | docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example exec -T collector-db psql -U collector -d signaldesk_collector -f -
Get-Content -Raw 'infra/collector/queries/spool-idempotency.sql' | docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example exec -T collector-db psql -U collector -d signaldesk_collector -f -
Get-Content -Raw 'infra/collector/queries/spool-quality-summary.sql' | docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env.example exec -T collector-db psql -U collector -d signaldesk_collector -f -
```
