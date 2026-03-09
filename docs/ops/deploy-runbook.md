# Deploy Runbook

## Initial Target
- Mobile: personal Android APK distribution
- API: Docker service (`api`) on private internal network
- Jobs bootstrap: one-time Docker service (`jobs-bootstrap`) for migration, seed, and first alert evaluation
- Jobs runtime: long-running Docker service (`jobs`) on private internal network
- DB: PostgreSQL Docker service (`postgres`) with persistent volume
- Orchestration: Docker Compose on one host

## Current Stack State
- compose file (`infra/local/docker-compose.yml`) defines `postgres`, `jobs-bootstrap`, `api`, `jobs`
- PostgreSQL bootstrap init scripts are mounted from `infra/local/postgres-init`
- API and jobs images are built from repo source (`services/api`, `services/jobs`)
- recurring jobs no longer reuse the `run-once` bootstrap path

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

## Collector Pi Deploy Smoke (COL-006)
Target node:
- host: `192.168.0.33`
- user: `admin`
- base path: `/home/admin/signal-desk-collector`

Verified sequence:
1. ssh and runtime checks:
   - `ssh signaldesk-pi "echo SSH_OK && whoami && hostname"`
   - `ssh signaldesk-pi "docker --version && docker compose version"`
2. sync collector assets:
   - `ssh signaldesk-pi "rm -rf ~/signal-desk-collector && mkdir -p ~/signal-desk-collector/infra ~/signal-desk-collector/services"`
   - `scp -r "E:\source\signal-desk-worktrees\collector-006\infra\collector" signaldesk-pi:/home/admin/signal-desk-collector/infra/`
   - `scp -r "E:\source\signal-desk-worktrees\collector-006\services\collector" signaldesk-pi:~/signal-desk-collector/services/`
3. prepare env and clear stale named containers:
   - `ssh signaldesk-pi "cd /home/admin/signal-desk-collector && cp infra/collector/.env.example infra/collector/.env"`
   - `ssh signaldesk-pi "docker rm -f signaldesk-collector-db || true; docker rm -f signaldesk-collector-bootstrap signaldesk-collector-runner signaldesk-collector-shipper signaldesk-collector-monitor || true"`
4. boot and run smoke:
   - `ssh signaldesk-pi "cd /home/admin/signal-desk-collector && docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env down -v --remove-orphans"`
   - `ssh signaldesk-pi "cd /home/admin/signal-desk-collector && docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env up -d collector-db"`
   - `ssh signaldesk-pi "cd /home/admin/signal-desk-collector && docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env run --rm collector-bootstrap"`
   - `ssh signaldesk-pi "cd /home/admin/signal-desk-collector && docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env run --rm collector-runner"`
5. verify spool evidence:
   - `ssh signaldesk-pi "cd /home/admin/signal-desk-collector && cat infra/collector/queries/spool-evidence.sql | docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env exec -T collector-db psql -U collector -d signaldesk_collector -f -"`
   - `ssh signaldesk-pi "cd /home/admin/signal-desk-collector && docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env run --rm collector-shipper"`
   - `ssh signaldesk-pi "cd /home/admin/signal-desk-collector && cat infra/collector/queries/spool-idempotency.sql | docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env exec -T collector-db psql -U collector -d signaldesk_collector -f -"`
   - `ssh signaldesk-pi "cd /home/admin/signal-desk-collector && docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env ps"`
