import '../event_editor/data/calendar_event_recurrence_id.dart';
import 'calendar_series_instance_cancellation.dart';
import 'models/calendar_entry.dart';

/// Stabiler Schlüssel für Serien-Instanz-Overrides (`series_id` + `recurrence_id`).
String? calendarSeriesOverrideKey(String? seriesId, DateTime? recurrenceId) {
  if (seriesId == null || seriesId.isEmpty || recurrenceId == null) {
    return null;
  }
  return '$seriesId|${formatCalendarRecurrenceId(recurrenceId)}';
}

/// `recurrence_id` aus der DB, sonst `start_time` als Fallback für Overrides.
DateTime? resolveCalendarEventRecurrenceId(CalendarEntry event) {
  if (event.seriesId == null || event.seriesId!.isEmpty) {
    return null;
  }
  return event.recurrenceId ?? event.startTime;
}

bool isCalendarEventVisibleInUtcWindow(
  CalendarEntry event, {
  required DateTime startUtc,
  required DateTime endExclusiveUtc,
}) {
  if (event.type == CalendarEntryType.breakType) {
    return true;
  }
  final start = event.startTime.toUtc();
  return !start.isBefore(startUtc) && start.isBefore(endExclusiveUtc);
}

/// Blendet Serien-Instanzen aus, wenn ein passender Eintrag in
/// [calendar_events] existiert (Override oder Storno).
List<CalendarEntry> mergeCalendarEntriesWithSeriesOverrides({
  required List<CalendarEntry> events,
  required List<CalendarEntry> expandedSeries,
  required DateTime startUtc,
  required DateTime endExclusiveUtc,
}) {
  final overrides = <String>{};
  final visibleEvents = <CalendarEntry>[];

  for (final event in events) {
    final recurrenceForKey = resolveCalendarEventRecurrenceId(event);
    final key = calendarSeriesOverrideKey(event.seriesId, recurrenceForKey);
    if (key != null) {
      overrides.add(key);
      if (!isCalendarSeriesInstanceCancellation(event) &&
          isCalendarEventVisibleInUtcWindow(
            event,
            startUtc: startUtc,
            endExclusiveUtc: endExclusiveUtc,
          )) {
        visibleEvents.add(event);
      }
    } else {
      visibleEvents.add(event);
    }
  }

  final remainingSeries = expandedSeries.where((seriesEntry) {
    final key = calendarSeriesOverrideKey(
      seriesEntry.seriesId,
      seriesEntry.recurrenceId,
    );
    return key == null || !overrides.contains(key);
  });

  return [...visibleEvents, ...remainingSeries];
}
