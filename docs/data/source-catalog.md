# Source Catalog (v0)

## Purpose
Define source inputs and ingestion behavior for MVP ranking, keyword detail evidence, watchlist tracking, and alert triggers.

## Scope Boundary
- Support only Release-1 workflows in `docs/product/mvp-scope.md`.
- Ingestion produces raw records and normalized derived records for server-side scoring.
- No sentiment LLM pipelines, no social graph ingestion, and no user-generated data in v0.

## Source Inventory
| source_id | Category | Core Use In MVP | Required Fields | Target Freshness | Ingestion Constraints | Fallback Behavior |
|---|---|---|---|---|---|---|
| `news_primary` | Financial/business news API or RSS aggregator | Mention velocity, evidence timeline, novelty detection | `external_id`, `published_at`, `source_name`, `title`, `url`, `language`, `raw_text_or_summary` | poll every 30 min | source rate limits, duplicate syndication, inconsistent timestamps | if API unavailable, keep last successful snapshot and mark affected keywords with `risk_flag=data_freshness_degraded` |
| `search_trends` | Google Trends (keyword-level interest) | Trend velocity and confirmation vs headline-only spikes | `keyword`, `window_start`, `window_end`, `interest_index`, `region`, `sample_granularity` | poll every 60 min | quota caps, sampled/relative index, sparse niche terms | if quota exceeded, skip cycle, carry forward prior normalized value up to 6h with staleness flag |
| `market_ohlcv` | Market data feed for mapped symbols | Price/volume reaction dimension and confirmation filters | `symbol`, `ts`, `open`, `high`, `low`, `close`, `volume`, `market` | every 15 min during market hours; daily close backfill | session boundaries, halted symbols, corporate action adjustments | if intraday feed delayed, use last known close-based reaction until next valid bar |
| `dart_disclosures` | DART disclosure feed | Event weight and credibility uplift for catalyst-backed moves | `filing_id`, `filed_at`, `issuer`, `symbol`, `filing_type`, `title`, `url` | poll every 30 min | delayed postings, issuer/symbol mapping ambiguity | if delayed, do not synthesize events; keep event score neutral and attach `risk_flag=event_coverage_partial` |

## Canonical Time And Identity Rules
- Store all timestamps in UTC (`timestamptz`) and render local time in clients.
- Preserve source timezone metadata when available for audit.
- Use deterministic idempotency keys:
  - news: `sha1(source_name + normalized_title + published_at_utc)`
  - trends: `sha1(keyword + region + window_end)`
  - market: `sha1(symbol + ts)`
  - disclosures: native `filing_id`
- Retain raw source payload hash for replay/debug (`raw_payload_hash`).

## Collector Metadata Contract Overlay (COL-004 Frozen)
This overlay is the collector-side, metadata-first quality contract. It runs before normalization and does not rely on AI.

### Required Envelope Fields For Every Collected Payload
- `source_id`
- `source_category`
- `collector_node_id`
- `collected_at`
- `upstream_event_at` (nullable only when source does not provide event timestamp)
- `publisher_name`
- `publisher_domain`
- `canonical_url`
- `payload_hash`
- `payload_version`
- `language`
- `market_scope`
- `title`
- `raw_payload_json`
- `idempotency_key`
- `quality_state`
- `ingest_status`

### Source-Family Metadata Requirements
| source_id | Source-specific required metadata | Conditionally required metadata | Staleness baseline |
|---|---|---|---|
| `news_primary` | `external_id` or deterministic fallback key parts, `published_at`, `source_name`, `title`, `url`, `language`, `raw_text_or_summary` | `region` when source feed provides region | `stale_source` when `published_at` older than 72h at collect time |
| `search_trends` | `keyword`, `window_start`, `window_end`, `interest_index`, `region`, `sample_granularity` | none | `stale_source` when `window_end` older than 6h |
| `market_ohlcv` | `symbol`, `ts`, `open`, `high`, `low`, `close`, `volume`, `market` | `session_id` when feed provides it | `stale_source` when `ts` older than 6h during market sessions |
| `dart_disclosures` | `filing_id`, `filed_at`, `issuer`, `symbol`, `filing_type`, `title`, `url` | none | `stale_source` when `filed_at` older than 7d for intraday freshness checks |

### Adapter-Side Quality Actions (No AI)
| condition | required action | resulting state |
|---|---|---|
| missing mandatory envelope field (`source_id`, `collected_at`, `publisher_name`, `canonical_url`, `payload_hash`) | reject from accepted lane and send evidence to dead-letter | `quality_state=dead_letter`, `ingest_status=rejected` |
| invalid or unparsable payload JSON | reject | `quality_state=dead_letter`, `ingest_status=rejected` |
| duplicate idempotency key or payload hash collision in same source scope | keep replay evidence and flag duplicate | `quality_state=duplicate`, `ingest_status=accepted` |
| malformed URL, unknown language tag, missing normally expected timestamp | downgrade | `quality_state=accepted_degraded` or `metadata_incomplete`, `ingest_status=accepted` |
| timestamp too far in future, publisher-domain registry mismatch, source metadata contradiction | quarantine | `quality_state=quarantined`, `ingest_status=accepted` (excluded from scoring publish until review) |
| source event timestamp outside freshness threshold | stale mark | `quality_state=stale_source`, `ingest_status=accepted` |

### Frozen Collector Quality States
Collector quality states are independent from scoring-layer `quality_flag` enums.

- `accepted`
- `accepted_degraded`
- `duplicate`
- `stale_source`
- `metadata_incomplete`
- `mapping_low_confidence`
- `quarantined`
- `dead_letter`

## Normalization And Mapping Requirements
- Keyword canonicalization:
  - map aliases to one canonical keyword id.
  - keep alias table for reverse lookup and audit.
- Entity mapping:
  - map keyword -> related symbols and sectors with confidence score (`0.0-1.0`).
  - do not emit symbol links below confidence threshold `0.60`.
- Deduplication:
  - collapse near-identical headlines from wire syndication within a 12h window.
  - keep one canonical record plus `duplicate_count` metadata.

## Derived Dataset Outputs Required By Scoring
These are stable targets for `BE-001` schema/API work.

| dataset | Grain | Required Columns | Produced By |
|---|---|---|---|
| `keyword_signal_timeslice` | `keyword_id` x `as_of_ts` (30-minute) | `mention_count_24h`, `mention_delta_24h`, `trend_index`, `trend_delta`, `market_reaction_raw`, `event_count_7d`, `source_coverage_ratio`, `freshness_minutes` | normalization + feature builder jobs |
| `keyword_evidence_event` | one supporting evidence item | `keyword_id`, `event_ts`, `event_type(news/trend/disclosure/market)`, `event_ref_id`, `summary_text`, `source_name`, `symbol`, `quality_flag` | evidence extraction job |
| `keyword_entity_link` | keyword-symbol relation | `keyword_id`, `symbol`, `sector`, `link_confidence`, `is_primary` | entity resolution job |

## Ingestion Failure And Recovery Policy
- Retries: exponential backoff (max 5 attempts per cycle).
- Partial failure behavior:
  - continue pipeline when at least 2 independent source categories succeeded in window.
  - block scoring publish only when fewer than 2 categories succeeded or market data is stale for >6h during market sessions.
- Backfill:
  - daily backfill job for previous 7 days of news/trends/disclosures to repair missed windows.

## Data Quality Risks (v0)
- Ambiguous entity mapping for broad keywords (`AI`, `battery`, `cloud`).
- Trend index instability for low-volume queries.
- Regional/news-source bias causing mention spikes without true market impact.
- Disclosure-to-symbol mapping latency for newly listed or renamed issuers.

## Quality Controls
- Emit `source_coverage_ratio` per keyword window to expose missing-source conditions.
- Emit `freshness_minutes` and suppress alert eligibility when freshness breaches threshold.
- Maintain per-source ingestion health metrics (`success_rate`, `p95_lag_minutes`, `dedup_ratio`).

## Contract Enums (for BE-001)
- `event_type` enum: `news`, `trend`, `disclosure`, `market`.
- `quality_flag` enum: `ok`, `deduped`, `low_source_diversity`, `mapping_low_confidence`, `stale_source`.
- `risk_flag` enum baseline from data layer (must match scoring output canonical list): `data_freshness_degraded`, `event_coverage_partial`, `mapping_unstable`, `thin_cohort`.

## Explicit Non-Goals For v0 Data Layer
- Real-time tick-level ingestion.
- Model-based sentiment scoring.
- Alternative data requiring paid enterprise licensing.
- Portfolio- or account-level personalization.
