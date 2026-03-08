# Database Schema

## Scope
This schema defines the BE-001 baseline for ranking, detail, watchlist, and alerts contracts.

## Conventions
- id columns: UUID (`gen_random_uuid()`), unless noted
- timestamps: `timestamptz` in UTC
- score precision follows DATA-001 contract:
  - score/delta/dimension fields: `numeric(5,2)`
  - confidence: `numeric(4,3)`
- text enums are documented as constrained values and should be backed by `CHECK` constraints

## Core Tables

### `keywords`
Purpose: canonical keyword entity.

Columns:
- `id` UUID PK
- `canonical_name` text not null unique
- `market_scope` text not null check in (`kr`,`us`,`all`)
- `sector_hint` text null
- `created_at` timestamptz not null default `now()`

Indexes:
- unique (`canonical_name`)
- btree (`market_scope`)

### `keyword_snapshots`
Purpose: read model for ranking and detail.

Columns:
- `id` UUID PK
- `keyword_id` UUID not null FK -> `keywords.id`
- `as_of_ts` timestamptz not null
- `score_total` numeric(5,2) not null
- `score_delta_24h` numeric(5,2) null
- `confidence` numeric(4,3) not null
- `rank_position` integer not null
- `dimension_mentions` numeric(5,2) null
- `dimension_trends` numeric(5,2) null
- `dimension_market` numeric(5,2) null
- `dimension_events` numeric(5,2) null
- `dimension_persistence` numeric(5,2) null
- `is_alert_eligible` boolean not null default `false`
- `reason_tags` text[] not null default `'{}'::text[]`
- `risk_flags` text[] not null default `'{}'::text[]`

Constraints:
- unique (`keyword_id`,`as_of_ts`)
- check (`confidence` >= 0.000 and `confidence` <= 1.000)
- check (all `risk_flags` entries are in `data_freshness_degraded|event_coverage_partial|mapping_unstable|thin_cohort`)

Indexes:
- btree (`as_of_ts` desc)
- btree (`score_total` desc)
- btree (`is_alert_eligible`,`as_of_ts` desc)
- gin (`reason_tags`)
- gin (`risk_flags`)

### `news_items`
Purpose: normalized news document metadata.

Columns:
- `id` UUID PK
- `source_name` text not null
- `published_at` timestamptz not null
- `title` text not null
- `url` text not null
- `normalized_hash` text not null unique
- `created_at` timestamptz not null default `now()`

Indexes:
- unique (`normalized_hash`)
- btree (`published_at` desc)

### `keyword_news_links`
Purpose: map keywords to evidence news.

Columns:
- `keyword_id` UUID not null FK -> `keywords.id`
- `news_item_id` UUID not null FK -> `news_items.id`
- `snapshot_id` UUID null FK -> `keyword_snapshots.id`
- `relevance_score` numeric(5,2) null

Constraints:
- primary key (`keyword_id`,`news_item_id`)

Indexes:
- btree (`news_item_id`)
- btree (`snapshot_id`)

### `stocks`
Purpose: canonical stock reference.

Columns:
- `id` UUID PK
- `ticker` text not null
- `name` text not null
- `market` text not null check in (`kr`,`us`)
- `sector` text null

Constraints:
- unique (`market`,`ticker`)

Indexes:
- btree (`sector`)

### `keyword_stock_links`
Purpose: map keywords to related stocks.

Columns:
- `keyword_id` UUID not null FK -> `keywords.id`
- `stock_id` UUID not null FK -> `stocks.id`
- `snapshot_id` UUID null FK -> `keyword_snapshots.id`
- `link_confidence` numeric(4,3) null

Constraints:
- primary key (`keyword_id`,`stock_id`)

Indexes:
- btree (`stock_id`)
- btree (`snapshot_id`)

### `keyword_sector_links`
Purpose: materialized sector mapping used by dashboard and detail APIs.

Columns:
- `keyword_id` UUID not null FK -> `keywords.id`
- `sector` text not null
- `snapshot_id` UUID null FK -> `keyword_snapshots.id`
- `link_confidence` numeric(4,3) null

Constraints:
- primary key (`keyword_id`,`sector`)

Indexes:
- btree (`sector`)
- btree (`snapshot_id`)

### `watchlist_items`
Purpose: tracked targets for alerts and watchlist view.

Columns:
- `id` UUID PK
- `target_type` text not null check in (`keyword`,`stock`)
- `target_id` UUID not null
- `created_at` timestamptz not null default `now()`

Constraints:
- unique (`target_type`,`target_id`)

Indexes:
- btree (`created_at` desc)

### `watchlist_alert_rules`
Purpose: per-item alert behavior.

Columns:
- `id` UUID PK
- `watchlist_item_id` UUID not null unique FK -> `watchlist_items.id`
- `is_enabled` boolean not null default `true`
- `min_severity` text not null default `medium` check in (`low`,`medium`,`high`,`critical`)
- `cooldown_minutes` integer not null default `60`
- `updated_at` timestamptz not null default `now()`

Indexes:
- btree (`is_enabled`,`min_severity`)

### `alerts`
Purpose: emitted alert events.

Columns:
- `id` UUID PK
- `target_type` text not null check in (`keyword`,`stock`)
- `target_id` UUID not null
- `keyword_id` UUID null FK -> `keywords.id`
- `watchlist_item_id` UUID null FK -> `watchlist_items.id`
- `triggered_at` timestamptz not null
- `severity` text not null check in (`low`,`medium`,`high`,`critical`)
- `message` text not null

Indexes:
- btree (`triggered_at` desc)
- btree (`severity`,`triggered_at` desc)
- btree (`target_type`,`target_id`,`triggered_at` desc)

## Relationship Notes
- `keyword_snapshots` is the primary source for ranking/detail reads.
- Link tables optionally reference `snapshot_id` to support evidence views at a specific scoring point.
- `watchlist_items.target_id` is polymorphic by `target_type`; FK enforcement is handled in service logic or triggers.

## Role And Privilege Expectations
- migrations run as `signaldesk_migrator`; this role owns schema objects
- API and jobs run as `signaldesk_app`; no ownership privileges
- diagnostics use `signaldesk_readonly`; select-only privileges
- superuser is bootstrap/admin only and never used by API/jobs runtime

Required grants pattern:
- schema `public` ownership and create rights: `signaldesk_migrator`
- table DML (`SELECT/INSERT/UPDATE/DELETE`): `signaldesk_app`
- table read (`SELECT`): `signaldesk_readonly`
- sequence usage/select/update: `signaldesk_app`
- sequence read: `signaldesk_readonly`

## API Mapping
- Home: `keyword_snapshots`, `keyword_sector_links`, `alerts`
- Keyword ranking: latest `keyword_snapshots` by `as_of_ts` (+ query-time period slicing)
- Keyword detail: `keyword_snapshots` + link tables + `news_items` + `stocks`
- Watchlist: `watchlist_items` + latest snapshots + `watchlist_alert_rules`
- Alerts: `alerts` ordered by `triggered_at`

## Open Implementation Notes
- Keep `reason_tags` and `risk_flags` array types stable for API compatibility.
- Enforce canonical `risk_flags` values in migrations to prevent DATA/BE enum drift.
- Multi-user ownership for watchlist is intentionally out of scope for current personal-use MVP.

## BE-008 Raw-Ingest Metadata And Quality Contract Freeze

### Compatibility Boundary
- BE-008 is additive and does not change BE-001 API payload contracts.
- raw-ingest and quality-state tables are frozen so collector and backend validate against one storage model.

### Source Registry Tables

#### `ingest_sources`
Purpose: canonical source registry aligned with collector and intake contracts.

Columns:
- `id` UUID PK
- `source_id` text not null unique
- `source_category` text not null check in (`news`,`search_trends`,`market_ohlcv`,`dart_disclosures`,`other`)
- `display_name` text not null
- `is_active` boolean not null default `true`
- `expected_upstream_event_at` boolean not null default `false`
- `created_at` timestamptz not null default `now()`

Indexes:
- unique (`source_id`)
- btree (`source_category`,`is_active`)

#### `ingest_source_domains`
Purpose: allowed or expected publisher domains for source-level validation.

Columns:
- `id` UUID PK
- `ingest_source_id` UUID not null FK -> `ingest_sources.id`
- `publisher_domain` text not null
- `is_allowlisted` boolean not null default `true`
- `created_at` timestamptz not null default `now()`

Constraints:
- unique (`ingest_source_id`,`publisher_domain`)

Indexes:
- btree (`publisher_domain`)

#### `source_contract_versions`
Purpose: track source metadata contract changes by version.

Columns:
- `id` UUID PK
- `ingest_source_id` UUID not null FK -> `ingest_sources.id`
- `contract_version` text not null
- `required_fields` text[] not null
- `effective_from` timestamptz not null
- `effective_to` timestamptz null
- `created_at` timestamptz not null default `now()`

Constraints:
- unique (`ingest_source_id`,`contract_version`)

Indexes:
- btree (`ingest_source_id`,`effective_from` desc)

### Collector Spool Lineage Tables

#### `collector_nodes`
Purpose: collector identity registry.

Columns:
- `id` UUID PK
- `collector_node_id` text not null unique
- `node_name` text not null
- `last_seen_at` timestamptz null
- `created_at` timestamptz not null default `now()`

Indexes:
- unique (`collector_node_id`)
- btree (`last_seen_at` desc)

#### `collector_spool_runs`
Purpose: one collector spool cycle (poll or webhook batch preparation).

Columns:
- `id` UUID PK
- `collector_node_id` UUID not null FK -> `collector_nodes.id`
- `ingest_source_id` UUID not null FK -> `ingest_sources.id`
- `spool_window_start` timestamptz null
- `spool_window_end` timestamptz null
- `run_status` text not null check in (`running`,`succeeded`,`partial`,`failed`)
- `started_at` timestamptz not null
- `completed_at` timestamptz null
- `adapter_version` text not null

Indexes:
- btree (`collector_node_id`,`started_at` desc)
- btree (`ingest_source_id`,`started_at` desc)

#### `collector_spool_items`
Purpose: per-item spool lineage row from collector before central acceptance.

Columns:
- `id` UUID PK
- `collector_spool_run_id` UUID not null FK -> `collector_spool_runs.id`
- `spool_item_key` text not null
- `idempotency_key` text not null
- `payload_hash` text not null
- `payload_version` text not null
- `retrieval_status` text not null check in (`ok`,`partial`,`failed`)
- `spooled_at` timestamptz not null
- `retry_count` integer not null default `0`
- `last_delivery_status` text null check in (`accepted`,`duplicate`,`rejected`,`retryable_failure`)

Constraints:
- unique (`spool_item_key`)
- unique (`collector_spool_run_id`,`idempotency_key`)

Indexes:
- btree (`payload_hash`)
- btree (`last_delivery_status`,`spooled_at` desc)

### Central Intake And Raw Persistence

#### `intake_requests`
Purpose: central intake attempt log for each submitted spool item.

Columns:
- `id` UUID PK
- `collector_spool_item_id` UUID not null FK -> `collector_spool_items.id`
- `ingest_source_id` UUID not null FK -> `ingest_sources.id`
- `request_received_at` timestamptz not null
- `response_class` text not null check in (`accepted`,`duplicate`,`rejected`,`retryable_failure`)
- `validation_code` text null
- `request_payload_hash` text not null
- `attempt_number` integer not null

Constraints:
- unique (`collector_spool_item_id`,`attempt_number`)

Indexes:
- btree (`request_received_at` desc)
- btree (`response_class`,`request_received_at` desc)

#### `raw_items`
Purpose: immutable central raw evidence row with explicit metadata columns.

Columns:
- `id` UUID PK
- `ingest_source_id` UUID not null FK -> `ingest_sources.id`
- `collector_node_id` UUID not null FK -> `collector_nodes.id`
- `source_category` text not null check in (`news`,`search_trends`,`market_ohlcv`,`dart_disclosures`,`other`)
- `idempotency_key` text not null
- `payload_hash` text not null
- `payload_version` text not null
- `collector_retry_count` integer not null default `0`
- `collected_at` timestamptz not null
- `upstream_event_at` timestamptz null
- `ingested_at` timestamptz not null default `now()`
- `publisher_name` text not null
- `publisher_domain` text not null
- `canonical_url` text not null
- `external_id` text null
- `language` text not null
- `market_scope` text not null check in (`kr`,`us`,`all`,`unknown`)
- `title` text not null
- `raw_payload_json` jsonb not null
- `metadata_completeness` numeric(5,2) not null

Constraints:
- unique (`ingest_source_id`,`idempotency_key`)

Indexes:
- btree (`ingest_source_id`,`ingested_at` desc)
- btree (`payload_hash`)
- btree (`upstream_event_at` desc)
- btree (`publisher_domain`)
- btree (`metadata_completeness`)
- gin (`raw_payload_json`)

#### `raw_item_spool_links`
Purpose: frozen lineage join between collector spool rows and central raw rows.

Columns:
- `collector_spool_item_id` UUID not null FK -> `collector_spool_items.id`
- `raw_item_id` UUID not null FK -> `raw_items.id`
- `linked_at` timestamptz not null default `now()`

Constraints:
- primary key (`collector_spool_item_id`,`raw_item_id`)
- unique (`collector_spool_item_id`)

Indexes:
- btree (`raw_item_id`)

### Metadata Quality-State Persistence

#### `raw_item_quality_states`
Purpose: current quality state for a raw row.

Columns:
- `raw_item_id` UUID not null primary key FK -> `raw_items.id`
- `quality_state` text not null check in (`accepted`,`accepted_degraded`,`duplicate`,`stale_source`,`metadata_incomplete`,`mapping_low_confidence`,`quarantined`,`dead_letter`)
- `state_reason_codes` text[] not null default `'{}'::text[]
- `missing_required_fields` text[] not null default `'{}'::text[]
- `is_replayable` boolean not null default `true`
- `updated_at` timestamptz not null default `now()`

Indexes:
- btree (`quality_state`,`updated_at` desc)
- gin (`state_reason_codes`)
- gin (`missing_required_fields`)

#### `raw_item_quality_history`
Purpose: append-only transition history for quality-state changes.

Columns:
- `id` UUID PK
- `raw_item_id` UUID not null FK -> `raw_items.id`
- `from_state` text null check in (`accepted`,`accepted_degraded`,`duplicate`,`stale_source`,`metadata_incomplete`,`mapping_low_confidence`,`quarantined`,`dead_letter`)
- `to_state` text not null check in (`accepted`,`accepted_degraded`,`duplicate`,`stale_source`,`metadata_incomplete`,`mapping_low_confidence`,`quarantined`,`dead_letter`)
- `transition_reason` text not null
- `transition_actor` text not null check in (`intake`,`quality_job`,`manual_review`,`replay_job`)
- `changed_at` timestamptz not null default `now()`

Indexes:
- btree (`raw_item_id`,`changed_at` desc)
- btree (`to_state`,`changed_at` desc)

#### `raw_duplicate_links`
Purpose: link duplicate rows to canonical raw rows for replay and audit.

Columns:
- `duplicate_raw_item_id` UUID not null primary key FK -> `raw_items.id`
- `canonical_raw_item_id` UUID not null FK -> `raw_items.id`
- `duplicate_reason` text not null
- `detected_at` timestamptz not null default `now()`

Indexes:
- btree (`canonical_raw_item_id`)

#### `raw_quarantine_records`
Purpose: quarantine storage for rows blocked from normal processing.

Columns:
- `id` UUID PK
- `raw_item_id` UUID not null unique FK -> `raw_items.id`
- `quarantine_reason` text not null
- `quarantine_detail` text null
- `quarantined_at` timestamptz not null default `now()`
- `released_at` timestamptz null
- `release_decision` text null check in (`released`,`kept_quarantined`,`moved_dead_letter`)

Indexes:
- btree (`quarantined_at` desc)
- btree (`release_decision`,`released_at` desc)

#### `raw_dead_letter_records`
Purpose: non-retryable failure records with replay guidance.

Columns:
- `id` UUID PK
- `raw_item_id` UUID null FK -> `raw_items.id`
- `collector_spool_item_id` UUID null FK -> `collector_spool_items.id`
- `dead_letter_reason` text not null
- `failure_class` text not null check in (`schema_invalid`,`security_rejected`,`source_contract_violation`,`other_non_retryable`)
- `captured_payload_hash` text not null
- `captured_at` timestamptz not null default `now()`
- `replay_blocked` boolean not null default `true`
- `replay_notes` text null

Indexes:
- btree (`captured_at` desc)
- btree (`failure_class`,`captured_at` desc)

### Metadata Completeness Requirements (Frozen)
- required columns for accepted ingestion:
  - `source_id` (resolved through `ingest_sources`)
  - `source_category`
  - `collector_node_id`
  - `retry_count`
  - `collected_at`
  - `publisher_name`
  - `publisher_domain`
  - `canonical_url`
  - `payload_hash`
  - `payload_version`
  - `language`
  - `market_scope`
  - `title`
  - `raw_payload_json`
- when `upstream_event_at` is required by source contract and missing:
  - row can persist as `accepted_degraded` or `metadata_incomplete` but must not be silently promoted to `accepted`.

### Storage Rules For Weak, Duplicate, Stale, Quarantined, Dead-Letter
1. weak metadata but structurally valid:
- persist in `raw_items`.
- mark `raw_item_quality_states.quality_state` as `accepted_degraded` or `metadata_incomplete`.
2. duplicate payload:
- do not discard.
- persist one canonical row and store duplicate relationship in `raw_duplicate_links`.
3. stale source payload:
- persist row with `stale_source` quality state and reason code.
4. quarantined payload:
- persist row and quarantine record.
- exclude from normalization until release decision.
5. dead-letter payload:
- persist dead-letter record even when raw row creation fails.
- include captured hash and replay notes for auditability.

### Replay Lineage Guarantees
- every accepted raw row must trace back to exactly one spool item via `raw_item_spool_links`.
- every quality decision must be queryable from current-state and history tables.
- dead-letter and quarantine records must preserve enough metadata to explain why replay is blocked or required.

### Retention Baseline
- `collector_spool_runs`, `collector_spool_items`: 90 days.
- `intake_requests`: 180 days.
- `raw_items`: 180 days hot + archived export with hash verification.
- `raw_item_quality_history`: 365 days.
- `raw_quarantine_records`, `raw_dead_letter_records`: minimum 365 days.

### Privilege Boundaries (Least Privilege)
- baseline roles remain:
  - `signaldesk_migrator`
  - `signaldesk_app`
  - `signaldesk_readonly`
- add job-scoped runtime roles (NOLOGIN, granted to app runtime principals as needed):
  - `signaldesk_intake_job`
  - `signaldesk_quality_job`
  - `signaldesk_replay_job`
  - `signaldesk_normalize_job`
- grant intent:
  - `signaldesk_intake_job`: insert into intake/raw/spool-link tables; read source registry and spool lineage
  - `signaldesk_quality_job`: read raw tables; write quality, duplicate, quarantine, dead-letter tables
  - `signaldesk_replay_job`: read raw + quality tables and transition history; no source-registry mutation
  - `signaldesk_normalize_job`: select from raw tables only for rows with allowed quality states
  - `signaldesk_api`: no write access to raw-ingest families
