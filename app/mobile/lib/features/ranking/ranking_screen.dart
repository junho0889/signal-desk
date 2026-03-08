import 'package:flutter/material.dart';

import '../../core/models/api_models.dart';
import '../../core/repositories/signaldesk_repository.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/loadable_controller.dart';
import '../../src/signal_desk_localizations.dart';
import '../shared/loadable_view.dart';
import '../shared/premium_tokens.dart';
import '../shared/signal_desk_context_rail.dart';
import '../shared/signal_desk_metric_row.dart';
import '../shared/signal_desk_shell.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key, required this.repository});

  final SignalDeskRepository repository;

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  late final LoadableController<KeywordsResponse> _controller;
  String _period = 'daily';

  static const _periods = <String>['intraday', 'daily', 'weekly'];

  @override
  void initState() {
    super.initState();
    _controller = LoadableController<KeywordsResponse>(
      loader: () => widget.repository.fetchKeywords(period: _period),
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
      title: l10n.rankingTitle,
      currentRoute: AppRoutes.ranking,
      contextRail: _controller.data == null
          ? null
          : SignalDeskContextRail(
              generatedAt: _controller.data!.generatedAt,
              scopeLabel: l10n.periodLabel(_period),
            ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SignalDeskSpacing.s16,
              SignalDeskSpacing.s8,
              SignalDeskSpacing.s16,
              SignalDeskSpacing.s8,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: SignalDeskSpacing.s8,
                children: _periods
                    .map(
                      (value) => ChoiceChip(
                        label: Text(l10n.periodLabel(value)),
                        selected: _period == value,
                        onSelected: (_) {
                          if (_period == value) {
                            return;
                          }
                          setState(() {
                            _period = value;
                          });
                          _controller.refresh();
                        },
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ),
          Expanded(
            child: LoadableView<KeywordsResponse>(
              controller: _controller,
              generatedAt: (data) => data.generatedAt,
              emptyMessage: l10n.rankingEmptyMessage,
              isEmpty: (data) => data.items.isEmpty,
              builder: (context, data) {
                return RefreshIndicator(
                  onRefresh: _controller.refresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      SignalDeskSpacing.s16,
                      0,
                      SignalDeskSpacing.s16,
                      SignalDeskSpacing.s24,
                    ),
                    children: data.items
                        .map(
                          (item) => SignalDeskMetricRow(
                            rank: item.rankPosition,
                            title: item.keyword,
                            score: item.score,
                            delta1d: item.delta1d,
                            confidence: item.confidence,
                            generatedAt: data.generatedAt,
                            isAlertEligible: item.isAlertEligible,
                            riskFlags: item.riskFlags,
                            supportingText: item.reasonTags.isEmpty
                                ? (item.relatedSectors.isEmpty
                                    ? '-'
                                    : item.relatedSectors.join(', '))
                                : item.reasonTags.join(', '),
                            onTap: () => Navigator.of(context).pushNamed(
                              AppRoutes.detail,
                              arguments: item.keywordId,
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
