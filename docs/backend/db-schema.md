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

## BE-006 Storage Contract Freeze (Additive To BE-001)

### Compatibility Rule
- BE-001 app-facing APIs remain unchanged.
- new columns and tables are internal pipeline/storage contracts for BE-006 and downstream implementation.

### Raw Ingestion Anchors

#### `ingestion_sources`
Purpose: source registry aligned with collector intake contract source ids.

Columns:
- `id` UUID PK
- `source_id` text not null unique
- `category` text not null check in (`news`,`search_trends`,`market_ohlcv`,`dart_disclosures`,`other`)
- `is_active` boolean not null default `true`
- `created_at` timestamptz not null default `now()`

#### `ingestion_runs`
Purpose: one ingestion cycle per source.

Columns:
- `id` UUID PK
- `ingestion_source_id` UUID not null FK -> `ingestion_sources.id`
- `collector_node_id` text null
- `window_start` timestamptz null
- `window_end` timestamptz null
- `status` text not null check in (`running`,`succeeded`,`partial`,`failed`)
- `started_at` timestamptz not null
- `completed_at` timestamptz null
- `code_version` text not null

Indexes:
- btree (`ingestion_source_id`,`started_at` desc)
- btree (`status`,`started_at` desc)

#### `raw_source_items`
Purpose: immutable per-item raw payload records with idempotency lineage.

Columns:
- `id` UUID PK
- `ingestion_run_id` UUID not null FK -> `ingestion_runs.id`
- `ingestion_source_id` UUID not null FK -> `ingestion_sources.id`
- `external_id` text null
- `idempotency_key` text not null
- `payload_hash` text not null
- `payload_version` text not null
- `payload_json` jsonb not null
- `collected_at` timestamptz not null
- `upstream_event_at` timestamptz null
- `retry_count` integer not null default `0`
- `created_at` timestamptz not null default `now()`

Constraints:
- unique (`ingestion_source_id`,`idempotency_key`)

Indexes:
- btree (`ingestion_source_id`,`collected_at` desc)
- btree (`payload_hash`)
- gin (`payload_json`)

### Normalization Contracts

#### `normalization_runs`
Purpose: execution boundary for canonical event extraction.

Columns:
- `id` UUID PK
- `trigger_type` text not null check in (`schedule`,`manual`,`backfill`,`replay`)
- `input_collected_from` timestamptz not null
- `input_collected_to` timestamptz not null
- `status` text not null check in (`running`,`succeeded`,`partial`,`failed`)
- `started_at` timestamptz not null
- `completed_at` timestamptz null
- `code_version` text not null
- `config_version` text not null

#### `normalized_events`
Purpose: canonical event records consumed by trust and model jobs.

Columns:
- `id` UUID PK
- `normalization_run_id` UUID not null FK -> `normalization_runs.id`
- `event_type` text not null check in (`news`,`trend`,`disclosure`,`market`)
- `event_ts` timestamptz not null
- `canonical_event_hash` text not null
- `summary_text` text not null
- `source_name` text null
- `quality_flags` text[] not null default `'{}'::text[]
- `created_at` timestamptz not null default `now()`

Constraints:
- unique (`event_type`,`canonical_event_hash`)

Indexes:
- btree (`event_ts` desc)
- gin (`quality_flags`)

#### `normalized_event_raw_links`
Purpose: many-to-many lineage to raw payload records.

Columns:
- `normalized_event_id` UUID not null FK -> `normalized_events.id`
- `raw_item_id` UUID not null FK -> `raw_source_items.id`
- `is_primary` boolean not null default `false`

Constraints:
- primary key (`normalized_event_id`,`raw_item_id`)

#### `keyword_event_links`
Purpose: map normalized events to keyword entities for downstream aggregation.

Columns:
- `normalized_event_id` UUID not null FK -> `normalized_events.id`
- `keyword_id` UUID not null FK -> `keywords.id`
- `relevance_score` numeric(5,2) not null

Constraints:
- primary key (`normalized_event_id`,`keyword_id`)

Indexes:
- btree (`keyword_id`)

### Trust Output Contracts

#### `trust_runs`
Purpose: run boundary for trust dimension scoring.

Columns:
- `id` UUID PK
- `normalization_run_id` UUID not null FK -> `normalization_runs.id`
- `policy_version` text not null
- `status` text not null check in (`running`,`succeeded`,`partial`,`failed`)
- `started_at` timestamptz not null
- `completed_at` timestamptz null
- `code_version` text not null

Indexes:
- btree (`normalization_run_id`)
- btree (`started_at` desc)

#### `event_trust_scores`
Purpose: trust dimensions per normalized event.

Columns:
- `id` UUID PK
- `trust_run_id` UUID not null FK -> `trust_runs.id`
- `normalized_event_id` UUID not null FK -> `normalized_events.id`
- `trust_score` numeric(5,2) not null
- `coverage_score` numeric(5,2) not null
- `contradiction_score` numeric(5,2) not null
- `misinformation_risk_score` numeric(5,2) not null
- `confidence` numeric(4,3) not null
- `trust_flags` text[] not null default `'{}'::text[]
- `created_at` timestamptz not null default `now()`

Constraints:
- unique (`trust_run_id`,`normalized_event_id`)

Indexes:
- btree (`normalized_event_id`)
- gin (`trust_flags`)

#### `keyword_trust_snapshots`
Purpose: keyword-level trust aggregate used by ranking and publish gating.

Columns:
- `id` UUID PK
- `trust_run_id` UUID not null FK -> `trust_runs.id`
- `keyword_id` UUID not null FK -> `keywords.id`
- `as_of_ts` timestamptz not null
- `trust_score` numeric(5,2) not null
- `coverage_score` numeric(5,2) not null
- `contradiction_count` integer not null default `0`
- `risk_flags` text[] not null default `'{}'::text[]

Constraints:
- unique (`trust_run_id`,`keyword_id`)

Indexes:
- btree (`keyword_id`,`as_of_ts` desc)
- gin (`risk_flags`)

#### `trust_review_queue`
Purpose: review queue for low-confidence or misinformation-risk events.

Columns:
- `id` UUID PK
- `trust_run_id` UUID not null FK -> `trust_runs.id`
- `normalized_event_id` UUID not null FK -> `normalized_events.id`
- `review_reason` text not null
- `review_status` text not null check in (`pending`,`resolved`,`dismissed`)
- `created_at` timestamptz not null default `now()`
- `resolved_at` timestamptz null

Indexes:
- btree (`review_status`,`created_at` desc)

### Feature Snapshot Contracts

#### `feature_runs`
Purpose: deterministic feature materialization boundary.

Columns:
- `id` UUID PK
- `normalization_run_id` UUID not null FK -> `normalization_runs.id`
- `trust_run_id` UUID not null FK -> `trust_runs.id`
- `feature_spec_version` text not null
- `status` text not null check in (`running`,`succeeded`,`partial`,`failed`)
- `started_at` timestamptz not null
- `completed_at` timestamptz null
- `code_version` text not null

Constraints:
- unique (`normalization_run_id`,`trust_run_id`,`feature_spec_version`)

Indexes:
- btree (`started_at` desc)

#### `keyword_feature_snapshots`
Purpose: run-scoped feature vectors at keyword granularity.

Columns:
- `id` UUID PK
- `feature_run_id` UUID not null FK -> `feature_runs.id`
- `keyword_id` UUID not null FK -> `keywords.id`
- `as_of_ts` timestamptz not null
- `feature_vector` jsonb not null
- `freshness_minutes` integer not null
- `source_coverage_ratio` numeric(5,2) not null
- `created_at` timestamptz not null default `now()`

Constraints:
- unique (`feature_run_id`,`keyword_id`)

Indexes:
- btree (`keyword_id`,`as_of_ts` desc)
- gin (`feature_vector`)

#### `feature_group_contributions`
Purpose: explicit per-group contribution values used for explainability.

Columns:
- `id` UUID PK
- `keyword_feature_snapshot_id` UUID not null FK -> `keyword_feature_snapshots.id`
- `group_name` text not null check in (`freshness`,`attention`,`market`,`catalyst`,`persistence`,`trust`)
- `group_value` numeric(8,3) not null

Constraints:
- unique (`keyword_feature_snapshot_id`,`group_name`)

Indexes:
- btree (`group_name`)

### Model Run Contracts

#### `model_registry`
Purpose: model identity and artifact metadata.

Columns:
- `id` UUID PK
- `model_key` text not null
- `version` text not null
- `model_type` text not null check in (`rule_v0`,`calibrated_linear`,`tree`,`hybrid`)
- `artifact_uri` text null
- `created_at` timestamptz not null default `now()`

Constraints:
- unique (`model_key`,`version`)

#### `model_runs`
Purpose: one ranking run over a feature snapshot run.

Columns:
- `id` UUID PK
- `model_registry_id` UUID not null FK -> `model_registry.id`
- `feature_run_id` UUID not null FK -> `feature_runs.id`
- `run_window_end` timestamptz not null
- `status` text not null check in (`running`,`succeeded`,`partial`,`failed`)
- `started_at` timestamptz not null
- `completed_at` timestamptz null
- `config_version` text not null
- `code_version` text not null

Constraints:
- unique (`model_registry_id`,`feature_run_id`,`run_window_end`)

Indexes:
- btree (`started_at` desc)
- btree (`feature_run_id`)

#### `model_keyword_scores`
Purpose: pre-publish model score artifact per keyword.

Columns:
- `id` UUID PK
- `model_run_id` UUID not null FK -> `model_runs.id`
- `keyword_id` UUID not null FK -> `keywords.id`
- `importance_score` numeric(5,2) not null
- `confidence_score` numeric(4,3) not null
- `score_delta_24h` numeric(5,2) null
- `warning_candidates` text[] not null default `'{}'::text[]
- `explanation_artifact` jsonb not null default `'{}'::jsonb
- `created_at` timestamptz not null default `now()`

Constraints:
- unique (`model_run_id`,`keyword_id`)

Indexes:
- btree (`model_run_id`,`importance_score` desc)
- gin (`warning_candidates`)
- gin (`explanation_artifact`)

### Label Contracts

#### `label_sets`
Purpose: immutable label policy definition.

Columns:
- `id` UUID PK
- `label_set_key` text not null unique
- `horizon_hours` integer not null
- `definition_version` text not null
- `created_at` timestamptz not null default `now()`

#### `keyword_labels`
Purpose: observed label outcomes used for evaluation/training.

Columns:
- `id` UUID PK
- `label_set_id` UUID not null FK -> `label_sets.id`
- `keyword_id` UUID not null FK -> `keywords.id`
- `label_window_start` timestamptz not null
- `label_window_end` timestamptz not null
- `label_value` numeric(8,4) not null
- `label_class` text not null check in (`negative`,`neutral`,`positive`,`high_impact`)
- `label_confidence` numeric(4,3) not null
- `provenance_event_count` integer not null default `0`
- `label_observed_at` timestamptz not null

Constraints:
- unique (`label_set_id`,`keyword_id`,`label_window_end`)

Indexes:
- btree (`keyword_id`,`label_window_end` desc)
- btree (`label_class`,`label_window_end` desc)

### Evaluation Snapshot Contracts

#### `evaluation_runs`
Purpose: evaluate one model run against one label set.

Columns:
- `id` UUID PK
- `model_run_id` UUID not null FK -> `model_runs.id`
- `label_set_id` UUID not null FK -> `label_sets.id`
- `evaluation_window_start` timestamptz not null
- `evaluation_window_end` timestamptz not null
- `status` text not null check in (`running`,`succeeded`,`failed`)
- `started_at` timestamptz not null
- `completed_at` timestamptz null
- `code_version` text not null

Constraints:
- unique (`model_run_id`,`label_set_id`,`evaluation_window_end`)

Indexes:
- btree (`started_at` desc)

#### `evaluation_metric_snapshots`
Purpose: aggregate evaluation metrics for a run.

Columns:
- `id` UUID PK
- `evaluation_run_id` UUID not null FK -> `evaluation_runs.id`
- `metric_name` text not null
- `metric_value` numeric(10,4) not null
- `metric_payload` jsonb not null default `'{}'::jsonb

Constraints:
- unique (`evaluation_run_id`,`metric_name`)

Indexes:
- btree (`evaluation_run_id`)

#### `evaluation_keyword_outcomes`
Purpose: per-keyword diagnostic rows for regression and replay analysis.

Columns:
- `id` UUID PK
- `evaluation_run_id` UUID not null FK -> `evaluation_runs.id`
- `keyword_id` UUID not null FK -> `keywords.id`
- `predicted_score` numeric(8,4) not null
- `actual_label` numeric(8,4) not null
- `residual` numeric(8,4) not null
- `diagnostic_flags` text[] not null default `'{}'::text[]

Constraints:
- unique (`evaluation_run_id`,`keyword_id`)

Indexes:
- btree (`evaluation_run_id`)
- gin (`diagnostic_flags`)

### Published Ranking Lineage Contracts

#### `publish_runs`
Purpose: immutable publish boundary from model + trust artifacts.

Columns:
- `id` UUID PK
- `model_run_id` UUID not null FK -> `model_runs.id`
- `trust_run_id` UUID not null FK -> `trust_runs.id`
- `publish_policy_version` text not null
- `status` text not null check in (`running`,`succeeded`,`partial`,`failed`)
- `published_at` timestamptz not null
- `code_version` text not null

Constraints:
- unique (`model_run_id`,`trust_run_id`,`published_at`)

Indexes:
- btree (`published_at` desc)

#### `publish_manifests`
Purpose: run-level manifest artifact for reproducibility and rollback.

Columns:
- `id` UUID PK
- `publish_run_id` UUID not null unique FK -> `publish_runs.id`
- `manifest_hash` text not null
- `manifest_json` jsonb not null
- `created_at` timestamptz not null default `now()`

Indexes:
- btree (`manifest_hash`)

#### `published_keyword_rankings`
Purpose: immutable app-serving ranking artifact rows.

Columns:
- `id` UUID PK
- `publish_run_id` UUID not null FK -> `publish_runs.id`
- `model_keyword_score_id` UUID not null FK -> `model_keyword_scores.id`
- `keyword_id` UUID not null FK -> `keywords.id`
- `rank_position` integer not null
- `importance_score` numeric(5,2) not null
- `confidence_score` numeric(4,3) not null
- `is_alert_eligible` boolean not null default `false`
- `reason_tags` text[] not null default `'{}'::text[]
- `risk_flags` text[] not null default `'{}'::text[]

Constraints:
- unique (`publish_run_id`,`keyword_id`)
- unique (`publish_run_id`,`rank_position`)

Indexes:
- btree (`publish_run_id`,`rank_position`)
- gin (`reason_tags`)
- gin (`risk_flags`)

#### `published_ranking_evidence`
Purpose: explainability lineage rows tied to normalized/trust artifacts.

Columns:
- `id` UUID PK
- `published_keyword_ranking_id` UUID not null FK -> `published_keyword_rankings.id`
- `normalized_event_id` UUID null FK -> `normalized_events.id`
- `event_trust_score_id` UUID null FK -> `event_trust_scores.id`
- `evidence_type` text not null check in (`news`,`trend`,`disclosure`,`market`,`trust`)
- `weight` numeric(5,2) null
- `summary_text` text null

Indexes:
- btree (`published_keyword_ranking_id`)
- btree (`normalized_event_id`)
- btree (`event_trust_score_id`)

### Serving Projection Lineage (`keyword_snapshots`)
- add nullable internal columns:
  - `publish_run_id` UUID FK -> `publish_runs.id`
  - `published_ranking_id` UUID FK -> `published_keyword_rankings.id`
  - `model_run_id` UUID FK -> `model_runs.id`
  - `trust_run_id` UUID FK -> `trust_runs.id`
- API response shape remains unchanged.

### Replay Lineage Rules (Frozen)
1. a published ranking row must map to one `publish_run_id`.
2. each publish run must map to one `model_run_id` and one `trust_run_id`.
3. each model run must map to one `feature_run_id`.
4. each feature run must map to one normalization run and one trust run.
5. each trust score row must map to one normalized event.
6. each normalized event must map to one or more raw source items.
7. labels and evaluation snapshots are immutable rows keyed by run/set/window uniqueness.

### Retention Rules (Frozen Baseline)
- raw payload body and hash lineage: 180 days hot, then archive.
- normalization, trust, feature, model, publish artifacts: 730 days minimum.
- labels and evaluation snapshots: 1095 days minimum.
- publish manifests: retain for the full life of corresponding publish runs.

### Privilege Boundaries (Executable Grant Plan)
- maintain baseline roles from `postgres-security.md`.
- add dedicated runtime roles (NOLOGIN) for executable least-privilege grants:
  - `signaldesk_ingest_job`
  - `signaldesk_normalize_job`
  - `signaldesk_trust_job`
  - `signaldesk_model_job`
  - `signaldesk_publish_job`
  - `signaldesk_api`
- grant matrix:
  - `signaldesk_ingest_job`: `SELECT/INSERT` on `ingestion_*`, `raw_source_items`
  - `signaldesk_normalize_job`: `SELECT` raw tables; `SELECT/INSERT/UPDATE` normalization tables
  - `signaldesk_trust_job`: `SELECT` normalization; `SELECT/INSERT/UPDATE` trust tables
  - `signaldesk_model_job`: `SELECT` normalization+trust+labels; `SELECT/INSERT/UPDATE` feature/model/evaluation tables
  - `signaldesk_publish_job`: `SELECT` trust+model; `SELECT/INSERT/UPDATE` publish tables + lineage columns on `keyword_snapshots`
  - `signaldesk_api`: `SELECT` only on serving and published evidence tables
- `signaldesk_readonly` remains global select-only diagnostics role.
