from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import yaml


@dataclass(slots=True)
class Task:
    id: str
    title: str
    owner: str
    status: str
    depends_on: list[str]
    files: list[str]
    acceptance: list[str]
    index: int


class TaskStore:
    def __init__(self, path: Path) -> None:
        self.path = path

    def load(self) -> tuple[dict, list[Task]]:
        raw = yaml.safe_load(self.path.read_text(encoding="utf-8"))
        if not isinstance(raw, dict):
            raise ValueError(f"Invalid task file: {self.path}")
        tasks_raw = raw.get("tasks", [])
        tasks: list[Task] = []
        for index, item in enumerate(tasks_raw):
            tasks.append(
                Task(
                    id=item["id"],
                    title=item["title"],
                    owner=item["owner"],
                    status=item["status"],
                    depends_on=list(item.get("depends_on", [])),
                    files=list(item.get("files", [])),
                    acceptance=list(item.get("acceptance", [])),
                    index=index,
                )
            )
        return raw, tasks

    def save(self, raw: dict) -> None:
        rendered = yaml.safe_dump(raw, sort_keys=False, allow_unicode=False)
        self.path.write_text(rendered, encoding="utf-8")

    @staticmethod
    def update_status(raw: dict, task_id: str, status: str) -> None:
        for item in raw.get("tasks", []):
            if item.get("id") == task_id:
                item["status"] = status
                return
        raise KeyError(f"Unknown task id: {task_id}")


def index_tasks(tasks: list[Task]) -> dict[str, Task]:
    return {task.id: task for task in tasks}


def dependencies_done(task: Task, task_index: dict[str, Task]) -> bool:
    return all(task_index[dependency].status == "done" for dependency in task.depends_on)


def ready_tasks(tasks: list[Task], task_index: dict[str, Task]) -> list[Task]:
    return [task for task in tasks if task.status == "todo" and dependencies_done(task, task_index)]


def active_tasks(tasks: list[Task]) -> list[Task]:
    return [task for task in tasks if task.status == "in_progress"]
