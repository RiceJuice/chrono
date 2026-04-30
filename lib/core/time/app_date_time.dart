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

  static DateTime parseDatabaseDateTime(String value) {
    final trimmed = value.trim();
    final normalized = trimmed.contains('T')
        ? trimmed
        : trimmed.replaceFirst(' ', 'T');
    return DateTime.parse(normalized);
  }

  static String formatLocalHourMinute(DateTime value) {
    final local = value.toLocal();
    final hours = local.hour.toString().padLeft(2, '0');
    final minutes = local.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
