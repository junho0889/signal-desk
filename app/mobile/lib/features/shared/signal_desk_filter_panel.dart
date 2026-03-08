import 'package:flutter/material.dart';

import 'premium_tokens.dart';

class SignalDeskFilterPanel extends StatelessWidget {
  const SignalDeskFilterPanel({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        SignalDeskSpacing.s16,
        SignalDeskSpacing.s8,
        SignalDeskSpacing.s16,
        SignalDeskSpacing.s8,
      ),
      padding: const EdgeInsets.all(SignalDeskSpacing.s12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(SignalDeskShape.radiusCard),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: SignalDeskSpacing.s8),
          child,
        ],
      ),
    );
  }
}
