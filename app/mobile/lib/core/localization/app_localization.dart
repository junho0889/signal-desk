import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

enum AppLanguage { english, korean }

class AppLanguageController extends ValueNotifier<AppLanguage> {
  AppLanguageController() : super(AppLanguage.english);

  bool get isKorean => value == AppLanguage.korean;

  void toggle() {
    value = isKorean ? AppLanguage.english : AppLanguage.korean;
  }
}

class AppLanguageScope extends InheritedNotifier<AppLanguageController> {
  const AppLanguageScope({
    super.key,
    required AppLanguageController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLanguageController controllerOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppLanguageScope>();
    assert(scope != null, 'AppLanguageScope is required above this context.');
    return scope!.notifier!;
  }

  static AppStrings stringsOf(BuildContext context) {
    final controller = controllerOf(context);
    return AppStrings(controller.value);
  }
}

class AppStrings {
  const AppStrings(this.language);

  final AppLanguage language;

  bool get isKorean => language == AppLanguage.korean;

  String get appName => isKorean ? '시그널데스크' : 'SignalDesk';
  String get languageToggleLabel => isKorean ? 'EN' : 'KO';
  String get languageToggleTooltip => isKorean ? '언어 전환' : 'Switch language';

  String get homeTitle => isKorean ? '시그널데스크 홈' : 'SignalDesk Home';
  String get rankingTitle => isKorean ? '키워드 랭킹' : 'Keyword Ranking';
  String get detailTitle => isKorean ? '키워드 상세' : 'Keyword Detail';
  String get watchlistTitle => isKorean ? '관심목록' : 'Watchlist';
  String get alertsTitle => isKorean ? '알림' : 'Alerts';

  String get navHome => isKorean ? '홈' : 'Home';
  String get navRanking => isKorean ? '랭킹' : 'Ranking';
  String get navWatchlist => isKorean ? '관심목록' : 'Watchlist';
  String get navAlerts => isKorean ? '알림' : 'Alerts';

  String get loadingTitle => isKorean ? '불러오는 중' : 'Loading';
  String get loadingDataMessage => isKorean ? '데이터를 불러오는 중입니다...' : 'Loading data...';
  String get couldNotLoadTitle => isKorean ? '불러오지 못했습니다' : 'Could not load';
  String get noDataTitle => isKorean ? '데이터 없음' : 'No data';
  String get nothingYetTitle => isKorean ? '아직 없음' : 'Nothing yet';
  String get nothingToShowMessage => isKorean ? '표시할 항목이 없습니다.' : 'Nothing to show yet.';
  String get retryAction => isKorean ? '다시 시도' : 'Retry';
  String get refreshAction => isKorean ? '새로고침' : 'Refresh';

  String get freshnessStaleLabel => isKorean ? '데이터 지연' : 'Stale snapshot';
  String get freshnessFreshLabel => isKorean ? '스냅샷 최신도' : 'Snapshot freshness';
  String freshnessFreshMessage(String age, String generatedAt) {
    if (isKorean) {
      return '경과 $age. 생성 시각 $generatedAt (로컬 시간).';
    }
    return 'Age $age. Generated $generatedAt (local time).';
  }

  String freshnessStaleMessage(String age, String generatedAt, String threshold) {
    if (isKorean) {
      return '경과 $age. 생성 시각 $generatedAt (로컬 시간). '
          '$threshold 이후 지연으로 간주되어 새로고침을 권장합니다.';
    }
    return 'Age $age. Generated $generatedAt (local time). '
        'Refresh recommended (stale after $threshold).';
  }

  String get underOneMinute => isKorean ? '1분 미만' : 'under 1m';
  String minutesLabel(int minutes) => isKorean ? '${minutes}분' : '${minutes}m';
  String hoursLabel(int hours) => isKorean ? '${hours}시간' : '${hours}h';
  String daysLabel(int days) => isKorean ? '${days}일' : '${days}d';

  String get topKeywordsHeader => isKorean ? '상위 키워드' : 'Top Keywords';
  String get sectorMoversHeader => isKorean ? '섹터 변동' : 'Sector Movers';
  String get recentAlertsHeader => isKorean ? '최근 알림' : 'Recent Alerts';
  String get noDashboardData => isKorean ? '대시보드 데이터가 없습니다.' : 'No dashboard data is available yet.';

  String get periodLabel => isKorean ? '기간:' : 'Period:';
  String periodOption(String period) {
    if (!isKorean) {
      return period;
    }
    switch (period) {
      case 'intraday':
        return '장중';
      case 'daily':
        return '일간';
      case 'weekly':
        return '주간';
      default:
        return period;
    }
  }

  String get severityLabel => isKorean ? '심각도:' : 'Severity:';
  String severityOption(String? severity) {
    if (severity == null) {
      return isKorean ? '전체' : 'All';
    }
    if (!isKorean) {
      return severity;
    }
    switch (severity) {
      case 'low':
        return '낮음';
      case 'medium':
        return '보통';
      case 'high':
        return '높음';
      case 'critical':
        return '긴급';
      default:
        return severity;
    }
  }

  String get noRankingData => isKorean ? '현재 필터에 해당하는 랭킹 데이터가 없습니다.' : 'No ranking data is available for this filter.';
  String get noAlertsData => isKorean ? '선택한 심각도에 해당하는 알림이 없습니다.' : 'No recent triggers match this severity filter.';
  String get noWatchlistData => isKorean ? '추적 중인 관심목록 항목이 없습니다.' : 'No watchlist items are being tracked yet.';
  String get noKeywordDetail => isKorean ? '키워드 상세 데이터가 없습니다.' : 'No keyword detail is available.';

  String get loadMoreAction => isKorean ? '더 불러오기' : 'Load More';
  String nextPageLoadError(String error) {
    if (isKorean) {
      return '다음 페이지를 불러오지 못했습니다. $error';
    }
    return 'Could not load next page. $error';
  }
  String get endOfRankingResults => isKorean ? '랭킹 결과의 끝입니다' : 'End of ranking results';
  String get endOfAlerts => isKorean ? '알림 목록의 끝입니다' : 'End of alerts';

  String get keywordsHeader => isKorean ? '키워드' : 'Keywords';
  String get stocksHeader => isKorean ? '종목' : 'Stocks';
  String get relatedStocksHeader => isKorean ? '연관 종목' : 'Related stocks';

  String get scoreLabel => isKorean ? '점수' : 'Score';
  String get deltaLabel => isKorean ? '변화' : 'Delta';
  String get delta24hLabel => isKorean ? '24시간 변화' : 'Delta 24h';
  String get confidenceLabel => isKorean ? '신뢰도' : 'Confidence';
  String get alertLabel => isKorean ? '알림' : 'Alert';
  String get alertEligibleLabel => isKorean ? '알림 가능' : 'Alert eligible';
  String get reasonsLabel => isKorean ? '근거' : 'Reasons';
  String get riskLabel => isKorean ? '위험' : 'Risk';
  String get riskFlagsLabel => isKorean ? '위험 플래그' : 'Risk flags';
  String get reasonLabel => isKorean ? '사유' : 'Reason';
  String get relatedSectorsLabel => isKorean ? '연관 섹터' : 'Related sectors';
  String get marketLabel => isKorean ? '시장' : 'Market';
  String get sectorLabel => isKorean ? '섹터' : 'Sector';
  String get linkLabel => isKorean ? '연결도' : 'Link';
  String get targetLabel => isKorean ? '대상' : 'Target';
  String targetType(String type) {
    if (!isKorean) {
      return type;
    }
    if (type == 'keyword') {
      return '키워드';
    }
    if (type == 'stock') {
      return '종목';
    }
    return type;
  }
  String get avgScoreLabel => isKorean ? '평균 점수' : 'Avg score';
  String get keywordCountLabel => isKorean ? '키워드 수' : 'Keywords';

  String get yesText => isKorean ? '예' : 'yes';
  String get noText => isKorean ? '아니오' : 'no';
  String boolToYesNo(bool value) => value ? yesText : noText;
  String get unavailableText => '-';
  String get insufficientDataText => isKorean ? '데이터 부족' : 'insufficient data';

  String get addToWatchlistAction => isKorean ? '관심목록에 추가' : 'Add To Watchlist';
  String get addingToWatchlistAction => isKorean ? '추가 중...' : 'Adding...';
  String get addedToWatchlistMessage => isKorean ? '관심목록에 추가했습니다.' : 'Added to watchlist.';
  String get watchlistUpdateNoConfirmationMessage => isKorean
      ? '관심목록 요청은 완료되었지만 확인 응답이 없습니다.'
      : 'Watchlist update completed without confirmation.';
  String watchlistUpdateFailedMessage(String detail) {
    if (isKorean) {
      return '관심목록 업데이트에 실패했습니다: $detail';
    }
    return 'Failed to update watchlist: $detail';
  }
}
