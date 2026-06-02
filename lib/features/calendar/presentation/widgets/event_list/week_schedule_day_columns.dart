import 'dart:async';
import 'dart:math' as math;

import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_week_layout_tokens.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_all_day_break_bar.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_all_day_break_layout.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_all_day_day_label.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/calendar_entry_card.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_layout.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_timeline.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_viewport.dart';
import 'package:flutter/material.dart';

import '../../../../../core/widgets/app_hairline_divider.dart';

/// Eine Tages-Spalte im Wochenraster (Tablet: in [WeekDayColumns], Handy:
/// in [WeekScheduleMobileBody] mit fester Breite / nahtlosem Streifen).
class WeekScheduleDayColumn extends StatelessWidget {
  const WeekScheduleDayColumn({
    required this.day,
    required this.entries,
    required this.bounds,
    required this.totalHeight,
    required this.hourHeight,
    required this.columnIndex,
    required this.columnCount,
    super.key,
  });

  final DateTime day;
  final List<CalendarEntry> entries;
  final WeekScheduleBounds bounds;
  final double totalHeight;
  final double hourHeight;
  final int columnIndex;
  final int columnCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = Theme.of(context).colorScheme;
    final verticalDividerColor = theme.brightness == Brightness.dark
        ? const Color(0xFFFFFFFF).withValues(alpha: 0.15)
        : scheme.outline.withValues(alpha: 0.20);
    final hourDividerColor = theme.brightness == Brightness.dark
        ? const Color(0xFFFFFFFF).withValues(alpha: 0.12)
        : scheme.outline.withValues(alpha: 0.14);
    final weekendBackgroundColor = Color.alphaBlend(
      Colors.black.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.30 : 0.04,
      ),
      scheme.surface,
    );
    final isWeekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;

    return SizedBox(
      height: totalHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isWeekend ? weekendBackgroundColor : null,
          border: Border(
            left: AppHairlineDivider.borderSide(context, verticalDividerColor),
            right: columnIndex == columnCount - 1
                ? AppHairlineDivider.borderSide(context, verticalDividerColor)
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
                  hourHeight: hourHeight,
                  lineWidth: AppHairlineDivider.physicalPixel(context),
                ),
              ),
            ),
            Positioned.fill(
              child: WeekEntriesLayer(
                entries: entries,
                day: day,
                bounds: bounds,
                hourHeight: hourHeight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WeekDayColumns extends StatelessWidget {
  const WeekDayColumns({
    required this.weekDays,
    required this.entriesByDay,
    required this.bounds,
    required this.totalHeight,
    required this.hourHeight,
    super.key,
  });

  final List<DateTime> weekDays;
  final List<List<CalendarEntry>> entriesByDay;
  final WeekScheduleBounds bounds;
  final double totalHeight;
  final double hourHeight;

  @override
  Widget build(BuildContext context) {
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
                    return Expanded(
                      child: WeekScheduleDayColumn(
                        day: day,
                        entries: entriesByDay[columnIndex],
                        bounds: bounds,
                        totalHeight: totalHeight,
                        hourHeight: hourHeight,
                        columnIndex: columnIndex,
                        columnCount: 7,
                      ),
                    );
                  }),
                ),
                WeekNowLine(
                  weekDays: weekDays,
                  bounds: bounds,
                  hourHeight: hourHeight,
                ),
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
    required this.hourHeight,
    super.key,
  });

  final List<CalendarEntry> entries;
  final DateTime day;
  final WeekScheduleBounds bounds;
  final double hourHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final regularEntries = entries
            .where((entry) => entry.type != CalendarEntryType.breakType)
            .toList(growable: false);
        final compactMobile = weekScheduleUsesMobileSeamlessScroll(context);
        final placements = buildWeekEntryPlacements(
          entries: regularEntries,
          day: day,
          bounds: bounds,
          hourHeight: hourHeight,
          adjacentEntryGap: compactMobile
              ? kWeekScheduleAdjacentEntryGapPhone
              : kWeekScheduleAdjacentEntryGap,
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

class WeekAllDayBreakRow extends StatelessWidget {
  const WeekAllDayBreakRow({
    required this.weekDays,
    required this.entriesByDay,
    required this.showTimelineColumn,
    required this.sectionHeight,
    super.key,
  });

  final List<DateTime> weekDays;
  final List<List<CalendarEntry>> entriesByDay;
  final bool showTimelineColumn;
  final double sectionHeight;

  @override
  Widget build(BuildContext context) {
    final layout = layoutWeekAllDayBreaks(entriesByDay: entriesByDay);
    final barHeight = math.max(
      0.0,
      sectionHeight - kWeekAllDayDayLabelHeight,
    );
    final scheme = Theme.of(context).colorScheme;
    final borderColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFFFFFF).withValues(alpha: 0.15)
        : scheme.outline.withValues(alpha: 0.20);

    return SizedBox(
      height: sectionHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showTimelineColumn)
                const SizedBox(width: kCalendarTimelineGutterWidth),
              Expanded(
                child: WeekAllDayDayLabelsRow(weekDays: weekDays),
              ),
            ],
          ),
          SizedBox(
            height: barHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showTimelineColumn)
                  SizedBox(
                    width: kCalendarTimelineGutterWidth,
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4, right: 8),
                        child: Text(
                          'Ganztägig',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.65,
                                    ),
                                    height: 1.1,
                                  ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: WeekAllDayBreakSpanLayer(
                    layout: layout,
                    columnCount: 7,
                    borderColor: borderColor,
                    sectionHeight: barHeight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Raster-Hintergrund (Spaltentrenner) plus mehrtägige Ganztags-Balken.
class WeekAllDayBreakSpanLayer extends StatelessWidget {
  const WeekAllDayBreakSpanLayer({
    required this.layout,
    required this.columnCount,
    required this.borderColor,
    this.maxVisibleLanes,
    this.sectionHeight,
    super.key,
  });

  final WeekAllDayBreakLayout layout;
  final int columnCount;
  final Color borderColor;
  final int? maxVisibleLanes;
  final double? sectionHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barHeight = sectionHeight ?? constraints.maxHeight;
        final laneLimit = maxVisibleLanes ??
            weekAllDayVisibleLaneLimit(barHeight + kWeekAllDayDayLabelHeight);
        final visibleSpans = layout.spans
            .where((span) => span.lane < laneLimit)
            .toList(growable: false);
        final columnWidth = constraints.maxWidth / columnCount;
        const horizontalInset = 1.5;

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(columnCount, (columnIndex) {
                return Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        left: AppHairlineDivider.borderSide(
                          context,
                          borderColor,
                        ),
                        right: columnIndex == columnCount - 1
                            ? AppHairlineDivider.borderSide(
                                context,
                                borderColor,
                              )
                            : BorderSide.none,
                        bottom: AppHairlineDivider.borderSide(
                          context,
                          borderColor,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            for (final span in visibleSpans) ...[
              Positioned(
                left: span.startColumn * columnWidth + horizontalInset,
                width:
                    (span.endColumn - span.startColumn + 1) * columnWidth -
                    horizontalInset * 2,
                top:
                    kWeekAllDayRowVerticalPadding / 2 +
                    span.lane * (kWeekAllDayLaneHeight + kWeekAllDayLaneGap),
                height: kWeekAllDayLaneHeight,
                child: WeekAllDayBreakBar(
                  label: span.label,
                  segment: WeekAllDayBreakBarSegment.single,
                  showLabel: false,
                ),
              ),
              Positioned(
                left: span.startColumn * columnWidth + horizontalInset,
                width: columnWidth - horizontalInset * 2,
                top:
                    kWeekAllDayRowVerticalPadding / 2 +
                    span.lane * (kWeekAllDayLaneHeight + kWeekAllDayLaneGap),
                height: kWeekAllDayLaneHeight,
                child: WeekAllDayBreakBar(
                  label: span.label,
                  segment: WeekAllDayBreakBarSegment.start,
                  showLabel: true,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Ganztags-Zelle für eine einzelne Tages-Spalte (Handy-Streifen).
class WeekAllDayBreakCell extends StatelessWidget {
  const WeekAllDayBreakCell({
    required this.day,
    required this.layout,
    required this.columnIndex,
    required this.columnCount,
    required this.borderColor,
    this.maxVisibleLanes,
    this.sectionHeight,
    this.firstVisibleColumnInWeek,
    super.key,
  });

  final DateTime day;
  final WeekAllDayBreakLayout layout;
  final int columnIndex;
  final int columnCount;
  final Color borderColor;
  final int? maxVisibleLanes;
  final double? sectionHeight;
  final int? firstVisibleColumnInWeek;

  @override
  Widget build(BuildContext context) {
    final spans = layout.spansForColumn(columnIndex);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WeekAllDayDayLabel(day: day, compact: columnCount == 1),
        Expanded(
          child: _WeekAllDayBreakCellBody(
            layout: layout,
            columnIndex: columnIndex,
            columnCount: columnCount,
            borderColor: borderColor,
            spans: spans,
            maxVisibleLanes: maxVisibleLanes,
            sectionHeight: sectionHeight,
            firstVisibleColumnInWeek: firstVisibleColumnInWeek,
          ),
        ),
      ],
    );
  }
}

class _WeekAllDayBreakCellBody extends StatelessWidget {
  const _WeekAllDayBreakCellBody({
    required this.layout,
    required this.columnIndex,
    required this.columnCount,
    required this.borderColor,
    required this.spans,
    this.maxVisibleLanes,
    this.sectionHeight,
    this.firstVisibleColumnInWeek,
  });

  final WeekAllDayBreakLayout layout;
  final int columnIndex;
  final int columnCount;
  final Color borderColor;
  final List<WeekAllDayBreakSpan> spans;
  final int? maxVisibleLanes;
  final double? sectionHeight;
  final int? firstVisibleColumnInWeek;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          left: AppHairlineDivider.borderSide(context, borderColor),
          right: columnIndex == columnCount - 1
              ? AppHairlineDivider.borderSide(context, borderColor)
              : BorderSide.none,
          bottom: AppHairlineDivider.borderSide(context, borderColor),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barHeight = sectionHeight ?? constraints.maxHeight;
          final laneLimit = maxVisibleLanes ??
              weekAllDayVisibleLaneLimit(barHeight + kWeekAllDayDayLabelHeight);
          final visibleSpans = spans
              .where((span) => span.lane < laneLimit)
              .toList(growable: false);

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              for (final span in visibleSpans) ...[
                Positioned(
                  left: 2,
                  right: 2,
                  top:
                      kWeekAllDayRowVerticalPadding / 2 +
                      span.lane * (kWeekAllDayLaneHeight + kWeekAllDayLaneGap),
                  height: kWeekAllDayLaneHeight,
                  child: WeekAllDayBreakBar(
                    label: span.label,
                    segment: columnCount == 1
                        ? WeekAllDayBreakBarSegment.single
                        : span.segmentAt(columnIndex),
                    showLabel: false,
                  ),
                ),
                if (span.shouldShowLabelAtColumn(
                  columnIndex,
                  firstVisibleColumnInWeek: firstVisibleColumnInWeek,
                ))
                  Positioned(
                    left: 2,
                    right: 2,
                    top:
                        kWeekAllDayRowVerticalPadding / 2 +
                        span.lane *
                            (kWeekAllDayLaneHeight + kWeekAllDayLaneGap),
                    height: kWeekAllDayLaneHeight,
                    child: WeekAllDayBreakBar(
                      label: span.label,
                      segment: WeekAllDayBreakBarSegment.single,
                      showLabel: true,
                    ),
                  ),
              ],
            ],
          );
        },
      ),
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
    final compactMobile = weekScheduleUsesMobileSeamlessScroll(context);
    final horizontalGap = compactMobile
        ? kWeekScheduleEntryHorizontalGapPhone
        : kWeekScheduleEntryHorizontalGapDefault;
    final verticalGap = compactMobile
        ? kWeekScheduleEntryVerticalGapPhone
        : kWeekScheduleEntryVerticalGapDefault;
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
  const WeekNowLine({
    required this.weekDays,
    required this.bounds,
    required this.hourHeight,
    super.key,
  });

  final List<DateTime> weekDays;
  final WeekScheduleBounds bounds;
  final double hourHeight;

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

    final top = topForMinute(
      nowMinute,
      widget.bounds,
      widget.hourHeight,
    );
    return Positioned(
      left: 0,
      right: 0,
      top: top,
      child: IgnorePointer(child: Container(height: 1, color: Colors.red)),
    );
  }
}
