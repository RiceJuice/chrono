import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/homework/domain/models/homework_task.dart';

String lessonHomeworkLookupKey({
  required String subjectId,
  required DateTime lessonStart,
}) {
  final normalizedSubjectId = subjectId.trim();
  return '$normalizedSubjectId|${lessonStart.toUtc().millisecondsSinceEpoch}';
}

String? lessonHomeworkLookupKeyForEntry(CalendarEntry entry) {
  if (entry.type != CalendarEntryType.lesson) return null;
  final subjectId = entry.subjectId?.trim();
  if (subjectId == null || subjectId.isEmpty) return null;
  return lessonHomeworkLookupKey(
    subjectId: subjectId,
    lessonStart: entry.startTime,
  );
}

bool isOpenHomeworkTaskForLesson({
  required HomeworkTask task,
  required CalendarEntry lesson,
}) {
  if (task.isCompleted || task.dueAt == null) return false;
  if (lesson.type != CalendarEntryType.lesson) return false;

  final lessonSubjectId = lesson.subjectId?.trim();
  final taskSubjectId = task.subjectId?.trim();
  if (lessonSubjectId == null ||
      lessonSubjectId.isEmpty ||
      taskSubjectId == null ||
      taskSubjectId.isEmpty ||
      lessonSubjectId != taskSubjectId) {
    return false;
  }

  return task.dueAt!.toUtc().millisecondsSinceEpoch ==
      lesson.startTime.toUtc().millisecondsSinceEpoch;
}

List<HomeworkTask> openHomeworkTasksForLesson({
  required Iterable<HomeworkTask> tasks,
  required CalendarEntry lesson,
}) {
  return tasks
      .where((task) => isOpenHomeworkTaskForLesson(task: task, lesson: lesson))
      .toList(growable: false);
}
