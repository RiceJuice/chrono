import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as fr;

import '../../../../core/database/database_provider.dart';
import '../../domain/models/calendar_entry.dart';
import '../../domain/repositories/calendar_repository.dart';

export 'filter/calendar/calendar_filter_options_providers.dart';
export 'filter/calendar/calendar_filtered_entries_providers.dart';
export 'filter/calendar/calendar_filters_provider.dart';
export 'filter/calendar/calendar_filters_state.dart';
export 'filter/search/search_filters_provider.dart';
part 'calendar_providers.g.dart';

@riverpod
class SelectedDay extends _$SelectedDay {
  @override
  DateTime build() {
    final now = DateTime.now().toLocal();
    return DateTime(now.year, now.month, now.day);
  }

  void update(DateTime newDate) {
    final localDay = newDate.toLocal();
    state = DateTime(localDay.year, localDay.month, localDay.day);
  }
}

@riverpod
class FocusedDay extends _$FocusedDay {
  @override
  DateTime build() {
    final now = DateTime.now().toLocal();
    return DateTime(now.year, now.month, now.day);
  }

  void update(DateTime newDay) {
    final localDay = newDay.toLocal();
    state = DateTime(localDay.year, localDay.month, localDay.day);
  }
}

@riverpod
CalendarRepository calendarRepository(Ref ref) {
  return CalendarRepository(ref.watch(dbProvider));
}

@riverpod
class CalendarEntries extends _$CalendarEntries {
  @override
  Stream<List<CalendarEntry>> build() {
    final repository = ref.watch(calendarRepositoryProvider);
    final day = ref.watch(selectedDayProvider);
    return repository.watchEntriesForDay(day);
  }
}

@riverpod
class CalendarEntriesForDay extends _$CalendarEntriesForDay {
  @override
  Stream<List<CalendarEntry>> build(DateTime day) {
    final repository = ref.watch(calendarRepositoryProvider);
    return repository.watchEntriesForDay(day);
  }
}

final calendarEntriesByQueryProvider =
    fr.StreamProvider.family<List<CalendarEntry>, String>((ref, query) {
      final repository = ref.watch(calendarRepositoryProvider);
      return repository.watchEntriesByQuery(query);
    });

final calendarAllEntriesProvider = fr.StreamProvider<List<CalendarEntry>>((ref) {
  final repository = ref.watch(calendarRepositoryProvider);
  return repository.watchAllEntries();
});
