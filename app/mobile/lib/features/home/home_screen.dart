import 'package:flutter/material.dart';

import '../../core/models/api_models.dart';
import '../../core/repositories/signaldesk_repository.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/loadable_controller.dart';
import '../../src/signal_desk_localizations.dart';
import '../shared/loadable_view.dart';
import '../shared/premium_tokens.dart';
import '../shared/signal_desk_context_rail.dart';
import '../shared/signal_desk_formatters.dart';
import '../shared/signal_desk_metric_row.dart';
import '../shared/signal_desk_section_card.dart';
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
    final l10n = SignalDeskLocalizations.of(context);

    return SignalDeskShell(
      title: l10n.homeTitle,
      currentRoute: AppRoutes.home,
      contextRail: _controller.data == null
          ? null
          : SignalDeskContextRail(generatedAt: _controller.data!.generatedAt),
      child: LoadableView<DashboardResponse>(
        controller: _controller,
        generatedAt: (data) => data.generatedAt,
        emptyMessage: l10n.dashboardEmptyMessage,
        isEmpty: (data) =>
            data.topKeywords.isEmpty &&
            data.hotSectors.isEmpty &&
            data.riskAlerts.isEmpty,
        builder: (context, data) {
          return RefreshIndicator(
            onRefresh: _controller.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                SignalDeskSpacing.s16,
                SignalDeskSpacing.s16,
                SignalDeskSpacing.s16,
                SignalDeskSpacing.s24,
              ),
              children: <Widget>[
                SignalDeskSectionCard(
                  title: l10n.topKeywords,
                  child: Column(
                    children: data.topKeywords
                        .asMap()
                        .entries
                        .map(
                          (entry) => SignalDeskMetricRow(
                            rank: entry.key + 1,
                            title: entry.value.keyword,
                            score: entry.value.score,
                            delta1d: entry.value.delta1d,
                            confidence: entry.value.confidence,
                            generatedAt: data.generatedAt,
                            isAlertEligible: entry.value.isAlertEligible,
                            riskFlags: entry.value.riskFlags,
                            supportingText: entry.value.reasonTags.isEmpty
                                ? '-'
                                : entry.value.reasonTags.join(', '),
                            onTap: () => Navigator.of(context).pushNamed(
                              AppRoutes.detail,
                              arguments: entry.value.keywordId,
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
                SignalDeskSectionCard(
                  title: l10n.sectorMovers,
                  child: Column(
                    children: data.hotSectors
                        .map(
                          (sector) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(sector.sector),
                            subtitle: Text(
                              '${l10n.keywordCountLabel(sector.keywordCount)} | '
                              '${l10n.scoreLabel} ${SignalDeskFormatters.score(sector.avgScore)}',
                            ),
                            trailing: Text(
                              SignalDeskFormatters.delta(sector.delta1d),
                              style: TextStyle(
                                color: (sector.delta1d ?? 0) >= 0
                                    ? SignalDeskPalette.momentumUp
                                    : SignalDeskPalette.momentumDown,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
                SignalDeskSectionCard(
                  title: l10n.recentAlerts,
                  child: Column(
                    children: data.riskAlerts
                        .map(
                          (alert) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              alert.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${l10n.severityLabel(alert.severity)} | '
                              '${SignalDeskFormatters.relativeAge(context, alert.triggeredAt)}',
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
