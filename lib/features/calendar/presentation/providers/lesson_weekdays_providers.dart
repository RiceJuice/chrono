import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/calendar_entry.dart';
import '../../event_editor/data/calendar_event_target_resolver.dart';
import '../../event_editor/presentation/providers/calendar_event_editor_providers.dart';

class LessonWeekdaysLookup {
  const LessonWeekdaysLookup({
    required this.subjectId,
    required this.seriesId,
    required this.fallbackWeekday,
  });

  final String? subjectId;
  final String? seriesId;
  final int fallbackWeekday;

  factory LessonWeekdaysLookup.fromEntry(CalendarEntry entry) {
    return LessonWeekdaysLookup(
      subjectId: entry.subjectId,
      seriesId: CalendarEventTargetResolver.resolveSeriesId(entry),
      fallbackWeekday: entry.startTime.toLocal().weekday,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LessonWeekdaysLookup &&
        other.subjectId == subjectId &&
        other.seriesId == seriesId &&
        other.fallbackWeekday == fallbackWeekday;
  }

  @override
  int get hashCode => Object.hash(subjectId, seriesId, fallbackWeekday);
}

final lessonWeekdaysForEntryProvider =
    StreamProvider.family<Set<int>, LessonWeekdaysLookup>((ref, lookup) {
      return ref.watch(calendarEventSeriesReaderProvider).watchLessonWeekdays(
            subjectId: lookup.subjectId,
            seriesId: lookup.seriesId,
            fallbackWeekday: lookup.fallbackWeekday,
          );
    });
