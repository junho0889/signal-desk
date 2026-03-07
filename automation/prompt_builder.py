from __future__ import annotations

from pathlib import Path

from automation.git_ops import WorktreeContext
from automation.task_store import Task


def render_worker_prompt(task: Task, context: WorktreeContext, repo_root: Path, dispatch_path: Path, resume_path: Path) -> str:
    lines = [
        f"You are the {task.owner} worker for task {task.id}.",
        f"Repository root: {repo_root}",
        f"Assigned worktree: {context.worktree_path}",
        "",
        "Required reads before editing:",
        "- AGENTS.md",
        "- coordination/working-agreement.md",
        "- coordination/checkpoint-policy.md",
        "- coordination/resume-template.md",
        f"- .codex/skills/{task.owner}/SKILL.md",
        f"- coordination/dispatches/{task.id}.md",
    ]
    if resume_path.exists():
        lines.append(f"- coordination/resume/{task.id}.md")
    lines.extend(
        [
            "",
            "Task contract:",
            f"- Own only the files listed in the dispatch and task metadata for {task.id}.",
            "- Create a checkpoint commit and push after each meaningful reviewable change.",
            "- Before pausing, update both the handoff note and the resume note.",
            "- Record exact verification commands and outcomes.",
            "- Stay active until the orchestrator accepts or redirects the task.",
            "",
            f"Dispatch file: {dispatch_path}",
            f"Resume file: {resume_path}",
        ]
    )
    return "\n".join(lines) + "\n"


def render_qa_prompt(task: Task, repo_root: Path, handoff_path: Path, resume_path: Path | None) -> str:
    lines = [
        "You are the signal-desk-qa reviewer.",
        f"Repository root: {repo_root}",
        f"Review target task: {task.id}",
        "",
        "Required reads before reviewing:",
        "- AGENTS.md",
        "- coordination/working-agreement.md",
        "- docs/ops/quality-gates.md",
        "- docs/ops/qa-strategy.md",
        "- coordination/checkpoint-policy.md",
        f"- coordination/handoffs/{task.id}.md",
    ]
    if resume_path and resume_path.exists():
        lines.append(f"- coordination/resume/{task.id}.md")
    lines.extend(
        [
            "",
            "QA contract:",
            "- Review the worker diff, handoff evidence, and verification commands.",
            "- Produce either a blocker handoff or an acceptance handoff.",
            "- Do not declare the project complete.",
            "- If QA updates repository files, create a checkpoint commit and push on the QA branch.",
            "",
            f"Handoff file: {handoff_path}",
        ]
    )
    return "\n".join(lines) + "\n"


def render_status_markdown(actions: list[str], warnings: list[str], queue_files: list[Path], active_task_ids: list[str]) -> str:
    lines = ["# Supervisor Status", "", "## Active Tasks"]
    if active_task_ids:
        lines.extend([f"- {task_id}" for task_id in active_task_ids])
    else:
        lines.append("- none")

    lines.extend(["", "## Queued Prompts"])
    if queue_files:
        lines.extend([f"- {path.name}" for path in queue_files])
    else:
        lines.append("- none")

    lines.extend(["", "## Actions"])
    if actions:
        lines.extend([f"- {action}" for action in actions])
    else:
        lines.append("- none")

    lines.extend(["", "## Warnings"])
    if warnings:
        lines.extend([f"- {warning}" for warning in warnings])
    else:
        lines.append("- none")

    return "\n".join(lines) + "\n"
