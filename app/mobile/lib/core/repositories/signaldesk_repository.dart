import '../models/api_models.dart';
import '../network/signaldesk_api_client.dart';

class SignalDeskRepository {
  SignalDeskRepository({required SignalDeskApiClient apiClient}) : _apiClient = apiClient;

  final SignalDeskApiClient _apiClient;

  Future<DashboardResponse> fetchDashboard() {
    return _apiClient.getDashboard();
  }

  Future<KeywordsResponse> fetchKeywords({
    required String period,
    String market = 'all',
    String? sector,
    int limit = 20,
    String? cursor,
  }) {
    return _apiClient.getKeywords(
      period: period,
      market: market,
      sector: sector,
      limit: limit,
      cursor: cursor,
    );
  }

  Future<KeywordDetailResponse> fetchKeywordDetail(
    String keywordId, {
    String period = 'daily',
    int points = 24,
  }) {
    return _apiClient.getKeywordDetail(
      keywordId,
      period: period,
      points: points,
    );
  }

  Future<WatchlistResponse> fetchWatchlist() {
    return _apiClient.getWatchlist();
  }

  Future<AlertsResponse> fetchAlerts({
    int limit = 20,
    String? cursor,
    String? severity,
  }) {
    return _apiClient.getAlerts(
      limit: limit,
      cursor: cursor,
      severity: severity,
    );
  }

  Future<bool> updateWatchlist({
    required String op,
    required String targetType,
    required String targetId,
  }) {
    return _apiClient.updateWatchlist(
      op: op,
      targetType: targetType,
      targetId: targetId,
    );
  }

  Future<bool> addKeywordToWatchlist(String keywordId) {
    return updateWatchlist(
      op: 'add',
      targetType: 'keyword',
      targetId: keywordId,
    );
  }
}
