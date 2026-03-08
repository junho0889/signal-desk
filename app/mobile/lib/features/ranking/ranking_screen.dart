import 'package:flutter/material.dart';

import '../../core/models/api_models.dart';
import '../../core/network/signaldesk_api_client.dart';
import '../../core/routes/app_routes.dart';
import '../shared/signal_desk_shell.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key, required this.apiClient});

  final SignalDeskApiClient apiClient;

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  String _period = 'daily';

  @override
  Widget build(BuildContext context) {
    return SignalDeskShell(
      title: 'Keyword Ranking',
      currentRoute: AppRoutes.ranking,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                const Text('Period:'),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _period,
                  items: const <String>['intraday', 'daily', 'weekly']
                      .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _period = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<KeywordsResponse>(
              future: widget.apiClient.getKeywords(period: _period),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Failed to load rankings: ${snapshot.error}'));
                }

                final data = snapshot.data;
                if (data == null || data.items.isEmpty) {
                  return const Center(child: Text('No ranking data.'));
                }

                return ListView.builder(
                  itemCount: data.items.length,
                  itemBuilder: (context, index) {
                    final item = data.items[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        title: Text('#${item.rankPosition} ${item.keyword}'),
                        subtitle: Text(
                          'Score ${item.score.toStringAsFixed(2)} | '
                          'Confidence ${item.confidence.toStringAsFixed(3)}',
                        ),
                        trailing: Text(item.delta1d?.toStringAsFixed(2) ?? '-'),
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRoutes.detail,
                          arguments: item.keywordId,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

