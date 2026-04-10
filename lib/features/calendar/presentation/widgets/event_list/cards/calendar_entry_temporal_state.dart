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
    final current = now ?? DateTime.now();
    final localNowDay = DateTime(current.year, current.month, current.day);
    final localStart = entry.startTime.toLocal();
    final localEntryDay = DateTime(localStart.year, localStart.month, localStart.day);

    return CalendarEntryTemporalState(
      isPast: entry.endTime.isBefore(current),
      isToday: localEntryDay == localNowDay,
    );
  }
}
