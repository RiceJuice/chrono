import 'dart:math' as math;

import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';

const double kWeekScheduleHourHeight = 72;
const double kWeekScheduleAdjacentEntryGap = 2;

class WeekScheduleBounds {
  const WeekScheduleBounds({
    required this.startMinute,
    required this.endMinute,
  });

  final double startMinute;
  final double endMinute;

  double get durationMinutes => endMinute - startMinute;

  double heightForHourHeight(double hourHeight) {
    return durationMinutes / 60.0 * hourHeight;
  }
}

class WeekEntryPlacement {
  const WeekEntryPlacement({
    required this.entry,
    required this.top,
    required this.height,
    required this.lane,
    required this.laneCount,
    required this.insetTop,
    required this.insetBottom,
  });

  final CalendarEntry entry;
  final double top;
  final double height;
  final int lane;
  final int laneCount;
  final double insetTop;
  final double insetBottom;

  WeekEntryPlacement copyWith({required int laneCount}) {
    return WeekEntryPlacement(
      entry: entry,
      top: top,
      height: height,
      lane: lane,
      laneCount: laneCount,
      insetTop: insetTop,
      insetBottom: insetBottom,
    );
  }
}

WeekScheduleBounds? computeWeekScheduleBounds(
  List<List<CalendarEntry>> entriesByDay,
) {
  double? startMin;
  double? endMin;

  for (final dayEntries in entriesByDay) {
    for (final entry in dayEntries) {
      final startLocal = AppDateTime.toLocal(entry.startTime);
      final endLocal = AppDateTime.toLocal(entry.endTime);
      final entryStart = _minuteOfDay(startLocal);
      final entryEnd = AppDateTime.isSameLocalDay(startLocal, endLocal)
          ? _minuteOfDay(endLocal)
          : 24 * 60.0;

      startMin = startMin == null ? entryStart : math.min(startMin, entryStart);
      endMin = endMin == null ? entryEnd : math.max(endMin, entryEnd);
    }
  }

  if (startMin == null || endMin == null || endMin <= startMin) {
    return null;
  }

  return WeekScheduleBounds(startMinute: startMin, endMinute: endMin);
}

List<WeekEntryPlacement> buildWeekEntryPlacements({
  required List<CalendarEntry> entries,
  required DateTime day,
  required WeekScheduleBounds bounds,
  required double hourHeight,
}) {
  final intervals = _buildIntervals(entries: entries, day: day);
  final placements = <WeekEntryPlacement>[];
  var index = 0;

  while (index < intervals.length) {
    final group = <_EntryInterval>[intervals[index]];
    var groupEnd = intervals[index].end;
    index++;

    while (index < intervals.length && intervals[index].start < groupEnd) {
      group.add(intervals[index]);
      groupEnd = math.max(groupEnd, intervals[index].end);
      index++;
    }

    final laneEnds = <double>[];
    final groupPlacements = <WeekEntryPlacement>[];
    for (var i = 0; i < group.length; i++) {
      final interval = group[i];
      var lane = laneEnds.indexWhere((end) => end <= interval.start);
      if (lane == -1) {
        lane = laneEnds.length;
        laneEnds.add(interval.end);
      } else {
        laneEnds[lane] = interval.end;
      }

      final top = _minutesToPixels(
        interval.start - bounds.startMinute,
        hourHeight,
      );
      final height = _minutesToPixels(
        interval.end - interval.start,
        hourHeight,
      );
      groupPlacements.add(
        WeekEntryPlacement(
          entry: interval.entry,
          top: top,
          height: math.max(1, height),
          lane: lane,
          laneCount: 1,
          insetTop: _touchesPrevious(intervals, interval)
              ? kWeekScheduleAdjacentEntryGap / 2
              : 0,
          insetBottom: _touchesNext(intervals, interval)
              ? kWeekScheduleAdjacentEntryGap / 2
              : 0,
        ),
      );
    }

    final laneCount = math.max(1, laneEnds.length);
    placements.addAll(
      groupPlacements.map(
        (placement) => placement.copyWith(laneCount: laneCount),
      ),
    );
  }

  return placements;
}

List<_EntryInterval> _buildIntervals({
  required List<CalendarEntry> entries,
  required DateTime day,
}) {
  final intervals = <_EntryInterval>[];

  for (final entry in entries) {
    final startLocal = AppDateTime.toLocal(entry.startTime);
    final endLocal = AppDateTime.toLocal(entry.endTime);
    if (!AppDateTime.isSameLocalDay(startLocal, day)) continue;

    final start = _minuteOfDay(startLocal);
    final end = AppDateTime.isSameLocalDay(startLocal, endLocal)
        ? _minuteOfDay(endLocal)
        : 24 * 60.0;
    intervals.add(
      _EntryInterval(entry: entry, start: start, end: math.max(start + 1, end)),
    );
  }

  intervals.sort((a, b) {
    final byStart = a.start.compareTo(b.start);
    if (byStart != 0) return byStart;
    return b.end.compareTo(a.end);
  });
  return intervals;
}

bool _touchesPrevious(List<_EntryInterval> intervals, _EntryInterval current) {
  return intervals
      .where((interval) => !identical(interval, current))
      .any((previous) => _sameMinute(previous.end, current.start));
}

bool _touchesNext(List<_EntryInterval> intervals, _EntryInterval current) {
  return intervals
      .where((interval) => !identical(interval, current))
      .any((next) => _sameMinute(current.end, next.start));
}

bool _sameMinute(double a, double b) => (a - b).abs() < 0.001;

double _minuteOfDay(DateTime value) {
  return value.hour * 60.0 +
      value.minute +
      value.second / 60.0 +
      value.millisecond / 60000.0;
}

double _minutesToPixels(double minutes, double hourHeight) {
  return minutes / 60.0 * hourHeight;
}

class _EntryInterval {
  const _EntryInterval({
    required this.entry,
    required this.start,
    required this.end,
  });

  final CalendarEntry entry;
  final double start;
  final double end;
}
