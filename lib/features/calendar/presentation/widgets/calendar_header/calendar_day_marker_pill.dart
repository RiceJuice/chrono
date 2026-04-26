import 'package:flutter/material.dart';
import '../../../domain/models/calendar_entry.dart';

DateTime normalizeCalendarDay(DateTime day) => DateTime(day.year, day.month, day.day);

Map<DateTime, CalendarDayMarkerData> buildCalendarDayMarkers(
  List<CalendarEntry> entries,
) {
  final minutesByDay = <DateTime, Map<CalendarEntryType, int>>{};
  final idsByDay = <DateTime, Set<String>>{};

  for (final entry in entries) {
    if (entry.type == CalendarEntryType.lesson) continue;
    final start = entry.startTime.toLocal();
    final end = entry.endTime.toLocal();
    if (!end.isAfter(start)) continue;

    var dayStart = normalizeCalendarDay(start);
    final endDay = normalizeCalendarDay(end);
    while (!dayStart.isAfter(endDay)) {
      final nextDayStart = dayStart.add(const Duration(days: 1));
      final effectiveStart = start.isAfter(dayStart) ? start : dayStart;
      final effectiveEnd = end.isBefore(nextDayStart) ? end : nextDayStart;
      final minutes = effectiveEnd.difference(effectiveStart).inMinutes;
      if (minutes > 0) {
        final typeMap = minutesByDay.putIfAbsent(
          dayStart,
          () => <CalendarEntryType, int>{},
        );
        typeMap.update(entry.type, (value) => value + minutes, ifAbsent: () => minutes);
        idsByDay.putIfAbsent(dayStart, () => <String>{}).add(entry.id);
      }
      dayStart = nextDayStart;
    }
  }

  final result = <DateTime, CalendarDayMarkerData>{};
  for (final day in minutesByDay.keys) {
    final typeMap = minutesByDay[day];
    if (typeMap == null || typeMap.isEmpty) continue;
    final totalMinutes = typeMap.values.fold<int>(0, (sum, value) => sum + value);
    if (totalMinutes <= 0) continue;

    final segments = typeMap.entries
        .map((entry) => TypeMinutesSegment(type: entry.key, minutes: entry.value))
        .toList(growable: false)
      ..sort((a, b) => b.minutes.compareTo(a.minutes));

    result[day] = CalendarDayMarkerData(
      totalMinutes: totalMinutes,
      eventCount: idsByDay[day]?.length ?? 0,
      segments: segments,
    );
  }

  return result;
}

class CalendarDayMarkerData {
  const CalendarDayMarkerData({
    required this.totalMinutes,
    required this.eventCount,
    required this.segments,
  });

  final int totalMinutes;
  final int eventCount;
  final List<TypeMinutesSegment> segments;
}

class TypeMinutesSegment {
  const TypeMinutesSegment({required this.type, required this.minutes});

  final CalendarEntryType type;
  final int minutes;
}

class CalendarDayMarkerPill extends StatelessWidget {
  const CalendarDayMarkerPill({super.key, required this.marker});

  final CalendarDayMarkerData marker;

  Color _cardBackgroundForType(BuildContext context, CalendarEntryType type) {
    final scheme = Theme.of(context).colorScheme;
    return switch (type) {
      CalendarEntryType.lesson => scheme.surfaceContainerHigh,
      CalendarEntryType.meal => scheme.surface,
      CalendarEntryType.event => scheme.secondary,
      CalendarEntryType.choir => scheme.secondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final busyRatio = (marker.totalMinutes / 720).clamp(0.0, 1.0);
    if (busyRatio <= 0) return const SizedBox.shrink();

    final pillBackground = Color.alphaBlend(
      Colors.white.withValues(alpha: 0.08),
      scheme.surfaceContainerHighest,
    );

    return Container(
      width: 28,
      height: 7,
      margin: const EdgeInsets.only(top: 28),
      decoration: BoxDecoration(
        color: pillBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final filledWidth = (maxWidth * busyRatio).clamp(4.0, maxWidth);
          if (filledWidth <= 0) return const SizedBox.shrink();

          return ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: filledWidth,
                child: Row(
                  children: marker.segments
                      .map(
                        (segment) => Expanded(
                          flex: segment.minutes,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: _cardBackgroundForType(
                                context,
                                segment.type,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
