DateTime _parseDate(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.parse(value).toUtc();
  }
  return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

String _parseString(dynamic value, {String fallback = ''}) {
  return value is String ? value : fallback;
}

int _parseInt(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return fallback;
}

double _parseDouble(dynamic value, {double fallback = 0.0}) {
  if (value is num) {
    return value.toDouble();
  }
  return fallback;
}

bool _parseBool(dynamic value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }
  return fallback;
}

List<String> _parseStringList(dynamic value) {
  if (value is List) {
    return value.whereType<String>().toList(growable: false);
  }
  return const <String>[];
}

class DashboardResponse {
  DashboardResponse({
    required this.generatedAt,
    required this.topKeywords,
    required this.hotSectors,
    required this.riskAlerts,
  });

  final DateTime generatedAt;
  final List<KeywordCard> topKeywords;
  final List<SectorMover> hotSectors;
  final List<RiskAlert> riskAlerts;

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    return DashboardResponse(
      generatedAt: _parseDate(json['generated_at']),
      topKeywords: (json['top_keywords'] as List? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(KeywordCard.fromJson)
          .toList(growable: false),
      hotSectors: (json['hot_sectors'] as List? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(SectorMover.fromJson)
          .toList(growable: false),
      riskAlerts: (json['risk_alerts'] as List? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(RiskAlert.fromJson)
          .toList(growable: false),
    );
  }
}

class KeywordCard {
  KeywordCard({
    required this.keywordId,
    required this.keyword,
    required this.score,
    this.delta1d,
    required this.confidence,
    required this.isAlertEligible,
    required this.reasonTags,
    required this.riskFlags,
  });

  final String keywordId;
  final String keyword;
  final double score;
  final double? delta1d;
  final double confidence;
  final bool isAlertEligible;
  final List<String> reasonTags;
  final List<String> riskFlags;

  factory KeywordCard.fromJson(Map<String, dynamic> json) {
    final delta = json['delta_1d'];
    return KeywordCard(
      keywordId: _parseString(json['keyword_id']),
      keyword: _parseString(json['keyword']),
      score: _parseDouble(json['score']),
      delta1d: delta is num ? delta.toDouble() : null,
      confidence: _parseDouble(json['confidence']),
      isAlertEligible: _parseBool(json['is_alert_eligible']),
      reasonTags: _parseStringList(json['reason_tags']),
      riskFlags: _parseStringList(json['risk_flags']),
    );
  }
}

class SectorMover {
  SectorMover({
    required this.sector,
    required this.keywordCount,
    required this.avgScore,
    this.delta1d,
  });

  final String sector;
  final int keywordCount;
  final double avgScore;
  final double? delta1d;

  factory SectorMover.fromJson(Map<String, dynamic> json) {
    final delta = json['delta_1d'];
    return SectorMover(
      sector: _parseString(json['sector']),
      keywordCount: _parseInt(json['keyword_count']),
      avgScore: _parseDouble(json['avg_score']),
      delta1d: delta is num ? delta.toDouble() : null,
    );
  }
}

class RiskAlert {
  RiskAlert({
    required this.alertId,
    required this.targetType,
    required this.targetId,
    required this.severity,
    required this.message,
    required this.triggeredAt,
  });

  final String alertId;
  final String targetType;
  final String targetId;
  final String severity;
  final String message;
  final DateTime triggeredAt;

  factory RiskAlert.fromJson(Map<String, dynamic> json) {
    return RiskAlert(
      alertId: _parseString(json['alert_id']),
      targetType: _parseString(json['target_type']),
      targetId: _parseString(json['target_id']),
      severity: _parseString(json['severity']),
      message: _parseString(json['message']),
      triggeredAt: _parseDate(json['triggered_at']),
    );
  }
}

class KeywordsResponse {
  KeywordsResponse({
    required this.generatedAt,
    required this.items,
    this.nextCursor,
  });

  final DateTime generatedAt;
  final List<KeywordListItem> items;
  final String? nextCursor;

  factory KeywordsResponse.fromJson(Map<String, dynamic> json) {
    final cursor = json['next_cursor'];
    return KeywordsResponse(
      generatedAt: _parseDate(json['generated_at']),
      items: (json['items'] as List? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(KeywordListItem.fromJson)
          .toList(growable: false),
      nextCursor: cursor is String ? cursor : null,
    );
  }
}

class KeywordListItem {
  KeywordListItem({
    required this.keywordId,
    required this.keyword,
    required this.rankPosition,
    required this.score,
    this.delta1d,
    required this.confidence,
    required this.isAlertEligible,
    required this.reasonTags,
    required this.riskFlags,
    required this.relatedSectors,
  });

  final String keywordId;
  final String keyword;
  final int rankPosition;
  final double score;
  final double? delta1d;
  final double confidence;
  final bool isAlertEligible;
  final List<String> reasonTags;
  final List<String> riskFlags;
  final List<String> relatedSectors;

  factory KeywordListItem.fromJson(Map<String, dynamic> json) {
    final delta = json['delta_1d'];
    return KeywordListItem(
      keywordId: _parseString(json['keyword_id']),
      keyword: _parseString(json['keyword']),
      rankPosition: _parseInt(json['rank_position']),
      score: _parseDouble(json['score']),
      delta1d: delta is num ? delta.toDouble() : null,
      confidence: _parseDouble(json['confidence']),
      isAlertEligible: _parseBool(json['is_alert_eligible']),
      reasonTags: _parseStringList(json['reason_tags']),
      riskFlags: _parseStringList(json['risk_flags']),
      relatedSectors: _parseStringList(json['related_sectors']),
    );
  }
}

class KeywordDetailResponse {
  KeywordDetailResponse({
    required this.generatedAt,
    required this.keywordId,
    required this.keyword,
    required this.scoreSummary,
    this.reasonBlock,
    required this.timeseries,
    required this.relatedNews,
    required this.relatedStocks,
    required this.relatedSectors,
    required this.riskFlags,
  });

  final DateTime generatedAt;
  final String keywordId;
  final String keyword;
  final ScoreSummary scoreSummary;
  final String? reasonBlock;
  final List<ScorePoint> timeseries;
  final List<RelatedNewsItem> relatedNews;
  final List<RelatedStockItem> relatedStocks;
  final List<String> relatedSectors;
  final List<String> riskFlags;

  factory KeywordDetailResponse.fromJson(Map<String, dynamic> json) {
    final reasonBlock = json['reason_block'];
    return KeywordDetailResponse(
      generatedAt: _parseDate(json['generated_at']),
      keywordId: _parseString(json['keyword_id']),
      keyword: _parseString(json['keyword']),
      scoreSummary: ScoreSummary.fromJson(
        (json['score_summary'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      reasonBlock: reasonBlock is String ? reasonBlock : null,
      timeseries: (json['timeseries'] as List? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(ScorePoint.fromJson)
          .toList(growable: false),
      relatedNews: (json['related_news'] as List? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(RelatedNewsItem.fromJson)
          .toList(growable: false),
      relatedStocks: (json['related_stocks'] as List? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(RelatedStockItem.fromJson)
          .toList(growable: false),
      relatedSectors: _parseStringList(json['related_sectors']),
      riskFlags: _parseStringList(json['risk_flags']),
    );
  }
}

class ScoreSummary {
  ScoreSummary({
    required this.score,
    this.delta1d,
    required this.confidence,
    required this.isAlertEligible,
    this.dimensionMentions,
    this.dimensionTrends,
    this.dimensionMarket,
    this.dimensionEvents,
    this.dimensionPersistence,
  });

  final double score;
  final double? delta1d;
  final double confidence;
  final bool isAlertEligible;
  final double? dimensionMentions;
  final double? dimensionTrends;
  final double? dimensionMarket;
  final double? dimensionEvents;
  final double? dimensionPersistence;

  factory ScoreSummary.fromJson(Map<String, dynamic> json) {
    double? nullableDouble(String key) {
      final value = json[key];
      return value is num ? value.toDouble() : null;
    }

    return ScoreSummary(
      score: _parseDouble(json['score']),
      delta1d: nullableDouble('delta_1d'),
      confidence: _parseDouble(json['confidence']),
      isAlertEligible: _parseBool(json['is_alert_eligible']),
      dimensionMentions: nullableDouble('dimension_mentions'),
      dimensionTrends: nullableDouble('dimension_trends'),
      dimensionMarket: nullableDouble('dimension_market'),
      dimensionEvents: nullableDouble('dimension_events'),
      dimensionPersistence: nullableDouble('dimension_persistence'),
    );
  }
}

class ScorePoint {
  ScorePoint({
    required this.snapshotAt,
    required this.score,
    required this.confidence,
  });

  final DateTime snapshotAt;
  final double score;
  final double confidence;

  factory ScorePoint.fromJson(Map<String, dynamic> json) {
    return ScorePoint(
      snapshotAt: _parseDate(json['snapshot_at']),
      score: _parseDouble(json['score']),
      confidence: _parseDouble(json['confidence']),
    );
  }
}

class RelatedNewsItem {
  RelatedNewsItem({
    required this.newsId,
    required this.sourceName,
    required this.publishedAt,
    required this.title,
    required this.url,
    this.relevanceScore,
  });

  final String newsId;
  final String sourceName;
  final DateTime publishedAt;
  final String title;
  final String url;
  final double? relevanceScore;

  factory RelatedNewsItem.fromJson(Map<String, dynamic> json) {
    final relevance = json['relevance_score'];
    return RelatedNewsItem(
      newsId: _parseString(json['news_id']),
      sourceName: _parseString(json['source_name']),
      publishedAt: _parseDate(json['published_at']),
      title: _parseString(json['title']),
      url: _parseString(json['url']),
      relevanceScore: relevance is num ? relevance.toDouble() : null,
    );
  }
}

class RelatedStockItem {
  RelatedStockItem({
    required this.stockId,
    required this.ticker,
    required this.name,
    required this.market,
    this.sector,
    this.linkConfidence,
  });

  final String stockId;
  final String ticker;
  final String name;
  final String market;
  final String? sector;
  final double? linkConfidence;

  factory RelatedStockItem.fromJson(Map<String, dynamic> json) {
    final sector = json['sector'];
    final confidence = json['link_confidence'];
    return RelatedStockItem(
      stockId: _parseString(json['stock_id']),
      ticker: _parseString(json['ticker']),
      name: _parseString(json['name']),
      market: _parseString(json['market']),
      sector: sector is String ? sector : null,
      linkConfidence: confidence is num ? confidence.toDouble() : null,
    );
  }
}

class WatchlistResponse {
  WatchlistResponse({
    required this.generatedAt,
    required this.keywords,
    required this.stocks,
  });

  final DateTime generatedAt;
  final List<WatchKeywordItem> keywords;
  final List<WatchStockItem> stocks;

  factory WatchlistResponse.fromJson(Map<String, dynamic> json) {
    return WatchlistResponse(
      generatedAt: _parseDate(json['generated_at']),
      keywords: (json['keywords'] as List? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(WatchKeywordItem.fromJson)
          .toList(growable: false),
      stocks: (json['stocks'] as List? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(WatchStockItem.fromJson)
          .toList(growable: false),
    );
  }
}

class WatchKeywordItem {
  WatchKeywordItem({
    required this.watchlistItemId,
    required this.keywordId,
    required this.keyword,
    this.score,
    this.delta1d,
    this.isAlertEligible,
    required this.riskFlags,
    this.severity,
  });

  final String watchlistItemId;
  final String keywordId;
  final String keyword;
  final double? score;
  final double? delta1d;
  final bool? isAlertEligible;
  final List<String> riskFlags;
  final String? severity;

  factory WatchKeywordItem.fromJson(Map<String, dynamic> json) {
    final score = json['score'];
    final delta = json['delta_1d'];
    final eligible = json['is_alert_eligible'];
    final severity = json['severity'];
    return WatchKeywordItem(
      watchlistItemId: _parseString(json['watchlist_item_id']),
      keywordId: _parseString(json['keyword_id']),
      keyword: _parseString(json['keyword']),
      score: score is num ? score.toDouble() : null,
      delta1d: delta is num ? delta.toDouble() : null,
      isAlertEligible: eligible is bool ? eligible : null,
      riskFlags: _parseStringList(json['risk_flags']),
      severity: severity is String ? severity : null,
    );
  }
}

class WatchStockItem {
  WatchStockItem({
    required this.watchlistItemId,
    required this.stockId,
    required this.ticker,
    required this.name,
    required this.market,
    this.severity,
  });

  final String watchlistItemId;
  final String stockId;
  final String ticker;
  final String name;
  final String market;
  final String? severity;

  factory WatchStockItem.fromJson(Map<String, dynamic> json) {
    final severity = json['severity'];
    return WatchStockItem(
      watchlistItemId: _parseString(json['watchlist_item_id']),
      stockId: _parseString(json['stock_id']),
      ticker: _parseString(json['ticker']),
      name: _parseString(json['name']),
      market: _parseString(json['market']),
      severity: severity is String ? severity : null,
    );
  }
}

class AlertsResponse {
  AlertsResponse({
    required this.generatedAt,
    required this.items,
    this.nextCursor,
  });

  final DateTime generatedAt;
  final List<AlertItem> items;
  final String? nextCursor;

  factory AlertsResponse.fromJson(Map<String, dynamic> json) {
    final cursor = json['next_cursor'];
    return AlertsResponse(
      generatedAt: _parseDate(json['generated_at']),
      items: (json['items'] as List? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(AlertItem.fromJson)
          .toList(growable: false),
      nextCursor: cursor is String ? cursor : null,
    );
  }
}

class AlertItem {
  AlertItem({
    required this.alertId,
    required this.targetType,
    required this.targetId,
    required this.targetLabel,
    required this.severity,
    required this.message,
    required this.triggeredAt,
    this.keywordId,
  });

  final String alertId;
  final String targetType;
  final String targetId;
  final String targetLabel;
  final String severity;
  final String message;
  final DateTime triggeredAt;
  final String? keywordId;

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    final keyword = json['keyword_id'];
    return AlertItem(
      alertId: _parseString(json['alert_id']),
      targetType: _parseString(json['target_type']),
      targetId: _parseString(json['target_id']),
      targetLabel: _parseString(json['target_label']),
      severity: _parseString(json['severity']),
      message: _parseString(json['message']),
      triggeredAt: _parseDate(json['triggered_at']),
      keywordId: keyword is String ? keyword : null,
    );
  }
}
