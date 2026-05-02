import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_week_layout_tokens.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_grid.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_layout.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_navigation.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_page_transition.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_timeline.dart';
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
  AnimationController? _transitionController;
  int? _currentPage;
  int? _lastProgrammaticPage;
  _WeekTransitionData? _activeTransition;
  double _timelineScrollOffset = 0;
  static const double _scrollVelocityBlend = 0.22;
  double _horizontalVelocityEma = 0;
  int? _lastVelocitySampleWallMicros;
  double _peakAbsNormVelocity = 0;
  double _latchedNormVelocity = 0;
  DateTime? _latchedVelocityValidUntil;

  @override
  void initState() {
    super.initState();
    final monday = weekMondayLocal(ref.read(focusedDayProvider));
    final initialPage = pageIndexForMonday(monday);
    _weekPageController = PageController(initialPage: initialPage);
    _ensureTransitionController();
    _currentPage = initialPage;
  }

  @override
  void dispose() {
    _transitionController?.dispose();
    _weekPageController.dispose();
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

  double _lerpDouble(double begin, double end, double t) {
    return begin + (end - begin) * t;
  }

  SpringDescription _overlaySpringForViewport() {
    final widthFactor = _viewportWidthFactor();
    return SpringDescription(
      mass: _lerpDouble(0.85, 1.12, widthFactor),
      stiffness: _lerpDouble(430, 305, widthFactor),
      damping: _lerpDouble(34, 39, widthFactor),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DateTime>(focusedDayProvider, _syncPageToFocusedWeek);

    return Stack(
      children: [
        Positioned.fill(
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleScheduleScrollNotification,
            child: Padding(
              padding: const EdgeInsets.only(
                left: kCalendarTimelineGutterWidth,
              ),
              child: PageView.builder(
                controller: _weekPageController,
                physics:
                    _SnappyPageViewPhysics(
                      widthFactor: _viewportWidthFactor(),
                    ).applyTo(
                      ScrollConfiguration.of(context).getScrollPhysics(context),
                    ),
                itemCount: kWeekPageCount,
                onPageChanged: _handlePageChanged,
                itemBuilder: (context, pageIndex) {
                  return WeekScheduleGrid(
                    monday: mondayForPageIndex(pageIndex),
                    showTimelineColumn: false,
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
    final monday = weekMondayLocal(ref.watch(focusedDayProvider));
    final weekDays = List<DateTime>.generate(
      7,
      (index) => monday.add(Duration(days: index)),
    );
    final asyncDays = weekDays
        .map((day) => ref.watch(filteredCalendarEntriesForDayProvider(day)))
        .toList(growable: false);

    if (asyncDays.any((day) => day.isLoading || day.hasError)) {
      return const SizedBox.shrink();
    }

    final entriesByDay = asyncDays
        .map((asyncDay) => asyncDay.requireValue)
        .toList(growable: false);
    final bounds = computeWeekScheduleBounds(entriesByDay);
    if (bounds == null) return const SizedBox.shrink();

    final totalHeight = bounds.heightForHourHeight(kWeekScheduleHourHeight);
    final showCurrentTime = weekDays.any(AppDateTime.isTodayLocal);

    return ClipRect(
      child: Transform.translate(
        offset: Offset(0, -_timelineScrollOffset),
        child: WeekTimelineColumn(
          bounds: bounds,
          totalHeight: totalHeight,
          showCurrentTime: showCurrentTime,
        ),
      ),
    );
  }

  bool _handleScheduleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.horizontal) {
      _handlePageViewScrollNotification(notification);
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

  void _handlePageViewScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _horizontalVelocityEma = 0;
      _lastVelocitySampleWallMicros = null;
      _peakAbsNormVelocity = 0;
    }

    if (notification is ScrollUpdateNotification &&
        notification.scrollDelta != null) {
      final nowMicros = DateTime.now().microsecondsSinceEpoch;
      if (_lastVelocitySampleWallMicros != null) {
        final dtMicros = nowMicros - _lastVelocitySampleWallMicros!;
        if (dtMicros > 0) {
          final dt = dtMicros / Duration.microsecondsPerSecond;
          if (dt > 1e-6) {
            final sample = notification.scrollDelta! / dt;
            _horizontalVelocityEma =
                _horizontalVelocityEma * (1 - _scrollVelocityBlend) +
                sample * _scrollVelocityBlend;
          }
        }
      }
      _lastVelocitySampleWallMicros = nowMicros;
      if (_weekPageController.hasClients) {
        final extent = _weekPageController.position.viewportDimension;
        if (extent > 0) {
          final norm = (_horizontalVelocityEma / extent).abs();
          if (norm > _peakAbsNormVelocity) {
            _peakAbsNormVelocity = norm;
          }
        }
      }
    }

    if (notification is ScrollEndNotification) {
      final sign = _horizontalVelocityEma >= 0 ? 1.0 : -1.0;
      _latchedNormVelocity = (sign * _peakAbsNormVelocity).clamp(-14.0, 14.0);
      _latchedVelocityValidUntil = DateTime.now().add(
        const Duration(milliseconds: 240),
      );
      _horizontalVelocityEma = 0;
      _lastVelocitySampleWallMicros = null;
      _peakAbsNormVelocity = 0;
    }
  }

  double _consumePageViewVelocityForTransition() {
    if (_latchedVelocityValidUntil == null ||
        DateTime.now().isAfter(_latchedVelocityValidUntil!)) {
      return 0;
    }
    final v = _latchedNormVelocity;
    _latchedVelocityValidUntil = null;
    _latchedNormVelocity = 0;
    return v;
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

    final swipeSpeed = _consumePageViewVelocityForTransition().abs();
    final pageDelta = (toPage - fromPage).abs();
    final widthFactor = _viewportWidthFactor();
    final velocityScale = _lerpDouble(1, 0.62, widthFactor);
    final simulationVelocity = swipeSpeed > 0
        ? (swipeSpeed * velocityScale).clamp(
            _lerpDouble(1.2, 0.85, widthFactor),
            _lerpDouble(8.0, 5.0, widthFactor),
          )
        : ((1.1 + pageDelta * 0.22) * velocityScale).clamp(
            _lerpDouble(1.1, 0.78, widthFactor),
            _lerpDouble(3.8, 2.55, widthFactor),
          );

    final transitionController = _ensureTransitionController();
    transitionController.stop();
    transitionController.value = 0;
    final simulation = SpringSimulation(
      _overlaySpringForViewport(),
      0,
      1,
      simulationVelocity,
      tolerance: const Tolerance(velocity: 1 / 1000, distance: 1 / 1000),
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
    final targetPage = pageIndexForMonday(weekMondayLocal(next));
    if (!_weekPageController.hasClients) return;

    final currentPage =
        _currentPage ??
        _weekPageController.page?.round() ??
        _weekPageController.initialPage;
    if (currentPage == targetPage) return;

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

    ref.read(focusedDayProvider.notifier).update(mondayForPageIndex(index));
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
    mass: 0.30 + 0.12 * widthFactor,
    stiffness: 270.0 - 60.0 * widthFactor,
    ratio: 1.07 - 0.07 * widthFactor,
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
