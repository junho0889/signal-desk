import 'package:flutter/material.dart';

import '../../core/models/api_models.dart';
import '../../core/network/signaldesk_api_client.dart';
import '../../core/routes/app_routes.dart';
import '../shared/signal_desk_shell.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key, required this.apiClient});

  final SignalDeskApiClient apiClient;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String? _severity;

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
                    setState(() {
                      _severity = value;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<AlertsResponse>(
              future: widget.apiClient.getAlerts(severity: _severity),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Failed to load alerts: ${snapshot.error}'));
                }

                final data = snapshot.data;
                if (data == null || data.items.isEmpty) {
                  return const Center(child: Text('No recent triggers.'));
                }

                return ListView.builder(
                  itemCount: data.items.length,
                  itemBuilder: (context, index) {
                    final item = data.items[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        title: Text(item.message),
                        subtitle: Text('${item.severity.toUpperCase()} | ${item.triggeredAt.toIso8601String()}'),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

