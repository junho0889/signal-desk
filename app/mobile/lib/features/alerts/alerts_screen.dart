import 'package:flutter/material.dart';

import '../../core/models/api_models.dart';
import '../../core/repositories/signaldesk_repository.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/loadable_controller.dart';
import '../../src/signal_desk_localizations.dart';
import '../shared/loadable_view.dart';
import '../shared/premium_tokens.dart';
import '../shared/signal_desk_context_rail.dart';
import '../shared/signal_desk_formatters.dart';
import '../shared/signal_desk_shell.dart';
import '../shared/signal_desk_trust_strip.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key, required this.repository});

  final SignalDeskRepository repository;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  late final LoadableController<AlertsResponse> _controller;
  String? _severity;

  static const _severityValues = <String?>[
    null,
    'low',
    'medium',
    'high',
    'critical',
  ];

  @override
  void initState() {
    super.initState();
    _controller = LoadableController<AlertsResponse>(
      loader: () => widget.repository.fetchAlerts(severity: _severity),
    );
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SignalDeskLocalizations.of(context);

    return SignalDeskShell(
      title: l10n.alertsTitle,
      currentRoute: AppRoutes.alerts,
      contextRail: _controller.data == null
          ? null
          : SignalDeskContextRail(
              generatedAt: _controller.data!.generatedAt,
              scopeLabel: _severity ?? l10n.allSeverity,
            ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SignalDeskSpacing.s16,
              SignalDeskSpacing.s8,
              SignalDeskSpacing.s16,
              0,
            ),
            child: Wrap(
              spacing: SignalDeskSpacing.s8,
              children: _severityValues
                  .map(
                    (value) => ChoiceChip(
                      label: Text(value ?? l10n.allSeverity),
                      selected: _severity == value,
                      onSelected: (_) {
                        if (_severity == value) {
                          return;
                        }
                        setState(() {
                          _severity = value;
                        });
                        _controller.refresh();
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          Expanded(
            child: LoadableView<AlertsResponse>(
              controller: _controller,
              generatedAt: (data) => data.generatedAt,
              emptyMessage: 'No recent triggers match this severity filter.',
              isEmpty: (data) => data.items.isEmpty,
              builder: (context, data) {
                return RefreshIndicator(
                  onRefresh: _controller.refresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      SignalDeskSpacing.s16,
                      SignalDeskSpacing.s12,
                      SignalDeskSpacing.s16,
                      SignalDeskSpacing.s24,
                    ),
                    children: data.items
                        .map(
                          (item) => Card(
                            shape: SignalDeskShape.card,
                            margin: const EdgeInsets.only(bottom: SignalDeskSpacing.s8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                final keywordId = item.keywordId;
                                if (keywordId != null && keywordId.isNotEmpty) {
                                  Navigator.of(context).pushNamed(
                                    AppRoutes.detail,
                                    arguments: keywordId,
                                  );
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(SignalDeskSpacing.s12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: SignalDeskSpacing.s8,
                                            vertical: SignalDeskSpacing.s4,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(999),
                                            color: _severityColor(item.severity)
                                                .withValues(alpha: 0.12),
                                          ),
                                          child: Text(
                                            SignalDeskFormatters.severity(item.severity),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                  color: _severityColor(item.severity),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          SignalDeskFormatters.relativeAge(
                                            context,
                                            item.triggeredAt,
                                          ),
                                          style: Theme.of(context).textTheme.labelMedium,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: SignalDeskSpacing.s8),
                                    Text(
                                      item.message,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: SignalDeskSpacing.s4),
                                    Text(
                                      '${item.targetType} · ${item.targetLabel}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: SignalDeskSpacing.s8),
                                    SignalDeskTrustStrip(
                                      confidence: _confidenceForSeverity(item.severity),
                                      isAlertEligible: true,
                                      riskFlags: const <String>[],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical':
        return SignalDeskPalette.risk;
      case 'high':
        return Colors.deepOrange;
      case 'medium':
        return Colors.amber.shade800;
      default:
        return Colors.blueGrey;
    }
  }

  double _confidenceForSeverity(String severity) {
    switch (severity) {
      case 'critical':
      case 'high':
        return 0.8;
      case 'medium':
        return 0.6;
      default:
        return 0.5;
    }
  }
}
