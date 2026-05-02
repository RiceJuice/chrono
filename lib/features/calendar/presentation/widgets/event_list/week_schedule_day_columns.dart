import 'dart:async';
import 'dart:math' as math;

import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/calendar_entry_card.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_layout.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_timeline.dart';
import 'package:flutter/material.dart';

class WeekDayColumns extends StatelessWidget {
  const WeekDayColumns({
    required this.weekDays,
    required this.entriesByDay,
    required this.bounds,
    required this.totalHeight,
    super.key,
  });

  final List<DateTime> weekDays;
  final List<List<CalendarEntry>> entriesByDay;
  final WeekScheduleBounds bounds;
  final double totalHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = Theme.of(context).colorScheme;
    final verticalDividerColor = theme.brightness == Brightness.dark
        ? const Color(0xFF242424)
        : scheme.outline.withValues(alpha: 0.20);
    final hourDividerColor = theme.brightness == Brightness.dark
        ? const Color(0xFF1C1C1E)
        : scheme.outline.withValues(alpha: 0.14);
    final weekendBackgroundColor = Color.alphaBlend(
      Colors.black.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.30 : 0.04,
      ),
      scheme.surface,
    );

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: totalHeight,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Row(
                  children: List.generate(7, (columnIndex) {
                    final day = weekDays[columnIndex];
                    final isWeekend =
                        day.weekday == DateTime.saturday ||
                        day.weekday == DateTime.sunday;

                    return Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: isWeekend ? weekendBackgroundColor : null,
                          border: Border(
                            left: BorderSide(color: verticalDividerColor),
                            right: columnIndex == 6
                                ? BorderSide(color: verticalDividerColor)
                                : BorderSide.none,
                          ),
                        ),
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: WeekHourGridPainter(
                                  bounds: bounds,
                                  lineColor: hourDividerColor,
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: WeekEntriesLayer(
                                entries: entriesByDay[columnIndex],
                                day: day,
                                bounds: bounds,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                WeekNowLine(weekDays: weekDays, bounds: bounds),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class WeekEntriesLayer extends StatelessWidget {
  const WeekEntriesLayer({
    required this.entries,
    required this.day,
    required this.bounds,
    super.key,
  });

  final List<CalendarEntry> entries;
  final DateTime day;
  final WeekScheduleBounds bounds;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final placements = buildWeekEntryPlacements(
          entries: entries,
          day: day,
          bounds: bounds,
          hourHeight: kWeekScheduleHourHeight,
        );

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            for (final placement in placements)
              _WeekEntryCardFrame(
                placement: placement,
                columnWidth: constraints.maxWidth,
              ),
          ],
        );
      },
    );
  }
}

class _WeekEntryCardFrame extends StatelessWidget {
  const _WeekEntryCardFrame({
    required this.placement,
    required this.columnWidth,
  });

  final WeekEntryPlacement placement;
  final double columnWidth;

  @override
  Widget build(BuildContext context) {
    const horizontalGap = 6.0;
    const verticalGap = 3.0;
    final laneWidth =
        (columnWidth - horizontalGap * (placement.laneCount + 1)) /
        placement.laneCount;
    final left = horizontalGap + placement.lane * (laneWidth + horizontalGap);

    return Positioned(
      left: left,
      width: math.max(0.0, laneWidth),
      top: placement.top,
      height: math.max(1.0, placement.height),
      child: Padding(
        padding: EdgeInsets.only(
          top: verticalGap + placement.insetTop,
          bottom: verticalGap + placement.insetBottom,
        ),
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(0.92)),
          child: CalendarEntryCard(
            entry: placement.entry,
            applyPastStyling: false,
            showTimeColumn: false,
            weekGridCompact: true,
          ),
        ),
      ),
    );
  }
}

class WeekNowLine extends StatefulWidget {
  const WeekNowLine({required this.weekDays, required this.bounds, super.key});

  final List<DateTime> weekDays;
  final WeekScheduleBounds bounds;

  @override
  State<WeekNowLine> createState() => _WeekNowLineState();
}

class _WeekNowLineState extends State<WeekNowLine> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.weekDays.any(AppDateTime.isTodayLocal)) {
      return const SizedBox.shrink();
    }

    final now = AppDateTime.nowLocal();
    final nowMinute =
        now.hour * 60.0 +
        now.minute +
        now.second / 60.0 +
        now.millisecond / 60000.0;
    if (nowMinute < widget.bounds.startMinute ||
        nowMinute > widget.bounds.endMinute) {
      return const SizedBox.shrink();
    }

    final top = topForMinute(nowMinute, widget.bounds);
    return Positioned(
      left: 0,
      right: 0,
      top: top,
      child: IgnorePointer(child: Container(height: 1, color: Colors.red)),
    );
  }
}
