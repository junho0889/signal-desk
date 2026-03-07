from __future__ import annotations

from datetime import datetime, timezone
from pathlib import Path
import json


DEFAULT_STATE = {
    "version": 1,
    "tasks": {},
    "events": [],
}


class RuntimeStore:
    def __init__(self, path: Path) -> None:
        self.path = path

    def load(self) -> dict:
        if not self.path.exists():
            return json.loads(json.dumps(DEFAULT_STATE))
        return json.loads(self.path.read_text(encoding="utf-8"))

    def save(self, state: dict) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.path.write_text(json.dumps(state, indent=2, sort_keys=True), encoding="utf-8")

    @staticmethod
    def task_state(state: dict, task_id: str) -> dict:
        return state.setdefault("tasks", {}).setdefault(task_id, {})

    @staticmethod
    def record_event(state: dict, level: str, message: str, task_id: str | None = None) -> None:
        event = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "level": level,
            "message": message,
        }
        if task_id:
            event["task_id"] = task_id
        state.setdefault("events", []).append(event)
        state["events"] = state["events"][-200:]
