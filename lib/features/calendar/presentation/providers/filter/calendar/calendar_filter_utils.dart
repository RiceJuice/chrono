import '../../../../domain/filter/calendar_filter_text.dart';
import '../../../../domain/filter/calendar_filters_logic.dart';
import '../../../../domain/models/calendar_entry.dart';
import 'calendar_filters_state.dart';

String? normalizeFilterText(String? value) {
  return normalizeCalendarFilterText(value);
}

List<String> normalizedFilterList(Iterable<String?> values) {
  return normalizedCalendarFilterList(values);
}

bool matchesFilters({
  required CalendarEntry entry,
  required CalendarFiltersState filters,
  required bool hideUnknownWhenFilterActive,
}) {
  return calendarEntryMatchesFilters(
    entry: entry,
    filters: filters,
    hideUnknownWhenFilterActive: hideUnknownWhenFilterActive,
  );
}
