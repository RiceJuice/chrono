import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/homework/domain/current_lesson_for_subject.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CalendarEntry _lesson({
  required DateTime start,
  required DateTime end,
  String subjectId = 'math',
}) {
  return CalendarEntry(
    id: 'l1',
    eventName: 'Mathe',
    startTime: start,
    endTime: end,
    accentColor: Colors.blue,
    type: CalendarEntryType.lesson,
    subjectId: subjectId,
  );
}

void main() {
  test('pickCurrentLesson wählt laufende Stunde mit 5-Min-Puffer', () {
    final now = DateTime(2026, 6, 27, 9, 3);
    final lesson = _lesson(
      start: DateTime(2026, 6, 27, 9, 0),
      end: DateTime(2026, 6, 27, 9, 45),
    );

    final picked = pickCurrentLesson(
      entries: [lesson],
      now: now,
    );

    expect(picked, lesson);
  });

  test('pickCurrentLesson ignoriert Stunde vor Puffer', () {
    final now = DateTime(2026, 6, 27, 8, 50);
    final lesson = _lesson(
      start: DateTime(2026, 6, 27, 9, 0),
      end: DateTime(2026, 6, 27, 9, 45),
    );

    final picked = pickCurrentLesson(
      entries: [lesson],
      now: now,
      startBuffer: const Duration(minutes: 5),
    );

    expect(picked, isNull);
  });

  test('pickCurrentLesson ignoriert vergangene Stunde', () {
    final now = DateTime(2026, 6, 27, 10, 0);
    final lesson = _lesson(
      start: DateTime(2026, 6, 27, 9, 0),
      end: DateTime(2026, 6, 27, 9, 45),
    );

    final picked = pickCurrentLesson(entries: [lesson], now: now);
    expect(picked, isNull);
  });

  test('pickCurrentLesson bevorzugt früheste überlappende Stunde', () {
    final now = DateTime(2026, 6, 27, 10, 10);
    final first = _lesson(
      start: DateTime(2026, 6, 27, 10, 0),
      end: DateTime(2026, 6, 27, 10, 45),
      subjectId: 'latin',
    );
    final second = _lesson(
      start: DateTime(2026, 6, 27, 10, 15),
      end: DateTime(2026, 6, 27, 11, 0),
      subjectId: 'math',
    );

    final picked = pickCurrentLesson(entries: [second, first], now: now);
    expect(picked?.subjectId, 'latin');
  });
}
