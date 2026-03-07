from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
import argparse
import json
import os
import subprocess
import time

from automation.config import AppConfig, load_app_config
from automation.git_ops import GitError, GitOps
from automation.prompt_builder import render_qa_prompt, render_status_markdown, render_worker_prompt
from automation.runtime_store import RuntimeStore
from automation.task_store import TaskStore, active_tasks, index_tasks, ready_tasks


@dataclass(slots=True)
class CycleResult:
    actions: list[str]
    warnings: list[str]


class Supervisor:
    def __init__(self, config: AppConfig) -> None:
        self.config = config
        self.repo_root = config.supervisor.repo_root
        self.task_store = TaskStore(self.repo_root / "coordination" / "tasks.yaml")
        self.runtime_store = RuntimeStore(config.supervisor.runtime_root / "state.json")
        self.git = GitOps(
            repo_root=self.repo_root,
            worktrees_root=config.supervisor.worktrees_root,
            main_branch=config.supervisor.main_branch,
            remote_name=config.supervisor.remote_name,
            agents=config.agents,
        )
        self.queue_dir = config.supervisor.runtime_root / "queue"
        self.log_dir = config.supervisor.runtime_root / "logs"
        self.status_path = config.supervisor.runtime_root / "status.md"

    def ensure_runtime_dirs(self) -> None:
        self.config.supervisor.runtime_root.mkdir(parents=True, exist_ok=True)
        self.queue_dir.mkdir(parents=True, exist_ok=True)
        self.log_dir.mkdir(parents=True, exist_ok=True)

    def run_cycle(self, dry_run: bool = False) -> CycleResult:
        self.ensure_runtime_dirs()
        raw_tasks, tasks = self.task_store.load()
        task_index = index_tasks(tasks)
        runtime = self.runtime_store.load()
        actions: list[str] = []
        warnings: list[str] = []
        task_file_changed = False

        if self.config.supervisor.auto_activate_ready_tasks:
            for task in ready_tasks(tasks, task_index):
                if dry_run:
                    actions.append(f"Would activate ready task {task.id}")
                    continue
                TaskStore.update_status(raw_tasks, task.id, "in_progress")
                task.status = "in_progress"
                task_file_changed = True
                actions.append(f"Activated ready task {task.id}")
                RuntimeStore.record_event(runtime, "info", "Activated ready task", task.id)
        else:
            for task in ready_tasks(tasks, task_index):
                warnings.append(f"Ready task {task.id} is waiting because auto activation is disabled")

        active = active_tasks(tasks)
        for task in active:
            context = self.git.resolve_context(task)
            resume_path = self.repo_root / "coordination" / "resume" / f"{task.id}.md"
            dispatch_path = self.repo_root / "coordination" / "dispatches" / f"{task.id}.md"
            task_state = RuntimeStore.task_state(runtime, task.id)

            if self.config.supervisor.auto_create_worktrees:
                try:
                    if not dry_run:
                        self.git.ensure_worktree(task)
                    actions.append(f"Ensured worktree for {task.id}: {context.worktree_path}")
                except GitError as error:
                    warnings.append(f"Failed to ensure worktree for {task.id}: {error}")
                    RuntimeStore.record_event(runtime, "error", str(error), task.id)
                    continue

            if not dispatch_path.exists():
                warning = f"Active task {task.id} is missing dispatch file {dispatch_path.name}"
                warnings.append(warning)
                RuntimeStore.record_event(runtime, "warning", warning, task.id)
                continue

            if not resume_path.exists():
                warning = f"Active task {task.id} is missing resume note {resume_path.name}"
                warnings.append(warning)
                RuntimeStore.record_event(runtime, "warning", warning, task.id)

            prompt = render_worker_prompt(task, context, self.repo_root, dispatch_path, resume_path)
            prompt_hash = __import__('hashlib').sha256(prompt.encode("utf-8")).hexdigest()
            prompt_path = self.queue_dir / f"{task.id}.prompt.md"
            if task_state.get("worker_prompt_hash") != prompt_hash or not prompt_path.exists():
                actions.append(f"Queued worker prompt for {task.id}")
                if not dry_run:
                    prompt_path.write_text(prompt, encoding="utf-8")
                    task_state["worker_prompt_hash"] = prompt_hash
                    task_state["worker_prompt_path"] = str(prompt_path)
                    task_state["worker_prompt_updated_at"] = datetime.now(timezone.utc).isoformat()
                    self._run_external_command(
                        command_template=self.config.supervisor.worker_command_template,
                        prompt_path=prompt_path,
                        worktree_path=context.worktree_path,
                        task_id=task.id,
                        role_name=task.owner,
                        runtime=runtime,
                        channel="worker",
                    )

        qa_agent = self.config.agents.get("signal-desk-qa")
        qa_context = None
        if qa_agent:
            qa_stub = type("TaskStub", (), {"id": "QA", "owner": "signal-desk-qa"})()
            qa_context = self.git.resolve_context(qa_stub)  # type: ignore[arg-type]
            if qa_agent.worktree_mode == "fixed" and qa_context.worktree_path.exists() and not dry_run:
                self.git.sync_fixed_worktree(qa_context)

        handoff_dir = self.repo_root / "coordination" / "handoffs"
        for task in tasks:
            handoff_path = handoff_dir / f"{task.id}.md"
            if not handoff_path.exists():
                continue
            handoff_status = self._extract_handoff_status(handoff_path)
            if handoff_status != "done":
                continue
            task_state = RuntimeStore.task_state(runtime, task.id)
            handoff_marker = self._file_marker(handoff_path)
            if task_state.get("qa_prompt_marker") == handoff_marker:
                continue
            qa_prompt_path = self.queue_dir / f"QA-{task.id}.prompt.md"
            qa_prompt = render_qa_prompt(task, self.repo_root, handoff_path, self.repo_root / "coordination" / "resume" / f"{task.id}.md")
            actions.append(f"Queued QA review prompt for {task.id}")
            if not dry_run:
                qa_prompt_path.write_text(qa_prompt, encoding="utf-8")
                task_state["qa_prompt_marker"] = handoff_marker
                task_state["qa_prompt_path"] = str(qa_prompt_path)
                task_state["qa_prompt_updated_at"] = datetime.now(timezone.utc).isoformat()
                self._run_external_command(
                    command_template=self.config.supervisor.qa_command_template,
                    prompt_path=qa_prompt_path,
                    worktree_path=qa_context.worktree_path if qa_context else self.repo_root,
                    task_id=task.id,
                    role_name="signal-desk-qa",
                    runtime=runtime,
                    channel="qa",
                )

        queue_files = sorted(self.queue_dir.glob("*.md"))
        status_markdown = render_status_markdown(actions, warnings, queue_files, [task.id for task in active])
        if not dry_run:
            self.status_path.write_text(status_markdown, encoding="utf-8")
            self.runtime_store.save(runtime)
            if task_file_changed:
                self.task_store.save(raw_tasks)
        return CycleResult(actions=actions, warnings=warnings)

    def doctor(self) -> dict:
        _, tasks = self.task_store.load()
        task_index = index_tasks(tasks)
        active = [task.id for task in active_tasks(tasks)]
        ready = [task.id for task in ready_tasks(tasks, task_index)]
        return {
            "repo_root": str(self.repo_root),
            "worktrees_root": str(self.config.supervisor.worktrees_root),
            "runtime_root": str(self.config.supervisor.runtime_root),
            "main_branch": self.config.supervisor.main_branch,
            "remote_name": self.config.supervisor.remote_name,
            "auto_activate_ready_tasks": self.config.supervisor.auto_activate_ready_tasks,
            "auto_create_worktrees": self.config.supervisor.auto_create_worktrees,
            "worker_command_configured": bool(self.config.supervisor.worker_command_template),
            "qa_command_configured": bool(self.config.supervisor.qa_command_template),
            "openai_api_key_present": bool(os.getenv("OPENAI_API_KEY")),
            "task_count": len(tasks),
            "active_tasks": active,
            "ready_tasks": ready,
        }

    def loop(self, interval_seconds: int, dry_run: bool = False) -> None:
        while True:
            result = self.run_cycle(dry_run=dry_run)
            print(f"[{datetime.now().isoformat(timespec='seconds')}] actions={len(result.actions)} warnings={len(result.warnings)}")
            for line in result.actions:
                print(f"ACTION: {line}")
            for line in result.warnings:
                print(f"WARNING: {line}")
            time.sleep(interval_seconds)

    def _run_external_command(
        self,
        command_template: str | None,
        prompt_path: Path,
        worktree_path: Path,
        task_id: str,
        role_name: str,
        runtime: dict,
        channel: str,
    ) -> None:
        if not command_template:
            RuntimeStore.record_event(runtime, "info", f"Prompt queued for {channel} runner", task_id)
            return

        command = command_template.format(
            repo_root=self.repo_root,
            worktree=worktree_path,
            prompt_file=prompt_path,
            task_id=task_id,
            role=role_name,
        )
        process = subprocess.run(
            command,
            shell=True,
            cwd=str(worktree_path),
            text=True,
            capture_output=True,
            check=False,
        )
        log_path = self.log_dir / f"{datetime.now().strftime('%Y%m%d-%H%M%S')}-{channel}-{task_id}.log"
        log_path.write_text(
            "\n".join(
                [
                    f"command: {command}",
                    f"returncode: {process.returncode}",
                    "stdout:",
                    process.stdout.strip(),
                    "stderr:",
                    process.stderr.strip(),
                ]
            )
            + "\n",
            encoding="utf-8",
        )
        level = "info" if process.returncode == 0 else "error"
        RuntimeStore.record_event(runtime, level, f"External {channel} command exit={process.returncode}", task_id)

    @staticmethod
    def _extract_handoff_status(handoff_path: Path) -> str | None:
        for line in handoff_path.read_text(encoding="utf-8").splitlines():
            normalized = line.strip().lower()
            if normalized.startswith("- status:"):
                return normalized.split(":", 1)[1].strip()
        return None

    @staticmethod
    def _file_marker(path: Path) -> str:
        stat = path.stat()
        return f"{int(stat.st_mtime)}:{stat.st_size}"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="SignalDesk automation supervisor")
    subparsers = parser.add_subparsers(dest="command", required=True)

    once_parser = subparsers.add_parser("once", help="Run one supervision cycle")
    once_parser.add_argument("--dry-run", action="store_true", help="Do not write any runtime or task changes")

    loop_parser = subparsers.add_parser("loop", help="Run repeated supervision cycles")
    loop_parser.add_argument("--dry-run", action="store_true", help="Do not write any runtime or task changes")
    loop_parser.add_argument("--interval", type=int, default=None, help="Polling interval in seconds")

    subparsers.add_parser("doctor", help="Inspect local automation prerequisites")
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    config = load_app_config()
    supervisor = Supervisor(config)

    if args.command == "doctor":
        print(json.dumps(supervisor.doctor(), indent=2, sort_keys=True))
        return 0
    if args.command == "once":
        result = supervisor.run_cycle(dry_run=args.dry_run)
        print(json.dumps({"actions": result.actions, "warnings": result.warnings}, indent=2))
        return 0
    if args.command == "loop":
        interval = args.interval or config.supervisor.poll_seconds
        supervisor.loop(interval_seconds=interval, dry_run=args.dry_run)
        return 0

    parser.error("Unknown command")
    return 2
