SELECT
  COUNT(*) AS total_rows,
  COUNT(*) FILTER (WHERE canonical_url IS NOT NULL AND canonical_url <> '') AS rows_with_canonical_url,
  COUNT(*) FILTER (WHERE COALESCE(summary_text, '') <> '' OR COALESCE(excerpt_text, '') <> '') AS rows_with_summary_or_excerpt,
  COUNT(*) FILTER (WHERE jsonb_array_length(COALESCE(outbound_links_json, '[]'::jsonb)) > 0) AS rows_with_outbound_links
FROM spool_items;
