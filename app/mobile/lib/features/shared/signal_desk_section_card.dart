import 'package:flutter/material.dart';

import 'premium_tokens.dart';

class SignalDeskSectionCard extends StatelessWidget {
  const SignalDeskSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: SignalDeskSpacing.s16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SignalDeskShape.radiusCard),
        gradient: LinearGradient(
          colors: <Color>[
            colorScheme.surface,
            colorScheme.surfaceContainerLow,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(SignalDeskSpacing.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (trailing != null) ...<Widget>[
                    const SizedBox(width: SignalDeskSpacing.s8),
                    trailing!,
                  ],
                ],
              ),
              const SizedBox(height: SignalDeskSpacing.s8),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
