SELECT
  COUNT(*) AS total_rows,
  SUM(
    CASE
      WHEN publisher_name = ''
        OR publisher_domain = ''
        OR canonical_url = ''
        OR title = ''
        OR payload_hash = ''
      THEN 1
      ELSE 0
    END
  ) AS rows_with_missing_core_metadata,
  SUM(CASE WHEN quality_state = 'accepted' THEN 1 ELSE 0 END) AS accepted_rows,
  SUM(CASE WHEN quality_state = 'duplicate' THEN 1 ELSE 0 END) AS duplicate_rows,
  SUM(CASE WHEN quality_state = 'accepted_degraded' THEN 1 ELSE 0 END) AS accepted_degraded_rows,
  SUM(CASE WHEN quality_state = 'stale_source' THEN 1 ELSE 0 END) AS stale_source_rows,
  SUM(CASE WHEN quality_state = 'quarantined' THEN 1 ELSE 0 END) AS quarantined_rows,
  SUM(CASE WHEN status = 'accepted' AND retry_count > 0 THEN 1 ELSE 0 END) AS accepted_rows_with_retry_count,
  SUM(CASE WHEN transport_status = 'offline_retry' THEN 1 ELSE 0 END) AS offline_retry_rows
FROM spool_items;
