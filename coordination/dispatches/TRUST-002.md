# Dispatch TRUST-002

## Task
- id: TRUST-002
- owner role: signal-desk-trust
- priority: high

## Objective
Freeze the trust-to-model feature contract and define when contradiction or misinformation-risk states must escalate into manual review rather than silently flowing into ranking.

## Required Reads
- `AGENTS.md`
- `coordination/working-agreement.md`
- `docs/trust/trust-framework.md`
- `docs/model/model-system-v1.md`
- `docs/model/ranking-roadmap.md`
- `docs/backend/storage-expansion-outline.md`
- `coordination/handoffs/TRUST-001.md` when available
- `coordination/handoffs/MODEL-002.md` when available
- `coordination/handoffs/BE-006.md` when available

## Files You Own
- `docs/trust/trust-framework.md`

## Deliverables
- model-input view of trust outputs and threshold semantics
- manual-review escalation policy for contradiction and misinformation-risk states
- feedback loop guidance for labels, evaluation, and future training

## Constraints
- do not reduce trust to one final yes-or-no field
- preserve inspectable uncertainty and explicit escalation states
- keep app-facing warning semantics aligned with trust storage and model behavior

## Verification
- document consistency review against model and storage docs
- `git diff --check`

## Handoff
- identify which trust inputs and escalation states downstream lanes can now treat as frozen
