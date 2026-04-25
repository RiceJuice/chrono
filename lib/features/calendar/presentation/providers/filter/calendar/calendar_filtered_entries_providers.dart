import 'package:flutter_riverpod/flutter_riverpod.dart' as fr;

import '../../../../domain/filter/calendar_filters_logic.dart';
import '../../../../domain/models/calendar_entry.dart';
import '../../calendar_providers.dart';

final filteredCalendarEntriesForDayProvider = fr
    .Provider.family<fr.AsyncValue<List<CalendarEntry>>, DateTime>((ref, day) {
      final source = ref.watch(calendarEntriesForDayProvider(day));
      final filters = ref.watch(calendarFiltersProvider);
      return source.whenData((entries) {
        return entries
            .where((entry) => calendarEntryMatchesFilters(
                  entry: entry,
                  filters: filters,
                  hideUnknownWhenFilterActive: false,
                ))
            .toList(growable: false);
      });
    });

final filteredCalendarEntriesByQueryProvider =
    fr.Provider.family<fr.AsyncValue<List<CalendarEntry>>, String>((
      ref,
      query,
    ) {
      final normalizedQuery = query.trim();
      final source = normalizedQuery.isEmpty
          ? ref.watch(calendarAllEntriesProvider)
          : ref.watch(calendarEntriesByQueryProvider(normalizedQuery));
      final filters = ref.watch(searchFiltersProvider);
      final hideUnknownWhenFilterActive =
          normalizedQuery.isEmpty && filters.hasUserOverrides;
      final effectiveFilters = normalizedQuery.isEmpty
          ? filters
          : _mergeWithDefaultFilters(filters);
      return source.whenData((entries) {
        return entries
            .where((entry) => calendarEntryMatchesFilters(
                  entry: entry,
                  filters: effectiveFilters,
                  hideUnknownWhenFilterActive: hideUnknownWhenFilterActive,
                ))
            .toList(growable: false);
      });
    });

CalendarFiltersState _mergeWithDefaultFilters(CalendarFiltersState filters) {
  return filters.copyWith(
    choirs: _mergeUnique(filters.choirs, filters.defaultChoirs),
    voices: _mergeUnique(filters.voices, filters.defaultVoices),
    classNames: _mergeUnique(filters.classNames, filters.defaultClassNames),
  );
}

List<String> _mergeUnique(List<String> active, List<String> defaults) {
  if (defaults.isEmpty) return active;
  final merged = <String>{...active, ...defaults}.toList()..sort();
  return merged;
}
