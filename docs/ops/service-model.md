# Service Model

## Operating Assumption
This is a personal-use service first. Favor low operational overhead over enterprise-grade complexity.

## Runtime Model
- one host runs Docker Compose
- PostgreSQL stores durable data in a named volume
- API and jobs containers share a private Docker network with PostgreSQL
- the app calls the API, never the database directly

## Required Capabilities
- scheduled ingestion
- derived data refresh
- mobile API availability
- alert delivery
- error visibility
- backup and restore path for PostgreSQL data

## Monitoring Baseline
- job success or failure
- last successful ingestion time
- API error rate
- push delivery failures
- PostgreSQL container health and free disk growth

## Escalation Baseline
- if ingestion fails twice in a row, stop trusting fresh rankings
- if API contract changes, update mobile dependency notes before release
- if alert noise rises, tune thresholds before adding new sources
- if PostgreSQL credentials or privileges drift, stop deploys until corrected
