# Deploy Runbook

## Initial Target
- Mobile: personal Android APK distribution
- API: local Docker container
- Jobs: local Docker container
- DB: local PostgreSQL container
- Orchestration: Docker Compose on the host machine

## Release Order
1. prepare `infra/local/.env` from the example file
2. start PostgreSQL and confirm bootstrap success
3. start API and worker containers
4. validate health checks and latest snapshot freshness
5. build and install Android APK

## Minimum Checks
- PostgreSQL health check responds
- API health endpoint responds
- latest snapshot time is within expected cadence
- notification evaluation job completes
- app can load dashboard and keyword detail

## Security Checks
- no real secrets are committed
- application containers use non-superuser database credentials
- PostgreSQL is not exposed beyond localhost or the internal Docker network
- init scripts are read-only mounted into the container
