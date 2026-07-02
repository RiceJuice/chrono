import 'package:chronoapp/core/database/backend_enums.dart';
import 'package:chronoapp/features/calendar/domain/filter/calendar_filters_state.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/timetable_live_activity/domain/timetable_live_activity_resolver.dart';
import 'package:chronoapp/features/calendar/timetable_live_activity/timetable_live_activity_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimetableLiveActivityResolver', () {
    const filters = CalendarFiltersState();

    CalendarEntry lesson({
      required String id,
      required DateTime start,
      required Duration duration,
      String name = 'Mathe',
      Color color = const Color(0xFF124E30),
    }) {
      return CalendarEntry(
        id: id,
        eventName: name,
        startTime: start,
        endTime: start.add(duration),
        accentColor: color,
        type: CalendarEntryType.lesson,
        subjectId: 'sub-1',
        choir: BackendChoir.unknown,
        voice: BackendVoice.unknown,
        schoolTrack: BackendSchoolTrack.unknown,
        diet: BackendDiet.unknown,
      );
    }

    CalendarEntry lunch({
      required String id,
      required DateTime start,
      required Duration duration,
    }) {
      return CalendarEntry(
        id: id,
        eventName: 'Mittagessen',
        startTime: start,
        endTime: start.add(duration),
        accentColor: const Color(0xFF124E30),
        type: CalendarEntryType.meal,
        choir: BackendChoir.unknown,
        voice: BackendVoice.unknown,
        schoolTrack: BackendSchoolTrack.unknown,
        diet: BackendDiet.noRestriction,
      );
    }

    test('startet 15 min vor erster Stunde mit vollem Tagesplan', () {
      final day = DateTime(2026, 7, 2);
      final firstStart = DateTime(2026, 7, 2, 8, 0);
      final entries = [
        lesson(id: 'l1', start: firstStart, duration: const Duration(hours: 1)),
        lunch(
          id: 'm1',
          start: DateTime(2026, 7, 2, 12, 0),
          duration: const Duration(minutes: 45),
        ),
        lesson(
          id: 'l2',
          start: DateTime(2026, 7, 2, 13, 0),
          duration: const Duration(hours: 1),
        ),
      ];

      final preStart = DateTime(2026, 7, 2, 7, 45);
      final snapshot = TimetableLiveActivityResolver.resolve(
        day: day,
        entries: entries,
        filters: filters,
        resolveAccent: (e) => e.accentColor,
        now: preStart,
      );

      expect(snapshot, isNotNull);
      expect(snapshot!.segments.length, 3);
      expect(snapshot.isPreStart, isTrue);
      expect(snapshot.currentTitle, 'Mathe');
      expect(snapshot.remainingLessons, 2);
      expect(snapshot.customId, liveActivityCustomIdForTimetableDay('2026-07-02'));
      expect(snapshot.toActivityPayload()['kind'], kTimetableLiveActivityKind);
    });

    test('wechselt nativ zur Mittagspause mit zwei verbleibenden Stunden', () {
      final day = DateTime(2026, 7, 2);
      final entries = [
        lesson(
          id: 'l1',
          start: DateTime(2026, 7, 2, 8, 0),
          duration: const Duration(hours: 1),
        ),
        lunch(
          id: 'm1',
          start: DateTime(2026, 7, 2, 12, 0),
          duration: const Duration(minutes: 45),
        ),
        lesson(
          id: 'l2',
          start: DateTime(2026, 7, 2, 13, 0),
          duration: const Duration(hours: 1),
        ),
      ];

      final snapshot = TimetableLiveActivityResolver.resolve(
        day: day,
        entries: entries,
        filters: filters,
        resolveAccent: (e) => e.accentColor,
        now: DateTime(2026, 7, 2, 12, 10),
      );

      expect(snapshot, isNotNull);
      expect(snapshot!.isMeal, isTrue);
      expect(snapshot.currentTitle, 'Mittagessen');
      expect(snapshot.remainingLessons, 1);
      expect(snapshot.hasNext, isTrue);
      expect(snapshot.nextTitle, 'Mathe');
    });

    test('liefert null nach Tagesende', () {
      final day = DateTime(2026, 7, 2);
      final entries = [
        lesson(
          id: 'l1',
          start: DateTime(2026, 7, 2, 8, 0),
          duration: const Duration(hours: 1),
        ),
      ];

      final snapshot = TimetableLiveActivityResolver.resolve(
        day: day,
        entries: entries,
        filters: filters,
        resolveAccent: (e) => e.accentColor,
        now: DateTime(2026, 7, 2, 9, 5),
      );

      expect(snapshot, isNull);
    });
  });
}
