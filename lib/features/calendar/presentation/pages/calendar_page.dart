import 'dart:async';

import 'package:chronoapp/core/widgets/main_navigation_bar.dart';
import 'package:chronoapp/features/calendar/presentation/pages/calendar_search_page.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_view_options.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_header/calendar_filter_bottom_sheet.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_week_layout_tokens.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/event_list.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronoapp/features/settings/presentation/providers/settings_profile_providers.dart';

import '../widgets/calendar_header/calendar_header.dart';
import '../widgets/calendar_header/calendar_search_overlay.dart';
import '../widgets/calendar_header/calendar_view_mode_overlay.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  static const Duration _searchDebounce = Duration(milliseconds: 300);
  static const Duration _viewModeTransitionDuration = Duration(
    milliseconds: 420,
  );
  static const Curve _viewModeTransitionCurve = Cubic(0.2, 0.8, 0.2, 1);

  bool _isSearchOpen = false;
  bool _isViewModeOverlayOpen = false;
  Timer? _debounceTimer;
  String _debouncedSearchQuery = '';

  void _openSearch() {
    setState(() {
      _isSearchOpen = true;
      _isViewModeOverlayOpen = false;
    });
  }

  void _openViewModeOverlay() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isViewModeOverlayOpen = true;
    });
  }

  void _closeViewModeOverlay() {
    setState(() {
      _isViewModeOverlayOpen = false;
    });
  }

  Future<void> _openCalendarFilters() async {
    HapticFeedback.heavyImpact();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const CalendarFilterBottomSheet(
        mode: CalendarFilterBottomSheetMode.calendarSettings,
      ),
    );
  }

  Future<void> _openSearchFilters() async {
    HapticFeedback.heavyImpact();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const CalendarFilterBottomSheet(
        mode: CalendarFilterBottomSheetMode.searchFilter,
      ),
    );
  }

  void _closeSearch() {
    _debounceTimer?.cancel();
    ref.read(searchFiltersProvider.notifier).resetToDefaults();
    setState(() {
      _isSearchOpen = false;
      _debouncedSearchQuery = '';
    });
  }

  void _onSearchQueryChanged(String nextQuery) {
    final trimmedQuery = nextQuery.trim();
    _debounceTimer?.cancel();

    if (trimmedQuery.isEmpty) {
      setState(() {
        _debouncedSearchQuery = '';
      });
      return;
    }

    _debounceTimer = Timer(_searchDebounce, () {
      if (!mounted) return;
      setState(() {
        _debouncedSearchQuery = trimmedQuery;
      });
    });
  }

  void _onCalendarViewModeChanged(CalendarViewMode nextMode) {
    final selectedDay = ref.read(selectedDayProvider);
    final focusedDay = ref.read(focusedDayProvider);

    if (nextMode == CalendarViewMode.week) {
      ref.read(focusedDayProvider.notifier).update(selectedDay);
    } else {
      ref.read(selectedDayProvider.notifier).update(focusedDay);
    }

    ref.read(calendarViewModeProvider.notifier).update(nextMode);
    setState(() {
      _isViewModeOverlayOpen = false;
    });
  }

  Widget _buildCalendarBody({required CalendarViewMode viewMode}) {
    final isWeekView = viewMode == CalendarViewMode.week;

    return AnimatedSwitcher(
      duration: _viewModeTransitionDuration,
      reverseDuration: _viewModeTransitionDuration,
      switchInCurve: _viewModeTransitionCurve,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[...previousChildren, ?currentChild],
        );
      },
      transitionBuilder: (child, animation) {
        final key = child.key;
        final targetMode = key is ValueKey<CalendarViewMode> ? key.value : null;
        final isWeekTarget = targetMode == CalendarViewMode.week;
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: _viewModeTransitionCurve,
          reverseCurve: Curves.easeInCubic,
        );
        final slideBegin = isWeekTarget
            ? const Offset(0.11, 0.012)
            : const Offset(-0.09, 0.012);
        final slideOvershoot = isWeekTarget
            ? const Offset(-0.012, 0)
            : const Offset(0.012, 0);
        final slideAnimation = TweenSequence<Offset>([
          TweenSequenceItem(
            tween: Tween<Offset>(
              begin: slideBegin,
              end: slideOvershoot,
            ).chain(CurveTween(curve: Curves.easeOutCubic)),
            weight: 78,
          ),
          TweenSequenceItem(
            tween: Tween<Offset>(
              begin: slideOvershoot,
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 22,
          ),
        ]).animate(curvedAnimation);
        final scaleAnimation = TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(
              begin: isWeekTarget ? 0.965 : 1.018,
              end: isWeekTarget ? 1.004 : 0.996,
            ).chain(CurveTween(curve: Curves.easeOutCubic)),
            weight: 74,
          ),
          TweenSequenceItem(
            tween: Tween<double>(
              begin: isWeekTarget ? 1.004 : 0.996,
              end: 1,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 26,
          ),
        ]).animate(curvedAnimation);

        return FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1)
              .chain(CurveTween(curve: const Interval(0.08, 1)))
              .animate(animation),
          child: SlideTransition(
            position: slideAnimation,
            child: ScaleTransition(scale: scaleAnimation, child: child),
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<CalendarViewMode>(viewMode),
        child: isWeekView ? const WeekScheduleView() : const EventList(),
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(syncedProfileProvider, (_, next) {
      next.whenData((profile) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          ref
              .read(calendarFiltersProvider.notifier)
              .initializeFromProfile(profile);
        });
      });
    });
    ref.listen<CalendarFiltersState>(calendarFiltersProvider, (_, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ref.read(searchFiltersProvider.notifier).initializeFromCalendar(next);
      });
    });
    final searchFilters = ref.watch(searchFiltersProvider);
    final hasVisibleSearchFilterChips = searchFilters.hasVisibleDeviationChips;
    final showSearchResults =
        _isSearchOpen ||
        _debouncedSearchQuery.isNotEmpty ||
        searchFilters.hasUserOverrides;
    final viewMode = ref.watch(calendarViewModeProvider);
    final mediaPadding = MediaQuery.paddingOf(context);
    // Muss zur kompakten Hoehe in CalendarSearchOverlay passen.
    const searchOverlayTopPadding = 8.0;
    const searchInputRowHeight = 42.0;
    const searchInputToChipsGap = 8.0;
    const chipRowExtent = 38.0;
    const searchOverlayBottomPadding = 4.0;
    final searchBarBottomInset =
        mediaPadding.top +
        searchOverlayTopPadding +
        searchInputRowHeight +
        searchInputToChipsGap +
        (_isSearchOpen && hasVisibleSearchFilterChips ? chipRowExtent : 0) +
        searchOverlayBottomPadding;

    return Scaffold(
      bottomNavigationBar: Stack(
        children: [
          MainNavigationBar(),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_isViewModeOverlayOpen,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutCubic,
                opacity: _isViewModeOverlayOpen ? 1 : 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _closeViewModeOverlay,
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.18),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isTabletCalendar =
                    constraints.maxWidth >= kCalendarTabletBreakpoint;
                final isWeekView = viewMode == CalendarViewMode.week;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (!showSearchResults) ...[
                      CalendarHeader(
                        weekTimetableMode: isWeekView,
                        viewMode: viewMode,
                        viewOptions: calendarViewOptions,
                        onViewModeChanged: _onCalendarViewModeChanged,
                        onViewMenuPressed: _openViewModeOverlay,
                        showCenteredViewControl: isTabletCalendar,
                        onSearchPressed: _openSearch,
                        onFilterPressed: _openCalendarFilters,
                      ),
                      Expanded(child: _buildCalendarBody(viewMode: viewMode)),
                    ] else ...[
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: searchBarBottomInset),
                          child: CalendarSearchPage(
                            query: _debouncedSearchQuery,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          CalendarViewModeOverlay(
            isOpen: _isViewModeOverlayOpen,
            options: calendarViewOptions,
            selectedMode: viewMode,
            onClose: _closeViewModeOverlay,
            onSelected: _onCalendarViewModeChanged,
          ),
          CalendarSearchOverlay(
            isOpen: _isSearchOpen,
            onClose: _closeSearch,
            onQueryChanged: _onSearchQueryChanged,
            onFilterPressed: _openSearchFilters,
          ),
        ],
      ),
    );
  }
}
