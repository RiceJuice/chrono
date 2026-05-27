import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:table_calendar/table_calendar.dart';

CalendarEntryLocalRange calendarHeaderEntryRange({
  required DateTime focusedDay,
  required CalendarFormat calendarFormat,
}) {
  final focused = AppDateTime.localDay(focusedDay);
  final (visibleStart, visibleEnd) = switch (calendarFormat) {
    CalendarFormat.month => _monthGridRange(focused),
    CalendarFormat.week => _weekRange(focused),
    CalendarFormat.twoWeeks => _twoWeekRange(focused),
  };

  return (
    startInclusive: AppDateTime.addLocalCalendarDays(visibleStart, -7),
    endExclusive: AppDateTime.addLocalCalendarDays(visibleEnd, 7),
  );
}

CalendarEntryLocalRange calendarWeekHeaderEntryRange(DateTime day) {
  final (visibleStart, visibleEnd) = _weekRange(day);
  return (
    startInclusive: AppDateTime.addLocalCalendarDays(visibleStart, -7),
    endExclusive: AppDateTime.addLocalCalendarDays(visibleEnd, 7),
  );
}

(DateTime startInclusive, DateTime endExclusive) _monthGridRange(
  DateTime focusedDay,
) {
  final monthStart = DateTime(focusedDay.year, focusedDay.month);
  final nextMonthStart = DateTime(focusedDay.year, focusedDay.month + 1);
  final visibleStart = AppDateTime.localMondayOfWeek(monthStart);
  final visibleEnd = AppDateTime.addLocalCalendarDays(
    AppDateTime.localMondayOfWeek(
      AppDateTime.addLocalCalendarDays(nextMonthStart, -1),
    ),
    7,
  );
  return (visibleStart, visibleEnd);
}

(DateTime startInclusive, DateTime endExclusive) _weekRange(DateTime day) {
  final start = AppDateTime.localMondayOfWeek(day);
  return (start, AppDateTime.addLocalCalendarDays(start, 7));
}

(DateTime startInclusive, DateTime endExclusive) _twoWeekRange(DateTime day) {
  final start = AppDateTime.localMondayOfWeek(day);
  return (start, AppDateTime.addLocalCalendarDays(start, 14));
}
