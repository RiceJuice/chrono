import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';

List<CalendarEntry> upcomingLessonsForSubject({
  required List<CalendarEntry> entries,
  required String subjectId,
  DateTime? now,
  int? limit,
}) {
  final clock = now ?? AppDateTime.nowLocal();
  final normalizedSubjectId = subjectId.trim();
  if (normalizedSubjectId.isEmpty) return const [];

  final candidates = entries
      .where(
        (entry) =>
            entry.type == CalendarEntryType.lesson &&
            entry.subjectId == normalizedSubjectId &&
            !AppDateTime.isPastInstant(entry.startTime, now: clock),
      )
      .toList(growable: false)
    ..sort((a, b) => a.startTime.compareTo(b.startTime));

  if (limit == null || limit >= candidates.length) {
    return candidates;
  }
  return candidates.take(limit).toList(growable: false);
}

CalendarEntry? lessonForSubjectOnLocalDay({
  required List<CalendarEntry> entries,
  required String subjectId,
  required DateTime day,
}) {
  final normalizedSubjectId = subjectId.trim();
  if (normalizedSubjectId.isEmpty) return null;

  final localDay = AppDateTime.localDay(day);
  final matches = entries
      .where(
        (entry) =>
            entry.type == CalendarEntryType.lesson &&
            entry.subjectId == normalizedSubjectId &&
            AppDateTime.isSameLocalDay(entry.startTime, localDay),
      )
      .toList(growable: false)
    ..sort((a, b) => a.startTime.compareTo(b.startTime));

  return matches.isEmpty ? null : matches.first;
}

List<CalendarEntry> lessonsForSubjectOnLocalDay({
  required List<CalendarEntry> entries,
  required String subjectId,
  required DateTime day,
}) {
  final normalizedSubjectId = subjectId.trim();
  if (normalizedSubjectId.isEmpty) return const [];

  final localDay = AppDateTime.localDay(day);
  final matches = entries
      .where(
        (entry) =>
            entry.type == CalendarEntryType.lesson &&
            entry.subjectId == normalizedSubjectId &&
            AppDateTime.isSameLocalDay(entry.startTime, localDay),
      )
      .toList(growable: false)
    ..sort((a, b) => a.startTime.compareTo(b.startTime));

  return matches;
}

String formatSchoolAssessmentTimeLabel(CalendarEntry lesson) {
  return '${AppDateTime.formatLocalHourMinute(lesson.startTime)} – '
      '${AppDateTime.formatLocalHourMinute(lesson.endTime)} Uhr';
}
