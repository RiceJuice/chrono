import 'package:chronoapp/features/homework/domain/models/homework_task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'groups by local day then subject regardless of time and completion',
    () {
      HomeworkTask task(
        String id,
        String subject,
        DateTime? due, {
        bool done = false,
      }) => HomeworkTask(
        id: id,
        title: id,
        subjectId: subject,
        dueAt: due,
        isCompleted: done,
        createdAt: DateTime(2026),
      );
      final tasks = [
        task('math', 'm', DateTime(2026, 10, 29, 8)),
        task('german', 'd', DateTime(2026, 10, 29, 11), done: true),
        task('earlier', 'm', DateTime(2026, 10, 28, 12)),
        task('undated', 'd', null),
      ];
      final sorted = sortHomeworkTasksByDueDay(
        tasks,
        subjectName: (id) => id == 'd' ? 'Deutsch' : 'Mathematik',
      );
      expect(sorted.map((task) => task.id), [
        'earlier',
        'german',
        'math',
        'undated',
      ]);
    },
  );
}
