# Checkpoint Policy

## Purpose
Make progress recoverable and reviewable even when sessions end unexpectedly or token limits are reached.

## When A Checkpoint Is Required
- after any substantial source change
- after a feature milestone becomes reviewable
- after a meaningful bug investigation or defect fix
- before handing work to another worker
- before stopping because of token or context limits

## Required Checkpoint Actions
1. stage and commit the meaningful work on the current task branch
2. push the branch to the remote when possible
3. update the task handoff if another worker is waiting
4. update `coordination/resume/<TASK-ID>.md` if the task is not fully done

## Commit Message Rule
- start the commit message with the task id
- examples:
- `DATA-001 feat: define scoring normalization rules`
- `BE-001 fix: tighten keyword detail payload`
- `APP-001 chore: checkpoint loading-state refactor`

## Push Rule
- push every reviewable checkpoint
- if push fails, record the exact command and error in the handoff and resume note
- do not hide unpushed work at session end
