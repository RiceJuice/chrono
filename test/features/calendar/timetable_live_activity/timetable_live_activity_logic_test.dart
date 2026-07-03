import 'package:chronoapp/core/database/backend_enums.dart';
import 'package:chronoapp/features/calendar/domain/filter/calendar_filter_defaults.dart';
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
      String? location,
      String? className,
      BackendSchoolTrack schoolTrack = BackendSchoolTrack.unknown,
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
        location: location,
        className: className,
        choir: BackendChoir.unknown,
        voice: BackendVoice.unknown,
        schoolTrack: schoolTrack,
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

    test('nutzt Raum als Untertitel und Fachkürzel im Segment', () {
      final day = DateTime(2026, 7, 2);
      final entries = [
        lesson(
          id: 'l1',
          name: 'Mathematik',
          location: 'A102',
          className: '10a',
          start: DateTime(2026, 7, 2, 8, 0),
          duration: const Duration(hours: 1),
        ),
        lesson(
          id: 'l2',
          name: 'Englisch',
          location: 'B204',
          className: '10a',
          start: DateTime(2026, 7, 2, 9, 0),
          duration: const Duration(hours: 1),
        ),
      ];

      final snapshot = TimetableLiveActivityResolver.resolve(
        day: day,
        entries: entries,
        filters: filters,
        resolveAccent: (e) => e.accentColor,
        now: DateTime(2026, 7, 2, 8, 15),
      );

      expect(snapshot, isNotNull);
      expect(snapshot!.currentSubtitle, 'A102');
      expect(snapshot.nextSubtitle, 'B204');

      final segments = snapshot.segments;
      expect(segments.first.shortTitle, 'Mat');
      expect(segments[1].shortTitle, 'Eng');
    });

    test('zählt nur gefilterte Stunden in Noch X Stunden', () {
      final day = DateTime(2026, 7, 2);
      final filters = calendarFiltersStateFromProfileFields(className: '10a');
      final entries = [
        lesson(
          id: 'l1',
          name: 'Physik',
          className: '10a',
          start: DateTime(2026, 7, 2, 8, 0),
          duration: const Duration(hours: 1),
        ),
        lesson(
          id: 'l2',
          name: 'Chemie',
          className: '10b',
          start: DateTime(2026, 7, 2, 9, 0),
          duration: const Duration(hours: 1),
        ),
        lesson(
          id: 'l3',
          name: 'Englisch',
          className: '10a',
          start: DateTime(2026, 7, 2, 10, 0),
          duration: const Duration(hours: 1),
        ),
        lesson(
          id: 'l4',
          name: 'Bio',
          className: '10b',
          start: DateTime(2026, 7, 2, 11, 0),
          duration: const Duration(hours: 1),
        ),
      ];

      final snapshot = TimetableLiveActivityResolver.resolve(
        day: day,
        entries: entries,
        filters: filters,
        resolveAccent: (e) => e.accentColor,
        now: DateTime(2026, 7, 2, 8, 15),
      );

      expect(snapshot, isNotNull);
      expect(snapshot!.segments.where((s) => s.isLesson).length, 2);
      expect(snapshot.remainingLessons, 1);
      expect(snapshot.currentTitle, 'Physik');
      expect(snapshot.nextTitle, 'Englisch');
    });

    test('schließt laufende Stunde aus Noch X Stunden aus', () {
      final day = DateTime(2026, 7, 2);
      final entries = [
        lesson(
          id: 'l1',
          start: DateTime(2026, 7, 2, 8, 0),
          duration: const Duration(hours: 1),
        ),
        lesson(
          id: 'l2',
          start: DateTime(2026, 7, 2, 9, 0),
          duration: const Duration(hours: 1),
        ),
        lesson(
          id: 'l3',
          start: DateTime(2026, 7, 2, 10, 0),
          duration: const Duration(hours: 1),
        ),
      ];

      final snapshot = TimetableLiveActivityResolver.resolve(
        day: day,
        entries: entries,
        filters: filters,
        resolveAccent: (e) => e.accentColor,
        now: DateTime(2026, 7, 2, 8, 15),
      );

      expect(snapshot, isNotNull);
      expect(snapshot!.remainingLessons, 2);
    });

    test('zählt nur Stunden des eigenen Schulzweigs', () {
      final day = DateTime(2026, 7, 2);
      final profileFilters = calendarFiltersStateFromProfileFields(
        className: '10a',
        schoolTrack: 'NTG',
      );
      final entries = [
        lesson(
          id: 'l1',
          name: 'Physik',
          className: '10a',
          schoolTrack: BackendSchoolTrack.ntg,
          start: DateTime(2026, 7, 2, 8, 0),
          duration: const Duration(hours: 1),
        ),
        lesson(
          id: 'l2',
          name: 'Musik',
          className: '10a',
          schoolTrack: BackendSchoolTrack.musisch,
          start: DateTime(2026, 7, 2, 9, 0),
          duration: const Duration(hours: 1),
        ),
        lesson(
          id: 'l3',
          name: 'Englisch',
          className: '10a',
          schoolTrack: BackendSchoolTrack.ntg,
          start: DateTime(2026, 7, 2, 10, 0),
          duration: const Duration(hours: 1),
        ),
      ];

      final snapshot = TimetableLiveActivityResolver.resolve(
        day: day,
        entries: entries,
        filters: profileFilters,
        resolveAccent: (e) => e.accentColor,
        now: DateTime(2026, 7, 2, 8, 15),
      );

      expect(snapshot, isNotNull);
      expect(snapshot!.segments.where((s) => s.isLesson).length, 2);
      expect(snapshot.remainingLessons, 1);
      expect(snapshot.currentTitle, 'Physik');
      expect(snapshot.nextTitle, 'Englisch');
    });

    test('behält Stunden ohne Schulzweig bei gesetztem Profil-Zweig', () {
      final day = DateTime(2026, 7, 2);
      final profileFilters = calendarFiltersStateFromProfileFields(
        className: '10a',
        schoolTrack: 'NTG',
      );
      final entries = [
        lesson(
          id: 'l1',
          name: 'Physik',
          className: '10a',
          schoolTrack: BackendSchoolTrack.ntg,
          start: DateTime(2026, 7, 2, 8, 0),
          duration: const Duration(hours: 1),
        ),
        lesson(
          id: 'l2',
          name: 'Ethik',
          className: '10a',
          start: DateTime(2026, 7, 2, 9, 0),
          duration: const Duration(hours: 1),
        ),
        lesson(
          id: 'l3',
          name: 'Musik',
          className: '10a',
          schoolTrack: BackendSchoolTrack.musisch,
          start: DateTime(2026, 7, 2, 10, 0),
          duration: const Duration(hours: 1),
        ),
      ];

      final snapshot = TimetableLiveActivityResolver.resolve(
        day: day,
        entries: entries,
        filters: profileFilters,
        resolveAccent: (e) => e.accentColor,
        now: DateTime(2026, 7, 2, 8, 15),
      );

      expect(snapshot, isNotNull);
      expect(snapshot!.segments.where((s) => s.isLesson).length, 2);
      expect(snapshot.currentTitle, 'Physik');
      expect(snapshot.nextTitle, 'Ethik');
    });

    test('behandelt Pause zwischen Stunden mit nächster Stunde links', () {
      final day = DateTime(2026, 7, 2);
      final entries = [
        lesson(
          id: 'l1',
          name: 'Mathematik',
          start: DateTime(2026, 7, 2, 9, 0),
          duration: const Duration(hours: 1, minutes: 15),
        ),
        lesson(
          id: 'l2',
          name: 'Englisch',
          start: DateTime(2026, 7, 2, 10, 35),
          duration: const Duration(minutes: 45),
        ),
        lesson(
          id: 'l3',
          name: 'Latein',
          start: DateTime(2026, 7, 2, 11, 20),
          duration: const Duration(minutes: 45),
        ),
      ];

      final snapshot = TimetableLiveActivityResolver.resolve(
        day: day,
        entries: entries,
        filters: filters,
        resolveAccent: (e) => e.accentColor,
        now: DateTime(2026, 7, 2, 10, 20),
      );

      expect(snapshot, isNotNull);
      expect(snapshot!.isPreStart, isTrue);
      expect(snapshot.currentTitle, 'Englisch');
      expect(snapshot.nextTitle, 'Latein');
      expect(snapshot.segmentStartMs, DateTime(2026, 7, 2, 10, 15).millisecondsSinceEpoch);
      expect(snapshot.segmentEndMs, DateTime(2026, 7, 2, 10, 35).millisecondsSinceEpoch);
      expect(snapshot.remainingLessons, 2);
    });
  });
}
