import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/school_assessments/domain/resolve_assessment_lesson.dart';
import 'package:chronoapp/features/school_assessments/domain/upcoming_lessons_for_subject.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CalendarEntry _lesson({
  required String subjectId,
  required DateTime start,
}) {
  return CalendarEntry(
    id: 'lesson-${start.millisecondsSinceEpoch}',
    eventName: 'Mathematik',
    startTime: start,
    endTime: start.add(const Duration(hours: 1)),
    accentColor: Colors.blue,
    type: CalendarEntryType.lesson,
    subjectId: subjectId,
  );
}

void main() {
  group('upcomingLessonsForSubject', () {
    test('returns future lessons sorted by start time', () {
      final now = DateTime.utc(2026, 3, 10, 12);
      final lessons = upcomingLessonsForSubject(
        entries: [
          _lesson(subjectId: 'math', start: DateTime.utc(2026, 3, 12, 8)),
          _lesson(subjectId: 'math', start: DateTime.utc(2026, 3, 11, 8)),
          _lesson(subjectId: 'math', start: DateTime.utc(2026, 3, 9, 8)),
          _lesson(subjectId: 'deutsch', start: DateTime.utc(2026, 3, 11, 9)),
        ],
        subjectId: 'math',
        now: now,
      );

      expect(lessons.length, 2);
      expect(lessons.first.startTime, DateTime.utc(2026, 3, 11, 8));
      expect(lessons.last.startTime, DateTime.utc(2026, 3, 12, 8));
    });
  });

  group('resolveAssessmentLessonForCustomDate', () {
    test('finds lesson on selected local day for subject', () {
      final day = DateTime(2026, 3, 12);
      final lesson = _lesson(
        subjectId: 'math',
        start: DateTime.utc(2026, 3, 12, 7),
      );

      final resolved = resolveAssessmentLessonForCustomDate(
        entries: [
          lesson,
          _lesson(subjectId: 'math', start: DateTime.utc(2026, 3, 13, 7)),
        ],
        subjectId: 'math',
        day: day,
      );

      expect(resolved?.id, lesson.id);
    });

    test('returns null when no lesson exists on day', () {
      final resolved = resolveAssessmentLessonForCustomDate(
        entries: [
          _lesson(subjectId: 'math', start: DateTime.utc(2026, 3, 13, 7)),
        ],
        subjectId: 'math',
        day: DateTime(2026, 3, 12),
      );

      expect(resolved, isNull);
    });
  });
}
