import 'package:flutter/material.dart';

import '../core/localization/app_localization.dart';
import '../core/network/signaldesk_api_client.dart';
import '../core/repositories/signaldesk_repository.dart';
import '../core/routes/app_routes.dart';
import '../features/alerts/alerts_screen.dart';
import '../features/detail/keyword_detail_screen.dart';
import '../features/home/home_screen.dart';
import '../features/ranking/ranking_screen.dart';
import '../features/watchlist/watchlist_screen.dart';

class SignalDeskApp extends StatefulWidget {
  const SignalDeskApp({super.key});

  @override
  State<SignalDeskApp> createState() => _SignalDeskAppState();
}

class _SignalDeskAppState extends State<SignalDeskApp> {
  final AppLanguageController _languageController = AppLanguageController();

  late final SignalDeskApiClient _apiClient = SignalDeskApiClient(
    baseUrl: const String.fromEnvironment(
      'SIGNALDESK_API_BASE_URL',
      defaultValue: 'http://127.0.0.1:8000',
    ),
    useMockData: const bool.fromEnvironment(
      'SIGNALDESK_USE_MOCK',
      defaultValue: true,
    ),
  );

  late final SignalDeskRepository _repository = SignalDeskRepository(
    apiClient: _apiClient,
  );

  @override
  void dispose() {
    _languageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLanguageScope(
      controller: _languageController,
      child: ValueListenableBuilder<AppLanguage>(
        valueListenable: _languageController,
        builder: (context, language, _) {
          final strings = AppStrings(language);
          return MaterialApp(
            title: strings.appName,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A4E8A)),
              useMaterial3: true,
            ),
            initialRoute: AppRoutes.home,
            routes: <String, WidgetBuilder>{
              AppRoutes.home: (_) => HomeScreen(repository: _repository),
              AppRoutes.ranking: (_) => RankingScreen(repository: _repository),
              AppRoutes.watchlist: (_) => WatchlistScreen(repository: _repository),
              AppRoutes.alerts: (_) => AlertsScreen(repository: _repository),
            },
            onGenerateRoute: (settings) {
              if (settings.name == AppRoutes.detail) {
                final keywordId = settings.arguments is String
                    ? settings.arguments as String
                    : 'kw_ai';
                return MaterialPageRoute<void>(
                  builder: (_) => KeywordDetailScreen(
                    repository: _repository,
                    keywordId: keywordId,
                  ),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}
