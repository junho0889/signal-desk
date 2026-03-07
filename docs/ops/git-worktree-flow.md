# Git Worktree Flow

## Why Worktrees
Use one main repository for orchestration and separate git worktrees for active workers. This isolates branches without duplicating the full repository.

## Layout
- orchestrator repo: `E:\source\signal-desk`
- worker worktrees: `E:\source\signal-desk-worktrees\<task-or-role>`

## Branch Rules
- keep `main` in the orchestrator repo only
- give each worker a task branch such as `worker/prod-001` or `worker/data-001`
- workers commit to their branch when they complete a reviewable unit
- workers push every meaningful checkpoint unless blocked and documented
- orchestrator reviews before merging or cherry-picking into `main`

## Standard Flow
1. orchestrator updates `main`
2. orchestrator creates a task branch and worktree from `main`
3. worker uses only that worktree
4. worker commits and pushes reviewable checkpoints
5. worker updates handoff and resume notes when pausing
6. orchestrator reviews the diff and either requests changes or integrates it
7. QA validates behavior on the integrated result or the worker branch, depending on the task

## Commands
Initialize repo:
- `git init -b main`
- `git remote add origin https://github.com/junho0889/signal-desk.git`

Create a worker worktree:
- `git worktree add E:\source\signal-desk-worktrees\prod-001 -b worker/prod-001 main`

Create a checkpoint commit:
- `git add -A`
- `git commit -m "PROD-001 docs: tighten MVP scope"`

Push a checkpoint branch:
- `git push -u origin worker/prod-001`

List worktrees:
- `git worktree list`

Review worker diff from orchestrator repo:
- `git log --oneline --decorate --graph --all -20`
- `git diff main..worker/prod-001`

Integrate after acceptance:
- `git merge --no-ff worker/prod-001`

Clean up after merge:
- `git worktree remove E:\source\signal-desk-worktrees\prod-001`
- `git branch -d worker/prod-001`
