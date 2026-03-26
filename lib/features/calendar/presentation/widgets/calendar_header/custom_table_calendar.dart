import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/calendar_providers.dart';

class CustomTableCalendar extends ConsumerWidget {
  const CustomTableCalendar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider);
    final focusedDay = ref.watch(focusedDayProvider);

    return TableCalendar(
      firstDay: DateTime(2020, 1, 1),
      lastDay: DateTime(2030, 12, 31),
      focusedDay: focusedDay,
      headerVisible: false,
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: false,
        leftChevronVisible: false,
        rightChevronVisible: false,
      ),
      selectedDayPredicate: (day) => isSameDay(selectedDay, day),
      onDaySelected: (newSelectedDay, newFocusedDay) {
        ref.read(selectedDayProvider.notifier).update(newSelectedDay);
        ref.read(focusedDayProvider.notifier).update(newFocusedDay);
      },
      onPageChanged: (newFocusedDay) {
        ref.read(focusedDayProvider.notifier).update(newFocusedDay);
        ref.read(selectedDayProvider.notifier).update(newFocusedDay);
      },
    );
  }
}