# Intelligence Platform Topology

## Purpose
Define the next-phase split between always-on collection, central storage, trust scoring, ranking, API delivery, and mobile consumption.

## Frozen Topology (COL-001)
1. `collector-node` on Raspberry Pi 4B 8GB
- runs source adapters continuously for `news_primary`, `search_trends`, `market_ohlcv`, and `dart_disclosures`
- writes every collected payload to local durable spool before any central transfer attempt
- runs transfer worker with retry/backoff and central acknowledgement handling
- emits heartbeat, backlog age, queue depth, and per-source success metrics

2. `central-intake` on the main host
- accepts raw collector payload envelopes via transport-agnostic intake boundary (HTTP endpoint or shared object/file drop translated by intake worker)
- writes canonical raw-ingest ledger in central storage
- returns acknowledgement result (`accepted`, `duplicate`, or `rejected`) per `spool_id`

3. `central-storage` on the main host
- remains authoritative for raw history, normalized entities, trust outputs, model features, ranking snapshots, and API read models
- no authoritative ranking or canonical DB state exists on the Pi

4. `normalization + trust + ranking jobs`
- normalize canonical raw intake records into entities/evidence
- compute freshness, quality, contradiction, and trust outputs
- publish explainable ranking and alert evaluation outputs

5. `api` and `mobile`
- API serves stable read models only
- mobile consumes documented contracts; it does not query collector-node directly

## Collector Lifecycle (Frozen)
1. scheduler triggers source adapter cycle (poll or webhook intake handling)
2. adapter fetches upstream payload and validates minimum required fields for the source
3. spool writer persists envelope + payload to local durable storage and marks item `queued`
4. transfer worker acquires queued item lease and attempts central delivery
5. on transient failure, item is released with incremented retry metadata and future `next_attempt_at_utc`
6. on central `accepted` or `duplicate` acknowledgement, item is marked `acked`
7. prune worker removes `acked` or `dead_letter` items using retention rules

Source-cycle success is defined as "payload safely spooled", not "centrally ingested".

## Local Spool Contract (Frozen)
Each spool item is one immutable payload body plus mutable delivery metadata.

### Required Envelope Fields
| field | type | notes |
|---|---|---|
| `spool_id` | `uuid` | collector-generated immutable id for delivery tracking |
| `source_id` | `enum` | `news_primary`, `search_trends`, `market_ohlcv`, `dart_disclosures` |
| `adapter_mode` | `enum` | `poll`, `webhook`, or `backfill` |
| `collected_at_utc` | `timestamptz` | when collector received payload |
| `upstream_event_ts_utc` | `timestamptz?` | source event timestamp when available |
| `idempotency_key` | `text` | deterministic key following `docs/data/source-catalog.md` identity rules |
| `payload_hash_sha256` | `text` | integrity and duplicate detection |
| `payload_encoding` | `enum` | `json`, `json_gzip`, or `csv` |
| `payload_bytes` | `integer` | payload size in bytes |
| `status` | `enum` | `queued`, `inflight`, `acked`, `dead_letter` |
| `retry_count` | `integer` | transfer attempts already made |
| `next_attempt_at_utc` | `timestamptz` | retry scheduler target time |
| `last_error_code` | `text?` | most recent transport or validation error |
| `last_error_at_utc` | `timestamptz?` | time of most recent failure |
| `lease_token` | `text?` | transfer worker lease guard for inflight handling |
| `lease_expires_at_utc` | `timestamptz?` | stale lease recovery boundary |
| `ack_code` | `enum?` | `accepted`, `duplicate`, `rejected` when central response exists |
| `ack_id` | `text?` | central acknowledgement id for audit |
| `acked_at_utc` | `timestamptz?` | collector receipt time of ack |
| `expires_at_utc` | `timestamptz` | spool retention deadline for cleanup safety |

### Spool State Rules
- `queued -> inflight` requires lease acquisition.
- `inflight -> queued` occurs on transient failure or lease expiry.
- `inflight -> acked` requires central `accepted` or `duplicate`.
- `inflight -> dead_letter` occurs on non-retriable rejection or retry budget exhaustion.

### Prune Rules
- `acked` items: keep at least 24h for local audit/replay, then prune.
- `dead_letter` items: keep 7 days for operator inspection before prune.
- if spool disk usage exceeds 80%, suspend non-critical backfill cycles first and keep primary polling active.
- prune must never delete `queued` or `inflight` records.

## Source Adapter Plan (Frozen)
| source_id | adapter type | baseline cadence | cycle success | output requirement |
|---|---|---|---|---|
| `news_primary` | poll adapter | every 30 minutes | raw items persisted to spool | include `external_id` or generated idempotency parts, `published_at`, `source_name`, `title`, `url`, `language`, body/summary payload |
| `search_trends` | poll adapter | every 60 minutes | raw window data persisted to spool | include `keyword`, `window_start`, `window_end`, `interest_index`, `region`, `sample_granularity` |
| `market_ohlcv` | poll adapter | every 15 minutes in market sessions + daily close backfill | bars persisted to spool | include `symbol`, `ts`, `open`, `high`, `low`, `close`, `volume`, `market` |
| `dart_disclosures` | poll adapter | every 30 minutes | disclosure payload persisted to spool | include `filing_id`, `filed_at`, `issuer`, `symbol`, `filing_type`, `title`, `url` |

Adapter errors are isolated per source so one failing source does not stop other adapter cycles.

## Retry Policy (Frozen)
- upstream source fetch retries: exponential backoff up to 5 attempts per cycle (aligned with data-layer policy)
- central delivery retries:
  - retriable conditions: timeout, network unreachable, HTTP 429, HTTP 5xx, temporary intake unavailable
  - base backoff: 30 seconds with multiplier 2.0 and jitter +/-20%
  - max backoff per item: 10 minutes
  - retry budget: 20 attempts or 24h from `collected_at_utc`, whichever comes first
  - exhausted items transition to `dead_letter` with final error metadata

## Central Acknowledgement Flow (Frozen)
1. collector sends envelope + payload (`spool_id`, `idempotency_key`, `payload_hash_sha256`, source metadata, payload body)
2. central intake validates envelope and writes durable raw-ingest record
3. central intake returns acknowledgement payload:
   - `ack_code`: `accepted` when newly stored
   - `ack_code`: `duplicate` when idempotency key/hash already exists
   - `ack_code`: `rejected` with reason for non-retriable contract failure
   - `ack_id` and `acked_at_utc` always present for handled responses
4. collector marks local spool item:
   - `accepted` or `duplicate` -> `acked`
   - `rejected` -> `dead_letter` unless operator overrides for replay

Collector must never treat request dispatch without acknowledgement as success.

## Responsibility Boundary (Frozen)
| area | collector-node (Pi) | central host |
|---|---|---|
| source polling/webhook intake | owner | none |
| local durability before transfer | owner | none |
| canonical raw history | buffer copy only | authoritative owner |
| normalization/entity mapping | none | owner |
| trust/model scoring | none | owner |
| API serving | none | owner |
| ranking/alert source of truth | none | owner |

## Frozen Contracts For Next Wave
- storage lane (`BE-004`): central raw-ingest schema must accept frozen spool envelope fields and ack semantics above
- model lane (`MODEL-001`): consume source freshness and provenance from centrally acknowledged raw records only
- trust lane (`TRUST-001`): trust/contradiction logic must reference canonical central records, not transient Pi spool state
- ops lane (`signal-desk-ops`): operating thresholds and runbook checks must include spool age, queue depth, and dead-letter monitoring
