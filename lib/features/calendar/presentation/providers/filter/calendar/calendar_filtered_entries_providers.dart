import 'package:flutter_riverpod/flutter_riverpod.dart' as fr;

import '../../../../domain/models/calendar_entry.dart';
import 'calendar_filter_utils.dart';
import 'calendar_filters_provider.dart';
import '../../calendar_providers.dart';
import '../search/search_filters_provider.dart';

final filteredCalendarEntriesForDayProvider = fr
    .Provider.family<fr.AsyncValue<List<CalendarEntry>>, DateTime>((ref, day) {
      final source = ref.watch(calendarEntriesForDayProvider(day));
      final filters = ref.watch(calendarFiltersProvider);
      return source.whenData((entries) {
        return entries
            .where((entry) => matchesFilters(
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
      final source = ref.watch(calendarEntriesByQueryProvider(query));
      final filters = ref.watch(searchFiltersProvider);
      return source.whenData((entries) {
        return entries
            .where((entry) => matchesFilters(
                  entry: entry,
                  filters: filters,
                  hideUnknownWhenFilterActive: true,
                ))
            .toList(growable: false);
      });
    });
