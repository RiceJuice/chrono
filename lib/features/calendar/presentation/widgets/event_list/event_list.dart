import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/core/time/local_calendar_index.dart';
import '../../providers/calendar_providers.dart';
import 'day_page.dart';
import 'event_list_page_transition.dart';

/// Feste Gesamthöhe des farbigen Headers im Termin-Bottom-Sheet (ohne Skalierung).
/// Die Vorschau nutzt dieselben [CalendarEntryCard]-Widgets wie [DayPage] / diese Liste.
const double kBottomModalHeaderHeight = 200;

class EventList extends ConsumerStatefulWidget {
  const EventList({super.key});

  @override
  ConsumerState<EventList> createState() => _EventListState();
}

class _EventListState extends ConsumerState<EventList>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int? _currentIndex;
  late final LocalCalendarIndex _dayIndex;
  late final AnimationController _transitionController;
  _TransitionData? _activeTransition;
  int? _pendingProgrammaticPage;

  static const double _scrollVelocityBlend = 0.22;
  double _horizontalVelocityEma = 0;
  int? _lastVelocitySampleWallMicros;
  double _peakAbsNormVelocity = 0;
  double _latchedNormVelocity = 0;
  DateTime? _latchedVelocityValidUntil;
  bool _onPageViewScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.horizontal) return false;

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
      if (_pageController.hasClients) {
        final extent = _pageController.position.viewportDimension;
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

    return false;
  }

  /// Zuletzt gemessene horizontale Wisch-Geschwindigkeit (Seiten/s), einmalig gültig.
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

  void _startOverlayTransition({required int fromIndex, required int toIndex}) {
    final transition = _TransitionData(
      fromDate: _dayIndex.dayAt(fromIndex),
      toDate: _dayIndex.dayAt(toIndex),
      isForward: toIndex > fromIndex,
    );

    setState(() {
      _activeTransition = transition;
    });

    final swipeSpeed = _consumePageViewVelocityForTransition().abs();
    final pageDelta = (toIndex - fromIndex).abs();
    final simulationVelocity = DayContentTransitionPhysics.simulationVelocityFor(
      pageDelta: pageDelta,
      swipeSpeed: swipeSpeed,
    );

    _transitionController.stop();
    _transitionController.value = 0;
    final simulation = SpringSimulation(
      DayContentTransitionPhysics.spring,
      0,
      1,
      simulationVelocity,
      tolerance: DayContentTransitionPhysics.tolerance,
    );

    _transitionController.animateWith(simulation).whenComplete(() {
      if (!mounted) return;
      if (_activeTransition == transition) {
        setState(() {
          _activeTransition = null;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final normalizedToday = AppDateTime.todayLocal();
    _dayIndex = LocalCalendarIndex(
      AppDateTime.addLocalCalendarDays(normalizedToday, -500),
    );
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    final initialDay = _dayIndex.normalize(ref.read(selectedDayProvider));
    final initialIndex = _dayIndex.indexOf(initialDay);
    _currentIndex = initialIndex;
    _pageController = PageController(initialPage: initialIndex);
  }

  @override
  void dispose() {
    _transitionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DateTime>(selectedDayProvider, (previous, next) {
      final targetIndex = _dayIndex.indexOf(next);
      final currentIndex = _currentIndex;

      if (!_pageController.hasClients || currentIndex == targetIndex) {
        return;
      }

      if (currentIndex != null) {
        _startOverlayTransition(fromIndex: currentIndex, toIndex: targetIndex);
      }

      // Logik bleibt sofortig/sprungbasiert, Animation läuft entkoppelt als Overlay.
      _pendingProgrammaticPage = targetIndex;
      _pageController.jumpToPage(targetIndex);
      _currentIndex = targetIndex;
    });

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _onPageViewScrollNotification,
          child: PageView.builder(
            controller: _pageController,
            physics: _SnappyPageViewPhysics().applyTo(
              ScrollConfiguration.of(context).getScrollPhysics(context),
            ),
            onPageChanged: (index) {
              _currentIndex = index;
              final newDate = _dayIndex.dayAt(index);
              if (_pendingProgrammaticPage != null &&
                  _pendingProgrammaticPage == index) {
                _pendingProgrammaticPage = null;
                return;
              }
              _pendingProgrammaticPage = null;
              if (_dayIndex.normalize(ref.read(selectedDayProvider)) != newDate) {
                ref.read(selectedDayProvider.notifier).update(newDate);
              }
            },
            itemBuilder: (context, index) {
              final dateForPage = _dayIndex.dayAt(index);
              return DayPage(
                key: ValueKey<DateTime>(dateForPage),
                date: dateForPage,
              );
            },
          ),
        ),
        if (_activeTransition != null)
          Positioned.fill(
            child: EventListPageTransition(
              fromDate: _activeTransition!.fromDate,
              toDate: _activeTransition!.toDate,
              isForward: _activeTransition!.isForward,
              animation: _transitionController,
            ),
          ),
      ],
    );
  }
}

/// Steifere Feder als Standard-[PageScrollPhysics]: Seite schneller zur Ruhe,
/// weniger „Nachgleiten“ nach dem Loslassen (das ist nicht die Overlay-Kurve).
class _SnappyPageViewPhysics extends ScrollPhysics {
  const _SnappyPageViewPhysics({super.parent});

  @override
  _SnappyPageViewPhysics applyTo(ScrollPhysics? ancestor) =>
      _SnappyPageViewPhysics(parent: buildParent(ancestor));

  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(
    mass: 0.48,
    stiffness: 175.0,
    ratio: 0.98,
  );
}

class _TransitionData {
  const _TransitionData({
    required this.fromDate,
    required this.toDate,
    required this.isForward,
  });

  final DateTime fromDate;
  final DateTime toDate;
  final bool isForward;
}
