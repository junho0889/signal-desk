import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../src/signal_desk_localizations.dart';
import 'premium_tokens.dart';

class SignalDeskTrendChartCard extends StatelessWidget {
  const SignalDeskTrendChartCard({
    super.key,
    required this.points,
    required this.title,
    this.height = 168,
    this.compact = false,
  });

  final List<double> points;
  final String title;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = SignalDeskLocalizations.of(context);

    if (points.length < 2) {
      return Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          l10n.insufficientChartDataMessage,
          style: Theme.of(context).textTheme.labelMedium,
        ),
      );
    }

    final spots = <FlSpot>[
      for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i]),
    ];

    final minY = points.reduce((a, b) => a < b ? a : b);
    final maxY = points.reduce((a, b) => a > b ? a : b);
    final spread = (maxY - minY).abs();
    final rangePadding = spread == 0
        ? (maxY.abs() < 1 ? 1.0 : maxY.abs() * 0.06)
        : spread * 0.12;
    final chartMinY = minY - rangePadding;
    final chartMaxY = maxY + rangePadding;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: height,
      padding: const EdgeInsets.all(SignalDeskSpacing.s8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!compact) ...<Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: SignalDeskSpacing.s8),
          ],
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (points.length - 1).toDouble(),
                minY: chartMinY,
                maxY: chartMaxY,
                gridData: FlGridData(
                  show: !compact,
                  drawVerticalLine: false,
                  horizontalInterval: spread == 0 ? 1 : spread / 3,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(
                  show: !compact,
                  border: Border.all(
                    color: colorScheme.outlineVariant,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles:
                        SideTitles(showTitles: !compact, reservedSize: 34),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles:
                        SideTitles(showTitles: !compact, reservedSize: 24),
                  ),
                ),
                lineBarsData: <LineChartBarData>[
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: colorScheme.primary,
                    barWidth: 2,
                    dotData: FlDotData(show: !compact && points.length <= 12),
                    belowBarData: BarAreaData(
                      show: !compact,
                      gradient: LinearGradient(
                        colors: <Color>[
                          colorScheme.primary.withValues(alpha: 0.22),
                          colorScheme.primary.withValues(alpha: 0.02),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
