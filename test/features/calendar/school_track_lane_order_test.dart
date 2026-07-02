import 'package:chronoapp/core/database/backend_enums.dart';
import 'package:chronoapp/features/calendar/domain/layout/school_track_lane_order.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/day_schedule_layout.dart';
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
  group('schoolTrackLanePriority', () {
    test('eigener Schulzweig steht vor fremden Zweigen', () {
      final own = _lesson(
        id: 'own',
        start: DateTime(2024, 6, 15, 8),
        end: DateTime(2024, 6, 15, 9),
        schoolTrack: BackendSchoolTrack.musisch,
      );
      final other = _lesson(
        id: 'other',
        start: DateTime(2024, 6, 15, 8),
        end: DateTime(2024, 6, 15, 9),
        schoolTrack: BackendSchoolTrack.ntg,
      );

      expect(
        schoolTrackLanePriority(own, ownSchoolTracks: ['musisch']),
        lessThan(schoolTrackLanePriority(other, ownSchoolTracks: ['musisch'])),
      );
    });

    test('fremde Schulzweige folgen fester Reihenfolge NTG vor Musisch', () {
      final ntg = _lesson(
        id: 'ntg',
        start: DateTime(2024, 6, 15, 8),
        end: DateTime(2024, 6, 15, 9),
        schoolTrack: BackendSchoolTrack.ntg,
      );
      final musisch = _lesson(
        id: 'musisch',
        start: DateTime(2024, 6, 15, 8),
        end: DateTime(2024, 6, 15, 9),
        schoolTrack: BackendSchoolTrack.musisch,
      );

      expect(
        schoolTrackLanePriority(ntg, ownSchoolTracks: const []),
        lessThan(schoolTrackLanePriority(musisch, ownSchoolTracks: const [])),
      );
    });
  });

  group('buildDayScheduleListItems', () {
    test('gruppiert überlappende Schulstunden in einer Zeile', () {
      final start = DateTime(2024, 6, 15, 8);
      final end = DateTime(2024, 6, 15, 9);
      final own = _lesson(
        id: 'own',
        start: start,
        end: end,
        schoolTrack: BackendSchoolTrack.ntg,
      );
      final other = _lesson(
        id: 'other',
        start: start,
        end: end,
        schoolTrack: BackendSchoolTrack.musisch,
      );
      final meal = CalendarEntry(
        id: 'meal',
        eventName: 'Mensa',
        startTime: DateTime(2024, 6, 15, 12),
        endTime: DateTime(2024, 6, 15, 13),
        accentColor: Colors.green,
        type: CalendarEntryType.meal,
      );

      final items = buildDayScheduleListItems(
        entries: [other, meal, own],
        ownSchoolTracks: ['ntg'],
      );

      expect(items, hasLength(2));
      expect(items.first, isA<DayScheduleLessonRowItem>());
      final row = items.first as DayScheduleLessonRowItem;
      expect(row.lessons.map((lesson) => lesson.id), ['own', 'other']);
      expect(items.last, isA<DayScheduleSingleItem>());
    });

    test('lässt nicht überlappende Schulstunden getrennt', () {
      final items = buildDayScheduleListItems(
        entries: [
          _lesson(
            id: 'a',
            start: DateTime(2024, 6, 15, 8),
            end: DateTime(2024, 6, 15, 9),
          ),
          _lesson(
            id: 'b',
            start: DateTime(2024, 6, 15, 10),
            end: DateTime(2024, 6, 15, 11),
          ),
        ],
        ownSchoolTracks: const ['ntg'],
      );

      expect(items.every((item) => item is DayScheduleSingleItem), isTrue);
    });
  });
}
