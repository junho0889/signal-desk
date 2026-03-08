import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';
import 'signal_desk_api.dart';

class SignalDeskApiClient implements SignalDeskApi {
  SignalDeskApiClient({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;

  Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    final uri = Uri.parse(baseUrl);
    final normalizedPath = '${uri.path.endsWith('/') ? uri.path.substring(0, uri.path.length - 1) : uri.path}/v1$path';
    return uri.replace(path: normalizedPath, queryParameters: queryParameters);
  }

  Future<Map<String, dynamic>> _get(String path, [Map<String, String>? query]) async {
    final response = await _httpClient.get(_buildUri(path, query));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('GET $path failed (${response.statusCode}): ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final response = await _httpClient.post(
      _buildUri(path),
      headers: const <String, String>{
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('POST $path failed (${response.statusCode}): ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  @override
  Future<DashboardResponse> getDashboard() async {
    final payload = await _get('/dashboard');
    return DashboardResponse.fromJson(payload);
  }

  @override
  Future<KeywordRankingResponse> getKeywords({
    required Period period,
    Market market = Market.all,
    String? sector,
    int? limit,
    String? cursor,
  }) async {
    final query = <String, String>{
      'period': period.name,
      'market': market.name,
      if (sector != null && sector.isNotEmpty) 'sector': sector,
      if (limit != null) 'limit': '$limit',
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
    };
    final payload = await _get('/keywords', query);
    return KeywordRankingResponse.fromJson(payload);
  }

  @override
  Future<KeywordDetailResponse> getKeywordDetail(
    String keywordId, {
    Period period = Period.daily,
    int? points,
  }) async {
    final query = <String, String>{
      'period': period.name,
      if (points != null) 'points': '$points',
    };
    final payload = await _get('/keywords/$keywordId', query);
    return KeywordDetailResponse.fromJson(payload);
  }

  @override
  Future<WatchlistResponse> getWatchlist() async {
    final payload = await _get('/watchlist');
    return WatchlistResponse.fromJson(payload);
  }

  @override
  Future<WatchlistMutationResponse> postWatchlist(
    WatchlistMutationRequest request,
  ) async {
    final payload = await _post('/watchlist', request.toJson());
    return WatchlistMutationResponse.fromJson(payload);
  }

  @override
  Future<AlertsResponse> getAlerts({
    Severity? severity,
    int? limit,
    String? cursor,
  }) async {
    final query = <String, String>{
      if (severity != null) 'severity': severity.name,
      if (limit != null) 'limit': '$limit',
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
    };
    final payload = await _get('/alerts', query);
    return AlertsResponse.fromJson(payload);
  }
}
