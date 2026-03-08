import 'package:flutter/material.dart';

import '../../core/models/api_models.dart';
import '../../core/repositories/signaldesk_repository.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/loadable_controller.dart';
import '../shared/data_freshness_banner.dart';
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
  bool _isLoadingNextPage = false;
  Object? _nextPageError;

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

  Future<void> _refreshFirstPage() async {
    if (mounted) {
      setState(() {
        _nextPageError = null;
      });
    }
    await _controller.refresh();
  }

  Future<void> _loadNextPage() async {
    final current = _controller.data;
    final cursor = current?.nextCursor;
    if (current == null || cursor == null || cursor.isEmpty || _isLoadingNextPage) {
      return;
    }
    final requestedSeverity = _severity;

    setState(() {
      _isLoadingNextPage = true;
      _nextPageError = null;
    });

    try {
      final nextPage = await widget.repository.fetchAlerts(
        cursor: cursor,
        severity: requestedSeverity,
      );
      if (!mounted || _severity != requestedSeverity || _controller.data != current) {
        return;
      }
      final merged = widget.repository.mergeAlertsPages(
        current: current,
        nextPage: nextPage,
      );
      _controller.replaceData(merged);
    } catch (error) {
      if (mounted) {
        setState(() {
          _nextPageError = error;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingNextPage = false;
        });
      }
    }
  }

  Widget _buildPaginationFooter(AlertsResponse data) {
    final hasMore = data.nextCursor != null && data.nextCursor!.isNotEmpty;

    if (_isLoadingNextPage) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_nextPageError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: <Widget>[
            Text(
              'Could not load next page. ${_nextPageError.toString()}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _loadNextPage,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: OutlinedButton(
          onPressed: _loadNextPage,
          child: const Text('Load More'),
        ),
      );
    }

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(child: Text('End of alerts')),
    );
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
                      _nextPageError = null;
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
              builder: (context, data) {
                if (data.items.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refreshFirstPage,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: <Widget>[
                        DataFreshnessBanner(generatedAt: data.generatedAt),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No recent triggers match this severity filter.'),
                            ),
                          ),
                        ),
                        _buildPaginationFooter(data),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshFirstPage,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: data.items.length + 2,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return DataFreshnessBanner(generatedAt: data.generatedAt);
                      }

                      if (index == data.items.length + 1) {
                        return _buildPaginationFooter(data);
                      }

                      final item = data.items[index - 1];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
