import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';

CalendarEntry? pickNextLessonForSubject({
  required List<CalendarEntry> entries,
  required String subjectId,
  DateTime? now,
}) {
  final clock = now ?? AppDateTime.nowLocal();
  final normalizedSubjectId = subjectId.trim();
  if (normalizedSubjectId.isEmpty) return null;

  final candidates = entries
      .where(
        (entry) =>
            entry.type == CalendarEntryType.lesson &&
            entry.subjectId == normalizedSubjectId &&
            !AppDateTime.isPastInstant(entry.startTime, now: clock),
      )
      .toList(growable: false)
    ..sort((a, b) => a.startTime.compareTo(b.startTime));

  return candidates.isEmpty ? null : candidates.first;
}
