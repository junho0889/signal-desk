# SignalDesk Cold Start

Use this file after a reboot or a long pause.

## One Prompt To Paste Into Codex

Paste this into a fresh Codex chat:

```text
Read E:\source\signal-desk\START.md and resume SignalDesk from the latest repo state.
Inspect coordination/tasks.yaml, automation/runtime/status.md, coordination/resume/, coordination/handoffs/, and git branch status.
Then tell me the exact next commands for the current active tasks and continue from the latest unfinished work.
```

## Minimum Shell Commands

Run these in PowerShell first:

```powershell
Set-Location E:\source\signal-desk
powershell -ExecutionPolicy Bypass -File .\scripts\orchestrator\status-board.ps1
```

If you want the supervisor loop running again:

```powershell
Set-Location E:\source\signal-desk
powershell -ExecutionPolicy Bypass -File .\scripts\orchestrator\run-supervisor.ps1 loop -Interval 60
```

## What To Trust For Resume State

Always trust these files in this order:

1. `coordination/tasks.yaml`
2. `coordination/resume/*.md`
3. `coordination/handoffs/*.md`
4. `automation/runtime/status.md`
5. `git status --short --branch` and `git log --oneline -1`

## Resume Checklist For Codex

When Codex resumes, it should:

1. Read `coordination/tasks.yaml` and find all `in_progress` tasks.
2. Read the matching `coordination/resume/<TASK-ID>.md` files.
3. Read any recent `coordination/handoffs/*.md`.
4. Check branch/worktree status for the active tasks.
5. Read `automation/runtime/status.md`.
6. Tell the user the exact next command or prompt to send to each active window.
7. Continue from the latest unfinished task instead of restarting planning.

## Current Working Pattern

- `Window 1`: orchestrator
- `Window 2`: active worker
- `Window 3`: QA
- `Window 4`: next dependency standby worker
- `Window 5`: supervisor loop or runtime support

## Current Snapshot

This section is only a hint. If it conflicts with the files above, ignore this section.

- Last known active task: `DATA-001`
- Last known next dependency: `BE-001`
- Runtime loop command: `powershell -ExecutionPolicy Bypass -File .\scripts\orchestrator\run-supervisor.ps1 loop -Interval 60`
