import 'package:flutter/material.dart';

import '../../src/signal_desk_localizations.dart';
import 'premium_tokens.dart';
import 'signal_desk_formatters.dart';
import 'signal_desk_freshness_badge.dart';

class SignalDeskContextRail extends StatelessWidget {
  const SignalDeskContextRail({
    super.key,
    required this.generatedAt,
    this.scopeLabel,
  });

  final DateTime generatedAt;
  final String? scopeLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = SignalDeskLocalizations.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        SignalDeskSpacing.s16,
        SignalDeskSpacing.s8,
        SignalDeskSpacing.s16,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: SignalDeskSpacing.s12,
        vertical: SignalDeskSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '$l10n.generatedAtLabel ${SignalDeskFormatters.timestamp(context, generatedAt)}'
              '${scopeLabel == null ? '' : ' · $scopeLabel'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          const SizedBox(width: SignalDeskSpacing.s8),
          SignalDeskFreshnessBadge(timestamp: generatedAt),
        ],
      ),
    );
  }
}
