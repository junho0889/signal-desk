from __future__ import annotations

from typing import Any


def build_notification_deliveries(
    alerts: list[dict[str, Any]],
    *,
    title_prefix: str,
) -> list[dict[str, Any]]:
    deliveries: list[dict[str, Any]] = []
    normalized_prefix = title_prefix.strip() or 'SignalDesk'

    for alert in alerts:
        keyword_id = alert.get('keyword_id') or (
            alert.get('target_id') if alert.get('target_type') == 'keyword' else None
        )
        deliveries.append(
            {
                'delivery_id': f"{alert['alert_id']}:push",
                'channel': 'push',
                'title': f"{normalized_prefix} | {str(alert['severity']).upper()} alert",
                'body': alert['message'],
                'route': {
                    'name': 'keyword_detail' if keyword_id else 'alerts',
                    'params': {'keyword_id': keyword_id} if keyword_id else {},
                },
                'meta': {
                    'alert_id': alert['alert_id'],
                    'target_type': alert['target_type'],
                    'target_id': alert['target_id'],
                    'target_label': alert['target_label'],
                    'keyword_id': keyword_id,
                    'severity': alert['severity'],
                    'triggered_at': alert['triggered_at'],
                },
            }
        )

    return deliveries


def dispatch_deliveries(
    deliveries: list[dict[str, Any]],
    *,
    sink: str,
) -> dict[str, Any]:
    if sink == 'none':
        return {
            'sink': sink,
            'attempted': len(deliveries),
            'delivered': 0,
            'items': [],
        }

    if sink == 'stdout':
        return {
            'sink': sink,
            'attempted': len(deliveries),
            'delivered': len(deliveries),
            'items': deliveries,
        }

    raise ValueError(f'Unsupported notification sink: {sink}')
