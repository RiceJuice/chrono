import 'package:chronoapp/features/homework/domain/homework_tasks_for_lesson.dart';
import 'package:chronoapp/features/homework/domain/models/homework_task.dart';
import 'package:chronoapp/features/homework/presentation/helpers/homework_due_display.dart';
import 'package:chronoapp/features/homework/presentation/providers/homework_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final openHomeworkTasksByLessonKeyProvider =
    Provider<Map<String, List<HomeworkTask>>>((ref) {
  ref.watch(homeworkListClockProvider);
  final tasks = ref.watch(homeworkTasksProvider).asData?.value;
  if (tasks == null || tasks.isEmpty) return const {};

  final index = <String, List<HomeworkTask>>{};
  for (final task in tasks) {
    if (task.isCompleted ||
        task.dueAt == null ||
        !isHomeworkTaskVisibleInList(task: task)) {
      continue;
    }
    final subjectId = task.subjectId?.trim();
    if (subjectId == null || subjectId.isEmpty) continue;

    final key = lessonHomeworkLookupKey(
      subjectId: subjectId,
      lessonStart: task.dueAt!,
    );
    index.putIfAbsent(key, () => <HomeworkTask>[]).add(task);
  }
  return index;
});

final openHomeworkTasksForLessonKeyProvider =
    Provider.family<List<HomeworkTask>, String>((ref, key) {
  final index = ref.watch(openHomeworkTasksByLessonKeyProvider);
  return index[key] ?? const [];
});
