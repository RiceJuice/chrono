import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';

/// Lokale Kalendertage (Mitternacht), an denen das Fach eine Stunde hat.
Set<DateTime> subjectLessonLocalDays({
  required List<CalendarEntry> entries,
  required String subjectId,
}) {
  final normalizedSubjectId = subjectId.trim();
  if (normalizedSubjectId.isEmpty) return {};

  final days = <DateTime>{};
  for (final entry in entries) {
    if (entry.type != CalendarEntryType.lesson) continue;
    if (entry.subjectId != normalizedSubjectId) continue;
    days.add(AppDateTime.localDay(entry.startTime));
  }
  return days;
}

bool isSubjectLessonLocalDay({
  required Set<DateTime> lessonDays,
  required DateTime day,
}) {
  return lessonDays.contains(AppDateTime.localDay(day));
}
