import 'package:flutter/material.dart';

import '../core/network/signaldesk_api_client.dart';
import '../core/repositories/signaldesk_repository.dart';
import '../core/routes/app_routes.dart';
import '../features/alerts/alerts_screen.dart';
import '../features/detail/keyword_detail_screen.dart';
import '../features/home/home_screen.dart';
import '../features/ranking/ranking_screen.dart';
import '../features/watchlist/watchlist_screen.dart';

class SignalDeskApp extends StatelessWidget {
  const SignalDeskApp({super.key});

  static final SignalDeskApiClient apiClient = SignalDeskApiClient(
    baseUrl: const String.fromEnvironment(
      'SIGNALDESK_API_BASE_URL',
      defaultValue: 'http://127.0.0.1:8000',
    ),
    useMockData: const bool.fromEnvironment(
      'SIGNALDESK_USE_MOCK',
      defaultValue: true,
    ),
  );

  static final SignalDeskRepository repository = SignalDeskRepository(
    apiClient: apiClient,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SignalDesk',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A4E8A)),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.home,
      routes: <String, WidgetBuilder>{
        AppRoutes.home: (_) => HomeScreen(repository: repository),
        AppRoutes.ranking: (_) => RankingScreen(repository: repository),
        AppRoutes.watchlist: (_) => WatchlistScreen(repository: repository),
        AppRoutes.alerts: (_) => AlertsScreen(repository: repository),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.detail) {
          final keywordId = settings.arguments is String
              ? settings.arguments as String
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
    );
  }
}
