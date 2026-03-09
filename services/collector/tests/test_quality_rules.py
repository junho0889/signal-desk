from __future__ import annotations

from datetime import datetime, timezone
import unittest

from signaldesk_collector.config import Settings
from signaldesk_collector.main import (
    _apply_evidence_quality,
    _idempotency_key,
    _normalize_market_scope,
    _normalize_row,
    _shipper_outcome,
    _validate_envelope,
)


def _settings(**overrides: object) -> Settings:
    base = Settings(
        db_url="postgresql://collector:collector@collector-db:5432/signaldesk_collector",
        fixture_path="signaldesk_collector/fixtures/news_primary.json",
        collector_node_id="collector-test-node",
        source_id="news_primary",
        source_category="news",
        default_language="en",
        default_market_scope="KRX",
        adapter_version="collector-v1",
        retrieval_status="ok",
        source_cursor=None,
        source_expects_upstream_event_at=True,
        max_future_skew_seconds=600,
        central_host="192.168.0.200",
        shipper_mode="simulate-offline",
        shipper_batch_size=20,
        simulated_intake_status="retryable_failure",
        simulated_reason_code="storage_unavailable",
        daemon_interval_seconds=60,
        daemon_ship_every_cycles=1,
        daemon_stream_mode=False,
        daemon_event_step_minutes=5,
        daemon_max_cycles=0,
    )
    return Settings(**{**base.__dict__, **overrides})


class QualityRulesTests(unittest.TestCase):
    def test_news_idempotency_normalizes_case_spacing_url_and_timestamp(self) -> None:
        row_a = {
            "source_name": " SignalDesk Fixture Wire ",
            "title": "Battery  Supply  Chain  Mentions Increase",
            "url": "HTTPS://Fixture.SignalDesk.Local/news/battery-supply-chain-morning/",
            "published_at": "2026-03-08T01:00:00Z",
        }
        row_b = {
            "source_name": "signaldesk fixture wire",
            "title": "battery supply chain mentions increase",
            "url": "https://fixture.signaldesk.local/news/battery-supply-chain-morning",
            "published_at": "2026-03-08T01:00:00+00:00",
        }
        self.assertEqual(
            _idempotency_key("news_primary", row_a),
            _idempotency_key("news_primary", row_b),
        )

    def test_search_trends_accepts_synthetic_url_when_url_missing(self) -> None:
        settings = _settings(source_id="search_trends", source_category="trends")
        fresh_window_end = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
        row = _normalize_row(
            settings,
            {
                "keyword": "battery",
                "region": "KR",
                "window_end": fresh_window_end,
            },
        )
        validator = _validate_envelope(row, settings, datetime.now(timezone.utc))
        self.assertEqual("accepted", validator["ingest_status"])
        self.assertEqual("accepted", validator["quality_state"])
        self.assertTrue(row["url"].startswith("https://synthetic.signaldesk.local/search_trends/"))

    def test_shipper_retry_increments_only_on_retryable_failure(self) -> None:
        accepted = _shipper_outcome(
            _settings(
                shipper_mode="simulate-intake",
                simulated_intake_status="accepted",
                simulated_reason_code="accepted",
            )
        )
        retryable = _shipper_outcome(
            _settings(
                shipper_mode="simulate-intake",
                simulated_intake_status="retryable_failure",
                simulated_reason_code="storage_unavailable",
            )
        )

        self.assertFalse(accepted["increment_retry"])
        self.assertEqual("delivered", accepted["transport_status"])
        self.assertTrue(retryable["increment_retry"])
        self.assertEqual("offline_retry", retryable["transport_status"])
        self.assertEqual("pending", retryable["status"])

    def test_market_scope_normalization_alias(self) -> None:
        self.assertEqual("KRX", _normalize_market_scope("kospi", "KRX"))
        self.assertEqual("US", _normalize_market_scope("nasdaq", "KRX"))
        self.assertEqual("KRX", _normalize_market_scope("", "KRX"))

    def test_missing_evidence_fields_marks_metadata_incomplete(self) -> None:
        settings = _settings()
        row = _normalize_row(
            settings,
            {
                "external_id": "fixture-news-100",
                "published_at": "2026-03-08T01:00:00Z",
                "source_name": "SignalDesk Fixture Wire",
                "title": "No Evidence Fields",
                "url": "https://fixture.signaldesk.local/news/no-evidence-fields",
                "language": "en",
                "market_scope": "KRX",
            },
        )
        validated = _validate_envelope(row, settings, datetime.now(timezone.utc))
        evidence = _apply_evidence_quality(row, validated)
        self.assertEqual("metadata_incomplete", evidence["quality_state"])
        self.assertEqual("missing_evidence_fields", evidence["reason_code"])

    def test_malformed_outbound_links_marks_quarantined(self) -> None:
        settings = _settings()
        row = _normalize_row(
            settings,
            {
                "external_id": "fixture-news-101",
                "published_at": "2026-03-08T01:10:00Z",
                "source_name": "SignalDesk Fixture Wire",
                "title": "Malformed Links",
                "url": "https://fixture.signaldesk.local/news/malformed-links",
                "language": "en",
                "market_scope": "KRX",
                "summary_text": "Summary text long enough to avoid weak-evidence downgrade.",
                "outbound_links": ["not-a-url"],
            },
        )
        validated = _validate_envelope(row, settings, datetime.now(timezone.utc))
        evidence = _apply_evidence_quality(row, validated)
        self.assertEqual("quarantined", evidence["quality_state"])
        self.assertEqual("malformed_outbound_links", evidence["reason_code"])

    def test_weak_evidence_marks_accepted_degraded(self) -> None:
        settings = _settings()
        row = _normalize_row(
            settings,
            {
                "external_id": "fixture-news-102",
                "published_at": "2026-03-08T01:20:00Z",
                "source_name": "SignalDesk Fixture Wire",
                "title": "Weak Evidence",
                "url": "https://fixture.signaldesk.local/news/weak-evidence",
                "language": "en",
                "market_scope": "KRX",
                "summary_text": "Short text",
            },
        )
        validated = _validate_envelope(row, settings, datetime.now(timezone.utc))
        evidence = _apply_evidence_quality(row, validated)
        self.assertEqual("accepted_degraded", evidence["quality_state"])
        self.assertEqual("weak_evidence", evidence["reason_code"])


if __name__ == "__main__":
    unittest.main()
