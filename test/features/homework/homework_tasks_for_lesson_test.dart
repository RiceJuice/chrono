import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/homework/domain/homework_tasks_for_lesson.dart';
import 'package:chronoapp/features/homework/domain/models/homework_task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('homework tasks for lesson', () {
    final createdAt = DateTime(2026, 6, 26, 12);

    CalendarEntry lesson({
      required String id,
      required String subjectId,
      required DateTime start,
    }) {
      return CalendarEntry(
        id: id,
        eventName: 'Stunde',
        startTime: start,
        endTime: start.add(const Duration(hours: 1)),
        accentColor: Colors.blue,
        type: CalendarEntryType.lesson,
        subjectId: subjectId,
      );
    }

    HomeworkTask task({
      required String id,
      String? subjectId,
      DateTime? dueAt,
      bool isCompleted = false,
    }) {
      return HomeworkTask(
        id: id,
        title: 'Aufgabe $id',
        subjectId: subjectId,
        isCompleted: isCompleted,
        createdAt: createdAt,
        dueAt: dueAt,
      );
    }

    test('lessonHomeworkLookupKey is stable for same subject and instant', () {
      final start = DateTime(2026, 6, 28, 8);
      final keyA = lessonHomeworkLookupKey(
        subjectId: 'math',
        lessonStart: start,
      );
      final keyB = lessonHomeworkLookupKey(
        subjectId: ' math ',
        lessonStart: start.toLocal(),
      );

      expect(keyA, keyB);
    });

    test('matches open task with same subject and due instant', () {
      final start = DateTime(2026, 6, 28, 8);
      final entry = lesson(id: 'l1', subjectId: 'math', start: start);
      final openTask = task(
        id: 't1',
        subjectId: 'math',
        dueAt: start,
      );

      expect(
        isOpenHomeworkTaskForLesson(task: openTask, lesson: entry),
        isTrue,
      );
      expect(
        openHomeworkTasksForLesson(tasks: [openTask], lesson: entry),
        [openTask],
      );
    });

    test('ignores completed tasks', () {
      final start = DateTime(2026, 6, 28, 8);
      final entry = lesson(id: 'l1', subjectId: 'math', start: start);
      final completedTask = task(
        id: 't1',
        subjectId: 'math',
        dueAt: start,
        isCompleted: true,
      );

      expect(
        isOpenHomeworkTaskForLesson(task: completedTask, lesson: entry),
        isFalse,
      );
    });

    test('ignores wrong subject or different due instant', () {
      final start = DateTime(2026, 6, 28, 8);
      final entry = lesson(id: 'l1', subjectId: 'math', start: start);

      final wrongSubject = task(
        id: 't1',
        subjectId: 'english',
        dueAt: start,
      );
      final wrongTime = task(
        id: 't2',
        subjectId: 'math',
        dueAt: start.add(const Duration(hours: 1)),
      );

      expect(
        openHomeworkTasksForLesson(
          tasks: [wrongSubject, wrongTime],
          lesson: entry,
        ),
        isEmpty,
      );
    });

    test('returns multiple open tasks for the same lesson', () {
      final start = DateTime(2026, 6, 28, 8);
      final entry = lesson(id: 'l1', subjectId: 'math', start: start);
      final first = task(id: 't1', subjectId: 'math', dueAt: start);
      final second = task(id: 't2', subjectId: 'math', dueAt: start);

      expect(
        openHomeworkTasksForLesson(tasks: [first, second], lesson: entry),
        [first, second],
      );
    });
  });
}
