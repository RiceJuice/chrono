import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as fr;

import '../../../../core/database/database_provider.dart';
import '../../../../core/time/app_date_time.dart';
import '../../domain/models/calendar_entry.dart';
import '../../domain/repositories/calendar_repository.dart';

export 'filter/calendar/calendar_filter_options_providers.dart';
export 'filter/calendar/calendar_filtered_entries_providers.dart';
export 'filter/calendar/calendar_filters_provider.dart';
export 'filter/calendar/calendar_filters_state.dart';
export 'filter/search/search_filters_provider.dart';
part 'calendar_providers.g.dart';

typedef CalendarEntryLocalRange = ({
  DateTime startInclusive,
  DateTime endExclusive,
});

/// Ursache der letzten [SelectedDay]-Änderung — steuert z. B. den Appear-Bounce
/// in [CalendarDaySelectionAppear] (nur bei [external], nicht bei [tap]).
enum CalendarDaySelectionOrigin { tap, external }

class CalendarDaySelectionOriginTracker
    extends fr.Notifier<CalendarDaySelectionOrigin> {
  /// Wird nur in [SelectedDay.update] erhöht — verhindert Appear beim Kaltstart.
  int changeGeneration = 0;

  @override
  CalendarDaySelectionOrigin build() => CalendarDaySelectionOrigin.external;

  void setOrigin(CalendarDaySelectionOrigin origin) {
    state = origin;
    changeGeneration++;
  }
}

final calendarDaySelectionOriginProvider =
    fr.NotifierProvider<
      CalendarDaySelectionOriginTracker,
      CalendarDaySelectionOrigin
    >(CalendarDaySelectionOriginTracker.new);

@riverpod
class SelectedDay extends _$SelectedDay {
  @override
  DateTime build() {
    return AppDateTime.todayLocal();
  }

  void update(
    DateTime newDate, {
    bool haptic = true,
    CalendarDaySelectionOrigin origin = CalendarDaySelectionOrigin.external,
  }) {
    final next = AppDateTime.localDay(newDate);
    if (state.year == next.year &&
        state.month == next.month &&
        state.day == next.day) {
      return;
    }
    ref.read(calendarDaySelectionOriginProvider.notifier).setOrigin(origin);
    if (haptic) {
      HapticFeedback.mediumImpact();
    }
    state = next;
  }
}

@riverpod
class FocusedDay extends _$FocusedDay {
  @override
  DateTime build() {
    return AppDateTime.todayLocal();
  }

  void update(DateTime newDay) {
    state = AppDateTime.localDay(newDay);
  }
}

/// Leichter Vorschau-Tag während horizontalem Wischen im mobilen Wochenraster.
/// Nur der Header lauscht darauf — [selectedDayProvider]/[focusedDayProvider]
/// werden erst nach dem Snap gesetzt, damit nicht die ganze Woche neu lädt.
class WeekScheduleScrollDay extends fr.Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void setPreview(DateTime day) {
    state = AppDateTime.localDay(day);
  }

  void clear() {
    state = null;
  }
}

final weekScheduleScrollDayProvider =
    fr.NotifierProvider<WeekScheduleScrollDay, DateTime?>(
      WeekScheduleScrollDay.new,
    );

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

final calendarEntriesInLocalRangeProvider =
    fr.StreamProvider.family<List<CalendarEntry>, CalendarEntryLocalRange>((
      ref,
      range,
    ) {
      final repository = ref.watch(calendarRepositoryProvider);
      return repository.watchEntriesInLocalRange(
        startInclusive: range.startInclusive,
        endExclusive: range.endExclusive,
      );
    });

final calendarBreakDaysInLocalRangeProvider =
    fr.StreamProvider.family<Set<DateTime>, CalendarEntryLocalRange>((
      ref,
      range,
    ) {
      final repository = ref.watch(calendarRepositoryProvider);
      return repository.watchBreakDaysInLocalRange(
        startInclusive: range.startInclusive,
        endExclusive: range.endExclusive,
      );
    });

final calendarHolidayDaysInLocalRangeProvider =
    fr.StreamProvider.family<Set<DateTime>, CalendarEntryLocalRange>((
      ref,
      range,
    ) {
      final repository = ref.watch(calendarRepositoryProvider);
      return repository.watchHolidayDaysInLocalRange(
        startInclusive: range.startInclusive,
        endExclusive: range.endExclusive,
      );
    });

final calendarAllEntriesProvider = fr.StreamProvider<List<CalendarEntry>>((
  ref,
) {
  final repository = ref.watch(calendarRepositoryProvider);
  return repository.watchAllEntries();
});

class CalendarSearchInputFocus extends fr.Notifier<bool> {
  @override
  bool build() => false;

  void update(bool isFocused) {
    if (state == isFocused) return;
    state = isFocused;
  }

  void dismiss() => update(false);
}

final calendarSearchInputFocusedProvider =
    fr.NotifierProvider<CalendarSearchInputFocus, bool>(
      CalendarSearchInputFocus.new,
    );
