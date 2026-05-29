import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:flutter/material.dart';

import '../../../domain/models/calendar_entry.dart';
import 'calendar_day_marker_pill.dart';
import '../calendar_week_layout_tokens.dart';

enum CalendarBreakRangeSegment { single, start, middle, end }

Set<DateTime> buildHolidayDays(List<CalendarEntry> entries) {
  final days = <DateTime>{};
  for (final entry in entries) {
    if (entry.type != CalendarEntryType.breakType ||
        entry.isRecurringInstance) {
      continue;
    }
    final startDay = normalizeCalendarDay(entry.startTime);
    final endDay = normalizeCalendarDay(entry.endTime);
    if (startDay == endDay ||
        (endDay.isAfter(startDay) &&
            AppDateTime.localCalendarDaysBetween(startDay, endDay) == 1 &&
            entry.endTime.toLocal().hour == 0 &&
            entry.endTime.toLocal().minute == 0)) {
      days.add(startDay);
    }
  }
  return days;
}

Map<DateTime, CalendarBreakRangeSegment> buildBreakRangeSegmentsByDay(
  List<CalendarEntry> entries,
) {
  final breakDays = <DateTime>{};
  for (final entry in entries) {
    if (entry.type != CalendarEntryType.breakType ||
        !entry.isRecurringInstance) {
      continue;
    }
    breakDays.add(normalizeCalendarDay(entry.startTime));
  }
  return buildBreakRangeSegmentsFromDays(breakDays);
}

Map<DateTime, CalendarBreakRangeSegment> buildBreakRangeSegmentsFromDays(
  Set<DateTime> days,
) {
  final breakDays = days.map(normalizeCalendarDay).toSet();
  if (breakDays.isEmpty) return const <DateTime, CalendarBreakRangeSegment>{};

  final segments = <DateTime, CalendarBreakRangeSegment>{};
  for (final day in breakDays) {
    final previous = AppDateTime.addLocalCalendarDays(day, -1);
    final next = AppDateTime.addLocalCalendarDays(day, 1);
    final hasPrevious = breakDays.contains(previous);
    final hasNext = breakDays.contains(next);
    segments[day] = switch ((hasPrevious, hasNext)) {
      (false, false) => CalendarBreakRangeSegment.single,
      (false, true) => CalendarBreakRangeSegment.start,
      (true, true) => CalendarBreakRangeSegment.middle,
      (true, false) => CalendarBreakRangeSegment.end,
    };
  }
  return segments;
}

/// Volle Tageszelle mit optionalem Ferien-Balken als Hintergrund-Layer.
class CalendarDayVacationShell extends StatelessWidget {
  const CalendarDayVacationShell({
    required this.breakRangeSegment,
    required this.breakRangeColor,
    required this.child,
    super.key,
  });

  final CalendarBreakRangeSegment? breakRangeSegment;
  final Color breakRangeColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        if (breakRangeSegment != null)
          CalendarBreakRangeBar(
            segment: breakRangeSegment!,
            color: breakRangeColor,
          ),
        child,
      ],
    );
  }
}

class CalendarBreakRangeBar extends StatelessWidget {
  const CalendarBreakRangeBar({
    required this.segment,
    required this.color,
    super.key,
  });

  final CalendarBreakRangeSegment segment;
  final Color color;

  static const _selectedIndicatorRadius = Radius.circular(11);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = constraints.maxWidth;
          final centeredInset = ((cellWidth - kCalendarSelectedDayBoxSize) / 2)
              .clamp(0.0, double.infinity);

          final (leftInset, rightInset) = switch (segment) {
            // Einzel-Tag exakt auf der Breite des Selected-Day-Markings.
            CalendarBreakRangeSegment.single => (centeredInset, centeredInset),
            // Start/Ende: runde Außenkante am Selected-Day-Marker ausrichten,
            // innen weiterziehen, damit mehrtägige Bereiche verbunden bleiben.
            CalendarBreakRangeSegment.start => (
              centeredInset,
              -kCalendarDayCellMargin,
            ),
            CalendarBreakRangeSegment.middle => (
              -kCalendarDayCellMargin,
              -kCalendarDayCellMargin,
            ),
            CalendarBreakRangeSegment.end => (
              -kCalendarDayCellMargin,
              centeredInset,
            ),
          };

          final radius = BorderRadius.horizontal(
            left: switch (segment) {
              CalendarBreakRangeSegment.single ||
              CalendarBreakRangeSegment.start => _selectedIndicatorRadius,
              CalendarBreakRangeSegment.middle ||
              CalendarBreakRangeSegment.end => Radius.zero,
            },
            right: switch (segment) {
              CalendarBreakRangeSegment.single ||
              CalendarBreakRangeSegment.end => _selectedIndicatorRadius,
              CalendarBreakRangeSegment.start ||
              CalendarBreakRangeSegment.middle => Radius.zero,
            },
          );

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: leftInset,
                right: rightInset,
                top: 0,
                bottom: 0,
                child: Align(
                  alignment: Alignment.center,
                  child: Transform.translate(
                    offset: const Offset(0, kCalendarSelectedDayVisualOffsetY),
                    child: SizedBox(
                      width: double.infinity,
                      height: kCalendarSelectedDayBoxSize,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: radius,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
