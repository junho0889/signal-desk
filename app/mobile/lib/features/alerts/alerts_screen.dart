import 'package:flutter/material.dart';

import '../../core/models/api_models.dart';
import '../../core/repositories/signaldesk_repository.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/loadable_controller.dart';
import '../shared/loadable_view.dart';
import '../shared/signal_desk_shell.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key, required this.repository});

  final SignalDeskRepository repository;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  late final LoadableController<AlertsResponse> _controller;
  String? _severity;

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
    return SignalDeskShell(
      title: 'Alerts',
      currentRoute: AppRoutes.alerts,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                const Text('Severity:'),
                const SizedBox(width: 12),
                DropdownButton<String?>(
                  value: _severity,
                  items: const <DropdownMenuItem<String?>>[
                    DropdownMenuItem<String?>(value: null, child: Text('All')),
                    DropdownMenuItem<String?>(value: 'low', child: Text('low')),
                    DropdownMenuItem<String?>(value: 'medium', child: Text('medium')),
                    DropdownMenuItem<String?>(value: 'high', child: Text('high')),
                    DropdownMenuItem<String?>(value: 'critical', child: Text('critical')),
                  ],
                  onChanged: (value) {
                    if (value == _severity) {
                      return;
                    }
                    setState(() {
                      _severity = value;
                    });
                    _controller.refresh();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: LoadableView<AlertsResponse>(
              controller: _controller,
              emptyMessage: 'No recent triggers match this severity filter.',
              isEmpty: (data) => data.items.isEmpty,
              builder: (context, data) {
                return RefreshIndicator(
                  onRefresh: _controller.refresh,
                  child: ListView.builder(
                    itemCount: data.items.length,
                    itemBuilder: (context, index) {
                      final item = data.items[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ListTile(
                          title: Text(item.message),
                          subtitle: Text(
                            '${item.severity.toUpperCase()} | '
                            '${item.triggeredAt.toIso8601String()}\n'
                            'Target ${item.targetType} | ${item.targetLabel}',
                          ),
                          isThreeLine: true,
                          onTap: () {
                            final keywordId = item.keywordId;
                            if (keywordId != null && keywordId.isNotEmpty) {
                              Navigator.of(context).pushNamed(
                                AppRoutes.detail,
                                arguments: keywordId,
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
