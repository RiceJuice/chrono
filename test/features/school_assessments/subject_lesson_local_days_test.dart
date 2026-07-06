import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/school_assessments/domain/subject_lesson_local_days.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CalendarEntry _lesson({
  required String subjectId,
  required DateTime start,
}) {
  return CalendarEntry(
    id: 'lesson-${start.millisecondsSinceEpoch}',
    eventName: 'Mathe',
    startTime: start,
    endTime: start.add(const Duration(hours: 1)),
    accentColor: Colors.blue,
    type: CalendarEntryType.lesson,
    subjectId: subjectId,
  );
}

void main() {
  test('subjectLessonLocalDays sammelt lokale Tage pro Fach', () {
    final days = subjectLessonLocalDays(
      entries: [
        _lesson(
          subjectId: 'math',
          start: DateTime.utc(2026, 3, 10, 7),
        ),
        _lesson(
          subjectId: 'math',
          start: DateTime.utc(2026, 3, 12, 7),
        ),
        _lesson(
          subjectId: 'deutsch',
          start: DateTime.utc(2026, 3, 10, 9),
        ),
      ],
      subjectId: 'math',
    );

    expect(days.length, 2);
    expect(
      days.contains(AppDateTime.localDay(DateTime.utc(2026, 3, 10, 7))),
      isTrue,
    );
    expect(
      days.contains(AppDateTime.localDay(DateTime.utc(2026, 3, 12, 7))),
      isTrue,
    );
  });
}
