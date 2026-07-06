import 'dart:async';

import 'package:chronoapp/core/database/powersync_schema.dart';
import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/domain/filter/calendar_filters_state.dart';
import 'package:chronoapp/features/calendar/domain/meal_period.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:chronoapp/features/calendar/domain/filter/calendar_display_filters.dart';
import 'package:chronoapp/features/calendar/domain/layout/school_track_lane_order.dart';
import 'package:chronoapp/features/calendar/timetable_live_activity/domain/timetable_live_activity_resolver.dart';
import 'package:powersync/powersync.dart';

/// Lokale Abfragen für Stundenplan-Live-Activities.
class TimetableLiveActivityDataSource {
  TimetableLiveActivityDataSource(this._repository);

  final CalendarRepository _repository;

  Stream<List<CalendarEntry>> watchEntriesForDay(DateTime day) {
    return _repository.watchEntriesForDay(day);
  }

  Future<List<CalendarEntry>> entriesForDay(DateTime day) async {
    return watchEntriesForDay(day).first;
  }

  Stream<void> watchTimetableChanges() {
    return _repository.watchEntriesForDay(AppDateTime.todayLocal()).map((_) {});
  }

  /// Für lokale Notification-Planung: Activity-Start (15 min vor erster eigener Stunde).
  Future<List<({String dayDateKey, DateTime at})>> upcomingActivityStarts({
    required DateTime rangeStart,
    required DateTime rangeEndExclusive,
    required CalendarFiltersState filters,
  }) async {
    final out = <({String dayDateKey, DateTime at})>[];
    var day = AppDateTime.localDay(rangeStart);
    final endDay = AppDateTime.localDay(rangeEndExclusive);

    while (!day.isAfter(endDay)) {
      final entries = await entriesForDay(day);
      final activityStart = TimetableLiveActivityResolver.activityStartForDay(
        day: day,
        entries: entries,
        filters: filters,
      );
      if (activityStart != null &&
          !activityStart.isBefore(rangeStart) &&
          activityStart.isBefore(rangeEndExclusive)) {
        out.add((dayDateKey: _dayKey(day), at: activityStart));
      }

      day = AppDateTime.addLocalCalendarDays(day, 1);
    }

    return out;
  }

  /// Segmentgrenzen für lokale Timer (Start/Ende jedes Segments).
  Future<List<({String dayDateKey, String segmentId, DateTime at})>>
      upcomingSegmentBoundaries({
    required DateTime rangeStart,
    required DateTime rangeEndExclusive,
    required CalendarFiltersState filters,
  }) async {
    final out = <({String dayDateKey, String segmentId, DateTime at})>[];
    var day = AppDateTime.localDay(rangeStart);
    final endDay = AppDateTime.localDay(rangeEndExclusive);

    while (!day.isAfter(endDay)) {
      final entries = await entriesForDay(day);
      final dayKey = _dayKey(day);
      final filtered = applyCalendarDisplayFilters(
        entries: entries,
        filters: filters,
        hideUnknownWhenFilterActive:
            filters.hasInitializedDefaults && filters.hasActiveFilters,
        forEventList: true,
      ).where((entry) {
        if (entry.type != CalendarEntryType.lesson &&
            entry.type != CalendarEntryType.meal) {
          return false;
        }
        if (entry.type == CalendarEntryType.meal &&
            resolveMealPeriod(entry.startTime) != MealPeriod.lunch) {
          return false;
        }
        return lessonMatchesOwnSchoolProfile(entry: entry, filters: filters);
      }).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      for (final entry in filtered) {
        final start = AppDateTime.toLocal(entry.startTime);
        final end = AppDateTime.toLocal(entry.endTime);
        if (start.isAfter(rangeStart) && start.isBefore(rangeEndExclusive)) {
          out.add((dayDateKey: dayKey, segmentId: entry.id, at: start));
        }
        if (end.isAfter(rangeStart) && end.isBefore(rangeEndExclusive)) {
          out.add((dayDateKey: dayKey, segmentId: '${entry.id}_end', at: end));
        }
      }

      day = AppDateTime.addLocalCalendarDays(day, 1);
    }

    return out;
  }

  Future<List<({String dayDateKey, DateTime end})>> upcomingDayEnds({
    required DateTime rangeStart,
    required DateTime rangeEndExclusive,
    required CalendarFiltersState filters,
  }) async {
    final out = <({String dayDateKey, DateTime end})>[];
    var day = AppDateTime.localDay(rangeStart);
    final endDay = AppDateTime.localDay(rangeEndExclusive);

    while (!day.isAfter(endDay)) {
      final entries = await entriesForDay(day);
      final dayEnd = TimetableLiveActivityResolver.dayEndForDay(
        day: day,
        entries: entries,
        filters: filters,
      );
      if (dayEnd != null &&
          !dayEnd.isBefore(rangeStart) &&
          dayEnd.isBefore(rangeEndExclusive)) {
        out.add((dayDateKey: _dayKey(day), end: dayEnd));
      }
      day = AppDateTime.addLocalCalendarDays(day, 1);
    }

    return out;
  }

  String _dayKey(DateTime day) {
    final local = AppDateTime.localDay(day);
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

/// Triggert auf Kalenderänderungen (Events + Serien).
Stream<void> watchTimetableCalendarChanges(PowerSyncDatabase db) {
  return db
      .watch(
        'SELECT COUNT(*) AS c FROM $kCalendarEventsTable',
        triggerOnTables: const {
          kCalendarEventsTable,
          kCalendarSeriesTable,
          kSubjectsTable,
        },
      )
      .map((_) {});
}
