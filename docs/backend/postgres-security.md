# PostgreSQL Security Baseline

## Security Goals
- keep the database off the public network
- separate bootstrap, migration, app, and readonly access
- make secret handling visible to every worker
- prevent accidental superuser use in application code

## Required Roles
- `postgres`: bootstrap and emergency admin only
- `signaldesk_migrator`: owns schema changes and default privileges
- `signaldesk_app`: runtime reads and writes needed by the API and jobs
- `signaldesk_readonly`: diagnostics and ad hoc analysis only

## Access Rules
- bind PostgreSQL to `127.0.0.1` only if host access is required
- otherwise keep PostgreSQL reachable only on the Docker network
- never expose PostgreSQL directly to the internet
- never store real credentials in the repo
- rotate bootstrap credentials when the local stack is recreated for a shared environment

## Privilege Rules
- revoke default public privileges on the target database
- revoke `CREATE` on schema `public` from `PUBLIC`
- grant schema ownership and migration rights to `signaldesk_migrator`
- grant only required DML rights to `signaldesk_app`
- grant readonly select access to `signaldesk_readonly`

## Operational Rules
- run app containers with `signaldesk_app` only
- run migration commands with `signaldesk_migrator`
- document every new schema privilege in the migration or design doc
- if a feature requires elevated access, redesign first and escalate only if justified

## Bootstrap Reference
- init script: `infra/postgres/init/001-bootstrap.sh`
- local env template: `infra/local/.env.example`
- local stack: `infra/local/docker-compose.yml`
