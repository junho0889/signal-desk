SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT idempotency_key) AS distinct_idempotency_keys,
  SUM(ingest_count) AS total_ingest_count
FROM spool_items;
