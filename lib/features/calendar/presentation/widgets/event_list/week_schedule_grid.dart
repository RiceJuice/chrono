import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_day_columns.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_layout.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_timeline.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WeekScheduleGrid extends ConsumerWidget {
  const WeekScheduleGrid({
    required this.monday,
    this.showTimelineColumn = true,
    this.hourHeight,
    super.key,
  });

  final DateTime monday;
  final bool showTimelineColumn;
  final double? hourHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedHourHeight =
        hourHeight ?? weekScheduleHourHeightFor(context);
    final weekDays = List<DateTime>.generate(
      7,
      (index) => monday.add(Duration(days: index)),
    );
    final asyncDays = weekDays
        .map((day) => ref.watch(filteredCalendarEntriesForDayProvider(day)))
        .toList(growable: false);

    for (final asyncDay in asyncDays) {
      if (asyncDay.hasError) {
        return Center(child: Text('Fehler: ${asyncDay.error}'));
      }
    }
    for (final asyncDay in asyncDays) {
      if (!asyncDay.hasValue) {
        return const Center(child: CircularProgressIndicator());
      }
    }

    final entriesByDay = asyncDays
        .map((asyncDay) => asyncDay.value ?? const <CalendarEntry>[])
        .toList(growable: false);
    final bounds = computeWeekScheduleBounds(entriesByDay);
    if (bounds == null) {
      return const Center(child: Text('Keine Einträge für diese Woche.'));
    }

    final totalHeight = bounds.heightForHourHeight(resolvedHourHeight);

    return SingleChildScrollView(
      child: SizedBox(
        height: totalHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTimelineColumn)
              WeekTimelineColumn(
                bounds: bounds,
                totalHeight: totalHeight,
                hourHeight: resolvedHourHeight,
              ),
            Expanded(
              child: WeekDayColumns(
                weekDays: weekDays,
                entriesByDay: entriesByDay,
                bounds: bounds,
                totalHeight: totalHeight,
                hourHeight: resolvedHourHeight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
