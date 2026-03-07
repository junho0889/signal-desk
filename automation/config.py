from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import os

import yaml


@dataclass(slots=True)
class AgentConfig:
    name: str
    worktree_mode: str = "per_task"
    worktree_name: str | None = None
    branch_name: str | None = None


@dataclass(slots=True)
class SupervisorConfig:
    repo_root: Path
    worktrees_root: Path
    runtime_root: Path
    main_branch: str
    remote_name: str
    poll_seconds: int
    auto_activate_ready_tasks: bool
    auto_create_worktrees: bool
    worker_command_template: str | None
    qa_command_template: str | None


@dataclass(slots=True)
class AppConfig:
    supervisor: SupervisorConfig
    agents: dict[str, AgentConfig]


def _load_yaml(path: Path) -> dict:
    if not path.exists():
        return {}
    raw = yaml.safe_load(path.read_text(encoding="utf-8"))
    if raw is None:
        return {}
    if not isinstance(raw, dict):
        raise ValueError(f"Expected YAML object in {path}")
    return raw


def _resolve_path(value: str, repo_root: Path) -> Path:
    candidate = Path(value)
    if candidate.is_absolute():
        return candidate
    return (repo_root / candidate).resolve()


def load_app_config(repo_root: Path | None = None) -> AppConfig:
    root = repo_root or Path(__file__).resolve().parents[1]
    config_dir = root / "automation" / "config"

    supervisor_data = _load_yaml(config_dir / "supervisor.yaml")
    agent_data = _load_yaml(config_dir / "agents.yaml").get("agents", {})

    supervisor = SupervisorConfig(
        repo_root=root,
        worktrees_root=_resolve_path(
            os.getenv("SIGNALDESK_WORKTREES_ROOT") or supervisor_data.get("worktrees_root", "../signal-desk-worktrees"),
            root,
        ),
        runtime_root=_resolve_path(
            supervisor_data.get("runtime_root", "automation/runtime"),
            root,
        ),
        main_branch=os.getenv("SIGNALDESK_MAIN_BRANCH") or supervisor_data.get("main_branch", "main"),
        remote_name=os.getenv("SIGNALDESK_REMOTE_NAME") or supervisor_data.get("remote_name", "origin"),
        poll_seconds=int(os.getenv("SIGNALDESK_POLL_SECONDS") or supervisor_data.get("poll_seconds", 60)),
        auto_activate_ready_tasks=(
            str(os.getenv("SIGNALDESK_AUTO_ACTIVATE", supervisor_data.get("auto_activate_ready_tasks", False))).lower()
            in {"1", "true", "yes", "on"}
        ),
        auto_create_worktrees=(
            str(os.getenv("SIGNALDESK_AUTO_CREATE_WORKTREES", supervisor_data.get("auto_create_worktrees", True))).lower()
            in {"1", "true", "yes", "on"}
        ),
        worker_command_template=os.getenv("SIGNALDESK_WORKER_COMMAND") or supervisor_data.get("worker_command_template") or None,
        qa_command_template=os.getenv("SIGNALDESK_QA_COMMAND") or supervisor_data.get("qa_command_template") or None,
    )

    agents: dict[str, AgentConfig] = {}
    for name, values in agent_data.items():
        agents[name] = AgentConfig(
            name=name,
            worktree_mode=values.get("worktree_mode", "per_task"),
            worktree_name=values.get("worktree_name"),
            branch_name=values.get("branch_name"),
        )

    return AppConfig(supervisor=supervisor, agents=agents)
