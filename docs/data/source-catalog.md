# Source Catalog

## Initial Sources
- News API: capture headlines, timestamps, source names, and article links
- Google Trends: capture keyword interest deltas and related queries
- Market data: capture price, return, and volume reaction for mapped stocks
- DART disclosures: capture filing events that strengthen or invalidate signal credibility

## Refresh Cadence
- News: every 30 minutes
- Trends: every 30 to 60 minutes depending on quota
- Market data: every 15 to 30 minutes during market hours
- DART: every 30 minutes

## Normalization Goals
- unify timestamps to one timezone strategy
- deduplicate near-identical headlines
- map aliases to canonical keyword names
- attach stocks and sectors where confidence is sufficient

## Risks
- noisy headline duplication
- ambiguous entity extraction
- limited trend granularity for niche themes
- delayed disclosure ingestion
