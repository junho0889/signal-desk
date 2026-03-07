# Local Docker Stack

## Services
- `postgres`: PostgreSQL 16 with persistent volume and bootstrap init script
- `api`: FastAPI service, planned to use `signaldesk_app`
- `jobs`: ingestion and scoring worker, planned to use `signaldesk_app`

## Network Rules
- create one private Docker network for all services
- expose the API port only when needed for local app testing
- bind PostgreSQL to `127.0.0.1` only if host tools need access
- do not expose PostgreSQL on a public interface

## Secret Rules
- keep real values in `infra/local/.env`
- commit only `infra/local/.env.example`
- use distinct passwords for bootstrap, migrator, app, and readonly roles

## Persistent Data
- keep PostgreSQL data in a named Docker volume
- do not store database state inside the repository tree
- document backup commands once the schema and migration tooling exist

## Bootstrap Flow
1. copy `infra/local/.env.example` to `infra/local/.env`
2. change all placeholder passwords
3. run `docker compose -f infra/local/docker-compose.yml up -d postgres`
4. confirm the `001-bootstrap.sh` init completed on first startup
5. connect using the readonly or migrator role, not the superuser, for normal work

## Future Additions
- add API and jobs services once the code folders exist
- add a reverse proxy only if remote access becomes necessary
- add automated backups after the first stable schema migration path exists
