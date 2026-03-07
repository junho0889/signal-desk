# Dispatch Protocol

## Recommended Setup
- Keep one Codex window dedicated to the orchestrator.
- Open two worker windows when tasks are independent.
- Add a third worker only after contracts are stable.
- Keep one worker slot available for QA once the project has executable code or user-visible flows.
- Add a preview or runtime window only when you need to keep Docker services, an emulator, or `flutter run` alive.
- Do not open more windows than active tasks with separate file ownership.

## Why This Model
Codex sessions do not share durable short-term memory. Direct chat between windows is not a reliable system. The repository is the shared state.

## Dispatch Lifecycle
1. Orchestrator updates `coordination/tasks.yaml`.
2. Orchestrator writes `coordination/dispatches/<TASK-ID>.md`.
3. Orchestrator assigns or creates the worker git worktree.
4. Worker reads `AGENTS.md`, the role skill, the dispatch, and the task resume note when it exists.
5. Worker claims the task in `coordination/tasks.yaml`.
6. Worker makes changes and runs required checks.
7. Worker creates a checkpoint commit and pushes the branch when the work reaches a reviewable state.
8. Worker writes a handoff note in `coordination/handoffs/`.
9. Worker updates `coordination/resume/<TASK-ID>.md` before pausing.
10. Orchestrator reviews the handoff, git diff, push state, and contract impact.
11. QA reviews behavior or docs impact when required.
12. Orchestrator either closes the task, returns feedback, or issues follow-up work.

## Dispatch Must Include
- objective
- owned files
- dependencies
- required reads
- required verification commands
- checkpoint expectations
- handoff expectations

## Worker Rules
- Own one active task at a time.
- Do not change shared contracts silently.
- If a task becomes blocked, stop and write a blocker handoff.
- If verification cannot be run, explain exactly why.
- If push is blocked, record the blocker in the handoff and resume note.
- Keep the chat window open and continue the same session until the orchestrator redirects or closes the task.

## Orchestrator Rules
- Keep tasks small and unambiguous.
- Separate work by file boundaries, not just by topic.
- Review handoffs before assigning dependent work.
- Convert repeated verbal instructions into repo docs quickly.
- Monitor active worktrees with the status-board script and direct git inspection.
