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

bool isHomeworkTaskOverdue({
  required HomeworkTask task,
  DateTime? now,
}) {
  if (task.isCompleted || task.dueAt == null) return false;
  final clock = now ?? DateTime.now();
  return task.dueAt!.isBefore(clock);
}
