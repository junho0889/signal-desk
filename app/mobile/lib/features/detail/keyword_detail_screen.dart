import 'package:flutter/material.dart';

import '../../core/models/api_models.dart';
import '../../core/network/api_exception.dart';
import '../../core/repositories/signaldesk_repository.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/loadable_controller.dart';
import '../shared/data_freshness_banner.dart';
import '../shared/loadable_view.dart';
import '../shared/signal_desk_shell.dart';

class KeywordDetailScreen extends StatefulWidget {
  const KeywordDetailScreen({
    super.key,
    required this.repository,
    required this.keywordId,
  });

  final SignalDeskRepository repository;
  final String keywordId;

  @override
  State<KeywordDetailScreen> createState() => _KeywordDetailScreenState();
}

class _KeywordDetailScreenState extends State<KeywordDetailScreen> {
  late final LoadableController<KeywordDetailResponse> _controller;
  bool _watchlistUpdating = false;

  @override
  void initState() {
    super.initState();
    _controller = LoadableController<KeywordDetailResponse>(
      loader: () => widget.repository.fetchKeywordDetail(widget.keywordId),
    );
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addToWatchlist(String keywordId) async {
    setState(() {
      _watchlistUpdating = true;
    });

    try {
      final ok = await widget.repository.addKeywordToWatchlist(keywordId);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Added to watchlist.'
                : 'Watchlist update completed without confirmation.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is ApiException ? error.message : error.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update watchlist: $message')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _watchlistUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SignalDeskShell(
      title: 'Keyword Detail',
      currentRoute: AppRoutes.ranking,
      child: LoadableView<KeywordDetailResponse>(
        controller: _controller,
        emptyMessage: 'No keyword detail is available.',
        builder: (context, data) {
          return RefreshIndicator(
            onRefresh: _controller.refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                DataFreshnessBanner(
                  generatedAt: data.generatedAt,
                  staleAfter: FreshnessPolicy.defaultStaleAfter,
                ),
                const SizedBox(height: 12),
                Text(data.keyword, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text('Score: ${data.scoreSummary.score.toStringAsFixed(2)}'),
                Text('Delta 24h: ${data.scoreSummary.delta1d?.toStringAsFixed(2) ?? '-'}'),
                Text('Confidence: ${data.scoreSummary.confidence.toStringAsFixed(3)}'),
                Text('Alert eligible: ${data.scoreSummary.isAlertEligible ? 'yes' : 'no'}'),
                const SizedBox(height: 12),
                Text(
                  'Reason: ${data.reasonBlock == null || data.reasonBlock!.isEmpty ? 'insufficient data' : data.reasonBlock!}',
                ),
                const SizedBox(height: 12),
                Text(
                  'Risk flags: ${data.riskFlags.isEmpty ? '-' : data.riskFlags.join(', ')}',
                ),
                const SizedBox(height: 12),
                Text(
                  'Related sectors: ${data.relatedSectors.isEmpty ? '-' : data.relatedSectors.join(', ')}',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Related stocks',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...data.relatedStocks.map(
                  (stock) => ListTile(
                    dense: true,
                    title: Text('${stock.ticker} | ${stock.name}'),
                    subtitle: Text(
                      'Market ${stock.market.toUpperCase()} | '
                      'Sector ${stock.sector ?? '-'} | '
                      'Link ${stock.linkConfidence?.toStringAsFixed(3) ?? '-'}',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _watchlistUpdating
                      ? null
                      : () => _addToWatchlist(data.keywordId),
                  child: Text(
                    _watchlistUpdating ? 'Adding...' : 'Add To Watchlist',
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
