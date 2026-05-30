import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_week_layout_tokens.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_grid.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_layout.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_day_columns.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_mobile_body.dart';
import 'package:chronoapp/core/startup/calendar_startup_state.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_navigation.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/event_list_page_transition.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_page_transition.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_timeline.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WeekScheduleView extends ConsumerStatefulWidget {
  const WeekScheduleView({super.key});

  @override
  ConsumerState<WeekScheduleView> createState() => _WeekScheduleViewState();
}

class _WeekScheduleViewState extends ConsumerState<WeekScheduleView>
    with SingleTickerProviderStateMixin {
  late final PageController _weekPageController;
  late final ScrollController _phoneSeamlessScroll;
  AnimationController? _transitionController;
  int? _currentPage;
  int? _lastProgrammaticPage;
  _WeekTransitionData? _activeTransition;
  double _timelineScrollOffset = 0;
  bool? _lastUsesMobileSeamlessScroll;

  @override
  void initState() {
    super.initState();
    _phoneSeamlessScroll = ScrollController(
      initialScrollOffset:
          CalendarStartupState.phoneSeamlessScrollOffset ?? 0,
    );
    final monday = AppDateTime.localMondayOfWeek(ref.read(focusedDayProvider));
    final initialPage = pageIndexForMonday(monday);
    _weekPageController = PageController(initialPage: initialPage);
    _ensureTransitionController();
    _currentPage = initialPage;
  }

  @override
  void dispose() {
    _transitionController?.dispose();
    _weekPageController.dispose();
    _phoneSeamlessScroll.dispose();
    super.dispose();
  }

  AnimationController _ensureTransitionController() {
    return _transitionController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
  }

  double _viewportWidth() {
    if (_weekPageController.hasClients) {
      final viewportDimension = _weekPageController.position.viewportDimension;
      if (viewportDimension > 0) return viewportDimension;
    }
    return MediaQuery.sizeOf(context).width - kCalendarTimelineGutterWidth;
  }

  double _viewportWidthFactor() {
    final viewportWidth = _viewportWidth().clamp(360.0, 1180.0);
    return ((viewportWidth - 360.0) / (1180.0 - 360.0)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DateTime>(focusedDayProvider, _syncPageToFocusedWeek);

    final usesMobileSeamless = weekScheduleUsesMobileSeamlessScroll(context);
    if (_lastUsesMobileSeamlessScroll != null &&
        _lastUsesMobileSeamlessScroll != usesMobileSeamless &&
        !usesMobileSeamless) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncPageToFocusedWeek(null, ref.read(focusedDayProvider));
      });
    }
    _lastUsesMobileSeamlessScroll = usesMobileSeamless;

    final hourHeight = weekScheduleHourHeightFor(context);

    return Stack(
      children: [
        Positioned.fill(
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleScheduleScrollNotification,
            child: Padding(
              padding: const EdgeInsets.only(
                left: kCalendarTimelineGutterWidth,
              ),
              child: usesMobileSeamless
                  ? WeekScheduleMobileBody(
                      horizontalController: _phoneSeamlessScroll,
                      hourHeight: hourHeight,
                    )
                  : PageView.builder(
                      controller: _weekPageController,
                      physics: _SnappyPageViewPhysics(
                        widthFactor: _viewportWidthFactor(),
                      ).applyTo(
                        ScrollConfiguration.of(
                          context,
                        ).getScrollPhysics(context),
                      ),
                      itemCount: kWeekPageCount,
                      onPageChanged: _handlePageChanged,
                      itemBuilder: (context, pageIndex) {
                        return WeekScheduleGrid(
                          monday: mondayForPageIndex(pageIndex),
                          showTimelineColumn: false,
                          hourHeight: hourHeight,
                        );
                      },
                    ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: kCalendarTimelineGutterWidth,
          child: IgnorePointer(child: _buildFixedTimeline(context)),
        ),
        if (_activeTransition != null)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(
                left: kCalendarTimelineGutterWidth,
              ),
              child: WeekSchedulePageTransition(
                fromMonday: _activeTransition!.fromMonday,
                toMonday: _activeTransition!.toMonday,
                isForward: _activeTransition!.isForward,
                animation: _ensureTransitionController(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFixedTimeline(BuildContext context) {
    final monday = AppDateTime.localMondayOfWeek(ref.watch(focusedDayProvider));
    final weekDays = List<DateTime>.generate(
      7,
      (index) => AppDateTime.addLocalCalendarDays(monday, index),
    );
    final asyncDays = weekDays
        .map((day) => ref.watch(filteredCalendarEntriesForDayProvider(day)))
        .toList(growable: false);

    if (asyncDays.any((day) => day.hasError)) {
      return const SizedBox.shrink();
    }
    if (asyncDays.any((day) => !day.hasValue)) {
      return const SizedBox.shrink();
    }

    final entriesByDay = asyncDays
        .map((asyncDay) => asyncDay.value ?? const <CalendarEntry>[])
        .toList(growable: false);
    final regularEntriesByDay = entriesByDay
        .map(
          (entries) => entries
              .where((entry) => entry.type != CalendarEntryType.breakType)
              .toList(growable: false),
        )
        .toList(growable: false);
    final bounds = computeWeekScheduleBoundsOrDefault(regularEntriesByDay);

    final maxAllDayBreaks = entriesByDay.fold<int>(
      0,
      (max, entries) => max < distinctBreakNames(entries).length
          ? distinctBreakNames(entries).length
          : max,
    );
    final allDayRowHeight = weekAllDayRowHeight(maxAllDayBreaks);
    final hourHeight = weekScheduleHourHeightFor(context);
    final totalHeight = bounds.heightForHourHeight(hourHeight);
    final showCurrentTime = weekDays.any(AppDateTime.isTodayLocal);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (allDayRowHeight > 0)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: allDayRowHeight,
            child: const ColoredBox(color: Colors.transparent),
          ),
        Positioned(
          left: 0,
          right: 0,
          top: allDayRowHeight,
          bottom: 0,
          child: ClipRect(
            child: Transform.translate(
              offset: Offset(0, -_timelineScrollOffset),
              child: SizedBox(
                height: totalHeight,
                child: WeekTimelineColumn(
                  bounds: bounds,
                  totalHeight: totalHeight,
                  hourHeight: hourHeight,
                  showCurrentTime: showCurrentTime,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _handleScheduleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.horizontal) {
      return false;
    }
    if (notification.metrics.axis != Axis.vertical) return false;

    final offset = notification.metrics.pixels.clamp(
      0.0,
      notification.metrics.maxScrollExtent,
    );
    if ((offset - _timelineScrollOffset).abs() > 0.5) {
      setState(() {
        _timelineScrollOffset = offset;
      });
    }
    return false;
  }

  void _startOverlayTransition({required int fromPage, required int toPage}) {
    final transition = _WeekTransitionData(
      fromMonday: mondayForPageIndex(fromPage),
      toMonday: mondayForPageIndex(toPage),
      isForward: toPage > fromPage,
    );

    setState(() {
      _activeTransition = transition;
    });

    final pageDelta = (toPage - fromPage).abs();

    final transitionController = _ensureTransitionController();
    transitionController.stop();
    transitionController.value = 0;
    final simulationVelocity = DayContentTransitionPhysics.simulationVelocityFor(
      pageDelta: pageDelta,
    );
    final simulation = SpringSimulation(
      DayContentTransitionPhysics.spring,
      0,
      1,
      simulationVelocity,
      tolerance: DayContentTransitionPhysics.tolerance,
    );

    transitionController.animateWith(simulation).whenComplete(() {
      if (!mounted) return;
      if (_activeTransition == transition) {
        setState(() {
          _activeTransition = null;
        });
      }
    });
  }

  void _syncPageToFocusedWeek(DateTime? previous, DateTime next) {
    if (!mounted) return;
    // Nahtlose Mobile-ListView (Phone-Portrait) scrollt über [WeekScheduleMobileBody].
    if (weekScheduleUsesMobileSeamlessScroll(context)) {
      return;
    }

    final targetPage = pageIndexForMonday(AppDateTime.localMondayOfWeek(next));

    void applySync() {
      if (!mounted) return;
      if (!_weekPageController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) => applySync());
        return;
      }

      final visiblePage =
          _weekPageController.page?.round() ??
          _currentPage ??
          _weekPageController.initialPage;
      final currentPage = visiblePage;
      if (currentPage == targetPage) {
        _currentPage = targetPage;
        return;
      }

      _startOverlayTransition(fromPage: currentPage, toPage: targetPage);
      _lastProgrammaticPage = targetPage;
      if (_timelineScrollOffset != 0) {
        setState(() {
          _timelineScrollOffset = 0;
        });
      }
      _weekPageController.jumpToPage(targetPage);
      _currentPage = targetPage;
    }

    applySync();
  }

  void _handlePageChanged(int index) {
    _currentPage = index;
    if (_timelineScrollOffset != 0) {
      setState(() {
        _timelineScrollOffset = 0;
      });
    }

    if (_lastProgrammaticPage == index) {
      _lastProgrammaticPage = null;
      return;
    }

    final monday = mondayForPageIndex(index);
    final selected = ref.read(selectedDayProvider);
    final newDay = AppDateTime.sameWeekdayInWeekOf(
      weekReference: monday,
      weekdaySource: selected,
    );
    ref.read(selectedDayProvider.notifier).update(newDay, haptic: false);
    ref.read(focusedDayProvider.notifier).update(newDay);
  }
}

/// Gleiche Grundcharakteristik wie in [EventList], auf großen Screens etwas
/// weicher skaliert, weil ein ganzer Wochenraster mehr Strecke zurücklegt.
class _SnappyPageViewPhysics extends ScrollPhysics {
  const _SnappyPageViewPhysics({required this.widthFactor, super.parent});

  final double widthFactor;

  @override
  _SnappyPageViewPhysics applyTo(ScrollPhysics? ancestor) =>
      _SnappyPageViewPhysics(
        widthFactor: widthFactor,
        parent: buildParent(ancestor),
      );

  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(
    mass: 0.48 + 0.12 * widthFactor,
    stiffness: 175.0 - 28.0 * widthFactor,
    ratio: 0.98,
  );
}

class _WeekTransitionData {
  const _WeekTransitionData({
    required this.fromMonday,
    required this.toMonday,
    required this.isForward,
  });

  final DateTime fromMonday;
  final DateTime toMonday;
  final bool isForward;
}
