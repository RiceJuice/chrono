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
        seriesId: seriesId,
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
    String? seriesId,
    required BackendSchoolTrack schoolTrack,
    required int fallbackWeekday,
  }) {
    return _db
        .watch(
          '''
          SELECT id, rrule, series_start, schooltrack
          FROM $kCalendarSeriesTable
          WHERE subject_id = ? AND type = 'lesson'
          ''',
          parameters: [subjectId],
          triggerOnTables: const {kCalendarSeriesTable},
        )
        .map((rows) {
          final filtered = filterLessonWeekdaySeriesRows(
            rows.map(_lessonWeekdaySeriesRowData),
            schoolTrack: schoolTrack,
            seriesId: seriesId,
          );
          return _resolveWeekdaysFromRowData(
            filtered,
            fallbackWeekday: fallbackWeekday,
          );
        });
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
    return _resolveWeekdaysFromRowData(
      rows.map(_lessonWeekdaySeriesRowData),
      fallbackWeekday: fallbackWeekday,
    );
  }

  Set<int> _resolveWeekdaysFromRowData(
    Iterable<LessonWeekdaySeriesRow> rows, {
    required int fallbackWeekday,
  }) {
    final weekdays = _aggregateWeekdaysFromRows(rows);
    return weekdays.isEmpty ? {fallbackWeekday} : weekdays;
  }

  Set<int> _aggregateWeekdaysFromRows(Iterable<LessonWeekdaySeriesRow> rows) {
    final weekdays = <int>{};
    for (final row in rows) {
      final seriesStartRaw = row.seriesStart;
      if (seriesStartRaw == null || seriesStartRaw.trim().isEmpty) {
        continue;
      }

      final seriesStart = AppDateTime.localDay(
        DateTime.parse(seriesStartRaw.trim()),
      );
      final parsed = CalendarEventRruleCodec.fromStorageText(
        row.rrule,
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

class LessonWeekdaySeriesRow {
  const LessonWeekdaySeriesRow({
    required this.id,
    required this.schooltrack,
    required this.rrule,
    required this.seriesStart,
  });

  final String id;
  final String? schooltrack;
  final String? rrule;
  final String? seriesStart;
}

LessonWeekdaySeriesRow _lessonWeekdaySeriesRowData(Row row) {
  return LessonWeekdaySeriesRow(
    id: row['id']?.toString() ?? '',
    schooltrack: row['schooltrack']?.toString(),
    rrule: row['rrule']?.toString(),
    seriesStart: row['series_start']?.toString(),
  );
}

/// Serienzeilen für die Wochentags-Anzeige nach Schulzweig filtern.
List<LessonWeekdaySeriesRow> filterLessonWeekdaySeriesRows(
  Iterable<LessonWeekdaySeriesRow> rows, {
  required BackendSchoolTrack schoolTrack,
  String? seriesId,
}) {
  final rowList = rows.toList(growable: false);
  if (schoolTrack == BackendSchoolTrack.unknown) {
    return rowList;
  }

  final matching = rowList
      .where(
        (row) =>
            BackendSchoolTrackCodec.fromBackend(row.schooltrack) == schoolTrack,
      )
      .toList(growable: false);
  if (matching.isNotEmpty) {
    return matching;
  }

  final normalizedSeriesId = seriesId?.trim();
  if (normalizedSeriesId == null || normalizedSeriesId.isEmpty) {
    return const [];
  }

  return rowList
      .where((row) => row.id == normalizedSeriesId)
      .toList(growable: false);
}
