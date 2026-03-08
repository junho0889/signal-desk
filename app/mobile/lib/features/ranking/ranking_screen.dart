import 'package:flutter/material.dart';

import '../../core/models/api_models.dart';
import '../../core/repositories/signaldesk_repository.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/loadable_controller.dart';
import '../shared/data_freshness_banner.dart';
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
  bool _isLoadingNextPage = false;
  Object? _nextPageError;

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

  Future<void> _refreshFirstPage() async {
    if (mounted) {
      setState(() {
        _nextPageError = null;
      });
    }
    await _controller.refresh();
  }

  Future<void> _loadNextPage() async {
    final current = _controller.data;
    final cursor = current?.nextCursor;
    if (current == null || cursor == null || cursor.isEmpty || _isLoadingNextPage) {
      return;
    }
    final requestedPeriod = _period;

    setState(() {
      _isLoadingNextPage = true;
      _nextPageError = null;
    });

    try {
      final nextPage = await widget.repository.fetchKeywords(
        period: requestedPeriod,
        cursor: cursor,
      );
      if (!mounted || _period != requestedPeriod || _controller.data != current) {
        return;
      }
      final merged = widget.repository.mergeKeywordsPages(
        current: current,
        nextPage: nextPage,
      );
      _controller.replaceData(merged);
    } catch (error) {
      if (mounted) {
        setState(() {
          _nextPageError = error;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingNextPage = false;
        });
      }
    }
  }

  Widget _buildPaginationFooter(KeywordsResponse data) {
    final hasMore = data.nextCursor != null && data.nextCursor!.isNotEmpty;

    if (_isLoadingNextPage) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_nextPageError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: <Widget>[
            Text(
              'Could not load next page. ${_nextPageError.toString()}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _loadNextPage,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: OutlinedButton(
          onPressed: _loadNextPage,
          child: const Text('Load More'),
        ),
      );
    }

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(child: Text('End of ranking results')),
    );
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
                      _nextPageError = null;
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
                  onRefresh: _refreshFirstPage,
                  child: ListView.builder(
                    itemCount: data.items.length + 2,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return DataFreshnessBanner(
                          generatedAt: data.generatedAt,
                          staleAfter: FreshnessPolicy.forPeriod(_period),
                        );
                      }

                      if (index == data.items.length + 1) {
                        return _buildPaginationFooter(data);
                      }

                      final item = data.items[index - 1];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
