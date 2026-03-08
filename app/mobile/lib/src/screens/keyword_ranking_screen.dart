import 'package:flutter/material.dart';

import '../api/models.dart';
import '../api/signal_desk_api.dart';
import 'keyword_detail_screen.dart';

class KeywordRankingScreen extends StatefulWidget {
  const KeywordRankingScreen({required this.api, super.key});

  static const route = '/ranking';

  final SignalDeskApi api;

  @override
  State<KeywordRankingScreen> createState() => _KeywordRankingScreenState();
}

class _KeywordRankingScreenState extends State<KeywordRankingScreen> {
  Period _period = Period.daily;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keyword Ranking')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<Period>(
              segments: const <ButtonSegment<Period>>[
                ButtonSegment(value: Period.intraday, label: Text('intraday')),
                ButtonSegment(value: Period.daily, label: Text('daily')),
                ButtonSegment(value: Period.weekly, label: Text('weekly')),
              ],
              selected: <Period>{_period},
              onSelectionChanged: (value) => setState(() => _period = value.first),
            ),
          ),
          Expanded(
            child: FutureBuilder<KeywordRankingResponse>(
              future: widget.api.getKeywords(period: _period),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Ranking load failed: ${snapshot.error}'));
                }
                final items = snapshot.data!.items;
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text('${item.rankPosition}. ${item.keyword}'),
                      subtitle: Text(
                        'score ${item.score.toStringAsFixed(1)} | conf ${item.confidence.toStringAsFixed(3)} | alert ${item.isAlertEligible ? 'yes' : 'no'}',
                      ),
                      trailing: Text(item.delta1d?.toStringAsFixed(1) ?? '-'),
                      onTap: () => Navigator.pushNamed(
                        context,
                        KeywordDetailScreen.route,
                        arguments: item.keywordId,
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
