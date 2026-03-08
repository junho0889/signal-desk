from __future__ import annotations

import argparse
import json
from typing import Any

from .alerts import evaluate_alerts
from .config import load_settings
from .db import get_connection
from .delivery import build_notification_deliveries, dispatch_deliveries
from .demo_data import seed_demo_data
from .migrations import apply_migrations


def _print(payload: dict[str, Any]) -> None:
    print(json.dumps(payload, indent=2, default=str))


def cmd_migrate() -> None:
    settings = load_settings()
    with get_connection(settings.migrator_database_url) as conn:
        applied = apply_migrations(conn)
        conn.commit()
    _print({'command': 'migrate', 'applied': applied})


def cmd_seed_demo() -> None:
    settings = load_settings()
    with get_connection(settings.app_database_url) as conn:
        summary = seed_demo_data(conn)
        conn.commit()
    _print({'command': 'seed-demo', 'summary': summary})


def cmd_evaluate_alerts() -> None:
    settings = load_settings()
    with get_connection(settings.app_database_url) as conn:
        result = evaluate_alerts(conn, delta_threshold=settings.alert_delta_threshold)
        conn.commit()

    deliveries = build_notification_deliveries(
        result['items'],
        title_prefix=settings.notification_title_prefix,
    )
    delivery_result = dispatch_deliveries(
        deliveries,
        sink=settings.notification_sink,
    )
    _print(
        {
            'command': 'evaluate-alerts',
            'result': {
                **result,
                'delivery': delivery_result,
            },
        }
    )


def cmd_run_once() -> None:
    cmd_migrate()
    cmd_seed_demo()
    cmd_evaluate_alerts()


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description='SignalDesk jobs runner')
    parser.add_argument(
        'command',
        choices=['migrate', 'seed-demo', 'evaluate-alerts', 'run-once'],
        help='operation to execute',
    )
    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()

    if args.command == 'migrate':
        cmd_migrate()
    elif args.command == 'seed-demo':
        cmd_seed_demo()
    elif args.command == 'evaluate-alerts':
        cmd_evaluate_alerts()
    else:
        cmd_run_once()


if __name__ == '__main__':
    main()
