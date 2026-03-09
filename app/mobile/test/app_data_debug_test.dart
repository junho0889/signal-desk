import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signaldesk_mobile/core/localization/app_localization.dart';
import 'package:signaldesk_mobile/core/models/api_models.dart';
import 'package:signaldesk_mobile/core/network/api_exception.dart';
import 'package:signaldesk_mobile/core/network/mock_payloads.dart';
import 'package:signaldesk_mobile/core/network/signaldesk_api_client.dart';
import 'package:signaldesk_mobile/core/repositories/signaldesk_repository.dart';
import 'package:signaldesk_mobile/core/routes/app_routes.dart';
import 'package:signaldesk_mobile/features/alerts/alerts_screen.dart';
import 'package:signaldesk_mobile/features/detail/keyword_detail_screen.dart';
import 'package:signaldesk_mobile/features/home/home_screen.dart';
import 'package:signaldesk_mobile/features/ranking/ranking_screen.dart';
import 'package:signaldesk_mobile/features/shared/data_freshness_banner.dart';
import 'package:signaldesk_mobile/features/watchlist/watchlist_screen.dart';

void main() {
  group('app data debug surfaces', () {
    testWidgets(
        'ranking/detail surfaces render freshness and trust/status labels', (
      tester,
    ) async {
      final repository = SignalDeskRepository(
        apiClient: SignalDeskApiClient(
          baseUrl: 'http://127.0.0.1:8000',
          useMockData: true,
        ),
      );

      await tester.pumpWidget(_buildApp(repository));
      await tester.pumpAndSettle();

      expect(find.text('Keyword Ranking'), findsOneWidget);
      expect(find.text('Snapshot freshness'), findsWidgets);
      expect(find.textContaining('Confidence'), findsWidgets);
      expect(find.textContaining('Alert'), findsWidgets);
      await tester.scrollUntilVisible(find.text('Load More'), 300);
      expect(find.text('Load More'), findsOneWidget);

      await tester.tap(find.byType(ListTile).at(0));
      await tester.pumpAndSettle();

      expect(find.text('Keyword Detail'), findsOneWidget);
      expect(find.textContaining('Confidence:'), findsWidgets);
      expect(find.textContaining('Alert eligible:'), findsWidgets);
      expect(find.textContaining('Risk flags:'), findsWidgets);
    });

    testWidgets('ranking initial-load error shows retry and recovers',
        (tester) async {
      final apiClient =
          _FlakyKeywordsApiClient(failInitialLoad: true, failNextPage: false);
      final repository = SignalDeskRepository(apiClient: apiClient);

      await tester.pumpWidget(_buildApp(repository));
      await tester.pumpAndSettle();

      expect(find.text('Could not load'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      apiClient.failInitialLoad = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(apiClient.initialLoadCalls, 2);
      expect(find.textContaining('AI Infrastructure'), findsWidgets);
    });

    testWidgets('ranking next-page error state is shown on pagination failure',
        (tester) async {
      final apiClient =
          _FlakyKeywordsApiClient(failInitialLoad: false, failNextPage: true);
      final repository = SignalDeskRepository(apiClient: apiClient);

      await tester.pumpWidget(_buildApp(repository));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Load More'), 300);
      await tester.tap(find.text('Load More'));
      await tester.pumpAndSettle();

      expect(apiClient.nextPageCalls, 1);
      expect(find.textContaining('Could not load next page.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('stale freshness banner appears when age exceeds threshold',
        (tester) async {
      final languageController = AppLanguageController();
      await tester.pumpWidget(
        AppLanguageScope(
          controller: languageController,
          child: MaterialApp(
            home: Scaffold(
              body: DataFreshnessBanner(
                generatedAt:
                    DateTime.now().toUtc().subtract(const Duration(hours: 10)),
                staleAfter: const Duration(hours: 1),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Stale snapshot'), findsOneWidget);
    });

    testWidgets('korean mode toggles visible ranking chrome', (tester) async {
      final repository = SignalDeskRepository(
        apiClient: SignalDeskApiClient(
          baseUrl: 'http://127.0.0.1:8000',
          useMockData: true,
        ),
      );

      await tester.pumpWidget(_buildApp(repository));
      await tester.pumpAndSettle();

      expect(find.text('Keyword Ranking'), findsOneWidget);
      expect(find.text('KO'), findsOneWidget);

      await tester.tap(find.text('KO'));
      await tester.pumpAndSettle();

      expect(find.text('\uD0A4\uC6CC\uB4DC \uB7AD\uD0B9'), findsOneWidget);
      expect(find.textContaining('\uC810\uC218'), findsWidgets);
      expect(find.text('EN'), findsOneWidget);
    });
  });
}

Widget _buildApp(SignalDeskRepository repository) {
  final languageController = AppLanguageController();
  return AppLanguageScope(
    controller: languageController,
    child: MaterialApp(
      home: RankingScreen(repository: repository),
      routes: <String, WidgetBuilder>{
        AppRoutes.home: (_) => HomeScreen(repository: repository),
        AppRoutes.ranking: (_) => RankingScreen(repository: repository),
        AppRoutes.watchlist: (_) => WatchlistScreen(repository: repository),
        AppRoutes.alerts: (_) => AlertsScreen(repository: repository),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.detail) {
          final keywordId = settings.arguments is String
              ? settings.arguments! as String
              : 'kw_ai';
          return MaterialPageRoute<void>(
            builder: (_) => KeywordDetailScreen(
              repository: repository,
              keywordId: keywordId,
            ),
          );
        }
        return null;
      },
    ),
  );
}

class _FlakyKeywordsApiClient extends SignalDeskApiClient {
  _FlakyKeywordsApiClient({
    required this.failInitialLoad,
    required this.failNextPage,
  }) : super(baseUrl: 'http://127.0.0.1:8000', useMockData: false);

  bool failInitialLoad;
  bool failNextPage;
  int initialLoadCalls = 0;
  int nextPageCalls = 0;

  @override
  Future<KeywordsResponse> getKeywords({
    required String period,
    String market = 'all',
    String? sector,
    int limit = 20,
    String? cursor,
  }) async {
    final isNextPage = cursor != null && cursor.isNotEmpty;
    if (isNextPage) {
      nextPageCalls += 1;
    } else {
      initialLoadCalls += 1;
    }
    if (!isNextPage && failInitialLoad) {
      throw ApiException('forced initial load failure');
    }
    if (isNextPage && failNextPage) {
      throw ApiException('forced next page failure');
    }

    return KeywordsResponse.fromJson(
      MockPayloads.keywords(
        period: period,
        market: market,
        sector: sector,
        limit: limit,
        cursor: cursor,
      ),
    );
  }
}
