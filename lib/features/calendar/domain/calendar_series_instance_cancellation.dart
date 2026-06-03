import 'models/calendar_entry.dart';

/// Serien-Override mit `end_time <= start_time` blendet die Instanz im Kalender aus.
bool isCalendarSeriesInstanceCancellation(CalendarEntry entry) {
  if (entry.seriesId == null || entry.recurrenceId == null) {
    return false;
  }
  return !entry.endTime.isAfter(entry.startTime);
}
