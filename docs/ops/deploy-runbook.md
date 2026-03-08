# Deploy Runbook

## Initial Target
- Mobile: personal Android APK distribution
- API: Docker service (`api`) on private internal network
- Jobs: Docker service (`jobs`) on private internal network
- DB: PostgreSQL Docker service (`postgres`) with persistent volume
- Orchestration: Docker Compose on one host

## Current Stack State
- current compose file (`infra/local/docker-compose.yml`) defines `postgres` only
- `api`/`jobs` onboarding is a planned next increment and must preserve security rules in this runbook

## Prerequisites
- Docker Desktop (or Docker Engine + Compose plugin)
- local env file created from `infra/local/.env.example`
- non-placeholder credentials for `postgres`, `signaldesk_migrator`, `signaldesk_app`, `signaldesk_readonly`

## Startup Sequence (Deterministic)
1. create env file:
   - `Copy-Item infra/local/.env.example infra/local/.env`
   - replace all placeholder passwords
2. start database first:
   - `docker compose -f infra/local/docker-compose.yml up -d postgres`
3. verify DB health:
   - `docker compose -f infra/local/docker-compose.yml ps`
   - `docker compose -f infra/local/docker-compose.yml logs postgres --tail=100`
4. when API/jobs services exist, start them after DB health is green:
   - `docker compose -f infra/local/docker-compose.yml up -d api jobs`
5. verify API and job heartbeat checks before APK validation

## Minimum Runtime Checks
- PostgreSQL health check returns healthy
- bootstrap roles were created (`signaldesk_migrator`, `signaldesk_app`, `signaldesk_readonly`)
- latest scoring snapshot freshness is within expected 30-minute cadence
- API responds on health endpoint (once service exists)
- alert evaluation job completed at least once after startup (once jobs service exists)

## Backup And Restore Baseline
Backup (logical dump):
- `docker exec signaldesk-postgres pg_dump -U $env:POSTGRES_USER -d postgres -Fc -f /tmp/signaldesk.dump`
- `docker cp signaldesk-postgres:/tmp/signaldesk.dump .\backups\signaldesk-<date>.dump`

Restore (local recovery drill):
1. stop API/jobs containers
2. restore into a clean local DB container
3. run schema sanity query and latest snapshot query
4. restart API/jobs and confirm contract-level reads

Retention baseline:
- keep at least 7 daily logical dumps locally
- verify one restore drill per month

## Release Checklist
1. verify `main` contains accepted handoffs for active tasks
2. run compose config validation:
   - `docker compose -f infra/local/docker-compose.yml config`
3. confirm DB role/security assumptions still match `docs/backend/postgres-security.md`
4. verify API contract docs and schema docs are in sync (`docs/backend/api-contract.md`, `docs/backend/db-schema.md`)
5. smoke-check mobile app flows: Home, Ranking, Detail, Watchlist, Alerts

## Rollback Checklist
- rollback docs/contracts via previous git commit if contract drift is detected
- rollback containers by redeploying last known-good compose revision
- if DB migration issue occurs, restore from latest logical dump and re-run validation checks

## Security Checks
- no real secrets committed in repo
- app runtime uses `signaldesk_app`, never `postgres` superuser
- migration commands use `signaldesk_migrator`
- PostgreSQL port binding remains localhost-only (`127.0.0.1`)
- init scripts remain read-only mounted (`../postgres/init:/docker-entrypoint-initdb.d:ro`)

## Operational Escalation
- if scoring freshness exceeds 60 minutes: suppress trust in ranking outputs until recovered
- if ingestion/scoring fails twice consecutively: pause release and investigate
- if role privileges drift from baseline: block deploy until corrected
- if alert noise is excessive: tune thresholds before adding new data sources
