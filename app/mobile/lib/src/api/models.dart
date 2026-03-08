enum Market { kr, us, all }

enum Period { intraday, daily, weekly }

enum Severity { low, medium, high, critical }

enum TargetType { keyword, stock }

enum WatchlistOperation { add, remove }

String _asString(Object value) => value.toString();

double? _asDoubleOrNull(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

int _asInt(Object value) {
  if (value is int) {
    return value;
  }
  return int.parse(value.toString());
}

bool? _asBoolOrNull(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is bool) {
    return value;
  }
  return value.toString().toLowerCase() == 'true';
}

List<String> _asStringList(Object? value) {
  if (value == null) {
    return const <String>[];
  }
  return (value as List<dynamic>).map((item) => item.toString()).toList();
}

Market marketFromString(String value) => Market.values.firstWhere(
      (item) => item.name == value,
      orElse: () => Market.all,
    );

Period periodFromString(String value) => Period.values.firstWhere(
      (item) => item.name == value,
      orElse: () => Period.daily,
    );

Severity severityFromString(String value) => Severity.values.firstWhere(
      (item) => item.name == value,
      orElse: () => Severity.medium,
    );

TargetType targetTypeFromString(String value) => TargetType.values.firstWhere(
      (item) => item.name == value,
      orElse: () => TargetType.keyword,
    );

WatchlistOperation watchlistOperationFromString(String value) =>
    WatchlistOperation.values.firstWhere(
      (item) => item.name == value,
      orElse: () => WatchlistOperation.add,
    );

class DashboardKeyword {
  DashboardKeyword({
    required this.keywordId,
    required this.keyword,
    required this.score,
    required this.delta1d,
    required this.confidence,
    required this.isAlertEligible,
    required this.reasonTags,
    required this.riskFlags,
  });

  factory DashboardKeyword.fromJson(Map<String, dynamic> json) => DashboardKeyword(
        keywordId: _asString(json['keyword_id'] ?? ''),
        keyword: _asString(json['keyword'] ?? ''),
        score: _asDoubleOrNull(json['score']) ?? 0,
        delta1d: _asDoubleOrNull(json['delta_1d']),
        confidence: _asDoubleOrNull(json['confidence']) ?? 0,
        isAlertEligible: _asBoolOrNull(json['is_alert_eligible']) ?? false,
        reasonTags: _asStringList(json['reason_tags']),
        riskFlags: _asStringList(json['risk_flags']),
      );

  final String keywordId;
  final String keyword;
  final double score;
  final double? delta1d;
  final double confidence;
  final bool isAlertEligible;
  final List<String> reasonTags;
  final List<String> riskFlags;
}

class DashboardSector {
  DashboardSector({
    required this.sector,
    required this.keywordCount,
    required this.avgScore,
    required this.delta1d,
  });

  factory DashboardSector.fromJson(Map<String, dynamic> json) => DashboardSector(
        sector: _asString(json['sector'] ?? ''),
        keywordCount: _asInt(json['keyword_count'] ?? 0),
        avgScore: _asDoubleOrNull(json['avg_score']) ?? 0,
        delta1d: _asDoubleOrNull(json['delta_1d']),
      );

  final String sector;
  final int keywordCount;
  final double avgScore;
  final double? delta1d;
}

class DashboardAlert {
  DashboardAlert({
    required this.alertId,
    required this.targetType,
    required this.targetId,
    required this.severity,
    required this.message,
    required this.triggeredAt,
  });

  factory DashboardAlert.fromJson(Map<String, dynamic> json) => DashboardAlert(
        alertId: _asString(json['alert_id'] ?? ''),
        targetType: targetTypeFromString(_asString(json['target_type'] ?? 'keyword')),
        targetId: _asString(json['target_id'] ?? ''),
        severity: severityFromString(_asString(json['severity'] ?? 'medium')),
        message: _asString(json['message'] ?? ''),
        triggeredAt: _asString(json['triggered_at'] ?? ''),
      );

  final String alertId;
  final TargetType targetType;
  final String targetId;
  final Severity severity;
  final String message;
  final String triggeredAt;
}

class DashboardResponse {
  DashboardResponse({
    required this.generatedAt,
    required this.topKeywords,
    required this.hotSectors,
    required this.riskAlerts,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) => DashboardResponse(
        generatedAt: _asString(json['generated_at'] ?? ''),
        topKeywords: (json['top_keywords'] as List<dynamic>? ?? const [])
            .map((item) => DashboardKeyword.fromJson(item as Map<String, dynamic>))
            .toList(),
        hotSectors: (json['hot_sectors'] as List<dynamic>? ?? const [])
            .map((item) => DashboardSector.fromJson(item as Map<String, dynamic>))
            .toList(),
        riskAlerts: (json['risk_alerts'] as List<dynamic>? ?? const [])
            .map((item) => DashboardAlert.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

  final String generatedAt;
  final List<DashboardKeyword> topKeywords;
  final List<DashboardSector> hotSectors;
  final List<DashboardAlert> riskAlerts;
}

class RankingItem {
  RankingItem({
    required this.keywordId,
    required this.keyword,
    required this.rankPosition,
    required this.score,
    required this.delta1d,
    required this.confidence,
    required this.isAlertEligible,
    required this.reasonTags,
    required this.riskFlags,
    required this.relatedSectors,
  });

  factory RankingItem.fromJson(Map<String, dynamic> json) => RankingItem(
        keywordId: _asString(json['keyword_id'] ?? ''),
        keyword: _asString(json['keyword'] ?? ''),
        rankPosition: _asInt(json['rank_position'] ?? 0),
        score: _asDoubleOrNull(json['score']) ?? 0,
        delta1d: _asDoubleOrNull(json['delta_1d']),
        confidence: _asDoubleOrNull(json['confidence']) ?? 0,
        isAlertEligible: _asBoolOrNull(json['is_alert_eligible']) ?? false,
        reasonTags: _asStringList(json['reason_tags']),
        riskFlags: _asStringList(json['risk_flags']),
        relatedSectors: _asStringList(json['related_sectors']),
      );

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
}

class KeywordRankingResponse {
  KeywordRankingResponse({
    required this.generatedAt,
    required this.items,
    required this.nextCursor,
  });

  factory KeywordRankingResponse.fromJson(Map<String, dynamic> json) =>
      KeywordRankingResponse(
        generatedAt: _asString(json['generated_at'] ?? ''),
        items: (json['items'] as List<dynamic>? ?? const [])
            .map((item) => RankingItem.fromJson(item as Map<String, dynamic>))
            .toList(),
        nextCursor: json['next_cursor']?.toString(),
      );

  final String generatedAt;
  final List<RankingItem> items;
  final String? nextCursor;
}

class ScoreSummary {
  ScoreSummary({
    required this.score,
    required this.delta1d,
    required this.confidence,
    required this.isAlertEligible,
    required this.dimensionMentions,
    required this.dimensionTrends,
    required this.dimensionMarket,
    required this.dimensionEvents,
    required this.dimensionPersistence,
  });

  factory ScoreSummary.fromJson(Map<String, dynamic> json) => ScoreSummary(
        score: _asDoubleOrNull(json['score']) ?? 0,
        delta1d: _asDoubleOrNull(json['delta_1d']),
        confidence: _asDoubleOrNull(json['confidence']) ?? 0,
        isAlertEligible: _asBoolOrNull(json['is_alert_eligible']) ?? false,
        dimensionMentions: _asDoubleOrNull(json['dimension_mentions']),
        dimensionTrends: _asDoubleOrNull(json['dimension_trends']),
        dimensionMarket: _asDoubleOrNull(json['dimension_market']),
        dimensionEvents: _asDoubleOrNull(json['dimension_events']),
        dimensionPersistence: _asDoubleOrNull(json['dimension_persistence']),
      );

  final double score;
  final double? delta1d;
  final double confidence;
  final bool isAlertEligible;
  final double? dimensionMentions;
  final double? dimensionTrends;
  final double? dimensionMarket;
  final double? dimensionEvents;
  final double? dimensionPersistence;
}

class TimeSeriesPoint {
  TimeSeriesPoint({
    required this.snapshotAt,
    required this.score,
    required this.confidence,
  });

  factory TimeSeriesPoint.fromJson(Map<String, dynamic> json) => TimeSeriesPoint(
        snapshotAt: _asString(json['snapshot_at'] ?? ''),
        score: _asDoubleOrNull(json['score']) ?? 0,
        confidence: _asDoubleOrNull(json['confidence']) ?? 0,
      );

  final String snapshotAt;
  final double score;
  final double confidence;
}

class RelatedNews {
  RelatedNews({
    required this.newsId,
    required this.sourceName,
    required this.publishedAt,
    required this.title,
    required this.url,
    required this.relevanceScore,
  });

  factory RelatedNews.fromJson(Map<String, dynamic> json) => RelatedNews(
        newsId: _asString(json['news_id'] ?? ''),
        sourceName: _asString(json['source_name'] ?? ''),
        publishedAt: _asString(json['published_at'] ?? ''),
        title: _asString(json['title'] ?? ''),
        url: _asString(json['url'] ?? ''),
        relevanceScore: _asDoubleOrNull(json['relevance_score']),
      );

  final String newsId;
  final String sourceName;
  final String publishedAt;
  final String title;
  final String url;
  final double? relevanceScore;
}

class RelatedStock {
  RelatedStock({
    required this.stockId,
    required this.ticker,
    required this.name,
    required this.market,
    required this.sector,
    required this.linkConfidence,
  });

  factory RelatedStock.fromJson(Map<String, dynamic> json) => RelatedStock(
        stockId: _asString(json['stock_id'] ?? ''),
        ticker: _asString(json['ticker'] ?? ''),
        name: _asString(json['name'] ?? ''),
        market: marketFromString(_asString(json['market'] ?? 'all')),
        sector: json['sector']?.toString(),
        linkConfidence: _asDoubleOrNull(json['link_confidence']),
      );

  final String stockId;
  final String ticker;
  final String name;
  final Market market;
  final String? sector;
  final double? linkConfidence;
}

class KeywordDetailResponse {
  KeywordDetailResponse({
    required this.generatedAt,
    required this.keywordId,
    required this.keyword,
    required this.scoreSummary,
    required this.reasonBlock,
    required this.timeseries,
    required this.relatedNews,
    required this.relatedStocks,
    required this.relatedSectors,
    required this.riskFlags,
  });

  factory KeywordDetailResponse.fromJson(Map<String, dynamic> json) =>
      KeywordDetailResponse(
        generatedAt: _asString(json['generated_at'] ?? ''),
        keywordId: _asString(json['keyword_id'] ?? ''),
        keyword: _asString(json['keyword'] ?? ''),
        scoreSummary: ScoreSummary.fromJson(
          (json['score_summary'] as Map<String, dynamic>? ?? const {}),
        ),
        reasonBlock: json['reason_block']?.toString(),
        timeseries: (json['timeseries'] as List<dynamic>? ?? const [])
            .map((item) => TimeSeriesPoint.fromJson(item as Map<String, dynamic>))
            .toList(),
        relatedNews: (json['related_news'] as List<dynamic>? ?? const [])
            .map((item) => RelatedNews.fromJson(item as Map<String, dynamic>))
            .toList(),
        relatedStocks: (json['related_stocks'] as List<dynamic>? ?? const [])
            .map((item) => RelatedStock.fromJson(item as Map<String, dynamic>))
            .toList(),
        relatedSectors: _asStringList(json['related_sectors']),
        riskFlags: _asStringList(json['risk_flags']),
      );

  final String generatedAt;
  final String keywordId;
  final String keyword;
  final ScoreSummary scoreSummary;
  final String? reasonBlock;
  final List<TimeSeriesPoint> timeseries;
  final List<RelatedNews> relatedNews;
  final List<RelatedStock> relatedStocks;
  final List<String> relatedSectors;
  final List<String> riskFlags;
}

class WatchlistKeyword {
  WatchlistKeyword({
    required this.watchlistItemId,
    required this.keywordId,
    required this.keyword,
    required this.score,
    required this.delta1d,
    required this.isAlertEligible,
    required this.riskFlags,
    required this.severity,
  });

  factory WatchlistKeyword.fromJson(Map<String, dynamic> json) => WatchlistKeyword(
        watchlistItemId: _asString(json['watchlist_item_id'] ?? ''),
        keywordId: _asString(json['keyword_id'] ?? ''),
        keyword: _asString(json['keyword'] ?? ''),
        score: _asDoubleOrNull(json['score']),
        delta1d: _asDoubleOrNull(json['delta_1d']),
        isAlertEligible: _asBoolOrNull(json['is_alert_eligible']),
        riskFlags: _asStringList(json['risk_flags']),
        severity: json['severity'] == null
            ? null
            : severityFromString(json['severity'].toString()),
      );

  final String watchlistItemId;
  final String keywordId;
  final String keyword;
  final double? score;
  final double? delta1d;
  final bool? isAlertEligible;
  final List<String> riskFlags;
  final Severity? severity;
}

class WatchlistStock {
  WatchlistStock({
    required this.watchlistItemId,
    required this.stockId,
    required this.ticker,
    required this.name,
    required this.market,
    required this.severity,
  });

  factory WatchlistStock.fromJson(Map<String, dynamic> json) => WatchlistStock(
        watchlistItemId: _asString(json['watchlist_item_id'] ?? ''),
        stockId: _asString(json['stock_id'] ?? ''),
        ticker: _asString(json['ticker'] ?? ''),
        name: _asString(json['name'] ?? ''),
        market: marketFromString(_asString(json['market'] ?? 'all')),
        severity: json['severity'] == null
            ? null
            : severityFromString(json['severity'].toString()),
      );

  final String watchlistItemId;
  final String stockId;
  final String ticker;
  final String name;
  final Market market;
  final Severity? severity;
}

class WatchlistResponse {
  WatchlistResponse({
    required this.generatedAt,
    required this.keywords,
    required this.stocks,
  });

  factory WatchlistResponse.fromJson(Map<String, dynamic> json) => WatchlistResponse(
        generatedAt: _asString(json['generated_at'] ?? ''),
        keywords: (json['keywords'] as List<dynamic>? ?? const [])
            .map((item) => WatchlistKeyword.fromJson(item as Map<String, dynamic>))
            .toList(),
        stocks: (json['stocks'] as List<dynamic>? ?? const [])
            .map((item) => WatchlistStock.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

  final String generatedAt;
  final List<WatchlistKeyword> keywords;
  final List<WatchlistStock> stocks;
}

class WatchlistMutationRequest {
  WatchlistMutationRequest({
    required this.op,
    required this.targetType,
    required this.targetId,
  });

  final WatchlistOperation op;
  final TargetType targetType;
  final String targetId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'op': op.name,
        'target_type': targetType.name,
        'target_id': targetId,
      };
}

class WatchlistMutationResponse {
  WatchlistMutationResponse({
    required this.ok,
    required this.watchlistItemId,
  });

  factory WatchlistMutationResponse.fromJson(Map<String, dynamic> json) =>
      WatchlistMutationResponse(
        ok: _asBoolOrNull(json['ok']) ?? false,
        watchlistItemId: json['watchlist_item_id']?.toString(),
      );

  final bool ok;
  final String? watchlistItemId;
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
    required this.keywordId,
  });

  factory AlertItem.fromJson(Map<String, dynamic> json) => AlertItem(
        alertId: _asString(json['alert_id'] ?? ''),
        targetType: targetTypeFromString(_asString(json['target_type'] ?? 'keyword')),
        targetId: _asString(json['target_id'] ?? ''),
        targetLabel: _asString(json['target_label'] ?? ''),
        severity: severityFromString(_asString(json['severity'] ?? 'medium')),
        message: _asString(json['message'] ?? ''),
        triggeredAt: _asString(json['triggered_at'] ?? ''),
        keywordId: json['keyword_id']?.toString(),
      );

  final String alertId;
  final TargetType targetType;
  final String targetId;
  final String targetLabel;
  final Severity severity;
  final String message;
  final String triggeredAt;
  final String? keywordId;
}

class AlertsResponse {
  AlertsResponse({
    required this.generatedAt,
    required this.items,
    required this.nextCursor,
  });

  factory AlertsResponse.fromJson(Map<String, dynamic> json) => AlertsResponse(
        generatedAt: _asString(json['generated_at'] ?? ''),
        items: (json['items'] as List<dynamic>? ?? const [])
            .map((item) => AlertItem.fromJson(item as Map<String, dynamic>))
            .toList(),
        nextCursor: json['next_cursor']?.toString(),
      );

  final String generatedAt;
  final List<AlertItem> items;
  final String? nextCursor;
}
