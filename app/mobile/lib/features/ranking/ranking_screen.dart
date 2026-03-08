import 'package:flutter/material.dart';

import '../../core/localization/app_localization.dart';
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

  Widget _buildPaginationFooter(BuildContext context, KeywordsResponse data) {
    final strings = AppLanguageScope.stringsOf(context);
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
              strings.nextPageLoadError(_nextPageError.toString()),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _loadNextPage,
              child: Text(strings.retryAction),
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
          child: Text(strings.loadMoreAction),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(child: Text(strings.endOfRankingResults)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLanguageScope.stringsOf(context);

    return SignalDeskShell(
      title: strings.rankingTitle,
      currentRoute: AppRoutes.ranking,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                Text(strings.periodLabel),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _period,
                  items: const <String>['intraday', 'daily', 'weekly']
                      .map(
                        (value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(strings.periodOption(value)),
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
              emptyMessage: strings.noRankingData,
              builder: (context, data) {
                if (data.items.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refreshFirstPage,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: <Widget>[
                        DataFreshnessBanner(
                          generatedAt: data.generatedAt,
                          staleAfter: FreshnessPolicy.forPeriod(_period),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(strings.noRankingData),
                            ),
                          ),
                        ),
                        _buildPaginationFooter(context, data),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshFirstPage,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: data.items.length + 2,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return DataFreshnessBanner(
                          generatedAt: data.generatedAt,
                          staleAfter: FreshnessPolicy.forPeriod(_period),
                        );
                      }

                      if (index == data.items.length + 1) {
                        return _buildPaginationFooter(context, data);
                      }

                      final item = data.items[index - 1];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          title: Text('#${item.rankPosition} ${item.keyword}'),
                          subtitle: Text(
                            '${strings.scoreLabel} ${item.score.toStringAsFixed(2)} | '
                            '${strings.deltaLabel} ${item.delta1d?.toStringAsFixed(2) ?? strings.unavailableText}\n'
                            '${strings.confidenceLabel} ${item.confidence.toStringAsFixed(3)} | '
                            '${strings.alertLabel} ${strings.boolToYesNo(item.isAlertEligible)}\n'
                            '${strings.reasonsLabel} ${item.reasonTags.isEmpty ? strings.unavailableText : item.reasonTags.join(', ')}\n'
                            '${strings.riskLabel} ${item.riskFlags.isEmpty ? strings.unavailableText : item.riskFlags.join(', ')}',
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
