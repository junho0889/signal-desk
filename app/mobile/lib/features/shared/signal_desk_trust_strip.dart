import 'package:flutter/material.dart';

import '../../src/signal_desk_localizations.dart';
import 'premium_tokens.dart';
import 'signal_desk_formatters.dart';

class SignalDeskTrustStrip extends StatelessWidget {
  const SignalDeskTrustStrip({
    super.key,
    required this.confidence,
    required this.isAlertEligible,
    required this.riskFlags,
  });

  final double confidence;
  final bool isAlertEligible;
  final List<String> riskFlags;

  @override
  Widget build(BuildContext context) {
    final l10n = SignalDeskLocalizations.of(context);
    final trustColor = confidence >= 0.75
        ? SignalDeskPalette.trustHigh
        : confidence >= 0.5
            ? SignalDeskPalette.trustMid
            : SignalDeskPalette.trustLow;

    return Wrap(
      spacing: SignalDeskSpacing.s4,
      runSpacing: SignalDeskSpacing.s4,
      children: <Widget>[
        _buildChip(
          context,
          '${l10n.confidenceLabel} ${SignalDeskFormatters.confidence(confidence)}',
          trustColor,
        ),
        _buildChip(
          context,
          isAlertEligible ? l10n.alertReadyLabel : l10n.alertHoldLabel,
          isAlertEligible ? Colors.indigo : Colors.grey,
        ),
        if (riskFlags.isNotEmpty)
          ...riskFlags.take(2).map(
                (risk) => _buildChip(context, risk, SignalDeskPalette.risk),
              ),
      ],
    );
  }

  Widget _buildChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SignalDeskSpacing.s8,
        vertical: SignalDeskSpacing.s4,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
