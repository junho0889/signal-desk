import 'package:flutter/material.dart';

import '../../core/models/api_models.dart';
import '../../core/network/signaldesk_api_client.dart';
import '../../core/routes/app_routes.dart';
import '../shared/signal_desk_shell.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.apiClient});

  final SignalDeskApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return SignalDeskShell(
      title: 'SignalDesk Home',
      currentRoute: AppRoutes.home,
      child: FutureBuilder<DashboardResponse>(
        future: apiClient.getDashboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load dashboard: ${snapshot.error}'));
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('No dashboard data.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Text('Generated at: ${data.generatedAt.toIso8601String()}'),
              const SizedBox(height: 16),
              const Text('Top Keywords', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...data.topKeywords.map((item) {
                return Card(
                  child: ListTile(
                    title: Text(item.keyword),
                    subtitle: Text('Score ${item.score.toStringAsFixed(2)} | Confidence ${item.confidence.toStringAsFixed(3)}'),
                    trailing: Text(item.delta1d?.toStringAsFixed(2) ?? '-'),
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.detail,
                      arguments: item.keywordId,
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              const Text('Recent Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...data.riskAlerts.map((alert) {
                return ListTile(
                  dense: true,
                  title: Text(alert.message),
                  subtitle: Text('${alert.severity.toUpperCase()} | ${alert.triggeredAt.toIso8601String()}'),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

