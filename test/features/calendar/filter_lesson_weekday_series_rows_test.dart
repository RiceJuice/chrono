import 'package:chronoapp/core/database/backend_enums.dart';
import 'package:chronoapp/features/calendar/event_editor/data/calendar_event_series_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('filterLessonWeekdaySeriesRows trennt NTG und Musisch', () {
    final rows = [
      const LessonWeekdaySeriesRow(
        id: 'ntg-series',
        schooltrack: 'NTG',
        rrule: 'RRULE:FREQ=WEEKLY;BYDAY=MO',
        seriesStart: '2026-01-05',
      ),
      const LessonWeekdaySeriesRow(
        id: 'musisch-series',
        schooltrack: 'Musisch',
        rrule: 'RRULE:FREQ=WEEKLY;BYDAY=FR',
        seriesStart: '2026-01-09',
      ),
    ];

    final ntgRows = filterLessonWeekdaySeriesRows(
      rows,
      schoolTrack: BackendSchoolTrack.ntg,
      seriesId: 'ntg-series',
    );
    final musischRows = filterLessonWeekdaySeriesRows(
      rows,
      schoolTrack: BackendSchoolTrack.musisch,
      seriesId: 'musisch-series',
    );

    expect(ntgRows.map((row) => row.id), ['ntg-series']);
    expect(musischRows.map((row) => row.id), ['musisch-series']);
  });

  test('filterLessonWeekdaySeriesRows nutzt seriesId als Fallback', () {
    final rows = [
      const LessonWeekdaySeriesRow(
        id: 'series-a',
        schooltrack: null,
        rrule: 'RRULE:FREQ=WEEKLY;BYDAY=TU',
        seriesStart: '2026-01-06',
      ),
      const LessonWeekdaySeriesRow(
        id: 'series-b',
        schooltrack: null,
        rrule: 'RRULE:FREQ=WEEKLY;BYDAY=TH',
        seriesStart: '2026-01-08',
      ),
    ];

    final filtered = filterLessonWeekdaySeriesRows(
      rows,
      schoolTrack: BackendSchoolTrack.ntg,
      seriesId: 'series-a',
    );

    expect(filtered.map((row) => row.id), ['series-a']);
  });
}
