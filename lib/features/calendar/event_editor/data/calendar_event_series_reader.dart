import 'package:powersync/powersync.dart';
import 'package:rrule/rrule.dart';
import 'package:sqlite3/common.dart';

import '../../../../core/database/backend_enums.dart';
import '../../../../core/database/powersync_schema.dart';
import '../../../../core/time/app_date_time.dart';
import '../domain/calendar_series_edit_state.dart';
import 'calendar_event_rrule_codec.dart';
import 'calendar_event_series_codec.dart';

class CalendarEventSeriesSnapshot {
  CalendarEventSeriesSnapshot({
    required this.seriesId,
    required this.series,
    this.subjectId,
  });

  final String seriesId;
  final CalendarSeriesEditState series;
  final String? subjectId;
}

class CalendarEventSeriesReader {
  CalendarEventSeriesReader(this._db);

  final PowerSyncDatabase _db;

  Future<CalendarEventSeriesSnapshot?> read(String seriesId) async {
    final rows = await _db.getAll(
      '''
      SELECT rrule, series_start, series_end, subject_id
      FROM $kCalendarSeriesTable
      WHERE id = ?
      LIMIT 1
      ''',
      [seriesId],
    );
    if (rows.isEmpty) return null;

    final row = rows.first;
    final seriesStartRaw = row['series_start']?.toString();
    if (seriesStartRaw == null || seriesStartRaw.trim().isEmpty) {
      return null;
    }

    final seriesStart = AppDateTime.localDay(DateTime.parse(seriesStartRaw.trim()));
    final seriesEnd = CalendarEventSeriesCodec.parseSeriesDateOrNull(row['series_end']);

    final parsed = CalendarEventRruleCodec.fromStorageText(
      row['rrule']?.toString(),
      fallbackSeriesStart: seriesStart,
    );

    final series = (parsed ?? CalendarSeriesEditState(
      frequency: Frequency.weekly,
      weekdays: {seriesStart.weekday},
      seriesStart: seriesStart,
    )).copyWith(
      seriesStart: seriesStart,
      seriesEnd: seriesEnd,
    );

    final subjectId = row['subject_id']?.toString().trim();
    return CalendarEventSeriesSnapshot(
      seriesId: seriesId,
      series: series,
      subjectId: subjectId == null || subjectId.isEmpty ? null : subjectId,
    );
  }

  Stream<Set<int>> watchLessonWeekdays({
    required String? subjectId,
    required String? seriesId,
    required BackendSchoolTrack schoolTrack,
    required int fallbackWeekday,
  }) {
    if (subjectId != null && subjectId.isNotEmpty) {
      return watchWeekdaysForSubject(
        subjectId,
        schoolTrack: schoolTrack,
        fallbackWeekday: fallbackWeekday,
      );
    }
    if (seriesId != null && seriesId.isNotEmpty) {
      return watchWeekdaysForSeries(
        seriesId,
        fallbackWeekday: fallbackWeekday,
      );
    }
    return Stream<Set<int>>.value({fallbackWeekday});
  }

  Stream<Set<int>> watchWeekdaysForSubject(
    String subjectId, {
    required BackendSchoolTrack schoolTrack,
    required int fallbackWeekday,
  }) {
    final schoolTrackFilter = schoolTrack.toBackend();
    final query = schoolTrackFilter == null
        ? '''
          SELECT rrule, series_start
          FROM $kCalendarSeriesTable
          WHERE subject_id = ? AND type = 'lesson'
          '''
        : '''
          SELECT rrule, series_start
          FROM $kCalendarSeriesTable
          WHERE subject_id = ?
            AND type = 'lesson'
            AND LOWER(COALESCE(schooltrack, '')) = LOWER(?)
          ''';
    final parameters = schoolTrackFilter == null
        ? [subjectId]
        : [subjectId, schoolTrackFilter];

    return _db
        .watch(
          query,
          parameters: parameters,
          triggerOnTables: const {kCalendarSeriesTable},
        )
        .map((rows) => _resolveWeekdays(rows, fallbackWeekday: fallbackWeekday));
  }

  Stream<Set<int>> watchWeekdaysForSeries(
    String seriesId, {
    required int fallbackWeekday,
  }) {
    return _db
        .watch(
          '''
          SELECT rrule, series_start
          FROM $kCalendarSeriesTable
          WHERE id = ?
          LIMIT 1
          ''',
          parameters: [seriesId],
          triggerOnTables: const {kCalendarSeriesTable},
        )
        .map((rows) => _resolveWeekdays(rows, fallbackWeekday: fallbackWeekday));
  }

  Set<int> _resolveWeekdays(
    ResultSet rows, {
    required int fallbackWeekday,
  }) {
    final weekdays = _aggregateWeekdaysFromRows(rows);
    return weekdays.isEmpty ? {fallbackWeekday} : weekdays;
  }

  Set<int> _aggregateWeekdaysFromRows(ResultSet rows) {
    final weekdays = <int>{};
    for (final row in rows) {
      final seriesStartRaw = row['series_start']?.toString();
      if (seriesStartRaw == null || seriesStartRaw.trim().isEmpty) {
        continue;
      }

      final seriesStart = AppDateTime.localDay(
        DateTime.parse(seriesStartRaw.trim()),
      );
      final parsed = CalendarEventRruleCodec.fromStorageText(
        row['rrule']?.toString(),
        fallbackSeriesStart: seriesStart,
      );
      if (parsed == null || parsed.frequency != Frequency.weekly) {
        continue;
      }
      weekdays.addAll(parsed.weekdays);
    }
    return weekdays;
  }
}
