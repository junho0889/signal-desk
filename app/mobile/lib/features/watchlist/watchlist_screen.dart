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

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key, required this.repository});

  final SignalDeskRepository repository;

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  late final LoadableController<WatchlistResponse> _controller;

  @override
  void initState() {
    super.initState();
    _controller = LoadableController<WatchlistResponse>(
      loader: widget.repository.fetchWatchlist,
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
      title: l10n.watchlistTitle,
      currentRoute: AppRoutes.watchlist,
      contextRail: _controller.data == null
          ? null
          : SignalDeskContextRail(generatedAt: _controller.data!.generatedAt),
      child: LoadableView<WatchlistResponse>(
        controller: _controller,
        generatedAt: (data) => data.generatedAt,
        emptyMessage: 'No watchlist items are being tracked yet.',
        isEmpty: (data) => data.keywords.isEmpty && data.stocks.isEmpty,
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
                  title: l10n.isKorean ? '키워드' : 'Keywords',
                  child: Column(
                    children: data.keywords
                        .map(
                          (item) => SignalDeskMetricRow(
                            title: item.keyword,
                            score: item.score,
                            delta1d: item.delta1d,
                            confidence: item.isAlertEligible == true ? 0.8 : 0.5,
                            generatedAt: data.generatedAt,
                            isAlertEligible: item.isAlertEligible ?? false,
                            riskFlags: item.riskFlags,
                            supportingText: item.severity ?? '-',
                            onTap: () => Navigator.of(context).pushNamed(
                              AppRoutes.detail,
                              arguments: item.keywordId,
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
                SignalDeskSectionCard(
                  title: l10n.isKorean ? '종목' : 'Stocks',
                  child: Column(
                    children: data.stocks
                        .map(
                          (item) => Card(
                            shape: SignalDeskShape.secondary,
                            margin: const EdgeInsets.only(bottom: SignalDeskSpacing.s8),
                            child: ListTile(
                              title: Text('${item.ticker} · ${item.name}'),
                              subtitle: Text(item.market.toUpperCase()),
                              trailing: Text(
                                SignalDeskFormatters.severity(item.severity ?? ''),
                              ),
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
