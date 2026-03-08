SELECT
  spool_id::text,
  source_id,
  source_category,
  publisher_name,
  publisher_domain,
  idempotency_key,
  status,
  quality_state,
  retry_count,
  ingest_count,
  collected_at_utc,
  upstream_event_at_utc,
  last_ship_attempt_at_utc,
  last_error_code
FROM spool_items
ORDER BY collected_at_utc, spool_id;
