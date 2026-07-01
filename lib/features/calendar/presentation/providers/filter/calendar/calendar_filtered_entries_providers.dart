import 'package:flutter_riverpod/flutter_riverpod.dart' as fr;

import '../../../../domain/filter/calendar_display_filters.dart';
import '../../../../domain/filter/calendar_search_effective_filters.dart';
import '../../../../domain/models/calendar_entry.dart';
import '../../calendar_providers.dart';
import 'calendar_filter_utils.dart';

final filteredCalendarEntriesForDayProvider =
    fr.Provider.family<fr.AsyncValue<List<CalendarEntry>>, DateTime>((
      ref,
      day,
    ) {
      final source = ref.watch(calendarEntriesForDayProvider(day));
      final filters = ref.watch(calendarFiltersProvider);
      final hideUnknown = shouldHideUnknownCalendarEntries(filters);
      return source.whenData((entries) {
        return applyCalendarDisplayFilters(
          entries: entries,
          filters: filters,
          hideUnknownWhenFilterActive: hideUnknown,
          forEventList: true,
        );
      });
    });

final filteredCalendarAllEntriesProvider =
    fr.Provider<fr.AsyncValue<List<CalendarEntry>>>((ref) {
      final source = ref.watch(calendarAllEntriesProvider);
      final filters = ref.watch(calendarFiltersProvider);
      final hideUnknown = shouldHideUnknownCalendarEntries(filters);
      return source.whenData((entries) {
        return applyCalendarDisplayFilters(
          entries: entries,
          filters: filters,
          hideUnknownWhenFilterActive: hideUnknown,
          forEventList: false,
        );
      });
    });

final filteredCalendarEntriesInLocalRangeProvider =
    fr.Provider.family<
      fr.AsyncValue<List<CalendarEntry>>,
      CalendarEntryLocalRange
    >((ref, range) {
      final source = ref.watch(calendarEntriesInLocalRangeProvider(range));
      final filters = ref.watch(calendarFiltersProvider);
      final hideUnknown = shouldHideUnknownCalendarEntries(filters);
      return source.whenData((entries) {
        return applyCalendarDisplayFilters(
          entries: entries,
          filters: filters,
          hideUnknownWhenFilterActive: hideUnknown,
          forEventList: false,
        );
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
      final effectiveFilters = effectiveCalendarFiltersForSearch(
        filters: filters,
        hasQuery: normalizedQuery.isNotEmpty,
      );
      return source.whenData((entries) {
        return applyCalendarDisplayFilters(
          entries: entries,
          filters: effectiveFilters,
          hideUnknownWhenFilterActive: hideUnknownWhenFilterActive,
          forEventList: false,
        );
      });
    });
