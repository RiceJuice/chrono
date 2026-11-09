import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/homework/domain/next_lesson_for_subject.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pickNextLessonForSubject', () {
    final now = DateTime(2026, 6, 26, 10);

    CalendarEntry lesson({
      required String id,
      required String subjectId,
      required DateTime start,
    }) {
      return CalendarEntry(
        id: id,
        eventName: 'Stunde $subjectId',
        startTime: start,
        endTime: start.add(const Duration(hours: 1)),
        accentColor: Colors.blue,
        type: CalendarEntryType.lesson,
        subjectId: subjectId,
      );
    }

    test('selected day resolves earliest matching subject lesson only', () {
      final entries = [
        lesson(
          id: 'later',
          subjectId: 'math',
          start: DateTime(2026, 6, 28, 11),
        ),
        lesson(id: 'first', subjectId: 'math', start: DateTime(2026, 6, 28, 8)),
        lesson(
          id: 'other',
          subjectId: 'english',
          start: DateTime(2026, 6, 28, 7),
        ),
        lesson(
          id: 'next-day',
          subjectId: 'math',
          start: DateTime(2026, 6, 29, 7),
        ),
      ];
      expect(
        pickLessonForSubjectOnDay(
          entries: entries,
          subjectId: 'math',
          day: DateTime(2026, 6, 28),
        )?.id,
        'first',
      );
      expect(
        pickLessonForSubjectOnDay(
          entries: entries,
          subjectId: 'math',
          day: DateTime(2026, 6, 30),
        ),
        isNull,
      );
    });

    test('returns earliest upcoming lesson for subject', () {
      final entries = [
        lesson(id: 'later', subjectId: 'math', start: DateTime(2026, 6, 27, 8)),
        lesson(
          id: 'earlier',
          subjectId: 'math',
          start: DateTime(2026, 6, 26, 12),
        ),
        lesson(
          id: 'other-subject',
          subjectId: 'english',
          start: DateTime(2026, 6, 26, 11),
        ),
      ];

      final next = pickNextLessonForSubject(
        entries: entries,
        subjectId: 'math',
        now: now,
      );

      expect(next?.id, 'earlier');
    });

    test('ignores past lessons and non-lesson entries', () {
      final entries = [
        lesson(id: 'past', subjectId: 'math', start: DateTime(2026, 6, 26, 8)),
        CalendarEntry(
          id: 'event',
          eventName: 'Event',
          startTime: DateTime(2026, 6, 27, 8),
          endTime: DateTime(2026, 6, 27, 9),
          accentColor: Colors.red,
          type: CalendarEntryType.event,
          subjectId: 'math',
        ),
      ];

      final next = pickNextLessonForSubject(
        entries: entries,
        subjectId: 'math',
        now: now,
      );

      expect(next, isNull);
    });
  });
}
