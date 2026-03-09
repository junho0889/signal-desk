SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT payload_hash) AS distinct_payload_hashes,
  COUNT(DISTINCT idempotency_key) AS distinct_idempotency_keys,
  SUM(ingest_count) AS total_ingest_count,
  SUM(CASE WHEN retry_count > 0 THEN 1 ELSE 0 END) AS rows_with_retries,
  SUM(CASE WHEN status = 'accepted' AND retry_count > 0 THEN 1 ELSE 0 END) AS accepted_rows_with_retry_count
FROM spool_items;
