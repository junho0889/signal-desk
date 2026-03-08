import 'package:flutter/material.dart';

import '../../src/signal_desk_localizations.dart';
import 'premium_tokens.dart';
import 'signal_desk_formatters.dart';

enum FreshnessBand {
  live,
  recent,
  aging,
  stale,
}

class SignalDeskFreshnessBadge extends StatelessWidget {
  const SignalDeskFreshnessBadge({
    super.key,
    required this.timestamp,
  });

  final DateTime timestamp;

  static FreshnessBand bandFor(DateTime timestamp) {
    final minutes = SignalDeskFormatters.ageMinutes(timestamp);
    if (minutes <= 120) {
      return FreshnessBand.live;
    }
    if (minutes <= 720) {
      return FreshnessBand.recent;
    }
    if (minutes <= 1440) {
      return FreshnessBand.aging;
    }
    return FreshnessBand.stale;
  }

  static bool isStale(DateTime timestamp) {
    return bandFor(timestamp) == FreshnessBand.stale;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SignalDeskLocalizations.of(context);
    final band = bandFor(timestamp);
    final (label, background, foreground) = switch (band) {
      FreshnessBand.live => (
          l10n.liveLabel,
          Colors.green.withValues(alpha: 0.12),
          SignalDeskPalette.momentumUp,
        ),
      FreshnessBand.recent => (
          l10n.recentLabel,
          Colors.blue.withValues(alpha: 0.12),
          Colors.blue.shade800,
        ),
      FreshnessBand.aging => (
          l10n.agingLabel,
          Colors.orange.withValues(alpha: 0.12),
          Colors.orange.shade800,
        ),
      FreshnessBand.stale => (
          l10n.staleLabel,
          Colors.red.withValues(alpha: 0.12),
          SignalDeskPalette.risk,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SignalDeskSpacing.s8,
        vertical: SignalDeskSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label | ${SignalDeskFormatters.relativeAge(context, timestamp)}',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
