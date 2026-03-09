import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/api_models.dart';
import '../../core/network/api_exception.dart';
import '../../core/repositories/signaldesk_repository.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/loadable_controller.dart';
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

  Future<void> _copyLink(String rawUrl) async {
    await Clipboard.setData(ClipboardData(text: rawUrl));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Source link copied.')),
    );
  }

  void _showNewsDetail(RelatedNewsItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('Source: ${item.sourceName}'),
                Text('Published: ${item.publishedAt.toIso8601String()}'),
                if (item.relevanceScore != null)
                  Text('Relevance: ${item.relevanceScore!.toStringAsFixed(3)}'),
                const SizedBox(height: 12),
                SelectableText(item.url),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _copyLink(item.url),
                    child: const Text('Copy Source Link'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
                  'Related news (sources)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (data.relatedNews.isEmpty)
                  const ListTile(
                    dense: true,
                    title: Text('No related news sources available.'),
                  ),
                ...data.relatedNews.map(
                  (news) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(news.title),
                    subtitle: Text(
                      '${news.sourceName} | ${news.publishedAt.toIso8601String()}\n${news.url}',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _showNewsDetail(news),
                  ),
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
