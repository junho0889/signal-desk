# Thread Registry

## Purpose
Lock the user-facing thread names so orchestration messages always refer to the same labels.

## Fixed Thread Names
- `Collector`
  - role: `signal-desk-collector`
  - primary task lane: `COL-001`
  - worktree: `E:\source\signal-desk-worktrees\collector-001`

- `BE-storage`
  - role: `signal-desk-storage`
  - primary task lane: `BE-004`
  - worktree: `E:\source\signal-desk-worktrees\storage-001`

- `MODEL`
  - role: `signal-desk-model`
  - primary task lane: `MODEL-001`
  - worktree: `E:\source\signal-desk-worktrees\model-001`

- `TRUST`
  - role: `signal-desk-trust`
  - primary task lane: `TRUST-001`
  - worktree: `E:\source\signal-desk-worktrees\trust-001`

- `DESIGN`
  - role: `signal-desk-design`
  - primary task lane: `DESIGN-002`
  - worktree: `E:\source\signal-desk-worktrees\design-002`

- `APP`
  - role: `signal-desk-mobile`
  - primary task lane: `APP-006`
  - worktree: `E:\source\signal-desk-worktrees\app-006`

- `Mobile thread`
  - role: `signal-desk-mobile`
  - active task lane: `APP-005` or other mobile implementation tasks
  - worktree: `E:\source\signal-desk-worktrees\app-005`

- `QA thread`
  - role: `signal-desk-qa`
  - primary task lanes: `QA-003`, `QA-004`
  - worktree: `E:\source\signal-desk-worktrees\qa-station`

- `Ops thread`
  - role: `signal-desk-ops`
  - primary task lane: `OPS-004`
  - worktree: `E:\source\signal-desk-worktrees\ops-004`

- `Backend thread`
  - role: `signal-desk-backend`
  - primary support lane: `BE-003`
  - worktree: `E:\source\signal-desk-worktrees\be-003`

- `Orchestrator thread`
  - role: `signal-desk-orchestrator`
  - coordination root: `E:\source\signal-desk`

## Rule
- In user-facing orchestration updates, always use the fixed thread names above.
- Do not rename threads implicitly in summaries.
- If a new thread is added later, register it here first before referring to it in user-facing updates.
