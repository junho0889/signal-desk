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

## BE-004 Layered Storage Expansion (Additive Contract)

### Compatibility Boundary
- existing BE-001 app-facing tables remain valid and continue to back API contracts
- BE-004 adds layered storage families for replayability, trust/versioning, and model lineage
- additive lineage columns on serving tables are internal and do not change API payload shape

### Raw Ingestion Layer

#### `ingestion_sources`
Purpose: registry of ingestion channels and source-level defaults.

Columns:
- `id` UUID PK
- `source_id` text not null unique (aligned to `docs/data/source-catalog.md`)
- `category` text not null check in (`news`,`search_trends`,`market_ohlcv`,`dart_disclosures`,`other`)
- `is_active` boolean not null default `true`
- `default_freshness_minutes` integer not null
- `created_at` timestamptz not null default `now()`

Indexes:
- unique (`source_id`)
- btree (`category`,`is_active`)

#### `collector_nodes`
Purpose: collector identity and heartbeat lineage from edge intake.

Columns:
- `id` UUID PK
- `node_name` text not null unique
- `host_fingerprint` text not null
- `last_heartbeat_at` timestamptz null
- `created_at` timestamptz not null default `now()`

Indexes:
- unique (`node_name`)
- btree (`last_heartbeat_at` desc)

#### `ingestion_runs`
Purpose: one source polling/webhook cycle with transport outcomes.

Columns:
- `id` UUID PK
- `ingestion_source_id` UUID not null FK -> `ingestion_sources.id`
- `collector_node_id` UUID null FK -> `collector_nodes.id`
- `run_started_at` timestamptz not null
- `run_completed_at` timestamptz null
- `status` text not null check in (`running`,`succeeded`,`partial`,`failed`)
- `attempt_count` integer not null default `1`
- `source_window_start` timestamptz null
- `source_window_end` timestamptz null
- `code_version` text not null
- `error_summary` text null

Indexes:
- btree (`ingestion_source_id`,`run_started_at` desc)
- btree (`status`,`run_started_at` desc)

#### `raw_payload_batches`
Purpose: transport envelope acknowledged from collector spool or direct intake.

Columns:
- `id` UUID PK
- `ingestion_run_id` UUID not null FK -> `ingestion_runs.id`
- `collector_ack_token` text null
- `payload_hash` text not null
- `item_count` integer not null
- `received_at` timestamptz not null default `now()`
- `storage_uri` text null
- `transport_status` text not null check in (`received`,`acknowledged`,`rejected`)

Constraints:
- unique (`ingestion_run_id`,`payload_hash`)

Indexes:
- btree (`received_at` desc)
- btree (`transport_status`,`received_at` desc)

#### `raw_source_items`
Purpose: immutable per-item raw payload record used for replay and audit.

Columns:
- `id` UUID PK
- `raw_payload_batch_id` UUID not null FK -> `raw_payload_batches.id`
- `ingestion_source_id` UUID not null FK -> `ingestion_sources.id`
- `external_id` text null
- `idempotency_key` text not null
- `source_event_ts` timestamptz null
- `collected_at` timestamptz not null
- `source_timezone` text null
- `payload_hash` text not null
- `payload_json` jsonb not null
- `retry_count` integer not null default `0`
- `created_at` timestamptz not null default `now()`

Constraints:
- unique (`ingestion_source_id`,`idempotency_key`)

Indexes:
- btree (`ingestion_source_id`,`collected_at` desc)
- btree (`source_event_ts` desc)
- gin (`payload_json`)

### Normalized Layer

#### `normalization_runs`
Purpose: normalization execution metadata and input bounds.

Columns:
- `id` UUID PK
- `trigger_type` text not null check in (`schedule`,`manual`,`backfill`,`replay`)
- `run_started_at` timestamptz not null
- `run_completed_at` timestamptz null
- `status` text not null check in (`running`,`succeeded`,`partial`,`failed`)
- `input_collected_from` timestamptz not null
- `input_collected_to` timestamptz not null
- `code_version` text not null
- `config_version` text not null

Indexes:
- btree (`run_started_at` desc)
- btree (`status`,`run_started_at` desc)

#### `entity_aliases`
Purpose: alias -> canonical entity mapping with confidence and provenance.

Columns:
- `id` UUID PK
- `entity_type` text not null check in (`keyword`,`stock`,`sector`,`issuer`)
- `alias_text` text not null
- `canonical_id` UUID not null
- `normalization_run_id` UUID not null FK -> `normalization_runs.id`
- `mapping_confidence` numeric(4,3) not null
- `is_active` boolean not null default `true`
- `created_at` timestamptz not null default `now()`

Constraints:
- unique (`entity_type`,`alias_text`,`canonical_id`)

Indexes:
- btree (`entity_type`,`alias_text`)
- btree (`canonical_id`)

#### `dedup_clusters`
Purpose: cluster near-identical source items to one canonical event candidate.

Columns:
- `id` UUID PK
- `normalization_run_id` UUID not null FK -> `normalization_runs.id`
- `cluster_hash` text not null
- `primary_raw_item_id` UUID not null FK -> `raw_source_items.id`
- `duplicate_count` integer not null default `0`
- `window_start` timestamptz not null
- `window_end` timestamptz not null
- `created_at` timestamptz not null default `now()`

Constraints:
- unique (`normalization_run_id`,`cluster_hash`)

Indexes:
- btree (`window_end` desc)
- btree (`primary_raw_item_id`)

#### `normalized_events`
Purpose: canonical event record consumed by trust/model jobs.

Columns:
- `id` UUID PK
- `normalization_run_id` UUID not null FK -> `normalization_runs.id`
- `event_type` text not null check in (`news`,`trend`,`disclosure`,`market`)
- `event_ts` timestamptz not null
- `canonical_event_hash` text not null
- `summary_text` text not null
- `source_name` text null
- `quality_flags` text[] not null default `'{}'::text[]
- `primary_keyword_id` UUID null FK -> `keywords.id`
- `primary_stock_id` UUID null FK -> `stocks.id`
- `created_at` timestamptz not null default `now()`

Constraints:
- unique (`event_type`,`canonical_event_hash`)

Indexes:
- btree (`event_ts` desc)
- btree (`primary_keyword_id`,`event_ts` desc)
- gin (`quality_flags`)

#### `normalized_event_raw_links`
Purpose: many-to-many lineage from normalized event back to raw source records.

Columns:
- `normalized_event_id` UUID not null FK -> `normalized_events.id`
- `raw_item_id` UUID not null FK -> `raw_source_items.id`
- `dedup_cluster_id` UUID null FK -> `dedup_clusters.id`
- `is_primary` boolean not null default `false`

Constraints:
- primary key (`normalized_event_id`,`raw_item_id`)

Indexes:
- btree (`raw_item_id`)
- btree (`dedup_cluster_id`)

#### `entity_resolution_links`
Purpose: run-scoped link outputs from canonical entities to keywords/stocks/sectors.

Columns:
- `id` UUID PK
- `normalization_run_id` UUID not null FK -> `normalization_runs.id`
- `keyword_id` UUID not null FK -> `keywords.id`
- `stock_id` UUID null FK -> `stocks.id`
- `sector` text null
- `link_confidence` numeric(4,3) not null
- `is_primary` boolean not null default `false`
- `created_at` timestamptz not null default `now()`

Indexes:
- btree (`keyword_id`,`created_at` desc)
- btree (`stock_id`,`created_at` desc)
- btree (`sector`,`created_at` desc)

#### `contradiction_links`
Purpose: contradiction edges between normalized events for trust processing.

Columns:
- `id` UUID PK
- `normalization_run_id` UUID not null FK -> `normalization_runs.id`
- `left_event_id` UUID not null FK -> `normalized_events.id`
- `right_event_id` UUID not null FK -> `normalized_events.id`
- `relation_type` text not null check in (`contradiction`,`temporal_conflict`,`value_conflict`)
- `confidence` numeric(4,3) not null
- `created_at` timestamptz not null default `now()`

Constraints:
- unique (`left_event_id`,`right_event_id`,`relation_type`)

Indexes:
- btree (`left_event_id`)
- btree (`right_event_id`)

### Trust Layer

#### `trust_runs`
Purpose: trust scoring execution boundary.

Columns:
- `id` UUID PK
- `run_started_at` timestamptz not null
- `run_completed_at` timestamptz null
- `status` text not null check in (`running`,`succeeded`,`partial`,`failed`)
- `normalization_run_id` UUID not null FK -> `normalization_runs.id`
- `policy_version` text not null
- `code_version` text not null

Indexes:
- btree (`run_started_at` desc)
- btree (`normalization_run_id`)

#### `source_reliability_snapshots`
Purpose: source-level credibility trend by trust run.

Columns:
- `id` UUID PK
- `trust_run_id` UUID not null FK -> `trust_runs.id`
- `ingestion_source_id` UUID not null FK -> `ingestion_sources.id`
- `reliability_score` numeric(5,2) not null
- `staleness_score` numeric(5,2) not null
- `coverage_score` numeric(5,2) not null
- `notes` text null
- `created_at` timestamptz not null default `now()`

Constraints:
- unique (`trust_run_id`,`ingestion_source_id`)

Indexes:
- btree (`ingestion_source_id`,`created_at` desc)

#### `event_trust_assessments`
Purpose: trust outputs for each normalized event.

Columns:
- `id` UUID PK
- `trust_run_id` UUID not null FK -> `trust_runs.id`
- `normalized_event_id` UUID not null FK -> `normalized_events.id`
- `credibility_score` numeric(5,2) not null
- `misinformation_risk_score` numeric(5,2) not null
- `contradiction_score` numeric(5,2) not null
- `confidence` numeric(4,3) not null
- `trust_flags` text[] not null default `'{}'::text[]
- `created_at` timestamptz not null default `now()`

Constraints:
- unique (`trust_run_id`,`normalized_event_id`)

Indexes:
- btree (`normalized_event_id`)
- btree (`trust_run_id`,`credibility_score` desc)
- gin (`trust_flags`)

#### `keyword_trust_snapshots`
Purpose: keyword-level trust aggregate used by publishing and alerts gating.

Columns:
- `id` UUID PK
- `trust_run_id` UUID not null FK -> `trust_runs.id`
- `keyword_id` UUID not null FK -> `keywords.id`
- `as_of_ts` timestamptz not null
- `trust_score` numeric(5,2) not null
- `low_confidence_ratio` numeric(5,2) not null
- `contradiction_count` integer not null default `0`
- `risk_flags` text[] not null default `'{}'::text[]

Constraints:
- unique (`trust_run_id`,`keyword_id`)

Indexes:
- btree (`keyword_id`,`as_of_ts` desc)
- gin (`risk_flags`)

### Model Layer

#### `feature_runs`
Purpose: feature materialization boundary from normalized + trust inputs.

Columns:
- `id` UUID PK
- `normalization_run_id` UUID not null FK -> `normalization_runs.id`
- `trust_run_id` UUID not null FK -> `trust_runs.id`
- `run_started_at` timestamptz not null
- `run_completed_at` timestamptz null
- `status` text not null check in (`running`,`succeeded`,`partial`,`failed`)
- `feature_spec_version` text not null
- `code_version` text not null

Indexes:
- btree (`run_started_at` desc)
- btree (`normalization_run_id`,`trust_run_id`)

#### `keyword_feature_snapshots`
Purpose: keyword feature vectors for a specific feature run.

Columns:
- `id` UUID PK
- `feature_run_id` UUID not null FK -> `feature_runs.id`
- `keyword_id` UUID not null FK -> `keywords.id`
- `as_of_ts` timestamptz not null
- `mention_count_24h` numeric(8,2) not null
- `mention_delta_24h` numeric(8,2) not null
- `trend_index` numeric(8,2) null
- `trend_delta` numeric(8,2) null
- `market_reaction_raw` numeric(8,2) null
- `event_count_7d` numeric(8,2) null
- `source_coverage_ratio` numeric(5,2) not null
- `freshness_minutes` integer not null
- `feature_payload` jsonb not null default `'{}'::jsonb

Constraints:
- unique (`feature_run_id`,`keyword_id`)

Indexes:
- btree (`keyword_id`,`as_of_ts` desc)
- gin (`feature_payload`)

#### `model_registry`
Purpose: model identity, objective, and artifact references.

Columns:
- `id` UUID PK
- `model_key` text not null unique
- `model_type` text not null check in (`rule_v0`,`linear`,`tree`,`hybrid`)
- `objective` text not null
- `version` text not null
- `artifact_uri` text null
- `created_at` timestamptz not null default `now()`

Constraints:
- unique (`model_key`,`version`)

Indexes:
- btree (`model_type`,`created_at` desc)

#### `model_runs`
Purpose: one ranking inference execution.

Columns:
- `id` UUID PK
- `model_registry_id` UUID not null FK -> `model_registry.id`
- `feature_run_id` UUID not null FK -> `feature_runs.id`
- `run_started_at` timestamptz not null
- `run_completed_at` timestamptz null
- `status` text not null check in (`running`,`succeeded`,`partial`,`failed`)
- `inference_window_end` timestamptz not null
- `config_version` text not null
- `code_version` text not null

Indexes:
- btree (`model_registry_id`,`run_started_at` desc)
- btree (`feature_run_id`)

#### `model_keyword_scores`
Purpose: model output scores before publishing policy and rank assignment.

Columns:
- `id` UUID PK
- `model_run_id` UUID not null FK -> `model_runs.id`
- `keyword_id` UUID not null FK -> `keywords.id`
- `score_total` numeric(5,2) not null
- `score_delta_24h` numeric(5,2) null
- `confidence` numeric(4,3) not null
- `dimension_mentions` numeric(5,2) null
- `dimension_trends` numeric(5,2) null
- `dimension_market` numeric(5,2) null
- `dimension_events` numeric(5,2) null
- `dimension_persistence` numeric(5,2) null
- `created_at` timestamptz not null default `now()`

Constraints:
- unique (`model_run_id`,`keyword_id`)

Indexes:
- btree (`model_run_id`,`score_total` desc)
- btree (`keyword_id`,`created_at` desc)

#### `model_run_metrics`
Purpose: evaluation and guardrail metrics for each model run.

Columns:
- `id` UUID PK
- `model_run_id` UUID not null FK -> `model_runs.id`
- `metric_name` text not null
- `metric_value` numeric(10,4) not null
- `metric_payload` jsonb not null default `'{}'::jsonb
- `created_at` timestamptz not null default `now()`

Constraints:
- unique (`model_run_id`,`metric_name`)

Indexes:
- btree (`model_run_id`)

### Published Ranking Layer

#### `publish_runs`
Purpose: final publication boundary that materializes stable ranking artifacts.

Columns:
- `id` UUID PK
- `model_run_id` UUID not null FK -> `model_runs.id`
- `trust_run_id` UUID not null FK -> `trust_runs.id`
- `published_at` timestamptz not null
- `status` text not null check in (`running`,`succeeded`,`partial`,`failed`)
- `publish_policy_version` text not null
- `code_version` text not null

Indexes:
- btree (`published_at` desc)
- btree (`model_run_id`,`trust_run_id`)

#### `published_keyword_rankings`
Purpose: immutable published ranking rows from a publish run.

Columns:
- `id` UUID PK
- `publish_run_id` UUID not null FK -> `publish_runs.id`
- `model_keyword_score_id` UUID not null FK -> `model_keyword_scores.id`
- `keyword_id` UUID not null FK -> `keywords.id`
- `rank_position` integer not null
- `score_total` numeric(5,2) not null
- `score_delta_24h` numeric(5,2) null
- `confidence` numeric(4,3) not null
- `is_alert_eligible` boolean not null default `false`
- `reason_tags` text[] not null default `'{}'::text[]
- `risk_flags` text[] not null default `'{}'::text[]

Constraints:
- unique (`publish_run_id`,`keyword_id`)
- unique (`publish_run_id`,`rank_position`)

Indexes:
- btree (`publish_run_id`,`rank_position`)
- btree (`keyword_id`,`publish_run_id`)
- gin (`reason_tags`)
- gin (`risk_flags`)

#### `published_ranking_evidence`
Purpose: evidence links attached to published ranking rows.

Columns:
- `id` UUID PK
- `published_keyword_ranking_id` UUID not null FK -> `published_keyword_rankings.id`
- `normalized_event_id` UUID null FK -> `normalized_events.id`
- `event_trust_assessment_id` UUID null FK -> `event_trust_assessments.id`
- `evidence_type` text not null check in (`news`,`trend`,`disclosure`,`market`,`trust`)
- `weight` numeric(5,2) null
- `summary_text` text null

Indexes:
- btree (`published_keyword_ranking_id`)
- btree (`normalized_event_id`)
- btree (`event_trust_assessment_id`)

#### Serving Projection Notes (`keyword_snapshots`, link tables)
- add nullable lineage columns to `keyword_snapshots`:
  - `publish_run_id` UUID FK -> `publish_runs.id`
  - `published_ranking_id` UUID FK -> `published_keyword_rankings.id`
  - `model_run_id` UUID FK -> `model_runs.id`
  - `trust_run_id` UUID FK -> `trust_runs.id`
- optional next-step: add `publish_run_id` to `keyword_news_links`, `keyword_stock_links`, and `keyword_sector_links` for consistent evidence replay.

### Lineage Rules (Raw -> App-Facing)
1. every published row must trace to a single `publish_run_id`.
2. every publish run must reference one `model_run_id` and one `trust_run_id`.
3. every model run must reference one `feature_run_id`, which references one normalization/trust input pair.
4. every trust output row must reference one `trust_run_id` and one `normalized_event_id`.
5. every normalized event must map back to one or more `raw_source_items` through `normalized_event_raw_links`.
6. no layer may overwrite prior run results in place; new run id means new rows.

### Retention Rules (Baseline)
- raw payload json: 180 days in primary postgres, then archive with hash manifest.
- raw ingestion metadata and run logs: 400 days minimum.
- normalized events, entity mappings, contradiction edges: 730 days minimum.
- trust outputs and feature/model run outputs: 400 days minimum with run summaries retained for at least 2 years.
- published rankings and serving snapshots: 730 days minimum.

### Privilege Boundary Rules (Least Privilege)
- migration/DDL: `signaldesk_migrator` only.
- ingestion runtime writes: raw layer tables only.
- normalization runtime writes: normalized layer tables only (read raw).
- trust runtime writes: trust layer tables only (read normalized).
- model runtime writes: feature/model layer tables only (read normalized/trust).
- publish runtime writes: published layer + serving projection columns only (read trust/model).
- API runtime:
  - select on `keyword_snapshots`, evidence links, watchlist, alerts.
  - no write to raw/normalized/trust/model layer tables.
- diagnostics runtime (`signaldesk_readonly`): select-only across all layers; access to full `payload_json` can be restricted in mirrored environments.
