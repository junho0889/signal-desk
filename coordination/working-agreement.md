# Working Agreement

## Purpose
Run this repo as a small specialist team even when work is performed across separate Codex sessions.

## Core Rules
- One orchestrator coordinates priorities and dependency order.
- Specialist workers own bounded domains.
- The repository is the only reliable communication channel.
- Shared contracts are edited deliberately and announced in the decision log.
- Verification is mandatory. Every meaningful change must be tested, debugged, or explicitly blocked.
- QA is not optional. Release-ready work requires explicit QA review or an orchestrator-approved reason to defer it.

## Session Topology
- Keep one orchestrator session open at all times.
- Add two or three worker sessions only when tasks are truly independent.
- Reserve one worker slot for QA once code or behavior exists to test.
- Do not exceed three active worker sessions until the repo has stable contracts and real code modules.
- If two tasks touch the same file, keep them serial.

## Communication Rules
- Claim work by updating `coordination/tasks.yaml`.
- Read the dispatch file for the task before making changes.
- Use task ids everywhere: commits, handoffs, decisions, and notes.
- Write a handoff when:
- you stop before the task is done
- you finish a task that unblocks another worker
- you discover a blocker, risk, or contract mismatch
- include the exact verification commands you ran and the result
- Keep handoffs short and factual.

## Supervision Rules
- Orchestrator checks active tasks, recent handoffs, and worktree git status repeatedly during the session.
- Orchestrator gives corrective feedback when a worker drifts from owned files, skips verification, or changes a contract without documenting it.
- Workers do not self-certify project completion. Only orchestrator can issue completion or downstream release signals.
- QA records defects as task follow-ups or blocker handoffs, not as informal chat only.

## File Ownership
- Product: `docs/product/*`
- Design: `docs/design/*`
- Data: `docs/data/*`, future ingestion jobs
- Backend: `docs/backend/*`, future API services
- Mobile: future Flutter app folders
- Ops: `docs/ops/*`, `infra/*`, `scripts/orchestrator/*`
- QA: `docs/ops/qa-strategy.md`, future test plans, defect notes
- Shared: `AGENTS.md`, `coordination/*`, `INSTALL-LOG.md`

## Parallel Work Pattern
1. Orchestrator creates or updates tasks with dependencies.
2. Orchestrator writes a dispatch file when the task needs specific instructions.
3. Orchestrator creates or assigns a git worktree for each active worker.
4. Each worker claims one task with clear file boundaries.
5. Workers read only the docs and skill files needed for that task.
6. Workers update contracts first when they must change a shared interface.
7. Workers run the required checks and write a handoff note.
8. Orchestrator reviews the handoff, diffs, and blockers before releasing the next task.

## Definition Of Ready
- Problem is described in one sentence.
- Acceptance criteria are listed.
- File ownership is clear.
- Dependencies are either done or explicitly listed.
- Required verification commands are known.

## Definition Of Done
- Required files are updated.
- Decisions and assumptions are documented.
- Verification commands and outcomes are recorded.
- The task entry is updated.
- A handoff note exists if another worker needs to continue.
- QA review exists for user-facing or integration-sensitive work.
