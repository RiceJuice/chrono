import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_day_columns.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_day_snap_physics.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_layout.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_navigation.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int kWeekScheduleTotalDaySlots = kWeekPageCount * 7;

/// Fallback-Zeitspanne, wenn eine Woche ohne Einträge ist (nur nahtlose Ansicht).
const WeekScheduleBounds _kSeamlessEmptyWeekBounds = WeekScheduleBounds(
  startMinute: 10 * 60.0,
  endMinute: 20 * 60.0,
);

/// Mobiler Wochen-Stundenplan: horizontal durch alle Tage des konfigurierten
/// Bereichs scrollbar (ohne harten Wochen-Sprung), drei Tage sichtbar, Tag-Snap.
class WeekScheduleMobileBody extends ConsumerStatefulWidget {
  const WeekScheduleMobileBody({
    required this.horizontalController,
    required this.hourHeight,
    super.key,
  });

  final ScrollController horizontalController;
  final double hourHeight;

  @override
  ConsumerState<WeekScheduleMobileBody> createState() =>
      _WeekScheduleMobileBodyState();
}

class _WeekScheduleMobileBodyState extends ConsumerState<WeekScheduleMobileBody> {
  bool _programmaticHorizontal = false;
  bool _handlingHorizontalScrollEnd = false;
  /// Letzter eingefädelter Tages-Index nach Snap; `null` bis zum ersten Stopp.
  int? _lastSnappedGlobalDayIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToSelectedDay(animated: false);
    });
  }

  void _scrollToSelectedDay({required bool animated}) {
    if (!widget.horizontalController.hasClients) return;
    final selected = ref.read(selectedDayProvider);
    final globalIndex = AppDateTime.localDay(selected)
        .difference(kWeekPageAnchorMonday)
        .inDays
        .clamp(0, kWeekScheduleTotalDaySlots - 1);
    final innerWidth = widget.horizontalController.position.viewportDimension;
    final dayWidth = weekSchedulePhoneDayColumnWidthFromInnerWidth(innerWidth);
    final maxExtent = widget.horizontalController.position.maxScrollExtent;
    final target = (globalIndex * dayWidth).clamp(0.0, maxExtent);
    _programmaticHorizontal = true;
    void finish() {
      _programmaticHorizontal = false;
      _lastSnappedGlobalDayIndex = globalIndex;
    }

    if (animated) {
      widget.horizontalController
          .animateTo(
            target,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          )
          .then((_) {
            if (mounted) finish();
          });
    } else {
      widget.horizontalController.jumpTo(target);
      finish();
    }
  }

  Future<void> _handleHorizontalScrollEnd() async {
    if (_programmaticHorizontal || _handlingHorizontalScrollEnd) return;
    if (!widget.horizontalController.hasClients) return;

    _handlingHorizontalScrollEnd = true;
    try {
      final innerWidth = widget.horizontalController.position.viewportDimension;
      final dayWidth = weekSchedulePhoneDayColumnWidthFromInnerWidth(innerWidth);
      if (dayWidth <= 0) return;

      final maxExtent = widget.horizontalController.position.maxScrollExtent;
      final raw = widget.horizontalController.offset;
      final snapped = ((raw / dayWidth).round() * dayWidth).clamp(0.0, maxExtent);

      if ((snapped - raw).abs() > 2) {
        _programmaticHorizontal = true;
        await widget.horizontalController.animateTo(
          snapped,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
        if (mounted) {
          _programmaticHorizontal = false;
        }
      }

      final off = widget.horizontalController.offset;
      final snappedIdx =
          (off / dayWidth).round().clamp(0, kWeekScheduleTotalDaySlots - 1);

      final previous = _lastSnappedGlobalDayIndex;
      if (previous != null) {
        final delta = (snappedIdx - previous).abs();
        if (delta > 0) {
          final pulses = delta.clamp(1, 14);
          for (var i = 0; i < pulses; i++) {
            HapticFeedback.mediumImpact();
          }
        }
      }
      _lastSnappedGlobalDayIndex = snappedIdx;

      final day = kWeekPageAnchorMonday.add(Duration(days: snappedIdx));
      ref.read(focusedDayProvider.notifier).update(day);
    } finally {
      if (mounted) {
        _handlingHorizontalScrollEnd = false;
      }
    }
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification &&
        notification.metrics.axis == Axis.horizontal) {
      _handleHorizontalScrollEnd();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DateTime>(selectedDayProvider, (previous, next) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToSelectedDay(animated: true);
      });
    });

    final focusMonday = weekMondayLocal(ref.watch(focusedDayProvider));
    final focusWeekDays = List<DateTime>.generate(
      7,
      (i) => focusMonday.add(Duration(days: i)),
    );
    final focusAsync = focusWeekDays
        .map((d) => ref.watch(filteredCalendarEntriesForDayProvider(d)))
        .toList(growable: false);

    for (final a in focusAsync) {
      if (a.hasError) {
        return Center(child: Text('Fehler: ${a.error}'));
      }
    }
    for (final a in focusAsync) {
      if (!a.hasValue) {
        return const Center(child: CircularProgressIndicator());
      }
    }

    final focusEntries = focusAsync
        .map((a) => a.value ?? const <CalendarEntry>[])
        .toList(growable: false);
    final anchorBounds =
        computeWeekScheduleBounds(focusEntries) ?? _kSeamlessEmptyWeekBounds;
    final anchorTotalHeight = anchorBounds.heightForHourHeight(widget.hourHeight);

    return LayoutBuilder(
      builder: (context, constraints) {
        final innerWidth = constraints.maxWidth;
        final dayWidth = weekSchedulePhoneDayColumnWidthFromInnerWidth(
          innerWidth,
        );
        final horizontalPhysics = WeekDaySnapScrollPhysics(
          dayColumnWidth: dayWidth,
        ).applyTo(ScrollConfiguration.of(context).getScrollPhysics(context));

        return NotificationListener<ScrollNotification>(
          onNotification: _onScrollNotification,
          child: SingleChildScrollView(
            child: SizedBox(
              height: anchorTotalHeight,
              width: innerWidth,
              child: ListView.builder(
                controller: widget.horizontalController,
                scrollDirection: Axis.horizontal,
                physics: horizontalPhysics,
                itemExtent: dayWidth,
                cacheExtent: dayWidth * 21,
                itemCount: kWeekScheduleTotalDaySlots,
                itemBuilder: (context, globalDayIndex) {
                  return WeekScheduleSeamlessDayTile(
                    globalDayIndex: globalDayIndex,
                    hourHeight: widget.hourHeight,
                    listCrossExtent: anchorTotalHeight,
                    dayWidth: dayWidth,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class WeekScheduleSeamlessDayTile extends ConsumerWidget {
  const WeekScheduleSeamlessDayTile({
    required this.globalDayIndex,
    required this.hourHeight,
    required this.listCrossExtent,
    required this.dayWidth,
    super.key,
  });

  final int globalDayIndex;
  final double hourHeight;
  final double listCrossExtent;
  final double dayWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = kWeekPageAnchorMonday.add(Duration(days: globalDayIndex));
    final monday = weekMondayLocal(day);
    final columnIndex = AppDateTime.localDay(day)
        .difference(AppDateTime.localDay(monday))
        .inDays;
    final weekDays = List<DateTime>.generate(
      7,
      (i) => monday.add(Duration(days: i)),
    );
    final asyncDays = weekDays
        .map((d) => ref.watch(filteredCalendarEntriesForDayProvider(d)))
        .toList(growable: false);

    for (final asyncDay in asyncDays) {
      if (asyncDay.hasError) {
        return SizedBox(
          width: dayWidth,
          height: listCrossExtent,
          child: Center(
            child: Text(
              'Fehler',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        );
      }
    }
    for (final asyncDay in asyncDays) {
      if (!asyncDay.hasValue) {
        return SizedBox(
          width: dayWidth,
          height: listCrossExtent,
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }
    }

    final entriesByDay = asyncDays
        .map((asyncDay) => asyncDay.value ?? const <CalendarEntry>[])
        .toList(growable: false);
    final bounds =
        computeWeekScheduleBounds(entriesByDay) ?? _kSeamlessEmptyWeekBounds;
    final totalHeight = bounds.heightForHourHeight(hourHeight);
    final safeColumnIndex = columnIndex.clamp(0, 6);
    final entries = entriesByDay[safeColumnIndex];

    return SizedBox(
      width: dayWidth,
      height: listCrossExtent,
      child: ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: dayWidth,
            height: totalHeight,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                WeekScheduleDayColumn(
                  day: day,
                  entries: entries,
                  bounds: bounds,
                  totalHeight: totalHeight,
                  hourHeight: hourHeight,
                  columnIndex: safeColumnIndex,
                  columnCount: 7,
                ),
                WeekNowLine(
                  weekDays: [day],
                  bounds: bounds,
                  hourHeight: hourHeight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
