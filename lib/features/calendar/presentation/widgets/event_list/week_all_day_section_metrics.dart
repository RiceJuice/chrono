import 'dart:math' as math;

import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_all_day_break_layout.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

int maxAllDayLaneCount(Iterable<int> laneCounts) {
  var maxLanes = 0;
  for (final count in laneCounts) {
    if (count > maxLanes) maxLanes = count;
  }
  return maxLanes;
}

int allDayLaneCountForEntriesByDay(List<List<CalendarEntry>> entriesByDay) {
  return layoutWeekAllDayBreaks(entriesByDay: entriesByDay).laneCount;
}

List<List<CalendarEntry>> entriesByDayForMonday(WidgetRef ref, DateTime monday) {
  final normalizedMonday = AppDateTime.localMondayOfWeek(monday);
  return List<List<CalendarEntry>>.generate(7, (index) {
    final day = AppDateTime.addLocalCalendarDays(normalizedMonday, index);
    return ref.watch(filteredCalendarEntriesForDayProvider(day)).value ??
        const <CalendarEntry>[];
  }, growable: false);
}

int allDayLaneCountForMonday(WidgetRef ref, DateTime monday) {
  return allDayLaneCountForEntriesByDay(entriesByDayForMonday(ref, monday));
}

/// Reservierte Ganztags-Höhe: Maximum über Fokus-, Übergangs- und sichtbare Wochen.
double resolveWeekAllDaySectionHeight(
  WidgetRef ref, {
  required DateTime focusMonday,
  DateTime? transitionFromMonday,
  DateTime? transitionToMonday,
  Iterable<DateTime>? extraMondays,
}) {
  final mondays = <DateTime>{
    AppDateTime.localMondayOfWeek(focusMonday),
    if (transitionFromMonday != null)
      AppDateTime.localMondayOfWeek(transitionFromMonday),
    if (transitionToMonday != null)
      AppDateTime.localMondayOfWeek(transitionToMonday),
    if (extraMondays != null)
      ...extraMondays.map(AppDateTime.localMondayOfWeek),
  };
  final laneCounts = mondays.map((m) => allDayLaneCountForMonday(ref, m));
  return weekAllDaySectionHeight(maxAllDayLaneCount(laneCounts));
}

/// Sichtbare Tages-Spalten im mobilen Ganztags-Streifen einbeziehen.
double resolveMobileAllDayStripSectionHeight(
  WidgetRef ref, {
  required DateTime focusMonday,
  required ScrollController horizontalController,
  required double dayWidth,
  required double viewportWidth,
}) {
  final mondays = <DateTime>{AppDateTime.localMondayOfWeek(focusMonday)};
  if (horizontalController.hasClients && dayWidth > 0) {
    final offset = horizontalController.offset;
    final firstIndex = (offset / dayWidth)
        .floor()
        .clamp(0, kWeekScheduleTotalDaySlots - 1);
    final visibleCount = math.min(
      kWeekScheduleTotalDaySlots - firstIndex,
      (viewportWidth / dayWidth).ceil() + 2,
    );
    for (var i = 0; i < visibleCount; i++) {
      final day = weekScheduleDayFromGlobalIndex(firstIndex + i);
      mondays.add(AppDateTime.localMondayOfWeek(day));
    }
  }
  final laneCounts = mondays.map((m) => allDayLaneCountForMonday(ref, m));
  return weekAllDaySectionHeight(maxAllDayLaneCount(laneCounts));
}
