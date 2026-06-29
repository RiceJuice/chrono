import 'package:chronoapp/features/homework/domain/models/homework_task.dart';
import 'package:chronoapp/features/homework/presentation/helpers/homework_due_display.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  HomeworkTask task({
    DateTime? dueAt,
    HomeworkDueSource? dueSource,
  }) {
    return HomeworkTask(
      id: 'task-1',
      title: 'Test',
      isCompleted: false,
      createdAt: DateTime(2026, 6, 26),
      dueAt: dueAt,
      dueSource: dueSource,
    );
  }

  group('homework task visibility', () {
    test('tasks without due date stay visible', () {
      expect(
        isHomeworkTaskVisibleInList(task: task()),
        isTrue,
      );
    });

    test('next-lesson tasks disappear when lesson starts', () {
      final dueAt = DateTime(2026, 6, 28, 8, 0);
      final homework = task(
        dueAt: dueAt,
        dueSource: HomeworkDueSource.nextLesson,
      );

      expect(
        isHomeworkTaskVisibleInList(
          task: homework,
          now: dueAt.subtract(const Duration(minutes: 1)),
        ),
        isTrue,
      );
      expect(
        isHomeworkTaskVisibleInList(task: homework, now: dueAt),
        isFalse,
      );
    });

    test('custom-date tasks stay visible through the due day', () {
      final dueAt = DateTime(2026, 6, 28);
      final homework = task(
        dueAt: dueAt,
        dueSource: HomeworkDueSource.customDate,
      );

      expect(
        isHomeworkTaskVisibleInList(
          task: homework,
          now: DateTime(2026, 6, 28, 23, 59, 59),
        ),
        isTrue,
      );
      expect(
        isHomeworkTaskVisibleInList(
          task: homework,
          now: DateTime(2026, 6, 29),
        ),
        isFalse,
      );
    });

    test('visibleHomeworkTasks filters only past-due tasks', () {
      final visible = task(
        dueAt: DateTime(2026, 6, 30, 8),
        dueSource: HomeworkDueSource.nextLesson,
      );
      final hidden = task(
        dueAt: DateTime(2026, 6, 28, 8),
        dueSource: HomeworkDueSource.nextLesson,
      );
      final withoutDue = task();

      final result = visibleHomeworkTasks(
        [visible, hidden, withoutDue],
        now: DateTime(2026, 6, 28, 9),
      );

      expect(result.map((entry) => entry.dueAt), [
        DateTime(2026, 6, 30, 8),
        null,
      ]);
    });
  });
}
