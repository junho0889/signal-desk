from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import subprocess

from automation.config import AgentConfig
from automation.task_store import Task


@dataclass(slots=True)
class WorktreeContext:
    branch_name: str
    worktree_path: Path
    role_name: str


class GitError(RuntimeError):
    pass


class GitOps:
    def __init__(
        self,
        repo_root: Path,
        worktrees_root: Path,
        main_branch: str,
        remote_name: str,
        agents: dict[str, AgentConfig],
    ) -> None:
        self.repo_root = repo_root
        self.worktrees_root = worktrees_root
        self.main_branch = main_branch
        self.remote_name = remote_name
        self.agents = agents

    def run(self, *args: str, cwd: Path | None = None, check: bool = True) -> subprocess.CompletedProcess[str]:
        process = subprocess.run(
            ["git", *args],
            cwd=str(cwd or self.repo_root),
            text=True,
            capture_output=True,
            check=False,
        )
        if check and process.returncode != 0:
            command = " ".join(args)
            raise GitError(f"git {command} failed: {process.stderr.strip()}")
        return process

    def resolve_context(self, task: Task) -> WorktreeContext:
        agent = self.agents.get(task.owner, AgentConfig(name=task.owner))
        if agent.worktree_mode == "fixed":
            worktree_name = agent.worktree_name or task.owner.replace("signal-desk-", "")
            branch_name = agent.branch_name or f"worker/{worktree_name}"
        else:
            worktree_name = task.id.lower()
            branch_name = f"worker/{task.id.lower()}"
        return WorktreeContext(
            branch_name=branch_name,
            worktree_path=self.worktrees_root / worktree_name,
            role_name=task.owner,
        )

    def ensure_worktree(self, task: Task) -> WorktreeContext:
        context = self.resolve_context(task)
        if context.worktree_path.exists():
            return context

        self.worktrees_root.mkdir(parents=True, exist_ok=True)
        branch_exists = bool(self.run("branch", "--list", context.branch_name, check=False).stdout.strip())
        if branch_exists:
            self.run("worktree", "add", str(context.worktree_path), context.branch_name)
        else:
            self.run("worktree", "add", str(context.worktree_path), "-b", context.branch_name, self.main_branch)
        return context

    def sync_fixed_worktree(self, context: WorktreeContext) -> bool:
        if not context.worktree_path.exists() or not self.is_clean(context.worktree_path):
            return False
        process = self.run("merge", "--ff-only", self.main_branch, cwd=context.worktree_path, check=False)
        return process.returncode == 0

    def is_clean(self, worktree_path: Path) -> bool:
        process = self.run("status", "--porcelain", cwd=worktree_path)
        return not process.stdout.strip()

    def branch_divergence(self, branch_name: str) -> tuple[int, int]:
        reference = f"{self.remote_name}/{self.main_branch}"
        process = self.run("rev-list", "--left-right", "--count", f"{branch_name}...{reference}")
        ahead, behind = process.stdout.strip().split()
        return int(ahead), int(behind)
