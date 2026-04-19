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
