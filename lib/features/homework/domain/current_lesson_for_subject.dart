import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';

CalendarEntry? pickCurrentLesson({
  required List<CalendarEntry> entries,
  DateTime? now,
  Duration startBuffer = const Duration(minutes: 5),
}) {
  final clock = now ?? AppDateTime.nowLocal();

  final candidates = entries
      .where(
        (entry) =>
            entry.type == CalendarEntryType.lesson &&
            entry.subjectId != null &&
            entry.subjectId!.trim().isNotEmpty &&
            AppDateTime.isTodayLocal(entry.startTime, now: clock) &&
            clock.isAfter(
              entry.startTime.toLocal().subtract(startBuffer),
            ) &&
            !AppDateTime.isPastInstant(entry.endTime, now: clock),
      )
      .toList(growable: false)
    ..sort((a, b) => a.startTime.compareTo(b.startTime));

  return candidates.isEmpty ? null : candidates.first;
}
