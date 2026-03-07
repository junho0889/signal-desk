# Database Schema

## Scope
This schema defines the BE-001 baseline for ranking, detail, watchlist, and alerts contracts.

## Conventions
- id columns: UUID (`gen_random_uuid()`), unless noted
- timestamps: `timestamptz` in UTC
- score-like values: `numeric(6,3)` unless tighter bound is needed
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
- `snapshot_at` timestamptz not null
- `period` text not null check in (`intraday`,`daily`,`weekly`)
- `score` numeric(6,3) not null
- `confidence` numeric(6,3) not null
- `mention_velocity` numeric(6,3) null
- `trend_velocity` numeric(6,3) null
- `market_reaction` numeric(6,3) null
- `event_weight` numeric(6,3) null
- `persistence` numeric(6,3) null
- `delta_1d` numeric(6,3) null
- `reason_tags` jsonb not null default `'[]'::jsonb`
- `risk_flags` jsonb not null default `'[]'::jsonb`

Constraints:
- unique (`keyword_id`,`period`,`snapshot_at`)

Indexes:
- btree (`period`,`snapshot_at` desc)
- btree (`score` desc)
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
- `relevance_score` numeric(6,3) null

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
- `link_confidence` numeric(6,3) null

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
- `link_confidence` numeric(6,3) null

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
- Keyword ranking: latest `keyword_snapshots` by `period`
- Keyword detail: `keyword_snapshots` + link tables + `news_items` + `stocks`
- Watchlist: `watchlist_items` + latest snapshots + `watchlist_alert_rules`
- Alerts: `alerts` ordered by `triggered_at`

## Open Implementation Notes
- Introduce taxonomy tables later for `reason_tags` and `risk_flags` when DATA quality stabilizes.
- Multi-user ownership for watchlist is intentionally out of scope for current personal-use MVP.
