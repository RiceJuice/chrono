import '../models/calendar_entry.dart';
import 'calendar_filters_logic.dart';
import 'calendar_filters_state.dart';
import 'calendar_meal_diet_filter.dart';

bool calendarEntriesOverlap(CalendarEntry a, CalendarEntry b) {
  return a.startTime.isBefore(b.endTime) && b.startTime.isBefore(a.endTime);
}

/// Blendet Nicht-Event-Termine aus, die zeitlich mit einem Event kollidieren.
List<CalendarEntry> suppressCalendarEntriesOverlappedByEvents(
  List<CalendarEntry> entries,
) {
  final events = entries
      .where((entry) => entry.type == CalendarEntryType.event)
      .toList(growable: false);
  if (events.isEmpty) {
    return entries;
  }

  return entries
      .where((entry) {
        if (entry.type == CalendarEntryType.event ||
            entry.type == CalendarEntryType.breakType) {
          return true;
        }
        return !events.any((event) => calendarEntriesOverlap(entry, event));
      })
      .toList(growable: false);
}

List<CalendarEntry> applyCalendarDisplayFilters({
  required List<CalendarEntry> entries,
  required CalendarFiltersState filters,
  required bool hideUnknownWhenFilterActive,
  required bool forEventList,
}) {
  final mealSlotsWithAlternatives = collectMealSlotsWithDietAlternatives(
    entries,
  );
  final filtered = entries
      .where(
        (entry) => forEventList
            ? calendarEntryVisibleInEventList(
                entry: entry,
                filters: filters,
                hideUnknownWhenFilterActive: hideUnknownWhenFilterActive,
                mealSlotsWithDietAlternatives: mealSlotsWithAlternatives,
              )
            : calendarEntryMatchesFilters(
                entry: entry,
                filters: filters,
                hideUnknownWhenFilterActive: hideUnknownWhenFilterActive,
                mealSlotsWithDietAlternatives: mealSlotsWithAlternatives,
              ),
      )
      .toList(growable: false);
  return suppressCalendarEntriesOverlappedByEvents(filtered);
}
