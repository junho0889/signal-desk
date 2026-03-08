import 'package:flutter/material.dart';

import '../../core/localization/app_localization.dart';
import '../../core/models/api_models.dart';
import '../../core/repositories/signaldesk_repository.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/loadable_controller.dart';
import '../shared/data_freshness_banner.dart';
import '../shared/loadable_view.dart';
import '../shared/signal_desk_shell.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository});

  final SignalDeskRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final LoadableController<DashboardResponse> _controller;

  @override
  void initState() {
    super.initState();
    _controller = LoadableController<DashboardResponse>(
      loader: widget.repository.fetchDashboard,
    );
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLanguageScope.stringsOf(context);

    return SignalDeskShell(
      title: strings.homeTitle,
      currentRoute: AppRoutes.home,
      child: LoadableView<DashboardResponse>(
        controller: _controller,
        emptyMessage: strings.noDashboardData,
        builder: (context, data) {
          final isEmpty =
              data.topKeywords.isEmpty &&
              data.hotSectors.isEmpty &&
              data.riskAlerts.isEmpty;

          if (isEmpty) {
            return RefreshIndicator(
              onRefresh: _controller.refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: <Widget>[
                  DataFreshnessBanner(generatedAt: data.generatedAt),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(strings.noDashboardData),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _controller.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: <Widget>[
                DataFreshnessBanner(generatedAt: data.generatedAt),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    strings.topKeywordsHeader,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                ...data.topKeywords.map((item) {
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      title: Text(item.keyword),
                      subtitle: Text(
                        '${strings.scoreLabel} ${item.score.toStringAsFixed(2)} | '
                        '${strings.deltaLabel} ${item.delta1d?.toStringAsFixed(2) ?? strings.unavailableText} | '
                        '${strings.confidenceLabel} ${item.confidence.toStringAsFixed(3)}\n'
                        '${strings.alertLabel} ${strings.boolToYesNo(item.isAlertEligible)} | '
                        '${strings.reasonsLabel} ${item.reasonTags.isEmpty ? strings.unavailableText : item.reasonTags.join(', ')}\n'
                        '${strings.riskLabel} ${item.riskFlags.isEmpty ? strings.unavailableText : item.riskFlags.join(', ')}',
                      ),
                      isThreeLine: true,
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.detail,
                        arguments: item.keywordId,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    strings.sectorMoversHeader,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                ...data.hotSectors.map((sector) {
                  return ListTile(
                    dense: true,
                    title: Text(sector.sector),
                    subtitle: Text(
                      '${strings.keywordCountLabel} ${sector.keywordCount} | '
                      '${strings.avgScoreLabel} ${sector.avgScore.toStringAsFixed(2)}',
                    ),
                    trailing: Text(sector.delta1d?.toStringAsFixed(2) ?? '-'),
                  );
                }),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    strings.recentAlertsHeader,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                ...data.riskAlerts.map((alert) {
                  final severity = strings.isKorean
                      ? strings.severityOption(alert.severity)
                      : alert.severity.toUpperCase();
                  return ListTile(
                    dense: true,
                    title: Text(alert.message),
                    subtitle: Text(
                      '$severity | '
                      '${alert.triggeredAt.toIso8601String()}',
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
