import 'package:flutter/material.dart';

import '../../core/models/api_models.dart';
import '../../core/network/signaldesk_api_client.dart';
import '../../core/routes/app_routes.dart';
import '../shared/signal_desk_shell.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key, required this.apiClient});

  final SignalDeskApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return SignalDeskShell(
      title: 'Watchlist',
      currentRoute: AppRoutes.watchlist,
      child: FutureBuilder<WatchlistResponse>(
        future: apiClient.getWatchlist(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load watchlist: ${snapshot.error}'));
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('No watchlist data.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              const Text('Keywords', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ...data.keywords.map((item) => ListTile(
                    title: Text(item.keyword),
                    subtitle: Text(
                      'Score ${item.score?.toStringAsFixed(2) ?? '-'} ¡¤ '
                      'Delta ${item.delta1d?.toStringAsFixed(2) ?? '-'}',
                    ),
                    trailing: Text(item.severity ?? '-'),
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.detail,
                      arguments: item.keywordId,
                    ),
                  )),
              const Divider(),
              const Text('Stocks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ...data.stocks.map((item) => ListTile(
                    title: Text('${item.ticker} ¡¤ ${item.name}'),
                    subtitle: Text('Market ${item.market.toUpperCase()}'),
                    trailing: Text(item.severity ?? '-'),
                  )),
            ],
          );
        },
      ),
    );
  }
}
