import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/calendar_providers.dart';

class CustomTableCalendar extends ConsumerWidget {
  const CustomTableCalendar({
    super.key,
    required this.calendarFormat,
    required this.onFormatChanged,
  });

  final CalendarFormat calendarFormat;
  final ValueChanged<CalendarFormat> onFormatChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider);
    final focusedDay = ref.watch(focusedDayProvider);
    ref.listen<DateTime>(selectedDayProvider, (previous, next) {
      final currentFocusedDay = ref.read(focusedDayProvider);
      if (!isSameDay(currentFocusedDay, next)) {
        ref.read(focusedDayProvider.notifier).update(next);
      }
    });

    return TableCalendar(
      locale: 'de_DE', //TODO: make this dynamic
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
          color: Theme.of(context).colorScheme.tertiaryContainer,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        todayDecoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        todayTextStyle: const TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.w700,
        ),
        weekendTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        outsideTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
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
        ref.read(selectedDayProvider.notifier).update(newSelectedDay);
        ref.read(focusedDayProvider.notifier).update(newFocusedDay);
      },
      onPageChanged: (newFocusedDay) {
        ref.read(focusedDayProvider.notifier).update(newFocusedDay);
        
      },
    );
  }
}