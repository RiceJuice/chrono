import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/school_assessments/domain/models/school_assessment.dart';
import 'package:chronoapp/features/school_assessments/domain/models/school_assessment_kind.dart';
import 'package:chronoapp/features/school_assessments/domain/models/school_assessment_schedule_source.dart';
import 'package:chronoapp/features/school_assessments/domain/school_assessment_lesson_lookup.dart';
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

SchoolAssessment _assessment({
  required String subjectId,
  required DateTime scheduledAt,
}) {
  return SchoolAssessment(
    id: 'a1',
    profileId: 'p1',
    kind: SchoolAssessmentKind.schulaufgabe,
    subjectId: subjectId,
    scheduledAt: scheduledAt,
    scheduleSource: SchoolAssessmentScheduleSource.lessonSlot,
    createdAt: DateTime(2026, 3, 1),
  );
}

void main() {
  group('school assessment lesson lookup', () {
    test('builds stable lookup key from subject and lesson start', () {
      final start = DateTime.utc(2026, 3, 15, 8);
      final key = schoolAssessmentLessonLookupKey(
        subjectId: 'math',
        lessonStart: start,
      );
      expect(key, 'math|${start.millisecondsSinceEpoch}');
    });

    test('matches assessment to lesson with same subject and start', () {
      final start = DateTime.utc(2026, 3, 15, 8);
      final lesson = _lesson(subjectId: 'math', start: start);
      final assessment = _assessment(subjectId: 'math', scheduledAt: start);

      expect(
        isSchoolAssessmentForLesson(assessment: assessment, lesson: lesson),
        isTrue,
      );
    });

    test('does not match different subject or time', () {
      final start = DateTime.utc(2026, 3, 15, 8);
      final lesson = _lesson(subjectId: 'math', start: start);
      final otherSubject = _assessment(
        subjectId: 'deutsch',
        scheduledAt: start,
      );
      final otherTime = _assessment(
        subjectId: 'math',
        scheduledAt: start.add(const Duration(days: 7)),
      );

      expect(
        isSchoolAssessmentForLesson(assessment: otherSubject, lesson: lesson),
        isFalse,
      );
      expect(
        isSchoolAssessmentForLesson(assessment: otherTime, lesson: lesson),
        isFalse,
      );
    });
  });

  group('school assessment preview lesson', () {
    test('picks lesson closest to one week before scheduled assessment', () {
      final assessmentStart = DateTime.utc(2026, 3, 15, 8);
      final previewLesson = _lesson(
        subjectId: 'math',
        start: DateTime.utc(2026, 3, 8, 8),
      );
      final wrongSubject = _lesson(
        subjectId: 'deutsch',
        start: DateTime.utc(2026, 3, 8, 8),
      );
      final afterAssessment = _lesson(
        subjectId: 'math',
        start: DateTime.utc(2026, 3, 16, 8),
      );

      final preview = findPreviewLessonForAssessment(
        assessment: _assessment(
          subjectId: 'math',
          scheduledAt: assessmentStart,
        ),
        lessons: [
          wrongSubject,
          afterAssessment,
          previewLesson,
        ],
      );

      expect(preview?.id, previewLesson.id);
    });

    test('returns null when no prior lesson exists', () {
      final assessmentStart = DateTime.utc(2026, 3, 15, 8);
      final preview = findPreviewLessonForAssessment(
        assessment: _assessment(
          subjectId: 'math',
          scheduledAt: assessmentStart,
        ),
        lessons: [
          _lesson(
            subjectId: 'math',
            start: DateTime.utc(2026, 3, 16, 8),
          ),
        ],
      );

      expect(preview, isNull);
    });
  });
}
