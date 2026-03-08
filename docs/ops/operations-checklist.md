# Operations Checklist (OPS-002)

## 1) Pre-Start
- confirm working tree is clean or expected
- confirm `infra/local/.env` exists and passwords are non-placeholder
- run compose validation:
  - `docker compose -f infra/local/docker-compose.yml --env-file infra/local/.env config`

## 2) Bring-Up
- start stack:
  - `docker compose -f infra/local/docker-compose.yml --env-file infra/local/.env up -d --build`
- verify service state:
  - `docker compose -f infra/local/docker-compose.yml --env-file infra/local/.env ps`

## 3) Health Checks
- postgres:
  - health should be `healthy`
  - `docker compose -f infra/local/docker-compose.yml --env-file infra/local/.env logs postgres --tail=80`
- api:
  - health should be `healthy`
  - `Invoke-RestMethod "http://127.0.0.1:8000/healthz"`
- jobs:
  - health should be `healthy`
  - `docker compose -f infra/local/docker-compose.yml --env-file infra/local/.env logs jobs --tail=120`

## 4) Data Freshness + Contract Smoke
- freshness query:
  - `docker exec signaldesk-postgres psql -U postgres -d signaldesk -c "SELECT now() AT TIME ZONE 'utc' AS now_utc, MAX(as_of_ts) AS latest_snapshot_utc FROM keyword_snapshots;"`
- contract endpoints:
  - `Invoke-RestMethod "http://127.0.0.1:8000/v1/dashboard"`
  - `Invoke-RestMethod "http://127.0.0.1:8000/v1/keywords?period=daily&market=all&limit=20"`
  - `Invoke-RestMethod "http://127.0.0.1:8000/v1/watchlist"`
  - `Invoke-RestMethod "http://127.0.0.1:8000/v1/alerts?limit=20"`

## 5) Restart Procedure
- restart one service:
  - `docker compose -f infra/local/docker-compose.yml --env-file infra/local/.env restart <service>`
- restart full stack:
  - `docker compose -f infra/local/docker-compose.yml --env-file infra/local/.env down`
  - `docker compose -f infra/local/docker-compose.yml --env-file infra/local/.env up -d`

## 6) Backup Procedure
- create logical backup:
  - `docker exec signaldesk-postgres pg_dump -U postgres -d signaldesk -Fc -f /tmp/signaldesk.dump`
  - `docker cp signaldesk-postgres:/tmp/signaldesk.dump .\backups\signaldesk-<date>.dump`
- verify artifact exists in `backups/`

## 7) Restore Drill (Local)
- stop app containers (`api`, `jobs`)
- restore backup into local postgres
- restart `api`, `jobs`
- rerun health + contract smoke checks

## 8) Rollback Trigger Criteria
- repeated API 5xx after restart
- freshness breach > 60 minutes with failed jobs cycle
- migration/data regression in contract endpoint payloads

## 9) Shutdown
- normal stop:
  - `docker compose -f infra/local/docker-compose.yml --env-file infra/local/.env down`
- destructive reset (explicit approval only):
  - `docker compose -f infra/local/docker-compose.yml --env-file infra/local/.env down -v`
