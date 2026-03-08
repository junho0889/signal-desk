import 'models.dart';

abstract class SignalDeskApi {
  Future<DashboardResponse> getDashboard();

  Future<KeywordRankingResponse> getKeywords({
    required Period period,
    Market market = Market.all,
    String? sector,
    int? limit,
    String? cursor,
  });

  Future<KeywordDetailResponse> getKeywordDetail(
    String keywordId, {
    Period period = Period.daily,
    int? points,
  });

  Future<WatchlistResponse> getWatchlist();

  Future<WatchlistMutationResponse> postWatchlist(WatchlistMutationRequest request);

  Future<AlertsResponse> getAlerts({
    Severity? severity,
    int? limit,
    String? cursor,
  });
}
