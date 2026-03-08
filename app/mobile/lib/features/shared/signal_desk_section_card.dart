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
    return Card(
      shape: SignalDeskShape.card,
      margin: const EdgeInsets.only(bottom: SignalDeskSpacing.s16),
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
                    style: Theme.of(context).textTheme.titleMedium,
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
    );
  }
}
