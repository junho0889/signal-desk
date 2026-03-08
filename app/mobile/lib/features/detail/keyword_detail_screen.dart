import 'package:flutter/material.dart';

import '../../core/localization/app_localization.dart';
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
    final strings = AppLanguageScope.stringsOf(context);

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
                ? strings.addedToWatchlistMessage
                : strings.watchlistUpdateNoConfirmationMessage,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is ApiException ? error.message : error.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.watchlistUpdateFailedMessage(message))),
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
    final strings = AppLanguageScope.stringsOf(context);

    return SignalDeskShell(
      title: strings.detailTitle,
      currentRoute: AppRoutes.ranking,
      child: LoadableView<KeywordDetailResponse>(
        controller: _controller,
        emptyMessage: strings.noKeywordDetail,
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
                Text('${strings.scoreLabel}: ${data.scoreSummary.score.toStringAsFixed(2)}'),
                Text(
                  '${strings.delta24hLabel}: '
                  '${data.scoreSummary.delta1d?.toStringAsFixed(2) ?? strings.unavailableText}',
                ),
                Text('${strings.confidenceLabel}: ${data.scoreSummary.confidence.toStringAsFixed(3)}'),
                Text(
                  '${strings.alertEligibleLabel}: '
                  '${strings.boolToYesNo(data.scoreSummary.isAlertEligible)}',
                ),
                const SizedBox(height: 12),
                Text(
                  '${strings.reasonLabel}: '
                  '${data.reasonBlock == null || data.reasonBlock!.isEmpty ? strings.insufficientDataText : data.reasonBlock!}',
                ),
                const SizedBox(height: 12),
                Text(
                  '${strings.riskFlagsLabel}: '
                  '${data.riskFlags.isEmpty ? strings.unavailableText : data.riskFlags.join(', ')}',
                ),
                const SizedBox(height: 12),
                Text(
                  '${strings.relatedSectorsLabel}: '
                  '${data.relatedSectors.isEmpty ? strings.unavailableText : data.relatedSectors.join(', ')}',
                ),
                const SizedBox(height: 12),
                Text(
                  strings.relatedStocksHeader,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ...data.relatedStocks.map(
                  (stock) => ListTile(
                    dense: true,
                    title: Text('${stock.ticker} | ${stock.name}'),
                    subtitle: Text(
                      '${strings.marketLabel} ${stock.market.toUpperCase()} | '
                      '${strings.sectorLabel} ${stock.sector ?? strings.unavailableText} | '
                      '${strings.linkLabel} ${stock.linkConfidence?.toStringAsFixed(3) ?? strings.unavailableText}',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _watchlistUpdating
                      ? null
                      : () => _addToWatchlist(data.keywordId),
                  child: Text(
                    _watchlistUpdating
                        ? strings.addingToWatchlistAction
                        : strings.addToWatchlistAction,
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
