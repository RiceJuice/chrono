import 'package:chronoapp/core/time/app_date_time.dart';

import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';

import 'package:chronoapp/features/calendar/presentation/providers/calendar_providers.dart';

import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_day_columns.dart';

import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_day_snap_physics.dart';

import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_layout.dart';

import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_initial_scroll.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_navigation.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_viewport.dart';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';



const int _kMsPerAnimatedDay = 30;

const int _kMinScrollAnimMs = 300;

const int _kMaxScrollAnimMs = 620;



/// Schneller Start, weiches Auslaufen — kein ease-in am Anfang.

const Curve _kExternalScrollCurve = Curves.easeInOutCubic;



/// Fallback-Zeitspanne, wenn eine Woche ohne Einträge ist (nur nahtlose Ansicht).

const WeekScheduleBounds _kSeamlessEmptyWeekBounds = WeekScheduleBounds(

  startMinute: 10 * 60.0,

  endMinute: 20 * 60.0,

);



/// Mobiler Wochen-Stundenplan: horizontal scrollbar, Portrait: Tag-Snap,

/// Querformat: Wochen-Snap.

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

  bool _suppressNextSelectedDayScroll = false;

  int _externalScrollGeneration = 0;

  int? _lastTrackedDayIndex;

  int? _lastPreviewMondayIndex;

  double? _lastHorizontalDayWidth;

  double? _lastHorizontalSnapStride;

  WeekScheduleBounds? _cachedAnchorBounds;

  bool _initialScrollDone = false;



  @override

  void initState() {

    super.initState();

    _scheduleInitialScrollRetry();

  }

  /// Beim ersten App-Start sind die Kalender-Daten asynchron — der Build liefert
  /// dann zuerst einen [CircularProgressIndicator] und die [ListView] (mit
  /// `horizontalController`) existiert noch nicht. Ohne Retry liefe der
  /// Initial-Scroll ins Leere und die [ListView] startete bei Offset 0
  /// (= 1. Januar 2018, [kWeekPageAnchorMonday]). Daher wird hier so lange auf
  /// jedes Frame gewartet, bis der Controller Clients hat — und auch dann erst
  /// das eigentliche Initial-Scroll-to-today durchgeführt.

  void _scheduleInitialScrollRetry() {

    WidgetsBinding.instance.addPostFrameCallback((_) async {

      if (!mounted || _initialScrollDone) return;

      if (!widget.horizontalController.hasClients ||

          widget.horizontalController.position.viewportDimension <= 0) {

        _scheduleInitialScrollRetry();

        return;

      }

      await _scrollToSelectedDay(animated: false);

      if (!mounted) return;

      setState(() {

        _initialScrollDone = true;

      });

    });

  }



  int _globalDayIndexFromOffset(double offset, double dayWidth) {

    if (dayWidth <= 0) return 0;

    return (offset / dayWidth)

        .round()

        .clamp(0, kWeekScheduleTotalDaySlots - 1);

  }



  Duration _scrollDurationForDaySpan(int daySpan) {

    final ms = (daySpan * _kMsPerAnimatedDay + _kMinScrollAnimMs)

        .clamp(_kMinScrollAnimMs, _kMaxScrollAnimMs);

    return Duration(milliseconds: ms.round());

  }



  Future<void> _animateHorizontalTo(

    double target, {

    required int daySpan,

    required int generation,

  }) async {

    if (!widget.horizontalController.hasClients) return;

    if (generation != _externalScrollGeneration) return;



    await widget.horizontalController.animateTo(

      target,

      duration: _scrollDurationForDaySpan(daySpan),

      curve: _kExternalScrollCurve,

    );

  }



  void _syncFocusedDayToSelected() {

    final selected = ref.read(selectedDayProvider);

    final focused = ref.read(focusedDayProvider);

    if (selected.year == focused.year &&

        selected.month == focused.month &&

        selected.day == focused.day) {

      return;

    }

    ref.read(focusedDayProvider.notifier).update(selected);

  }



  Future<void> _scrollToSelectedDay({required bool animated}) async {

    if (!mounted) return;

    if (!widget.horizontalController.hasClients) return;



    final selected = ref.read(selectedDayProvider);

    final selectedGlobalIndex = weekScheduleGlobalDayIndex(selected);

    final innerWidth = widget.horizontalController.position.viewportDimension;

    final orientation = MediaQuery.orientationOf(context);

    final stride = weekSchedulePanStrideFor(context);

    final dayWidth = weekSchedulePhoneDayColumnWidthFromInnerWidth(

      innerWidth,

      orientation: orientation,

    );

    if (dayWidth <= 0) return;



    final targetGlobalIndex = weekScheduleScrollTargetGlobalIndex(
      selectedGlobalIndex,
      stride,
    );

    final maxExtent = widget.horizontalController.position.maxScrollExtent;

    final target = weekScheduleOffsetForGlobalIndex(targetGlobalIndex, dayWidth)
        .clamp(0.0, maxExtent);

    final offset = widget.horizontalController.offset;



    if ((offset - target).abs() < 1.5) {

      _lastTrackedDayIndex = selectedGlobalIndex;

      _lastPreviewMondayIndex = weekScheduleScrollTargetGlobalIndex(
        selectedGlobalIndex,
        WeekSchedulePanStride.week,
      );

      return;

    }



    final generation = ++_externalScrollGeneration;

    ref.read(weekScheduleScrollDayProvider.notifier).clear();

    _programmaticHorizontal = true;



    try {

      if (!animated) {

        widget.horizontalController.jumpTo(target);

      } else {

        final currentIndex = _lastTrackedDayIndex ??

            _globalDayIndexFromOffset(offset, dayWidth);

        final dayDelta =

            (selectedGlobalIndex - currentIndex).abs().clamp(1, 120);

        await _animateHorizontalTo(

          target,

          daySpan: dayDelta,

          generation: generation,

        );

      }

    } finally {

      if (mounted && generation == _externalScrollGeneration) {

        _programmaticHorizontal = false;

        _lastTrackedDayIndex = selectedGlobalIndex;

        _lastPreviewMondayIndex = weekScheduleScrollTargetGlobalIndex(
        selectedGlobalIndex,
        WeekSchedulePanStride.week,
      );

        if (animated) {

          _syncFocusedDayToSelected();

        }

      }

    }

  }



  void _setScrollPreviewIndex(int globalDayIndex, WeekSchedulePanStride stride) {

    if (_programmaticHorizontal) return;



    final clamped = globalDayIndex.clamp(0, kWeekScheduleTotalDaySlots - 1);

    final mondayIndex = weekScheduleScrollTargetGlobalIndex(
      clamped,
      WeekSchedulePanStride.week,
    );



    if (stride == WeekSchedulePanStride.week) {

      if (mondayIndex == _lastPreviewMondayIndex) return;

      _lastPreviewMondayIndex = mondayIndex;

    } else {

      if (clamped == _lastTrackedDayIndex) return;

    }



    _lastTrackedDayIndex = clamped;



    final selected = ref.read(selectedDayProvider);

    final weekdayOffset = AppDateTime.weekdayOffsetFromMonday(selected);

    final previewDay = weekScheduleDayFromGlobalIndex(
      stride == WeekSchedulePanStride.week
          ? mondayIndex + weekdayOffset
          : clamped,
    );

    HapticFeedback.mediumImpact();

    ref.read(weekScheduleScrollDayProvider.notifier).setPreview(previewDay);

  }



  void _commitFromSnappedOffset(

    double offset,

    double dayWidth,

    double snapStride,

    WeekSchedulePanStride stride,

  ) {

    final alignedOffset = stride == WeekSchedulePanStride.week

        ? (offset / snapStride).round() * snapStride

        : (offset / dayWidth).round() * dayWidth;

    final snappedGlobalIndex =

        _globalDayIndexFromOffset(alignedOffset, dayWidth);

    final selected = ref.read(selectedDayProvider);

    final weekdayOffset = AppDateTime.weekdayOffsetFromMonday(selected);

    final int commitGlobalIndex;

    if (stride == WeekSchedulePanStride.week) {

      commitGlobalIndex =

          weekScheduleScrollTargetGlobalIndex(
                snappedGlobalIndex,
                WeekSchedulePanStride.week,
              ) +
              weekdayOffset;

    } else {

      commitGlobalIndex = snappedGlobalIndex;

    }



    final clamped =

        commitGlobalIndex.clamp(0, kWeekScheduleTotalDaySlots - 1);

    final day = weekScheduleDayFromGlobalIndex(clamped);

    _lastTrackedDayIndex = clamped;

    _lastPreviewMondayIndex = weekScheduleScrollTargetGlobalIndex(
      clamped,
      WeekSchedulePanStride.week,
    );

    ref.read(weekScheduleScrollDayProvider.notifier).clear();

    _suppressNextSelectedDayScroll = true;

    ref.read(selectedDayProvider.notifier).update(day, haptic: false);

    ref.read(focusedDayProvider.notifier).update(day);

  }



  int? _globalDayIndexFromScrollMetrics(

    ScrollMetrics metrics,

    WeekSchedulePanStride stride,

  ) {

    final orientation = MediaQuery.orientationOf(context);

    final dayWidth = weekSchedulePhoneDayColumnWidthFromInnerWidth(

      metrics.viewportDimension,

      orientation: orientation,

    );

    if (dayWidth <= 0) return null;

    return _globalDayIndexFromOffset(metrics.pixels, dayWidth);

  }



  Future<void> _handleHorizontalScrollEnd() async {

    if (_programmaticHorizontal || _handlingHorizontalScrollEnd) return;

    if (!widget.horizontalController.hasClients) return;



    _handlingHorizontalScrollEnd = true;

    try {

      final innerWidth = widget.horizontalController.position.viewportDimension;

      final orientation = MediaQuery.orientationOf(context);

      final stride = weekSchedulePanStrideFor(context);

      final dayWidth = weekSchedulePhoneDayColumnWidthFromInnerWidth(

        innerWidth,

        orientation: orientation,

      );

      final snapStride = weekScheduleSnapStrideFromInnerWidth(

        innerWidth,

        orientation: orientation,

        stride: stride,

      );

      if (dayWidth <= 0 || snapStride <= 0) return;



      final offset = widget.horizontalController.offset;

      _commitFromSnappedOffset(offset, dayWidth, snapStride, stride);

    } finally {

      if (mounted) {

        _handlingHorizontalScrollEnd = false;

      }

    }

  }



  bool _onScrollNotification(ScrollNotification notification) {

    if (notification.metrics.axis != Axis.horizontal) return false;



    final stride = weekSchedulePanStrideFor(context);



    if (notification is ScrollStartNotification) {

      // Nur Nutzer-Gesten abbrechen — programmatische Scrolls (Header-Sync)
      // dürfen _externalScrollGeneration nicht invalidieren.
      if (notification.dragDetails != null) {

        _externalScrollGeneration++;

      }

      final idx = _globalDayIndexFromScrollMetrics(

        notification.metrics,

        stride,

      );

      if (idx != null) {

        _lastTrackedDayIndex = idx;

        _lastPreviewMondayIndex = weekScheduleScrollTargetGlobalIndex(
          idx,
          WeekSchedulePanStride.week,
        );

      }

    } else if (notification is ScrollUpdateNotification) {

      final idx = _globalDayIndexFromScrollMetrics(

        notification.metrics,

        stride,

      );

      if (idx != null) {

        _setScrollPreviewIndex(idx, stride);

      }

    } else if (notification is ScrollEndNotification) {

      _handleHorizontalScrollEnd();

    }

    return false;

  }



  @override

  Widget build(BuildContext context) {

    ref.listen<DateTime>(selectedDayProvider, (previous, next) {

      if (!mounted || previous == null) return;

      if (_suppressNextSelectedDayScroll) {

        _suppressNextSelectedDayScroll = false;

        return;

      }

      if (_programmaticHorizontal || _handlingHorizontalScrollEnd) return;



      _scrollToSelectedDay(animated: true);

    });



    final focusMonday = AppDateTime.localMondayOfWeek(
      ref.watch(selectedDayProvider),
    );

    final focusWeekDays = List<DateTime>.generate(

      7,

      (i) => AppDateTime.addLocalCalendarDays(focusMonday, i),

    );

    final focusAsync = focusWeekDays

        .map((d) => ref.watch(filteredCalendarEntriesForDayProvider(d)))

        .toList(growable: false);



    for (final a in focusAsync) {

      if (a.hasError) {

        return Center(child: Text('Fehler: ${a.error}'));

      }

    }

    final allWeekDataReady = focusAsync.every((a) => a.hasValue);

    if (!allWeekDataReady && _cachedAnchorBounds == null) {

      return const Center(child: CircularProgressIndicator());

    }



    final focusEntries = focusAsync

        .map((a) => a.value ?? const <CalendarEntry>[])

        .toList(growable: false);

    final computedBounds =

        computeWeekScheduleBounds(focusEntries) ?? _kSeamlessEmptyWeekBounds;

    if (allWeekDataReady) {

      _cachedAnchorBounds = computedBounds;

    }

    final anchorBounds = _cachedAnchorBounds ?? computedBounds;

    final anchorTotalHeight = anchorBounds.heightForHourHeight(widget.hourHeight);



    return LayoutBuilder(

      builder: (context, constraints) {

        final innerWidth = constraints.maxWidth;

        final orientation = MediaQuery.orientationOf(context);

        final stride = weekSchedulePanStrideFor(context);

        final dayWidth = weekSchedulePhoneDayColumnWidthFromInnerWidth(

          innerWidth,

          orientation: orientation,

        );

        final snapStride = weekScheduleSnapStrideFromInnerWidth(

          innerWidth,

          orientation: orientation,

          stride: stride,

        );

        final prevDayW = _lastHorizontalDayWidth;

        final prevStride = _lastHorizontalSnapStride;

        _lastHorizontalDayWidth = dayWidth;

        _lastHorizontalSnapStride = snapStride;

        if ((prevDayW != null && (prevDayW - dayWidth).abs() > 0.5) ||

            (prevStride != null && (prevStride - snapStride).abs() > 0.5)) {

          WidgetsBinding.instance.addPostFrameCallback((_) {

            if (mounted) _scrollToSelectedDay(animated: false);

          });

        }

        final horizontalPhysics = WeekScheduleSnapScrollPhysics(

          snapStride: snapStride,

          dayColumnWidth: dayWidth,

        ).applyTo(ScrollConfiguration.of(context).getScrollPhysics(context));



        // Die [ListView] muss auch vor dem Initial-Scroll im Tree sein, damit
        // der [ScrollController] eine Position bekommt; sonst kann
        // [_scheduleInitialScrollRetry] niemals scrollen. Wir blenden sie
        // jedoch unsichtbar, bis der jump auf den aktuellen Tag erfolgt ist —
        // andernfalls würde für ein Frame der Listen-Anfang
        // ([kWeekPageAnchorMonday] = 1. Januar 2018) sichtbar werden.

        final listView = ListView.builder(

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

        );



        return NotificationListener<ScrollNotification>(

          onNotification: _onScrollNotification,

          child: SizedBox(

            height: anchorTotalHeight,

            width: innerWidth,

            child: Stack(

              fit: StackFit.expand,

              children: [

                Opacity(

                  opacity: _initialScrollDone ? 1.0 : 0.0,

                  child: listView,

                ),

                if (!_initialScrollDone)

                  const Center(child: CircularProgressIndicator()),

              ],

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

    final day = weekScheduleDayFromGlobalIndex(globalDayIndex);

    final monday = AppDateTime.localMondayOfWeek(day);

    final columnIndex = AppDateTime.weekdayOffsetFromMonday(day);

    final weekDays = List<DateTime>.generate(

      7,

      (i) => AppDateTime.addLocalCalendarDays(monday, i),

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

