import 'package:flutter/material.dart';

import '../src/api/mock_signal_desk_api.dart';
import '../src/api/signal_desk_api.dart';
import '../src/api/signal_desk_api_client.dart';
import '../src/screens/alerts_screen.dart';
import '../src/screens/home_screen.dart';
import '../src/screens/keyword_detail_screen.dart';
import '../src/screens/keyword_ranking_screen.dart';
import '../src/screens/watchlist_screen.dart';

class SignalDeskApp extends StatelessWidget {
  const SignalDeskApp({super.key});

  static const _apiBaseUrl = String.fromEnvironment(
    'SIGNAL_DESK_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );
  static const _useMockApi = bool.fromEnvironment(
    'USE_MOCK_API',
    defaultValue: true,
  );

  @override
  Widget build(BuildContext context) {
    final SignalDeskApi api = _useMockApi
        ? MockSignalDeskApi()
        : SignalDeskApiClient(baseUrl: _apiBaseUrl);

    return MaterialApp(
      title: 'SignalDesk',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF165D4F)),
        useMaterial3: true,
      ),
      initialRoute: HomeScreen.route,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case HomeScreen.route:
            return MaterialPageRoute(builder: (_) => HomeScreen(api: api));
          case KeywordRankingScreen.route:
            return MaterialPageRoute(
              builder: (_) => KeywordRankingScreen(api: api),
            );
          case WatchlistScreen.route:
            return MaterialPageRoute(builder: (_) => WatchlistScreen(api: api));
          case AlertsScreen.route:
            return MaterialPageRoute(builder: (_) => AlertsScreen(api: api));
          case KeywordDetailScreen.route:
            final keywordId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => KeywordDetailScreen(api: api, keywordId: keywordId),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Unknown route')),
                body: Center(child: Text('No route for ${settings.name}')),
              ),
            );
        }
      },
    );
  }
}
