import 'package:flutter/material.dart';

import '../../core/localization/app_localization.dart';
import '../../core/models/api_models.dart';
import '../../core/repositories/signaldesk_repository.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/loadable_controller.dart';
import '../shared/data_freshness_banner.dart';
import '../shared/loadable_view.dart';
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
    final strings = AppLanguageScope.stringsOf(context);

    return SignalDeskShell(
      title: strings.watchlistTitle,
      currentRoute: AppRoutes.watchlist,
      child: LoadableView<WatchlistResponse>(
        controller: _controller,
        emptyMessage: strings.noWatchlistData,
        builder: (context, data) {
          final isEmpty = data.keywords.isEmpty && data.stocks.isEmpty;
          if (isEmpty) {
            return RefreshIndicator(
              onRefresh: _controller.refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  DataFreshnessBanner(generatedAt: data.generatedAt),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(strings.noWatchlistData),
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
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                DataFreshnessBanner(generatedAt: data.generatedAt),
                const SizedBox(height: 12),
                Text(
                  strings.keywordsHeader,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...data.keywords.map(
                  (item) => ListTile(
                    title: Text(item.keyword),
                    subtitle: Text(
                      '${strings.scoreLabel} ${item.score?.toStringAsFixed(2) ?? strings.unavailableText} | '
                      '${strings.deltaLabel} ${item.delta1d?.toStringAsFixed(2) ?? strings.unavailableText}\n'
                      '${strings.alertLabel} ${item.isAlertEligible == null ? strings.unavailableText : strings.boolToYesNo(item.isAlertEligible!)} | '
                      '${strings.riskLabel} ${item.riskFlags.isEmpty ? strings.unavailableText : item.riskFlags.join(', ')}',
                    ),
                    isThreeLine: true,
                    trailing: Text(item.severity == null ? strings.unavailableText : strings.severityOption(item.severity)),
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.detail,
                      arguments: item.keywordId,
                    ),
                  ),
                ),
                const Divider(),
                Text(
                  strings.stocksHeader,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...data.stocks.map(
                  (item) => ListTile(
                    title: Text('${item.ticker} | ${item.name}'),
                    subtitle: Text('${strings.marketLabel} ${item.market.toUpperCase()}'),
                    trailing: Text(item.severity == null ? strings.unavailableText : strings.severityOption(item.severity)),
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
