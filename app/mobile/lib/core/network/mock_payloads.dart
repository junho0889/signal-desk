class MockPayloads {
  static String _isoNow() => DateTime.now().toUtc().toIso8601String();

  static String _isoWithOffset(Duration offset) {
    return DateTime.now().toUtc().subtract(offset).toIso8601String();
  }

  static Map<String, dynamic> dashboard() => {
        'generated_at': _isoWithOffset(const Duration(minutes: 30)),
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
            'triggered_at': _isoNow(),
          },
        ],
      };

  static Map<String, dynamic> keywords({
    String period = 'daily',
    String market = 'all',
    String? sector,
    int limit = 20,
    String? cursor,
  }) {
    final allItems = <Map<String, dynamic>>[
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
      {
        'keyword_id': 'kw_robotics',
        'keyword': 'Industrial Robotics',
        'rank_position': 3,
        'score': 69.1,
        'delta_1d': 1.3,
        'confidence': 0.71,
        'is_alert_eligible': true,
        'reason_tags': ['search_confirmation'],
        'risk_flags': [],
        'related_sectors': ['Automation', 'Manufacturing'],
      },
      {
        'keyword_id': 'kw_hydrogen',
        'keyword': 'Hydrogen Mobility',
        'rank_position': 4,
        'score': 64.2,
        'delta_1d': -0.8,
        'confidence': 0.59,
        'is_alert_eligible': false,
        'reason_tags': ['weak_market_confirmation'],
        'risk_flags': ['mapping_unstable'],
        'related_sectors': ['Energy Transition'],
      },
      {
        'keyword_id': 'kw_cyber',
        'keyword': 'Cybersecurity',
        'rank_position': 5,
        'score': 62.8,
        'delta_1d': 0.7,
        'confidence': 0.76,
        'is_alert_eligible': true,
        'reason_tags': ['persistent_multi_window'],
        'risk_flags': [],
        'related_sectors': ['Software'],
      },
      {
        'keyword_id': 'kw_biotech',
        'keyword': 'Biotech Platform',
        'rank_position': 6,
        'score': 59.4,
        'delta_1d': -1.2,
        'confidence': 0.58,
        'is_alert_eligible': false,
        'reason_tags': ['stale_input_risk'],
        'risk_flags': ['data_freshness_degraded'],
        'related_sectors': ['Healthcare'],
      },
    ];

    final normalizedSector = sector?.trim().toLowerCase();
    final filteredItems = normalizedSector == null || normalizedSector.isEmpty
        ? allItems
        : allItems.where((item) {
            final sectors = (item['related_sectors'] as List<dynamic>)
                .whereType<String>()
                .map((value) => value.toLowerCase());
            return sectors.contains(normalizedSector);
          }).toList(growable: false);

    final normalizedMarket = market.toLowerCase();
    final marketItems = normalizedMarket == 'all'
        ? filteredItems
        : filteredItems.where((item) {
            final keywordId = item['keyword_id'] as String?;
            if (normalizedMarket == 'us') {
              return keywordId == 'kw_ai' ||
                  keywordId == 'kw_robotics' ||
                  keywordId == 'kw_cyber' ||
                  keywordId == 'kw_biotech';
            }
            if (normalizedMarket == 'kr') {
              return keywordId == 'kw_battery' || keywordId == 'kw_hydrogen';
            }
            return true;
          }).toList(growable: false);

    final requestedLimit = limit <= 0 ? 20 : limit;
    final pageSize = requestedLimit < 3 ? requestedLimit : 3;
    final start = cursor == 'kw_page_2' ? pageSize : 0;
    final end = (start + pageSize) > marketItems.length
        ? marketItems.length
        : start + pageSize;
    final pageItems = marketItems.sublist(start, end);
    final nextCursor = end < marketItems.length ? 'kw_page_2' : null;

    return {
      'generated_at': period == 'intraday'
          ? _isoWithOffset(const Duration(hours: 2))
          : _isoWithOffset(const Duration(minutes: 45)),
      'next_cursor': nextCursor,
      'items': pageItems,
    };
  }

  static Map<String, dynamic> keywordDetail(String keywordId) => {
        'generated_at': _isoWithOffset(const Duration(minutes: 75)),
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
            'snapshot_at': _isoWithOffset(const Duration(hours: 1)),
            'score': 79.2,
            'confidence': 0.78,
          },
          {
            'snapshot_at': _isoNow(),
            'score': 82.4,
            'confidence': 0.81,
          },
        ],
        'related_news': [
          {
            'news_id': 'nw_001',
            'source_name': 'MarketWire',
            'published_at': _isoNow(),
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
        'generated_at': _isoWithOffset(const Duration(hours: 7)),
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

  static Map<String, dynamic> alerts({
    String? cursor,
    String? severity,
    int limit = 20,
  }) {
    final allItems = <Map<String, dynamic>>[
      {
        'alert_id': 'al_001',
        'target_type': 'keyword',
        'target_id': 'kw_ai',
        'target_label': 'AI Infrastructure',
        'severity': 'high',
        'message': 'Score delta crossed threshold',
        'triggered_at': _isoNow(),
        'keyword_id': 'kw_ai',
      },
      {
        'alert_id': 'al_002',
        'target_type': 'keyword',
        'target_id': 'kw_battery',
        'target_label': 'Battery Supply Chain',
        'severity': 'medium',
        'message': 'Confidence dropped below watch threshold',
        'triggered_at': _isoWithOffset(const Duration(minutes: 50)),
        'keyword_id': 'kw_battery',
      },
      {
        'alert_id': 'al_003',
        'target_type': 'stock',
        'target_id': 'st_001',
        'target_label': 'NVIDIA',
        'severity': 'critical',
        'message': 'Related keyword volatility breached guardrail',
        'triggered_at': _isoWithOffset(const Duration(hours: 1, minutes: 30)),
        'keyword_id': 'kw_ai',
      },
      {
        'alert_id': 'al_004',
        'target_type': 'stock',
        'target_id': 'st_002',
        'target_label': 'LG Energy Solution',
        'severity': 'low',
        'message': 'Event-coverage warning resolved after latest pull',
        'triggered_at': _isoWithOffset(const Duration(hours: 2)),
        'keyword_id': null,
      },
    ];

    final normalizedSeverity = severity?.trim().toLowerCase();
    final filtered = normalizedSeverity == null || normalizedSeverity.isEmpty
        ? allItems
        : allItems
            .where((item) => item['severity'] == normalizedSeverity)
            .toList(growable: false);

    final requestedLimit = limit <= 0 ? 20 : limit;
    final pageSize = requestedLimit < 2 ? requestedLimit : 2;
    final start = cursor == 'al_page_2' ? pageSize : 0;
    final end = (start + pageSize) > filtered.length ? filtered.length : start + pageSize;
    final pageItems = filtered.sublist(start, end);
    final nextCursor = end < filtered.length ? 'al_page_2' : null;

    return {
      'generated_at': _isoWithOffset(const Duration(hours: 2, minutes: 15)),
      'next_cursor': nextCursor,
      'items': pageItems,
    };
  }
}
