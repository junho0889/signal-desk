# Storage Expansion Outline

## Purpose
Describe the next schema expansion beyond the current MVP read-model baseline.

## BE-008 Freeze Scope
- raw-ingest metadata schema
- source registry contract
- spool-to-central lineage
- quality-state persistence for accepted, degraded, duplicate, stale, quarantined, and dead-letter payloads

## Raw-Ingest Table Families (Frozen)
1. source registry
- `ingest_sources`
- `ingest_source_domains`
- `source_contract_versions`

2. collector spool lineage
- `collector_nodes`
- `collector_spool_runs`
- `collector_spool_items`

3. central intake persistence
- `intake_requests`
- `raw_items`
- `raw_item_spool_links`

4. metadata quality persistence
- `raw_item_quality_states`
- `raw_item_quality_history`
- `raw_duplicate_links`
- `raw_quarantine_records`
- `raw_dead_letter_records`

## Required Metadata Contract (Stored As Columns, Not Hidden In One Blob)
- identity and provenance:
  - `source_id`
  - `source_category`
  - `collector_node_id`
  - `spool_item_key`
  - `retry_count`
  - `idempotency_key`
  - `payload_hash`
  - `payload_version`
- time and freshness:
  - `collected_at`
  - `upstream_event_at` when available
  - `ingested_at`
- publisher and reference:
  - `publisher_name`
  - `publisher_domain`
  - `canonical_url`
  - `external_id` when available
- classification and rendering:
  - `language`
  - `market_scope`
  - `title`
- payload:
  - `raw_payload_json`

## Quality-State Storage Rules
- `accepted`:
  - metadata is complete enough for normal downstream use.
- `accepted_degraded`:
  - persisted and replayable, but missing or weak metadata is explicitly recorded.
- `duplicate`:
  - links to canonical raw row through `raw_duplicate_links`; replay points to canonical row.
- `stale_source`:
  - persisted with stale reason and threshold breach metadata.
- `metadata_incomplete`:
  - persisted when structurally valid but missing required metadata fields.
- `quarantined`:
  - persisted in quarantine tables and blocked from normal normalization until released.
- `dead_letter`:
  - persisted with non-retryable reason and replay guidance metadata.

## Lineage Freeze (Collector Spool -> Central Raw)
- collector row identity: `collector_spool_items.spool_item_key`
- intake attempt lineage: `intake_requests.collector_spool_item_id`
- central raw lineage: `raw_item_spool_links(collector_spool_item_id, raw_item_id)`
- quality lineage: `raw_item_quality_states.raw_item_id`
- state transition lineage: `raw_item_quality_history.raw_item_id`

## Storage Principles
- raw payloads remain replayable
- metadata quality is queryable by explicit columns and state tables
- weak and quarantined rows keep lineage and replay references
- duplicate detection never destroys canonical provenance

## Retention Baseline
- `collector_spool_items`: 90 days hot (lineage + delivery diagnostics)
- `intake_requests`: 180 days
- `raw_items`: 180 days hot + archive export with hash manifest
- `raw_item_quality_history`: 365 days
- `raw_quarantine_records`: retain until resolved + 365 days
- `raw_dead_letter_records`: 365 days minimum

## Least-Privilege Boundaries (Executable)
- `signaldesk_intake_job`:
  - write `intake_requests`, `raw_items`, `raw_item_spool_links`
  - read source registry and spool-lineage tables
- `signaldesk_quality_job`:
  - read `raw_items`
  - write quality-state, duplicate, quarantine, and dead-letter tables
- `signaldesk_replay_job`:
  - read raw and quality tables
  - no permission to mutate source registry or quality decisions
- `signaldesk_normalize_job`:
  - read only rows with permitted quality states (`accepted`, `accepted_degraded`)
- `signaldesk_api`:
  - no write access to raw-ingest tables

## Ownership Boundary
- collector lane defines spool emission behavior and envelope semantics
- backend lane defines intake API behavior and validation flow
- storage lane freezes table and lineage contracts in this document and `db-schema.md`
