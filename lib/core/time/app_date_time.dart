class AppDateTime {
  const AppDateTime._();

  static DateTime nowLocal() => DateTime.now().toLocal();

  static DateTime toLocal(DateTime value) => value.toLocal();

  static DateTime localDay(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
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
}
