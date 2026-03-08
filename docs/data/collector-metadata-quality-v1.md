# Collector Metadata Quality V1

## Purpose
Define the metadata and quality-state contract that collector and backend must share for raw-ingest persistence.

## Contract Principle
- metadata quality must be queryable from explicit columns and state tables
- replayability must be preserved for accepted, degraded, duplicate, stale, and quarantined payloads
- dead-letter cases must remain auditable even when raw-row creation fails

## Required Metadata Fields (Frozen)
| field | required | notes |
|---|---|---|
| `source_id` | yes | must resolve to `ingest_sources.source_id` |
| `source_category` | yes | must match source registry category |
| `collector_node_id` | yes | must resolve to registered collector node |
| `spool_item_key` | yes | unique collector spool identity |
| `retry_count` | yes | collector-reported retry attempt count |
| `idempotency_key` | yes | source-scoped deterministic key |
| `payload_hash` | yes | replay and duplicate detection anchor |
| `payload_version` | yes | payload schema version |
| `collected_at` | yes | collector capture timestamp |
| `upstream_event_at` | conditional | required when source contract marks expected upstream event time |
| `publisher_name` | yes | canonical publisher label |
| `publisher_domain` | yes | normalized domain |
| `canonical_url` | yes | normalized URL |
| `external_id` | conditional | required when source provides external identifiers |
| `language` | yes | unknown allowed only with degraded quality state |
| `market_scope` | yes | `kr`, `us`, `all`, or `unknown` |
| `title` | yes | human-readable item label |
| `raw_payload_json` | yes | immutable payload body |

## Recommended Metadata Fields
- `author_name`
- `region`
- `content_type`
- `summary_text`
- `symbol_candidates`
- `keyword_candidates`
- `source_priority_tier`
- `source_cursor`
- `duplicate_of_hash`

## Storage Mapping (Frozen)
- source registry:
  - `ingest_sources`
  - `ingest_source_domains`
  - `source_contract_versions`
- spool lineage:
  - `collector_nodes`
  - `collector_spool_runs`
  - `collector_spool_items`
- central raw persistence:
  - `intake_requests`
  - `raw_items`
  - `raw_item_spool_links`
- quality persistence:
  - `raw_item_quality_states`
  - `raw_item_quality_history`
  - `raw_duplicate_links`
  - `raw_quarantine_records`
  - `raw_dead_letter_records`

## Quality States (Frozen Enum)
- `accepted`
- `accepted_degraded`
- `duplicate`
- `stale_source`
- `metadata_incomplete`
- `mapping_low_confidence`
- `quarantined`
- `dead_letter`

## State Assignment Rules
1. `accepted`
- all required metadata fields are present and structurally valid.
2. `accepted_degraded`
- payload is structurally valid and replayable, but one or more quality concerns are present.
3. `duplicate`
- idempotency or hash logic maps payload to existing canonical row.
4. `stale_source`
- source recency thresholds are exceeded for the source category.
5. `metadata_incomplete`
- structurally valid payload with missing required metadata.
6. `quarantined`
- payload is blocked from normal normalization pending review.
7. `dead_letter`
- non-retryable failure; payload or metadata is stored for audit with replay guidance.

## Non-AI Validation Filters
- canonical URL normalization
- publisher-domain extraction and registry match
- source-specific idempotency derivation
- timestamp sanity checks
- duplicate detection
- language and market-scope validation

## Replay And Lineage Guarantees
- every accepted central raw row must map to one `collector_spool_items` row through `raw_item_spool_links`.
- every state transition must append to `raw_item_quality_history`.
- duplicate rows must link to canonical rows via `raw_duplicate_links`.
- quarantine and dead-letter records must include reason and operator-facing notes.

## Verification Expectations
- fixture ingest proves required-field persistence and state assignment.
- duplicate and stale fixtures prove deterministic state transitions.
- quarantine and dead-letter fixtures prove replay auditability.
