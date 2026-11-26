import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/homework/domain/models/homework_task.dart';
import 'package:chronoapp/features/calendar/presentation/providers/filter/calendar/calendar_filtered_entries_providers.dart';
import 'package:chronoapp/features/homework/domain/next_lesson_for_subject.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final nextLessonForSubjectProvider =
    Provider.family<AsyncValue<CalendarEntry?>, String?>((ref, subjectId) {
      final normalizedSubjectId = subjectId?.trim();
      if (normalizedSubjectId == null || normalizedSubjectId.isEmpty) {
        return const AsyncData(null);
      }

      final entriesAsync = ref.watch(filteredCalendarAllEntriesProvider);
      return entriesAsync.when(
        loading: () => const AsyncLoading(),
        error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
        data: (entries) => AsyncData(
          pickNextLessonForSubject(
            entries: entries,
            subjectId: normalizedSubjectId,
          ),
        ),
      );
    });

final lessonForSubjectOnDayProvider =
    Provider.family<
      AsyncValue<CalendarEntry?>,
      ({String subjectId, DateTime day})
    >((ref, args) {
      return ref
          .watch(filteredCalendarAllEntriesProvider)
          .whenData(
            (entries) => pickLessonForSubjectOnDay(
              entries: entries,
              subjectId: args.subjectId,
              day: args.day,
            ),
          );
    });

({DateTime? dueAt, HomeworkDueSource? dueSource}) resolveHomeworkFormDue({
  required List<CalendarEntry>? entries,
  required String? subjectId,
  required bool nextLesson,
  required DateTime? day,
}) {
  if (nextLesson) {
    final lesson = entries == null || subjectId == null
        ? null
        : pickNextLessonForSubject(entries: entries, subjectId: subjectId);
    return (
      dueAt: lesson?.startTime.toLocal(),
      dueSource: lesson == null ? null : HomeworkDueSource.nextLesson,
    );
  }

  if (day == null) return (dueAt: null, dueSource: null);
  final lesson = entries == null || subjectId == null
      ? null
      : pickLessonForSubjectOnDay(
          entries: entries,
          subjectId: subjectId,
          day: day,
        );
  return (
    dueAt:
        lesson?.startTime.toLocal() ??
        DateTime(day.year, day.month, day.day, 23, 59),
    dueSource: HomeworkDueSource.customDate,
  );
}
