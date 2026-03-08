# Dispatch TRUST-001

## Task
- id: TRUST-001
- owner role: signal-desk-trust
- priority: high

## Objective
Define the trust layer that scores source credibility, contradiction risk, freshness, and misinformation-risk indicators without collapsing uncertainty into a single binary verdict.

## Required Reads
- `AGENTS.md`
- `coordination/working-agreement.md`
- `docs/trust/trust-framework.md`
- `docs/data/source-catalog.md`
- `docs/architecture/intelligence-platform-topology.md`
- `docs/backend/storage-expansion-outline.md`
- `coordination/handoffs/BE-004.md` when available

## Files You Own
- `docs/trust/trust-framework.md`

## Deliverables
- trust dimensions and score outputs
- contradiction and misinformation-risk handling policy
- storage-facing output expectations and app-facing warning candidates

## Constraints
- make uncertainty inspectable
- keep the trust layer explainable and auditable
- do not turn this task into a full ML implementation task

## Verification
- document consistency review against storage and data docs
- `git diff --check`

## Handoff
- call out which outputs design, app, and model lanes should treat as stable
