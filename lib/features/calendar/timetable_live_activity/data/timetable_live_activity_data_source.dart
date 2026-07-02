import 'dart:async';

import 'package:chronoapp/core/database/powersync_schema.dart';
import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/domain/repositories/calendar_repository.dart';
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

  /// Für lokale Notification-Planung: Activity-Start (15 min vor erster Stunde).
  Future<List<({String dayDateKey, DateTime at})>> upcomingActivityStarts({
    required DateTime rangeStart,
    required DateTime rangeEndExclusive,
  }) async {
    final out = <({String dayDateKey, DateTime at})>[];
    var day = AppDateTime.localDay(rangeStart);
    final endDay = AppDateTime.localDay(rangeEndExclusive);

    while (!day.isAfter(endDay)) {
      final entries = await entriesForDay(day);
      final lessons = entries
          .where((e) => e.type == CalendarEntryType.lesson)
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      if (lessons.isNotEmpty) {
        final firstStart = AppDateTime.toLocal(lessons.first.startTime);
        final activityStart = firstStart.subtract(
          const Duration(minutes: 15),
        );
        if (!activityStart.isBefore(rangeStart) &&
            activityStart.isBefore(rangeEndExclusive)) {
          out.add((
            dayDateKey: _dayKey(day),
            at: activityStart,
          ));
        }
      }

      day = AppDateTime.addLocalCalendarDays(day, 1);
    }

    return out;
  }

  Future<List<({String dayDateKey, DateTime end})>> upcomingDayEnds({
    required DateTime rangeStart,
    required DateTime rangeEndExclusive,
  }) async {
    final out = <({String dayDateKey, DateTime end})>[];
    var day = AppDateTime.localDay(rangeStart);
    final endDay = AppDateTime.localDay(rangeEndExclusive);

    while (!day.isAfter(endDay)) {
      final entries = await entriesForDay(day);
      final relevant = entries
          .where(
            (e) =>
                e.type == CalendarEntryType.lesson ||
                e.type == CalendarEntryType.meal,
          )
          .toList();
      if (relevant.isNotEmpty) {
        final last = relevant.reduce(
          (a, b) => a.endTime.isAfter(b.endTime) ? a : b,
        );
        final localEnd = AppDateTime.toLocal(last.endTime);
        if (!localEnd.isBefore(rangeStart) &&
            localEnd.isBefore(rangeEndExclusive)) {
          out.add((dayDateKey: _dayKey(day), end: localEnd));
        }
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
