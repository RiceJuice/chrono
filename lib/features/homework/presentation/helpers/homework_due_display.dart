import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/event_editor/presentation/widgets/pickers/event_date_time_pickers.dart';
import 'package:chronoapp/features/homework/domain/models/homework_task.dart';

String formatHomeworkDueLabel({
  required DateTime dueAt,
  required HomeworkDueSource? dueSource,
}) {
  final localDueAt = dueAt.toLocal();

  return switch (dueSource) {
    HomeworkDueSource.nextLesson =>
      '${AppDateTime.formatLocalFullWeekdayDate(localDueAt)}, '
          '${AppDateTime.formatLocalHourMinute(localDueAt)}',
    HomeworkDueSource.customDate => EventDateTimePickers.formatDate(localDueAt),
    null => EventDateTimePickers.formatDate(localDueAt),
  };
}

DateTime homeworkTaskDueDeadline(HomeworkTask task) {
  final dueAt = task.dueAt!.toLocal();

  return switch (task.dueSource) {
    HomeworkDueSource.nextLesson => dueAt,
    HomeworkDueSource.customDate => AppDateTime.addLocalCalendarDays(
        AppDateTime.localDay(dueAt),
        1,
      ),
    null => AppDateTime.addLocalCalendarDays(
        AppDateTime.localDay(dueAt),
        1,
      ),
  };
}

bool isHomeworkTaskPastDue({
  required HomeworkTask task,
  DateTime? now,
}) {
  if (task.dueAt == null) return false;
  final clock = AppDateTime.toLocal(now ?? DateTime.now());
  return !clock.isBefore(homeworkTaskDueDeadline(task));
}

bool isHomeworkTaskVisibleInList({
  required HomeworkTask task,
  DateTime? now,
}) {
  return !isHomeworkTaskPastDue(task: task, now: now);
}

List<HomeworkTask> visibleHomeworkTasks(
  Iterable<HomeworkTask> tasks, {
  DateTime? now,
}) {
  return tasks
      .where((task) => isHomeworkTaskVisibleInList(task: task, now: now))
      .toList(growable: false);
}

bool isHomeworkTaskOverdue({
  required HomeworkTask task,
  DateTime? now,
}) {
  if (task.isCompleted || task.dueAt == null) return false;
  final clock = AppDateTime.toLocal(now ?? DateTime.now());
  return task.dueAt!.isBefore(clock);
}
