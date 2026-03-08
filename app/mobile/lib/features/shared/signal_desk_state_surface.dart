import 'package:flutter/material.dart';

import '../../src/signal_desk_localizations.dart';
import 'premium_tokens.dart';

class SignalDeskStateSurface extends StatelessWidget {
  const SignalDeskStateSurface({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;
  final bool compact;

  factory SignalDeskStateSurface.loading(BuildContext context) {
    final l10n = SignalDeskLocalizations.of(context);
    return SignalDeskStateSurface(
      icon: Icons.hourglass_bottom_outlined,
      title: l10n.loadingTitle,
      message: l10n.isKorean ? '데이터를 불러오는 중입니다.' : 'Loading market intelligence.',
    );
  }

  factory SignalDeskStateSurface.empty(BuildContext context, {String? message}) {
    final l10n = SignalDeskLocalizations.of(context);
    return SignalDeskStateSurface(
      icon: Icons.inbox_outlined,
      title: l10n.noDataTitle,
      message: message ?? (l10n.isKorean ? '표시할 데이터가 없습니다.' : 'Nothing to show yet.'),
      actionLabel: l10n.refreshLabel,
      onAction: null,
    );
  }

  factory SignalDeskStateSurface.error(
    BuildContext context, {
    required String message,
    required Future<void> Function() onRetry,
  }) {
    final l10n = SignalDeskLocalizations.of(context);
    return SignalDeskStateSurface(
      icon: Icons.cloud_off_outlined,
      title: l10n.loadFailedTitle,
      message: message,
      actionLabel: l10n.retryLabel,
      onAction: onRetry,
    );
  }

  factory SignalDeskStateSurface.stale(BuildContext context, {required String message}) {
    final l10n = SignalDeskLocalizations.of(context);
    return SignalDeskStateSurface(
      icon: Icons.schedule,
      title: l10n.staleLabel,
      message: message,
      compact: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: compact ? 44 : 164),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SignalDeskSpacing.s16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: compact ? 18 : 28),
            const SizedBox(width: SignalDeskSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: SignalDeskSpacing.s4),
                  Text(message, style: Theme.of(context).textTheme.bodySmall),
                  if (actionLabel != null && onAction != null) ...<Widget>[
                    const SizedBox(height: SignalDeskSpacing.s12),
                    FilledButton(
                      onPressed: () => onAction!(),
                      child: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SignalDeskSpacing.s16,
        vertical: SignalDeskSpacing.s8,
      ),
      child: card,
    );
  }
}
