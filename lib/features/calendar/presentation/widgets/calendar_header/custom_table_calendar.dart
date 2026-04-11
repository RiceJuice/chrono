import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/calendar_providers.dart';
import '../../theme/calendar_presentation_theme.dart';

class CustomTableCalendar extends ConsumerWidget {
  const CustomTableCalendar({
    super.key,
    required this.calendarFormat,
    required this.onFormatChanged,
  });

  final CalendarFormat calendarFormat;
  final ValueChanged<CalendarFormat> onFormatChanged;

  DateTime _startOfWeek(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final offsetFromMonday = normalizedDay.weekday - DateTime.monday;
    return DateTime(
      normalizedDay.year,
      normalizedDay.month,
      normalizedDay.day - offsetFromMonday,
    );
  }

  DateTime _selectedDayForPage(DateTime focusedDay, DateTime currentSelectedDay) {
    final normalizedFocusedDay = DateTime(
      focusedDay.year,
      focusedDay.month,
      focusedDay.day,
    );

    switch (calendarFormat) {
      case CalendarFormat.month:
        return DateTime(normalizedFocusedDay.year, normalizedFocusedDay.month, 1);
      case CalendarFormat.week:
        final weekStart = _startOfWeek(normalizedFocusedDay);
        final weekdayOffset = currentSelectedDay.weekday - DateTime.monday;
        return DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + weekdayOffset,
        );
      case CalendarFormat.twoWeeks:
        return normalizedFocusedDay;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final selectedDay = ref.watch(selectedDayProvider);
    final focusedDay = ref.watch(focusedDayProvider);
    ref.listen<DateTime>(selectedDayProvider, (previous, next) {
      final currentFocusedDay = ref.read(focusedDayProvider);
      if (!isSameDay(currentFocusedDay, next)) {
        ref.read(focusedDayProvider.notifier).update(next);
      }
    });

    return TableCalendar(
      locale: 'de_DE', 
      startingDayOfWeek: StartingDayOfWeek.monday,
      firstDay: DateTime(2020, 1, 1), //TODO: make this dynamic
      lastDay: DateTime(2030, 12, 31), //TODO: make this dynamic
      calendarFormat: calendarFormat,
      focusedDay: focusedDay,
      rowHeight: 40,
      daysOfWeekHeight: 20,
      availableGestures: AvailableGestures.horizontalSwipe,
      headerVisible: false,
      calendarStyle: CalendarStyle(
        cellMargin: const EdgeInsets.all(2),
        selectedDecoration: BoxDecoration(
          color: scheme.primary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        todayDecoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
          color: CalendarPresentationTheme.todayAccentColor(context),
          fontWeight: FontWeight.w700,
        ),
        weekendTextStyle: TextStyle(
          color: scheme.onSurface,
        ),
        outsideTextStyle: TextStyle(
          color: scheme.onSurface.withValues(alpha: 0.3),
        ),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: false,
        leftChevronVisible: false,
        rightChevronVisible: false,
      ),
      selectedDayPredicate: (day) => isSameDay(selectedDay, day),
      onFormatChanged: onFormatChanged,
      onDaySelected: (newSelectedDay, newFocusedDay) {
        final currentSelectedDay = ref.read(selectedDayProvider);
        if (isSameDay(currentSelectedDay, newSelectedDay)) return;
        ref.read(selectedDayProvider.notifier).update(newSelectedDay);
        ref.read(focusedDayProvider.notifier).update(newFocusedDay);
      },
      onPageChanged: (newFocusedDay) {
        final currentSelectedDay = ref.read(selectedDayProvider);
        final nextSelectedDay = _selectedDayForPage(
          newFocusedDay,
          currentSelectedDay,
        );
        ref.read(selectedDayProvider.notifier).update(nextSelectedDay);
        ref.read(focusedDayProvider.notifier).update(nextSelectedDay);
      },
    );
  }
}