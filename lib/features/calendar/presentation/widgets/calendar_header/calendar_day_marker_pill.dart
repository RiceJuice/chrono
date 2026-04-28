import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../domain/models/calendar_entry.dart';

const _timelineStartHour = 10;
const _minimumTimelineDurationMinutes = 10 * 60;
const _minimumSegmentWidth = 10.0;
const _pillContentInset = 1.5;

DateTime normalizeCalendarDay(DateTime day) => DateTime(day.year, day.month, day.day);

Map<DateTime, CalendarDayMarkerData> buildCalendarDayMarkers(
  List<CalendarEntry> entries,
) {
  final rawSegmentsByDay = <DateTime, List<_RawTimelineSegment>>{};
  final idsByDay = <DateTime, Set<String>>{};

  for (final entry in entries) {
    if (entry.type == CalendarEntryType.lesson || entry.type == CalendarEntryType.meal) {
      continue;
    }
    final start = entry.startTime.toLocal();
    final end = entry.endTime.toLocal();
    if (!end.isAfter(start)) continue;

    var dayStart = normalizeCalendarDay(start);
    final endDay = normalizeCalendarDay(end);
    while (!dayStart.isAfter(endDay)) {
      final nextDayStart = dayStart.add(const Duration(days: 1));
      final effectiveStart = start.isAfter(dayStart) ? start : dayStart;
      final effectiveEnd = end.isBefore(nextDayStart) ? end : nextDayStart;
      final startMinute = effectiveStart.difference(dayStart).inMinutes;
      final endMinute = effectiveEnd.difference(dayStart).inMinutes;
      final clippedStartMinute = startMinute.clamp(0, Duration.minutesPerDay).toInt();
      final clippedEndMinute = endMinute.clamp(0, Duration.minutesPerDay).toInt();

      if (clippedEndMinute > clippedStartMinute) {
        rawSegmentsByDay.putIfAbsent(dayStart, () => <_RawTimelineSegment>[]).add(
          _RawTimelineSegment(
            type: entry.type,
            startMinute: clippedStartMinute,
            endMinute: clippedEndMinute,
          ),
        );
        idsByDay.putIfAbsent(dayStart, () => <String>{}).add(entry.id);
      }
      dayStart = nextDayStart;
    }
  }

  final result = <DateTime, CalendarDayMarkerData>{};
  for (final day in rawSegmentsByDay.keys) {
    final rawSegments = rawSegmentsByDay[day];
    if (rawSegments == null || rawSegments.isEmpty) continue;
    final visibleRawSegments = _keepLongestNonOverlappingSegments(rawSegments);
    if (visibleRawSegments.isEmpty) continue;

    final defaultStartMinute = _timelineStartHour * Duration.minutesPerHour;
    final timelineStartMinute = visibleRawSegments
        .fold<int>(
          defaultStartMinute,
          (earliest, segment) => math.min(earliest, segment.startMinute),
        )
        .clamp(0, Duration.minutesPerDay)
        .toInt();
    final latestEndMinute = visibleRawSegments
        .fold<int>(
          timelineStartMinute + _minimumTimelineDurationMinutes,
          (latest, segment) => math.max(latest, segment.endMinute),
        )
        .clamp(0, Duration.minutesPerDay)
        .toInt();
    final timelineEndMinute = latestEndMinute;
    final timelineDurationMinutes = timelineEndMinute - timelineStartMinute;
    if (timelineDurationMinutes <= 0) continue;

    final segments = visibleRawSegments
        .map(
          (segment) => TimelineSegment(
            type: segment.type,
            startMinute: segment.startMinute - timelineStartMinute,
            endMinute: segment.endMinute - timelineStartMinute,
          ),
        )
        .where((segment) => segment.durationMinutes > 0)
        .toList(growable: false);
    if (segments.isEmpty) continue;

    segments.sort((a, b) {
      final startComparison = a.startMinute.compareTo(b.startMinute);
      if (startComparison != 0) return startComparison;
      return b.durationMinutes.compareTo(a.durationMinutes);
    });
    final totalMinutes = segments.fold<int>(
      0,
      (sum, segment) => sum + segment.durationMinutes,
    );
    if (totalMinutes <= 0) continue;

    result[day] = CalendarDayMarkerData(
      totalMinutes: totalMinutes,
      eventCount: idsByDay[day]?.length ?? 0,
      timelineDurationMinutes: timelineDurationMinutes,
      segments: segments,
    );
  }

  return result;
}

List<_RawTimelineSegment> _keepLongestNonOverlappingSegments(
  List<_RawTimelineSegment> segments,
) {
  final kept = <_RawTimelineSegment>[];
  final candidates = segments.toList(growable: false)
    ..sort((a, b) {
      final durationComparison = b.durationMinutes.compareTo(a.durationMinutes);
      if (durationComparison != 0) return durationComparison;
      return a.startMinute.compareTo(b.startMinute);
    });

  for (final candidate in candidates) {
    final overlapsSameType = kept.any(
      (segment) =>
          segment.type == candidate.type && segment.overlaps(candidate),
    );
    if (!overlapsSameType) kept.add(candidate);
  }

  kept.sort((a, b) {
    final startComparison = a.startMinute.compareTo(b.startMinute);
    if (startComparison != 0) return startComparison;
    return b.durationMinutes.compareTo(a.durationMinutes);
  });
  return kept;
}

class CalendarDayMarkerData {
  const CalendarDayMarkerData({
    required this.totalMinutes,
    required this.eventCount,
    required this.timelineDurationMinutes,
    required this.segments,
  });

  final int totalMinutes;
  final int eventCount;
  final int timelineDurationMinutes;
  final List<TimelineSegment> segments;
}

class _RawTimelineSegment {
  const _RawTimelineSegment({
    required this.type,
    required this.startMinute,
    required this.endMinute,
  });

  final CalendarEntryType type;
  final int startMinute;
  final int endMinute;

  int get durationMinutes => endMinute - startMinute;

  bool overlaps(_RawTimelineSegment other) {
    return startMinute < other.endMinute && other.startMinute < endMinute;
  }
}

class TimelineSegment {
  const TimelineSegment({
    required this.type,
    required this.startMinute,
    required this.endMinute,
  });

  final CalendarEntryType type;
  final int startMinute;
  final int endMinute;

  int get durationMinutes => endMinute - startMinute;
}

class CalendarDayMarkerPill extends StatelessWidget {
  const CalendarDayMarkerPill({
    super.key,
    this.marker,
    this.width = 28,
    this.height = 7,
  });

  final CalendarDayMarkerData? marker;
  final double width;
  final double height;

  Color _cardBackgroundForType(BuildContext context, CalendarEntryType type) {
    return switch (type) {
      CalendarEntryType.lesson => const Color(0xFF29509E),
      CalendarEntryType.meal => const Color(0xFF29509E),
      CalendarEntryType.event => const Color(0xFF29509E),
      CalendarEntryType.choir => const Color(0xFFCBBBA0),
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final marker = this.marker;

    final pillBackground = Color.alphaBlend(
      Colors.white.withValues(alpha: 0.08),
      scheme.surfaceContainerHighest,
    );

    return Container(
      width: width + (_pillContentInset * 2),
      height: height + (_pillContentInset * 2),
      decoration: BoxDecoration(
        color: pillBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_pillContentInset),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            if (marker == null || marker.segments.isEmpty) {
              return const SizedBox.expand();
            }

            return ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                children: marker.segments.map((segment) {
                  final left = maxWidth *
                      (segment.startMinute / marker.timelineDurationMinutes);
                  final segmentWidth = maxWidth *
                      (segment.durationMinutes / marker.timelineDurationMinutes);
                  final availableWidth = math.max(0.0, maxWidth - left);
                  if (availableWidth <= 0) return const SizedBox.shrink();
                  final width = math.min(
                    math.max(segmentWidth, _minimumSegmentWidth),
                    availableWidth,
                  );

                  return Positioned(
                    left: left,
                    top: 0,
                    bottom: 0,
                    width: width,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _cardBackgroundForType(
                          context,
                          segment.type,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  );
                }).toList(growable: false),
              ),
            );
          },
        ),
      ),
    );
  }
}
