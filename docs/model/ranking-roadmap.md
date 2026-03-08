# Ranking Roadmap

## Purpose
Define the modeling lane for SignalDesk ranking beyond the current scoring-v0 baseline.

## Phase Order
1. explainable rule-based scoring
2. calibrated statistical ranking
3. supervised ranking after labels and evaluation sets exist
4. deeper model experimentation only when offline and online evaluation are stable

## Required Outputs
- daily and intraday ranking scores
- per-keyword feature breakdown
- explanation-ready contribution summaries
- run metadata for reproducibility

## Evaluation Requirements
- offline ranking correlation checks
- stability checks between adjacent runs
- alert precision review for high-severity outputs
- regression checks against stale or low-coverage source windows

## Dependencies
- stable raw and normalized storage
- trust features and credibility signals
- canonical entity mapping
