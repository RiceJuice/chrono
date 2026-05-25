/// Normalisiert [recurrence_id] für stabile Override-Keys (Sekunden, UTC).
String formatCalendarRecurrenceId(DateTime value) {
  final utc = value.toUtc();
  return DateTime.utc(
    utc.year,
    utc.month,
    utc.day,
    utc.hour,
    utc.minute,
    utc.second,
  ).toIso8601String();
}

DateTime parseCalendarRecurrenceId(String iso) {
  return DateTime.parse(iso.trim()).toUtc();
}
