part of 'calendar_providers.dart';

final calendarChoirFilterOptionsProvider = fr.Provider<List<String>>((ref) {
  return BackendChoir.values
      .where((value) => value != BackendChoir.unknown)
      .map((value) => _normalizeText(value.toBackend()))
      .whereType<String>()
      .toList(growable: false);
});

final calendarVoiceFilterOptionsProvider = fr.Provider<List<String>>((ref) {
  return BackendVoice.values
      .where((value) => value != BackendVoice.unknown)
      .map((value) => _normalizeText(value.toBackend()))
      .whereType<String>()
      .toList(growable: false);
});

final calendarClassFilterOptionsProvider =
    fr.Provider<fr.AsyncValue<List<String>>>((ref) {
      final entriesAsync = ref.watch(calendarAllEntriesProvider);
      return entriesAsync.whenData((entries) {
        final set = <String>{};
        for (final entry in entries) {
          final className = _normalizeText(entry.className);
          if (className != null) {
            set.add(className);
          }
        }
        final items = set.toList()..sort();
        return items;
      });
    });

final filteredCalendarEntriesForDayProvider = fr
    .Provider.family<fr.AsyncValue<List<CalendarEntry>>, DateTime>((ref, day) {
      final source = ref.watch(calendarEntriesForDayProvider(day));
      final filters = ref.watch(calendarLocalFiltersProvider);
      return source.whenData((entries) {
        return entries
            .where((entry) => _matchesFilters(
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
      final filters = ref.watch(calendarLocalFiltersProvider);
      return source.whenData((entries) {
        return entries
            .where((entry) => _matchesFilters(
                  entry: entry,
                  filters: filters,
                  hideUnknownWhenFilterActive: true,
                ))
            .toList(growable: false);
      });
    });
