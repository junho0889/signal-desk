import 'package:flutter/widgets.dart';

class SignalDeskLocalizations {
  SignalDeskLocalizations(this.locale);

  final Locale locale;

  bool get isKorean => locale.languageCode == 'ko';

  static SignalDeskLocalizations of(BuildContext context) {
    final localizations = Localizations.of<SignalDeskLocalizations>(
      context,
      SignalDeskLocalizations,
    );
    assert(localizations != null, 'SignalDeskLocalizations is not available.');
    return localizations!;
  }

  static const delegate = _SignalDeskLocalizationsDelegate();

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  String get appTitle =>
      isKorean ? '\uC2DC\uADF8\uB110\uB370\uC2A4\uD06C' : 'SignalDesk';
  String get homeTitle => isKorean ? '\uD648' : 'Home';
  String get rankingTitle =>
      isKorean ? '\uD0A4\uC6CC\uB4DC \uB7AD\uD0B9' : 'Keyword Ranking';
  String get detailTitle =>
      isKorean ? '\uD0A4\uC6CC\uB4DC \uC0C1\uC138' : 'Keyword Detail';
  String get watchlistTitle =>
      isKorean ? '\uAD00\uC2EC\uBAA9\uB85D' : 'Watchlist';
  String get alertsTitle => isKorean ? '\uC54C\uB9BC' : 'Alerts';

  String get generatedAtLabel =>
      isKorean ? '\uAC31\uC2E0 \uC2DC\uAC01' : 'Generated';
  String get staleLabel =>
      isKorean ? '\uC9C0\uC5F0 \uB370\uC774\uD130' : 'Stale data';
  String get liveLabel => isKorean ? '\uC2E4\uC2DC\uAC04' : 'Live';
  String get recentLabel => isKorean ? '\uCD5C\uADFC' : 'Recent';
  String get agingLabel => isKorean ? '\uB178\uD6C4' : 'Aging';

  String get topKeywords =>
      isKorean ? '\uC0C1\uC704 \uD0A4\uC6CC\uB4DC' : 'Top Keywords';
  String get sectorMovers =>
      isKorean ? '\uC139\uD130 \uBAA8\uBA58\uD140' : 'Sector Movers';
  String get recentAlerts =>
      isKorean ? '\uCD5C\uADFC \uC54C\uB9BC' : 'Recent Alerts';
  String get rankingFilterPeriod => isKorean ? '\uC8FC\uAE30' : 'Period';
  String get alertsFilterSeverity =>
      isKorean ? '\uC2EC\uAC01\uB3C4' : 'Severity';

  String get scoreLabel => isKorean ? '\uC810\uC218' : 'Score';
  String get deltaLabel => isKorean ? '24h \uBCC0\uD654' : 'Delta 24h';
  String get confidenceLabel => isKorean ? '\uC2E0\uB8B0\uB3C4' : 'Confidence';
  String get trustLabel => isKorean ? '\uC2E0\uB8B0 \uC0C1\uD0DC' : 'Trust';
  String get freshnessLabel => isKorean ? '\uC2E0\uC120\uB3C4' : 'Freshness';
  String get reasonLabel => isKorean ? '\uADFC\uAC70' : 'Reason';
  String get riskLabel => isKorean ? '\uB9AC\uC2A4\uD06C' : 'Risk';

  String get keywordsLabel => isKorean ? '\uD0A4\uC6CC\uB4DC' : 'Keywords';
  String get stocksLabel => isKorean ? '\uC885\uBAA9' : 'Stocks';
  String get dimensionContributionsTitle =>
      isKorean ? '\uAE30\uC5EC \uC9C0\uD45C' : 'Dimension contributions';
  String get relatedStocksSectorsTitle => isKorean
      ? '\uC5F0\uAD00 \uC885\uBAA9 \uBC0F \uC139\uD130'
      : 'Related stocks and sectors';
  String get scoreConfidenceTrendTitle => isKorean
      ? '\uC810\uC218\uC640 \uC2E0\uB8B0\uB3C4 \uCD94\uC774'
      : 'Score and confidence trend';

  String get mentionsLabel => isKorean ? '\uC5B8\uAE09\uB7C9' : 'Mentions';
  String get trendsLabel => isKorean ? '\uD2B8\uB80C\uB4DC' : 'Trends';
  String get marketLabel => isKorean ? '\uC2DC\uC7A5\uBC18\uC751' : 'Market';
  String get eventsLabel => isKorean ? '\uC774\uBCA4\uD2B8' : 'Events';
  String get persistenceLabel =>
      isKorean ? '\uC9C0\uC18D\uC131' : 'Persistence';

  String get retryLabel => isKorean ? '\uB2E4\uC2DC \uC2DC\uB3C4' : 'Retry';
  String get refreshLabel => isKorean ? '\uC0C8\uB85C\uACE0\uCE68' : 'Refresh';
  String get noDataTitle =>
      isKorean ? '\uB370\uC774\uD130 \uC5C6\uC74C' : 'No data';
  String get loadingTitle => isKorean ? '\uB85C\uB529 \uC911' : 'Loading';
  String get loadFailedTitle =>
      isKorean ? '\uBD88\uB7EC\uC624\uAE30 \uC2E4\uD328' : 'Could not load';
  String get loadingMessage => isKorean
      ? '\uB370\uC774\uD130\uB97C \uBD88\uB7EC\uC624\uB294 \uC911\uC785\uB2C8\uB2E4.'
      : 'Loading market intelligence.';
  String get emptyStateMessage => isKorean
      ? '\uD45C\uC2DC\uD560 \uB370\uC774\uD130\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4.'
      : 'Nothing to show yet.';
  String get dashboardEmptyMessage => isKorean
      ? '\uD648 \uB370\uC774\uD130\uAC00 \uC544\uC9C1 \uC5C6\uC2B5\uB2C8\uB2E4.'
      : 'No dashboard data is available yet.';
  String get rankingEmptyMessage => isKorean
      ? '\uC120\uD0DD\uD55C \uD544\uD130\uC5D0 \uD45C\uC2DC\uD560 \uB7AD\uD0B9 \uB370\uC774\uD130\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4.'
      : 'No ranking data is available for this filter.';
  String get detailEmptyMessage => isKorean
      ? '\uD0A4\uC6CC\uB4DC \uC0C1\uC138 \uB370\uC774\uD130\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4.'
      : 'No keyword detail is available.';
  String get watchlistEmptyMessage => isKorean
      ? '\uCD94\uC801 \uC911\uC778 \uAD00\uC2EC\uBAA9\uB85D \uD56D\uBAA9\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.'
      : 'No watchlist items are being tracked yet.';
  String get alertsEmptyMessage => isKorean
      ? '\uC120\uD0DD\uD55C \uC2EC\uAC01\uB3C4\uC5D0 \uD574\uB2F9\uD558\uB294 \uC54C\uB9BC\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.'
      : 'No recent triggers match this severity filter.';
  String get insufficientDataMessage => isKorean
      ? '\uB370\uC774\uD130\uAC00 \uBD80\uC871\uD569\uB2C8\uB2E4.'
      : 'Insufficient data';
  String get insufficientChartDataMessage => isKorean
      ? '\uCC28\uD2B8 \uB370\uC774\uD130\uAC00 \uBD80\uC871\uD569\uB2C8\uB2E4.'
      : 'Insufficient chart data';

  String get addWatchlist =>
      isKorean ? '\uAD00\uC2EC\uBAA9\uB85D \uCD94\uAC00' : 'Add to Watchlist';
  String get addingWatchlist =>
      isKorean ? '\uCD94\uAC00 \uC911...' : 'Adding...';
  String get watchlistAdded => isKorean
      ? '\uAD00\uC2EC\uBAA9\uB85D\uC5D0 \uCD94\uAC00\uD588\uC2B5\uB2C8\uB2E4.'
      : 'Added to watchlist.';
  String get watchlistPendingConfirm => isKorean
      ? '\uC11C\uBC84 \uD655\uC778 \uC5C6\uC774 \uCC98\uB9AC\uB418\uC5C8\uC2B5\uB2C8\uB2E4.'
      : 'Watchlist update completed without confirmation.';
  String get watchlistUpdateFailedPrefix => isKorean
      ? '\uAD00\uC2EC\uBAA9\uB85D \uC5C5\uB370\uC774\uD2B8 \uC2E4\uD328:'
      : 'Failed to update watchlist:';

  String get allSeverity => isKorean ? '\uC804\uCCB4' : 'All';
  String get alertReadyLabel =>
      isKorean ? '\uC54C\uB9BC \uAC00\uB2A5' : 'Alert Ready';
  String get alertHoldLabel =>
      isKorean ? '\uC54C\uB9BC \uBCF4\uB958' : 'Alert Hold';

  String periodLabel(String period) {
    switch (period) {
      case 'intraday':
        return isKorean ? '\uB2F9\uC77C' : 'Intraday';
      case 'weekly':
        return isKorean ? '\uC8FC\uAC04' : 'Weekly';
      case 'daily':
      default:
        return isKorean ? '\uC77C\uAC04' : 'Daily';
    }
  }

  String severityLabel(String? severity) {
    switch (severity) {
      case null:
        return allSeverity;
      case 'low':
        return isKorean ? '\uB0AE\uC74C' : 'LOW';
      case 'medium':
        return isKorean ? '\uBCF4\uD1B5' : 'MEDIUM';
      case 'high':
        return isKorean ? '\uB192\uC74C' : 'HIGH';
      case 'critical':
        return isKorean ? '\uAE34\uAE09' : 'CRITICAL';
      default:
        return severity.toUpperCase();
    }
  }

  String keywordCountLabel(int count) {
    if (isKorean) {
      return '$count\uAC1C \uD0A4\uC6CC\uB4DC';
    }
    return '$count keywords';
  }

  String staleDataMessage(String relativeAge) {
    if (isKorean) {
      return '\uB370\uC774\uD130\uAC00 $relativeAge \uC9C0\uB0AC\uC2B5\uB2C8\uB2E4. \uD574\uC11D\uC5D0 \uC8FC\uC758\uD558\uC138\uC694.';
    }
    return 'Data is $relativeAge old. Interpret with caution.';
  }

  String relativeTime(int minutes) {
    if (minutes < 1) {
      return isKorean ? '\uBC29\uAE08 \uC804' : 'just now';
    }
    if (minutes < 60) {
      return isKorean ? '$minutes\uBD84 \uC804' : '${minutes}m ago';
    }
    final hours = minutes ~/ 60;
    if (hours < 24) {
      return isKorean ? '$hours\uC2DC\uAC04 \uC804' : '${hours}h ago';
    }
    final days = hours ~/ 24;
    return isKorean ? '$days\uC77C \uC804' : '${days}d ago';
  }
}

class _SignalDeskLocalizationsDelegate
    extends LocalizationsDelegate<SignalDeskLocalizations> {
  const _SignalDeskLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return locale.languageCode == 'en' || locale.languageCode == 'ko';
  }

  @override
  Future<SignalDeskLocalizations> load(Locale locale) async {
    return SignalDeskLocalizations(locale);
  }

  @override
  bool shouldReload(_SignalDeskLocalizationsDelegate old) => false;
}
