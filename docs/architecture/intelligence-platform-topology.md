# Intelligence Platform Topology

## Purpose
Define the next-phase split between always-on collection, central storage, trust scoring, ranking, API delivery, and mobile consumption.

## Target Topology
1. `collector-node` on Raspberry Pi 4B 8GB
- runs source adapters continuously
- writes raw payloads to a local spool directory first
- retries and forwards accepted payloads to central storage or a central intake service

2. `central-storage` on the main host
- stores raw payloads, normalized records, trust assessments, model outputs, and API read models
- remains the authoritative source of truth for ranking and app-serving data

3. `normalization + trust + ranking jobs`
- normalize raw payloads into canonical entities
- score freshness, credibility, contradiction, and quality flags
- build feature snapshots and publish ranking outputs

4. `api`
- serves only stable read models and explainable evidence payloads

5. `mobile`
- consumes ranking, detail, watchlist, alert, trust, and chart payloads through documented APIs

## Raspberry Pi Collector Node
- hardware target: Raspberry Pi 4B 8GB
- role: collector only, not the main ranking or API host
- expected duties:
  - source polling and webhook intake
  - local spool persistence for transient network failure
  - payload signing or provenance metadata attachment if required
  - retry and backoff scheduling
  - heartbeat and queue-depth reporting

## Central Processing Boundary
- central storage owns canonical raw and normalized history
- normalization jobs own alias resolution, deduplication, and event extraction
- trust jobs own source reliability and misinformation-risk outputs
- model jobs own feature generation, ranking, and evaluation

## Data Movement Contract
- collector writes payloads to local spool before marking a source cycle successful
- each payload carries:
  - source id
  - collection timestamp
  - upstream event timestamp when available
  - payload hash
  - retry count
  - transport status
- central intake acknowledges receipt before the collector can prune local spool items

## Design Implication
- the app must be able to surface:
  - freshness
  - evidence source mix
  - trust score
  - ranking movement
  - contradictions or low-confidence warnings

## Open Lanes
- collector lane: Raspberry Pi source adapters and spool contract
- storage lane: raw, normalized, trust-aware schema and retention
- model lane: ranking and evaluation framework
- trust lane: credibility and misinformation framework
- design lane: chart system and premium information layout
- app lane: integrate charts, trust, and multilingual surfaces
