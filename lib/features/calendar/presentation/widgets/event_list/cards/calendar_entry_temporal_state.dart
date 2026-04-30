import 'package:chronoapp/core/time/app_date_time.dart';

import '../../../../domain/models/calendar_entry.dart';

class CalendarEntryTemporalState {
  const CalendarEntryTemporalState({
    required this.isPast,
    required this.isToday,
  });

  final bool isPast;
  final bool isToday;

  static CalendarEntryTemporalState fromEntry(
    CalendarEntry entry, {
    DateTime? now,
  }) {
    return CalendarEntryTemporalState(
      isPast: AppDateTime.isPastInstant(entry.endTime, now: now),
      isToday: AppDateTime.isTodayLocal(entry.startTime, now: now),
    );
  }
}
