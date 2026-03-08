import 'package:flutter/material.dart';

import '../api/models.dart';
import '../api/signal_desk_api.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({required this.api, super.key});

  static const route = '/watchlist';

  final SignalDeskApi api;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Watchlist')),
      body: FutureBuilder<WatchlistResponse>(
        future: api.getWatchlist(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Watchlist load failed: ${snapshot.error}'));
          }

          final watchlist = snapshot.data!;
          return DefaultTabController(
            length: 2,
            child: Column(
              children: <Widget>[
                const TabBar(tabs: <Tab>[Tab(text: 'Keywords'), Tab(text: 'Stocks')]),
                Expanded(
                  child: TabBarView(
                    children: <Widget>[
                      ListView(
                        children: watchlist.keywords
                            .map(
                              (item) => ListTile(
                                title: Text(item.keyword),
                                subtitle: Text('score ${item.score?.toStringAsFixed(1) ?? '-'} | severity ${item.severity?.name ?? '-'}'),
                              ),
                            )
                            .toList(),
                      ),
                      ListView(
                        children: watchlist.stocks
                            .map(
                              (item) => ListTile(
                                title: Text('${item.ticker} ${item.name}'),
                                subtitle: Text('market ${item.market.name} | severity ${item.severity?.name ?? '-'}'),
                              ),
                            )
                            .toList(),
                      ),
                    ],
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
