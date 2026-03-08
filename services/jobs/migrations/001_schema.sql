CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS keywords (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  canonical_name text NOT NULL UNIQUE,
  market_scope text NOT NULL CHECK (market_scope IN ('kr', 'us', 'all')),
  sector_hint text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS keyword_snapshots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  keyword_id uuid NOT NULL REFERENCES keywords(id) ON DELETE CASCADE,
  as_of_ts timestamptz NOT NULL,
  score_total numeric(5,2) NOT NULL,
  score_delta_24h numeric(5,2),
  confidence numeric(4,3) NOT NULL,
  rank_position integer NOT NULL,
  dimension_mentions numeric(5,2),
  dimension_trends numeric(5,2),
  dimension_market numeric(5,2),
  dimension_events numeric(5,2),
  dimension_persistence numeric(5,2),
  is_alert_eligible boolean NOT NULL DEFAULT false,
  reason_tags text[] NOT NULL DEFAULT '{}'::text[],
  risk_flags text[] NOT NULL DEFAULT '{}'::text[],
  CONSTRAINT uq_keyword_snapshot UNIQUE (keyword_id, as_of_ts),
  CONSTRAINT chk_confidence_range CHECK (confidence >= 0.000 AND confidence <= 1.000),
  CONSTRAINT chk_reason_tags_values CHECK (
    reason_tags <@ ARRAY[
      'mentions_accelerating',
      'search_confirmation',
      'price_volume_confirmation',
      'disclosure_backed',
      'persistent_multi_window',
      'low_source_diversity',
      'stale_input_risk',
      'weak_market_confirmation'
    ]::text[]
  ),
  CONSTRAINT chk_risk_flags_values CHECK (
    risk_flags <@ ARRAY[
      'data_freshness_degraded',
      'event_coverage_partial',
      'mapping_unstable',
      'thin_cohort'
    ]::text[]
  )
);

CREATE TABLE IF NOT EXISTS news_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  source_name text NOT NULL,
  published_at timestamptz NOT NULL,
  title text NOT NULL,
  url text NOT NULL,
  normalized_hash text NOT NULL UNIQUE,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS keyword_news_links (
  keyword_id uuid NOT NULL REFERENCES keywords(id) ON DELETE CASCADE,
  news_item_id uuid NOT NULL REFERENCES news_items(id) ON DELETE CASCADE,
  snapshot_id uuid REFERENCES keyword_snapshots(id) ON DELETE SET NULL,
  relevance_score numeric(5,2),
  PRIMARY KEY (keyword_id, news_item_id)
);

CREATE TABLE IF NOT EXISTS stocks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ticker text NOT NULL,
  name text NOT NULL,
  market text NOT NULL CHECK (market IN ('kr', 'us')),
  sector text,
  CONSTRAINT uq_market_ticker UNIQUE (market, ticker)
);

CREATE TABLE IF NOT EXISTS keyword_stock_links (
  keyword_id uuid NOT NULL REFERENCES keywords(id) ON DELETE CASCADE,
  stock_id uuid NOT NULL REFERENCES stocks(id) ON DELETE CASCADE,
  snapshot_id uuid REFERENCES keyword_snapshots(id) ON DELETE SET NULL,
  link_confidence numeric(4,3),
  PRIMARY KEY (keyword_id, stock_id)
);

CREATE TABLE IF NOT EXISTS keyword_sector_links (
  keyword_id uuid NOT NULL REFERENCES keywords(id) ON DELETE CASCADE,
  sector text NOT NULL,
  snapshot_id uuid REFERENCES keyword_snapshots(id) ON DELETE SET NULL,
  link_confidence numeric(4,3),
  PRIMARY KEY (keyword_id, sector)
);

CREATE TABLE IF NOT EXISTS watchlist_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  target_type text NOT NULL CHECK (target_type IN ('keyword', 'stock')),
  target_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_watchlist_target UNIQUE (target_type, target_id)
);

CREATE TABLE IF NOT EXISTS watchlist_alert_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  watchlist_item_id uuid NOT NULL UNIQUE REFERENCES watchlist_items(id) ON DELETE CASCADE,
  is_enabled boolean NOT NULL DEFAULT true,
  min_severity text NOT NULL DEFAULT 'medium' CHECK (min_severity IN ('low', 'medium', 'high', 'critical')),
  cooldown_minutes integer NOT NULL DEFAULT 60,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS alerts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  target_type text NOT NULL CHECK (target_type IN ('keyword', 'stock')),
  target_id uuid NOT NULL,
  keyword_id uuid REFERENCES keywords(id) ON DELETE SET NULL,
  watchlist_item_id uuid REFERENCES watchlist_items(id) ON DELETE SET NULL,
  triggered_at timestamptz NOT NULL,
  severity text NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  message text NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_keywords_market_scope ON keywords (market_scope);

CREATE INDEX IF NOT EXISTS idx_keyword_snapshots_as_of_ts_desc ON keyword_snapshots (as_of_ts DESC);
CREATE INDEX IF NOT EXISTS idx_keyword_snapshots_score_desc ON keyword_snapshots (score_total DESC);
CREATE INDEX IF NOT EXISTS idx_keyword_snapshots_alert_eligible ON keyword_snapshots (is_alert_eligible, as_of_ts DESC);
CREATE INDEX IF NOT EXISTS idx_keyword_snapshots_reason_tags_gin ON keyword_snapshots USING gin (reason_tags);
CREATE INDEX IF NOT EXISTS idx_keyword_snapshots_risk_flags_gin ON keyword_snapshots USING gin (risk_flags);

CREATE INDEX IF NOT EXISTS idx_news_items_published_at_desc ON news_items (published_at DESC);
CREATE INDEX IF NOT EXISTS idx_keyword_news_links_news_item_id ON keyword_news_links (news_item_id);
CREATE INDEX IF NOT EXISTS idx_keyword_news_links_snapshot_id ON keyword_news_links (snapshot_id);

CREATE INDEX IF NOT EXISTS idx_stocks_sector ON stocks (sector);
CREATE INDEX IF NOT EXISTS idx_keyword_stock_links_stock_id ON keyword_stock_links (stock_id);
CREATE INDEX IF NOT EXISTS idx_keyword_stock_links_snapshot_id ON keyword_stock_links (snapshot_id);

CREATE INDEX IF NOT EXISTS idx_keyword_sector_links_sector ON keyword_sector_links (sector);
CREATE INDEX IF NOT EXISTS idx_keyword_sector_links_snapshot_id ON keyword_sector_links (snapshot_id);

CREATE INDEX IF NOT EXISTS idx_watchlist_items_created_at_desc ON watchlist_items (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_watchlist_alert_rules_enabled_severity ON watchlist_alert_rules (is_enabled, min_severity);

CREATE INDEX IF NOT EXISTS idx_alerts_triggered_at_desc ON alerts (triggered_at DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_severity_triggered_at_desc ON alerts (severity, triggered_at DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_target_type_target_id_triggered_at_desc ON alerts (target_type, target_id, triggered_at DESC);

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'signaldesk_app') THEN
    GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO signaldesk_app;
    GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA public TO signaldesk_app;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'signaldesk_readonly') THEN
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO signaldesk_readonly;
    GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO signaldesk_readonly;
  END IF;
END $$;
