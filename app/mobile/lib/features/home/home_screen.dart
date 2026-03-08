import 'package:flutter/material.dart';

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
    return SignalDeskShell(
      title: 'SignalDesk Home',
      currentRoute: AppRoutes.home,
      child: LoadableView<DashboardResponse>(
        controller: _controller,
        emptyMessage: 'No dashboard data is available yet.',
        isEmpty: (data) =>
            data.topKeywords.isEmpty &&
            data.hotSectors.isEmpty &&
            data.riskAlerts.isEmpty,
        builder: (context, data) {
          return RefreshIndicator(
            onRefresh: _controller.refresh,
            child: ListView(
              children: <Widget>[
                DataFreshnessBanner(generatedAt: data.generatedAt),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Top Keywords',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                ...data.topKeywords.map((item) {
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      title: Text(item.keyword),
                      subtitle: Text(
                        'Score ${item.score.toStringAsFixed(2)} | '
                        'Delta ${item.delta1d?.toStringAsFixed(2) ?? '-'} | '
                        'Confidence ${item.confidence.toStringAsFixed(3)}\n'
                        'Alert ${item.isAlertEligible ? 'yes' : 'no'} | '
                        'Reasons ${item.reasonTags.isEmpty ? '-' : item.reasonTags.join(', ')}\n'
                        'Risk ${item.riskFlags.isEmpty ? '-' : item.riskFlags.join(', ')}',
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Sector Movers',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                ...data.hotSectors.map((sector) {
                  return ListTile(
                    dense: true,
                    title: Text(sector.sector),
                    subtitle: Text(
                      'Keywords ${sector.keywordCount} | '
                      'Avg score ${sector.avgScore.toStringAsFixed(2)}',
                    ),
                    trailing: Text(sector.delta1d?.toStringAsFixed(2) ?? '-'),
                  );
                }),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Recent Alerts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                ...data.riskAlerts.map((alert) {
                  return ListTile(
                    dense: true,
                    title: Text(alert.message),
                    subtitle: Text(
                      '${alert.severity.toUpperCase()} | '
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
