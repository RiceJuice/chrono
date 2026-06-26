import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
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
