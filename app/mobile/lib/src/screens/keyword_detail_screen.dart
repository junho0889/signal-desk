import 'package:flutter/material.dart';

import '../api/models.dart';
import '../api/signal_desk_api.dart';

class KeywordDetailScreen extends StatelessWidget {
  const KeywordDetailScreen({
    required this.api,
    required this.keywordId,
    super.key,
  });

  static const route = '/detail';

  final SignalDeskApi api;
  final String keywordId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keyword Detail')),
      body: FutureBuilder<KeywordDetailResponse>(
        future: api.getKeywordDetail(keywordId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Detail load failed: ${snapshot.error}'));
          }

          final detail = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Text(detail.keyword, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Score ${detail.scoreSummary.score.toStringAsFixed(1)} | Delta ${detail.scoreSummary.delta1d?.toStringAsFixed(1) ?? '-'}'),
              Text('Confidence ${detail.scoreSummary.confidence.toStringAsFixed(3)}'),
              const SizedBox(height: 12),
              if (detail.reasonBlock != null) Text(detail.reasonBlock!),
              const SizedBox(height: 12),
              Text('Risk flags: ${detail.riskFlags.join(', ')}'),
              const SizedBox(height: 16),
              Text('Related Stocks', style: Theme.of(context).textTheme.titleMedium),
              ...detail.relatedStocks.map(
                (stock) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('${stock.ticker} ${stock.name}'),
                  subtitle: Text('market ${stock.market.name} | conf ${stock.linkConfidence?.toStringAsFixed(2) ?? '-'}'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
