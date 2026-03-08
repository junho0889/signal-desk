import 'models.dart';
import 'signal_desk_api.dart';

class MockSignalDeskApi implements SignalDeskApi {
  @override
  Future<DashboardResponse> getDashboard() async => DashboardResponse(
        generatedAt: '2026-03-08T09:00:00Z',
        topKeywords: <DashboardKeyword>[
          DashboardKeyword(
            keywordId: 'kw-ai-chip',
            keyword: 'AI Chip Export',
            score: 87.2,
            delta1d: 4.1,
            confidence: 0.82,
            isAlertEligible: true,
            reasonTags: const <String>['mentions_accelerating', 'disclosure_backed'],
            riskFlags: const <String>['mapping_unstable'],
          ),
        ],
        hotSectors: <DashboardSector>[
          DashboardSector(
            sector: 'Semiconductor',
            keywordCount: 7,
            avgScore: 74.6,
            delta1d: 3.2,
          ),
        ],
        riskAlerts: <DashboardAlert>[
          DashboardAlert(
            alertId: 'al-1',
            targetType: TargetType.keyword,
            targetId: 'kw-ai-chip',
            severity: Severity.high,
            message: 'Keyword score jump detected',
            triggeredAt: '2026-03-08T08:57:10Z',
          ),
        ],
      );

  @override
  Future<AlertsResponse> getAlerts({Severity? severity, int? limit, String? cursor}) async =>
      AlertsResponse(
        generatedAt: '2026-03-08T09:00:00Z',
        items: <AlertItem>[
          AlertItem(
            alertId: 'al-1',
            targetType: TargetType.keyword,
            targetId: 'kw-ai-chip',
            targetLabel: 'AI Chip Export',
            severity: Severity.high,
            message: 'Keyword score jump detected',
            triggeredAt: '2026-03-08T08:57:10Z',
            keywordId: 'kw-ai-chip',
          ),
        ],
        nextCursor: null,
      );

  @override
  Future<KeywordDetailResponse> getKeywordDetail(
    String keywordId, {
    Period period = Period.daily,
    int? points,
  }) async =>
      KeywordDetailResponse(
        generatedAt: '2026-03-08T09:00:00Z',
        keywordId: keywordId,
        keyword: 'AI Chip Export',
        scoreSummary: ScoreSummary(
          score: 87.2,
          delta1d: 4.1,
          confidence: 0.82,
          isAlertEligible: true,
          dimensionMentions: 20,
          dimensionTrends: 17,
          dimensionMarket: 19,
          dimensionEvents: 16,
          dimensionPersistence: 15,
        ),
        reasonBlock: 'Mentions and filing evidence accelerated across 24h.',
        timeseries: <TimeSeriesPoint>[
          TimeSeriesPoint(snapshotAt: '2026-03-08T08:00:00Z', score: 80, confidence: 0.79),
          TimeSeriesPoint(snapshotAt: '2026-03-08T09:00:00Z', score: 87.2, confidence: 0.82),
        ],
        relatedNews: <RelatedNews>[
          RelatedNews(
            newsId: 'news-1',
            sourceName: 'MarketWire',
            publishedAt: '2026-03-08T07:50:00Z',
            title: 'Chip export narrative continues to expand',
            url: 'https://example.com/news-1',
            relevanceScore: 0.77,
          ),
        ],
        relatedStocks: <RelatedStock>[
          RelatedStock(
            stockId: 'stk-nvda',
            ticker: 'NVDA',
            name: 'NVIDIA Corp.',
            market: Market.us,
            sector: 'Semiconductor',
            linkConfidence: 0.75,
          ),
        ],
        relatedSectors: const <String>['Semiconductor', 'Hardware'],
        riskFlags: const <String>['mapping_unstable'],
      );

  @override
  Future<KeywordRankingResponse> getKeywords({
    required Period period,
    Market market = Market.all,
    String? sector,
    int? limit,
    String? cursor,
  }) async =>
      KeywordRankingResponse(
        generatedAt: '2026-03-08T09:00:00Z',
        items: <RankingItem>[
          RankingItem(
            keywordId: 'kw-ai-chip',
            keyword: 'AI Chip Export',
            rankPosition: 1,
            score: 87.2,
            delta1d: 4.1,
            confidence: 0.82,
            isAlertEligible: true,
            reasonTags: const <String>['mentions_accelerating'],
            riskFlags: const <String>['mapping_unstable'],
            relatedSectors: const <String>['Semiconductor'],
          ),
        ],
        nextCursor: null,
      );

  @override
  Future<WatchlistResponse> getWatchlist() async => WatchlistResponse(
        generatedAt: '2026-03-08T09:00:00Z',
        keywords: <WatchlistKeyword>[
          WatchlistKeyword(
            watchlistItemId: 'wl-kw-1',
            keywordId: 'kw-ai-chip',
            keyword: 'AI Chip Export',
            score: 87.2,
            delta1d: 4.1,
            isAlertEligible: true,
            riskFlags: const <String>['mapping_unstable'],
            severity: Severity.high,
          ),
        ],
        stocks: <WatchlistStock>[
          WatchlistStock(
            watchlistItemId: 'wl-stk-1',
            stockId: 'stk-nvda',
            ticker: 'NVDA',
            name: 'NVIDIA Corp.',
            market: Market.us,
            severity: Severity.medium,
          ),
        ],
      );

  @override
  Future<WatchlistMutationResponse> postWatchlist(WatchlistMutationRequest request) async =>
      WatchlistMutationResponse(ok: true, watchlistItemId: 'wl-created-1');
}
