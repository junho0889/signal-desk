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

## Recent Spool Evidence Snapshot (2026-03-09, collector-003 fixture rerun)
Evidence source:
- local collector test-db query against `spool_items` after bootstrap, fixture ingest x2, and shipper simulate-offline x1

| metric | observed | note |
|---|---:|---|
| spool rows | `2` | fixture payload count |
| total ingest events (`SUM(ingest_count)`) | `4` | rerun doubled ingest counters |
| metadata completeness ratio | `100.00%` | all required envelope fields present |
| duplicate ratio (`(sum(ingest_count)-count(*))/sum(ingest_count)`) | `50.00%` | high during rerun scenario |
| `quality_state=duplicate` row ratio | `100.00%` | both canonical rows moved to duplicate state after rerun |
| stale ratio (`quality_state=stale_source`) | `0.00%` | no stale fixture evidence |
| missing required fields ratio | `0.00%` | none missing in fixture |
| blank `source_cursor` ratio | `100.00%` | currently empty for `news_primary` fixture |
| publisher/domain validity (`publisher_domain` matches URL host) | `100.00%` | fixture domain valid |
| shipper retry-marked rows | `2/2` | `retry_count=1`, `last_intake_status=retryable_failure` |

## TOP 5 FIXES
1. Preserve canonical quality state on idempotent reruns.
- observed gap: rerun turns all rows into `quality_state=duplicate`, collapsing canonical `accepted` evidence.
- threshold: `quality_state=duplicate` row ratio must stay `< 5%` in normal ingestion windows; idempotent reruns should not rewrite canonical row quality state.
- exact collector rule change:
  - on `ON CONFLICT (idempotency_key)`, keep existing `quality_state` unless new payload hash conflicts unexpectedly.
  - increment `ingest_count`, set `reason_code=idempotent_rerun`, and keep canonical row in accepted lane.
  - use `quality_state=duplicate` only for true duplicate payload records that are not canonical.
- implementation detail:
  - update upsert clause in collector ingest SQL to avoid unconditional quality-state override.
  - add `duplicate_hits` counter (or equivalent) if duplicate frequency is needed without state rewrite.

2. Make `source_cursor` policy explicit by source family.
- observed gap: `source_cursor` is blank in `100%` of sampled rows, but policy currently treats it as conditional without enforcement.
- threshold: cursor-driven sources must have `source_cursor` missing ratio `0%`; non-cursor sources must emit `source_cursor='not_applicable'`.
- exact collector rule change:
  - maintain source-level config `requires_cursor` in adapter settings.
  - if `requires_cursor=true` and cursor missing, set `quality_state=metadata_incomplete` and `reason_code=cursor_missing`.
  - if `requires_cursor=false`, emit literal `not_applicable` instead of blank.
- implementation detail:
  - enforce during envelope build, before DB write.
  - add query check for blank cursor values as a release gate.

3. Enforce strict publisher-domain validation with quarantine behavior.
- observed gap: domain validity is `100%` in fixtures, but only one trusted fixture domain is covered.
- threshold: `publisher_domain_valid_pct` must remain `100%`; any mismatch goes to quarantine, not accepted lane.
- exact collector rule change:
  - normalize hostname from `canonical_url` and compare with normalized `publisher_domain`.
  - if mismatch or parsing fails, set `quality_state=quarantined`, `ingest_status=accepted`, `reason_code=publisher_domain_mismatch`.
  - require explicit allowlist entry per source family before moving from quarantine.
- implementation detail:
  - implement deterministic domain normalizer (lowercase + punycode handling).
  - add per-source allowlist map and quarantine audit query.

4. Add source-family stale checks with measurable limits.
- observed gap: stale ratio is `0%`, but stale rule execution has no explicit sampled evidence in current fixture set.
- threshold: stale ratio targets by source family:
  - `news_primary` <= `10%` per 24h ingest window
  - `search_trends` <= `5%` per 24h
  - `market_ohlcv` <= `2%` during market session windows
  - `dart_disclosures` <= `15%` per 24h
- exact collector rule change:
  - evaluate source-specific freshness windows at ingest time.
  - rows beyond threshold set `quality_state=stale_source`, `reason_code=stale_threshold_exceeded`.
  - stale rows remain replayable but excluded from default publish candidate queries.
- implementation detail:
  - introduce fixture cases intentionally stale for each source family.
  - add stale-ratio SQL query to smoke verification commands.

5. Add field-level missing metadata telemetry and hard reject gates.
- observed gap: completeness is `100%` on tiny fixture sample, but per-field missing telemetry is not persisted in a queryable structure.
- threshold:
  - core required field missing ratio must be `0%` (hard reject to dead-letter).
  - non-core recommended field missing ratio alert at `> 20%`.
- exact collector rule change:
  - compute `missing_required_fields` and `missing_recommended_fields` arrays per payload.
  - if required array non-empty, set `quality_state=dead_letter`, `ingest_status=rejected`, and persist exact missing list.
  - if only recommended fields missing, allow `accepted_degraded` with reason codes.
- implementation detail:
  - add explicit missing-field computation in adapter envelope pipeline.
  - expose missing-field counters in spool evidence SQL for QA gating.

## Test Expectations
- fixture ingest must land rows in the local collector test database
- query evidence must show metadata completeness and state transitions
- weak or malformed fixtures must demonstrate reject, downgrade, stale, duplicate, or quarantine behavior explicitly
- rerun with same fixture must show idempotent behavior without duplicate canonical accepted rows

## Release-Gate Note
Until broader runnable collector output exists across lanes, orchestrator review is the active gate for this contract freeze and QA review is deferred by direction.
