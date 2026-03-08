import 'package:flutter/material.dart';

import '../../core/models/api_models.dart';
import '../../core/repositories/signaldesk_repository.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/loadable_controller.dart';
import '../shared/loadable_view.dart';
import '../shared/signal_desk_shell.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key, required this.repository});

  final SignalDeskRepository repository;

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  late final LoadableController<KeywordsResponse> _controller;
  String _period = 'daily';

  @override
  void initState() {
    super.initState();
    _controller = LoadableController<KeywordsResponse>(
      loader: () => widget.repository.fetchKeywords(period: _period),
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
                      .map(
                        (value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null || value == _period) {
                      return;
                    }
                    setState(() {
                      _period = value;
                    });
                    _controller.refresh();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: LoadableView<KeywordsResponse>(
              controller: _controller,
              emptyMessage: 'No ranking data is available for this filter.',
              isEmpty: (data) => data.items.isEmpty,
              builder: (context, data) {
                return RefreshIndicator(
                  onRefresh: _controller.refresh,
                  child: ListView.builder(
                    itemCount: data.items.length,
                    itemBuilder: (context, index) {
                      final item = data.items[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ListTile(
                          title: Text('#${item.rankPosition} ${item.keyword}'),
                          subtitle: Text(
                            'Score ${item.score.toStringAsFixed(2)} | '
                            'Delta ${item.delta1d?.toStringAsFixed(2) ?? '-'}\n'
                            'Confidence ${item.confidence.toStringAsFixed(3)} | '
                            'Alert ${item.isAlertEligible ? 'yes' : 'no'}\n'
                            'Reasons ${item.reasonTags.isEmpty ? '-' : item.reasonTags.join(', ')}\n'
                            'Risk ${item.riskFlags.isEmpty ? '-' : item.riskFlags.join(', ')}',
                          ),
                          isFourLine: true,
                          onTap: () => Navigator.of(context).pushNamed(
                            AppRoutes.detail,
                            arguments: item.keywordId,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
