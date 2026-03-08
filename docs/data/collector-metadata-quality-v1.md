# Collector Metadata Quality V1

## Purpose
Define the metadata and non-AI quality rules that every collector payload must satisfy before it becomes trusted raw evidence.

## Principle
SignalDesk should prefer fewer high-quality payloads over a larger pile of weak, duplicate, or metadata-poor records.

## Required Metadata Per Raw Payload
- `source_id`
- `source_category`
- `collector_node_id`
- `collected_at`
- `upstream_event_at` when available
- `publisher_name`
- `publisher_domain`
- `canonical_url`
- `external_id` when the source provides one
- `payload_hash`
- `payload_version`
- `language`
- `market_scope`
- `title` or equivalent human-readable label
- `raw_payload_json`

## Recommended Metadata
- `author_name`
- `region`
- `content_type`
- `summary_text`
- `symbol_candidates`
- `keyword_candidates`
- `duplicate_of_hash`
- `source_priority_tier`

## Minimum Acceptance Rules
- reject payloads missing `source_id`, `collected_at`, `publisher_name`, `canonical_url`, or `payload_hash`
- downgrade payloads missing `upstream_event_at` when the source normally supplies it
- downgrade payloads with unknown `language` or malformed URLs
- keep raw payloads replayable even when downgraded, unless they are structurally invalid

## Quality States
- `accepted`
- `accepted_degraded`
- `duplicate`
- `stale_source`
- `metadata_incomplete`
- `mapping_low_confidence`
- `quarantined`
- `dead_letter`

## Non-AI Filters The Collector Must Apply
- canonical URL normalization
- publisher-domain extraction and allowlist or registry match
- source-specific idempotency key derivation
- timestamp sanity check
- duplicate and near-duplicate detection when the source makes this possible
- basic language and market-scope tagging

## Why This Matters
- trust and ranking are only as good as the raw evidence
- metadata completeness lets backend, trust, and QA reason about failures
- many bad payloads can be filtered before any model exists

## Adapter Evidence Requirements
Every source adapter should emit:
- the raw payload
- normalized envelope metadata
- adapter version
- retrieval status
- any source-side cursor or checkpoint needed for replay

## Test Expectations
- fixture ingest must land rows in the local collector test database
- query evidence must show metadata completeness and state transitions
- weak or malformed fixtures must demonstrate reject, downgrade, or quarantine behavior explicitly
