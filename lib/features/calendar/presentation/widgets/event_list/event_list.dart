import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/calendar_providers.dart';
import 'day_page.dart';
import 'event_list_navigation_logic.dart';
import 'event_list_page_transition.dart';

class EventList extends ConsumerStatefulWidget {
  const EventList({super.key});

  @override
  ConsumerState<EventList> createState() => _EventListState();
}

class _EventListState extends ConsumerState<EventList>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int? _currentIndex;
  late final DateTime _startDate;
  late final EventListNavigationLogic _navigationLogic;
  late final AnimationController _transitionController;
  _TransitionData? _activeTransition;

  void _startOverlayTransition({
    required int fromIndex,
    required int toIndex,
  }) {
    final transition = _TransitionData(
      fromDate: _navigationLogic.dateFromIndex(fromIndex),
      toDate: _navigationLogic.dateFromIndex(toIndex),
      isForward: _navigationLogic.isForward(fromIndex, toIndex),
    );

    setState(() {
      _activeTransition = transition;
    });

    _transitionController.forward(from: 0).whenComplete(() {
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
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    _startDate = normalizedToday.subtract(const Duration(days: 500));
    _navigationLogic = EventListNavigationLogic(startDate: _startDate);
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: EventListNavigationLogic.transitionDurationMs,
      ),
    );

    final initialDay = _navigationLogic.normalize(ref.read(selectedDayProvider));
    final initialIndex = _navigationLogic.indexFromDate(initialDay);
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
      final targetIndex = _navigationLogic.indexFromDate(next);
      final currentIndex = _currentIndex;

      if (!_pageController.hasClients ||
          !_navigationLogic.shouldNavigate(currentIndex, targetIndex)) {
        return;
      }

      if (currentIndex != null) {
        _startOverlayTransition(fromIndex: currentIndex, toIndex: targetIndex);
      }

      // Logik bleibt sofortig/sprungbasiert, Animation läuft entkoppelt als Overlay.
      _pageController.jumpToPage(targetIndex);
      _currentIndex = targetIndex;
    });

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            _currentIndex = index;
            final newDate = _navigationLogic.dateFromIndex(index);
            if (_navigationLogic.normalize(ref.read(selectedDayProvider)) !=
                newDate) {
              ref.read(selectedDayProvider.notifier).update(newDate);
            }
          },
          itemBuilder: (context, index) {
            final dateForPage = _navigationLogic.dateFromIndex(index);
            return DayPage(date: dateForPage);
          },
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
