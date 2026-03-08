import 'package:flutter/material.dart';

import '../../core/localization/app_localization.dart';

class FreshnessPolicy {
  static const Duration defaultStaleAfter = Duration(hours: 6);
  static const Duration intradayStaleAfter = Duration(hours: 2);
  static const Duration weeklyStaleAfter = Duration(hours: 24);

  static Duration forPeriod(String period) {
    if (period == 'intraday') {
      return intradayStaleAfter;
    }
    if (period == 'weekly') {
      return weeklyStaleAfter;
    }
    return defaultStaleAfter;
  }
}

class DataFreshnessBanner extends StatelessWidget {
  const DataFreshnessBanner({
    super.key,
    required this.generatedAt,
    this.staleAfter = FreshnessPolicy.defaultStaleAfter,
  });

  final DateTime generatedAt;
  final Duration staleAfter;

  @override
  Widget build(BuildContext context) {
    final strings = AppLanguageScope.stringsOf(context);
    final generatedUtc = generatedAt.toUtc();
    final age = DateTime.now().toUtc().difference(generatedUtc);
    final safeAge = age.isNegative ? Duration.zero : age;
    final isStale = safeAge > staleAfter;

    final icon = isStale ? Icons.warning_amber_rounded : Icons.schedule;
    final color = isStale ? Colors.orange.shade900 : Colors.blueGrey.shade700;
    final label = isStale ? strings.freshnessStaleLabel : strings.freshnessFreshLabel;
    final ageLabel = _formatAge(safeAge, strings);
    final thresholdLabel = _formatAge(staleAfter, strings);
    final generatedLabel = _formatLocalTimestamp(generatedUtc.toLocal());
    final message = isStale
        ? strings.freshnessStaleMessage(ageLabel, generatedLabel, thresholdLabel)
        : strings.freshnessFreshMessage(ageLabel, generatedLabel);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAge(Duration duration, AppStrings strings) {
    if (duration.inMinutes < 1) {
      return strings.underOneMinute;
    }
    if (duration.inHours < 1) {
      return strings.minutesLabel(duration.inMinutes);
    }
    if (duration.inDays < 1) {
      final minutesRemainder = duration.inMinutes.remainder(60);
      if (minutesRemainder == 0) {
        return strings.hoursLabel(duration.inHours);
      }
      return '${strings.hoursLabel(duration.inHours)} ${strings.minutesLabel(minutesRemainder)}';
    }
    final hoursRemainder = duration.inHours.remainder(24);
    if (hoursRemainder == 0) {
      return strings.daysLabel(duration.inDays);
    }
    return '${strings.daysLabel(duration.inDays)} ${strings.hoursLabel(hoursRemainder)}';
  }

  String _formatLocalTimestamp(DateTime localTime) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${localTime.year}-${twoDigits(localTime.month)}-${twoDigits(localTime.day)} '
        '${twoDigits(localTime.hour)}:${twoDigits(localTime.minute)}';
  }
}
