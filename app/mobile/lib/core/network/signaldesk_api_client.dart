import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/api_models.dart';
import 'api_exception.dart';
import 'mock_payloads.dart';

class SignalDeskApiClient {
  SignalDeskApiClient({
    required String baseUrl,
    http.Client? httpClient,
    this.useMockData = true,
  })  : _baseUri = Uri.parse(baseUrl),
        _http = httpClient ?? http.Client();

  final Uri _baseUri;
  final http.Client _http;
  final bool useMockData;

  Future<DashboardResponse> getDashboard() async {
    final json = await _get(
      path: '/v1/dashboard',
      mock: MockPayloads.dashboard,
    );
    return DashboardResponse.fromJson(json);
  }

  Future<KeywordsResponse> getKeywords({
    required String period,
    String market = 'all',
    String? sector,
    int limit = 20,
    String? cursor,
  }) async {
    final query = <String, String>{
      'period': period,
      'market': market,
      'limit': '$limit',
      if (sector != null && sector.isNotEmpty) 'sector': sector,
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
    };

    final json = await _get(
      path: '/v1/keywords',
      queryParameters: query,
      mock: MockPayloads.keywords,
    );
    return KeywordsResponse.fromJson(json);
  }

  Future<KeywordDetailResponse> getKeywordDetail(
    String keywordId, {
    String period = 'daily',
    int points = 24,
  }) async {
    final json = await _get(
      path: '/v1/keywords/$keywordId',
      queryParameters: <String, String>{
        'period': period,
        'points': '$points',
      },
      mock: () => MockPayloads.keywordDetail(keywordId),
    );
    return KeywordDetailResponse.fromJson(json);
  }

  Future<WatchlistResponse> getWatchlist() async {
    final json = await _get(
      path: '/v1/watchlist',
      mock: MockPayloads.watchlist,
    );
    return WatchlistResponse.fromJson(json);
  }

  Future<AlertsResponse> getAlerts({
    int limit = 20,
    String? cursor,
    String? severity,
  }) async {
    final json = await _get(
      path: '/v1/alerts',
      queryParameters: <String, String>{
        'limit': '$limit',
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        if (severity != null && severity.isNotEmpty) 'severity': severity,
      },
      mock: MockPayloads.alerts,
    );
    return AlertsResponse.fromJson(json);
  }

  Future<bool> updateWatchlist({
    required String op,
    required String targetType,
    required String targetId,
  }) async {
    if (useMockData) {
      return true;
    }

    final uri = _baseUri.replace(path: '/v1/watchlist');
    final response = await _http.post(
      uri,
      headers: const {'content-type': 'application/json; charset=utf-8'},
      body: jsonEncode(
        <String, dynamic>{
          'op': op,
          'target_type': targetType,
          'target_id': targetId,
        },
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toApiException(response);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded['ok'] == true;
    }
    return false;
  }

  Future<Map<String, dynamic>> _get({
    required String path,
    required Map<String, dynamic> Function() mock,
    Map<String, String>? queryParameters,
  }) async {
    if (useMockData) {
      return mock();
    }

    final uri = _baseUri.replace(path: path, queryParameters: queryParameters);
    final response = await _http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toApiException(response);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw ApiException('Unexpected response shape: expected object payload');
  }

  ApiException _toApiException(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final error = (decoded['error'] as Map?)?.cast<String, dynamic>();
        return ApiException(
          (error?['message'] as String?) ??
              'Request failed with status ${response.statusCode}',
          code: error?['code'] as String?,
          requestId: decoded['request_id'] as String?,
        );
      }
    } catch (_) {
      // Fall through to generic exception.
    }

    return ApiException(
      'Request failed with status ${response.statusCode}',
    );
  }
}
