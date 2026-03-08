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
- compose project name: `signaldesk-collector-test`
- compose file path: `infra/collector/docker-compose.yml`
- env file path: `infra/collector/.env`
- stack separation:
  - do not reuse `infra/local/docker-compose.yml`
  - do not reuse `infra/local/.env`
  - do not share main app PostgreSQL volumes

### Boot Commands
Create env file:
```powershell
Copy-Item infra/collector/.env.example infra/collector/.env
```

Validate config:
```powershell
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env config
```

Start the collector test database:
```powershell
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env up -d collector-db
```

Check status:
```powershell
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env ps
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env logs collector-db --tail=120
```

### Reset Commands
Destructive reset:
```powershell
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env down -v
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env up -d collector-db
```

The reset must produce a clean test database with no residual spool rows before the next fixture run.

### Fixture Ingest Commands
Run the deterministic baseline fixture set:
```powershell
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env run --rm -e SIGNALDESK_COLLECTOR_RUN_MODE=fixture_once -e SIGNALDESK_FIXTURE_SET=baseline -e SIGNALDESK_COLLECTOR_DISABLE_SHIPPER=true collector-runner
```

Re-run the same fixture set after a runner restart:
```powershell
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env restart collector-runner
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env run --rm -e SIGNALDESK_COLLECTOR_RUN_MODE=fixture_once -e SIGNALDESK_FIXTURE_SET=baseline -e SIGNALDESK_COLLECTOR_DISABLE_SHIPPER=true collector-runner
```

If the local test flow also needs shipper behavior:
```powershell
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env run --rm -e SIGNALDESK_COLLECTOR_RUN_MODE=fixture_once -e SIGNALDESK_FIXTURE_SET=baseline -e SIGNALDESK_COLLECTOR_DISABLE_SHIPPER=false collector-runner
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env logs collector-shipper --tail=120
```

### Required Query Commands
Source registry:
```powershell
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env exec collector-db psql -U signaldesk_collector -d signaldesk_collector_test -c "select source_id, source_category, expected_upstream_event_at from ingest_sources order by source_id;"
```

Spool run and latest items:
```powershell
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env exec collector-db psql -U signaldesk_collector -d signaldesk_collector_test -c "select run_status, adapter_version, started_at, completed_at from collector_spool_runs order by started_at desc limit 5;"
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env exec collector-db psql -U signaldesk_collector -d signaldesk_collector_test -c "select spool_item_key, payload_hash, retrieval_status, delivery_attempt_count, last_delivery_status from collector_spool_items order by spooled_at desc limit 10;"
```

Metadata completeness and quality-state proof:
```powershell
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env exec collector-db psql -U signaldesk_collector -d signaldesk_collector_test -c "select ri.payload_hash, ri.publisher_domain, ri.canonical_url, ri.metadata_completeness, q.quality_state from raw_items ri join raw_item_quality_states q on q.raw_item_id = ri.id order by ri.ingested_at desc limit 10;"
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env exec collector-db psql -U signaldesk_collector -d signaldesk_collector_test -c "select ri.payload_hash, q.quality_state, q.state_reason_codes, q.missing_required_fields from raw_items ri join raw_item_quality_states q on q.raw_item_id = ri.id where q.quality_state <> 'accepted' order by ri.ingested_at desc limit 10;"
```

Quarantine and dead-letter proof:
```powershell
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env exec collector-db psql -U signaldesk_collector -d signaldesk_collector_test -c "select raw_item_id, quarantine_reason, quarantined_at, release_decision from raw_quarantine_records order by quarantined_at desc limit 10;"
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env exec collector-db psql -U signaldesk_collector -d signaldesk_collector_test -c "select captured_payload_hash, dead_letter_reason, failure_class, captured_at from raw_dead_letter_records order by captured_at desc limit 10;"
```

Idempotent re-run proof:
```powershell
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env exec collector-db psql -U signaldesk_collector -d signaldesk_collector_test -c "select payload_hash, count(*) from collector_spool_items group by payload_hash order by count(*) desc, payload_hash limit 10;"
```

### Expected Results
- `collector-db` becomes healthy after boot
- fixture ingest writes at least one `collector_spool_runs` row and one `collector_spool_items` row
- metadata inspection shows `publisher_domain`, `canonical_url`, `payload_hash`, and `metadata_completeness`
- non-accepted fixtures, if present, show explicit `quality_state`, `state_reason_codes`, or quarantine/dead-letter evidence
- fixture re-run after restart is auditable through stable spool keys or duplicate-safe results rather than silent duplication

### Restart And Cleanup
Restart runtime services only:
```powershell
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env restart collector-runner collector-shipper
```

Stop test stack:
```powershell
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env down
```

Destructive cleanup:
```powershell
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env down -v
```

### Implementation Freeze Notes
- the command surface above is the required ops contract for `COL-003` local smoke
- if collector implementation needs different service names, env keys, or query targets, update OPS-006 before QA review
- no Windows system changes should be required for this test path

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
