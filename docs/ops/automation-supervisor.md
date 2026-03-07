# Automation Supervisor

## Purpose
Provide a headless supervision loop for SignalDesk so task discovery, prompt queueing, worktree preparation, and QA review requests do not depend on manually nudging idle chat windows.

## What It Does Today
- reads `coordination/tasks.yaml`
- identifies active and ready tasks
- ensures task worktrees exist when enabled
- writes runtime prompt files for active workers
- writes QA review prompt files when a task handoff reaches `status: done`
- writes runtime status and event state under `automation/runtime/`
- supports repeated polling with `loop`

## What It Does Not Do By Default
- it does not edit tracked project files on behalf of workers
- it does not call a model automatically unless an external worker command is configured
- it does not bypass checkpoint, handoff, or resume rules

## Runtime Modes
- `prompt_only`: default mode; supervisor writes prompt files and status, but does not launch external worker commands
- `external_command`: optional mode; configure `SIGNALDESK_WORKER_COMMAND` and `SIGNALDESK_QA_COMMAND` to launch a headless runner when prompts are queued

## Required Files
- `automation/config/supervisor.yaml`
- `automation/config/agents.yaml`
- `coordination/tasks.yaml`
- `coordination/dispatches/<TASK-ID>.md`
- `coordination/handoffs/<TASK-ID>.md` for QA review triggering

## Runtime Output
- `automation/runtime/state.json`
- `automation/runtime/status.md`
- `automation/runtime/queue/*.prompt.md`
- `automation/runtime/logs/*.log`

## Quick Start
1. run doctor:
- `python -m automation.main doctor`
2. run one dry cycle:
- `python -m automation.main once --dry-run`
3. run one real cycle in prompt-only mode:
- `python -m automation.main once`
4. run continuous supervision:
- `python -m automation.main loop --interval 60`

## External Runner Placeholders
Command templates may use these placeholders:
- `{repo_root}`
- `{worktree}`
- `{prompt_file}`
- `{task_id}`
- `{role}`

## Recommended Next Step For Full Autonomy
Wire `SIGNALDESK_WORKER_COMMAND` and `SIGNALDESK_QA_COMMAND` to a headless local runner that can read the prompt file, operate in the assigned worktree, and follow the checkpoint/handoff/resume contract.