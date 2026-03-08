import 'package:flutter/material.dart';

import '../api/models.dart';
import '../api/signal_desk_api.dart';
import 'keyword_detail_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({required this.api, super.key});

  static const route = '/alerts';

  final SignalDeskApi api;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  Severity? _severity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alerts')),
      body: Column(
        children: <Widget>[
          Wrap(
            spacing: 8,
            children: <Widget>[
              ChoiceChip(
                label: const Text('all'),
                selected: _severity == null,
                onSelected: (_) => setState(() => _severity = null),
              ),
              ...Severity.values.map(
                (value) => ChoiceChip(
                  label: Text(value.name),
                  selected: _severity == value,
                  onSelected: (_) => setState(() => _severity = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<AlertsResponse>(
              future: widget.api.getAlerts(severity: _severity),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Alerts load failed: ${snapshot.error}'));
                }
                final items = snapshot.data!.items;
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final alert = items[index];
                    return ListTile(
                      title: Text(alert.message),
                      subtitle: Text('${alert.targetLabel} | ${alert.severity.name} | ${alert.triggeredAt}'),
                      onTap: alert.keywordId == null
                          ? null
                          : () => Navigator.pushNamed(
                                context,
                                KeywordDetailScreen.route,
                                arguments: alert.keywordId,
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
