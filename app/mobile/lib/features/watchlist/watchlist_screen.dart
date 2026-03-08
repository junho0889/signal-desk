import 'package:flutter/material.dart';

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
    return SignalDeskShell(
      title: 'Watchlist',
      currentRoute: AppRoutes.watchlist,
      child: LoadableView<WatchlistResponse>(
        controller: _controller,
        emptyMessage: 'No watchlist items are being tracked yet.',
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
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No watchlist items are being tracked yet.'),
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
                const Text(
                  'Keywords',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...data.keywords.map(
                  (item) => ListTile(
                    title: Text(item.keyword),
                    subtitle: Text(
                      'Score ${item.score?.toStringAsFixed(2) ?? '-'} | '
                      'Delta ${item.delta1d?.toStringAsFixed(2) ?? '-'}\n'
                      'Alert ${item.isAlertEligible == null ? '-' : (item.isAlertEligible! ? 'yes' : 'no')} | '
                      'Risk ${item.riskFlags.isEmpty ? '-' : item.riskFlags.join(', ')}',
                    ),
                    isThreeLine: true,
                    trailing: Text(item.severity ?? '-'),
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.detail,
                      arguments: item.keywordId,
                    ),
                  ),
                ),
                const Divider(),
                const Text(
                  'Stocks',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...data.stocks.map(
                  (item) => ListTile(
                    title: Text('${item.ticker} | ${item.name}'),
                    subtitle: Text('Market ${item.market.toUpperCase()}'),
                    trailing: Text(item.severity ?? '-'),
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
