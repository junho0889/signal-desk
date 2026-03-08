# Collector Metadata Quality V1

## Purpose
Define the frozen metadata and non-AI quality rules that every collector payload must satisfy before it can enter trusted raw-ingest lanes.

## Principle
SignalDesk should prefer fewer high-quality payloads over a larger pile of weak, duplicate, or metadata-poor records.

## Scope
- applies to collector adapter output before central scoring logic
- uses deterministic metadata and rule checks only
- does not rely on AI or learned quality scoring

## Frozen Envelope Fields
These fields are required unless explicitly marked nullable.

| field | required | notes |
|---|---|---|
| `source_id` | yes | one of the registered source adapters |
| `source_category` | yes | `news`, `trend`, `market`, or `disclosure` |
| `collector_node_id` | yes | collector instance identity |
| `collected_at` | yes | UTC timestamp when collector received payload |
| `upstream_event_at` | conditional | nullable only when source does not provide event time |
| `publisher_name` | yes | canonical publisher label |
| `publisher_domain` | yes | normalized domain extracted from URL |
| `canonical_url` | yes | normalized URL used for dedupe scope |
| `external_id` | conditional | required when source provides it |
| `payload_hash` | yes | sha256 hash over canonical payload representation |
| `payload_version` | yes | envelope/payload schema version |
| `language` | yes | RFC-style language tag; unknown allowed only with downgrade |
| `market_scope` | yes | expected market universe tag |
| `title` | yes | human-readable summary label |
| `raw_payload_json` | yes | replayable source payload body |
| `idempotency_key` | yes | deterministic source-family key |
| `adapter_version` | yes | adapter implementation version |
| `retrieval_status` | yes | adapter fetch status (`ok`, `partial`, `error`) |
| `source_cursor` | conditional | required when source is cursor-driven |

## Source-Family Idempotency Rules
- `news_primary`: `sha1(source_name + normalized_title + published_at_utc)`
- `search_trends`: `sha1(keyword + region + window_end)`
- `market_ohlcv`: `sha1(symbol + ts)`
- `dart_disclosures`: use native `filing_id`

## Quality States (Frozen)
- `accepted`
- `accepted_degraded`
- `duplicate`
- `stale_source`
- `metadata_incomplete`
- `mapping_low_confidence`
- `quarantined`
- `dead_letter`

## Ingest Status (Frozen)
- `accepted`
- `rejected`

## Rule Execution Order
1. structural validation
2. metadata completeness checks
3. URL/domain normalization and registry match
4. timestamp sanity and freshness checks
5. idempotency and duplicate detection
6. quarantine checks for suspicious but parseable payloads
7. final quality-state assignment

## Non-AI Action Rules (Frozen)

### Reject Rules
Reject from accepted lane and mark dead-letter evidence when any condition is true:
- missing required core fields: `source_id`, `collected_at`, `publisher_name`, `canonical_url`, `payload_hash`, `raw_payload_json`
- unparsable or non-JSON payload body when JSON is the declared encoding
- impossible timestamp format for `collected_at`
- payload hash mismatch after canonicalization

Result:
- `quality_state=dead_letter`
- `ingest_status=rejected`

### Downgrade Rules
Accept but downgrade quality when metadata is incomplete or low confidence:
- missing `upstream_event_at` where source usually provides one
- malformed URL corrected by normalizer but confidence reduced
- unknown `language` token
- weak entity symbol candidates or unresolved mapping hints

Result:
- `quality_state=accepted_degraded` or `metadata_incomplete` (or `mapping_low_confidence` when mapping-specific)
- `ingest_status=accepted`

### Duplicate Rules
When idempotency key already exists for the same source scope:
- keep replayable payload and metadata evidence
- do not create a second canonical accepted row

Result:
- `quality_state=duplicate`
- `ingest_status=accepted`

### Stale Rules
Mark stale but retain replayable evidence:
- `news_primary`: `published_at` older than 72h at collection time
- `search_trends`: `window_end` older than 6h
- `market_ohlcv`: bar timestamp older than 6h during active market session
- `dart_disclosures`: `filed_at` older than 7d for intraday freshness use

Result:
- `quality_state=stale_source`
- `ingest_status=accepted`

### Quarantine Rules
Quarantine parseable payloads that look suspicious or policy-unsafe:
- publisher-domain mismatch against source registry policy
- timestamp too far in future (>10 minutes ahead of collector time)
- source metadata contradiction requiring manual review

Result:
- `quality_state=quarantined`
- `ingest_status=accepted`
- excluded from downstream scoring publish until reviewed

## Adapter Evidence Requirements
Every adapter write must persist or log enough evidence for replay and QA:
- normalized envelope metadata
- raw payload body
- adapter version
- retrieval status
- idempotency key and payload hash
- source cursor/checkpoint (when available)
- final `quality_state` and `ingest_status`
- rule reason code for downgrade, quarantine, duplicate, stale, or reject outcomes

## Storage/Backend/QA Frozen Contract Fields
The following fields are frozen for downstream lanes to consume consistently:
- `source_id`
- `source_category`
- `collector_node_id`
- `collected_at`
- `upstream_event_at`
- `publisher_name`
- `publisher_domain`
- `canonical_url`
- `payload_hash`
- `payload_version`
- `idempotency_key`
- `quality_state`
- `ingest_status`
- `retry_count`
- `last_error_code`
- `adapter_version`
- `retrieval_status`

## Test Expectations
- fixture ingest must land rows in the local collector test database
- query evidence must show metadata completeness and state transitions
- weak or malformed fixtures must demonstrate reject, downgrade, stale, duplicate, or quarantine behavior explicitly
- rerun with same fixture must show idempotent behavior without duplicate canonical accepted rows

## Release-Gate Note
Until broader runnable collector output exists across lanes, orchestrator review is the active gate for this contract freeze and QA review is deferred by direction.
