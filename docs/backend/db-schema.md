# Database Schema

## Core Tables

### `keywords`
- id
- canonical_name
- market_scope
- sector_hint
- created_at

### `keyword_snapshots`
- id
- keyword_id
- snapshot_at
- score
- confidence
- mention_velocity
- trend_velocity
- market_reaction
- event_weight
- persistence
- reason_tags
- risk_flags

### `news_items`
- id
- source_name
- published_at
- title
- url
- normalized_hash

### `keyword_news_links`
- keyword_id
- news_item_id
- relevance_score

### `stocks`
- id
- ticker
- name
- market
- sector

### `keyword_stock_links`
- keyword_id
- stock_id
- link_confidence

### `watchlist_items`
- id
- target_type
- target_id
- created_at

### `alerts`
- id
- target_type
- target_id
- triggered_at
- severity
- message

## Role Expectations
- schema migrations run with `signaldesk_migrator`
- application queries run with `signaldesk_app`
- read-only diagnostics run with `signaldesk_readonly`
- bootstrap and emergency admin use the PostgreSQL superuser only outside normal app flow

## Notes
- Store derived snapshots so the app can query quickly.
- Treat `keyword_snapshots` as the main read model for ranking views.
- Do not let application code own the database or schema.
