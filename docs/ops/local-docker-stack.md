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

## Collector Test Stack

### Purpose
Collector ingest testing on this PC must run as a separate Docker Compose project from the main app stack.

This local collector stack exists to prove three things without guesswork:
- a clean test database can be booted and reset repeatedly
- a deterministic fixture ingest path writes collector spool rows
- metadata and quality-state evidence can be queried directly after ingest

### Required Separation
- planned compose file path: `infra/collector/docker-compose.yml`
- planned env file path: `infra/collector/.env`
- required project name for local smoke: `signaldesk-collector-test`
- do not add collector services to `infra/local/docker-compose.yml`
- do not share the main app PostgreSQL volume or env file with the collector test stack
- do not require Windows system setting changes for the local test flow

### Required Services
- `collector-db`
  - local PostgreSQL test database for collector spool and ingest-evidence tables
- `collector-runner`
  - fixture-driven ingest entrypoint for repeatable local smoke
- `collector-shipper`
  - optional in local smoke when proving delivery-state transitions
- optional `collector-monitor`
  - queue-depth and last-success telemetry

### Required Environment Contract
The local test stack should expose these env keys so the runbook stays deterministic:
- `SIGNALDESK_COLLECTOR_DB_NAME`
- `SIGNALDESK_COLLECTOR_DB_USER`
- `SIGNALDESK_COLLECTOR_DB_PASSWORD`
- `SIGNALDESK_COLLECTOR_RUN_MODE`
- `SIGNALDESK_FIXTURE_SET`
- `SIGNALDESK_COLLECTOR_DISABLE_SHIPPER`
- `SIGNALDESK_CENTRAL_BASE_URL`
- `SIGNALDESK_SPOOL_RETENTION_DAYS`

Recommended local-test values:
- `SIGNALDESK_COLLECTOR_RUN_MODE=fixture_once`
- `SIGNALDESK_FIXTURE_SET=baseline`
- `SIGNALDESK_COLLECTOR_DISABLE_SHIPPER=true`
- `SIGNALDESK_SPOOL_RETENTION_DAYS=30`

### Network And Host Assumptions
- collector test traffic stays isolated from the main app Docker network
- `collector-db` should not be exposed publicly
- if host-side SQL inspection is needed, bind `collector-db` to `127.0.0.1` only
- if the shipper is enabled for an integration smoke, it should target the explicit central host contract rather than a Docker service alias
- central-host baseline remains `192.168.0.200`, but local fixture smoke should not depend on that host being available

### Test-DB Lifecycle Contract
The local collector stack must make these exact operations possible:

Boot:
```powershell
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env config
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env up -d collector-db
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env ps
```

Reset:
```powershell
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env down -v
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env up -d collector-db
```

Fixture ingest:
```powershell
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env run --rm -e SIGNALDESK_COLLECTOR_RUN_MODE=fixture_once -e SIGNALDESK_FIXTURE_SET=baseline -e SIGNALDESK_COLLECTOR_DISABLE_SHIPPER=true collector-runner
```

Restart verification:
```powershell
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env restart collector-runner
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env run --rm -e SIGNALDESK_COLLECTOR_RUN_MODE=fixture_once -e SIGNALDESK_FIXTURE_SET=baseline -e SIGNALDESK_COLLECTOR_DISABLE_SHIPPER=true collector-runner
```

### Required Query Surface
To keep QA and downstream review deterministic, the collector local test database must support these exact inspection targets after fixture ingest:
- `ingest_sources`
- `collector_nodes`
- `collector_spool_runs`
- `collector_spool_items`
- `raw_items`
- `raw_item_quality_states`
- `raw_quarantine_records`
- `raw_dead_letter_records`

These names are aligned with the current storage and intake branches. If implementation lands with different physical names, the collector lane must provide compatibility views or update OPS-006 before QA review.

### Exact Query Commands
Source registry:
```powershell
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env exec collector-db psql -U signaldesk_collector -d signaldesk_collector_test -c "select source_id, source_category, expected_upstream_event_at from ingest_sources order by source_id;"
```

Latest spool run:
```powershell
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env exec collector-db psql -U signaldesk_collector -d signaldesk_collector_test -c "select run_status, adapter_version, started_at, completed_at from collector_spool_runs order by started_at desc limit 5;"
```

Spool item proof:
```powershell
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env exec collector-db psql -U signaldesk_collector -d signaldesk_collector_test -c "select spool_item_key, payload_hash, retrieval_status, delivery_attempt_count, last_delivery_status from collector_spool_items order by spooled_at desc limit 10;"
```

Metadata and quality-state proof:
```powershell
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env exec collector-db psql -U signaldesk_collector -d signaldesk_collector_test -c "select ri.payload_hash, ri.publisher_domain, ri.canonical_url, ri.metadata_completeness, q.quality_state from raw_items ri join raw_item_quality_states q on q.raw_item_id = ri.id order by ri.ingested_at desc limit 10;"
```

Weak or downgraded payload evidence:
```powershell
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env exec collector-db psql -U signaldesk_collector -d signaldesk_collector_test -c "select ri.payload_hash, q.quality_state, q.state_reason_codes, q.missing_required_fields from raw_items ri join raw_item_quality_states q on q.raw_item_id = ri.id where q.quality_state <> 'accepted' order by ri.ingested_at desc limit 10;"
```

Quarantine evidence:
```powershell
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env exec collector-db psql -U signaldesk_collector -d signaldesk_collector_test -c "select raw_item_id, quarantine_reason, quarantined_at, release_decision from raw_quarantine_records order by quarantined_at desc limit 10;"
```

Dead-letter evidence:
```powershell
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env exec collector-db psql -U signaldesk_collector -d signaldesk_collector_test -c "select captured_payload_hash, dead_letter_reason, failure_class, captured_at from raw_dead_letter_records order by captured_at desc limit 10;"
```

Idempotent re-run evidence:
```powershell
docker compose -p signaldesk-collector-test -f infra/collector/docker-compose.yml --env-file infra/collector/.env exec collector-db psql -U signaldesk_collector -d signaldesk_collector_test -c "select payload_hash, count(*) from collector_spool_items group by payload_hash order by count(*) desc, payload_hash limit 10;"
```

### Retention And Restart Behavior
- `collector-db`, `collector-runner`, and `collector-shipper` should use `unless-stopped`
- restart must not wipe the collector test database or reset retry counters
- fixture re-run should be auditable through stable spool keys or duplicate handling, not silent row loss
- local test retention baseline remains 30 days for undelivered and dead-letter evidence unless a stricter contract is frozen later

### Future Additions
- add the real `infra/collector/` assets once `COL-003` lands
- update the exact command contract if collector implementation chooses a different fixture entrypoint, but do that before QA review
- keep the collector test stack separate from the main app stack even after the real collector services exist
