# Storage Expansion Outline

## Purpose
Describe the next schema expansion beyond the current MVP read-model baseline.

## Required Layers
- raw ingestion layer
- normalized event and entity layer
- trust and provenance layer
- feature and model layer
- API read-model layer

## Required Table Families
- source registry and ingestion runs
- raw payload batches and raw source items
- alias maps and canonical entities
- dedup clusters and contradiction links
- trust assessments and quality flags
- feature snapshots and model runs
- published ranking snapshots and evidence links

## Storage Principles
- raw payloads remain replayable
- normalized entities remain traceable back to raw source records
- trust outputs are versioned, not overwritten silently
- published ranking outputs are reproducible for a given run id

## Ownership Boundary
- collector lane defines the intake and spool contract
- storage lane defines canonical schema, retention, and privilege model
- model and trust lanes define score outputs that storage must persist
