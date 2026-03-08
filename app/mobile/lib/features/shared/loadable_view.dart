import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/state/loadable_controller.dart';
import 'signal_desk_formatters.dart';
import 'signal_desk_state_surface.dart';

class LoadableView<T> extends StatelessWidget {
  const LoadableView({
    super.key,
    required this.controller,
    required this.builder,
    this.isEmpty,
    this.emptyMessage = 'Nothing to show yet.',
    this.errorMessageBuilder,
    this.generatedAt,
  });

  final LoadableController<T> controller;
  final Widget Function(BuildContext context, T data) builder;
  final bool Function(T data)? isEmpty;
  final String emptyMessage;
  final String Function(Object error)? errorMessageBuilder;
  final DateTime? Function(T data)? generatedAt;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final data = controller.data;
        if (data == null) {
          if (controller.isLoading || !controller.hasAttemptedLoad) {
            return SignalDeskStateSurface.loading(context);
          }
          if (controller.error != null) {
            return SignalDeskStateSurface.error(
              context,
              message: _messageForError(controller.error!),
              onRetry: controller.refresh,
            );
          }
          return SignalDeskStateSurface(
            icon: Icons.inbox_outlined,
            title: 'No data',
            message: emptyMessage,
            actionLabel: 'Refresh',
            onAction: controller.refresh,
          );
        }

        if (isEmpty?.call(data) ?? false) {
          return SignalDeskStateSurface(
            icon: Icons.inbox_outlined,
            title: 'No data',
            message: emptyMessage,
            actionLabel: 'Refresh',
            onAction: controller.refresh,
          );
        }

        final content = builder(context, data);
        final staleAt = generatedAt?.call(data);
        final showStale = staleAt != null &&
            DateTime.now().toUtc().difference(staleAt.toUtc()) >
                const Duration(hours: 24);

        final visibleContent = controller.isLoading
            ? Stack(
                children: <Widget>[
                  Positioned.fill(child: content),
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(),
                  ),
                ],
              )
            : content;

        if (!showStale) {
          return visibleContent;
        }

        return Column(
          children: <Widget>[
            SignalDeskStateSurface.stale(
              context,
              message:
                  'Data is ${SignalDeskFormatters.relativeAge(context, staleAt)} old. Interpret with caution.',
            ),
            Expanded(child: visibleContent),
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
