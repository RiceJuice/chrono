import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/helpers/lesson_week_grid_display_name.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('lessonWeekGridDisplayName', () {
    test('shortens common lesson names for week grid', () {
      expect(lessonWeekGridDisplayName('Mathematik'), 'Mathe');
      expect(lessonWeekGridDisplayName('Wirtschaft und Recht'), 'WuR');
      expect(lessonWeekGridDisplayName('Politik und Gesellschaft'), 'PuG');
      expect(lessonWeekGridDisplayName('Erdkunde'), 'Geo');
      expect(lessonWeekGridDisplayName('Geographie'), 'Geo');
      expect(lessonWeekGridDisplayName('Geo'), 'Geo');
    });

    test('keeps unknown lesson names unchanged', () {
      expect(lessonWeekGridDisplayName('Englisch'), 'Englisch');
    });
  });

  group('calendarEntryCardTitle', () {
    CalendarEntry lesson(String name) {
      final start = DateTime(2026, 6, 28, 8);
      return CalendarEntry(
        id: 'l1',
        eventName: name,
        startTime: start,
        endTime: start.add(const Duration(hours: 1)),
        accentColor: Colors.blue,
        type: CalendarEntryType.lesson,
        subjectId: 'math',
      );
    }

    test('abbreviates only compact lesson cards', () {
      final entry = lesson('Mathematik');
      expect(calendarEntryCardTitle(entry, compact: true), 'Mathe');
      expect(calendarEntryCardTitle(entry, compact: false), 'Mathematik');
    });
  });
}
