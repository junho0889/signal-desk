import 'package:flutter/material.dart';

import '../../core/models/api_models.dart';
import '../../core/network/api_exception.dart';
import '../../core/repositories/signaldesk_repository.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/loadable_controller.dart';
import '../../src/signal_desk_localizations.dart';
import '../shared/loadable_view.dart';
import '../shared/premium_tokens.dart';
import '../shared/signal_desk_context_rail.dart';
import '../shared/signal_desk_formatters.dart';
import '../shared/signal_desk_freshness_badge.dart';
import '../shared/signal_desk_risk_callout.dart';
import '../shared/signal_desk_section_card.dart';
import '../shared/signal_desk_shell.dart';
import '../shared/signal_desk_trend_chart_card.dart';
import '../shared/signal_desk_trust_strip.dart';

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

    final l10n = SignalDeskLocalizations.of(context);

    try {
      final ok = await widget.repository.addKeywordToWatchlist(keywordId);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? l10n.watchlistAdded : l10n.watchlistPendingConfirm,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is ApiException ? error.message : error.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.watchlistUpdateFailedPrefix} $message')),
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
    final l10n = SignalDeskLocalizations.of(context);

    return SignalDeskShell(
      title: l10n.detailTitle,
      currentRoute: AppRoutes.ranking,
      contextRail: _controller.data == null
          ? null
          : SignalDeskContextRail(generatedAt: _controller.data!.generatedAt),
      primaryAction: _controller.data == null
          ? null
          : FilledButton(
              onPressed: _watchlistUpdating
                  ? null
                  : () => _addToWatchlist(_controller.data!.keywordId),
              child: Text(
                _watchlistUpdating ? l10n.addingWatchlist : l10n.addWatchlist,
              ),
            ),
      child: LoadableView<KeywordDetailResponse>(
        controller: _controller,
        generatedAt: (data) => data.generatedAt,
        emptyMessage: l10n.detailEmptyMessage,
        builder: (context, data) {
          return RefreshIndicator(
            onRefresh: _controller.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                SignalDeskSpacing.s16,
                SignalDeskSpacing.s16,
                SignalDeskSpacing.s16,
                SignalDeskSpacing.s24,
              ),
              children: <Widget>[
                SignalDeskSectionCard(
                  title: data.keyword,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _kpiTile(
                              context,
                              label: l10n.scoreLabel,
                              value: SignalDeskFormatters.score(
                                data.scoreSummary.score,
                              ),
                              toneColor: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: SignalDeskSpacing.s8),
                          Expanded(
                            child: _kpiTile(
                              context,
                              label: l10n.deltaLabel,
                              value: SignalDeskFormatters.delta(
                                data.scoreSummary.delta1d,
                              ),
                              toneColor: (data.scoreSummary.delta1d ?? 0) >= 0
                                  ? SignalDeskPalette.momentumUp
                                  : SignalDeskPalette.momentumDown,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: SignalDeskSpacing.s8),
                      _kpiTile(
                        context,
                        label: l10n.confidenceLabel,
                        value: SignalDeskFormatters.confidence(
                          data.scoreSummary.confidence,
                        ),
                        toneColor: SignalDeskPalette.trustHigh,
                      ),
                      const SizedBox(height: SignalDeskSpacing.s8),
                      SignalDeskTrustStrip(
                        confidence: data.scoreSummary.confidence,
                        isAlertEligible: data.scoreSummary.isAlertEligible,
                        riskFlags: data.riskFlags,
                      ),
                      const SizedBox(height: SignalDeskSpacing.s8),
                      SignalDeskFreshnessBadge(timestamp: data.generatedAt),
                    ],
                  ),
                ),
                SignalDeskRiskCallout(riskFlags: data.riskFlags),
                SignalDeskSectionCard(
                  title: l10n.scoreConfidenceTrendTitle,
                  child: SignalDeskTrendChartCard(
                    title: l10n.scoreConfidenceTrendTitle,
                    points: data.timeseries
                        .map((point) => point.score)
                        .toList(growable: false),
                  ),
                ),
                SignalDeskSectionCard(
                  title: l10n.reasonLabel,
                  child: Text(
                    data.reasonBlock == null || data.reasonBlock!.isEmpty
                        ? l10n.insufficientDataMessage
                        : data.reasonBlock!,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                SignalDeskSectionCard(
                  title: l10n.dimensionContributionsTitle,
                  child: Column(
                    children: <Widget>[
                      _dimensionRow(context, l10n.mentionsLabel,
                          data.scoreSummary.dimensionMentions),
                      _dimensionRow(context, l10n.trendsLabel,
                          data.scoreSummary.dimensionTrends),
                      _dimensionRow(context, l10n.marketLabel,
                          data.scoreSummary.dimensionMarket),
                      _dimensionRow(context, l10n.eventsLabel,
                          data.scoreSummary.dimensionEvents),
                      _dimensionRow(context, l10n.persistenceLabel,
                          data.scoreSummary.dimensionPersistence),
                    ],
                  ),
                ),
                SignalDeskSectionCard(
                  title: l10n.relatedStocksSectorsTitle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ...data.relatedStocks.map(
                        (stock) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text('${stock.ticker} | ${stock.name}'),
                          subtitle: Text(
                            '${stock.market.toUpperCase()} | ${stock.sector ?? '-'} | ${SignalDeskFormatters.confidence(stock.linkConfidence ?? 0)}',
                          ),
                        ),
                      ),
                      if (data.relatedSectors.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.only(top: SignalDeskSpacing.s8),
                          child: Wrap(
                            spacing: SignalDeskSpacing.s8,
                            runSpacing: SignalDeskSpacing.s8,
                            children: data.relatedSectors
                                .map(
                                  (sector) => Chip(
                                    label: Text(
                                      sector,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _dimensionRow(BuildContext context, String label, double? value) {
    final normalized = (value ?? 0).clamp(0, 100) / 100;
    return Padding(
      padding: const EdgeInsets.only(bottom: SignalDeskSpacing.s8),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                  child: Text(label,
                      style: Theme.of(context).textTheme.bodySmall)),
              Text(value == null ? '-' : value.toStringAsFixed(2)),
            ],
          ),
          const SizedBox(height: SignalDeskSpacing.s4),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: normalized),
          ),
        ],
      ),
    );
  }

  Widget _kpiTile(
    BuildContext context, {
    required String label,
    required String value,
    required Color toneColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SignalDeskSpacing.s8,
        vertical: SignalDeskSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: toneColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(SignalDeskShape.radiusSecondary),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: SignalDeskSpacing.s4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: toneColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
