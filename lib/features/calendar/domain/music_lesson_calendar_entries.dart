import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/time/app_date_time.dart';
import '../../music_lessons/domain/music_lesson_schedule.dart';
import 'models/calendar_entry.dart';

final _berlin = _loadBerlin();

tz.Location _loadBerlin() {
  tz_data.initializeTimeZones();
  return tz.getLocation('Europe/Berlin');
}

/// Weekly school lessons are scheduled in Berlin wall time, including after
/// a daylight saving change. The shared calendar merge removes school breaks.
Iterable<CalendarEntry> musicLessonCalendarEntries(
  MusicLessonSchedule schedule, {
  required DateTime startUtc,
  required DateTime endExclusiveUtc,
  required Set<DateTime> freeDays,
}) sync* {
  final windowStart = tz.TZDateTime.from(startUtc, _berlin);
  final windowEnd = tz.TZDateTime.from(endExclusiveUtc, _berlin);
  final firstDate = DateTime.utc(
    windowStart.year,
    windowStart.month,
    windowStart.day,
  );
  final lastDate = DateTime.utc(windowEnd.year, windowEnd.month, windowEnd.day);
  final from = schedule.startsOn.isAfter(firstDate)
      ? schedule.startsOn
      : firstDate;

  for (final lesson in schedule.lessons) {
    var date = from.add(Duration(days: (lesson.weekday - from.weekday) % 7));
    while (!date.isAfter(lastDate)) {
      final start = tz.TZDateTime(
        _berlin,
        date.year,
        date.month,
        date.day,
        lesson.startMinute ~/ 60,
        lesson.startMinute % 60,
      ).toUtc();
      if (!start.isBefore(startUtc) &&
          start.isBefore(endExclusiveUtc) &&
          !freeDays.contains(AppDateTime.localDay(start))) {
        final seriesId = 'music-lesson:${lesson.kind.name}';
        yield CalendarEntry(
          id: '$seriesId:${start.toIso8601String()}',
          seriesId: seriesId,
          recurrenceId: start,
          isRecurringInstance: true,
          eventName: lesson.title,
          description: lesson.teacher == null
              ? null
              : 'Lehrkraft: ${lesson.teacher}',
          startTime: start,
          endTime: start.add(Duration(minutes: lesson.durationMinutes)),
          accentColor: const Color(0xFF7957B2),
          type: CalendarEntryType.lesson,
        );
      }
      date = date.add(const Duration(days: 7));
    }
  }
}
