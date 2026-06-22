import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/domain/filter/event_schedule_filter.dart';
import 'package:chronoapp/features/calendar/domain/filter/calendar_filters_state.dart';
import 'package:chronoapp/features/calendar/domain/models/event_schedule.dart';
import 'package:chronoapp/features/calendar/live_activity/domain/schedule_live_activity_snapshot.dart';
import 'package:chronoapp/features/calendar/live_activity/live_activity_constants.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/calendar_now_anchor.dart';

/// Ermittelt aktuellen/nächsten sichtbaren Ablaufplanpunkt für die Live Activity.
abstract final class ScheduleLiveActivityResolver {
  ScheduleLiveActivityResolver._();

  static ScheduleLiveActivitySnapshot? resolve({
    required String eventId,
    required List<EventSchedule> schedules,
    required EventScheduleListFilter listFilter,
    required CalendarFiltersState filters,
    DateTime? now,
  }) {
    if (schedules.isEmpty) return null;

    final clock = now ?? DateTime.now();
    final visible = schedules.where((schedule) {
      if (!_isVisibleForListFilter(
        schedule: schedule,
        listFilter: listFilter,
        filters: filters,
      )) {
        return false;
      }
      return eventScheduleVisible(schedule: schedule, filters: filters);
    }).toList();

    if (visible.isEmpty) return null;

    final currentIndex = _currentIndex(visible, now: clock);
    if (currentIndex == null) return null;

    final current = visible[currentIndex];
    final next = currentIndex + 1 < visible.length
        ? visible[currentIndex + 1]
        : null;

    final segmentStart = AppDateTime.toLocal(current.startTime);
    final segmentEnd = AppDateTime.toLocal(
      CalendarNowAnchor.scheduleEffectiveEnd(current),
    );
    if (!segmentEnd.isAfter(clock) && segmentStart.isBefore(clock)) {
      return null;
    }

    return ScheduleLiveActivitySnapshot(
      eventId: eventId,
      customId: liveActivityCustomIdForEvent(eventId),
      currentScheduleId: current.id,
      currentTitle: current.title,
      currentSubtitle: current.location ?? '',
      nextTitle: next?.title ?? '',
      nextSubtitle: next?.location ?? '',
      segmentStartMs: segmentStart.millisecondsSinceEpoch,
      segmentEndMs: segmentEnd.millisecondsSinceEpoch,
    );
  }

  static int? _currentIndex(
    List<EventSchedule> visible, {
    required DateTime now,
  }) {
    for (var i = 0; i < visible.length; i++) {
      final schedule = visible[i];
      if (!AppDateTime.isTodayLocal(schedule.startTime, now: now)) continue;
      if (!CalendarNowAnchor.scheduleIsPast(schedule, now: now)) return i;
    }
    return null;
  }

  static bool _isVisibleForListFilter({
    required EventSchedule schedule,
    required EventScheduleListFilter listFilter,
    required CalendarFiltersState filters,
  }) {
    if (listFilter == EventScheduleListFilter.all) return true;
    return eventScheduleMatchesUserProfile(
      schedule: schedule,
      filters: filters,
    );
  }

  /// Ob der gesamte sichtbare Ablauf für heute beendet ist.
  static bool isScheduleDayFinished({
    required List<EventSchedule> schedules,
    required EventScheduleListFilter listFilter,
    required CalendarFiltersState filters,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final visible = schedules.where((schedule) {
      return _isVisibleForListFilter(
            schedule: schedule,
            listFilter: listFilter,
            filters: filters,
          ) &&
          eventScheduleVisible(schedule: schedule, filters: filters);
    });
    if (visible.isEmpty) return true;

    final lastToday = visible.where(
      (s) => AppDateTime.isTodayLocal(s.startTime, now: clock),
    );
    if (lastToday.isEmpty) return true;

    return lastToday.every(
      (s) => CalendarNowAnchor.scheduleIsPast(s, now: clock),
    );
  }
}
