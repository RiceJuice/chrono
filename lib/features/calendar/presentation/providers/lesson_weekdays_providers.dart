import 'package:chronoapp/core/database/backend_enums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/calendar_entry.dart';
import '../../event_editor/data/calendar_event_target_resolver.dart';
import '../../event_editor/presentation/providers/calendar_event_editor_providers.dart';

class LessonWeekdaysLookup {
  const LessonWeekdaysLookup({
    required this.subjectId,
    required this.seriesId,
    required this.schoolTrack,
    required this.fallbackWeekday,
  });

  final String? subjectId;
  final String? seriesId;
  final BackendSchoolTrack schoolTrack;
  final int fallbackWeekday;

  factory LessonWeekdaysLookup.fromEntry(CalendarEntry entry) {
    return LessonWeekdaysLookup(
      subjectId: entry.subjectId,
      seriesId: CalendarEventTargetResolver.resolveSeriesId(entry),
      schoolTrack: entry.schoolTrack,
      fallbackWeekday: entry.startTime.toLocal().weekday,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LessonWeekdaysLookup &&
        other.subjectId == subjectId &&
        other.seriesId == seriesId &&
        other.schoolTrack == schoolTrack &&
        other.fallbackWeekday == fallbackWeekday;
  }

  @override
  int get hashCode => Object.hash(subjectId, seriesId, schoolTrack, fallbackWeekday);
}

final lessonWeekdaysForEntryProvider =
    StreamProvider.family<Set<int>, LessonWeekdaysLookup>((ref, lookup) {
      return ref.watch(calendarEventSeriesReaderProvider).watchLessonWeekdays(
            subjectId: lookup.subjectId,
            seriesId: lookup.seriesId,
            schoolTrack: lookup.schoolTrack,
            fallbackWeekday: lookup.fallbackWeekday,
          );
    });
