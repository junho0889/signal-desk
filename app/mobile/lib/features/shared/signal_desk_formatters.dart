import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../src/signal_desk_localizations.dart';

class SignalDeskFormatters {
  SignalDeskFormatters._();

  static String score(double? value) {
    if (value == null) {
      return '-';
    }
    return NumberFormat('0.00').format(value);
  }

  static String delta(double? value) {
    if (value == null) {
      return '-';
    }
    final formatted = NumberFormat('0.00').format(value.abs());
    if (value > 0) {
      return '+$formatted';
    }
    if (value < 0) {
      return '-$formatted';
    }
    return formatted;
  }

  static String confidence(double value) {
    return '${NumberFormat('0.0').format(value * 100)}%';
  }

  static String timestamp(BuildContext context, DateTime value) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat('yyyy-MM-dd HH:mm', locale).format(value.toLocal());
  }

  static int ageMinutes(DateTime timestamp, {DateTime? nowUtc}) {
    final now = nowUtc ?? DateTime.now().toUtc();
    return now.difference(timestamp.toUtc()).inMinutes;
  }

  static String relativeAge(BuildContext context, DateTime timestamp) {
    final minutes = ageMinutes(timestamp);
    return SignalDeskLocalizations.of(context).relativeTime(minutes);
  }

  static String severity(String value) {
    if (value.isEmpty) {
      return '-';
    }
    return value.toUpperCase();
  }
}
