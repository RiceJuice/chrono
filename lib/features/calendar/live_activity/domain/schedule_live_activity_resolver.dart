import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/domain/filter/event_schedule_filter.dart';
import 'package:chronoapp/features/calendar/domain/filter/calendar_filters_state.dart';
import 'package:chronoapp/features/calendar/domain/models/event_schedule.dart';
import 'package:chronoapp/features/calendar/live_activity/domain/schedule_live_activity_event.dart';
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
    final segmentEnd = _effectiveEnd(current, next);

    return ScheduleLiveActivitySnapshot(
      eventId: eventId,
      customId: liveActivityCustomIdForEvent(eventId),
      currentScheduleId: current.id,
      currentTitle: current.title,
      currentSubtitle: current.location ?? '',
      hasNext: next != null,
      nextTitle: next?.title ?? '',
      nextSubtitle: next?.location ?? '',
      segmentStartMs: segmentStart.millisecondsSinceEpoch,
      segmentEndMs: segmentEnd.millisecondsSinceEpoch,
    );
  }

  /// Live Activity für Event-Termine ohne Ablaufplan.
  static ScheduleLiveActivitySnapshot? resolveFromEvent({
    required ScheduleLiveActivityEvent event,
    required CalendarFiltersState filters,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    if (!calendarEventVisible(event: event, filters: filters)) {
      return null;
    }
    if (!AppDateTime.isTodayLocal(event.startTime, now: clock)) {
      return null;
    }
    if (AppDateTime.isPastInstant(event.endTime, now: clock)) {
      return null;
    }
    if (AppDateTime.toLocal(event.startTime).isAfter(clock)) {
      return null;
    }

    final segmentStart = AppDateTime.toLocal(event.startTime);
    final segmentEnd = AppDateTime.toLocal(event.endTime);

    return ScheduleLiveActivitySnapshot(
      eventId: event.id,
      customId: liveActivityCustomIdForEvent(event.id),
      currentScheduleId: event.id,
      currentTitle: event.eventName,
      currentSubtitle: event.location ?? '',
      hasNext: false,
      nextTitle: '',
      nextSubtitle: '',
      segmentStartMs: segmentStart.millisecondsSinceEpoch,
      segmentEndMs: segmentEnd.millisecondsSinceEpoch,
    );
  }

  static bool isEventFinished({
    required ScheduleLiveActivityEvent event,
    DateTime? now,
  }) {
    return AppDateTime.isPastInstant(event.endTime, now: now);
  }

  static int? _currentIndex(
    List<EventSchedule> visible, {
    required DateTime now,
  }) {
    for (var i = 0; i < visible.length; i++) {
      final schedule = visible[i];
      if (!AppDateTime.isTodayLocal(schedule.startTime, now: now)) continue;
      final next = i + 1 < visible.length ? visible[i + 1] : null;
      final segmentEnd = _effectiveEnd(schedule, next);
      if (AppDateTime.toLocal(segmentEnd).isAfter(now)) return i;
    }
    return null;
  }

  static DateTime _effectiveEnd(EventSchedule current, EventSchedule? next) {
    if (current.endTime != null) {
      return AppDateTime.toLocal(current.endTime!);
    }
    if (next != null) {
      return AppDateTime.toLocal(next.startTime);
    }
    return AppDateTime.toLocal(current.startTime).add(const Duration(minutes: 45));
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

    final todayList = visible
        .where((s) => AppDateTime.isTodayLocal(s.startTime, now: clock))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    if (todayList.isEmpty) return true;

    for (var i = 0; i < todayList.length; i++) {
      final next = i + 1 < todayList.length ? todayList[i + 1] : null;
      if (!CalendarNowAnchor.scheduleIsPast(todayList[i], next: next, now: clock)) {
        return false;
      }
    }
    return true;
  }
}
