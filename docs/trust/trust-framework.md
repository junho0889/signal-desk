# Trust Framework

## Purpose
Define how SignalDesk will distinguish high-confidence information from stale, contradictory, or misleading signals.

## Trust Dimensions
- source reliability
- freshness
- source diversity
- contradiction risk
- entity-mapping confidence
- duplication and syndication intensity

## Output Types
- trust score
- coverage score
- contradiction flag
- stale source flag
- low-confidence mapping flag
- misinformation-risk review flag

## Principles
- do not reduce trust to a single yes or no verdict
- keep evidence and provenance inspectable
- make contradiction visible to users instead of hiding it
- preserve uncertainty where signals disagree

## Dependencies
- raw payload history
- normalized events
- source registry and source-level reputation inputs
