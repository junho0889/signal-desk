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

## Collector Deployment Debug (Pi 192.168.0.33)

### Scope
- This section is only for collector deployment smoke on Raspberry Pi `192.168.0.33`.
- Keep this path isolated from the main app stack runtime above.

### SSH Auth Preflight (Required)
Run this exact command first:
```powershell
ssh signaldesk-pi "echo SSH_OK"
```

If it returns:
```text
Permission denied (publickey,password)
```
then remote deployment cannot proceed.

Validated host alias config used for stable runs:
```sshconfig
Host signaldesk-pi
  HostName 192.168.0.33
  User admin
  Port 22
  IdentityFile ~/.ssh/signaldesk_pi_ed25519
  IdentitiesOnly yes
  PreferredAuthentications publickey,password
  StrictHostKeyChecking accept-new
```

### Focused Fix For Deployment Path
1. Provision key auth for `admin@192.168.0.33`:
   - ensure local private key exists at `C:\Users\admin\.ssh\signaldesk_pi_ed25519`
   - add its public key to the Pi user's `~/.ssh/authorized_keys` (one-time operator action)
2. Re-run the same preflight command until it prints `SSH_OK`.

### 24/7 Daemon Deploy (Pi)
Use `/home/admin/signal-desk-collector` as the fixed remote collector root.

```powershell
ssh signaldesk-pi "echo SSH_OK && whoami && hostname"
ssh signaldesk-pi "docker --version && docker compose version"
ssh signaldesk-pi "rm -rf /home/admin/signal-desk-collector && mkdir -p /home/admin/signal-desk-collector/infra /home/admin/signal-desk-collector/services"
scp -r infra/collector signaldesk-pi:/home/admin/signal-desk-collector/infra/
scp -r services/collector signaldesk-pi:/home/admin/signal-desk-collector/services/
ssh signaldesk-pi "cp /home/admin/signal-desk-collector/infra/collector/.env.example /home/admin/signal-desk-collector/infra/collector/.env"
ssh signaldesk-pi "sed -i 's/^SIGNALDESK_COLLECTOR_NODE_ID=.*/SIGNALDESK_COLLECTOR_NODE_ID=collector-pi-192-168-0-33/' /home/admin/signal-desk-collector/infra/collector/.env"
ssh signaldesk-pi "sed -i 's/^SIGNALDESK_COLLECTOR_DAEMON_INTERVAL_SECONDS=.*/SIGNALDESK_COLLECTOR_DAEMON_INTERVAL_SECONDS=15/' /home/admin/signal-desk-collector/infra/collector/.env"
ssh signaldesk-pi "sed -i 's/^SIGNALDESK_COLLECTOR_DAEMON_SHIP_EVERY_CYCLES=.*/SIGNALDESK_COLLECTOR_DAEMON_SHIP_EVERY_CYCLES=1/' /home/admin/signal-desk-collector/infra/collector/.env"
ssh signaldesk-pi "sed -i 's/^SIGNALDESK_COLLECTOR_DAEMON_STREAM_MODE=.*/SIGNALDESK_COLLECTOR_DAEMON_STREAM_MODE=true/' /home/admin/signal-desk-collector/infra/collector/.env"
ssh signaldesk-pi "sed -i 's/^SIGNALDESK_COLLECTOR_DAEMON_EVENT_STEP_MINUTES=.*/SIGNALDESK_COLLECTOR_DAEMON_EVENT_STEP_MINUTES=1/' /home/admin/signal-desk-collector/infra/collector/.env"
ssh signaldesk-pi "sed -i 's/^SIGNALDESK_COLLECTOR_DAEMON_MAX_CYCLES=.*/SIGNALDESK_COLLECTOR_DAEMON_MAX_CYCLES=0/' /home/admin/signal-desk-collector/infra/collector/.env"
ssh signaldesk-pi "cd /home/admin/signal-desk-collector && docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env down -v --remove-orphans"
ssh signaldesk-pi "cd /home/admin/signal-desk-collector && docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env up -d collector-db"
ssh signaldesk-pi "cd /home/admin/signal-desk-collector && docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env run --rm collector-bootstrap"
ssh signaldesk-pi "cd /home/admin/signal-desk-collector && docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env up -d collector-daemon"
ssh signaldesk-pi "cd /home/admin/signal-desk-collector && docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env ps"
ssh signaldesk-pi "docker inspect -f '{{.HostConfig.RestartPolicy.Name}}' signaldesk_collector-collector-daemon-1"
```

### 24/7 Evidence And Logs
```powershell
ssh signaldesk-pi "cd /home/admin/signal-desk-collector && cat infra/collector/queries/spool-evidence.sql | docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env exec -T collector-db psql -U collector -d signaldesk_collector -f -"
ssh signaldesk-pi "cd /home/admin/signal-desk-collector && cat infra/collector/queries/spool-idempotency.sql | docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env exec -T collector-db psql -U collector -d signaldesk_collector -f -"
ssh signaldesk-pi "cd /home/admin/signal-desk-collector && docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env exec -T collector-db psql -U collector -d signaldesk_collector -c 'SELECT COUNT(*) AS total_rows, COUNT(*) FILTER (WHERE COALESCE(octet_length(collector_node_id),0)=0 OR COALESCE(octet_length(payload_hash),0)=0 OR COALESCE(octet_length(idempotency_key),0)=0 OR COALESCE(octet_length(publisher_domain),0)=0 OR COALESCE(octet_length(canonical_url),0)=0) AS rows_with_missing_required_metadata FROM spool_items;' -c 'SELECT quality_state, COUNT(*) AS row_count FROM spool_items GROUP BY quality_state ORDER BY quality_state;'"
```

### 24/7 Restart And Recovery
```powershell
# restart daemon only
ssh signaldesk-pi "cd /home/admin/signal-desk-collector && docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env restart collector-daemon"

# restart full collector runtime
ssh signaldesk-pi "cd /home/admin/signal-desk-collector && docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env down"
ssh signaldesk-pi "cd /home/admin/signal-desk-collector && docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env up -d collector-db collector-daemon"

# destructive recovery when state is broken
ssh signaldesk-pi "cd /home/admin/signal-desk-collector && docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env down -v --remove-orphans"
ssh signaldesk-pi "cd /home/admin/signal-desk-collector && docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env up -d collector-db"
ssh signaldesk-pi "cd /home/admin/signal-desk-collector && docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env run --rm collector-bootstrap"
ssh signaldesk-pi "cd /home/admin/signal-desk-collector && docker compose -f infra/collector/docker-compose.yml --env-file infra/collector/.env up -d collector-daemon"
```
