import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as fr;

enum CalendarViewMode { day, week }

class CalendarViewOption {
  const CalendarViewOption({
    required this.mode,
    required this.label,
    required this.icon,
  });

  final CalendarViewMode mode;
  final String label;
  final IconData icon;
}

const calendarViewOptions = <CalendarViewOption>[
  CalendarViewOption(
    mode: CalendarViewMode.day,
    label: 'Tag',
    icon: Icons.view_day_outlined,
  ),
  CalendarViewOption(
    mode: CalendarViewMode.week,
    label: 'Woche',
    icon: Icons.view_week_outlined,
  ),
];

class CalendarViewModeController extends fr.Notifier<CalendarViewMode> {
  @override
  CalendarViewMode build() => calendarViewOptions.first.mode;

  void update(CalendarViewMode mode) {
    if (state == mode) return;
    state = mode;
  }
}

final calendarViewModeProvider =
    fr.NotifierProvider<CalendarViewModeController, CalendarViewMode>(
      CalendarViewModeController.new,
    );

CalendarViewOption calendarViewOptionFor(CalendarViewMode mode) {
  return calendarViewOptions.firstWhere(
    (option) => option.mode == mode,
    orElse: () => calendarViewOptions.first,
  );
}
