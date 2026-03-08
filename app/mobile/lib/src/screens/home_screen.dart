import 'package:flutter/material.dart';

import '../api/models.dart';
import '../api/signal_desk_api.dart';
import 'alerts_screen.dart';
import 'keyword_detail_screen.dart';
import 'keyword_ranking_screen.dart';
import 'watchlist_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.api, super.key});

  static const route = '/';

  final SignalDeskApi api;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SignalDesk Home'),
        actions: <Widget>[
          IconButton(
            onPressed: () => Navigator.pushNamed(context, KeywordRankingScreen.route),
            icon: const Icon(Icons.leaderboard_outlined),
            tooltip: 'Ranking',
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, WatchlistScreen.route),
            icon: const Icon(Icons.bookmark_outline),
            tooltip: 'Watchlist',
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AlertsScreen.route),
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Alerts',
          ),
        ],
      ),
      body: FutureBuilder<DashboardResponse>(
        future: api.getDashboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Dashboard load failed: ${snapshot.error}'));
          }
          final dashboard = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Text('Updated ${dashboard.generatedAt}', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 16),
              Text('Top Keywords', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...dashboard.topKeywords.map(
                (item) => Card(
                  child: ListTile(
                    title: Text(item.keyword),
                    subtitle: Text('score ${item.score.toStringAsFixed(1)} | delta ${item.delta1d?.toStringAsFixed(1) ?? '-'}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(
                      context,
                      KeywordDetailScreen.route,
                      arguments: item.keywordId,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Sector Movers', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...dashboard.hotSectors.map(
                (item) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.sector),
                  subtitle: Text('keywords ${item.keywordCount} | avg ${item.avgScore.toStringAsFixed(1)}'),
                ),
              ),
              const SizedBox(height: 16),
              Text('Alert Summary', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...dashboard.riskAlerts.map(
                (item) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.message),
                  subtitle: Text('${item.severity.name} | ${item.triggeredAt}'),
                  onTap: () => Navigator.pushNamed(context, AlertsScreen.route),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
