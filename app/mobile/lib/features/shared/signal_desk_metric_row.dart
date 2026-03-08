import 'package:flutter/material.dart';

import '../../src/signal_desk_localizations.dart';
import 'premium_tokens.dart';
import 'signal_desk_formatters.dart';
import 'signal_desk_freshness_badge.dart';
import 'signal_desk_trend_chart_card.dart';
import 'signal_desk_trust_strip.dart';

class SignalDeskMetricRow extends StatelessWidget {
  const SignalDeskMetricRow({
    super.key,
    required this.title,
    required this.score,
    required this.delta1d,
    required this.confidence,
    required this.generatedAt,
    required this.isAlertEligible,
    required this.riskFlags,
    required this.supportingText,
    required this.onTap,
    this.rank,
    this.trendPoints,
  });

  final int? rank;
  final String title;
  final double? score;
  final double? delta1d;
  final double confidence;
  final DateTime generatedAt;
  final bool isAlertEligible;
  final List<String> riskFlags;
  final String supportingText;
  final VoidCallback onTap;
  final List<double>? trendPoints;

  @override
  Widget build(BuildContext context) {
    final deltaColor = (delta1d ?? 0) >= 0
        ? SignalDeskPalette.momentumUp
        : SignalDeskPalette.momentumDown;
    final l10n = SignalDeskLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: SignalDeskSpacing.s8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SignalDeskShape.radiusCard),
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(SignalDeskShape.radiusCard),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 108),
          child: Padding(
            padding: const EdgeInsets.all(SignalDeskSpacing.s12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    if (rank != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SignalDeskSpacing.s8,
                          vertical: SignalDeskSpacing.s4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '#$rank',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    if (rank != null)
                      const SizedBox(width: SignalDeskSpacing.s8),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                    const SizedBox(width: SignalDeskSpacing.s8),
                    const Icon(Icons.chevron_right, size: 18),
                  ],
                ),
                const SizedBox(height: SignalDeskSpacing.s8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: SignalDeskTrustStrip(
                        confidence: confidence,
                        isAlertEligible: isAlertEligible,
                        riskFlags: riskFlags,
                      ),
                    ),
                    const SizedBox(width: SignalDeskSpacing.s8),
                    SignalDeskFreshnessBadge(timestamp: generatedAt),
                  ],
                ),
                const SizedBox(height: SignalDeskSpacing.s8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${l10n.scoreLabel} ${SignalDeskFormatters.score(score)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: SignalDeskSpacing.s4),
                          Text(
                            '${l10n.deltaLabel} ${SignalDeskFormatters.delta(delta1d)}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: deltaColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 96,
                      height: 36,
                      child: SignalDeskTrendChartCard(
                        points:
                            trendPoints ?? _buildTrendFallback(score, delta1d),
                        title: '',
                        height: 36,
                        compact: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SignalDeskSpacing.s8),
                Text(
                  supportingText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<double> _buildTrendFallback(double? scoreValue, double? deltaValue) {
    if (scoreValue == null || deltaValue == null) {
      return const <double>[0, 0];
    }
    return <double>[scoreValue - deltaValue, scoreValue];
  }
}
