import 'package:powersync/powersync.dart';
import 'package:rrule/rrule.dart';

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
}
