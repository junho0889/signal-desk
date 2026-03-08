import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/network/signaldesk_api_client.dart';
import '../core/repositories/signaldesk_repository.dart';
import '../core/routes/app_routes.dart';
import '../features/alerts/alerts_screen.dart';
import '../features/detail/keyword_detail_screen.dart';
import '../features/home/home_screen.dart';
import '../features/ranking/ranking_screen.dart';
import '../features/watchlist/watchlist_screen.dart';
import 'app_scope.dart';
import 'signal_desk_localizations.dart';

class SignalDeskApp extends StatefulWidget {
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
  State<SignalDeskApp> createState() => _SignalDeskAppState();
}

class _SignalDeskAppState extends State<SignalDeskApp> {
  Locale _locale = const Locale('en');

  void _toggleLocale() {
    setState(() {
      _locale = _locale.languageCode == 'ko'
          ? const Locale('en')
          : const Locale('ko');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlexThemeData.light(
      colors: const FlexSchemeColor(
        primary: Color(0xFF0B5C74),
        primaryContainer: Color(0xFFCDEAF2),
        secondary: Color(0xFF1F6A57),
        secondaryContainer: Color(0xFFD8EEE6),
        tertiary: Color(0xFF7B5A2E),
        tertiaryContainer: Color(0xFFF2E7D7),
        appBarColor: Color(0xFFF3F7FA),
        error: Color(0xFFB3261E),
      ),
      useMaterial3: true,
      fontFamilyFallback: const <String>[
        'Pretendard Variable',
        'Noto Sans KR',
        'Roboto',
      ],
      subThemesData: const FlexSubThemesData(
        defaultRadius: 14,
        inputDecoratorRadius: 10,
        navigationBarIndicatorRadius: 10,
        navigationBarLabelTextStyle: TextStyle(fontWeight: FontWeight.w600),
        cardRadius: 14,
        cardElevation: 0,
      ),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 7,
      appBarStyle: FlexAppBarStyle.surface,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
    );

    return MaterialApp(
      title: 'SignalDesk',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: SignalDeskLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        SignalDeskLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: theme,
      initialRoute: AppRoutes.home,
      routes: <String, WidgetBuilder>{
        AppRoutes.home: (_) => HomeScreen(repository: SignalDeskApp.repository),
        AppRoutes.ranking: (_) =>
            RankingScreen(repository: SignalDeskApp.repository),
        AppRoutes.watchlist: (_) =>
            WatchlistScreen(repository: SignalDeskApp.repository),
        AppRoutes.alerts: (_) =>
            AlertsScreen(repository: SignalDeskApp.repository),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.detail) {
          final keywordId = settings.arguments is String
              ? settings.arguments as String
              : 'kw_ai';
          return MaterialPageRoute<void>(
            builder: (_) => KeywordDetailScreen(
              repository: SignalDeskApp.repository,
              keywordId: keywordId,
            ),
          );
        }
        return null;
      },
      builder: (context, child) {
        return SignalDeskAppScope(
          locale: _locale,
          toggleLocale: _toggleLocale,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
