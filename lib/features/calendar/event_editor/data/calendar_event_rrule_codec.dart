import 'package:rrule/rrule.dart';

import '../domain/calendar_series_edit_state.dart';

class CalendarEventRruleCodec {
  CalendarEventRruleCodec._();

  /// Speicherformat für Postgres (kompatibel mit [CalendarRepository._normalizeRruleText]).
  static String toStorageText(CalendarSeriesEditState state) {
    final byWeekDays = state.frequency == Frequency.weekly
        ? state.weekdays.map((d) => ByWeekDayEntry(d)).toList()
        : const <ByWeekDayEntry>[];

    final rule = RecurrenceRule(
      frequency: state.frequency,
      interval: state.interval,
      byWeekDays: byWeekDays,
    );
    final encoded = rule.toString().trim();
    if (encoded.toUpperCase().startsWith('RRULE:')) {
      return encoded;
    }
    return 'RRULE:$encoded';
  }

  static CalendarSeriesEditState? fromStorageText(
    String? raw, {
    required DateTime fallbackSeriesStart,
  }) {
    final normalized = _normalizeRruleText(raw);
    if (normalized == null) return null;

    try {
      final rule = RecurrenceRule.fromString(normalized);
      final weekdays = rule.byWeekDays.map((e) => e.day).toSet();
      return CalendarSeriesEditState(
        frequency: rule.frequency,
        weekdays: weekdays.isEmpty && rule.frequency == Frequency.weekly
            ? {fallbackSeriesStart.weekday}
            : weekdays,
        seriesStart: fallbackSeriesStart,
        interval: rule.interval ?? 1,
      );
    } catch (_) {
      return null;
    }
  }

  static String? _normalizeRruleText(String? rawRule) {
    final raw = rawRule?.trim();
    if (raw == null || raw.isEmpty) return null;

    final lines = raw
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) return null;

    for (final line in lines) {
      final upper = line.toUpperCase();
      if (upper.startsWith('RRULE:')) {
        final value = line.substring(6).trim();
        return value.isEmpty ? null : 'RRULE:$value';
      }
    }

    final first = lines.first;
    final upperFirst = first.toUpperCase();
    if (upperFirst.startsWith('FREQ=')) {
      return 'RRULE:$first';
    }
    if (upperFirst.contains('FREQ=')) {
      final idx = upperFirst.indexOf('FREQ=');
      final extracted = first.substring(idx).trim();
      return extracted.isEmpty ? null : 'RRULE:$extracted';
    }

    return null;
  }
}
