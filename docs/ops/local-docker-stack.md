# Local Docker Stack

## Main App Stack

### Services
- `postgres`: PostgreSQL 16 with persistent volume and bootstrap init script
- `api`: FastAPI service, planned to use `signaldesk_app`
- `jobs`: ingestion and scoring worker, planned to use `signaldesk_app`

### Network Rules
- create one private Docker network for the main app stack
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

## Collector Stack

### Purpose
The collector runtime must be developed on this PC as a separate Docker Compose project from the main app stack.

This stack is intentionally isolated so collector restart, backlog, and offline-delivery testing do not affect the API/jobs/PostgreSQL runtime used for the main app.

### Planned Compose Boundary
- planned compose file path: `infra/collector/docker-compose.yml`
- planned env file path: `infra/collector/.env`
- planned project name: `signaldesk-collector`
- do not reuse the main stack project name or `infra/local/docker-compose.yml`

### Planned Services
- `collector-db`
  - local PostgreSQL spool database for raw envelopes and delivery state
- `collector-runner`
  - executes source adapters and writes every collected payload to the local spool first
- `collector-shipper`
  - reads pending spool rows and ships them to central intake on `192.168.0.200`
- optional `collector-monitor`
  - exposes queue depth, oldest pending age, and last successful ship timestamp

### Network Rules
- create a collector-only private Docker network such as `signaldesk-collector-internal`
- do not join collector services to the main app stack network
- do not expose `collector-db` on a public interface
- if host tooling needs direct database access on this PC, bind `collector-db` to `127.0.0.1` only
- collector outbound traffic must be allowed to reach the central host at `192.168.0.200`
- collector runtime must tolerate the central host being offline for long workday windows

### Environment And Host Assumptions
- this PC remains the first development target for the collector stack
- Docker Desktop is sufficient; no Windows network or firewall configuration changes are part of the repo workflow
- central intake target baseline remains `192.168.0.200`
- collector env should keep central target details explicit:
  - `SIGNALDESK_COLLECTOR_NODE_ID`
  - `SIGNALDESK_COLLECTOR_DB_NAME`
  - `SIGNALDESK_COLLECTOR_DB_USER`
  - `SIGNALDESK_COLLECTOR_DB_PASSWORD`
  - `SIGNALDESK_CENTRAL_BASE_URL`
  - `SIGNALDESK_SHIP_MAX_BATCH_SIZE`
  - `SIGNALDESK_SHIP_RETRY_SECONDS`
  - `SIGNALDESK_SPOOL_RETENTION_DAYS`

### Persistent Data And Retention
- keep collector spool state in a dedicated named volume such as `signaldesk-collector-db-data`
- do not store collector database files inside the repository tree
- retain `pending`, `shipping`, `rejected`, and `dead_letter` spool rows for up to 30 days unless a more restrictive contract is frozen later
- prune `accepted` and `duplicate` rows only after central acknowledgement requirements are satisfied
- if a future dead-letter export directory is added, mount it as a separate collector-only volume and document the retention window explicitly

### Restart Behavior
- `collector-db`: `unless-stopped`
- `collector-runner`: `unless-stopped`, depends on healthy `collector-db`
- `collector-shipper`: `unless-stopped`, depends on healthy `collector-db`
- `collector-monitor`: `unless-stopped` only when enabled
- collector restart must not delete spool state or reset retry counters
- collector services should resume from the existing spool backlog after restart instead of recollecting already persisted payloads blindly

### Local Development Flow On This PC
1. create the collector env file outside version control from a future `infra/collector/.env.example`
2. set the central target explicitly to `192.168.0.200`
3. validate the collector compose config separately from the main app stack
4. start `collector-db` first, then bring up `collector-runner` and `collector-shipper`
5. verify that collector logs show:
   - source execution
   - spool writes
   - retry scheduling
   - central delivery attempts
6. test restart behavior by restarting `collector-runner` and `collector-shipper` without removing volumes
7. test offline buffering by simulating central-host unavailability and confirming spool growth is retained locally

### Separation Rules
- do not add collector services to `infra/local/docker-compose.yml`
- do not store collector credentials in `infra/local/.env`
- do not share the main app PostgreSQL volume with the collector stack
- do not assume the collector stack can resolve the main app stack by Docker service name; cross-stack communication should use explicit host/IP configuration

## Future Additions
- add API and jobs services once the code folders exist
- add a reverse proxy only if remote access becomes necessary
- add automated backups after the first stable schema migration path exists
- add the collector compose file and example env file after collector and intake workers freeze the runtime inputs
