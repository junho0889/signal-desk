# Backend Implementation Notes (BE-002)

## Scope Delivered
BE-002 implements backend v1 contract-serving paths for:
- `GET /v1/dashboard`
- `GET /v1/keywords`
- `GET /v1/keywords/{keyword_id}`
- `GET /v1/watchlist`
- `POST /v1/watchlist`
- `GET /v1/alerts`

It also adds a jobs runtime baseline for:
- schema migration application
- demo data seeding
- watchlist alert evaluation

## Code Layout
- `services/api/`: FastAPI contract server
- `services/jobs/`: migration + data/jobs runner
- `services/jobs/migrations/001_schema.sql`: BE-001-aligned schema bootstrap

## Runtime Environment Variables
- `SIGNALDESK_APP_DATABASE_URL`
  - runtime role: `signaldesk_app`
  - used by API and data/jobs writes
- `SIGNALDESK_MIGRATOR_DATABASE_URL`
  - runtime role: `signaldesk_migrator`
  - used by migration command
- `SIGNALDESK_ALERT_DELTA_THRESHOLD`
  - optional, default `2.0`

## Local Docker-First Bring-Up
1. Start PostgreSQL container.
2. Run migration job with migrator role.
3. Seed demo data and evaluate alerts.
4. Start API service and verify `/v1` endpoints.

PowerShell example:
```powershell
Set-Location E:\source\signal-desk

# 1) postgres
Copy-Item infra\local\.env.example infra\local\.env -ErrorAction SilentlyContinue
docker compose -f infra/local/docker-compose.yml up -d postgres
docker compose -f infra/local/docker-compose.yml ps

# 2) env urls (replace passwords with your local .env values)
$env:SIGNALDESK_MIGRATOR_DATABASE_URL="postgresql://signaldesk_migrator:<migrator_password>@127.0.0.1:5432/signaldesk"
$env:SIGNALDESK_APP_DATABASE_URL="postgresql://signaldesk_app:<app_password>@127.0.0.1:5432/signaldesk"

# 3) jobs
python -m services.jobs.signaldesk_jobs.main migrate
python -m services.jobs.signaldesk_jobs.main seed-demo
python -m services.jobs.signaldesk_jobs.main evaluate-alerts

# 4) api
pip install -r services/api/requirements.txt
uvicorn services.api.app.main:app --host 127.0.0.1 --port 8000
```

## Contract Sanity Checks
```powershell
Invoke-RestMethod "http://127.0.0.1:8000/v1/dashboard"
Invoke-RestMethod "http://127.0.0.1:8000/v1/keywords?period=daily&market=all&limit=20"
Invoke-RestMethod "http://127.0.0.1:8000/v1/keywords/00000000-0000-0000-0000-000000000101?period=daily&points=24"
Invoke-RestMethod "http://127.0.0.1:8000/v1/watchlist"
Invoke-RestMethod "http://127.0.0.1:8000/v1/alerts?limit=20"
Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:8000/v1/watchlist" -ContentType "application/json" -Body '{"op":"add","target_type":"keyword","target_id":"00000000-0000-0000-0000-000000000103"}'
```

## Known Gaps
- authentication/user-scoped watchlist is out of MVP scope
- cursor format is offset-token (`"0"`, `"20"`, ...), not opaque keyset
- jobs runner is manual/one-shot baseline; scheduler/container integration is finalized in OPS-002
