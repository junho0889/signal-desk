# Deploy Runbook

## Initial Target
- Mobile: personal Android APK distribution
- API: Docker service (`api`) on private internal network
- Jobs: Docker service (`jobs`) on private internal network
- DB: PostgreSQL Docker service (`postgres`) with persistent volume
- Orchestration: Docker Compose on one host

## Current Stack State
- compose file (`infra/local/docker-compose.yml`) defines `postgres`, `api`, `jobs`
- PostgreSQL bootstrap init scripts are mounted from `infra/local/postgres-init`
- API and jobs images are built from repo source (`services/api`, `services/jobs`)

## Prerequisites
- Docker Desktop (or Docker Engine + Compose plugin)
- local env file from `infra/local/.env.example`
- non-placeholder credentials for `postgres`, `signaldesk_migrator`, `signaldesk_app`, `signaldesk_readonly`

## Startup Sequence (Deterministic)
1. create env file:
   - `Copy-Item infra/local/.env.example infra/local/.env`
   - replace all placeholder passwords
2. validate compose config:
   - `docker compose -f infra/local/docker-compose.yml --env-file infra/local/.env config`
3. bring up full stack:
   - `docker compose -f infra/local/docker-compose.yml --env-file infra/local/.env up -d --build`
4. verify service health:
   - `docker compose -f infra/local/docker-compose.yml --env-file infra/local/.env ps`
5. inspect logs (startup only):
   - `docker compose -f infra/local/docker-compose.yml --env-file infra/local/.env logs postgres --tail=120`
   - `docker compose -f infra/local/docker-compose.yml --env-file infra/local/.env logs api --tail=120`
   - `docker compose -f infra/local/docker-compose.yml --env-file infra/local/.env logs jobs --tail=120`

## Bring-Down / Cleanup
- stop stack:
  - `docker compose -f infra/local/docker-compose.yml --env-file infra/local/.env down`
- stop + remove volumes (destructive):
  - `docker compose -f infra/local/docker-compose.yml --env-file infra/local/.env down -v`

## Minimum Runtime Checks
- `postgres` health is `healthy`
- `api` health is `healthy` and `GET /healthz` returns `200`
- `jobs` health is `healthy`
- role bootstrap completed (`signaldesk_migrator`, `signaldesk_app`, `signaldesk_readonly`)
- latest `keyword_snapshots.as_of_ts` freshness is within 60 minutes
- alerts table receives events after job cycle

## Contract Smoke Checks
- `Invoke-RestMethod "http://127.0.0.1:$env:API_PORT/v1/dashboard"`
- `Invoke-RestMethod "http://127.0.0.1:$env:API_PORT/v1/keywords?period=daily&market=all&limit=20"`
- `Invoke-RestMethod "http://127.0.0.1:$env:API_PORT/v1/watchlist"`
- `Invoke-RestMethod "http://127.0.0.1:$env:API_PORT/v1/alerts?limit=20"`

## Backup And Restore Baseline
Backup (logical dump):
- `docker exec signaldesk-postgres pg_dump -U postgres -d signaldesk -Fc -f /tmp/signaldesk.dump`
- `docker cp signaldesk-postgres:/tmp/signaldesk.dump .\backups\signaldesk-<date>.dump`

Restore (local recovery drill):
1. `docker compose ... down`
2. start postgres only
3. restore dump into `signaldesk`
4. bring up `api` + `jobs`
5. rerun API contract smoke checks

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
- if API error rate spikes: investigate DB connectivity and recent job/migration logs first
