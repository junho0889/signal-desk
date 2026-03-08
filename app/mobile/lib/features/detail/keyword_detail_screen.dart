import 'package:flutter/material.dart';

import '../../core/models/api_models.dart';
import '../../core/network/signaldesk_api_client.dart';
import '../../core/routes/app_routes.dart';
import '../shared/signal_desk_shell.dart';

class KeywordDetailScreen extends StatelessWidget {
  const KeywordDetailScreen({
    super.key,
    required this.apiClient,
    required this.keywordId,
  });

  final SignalDeskApiClient apiClient;
  final String keywordId;

  @override
  Widget build(BuildContext context) {
    return SignalDeskShell(
      title: 'Keyword Detail',
      currentRoute: AppRoutes.ranking,
      child: FutureBuilder<KeywordDetailResponse>(
        future: apiClient.getKeywordDetail(keywordId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load detail: ${snapshot.error}'));
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('No detail data.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Text(data.keyword, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text('Score: ${data.scoreSummary.score.toStringAsFixed(2)}'),
              Text('Delta 24h: ${data.scoreSummary.delta1d?.toStringAsFixed(2) ?? '-'}'),
              Text('Confidence: ${data.scoreSummary.confidence.toStringAsFixed(3)}'),
              Text('Alert eligible: ${data.scoreSummary.isAlertEligible}'),
              const SizedBox(height: 12),
              if (data.reasonBlock != null) Text('Reason: ${data.reasonBlock}'),
              const SizedBox(height: 12),
              Text('Risk flags: ${data.riskFlags.isEmpty ? '-' : data.riskFlags.join(', ')}'),
              const SizedBox(height: 12),
              const Text('Related stocks', style: TextStyle(fontWeight: FontWeight.bold)),
              ...data.relatedStocks.map((stock) => ListTile(
                    dense: true,
                    title: Text('${stock.ticker} | ${stock.name}'),
                    subtitle: Text('Market ${stock.market.toUpperCase()} | Sector ${stock.sector ?? '-'}'),
                  )),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  await apiClient.updateWatchlist(
                    op: 'add',
                    targetType: 'keyword',
                    targetId: data.keywordId,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Added to watchlist (baseline flow).')),
                    );
                  }
                },
                child: const Text('Add To Watchlist'),
              ),
            ],
          );
        },
      ),
    );
  }
}

