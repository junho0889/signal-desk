class MockPayloads {
  static Map<String, dynamic> dashboard() => {
        'generated_at': DateTime.now().toUtc().toIso8601String(),
        'top_keywords': [
          {
            'keyword_id': 'kw_ai',
            'keyword': 'AI Infrastructure',
            'score': 82.4,
            'delta_1d': 5.2,
            'confidence': 0.81,
            'is_alert_eligible': true,
            'reason_tags': ['mentions_accelerating', 'search_confirmation'],
            'risk_flags': [],
          },
          {
            'keyword_id': 'kw_battery',
            'keyword': 'Battery Supply Chain',
            'score': 73.6,
            'delta_1d': -1.4,
            'confidence': 0.67,
            'is_alert_eligible': false,
            'reason_tags': ['persistent_multi_window'],
            'risk_flags': ['event_coverage_partial'],
          },
        ],
        'hot_sectors': [
          {
            'sector': 'Semiconductors',
            'keyword_count': 5,
            'avg_score': 78.2,
            'delta_1d': 2.7,
          },
          {
            'sector': 'Energy Storage',
            'keyword_count': 4,
            'avg_score': 71.9,
            'delta_1d': null,
          },
        ],
        'risk_alerts': [
          {
            'alert_id': 'al_001',
            'target_type': 'keyword',
            'target_id': 'kw_ai',
            'severity': 'high',
            'message': 'AI Infrastructure moved +5.2 in 24h',
            'triggered_at': DateTime.now().toUtc().toIso8601String(),
          },
        ],
      };

  static Map<String, dynamic> keywords() => {
        'generated_at': DateTime.now().toUtc().toIso8601String(),
        'next_cursor': null,
        'items': [
          {
            'keyword_id': 'kw_ai',
            'keyword': 'AI Infrastructure',
            'rank_position': 1,
            'score': 82.4,
            'delta_1d': 5.2,
            'confidence': 0.81,
            'is_alert_eligible': true,
            'reason_tags': ['mentions_accelerating', 'price_volume_confirmation'],
            'risk_flags': [],
            'related_sectors': ['Semiconductors', 'Cloud'],
          },
          {
            'keyword_id': 'kw_battery',
            'keyword': 'Battery Supply Chain',
            'rank_position': 2,
            'score': 73.6,
            'delta_1d': null,
            'confidence': 0.67,
            'is_alert_eligible': false,
            'reason_tags': ['persistent_multi_window'],
            'risk_flags': ['event_coverage_partial'],
            'related_sectors': ['Energy Storage'],
          },
        ],
      };

  static Map<String, dynamic> keywordDetail(String keywordId) => {
        'generated_at': DateTime.now().toUtc().toIso8601String(),
        'keyword_id': keywordId,
        'keyword': keywordId == 'kw_ai' ? 'AI Infrastructure' : 'Battery Supply Chain',
        'score_summary': {
          'score': 82.4,
          'delta_1d': 5.2,
          'confidence': 0.81,
          'is_alert_eligible': true,
          'dimension_mentions': 88.0,
          'dimension_trends': 79.0,
          'dimension_market': 76.0,
          'dimension_events': 65.0,
          'dimension_persistence': 71.0,
        },
        'reason_block': 'Mentions and market confirmation increased together in the last cycle.',
        'timeseries': [
          {
            'snapshot_at': DateTime.now().toUtc().subtract(const Duration(hours: 1)).toIso8601String(),
            'score': 79.2,
            'confidence': 0.78,
          },
          {
            'snapshot_at': DateTime.now().toUtc().toIso8601String(),
            'score': 82.4,
            'confidence': 0.81,
          },
        ],
        'related_news': [
          {
            'news_id': 'nw_001',
            'source_name': 'MarketWire',
            'published_at': DateTime.now().toUtc().toIso8601String(),
            'title': 'AI infra demand shows renewed momentum',
            'url': 'https://example.com/news/ai',
            'relevance_score': 0.84,
          },
        ],
        'related_stocks': [
          {
            'stock_id': 'st_001',
            'ticker': 'NVDA',
            'name': 'NVIDIA',
            'market': 'us',
            'sector': 'Semiconductors',
            'link_confidence': 0.93,
          },
        ],
        'related_sectors': ['Semiconductors', 'Cloud'],
        'risk_flags': [],
      };

  static Map<String, dynamic> watchlist() => {
        'generated_at': DateTime.now().toUtc().toIso8601String(),
        'keywords': [
          {
            'watchlist_item_id': 'wl_kw_001',
            'keyword_id': 'kw_ai',
            'keyword': 'AI Infrastructure',
            'score': 82.4,
            'delta_1d': 5.2,
            'is_alert_eligible': true,
            'risk_flags': [],
            'severity': 'high',
          },
        ],
        'stocks': [
          {
            'watchlist_item_id': 'wl_st_001',
            'stock_id': 'st_001',
            'ticker': 'NVDA',
            'name': 'NVIDIA',
            'market': 'us',
            'severity': 'medium',
          },
        ],
      };

  static Map<String, dynamic> alerts() => {
        'generated_at': DateTime.now().toUtc().toIso8601String(),
        'next_cursor': null,
        'items': [
          {
            'alert_id': 'al_001',
            'target_type': 'keyword',
            'target_id': 'kw_ai',
            'target_label': 'AI Infrastructure',
            'severity': 'high',
            'message': 'Score delta crossed threshold',
            'triggered_at': DateTime.now().toUtc().toIso8601String(),
            'keyword_id': 'kw_ai',
          },
        ],
      };
}
