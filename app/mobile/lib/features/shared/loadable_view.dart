import 'package:flutter/material.dart';

import '../../core/localization/app_localization.dart';
import '../../core/network/api_exception.dart';
import '../../core/state/loadable_controller.dart';

class LoadableView<T> extends StatelessWidget {
  static const String defaultLoadingMessage = 'Loading data...';
  static const String defaultEmptyMessage = 'Nothing to show yet.';

  const LoadableView({
    super.key,
    required this.controller,
    required this.builder,
    this.isEmpty,
    this.loadingMessage = defaultLoadingMessage,
    this.emptyMessage = defaultEmptyMessage,
    this.errorMessageBuilder,
  });

  final LoadableController<T> controller;
  final Widget Function(BuildContext context, T data) builder;
  final bool Function(T data)? isEmpty;
  final String loadingMessage;
  final String emptyMessage;
  final String Function(Object error)? errorMessageBuilder;

  @override
  Widget build(BuildContext context) {
    final strings = AppLanguageScope.stringsOf(context);
    final resolvedLoadingMessage =
        loadingMessage == defaultLoadingMessage ? strings.loadingDataMessage : loadingMessage;
    final resolvedEmptyMessage =
        emptyMessage == defaultEmptyMessage ? strings.nothingToShowMessage : emptyMessage;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final data = controller.data;
        if (data == null) {
          if (controller.isLoading || !controller.hasAttemptedLoad) {
            return _StateCard(
              icon: Icons.hourglass_bottom_outlined,
              title: strings.loadingTitle,
              message: resolvedLoadingMessage,
            );
          }
          if (controller.error != null) {
            return _StateCard(
              icon: Icons.cloud_off_outlined,
              title: strings.couldNotLoadTitle,
              message: _messageForError(controller.error!),
              actionLabel: strings.retryAction,
              onAction: controller.refresh,
            );
          }
          return _StateCard(
            icon: Icons.inbox_outlined,
            title: strings.noDataTitle,
            message: resolvedEmptyMessage,
            actionLabel: strings.refreshAction,
            onAction: controller.refresh,
          );
        }

        if (isEmpty?.call(data) ?? false) {
          return _StateCard(
            icon: Icons.inbox_outlined,
            title: strings.nothingYetTitle,
            message: resolvedEmptyMessage,
            actionLabel: strings.refreshAction,
            onAction: controller.refresh,
          );
        }

        final content = builder(context, data);
        if (!controller.isLoading) {
          return content;
        }

        return Stack(
          children: <Widget>[
            Positioned.fill(child: content),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
          ],
        );
      },
    );
  }

  String _messageForError(Object error) {
    if (errorMessageBuilder != null) {
      return errorMessageBuilder!(error);
    }
    if (error is ApiException) {
      return error.message;
    }
    return error.toString();
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(icon, size: 32),
                  const SizedBox(height: 12),
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (actionLabel != null && onAction != null) ...<Widget>[
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => onAction!(),
                      child: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
