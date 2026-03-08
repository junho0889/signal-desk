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

  String get appTitle => isKorean ? '시그널데스크' : 'SignalDesk';
  String get homeTitle => isKorean ? '홈' : 'Home';
  String get rankingTitle => isKorean ? '키워드 랭킹' : 'Keyword Ranking';
  String get detailTitle => isKorean ? '키워드 상세' : 'Keyword Detail';
  String get watchlistTitle => isKorean ? '관심목록' : 'Watchlist';
  String get alertsTitle => isKorean ? '알림' : 'Alerts';

  String get generatedAtLabel => isKorean ? '갱신 시각' : 'Generated';
  String get staleLabel => isKorean ? '지연 데이터' : 'Stale data';
  String get liveLabel => isKorean ? '실시간' : 'Live';
  String get recentLabel => isKorean ? '최근' : 'Recent';
  String get agingLabel => isKorean ? '노후' : 'Aging';

  String get topKeywords => isKorean ? '상위 키워드' : 'Top Keywords';
  String get sectorMovers => isKorean ? '섹터 모멘텀' : 'Sector Movers';
  String get recentAlerts => isKorean ? '최근 알림' : 'Recent Alerts';
  String get rankingFilterPeriod => isKorean ? '주기' : 'Period';
  String get alertsFilterSeverity => isKorean ? '심각도' : 'Severity';

  String get scoreLabel => isKorean ? '점수' : 'Score';
  String get deltaLabel => isKorean ? '24h 변화' : 'Delta 24h';
  String get confidenceLabel => isKorean ? '신뢰도' : 'Confidence';
  String get trustLabel => isKorean ? '신뢰 상태' : 'Trust';
  String get freshnessLabel => isKorean ? '신선도' : 'Freshness';
  String get reasonLabel => isKorean ? '근거' : 'Reason';
  String get riskLabel => isKorean ? '리스크' : 'Risk';

  String get retryLabel => isKorean ? '다시 시도' : 'Retry';
  String get refreshLabel => isKorean ? '새로고침' : 'Refresh';
  String get noDataTitle => isKorean ? '데이터 없음' : 'No data';
  String get loadingTitle => isKorean ? '로딩 중' : 'Loading';
  String get loadFailedTitle => isKorean ? '불러오기 실패' : 'Could not load';

  String get addWatchlist => isKorean ? '관심목록 추가' : 'Add to Watchlist';
  String get addingWatchlist => isKorean ? '추가 중...' : 'Adding...';

  String get allSeverity => isKorean ? '전체' : 'All';

  String relativeTime(int minutes) {
    if (minutes < 1) {
      return isKorean ? '방금 전' : 'just now';
    }
    if (minutes < 60) {
      return isKorean ? '$minutes분 전' : '${minutes}m ago';
    }
    final hours = minutes ~/ 60;
    if (hours < 24) {
      return isKorean ? '$hours시간 전' : '${hours}h ago';
    }
    final days = hours ~/ 24;
    return isKorean ? '$days일 전' : '${days}d ago';
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
