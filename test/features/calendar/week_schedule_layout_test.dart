import 'package:chronoapp/core/database/backend_enums.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CalendarEntry _lesson({
  required String id,
  required DateTime start,
  required DateTime end,
  BackendSchoolTrack schoolTrack = BackendSchoolTrack.ntg,
}) {
  return CalendarEntry(
    id: id,
    eventName: id,
    startTime: start,
    endTime: end,
    accentColor: Colors.blue,
    type: CalendarEntryType.lesson,
    schoolTrack: schoolTrack,
  );
}

void main() {
  test('buildWeekEntryPlacements ordnet eigenen Schulzweig links', () {
    final day = DateTime(2024, 6, 15);
    final start = DateTime(2024, 6, 15, 8);
    final end = DateTime(2024, 6, 15, 9);
    final own = _lesson(
      id: 'own',
      start: start,
      end: end,
      schoolTrack: BackendSchoolTrack.musisch,
    );
    final other = _lesson(
      id: 'other',
      start: start,
      end: end,
      schoolTrack: BackendSchoolTrack.ntg,
    );

    final placements = buildWeekEntryPlacements(
      entries: [other, own],
      day: day,
      bounds: const WeekScheduleBounds(startMinute: 8 * 60, endMinute: 18 * 60),
      hourHeight: 72,
      ownSchoolTracks: ['musisch'],
    );

    expect(placements, hasLength(2));
    expect(placements.firstWhere((p) => p.entry.id == 'own').lane, 0);
    expect(placements.firstWhere((p) => p.entry.id == 'other').lane, 1);
  });
}
