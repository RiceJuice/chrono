import 'package:chronoapp/features/homework/domain/models/homework_task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeworkTask', () {
    final createdAt = DateTime(2026, 6, 26, 12, 30);
    final completedAt = DateTime(2026, 6, 26, 14, 0);
    final dueAt = DateTime(2026, 6, 28, 8);

    test('serializes and deserializes round-trip', () {
      final task = HomeworkTask(
        id: 'task-1',
        title: 'Mathe üben',
        description: 'Aufgaben 3–7',
        subjectId: 'subject-math',
        isCompleted: true,
        createdAt: createdAt,
        completedAt: completedAt,
        dueAt: dueAt,
        dueSource: HomeworkDueSource.nextLesson,
      );

      final restored = HomeworkTask.fromJson(task.toJson());

      expect(restored.id, task.id);
      expect(restored.title, task.title);
      expect(restored.description, task.description);
      expect(restored.subjectId, task.subjectId);
      expect(restored.isCompleted, task.isCompleted);
      expect(restored.createdAt, createdAt);
      expect(restored.completedAt, completedAt);
      expect(restored.dueAt, dueAt);
      expect(restored.dueSource, HomeworkDueSource.nextLesson);
    });

    test('sortHomeworkTasks keeps open tasks before completed ones', () {
      final open = HomeworkTask(
        id: 'open',
        title: 'Offen',
        isCompleted: false,
        createdAt: DateTime(2026, 6, 25),
      );
      final done = HomeworkTask(
        id: 'done',
        title: 'Erledigt',
        isCompleted: true,
        createdAt: DateTime(2026, 6, 27),
        completedAt: DateTime(2026, 6, 27),
      );

      final sorted = sortHomeworkTasks([done, open]);

      expect(sorted.map((task) => task.id).toList(), ['open', 'done']);
    });

    test('sortHomeworkTasks orders open tasks by dueAt ascending', () {
      final later = HomeworkTask(
        id: 'later',
        title: 'Später',
        isCompleted: false,
        createdAt: DateTime(2026, 6, 27),
        dueAt: DateTime(2026, 6, 30),
        dueSource: HomeworkDueSource.customDate,
      );
      final sooner = HomeworkTask(
        id: 'sooner',
        title: 'Früher',
        isCompleted: false,
        createdAt: DateTime(2026, 6, 25),
        dueAt: DateTime(2026, 6, 28),
        dueSource: HomeworkDueSource.nextLesson,
      );
      final noDue = HomeworkTask(
        id: 'no-due',
        title: 'Ohne',
        isCompleted: false,
        createdAt: DateTime(2026, 6, 29),
      );

      final sorted = sortHomeworkTasks([later, noDue, sooner]);

      expect(sorted.map((task) => task.id).toList(), ['sooner', 'later', 'no-due']);
    });

    test('homeworkDueAtEndOfLocalDay returns end of day', () {
      final end = homeworkDueAtEndOfLocalDay(DateTime(2026, 6, 26, 15, 30));

      expect(end.year, 2026);
      expect(end.month, 6);
      expect(end.day, 26);
      expect(end.hour, 23);
      expect(end.minute, 59);
      expect(end.second, 59);
    });
  });
}
