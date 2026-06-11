import 'package:intl/intl.dart';

class AppDateTime {
  const AppDateTime._();

  static DateTime nowLocal() => DateTime.now().toLocal();

  static DateTime toLocal(DateTime value) => value.toLocal();

  static DateTime localDay(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  /// Kalendertags-Index (UTC-Datumsteil), unabhängig von Sommer-/Winterzeit.
  static int localCalendarDayNumber(DateTime value) {
    final day = localDay(value);
    return DateTime.utc(day.year, day.month, day.day)
        .difference(DateTime.utc(1970, 1, 1))
        .inDays;
  }

  /// Addiert Kalendertage per Datumskomponente (kein [Duration]-Add auf Local).
  static DateTime addLocalCalendarDays(DateTime value, int days) {
    final day = localDay(value);
    return DateTime(day.year, day.month, day.day + days);
  }

  /// Kalendertage zwischen zwei lokalen Tagen (immer ganzzahlig).
  static int localCalendarDaysBetween(DateTime from, DateTime to) {
    return localCalendarDayNumber(to) - localCalendarDayNumber(from);
  }

  /// Montag der ISO-Woche, die [day] enthält (lokales Datum).
  static DateTime localMondayOfWeek(DateTime day) {
    final normalized = localDay(day);
    final offsetFromMonday = normalized.weekday - DateTime.monday;
    return DateTime(
      normalized.year,
      normalized.month,
      normalized.day - offsetFromMonday,
    );
  }

  /// 0 = Montag … 6 = Sonntag innerhalb der Woche von [day].
  static int weekdayOffsetFromMonday(DateTime day) {
    return (localDay(day).weekday - DateTime.monday).clamp(0, 6);
  }

  /// Wochentag von [weekdaySource] in der Woche, die [weekReference] enthält.
  static DateTime sameWeekdayInWeekOf({
    required DateTime weekReference,
    required DateTime weekdaySource,
  }) {
    return addLocalCalendarDays(
      localMondayOfWeek(weekReference),
      weekdayOffsetFromMonday(weekdaySource),
    );
  }

  static bool isSameLocalWeek(DateTime a, DateTime b) {
    return isSameLocalDay(localMondayOfWeek(a), localMondayOfWeek(b));
  }

  static DateTime todayLocal({DateTime? now}) =>
      localDay(now ?? DateTime.now());

  static bool isSameLocalDay(DateTime a, DateTime b) {
    final aDay = localDay(a);
    final bDay = localDay(b);
    return aDay.year == bDay.year &&
        aDay.month == bDay.month &&
        aDay.day == bDay.day;
  }

  static bool isTodayLocal(DateTime value, {DateTime? now}) {
    return isSameLocalDay(value, now ?? DateTime.now());
  }

  static bool isBeforeTodayLocal(DateTime value, {DateTime? now}) {
    return localDay(value).isBefore(todayLocal(now: now));
  }

  static bool isPastInstant(DateTime value, {DateTime? now}) {
    return value.toLocal().isBefore((now ?? DateTime.now()).toLocal());
  }

  static DateTime asUtcInstant(DateTime value) {
    return value.isUtc ? value : value.toUtc();
  }

  static (DateTime startUtc, DateTime endExclusiveUtc) utcBoundsForLocalDay(
    DateTime value,
  ) {
    final startLocal = localDay(value);
    final endLocal = startLocal.add(const Duration(days: 1));
    return (startLocal.toUtc(), endLocal.toUtc());
  }

  static DateTime localWallTimeAsUtcInstant(
    DateTime date, {
    required int hour,
    required int minute,
    int second = 0,
    int millisecond = 0,
    int microsecond = 0,
  }) {
    final day = localDay(date);
    return DateTime(
      day.year,
      day.month,
      day.day,
      hour,
      minute,
      second,
      millisecond,
      microsecond,
    ).toUtc();
  }

  static DateTime parseDatabaseDateTime(
    String value, {
    bool assumeUtcWhenTimezoneMissing = false,
  }) {
    final trimmed = value.trim();
    final normalized = trimmed.contains('T')
        ? trimmed
        : trimmed.replaceFirst(' ', 'T');
    if (assumeUtcWhenTimezoneMissing && !_hasExplicitTimezone(normalized)) {
      return DateTime.parse('${normalized}Z');
    }
    return DateTime.parse(normalized);
  }

  static DateTime parseDatabaseTimeOnDate(
    DateTime date,
    String value, {
    bool assumeLocalWhenTimezoneMissing = true,
  }) {
    final raw = value.trim();
    if (raw.isEmpty) {
      throw const FormatException('TIME-Wert fehlt oder ist leer');
    }

    final looksLikeDateTime =
        raw.contains('T') || (raw.contains(' ') && raw.contains('-'));
    if (looksLikeDateTime) {
      return asUtcInstant(
        parseDatabaseDateTime(raw, assumeUtcWhenTimezoneMissing: true),
      );
    }

    if (_hasExplicitTimezone(raw)) {
      return DateTime.parse(
        '${_formatIsoDate(localDay(date))}T${_normalizeTimeZoneOffset(raw)}',
      ).toUtc();
    }

    final parsedTime = _parseTimeParts(raw);
    if (!assumeLocalWhenTimezoneMissing) {
      return DateTime.utc(
        date.year,
        date.month,
        date.day,
        parsedTime.hour,
        parsedTime.minute,
        parsedTime.second,
        parsedTime.millisecond,
        parsedTime.microsecond,
      );
    }

    return localWallTimeAsUtcInstant(
      date,
      hour: parsedTime.hour,
      minute: parsedTime.minute,
      second: parsedTime.second,
      millisecond: parsedTime.millisecond,
      microsecond: parsedTime.microsecond,
    );
  }

  static bool _hasExplicitTimezone(String value) {
    final upper = value.toUpperCase();
    if (upper.endsWith('Z')) return true;
    final tzOffset = RegExp(r'[+-]\d{2}(?::?\d{2})?$');
    return tzOffset.hasMatch(value);
  }

  static ({int hour, int minute, int second, int millisecond, int microsecond})
  _parseTimeParts(String value) {
    final parts = value.split(':');
    if (parts.length < 2) {
      throw FormatException('Ungueltiges TIME-Format: $value');
    }

    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    var second = 0;
    var millisecond = 0;
    var microsecond = 0;

    if (parts.length >= 3) {
      final secAndFraction = parts[2].split('.');
      second = int.parse(secAndFraction[0]);
      if (secAndFraction.length > 1) {
        final fraction = secAndFraction[1].padRight(6, '0');
        microsecond = int.parse(fraction.substring(0, 6));
        millisecond = microsecond ~/ 1000;
        microsecond = microsecond % 1000;
      }
    }

    return (
      hour: hour,
      minute: minute,
      second: second,
      millisecond: millisecond,
      microsecond: microsecond,
    );
  }

  static String _normalizeTimeZoneOffset(String value) {
    final trimmed = value.trim();
    if (trimmed.toUpperCase().endsWith('Z')) return trimmed;

    final match = RegExp(r'([+-])(\d{2})(?::?(\d{2}))?$').firstMatch(trimmed);
    if (match == null) return trimmed;

    final sign = match.group(1)!;
    final hours = match.group(2)!;
    final minutes = match.group(3) ?? '00';
    return '${trimmed.substring(0, match.start)}$sign$hours:$minutes';
  }

  static String _formatIsoDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String formatLocalHourMinute(DateTime value) {
    final local = value.toLocal();
    final hours = local.hour.toString().padLeft(2, '0');
    final minutes = local.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  /// Vollständiges Datum, z. B. „Donnerstag, 3. Mai“.
  static String formatLocalFullWeekdayDate(DateTime value) {
    return DateFormat('EEEE, d. MMMM', 'de').format(localDay(value));
  }

  static const weekdayOrderMondayFirst = <int>[
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
    DateTime.sunday,
  ];

  static const fullWeekdayLabels = <int, String>{
    DateTime.monday: 'Montag',
    DateTime.tuesday: 'Dienstag',
    DateTime.wednesday: 'Mittwoch',
    DateTime.thursday: 'Donnerstag',
    DateTime.friday: 'Freitag',
    DateTime.saturday: 'Samstag',
    DateTime.sunday: 'Sonntag',
  };

  static const recurringWeekdayLabels = <int, String>{
    DateTime.monday: 'Montags',
    DateTime.tuesday: 'Dienstags',
    DateTime.wednesday: 'Mittwochs',
    DateTime.thursday: 'Donnerstags',
    DateTime.friday: 'Freitags',
    DateTime.saturday: 'Samstags',
    DateTime.sunday: 'Sonntags',
  };

  /// Wiederholungs-Wochentage, z. B. „Montags, Mittwochs und Freitags“.
  static String formatLocalFullWeekdays(Iterable<int> weekdays) {
    final unique = weekdays.toSet();
    if (unique.isEmpty) return '';

    final sorted =
        weekdayOrderMondayFirst.where(unique.contains).toList(growable: false);
    final labels =
        sorted.map((day) => recurringWeekdayLabels[day]!).toList(growable: false);

    if (labels.length == 1) return labels.first;
    if (labels.length == 2) return '${labels[0]} und ${labels[1]}';

    return '${labels.sublist(0, labels.length - 1).join(', ')} und ${labels.last}';
  }
}
