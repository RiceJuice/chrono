import 'dart:async';

import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:chronoapp/features/calendar/live_activity/presentation/schedule_live_activity_deep_link_pending.dart';
import 'package:chronoapp/features/calendar/live_activity/presentation/schedule_live_activity_open_request_provider.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/base_bottom_modal.dart';
import 'package:chronoapp/features/calendar/data/calendar_signed_url_cache.dart';
import 'package:chronoapp/features/calendar/event_editor/presentation/pages/calendar_event_form_page.dart';
import 'package:chronoapp/features/calendar/event_editor/presentation/providers/is_admin_provider.dart';
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
import '../widgets/calendar_header/calendar_view_mode_overlay.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage>
    with WidgetsBindingObserver {
  static const Duration _viewModeTransitionDuration = Duration(
    milliseconds: 300,
  );
  static const Curve _viewModeTransitionCurve = Cubic(0.2, 0.8, 0.2, 1);

  /// Letzter bekannter Landscape-Zustand — nur um beim Eintreten ins Querformat
  /// den Fokus auf den Montag zu setzen.
  bool? _prevIsPhoneLandscape;

  void _restoreNonImmersiveSystemUi() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  void _syncCalendarLandscapeImmersive() {
    if (!mounted) return;
    if (calendarUsePhoneLandscapeChrome(context)) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      _restoreNonImmersiveSystemUi();
    }
  }

  void _openViewModeOverlay() {
    HapticFeedback.mediumImpact();
    ref.read(calendarViewModeOverlayOpenProvider.notifier).set(isOpen: true);
  }

  void _closeViewModeOverlay() {
    ref.read(calendarViewModeOverlayOpenProvider.notifier).set(isOpen: false);
  }

  Future<void> _openCalendarFilters() async {
    HapticFeedback.heavyImpact();
    await AppModalSheet.show<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const CalendarFilterBottomSheet(
        mode: CalendarFilterBottomSheetMode.calendarSettings,
      ),
    );
  }

  Future<void> _openCreateEventSheet() async {
    if (AppModalSheetTracker.depth.value > 0) return;
    AppHaptics.light();
    final day = ref.read(selectedDayProvider);
    await CalendarEventFormPage.showCreate(context, initialDay: day);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(CalendarSignedUrlCache.shared.ensureLoaded());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumePendingScheduleDeepLink();
    });
  }

  void _consumePendingScheduleDeepLink() {
    if (!mounted) return;
    final pending = ScheduleLiveActivityDeepLinkPending.consume();
    if (pending == null || pending.isEmpty) return;
    ref.read(scheduleLiveActivityOpenRequestProvider.notifier).open(pending);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncCalendarLandscapeImmersive();
  }

  @override
  void didChangeMetrics() {
    _syncCalendarLandscapeImmersive();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncCalendarLandscapeImmersive();
    }
  }

  void _onCalendarViewModeChanged(CalendarViewMode nextMode) {
    final selectedDay = ref.read(selectedDayProvider);
    final focusedDay = ref.read(focusedDayProvider);

    if (nextMode == CalendarViewMode.week) {
      ref
          .read(focusedDayProvider.notifier)
          .update(AppDateTime.localMondayOfWeek(selectedDay));
    } else {
      ref.read(selectedDayProvider.notifier).update(focusedDay);
    }

    ref.read(calendarViewModeProvider.notifier).update(nextMode);
    ref.read(calendarViewModeOverlayOpenProvider.notifier).set(isOpen: false);
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
          fit: StackFit.expand,
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
            ? const Offset(0, 0.078)
            : const Offset(0, -0.078);
        final slideOvershoot = isWeekTarget
            ? const Offset(0, -0.016)
            : const Offset(0, 0.016);
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
              .chain(CurveTween(curve: const Interval(0.0, 0.38)))
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

  Widget _buildCalendarContent({
    required CalendarViewMode viewMode,
    required bool isTabletCalendar,
    required bool isAdmin,
  }) {
    final isWeekView = viewMode == CalendarViewMode.week;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        CalendarHeader(
          weekTimetableMode: isWeekView,
          viewMode: viewMode,
          viewOptions: calendarViewOptions,
          onViewModeChanged: _onCalendarViewModeChanged,
          onViewMenuPressed: _openViewModeOverlay,
          showCenteredViewControl: isTabletCalendar,
          onCreatePressed: isAdmin ? _openCreateEventSheet : null,
          onFilterPressed: _openCalendarFilters,
        ),
        Expanded(child: _buildCalendarBody(viewMode: viewMode)),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restoreNonImmersiveSystemUi();
    super.dispose();
  }

  Future<void> _openScheduleFromLiveActivity(String eventId) async {
    ref.read(scheduleLiveActivityOpenRequestProvider.notifier).clear();

    final entry = await ref.read(calendarRepositoryProvider).entryById(eventId);
    if (!mounted || entry == null) return;

    ref.read(selectedDayProvider.notifier).update(
          entry.startTime,
          haptic: false,
          origin: CalendarDaySelectionOrigin.external,
        );

    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    if (AppModalSheetTracker.depth.value > 0) return;

    await BaseBottomModal.show(context, entry: entry);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(scheduleLiveActivityOpenRequestProvider, (prev, next) {
      if (next == null || next.isEmpty) return;
      unawaited(_openScheduleFromLiveActivity(next));
    });
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

    final isAdmin = ref.watch(isAdminProvider);
    final storedViewMode = ref.watch(calendarViewModeProvider);
    final usePhoneLandscapeChrome = calendarUsePhoneLandscapeChrome(context);
    final viewMode =
        usePhoneLandscapeChrome ? CalendarViewMode.week : storedViewMode;

    if (usePhoneLandscapeChrome && _prevIsPhoneLandscape == false) {
      _prevIsPhoneLandscape = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final selectedDay = ref.read(selectedDayProvider);
        ref
            .read(focusedDayProvider.notifier)
            .update(AppDateTime.localMondayOfWeek(selectedDay));
      });
    } else if (!usePhoneLandscapeChrome && _prevIsPhoneLandscape == true) {
      _prevIsPhoneLandscape = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final stored = ref.read(calendarViewModeProvider);
        if (stored != CalendarViewMode.week) {
          final focusedDay = ref.read(focusedDayProvider);
          ref.read(selectedDayProvider.notifier).update(focusedDay);
        }
      });
    } else {
      _prevIsPhoneLandscape = usePhoneLandscapeChrome;
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
                return const SizedBox.shrink();
              }
              final isTabletCalendar = calendarIsTabletLayout(context);
              return SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: _buildCalendarContent(
                  viewMode: viewMode,
                  isTabletCalendar: isTabletCalendar,
                  isAdmin: isAdmin,
                ),
              );
            },
          ),
          CalendarViewModeOverlay(
            isOpen: ref.watch(calendarViewModeOverlayOpenProvider),
            options: calendarViewOptions,
            selectedMode: viewMode,
            onClose: _closeViewModeOverlay,
            onSelected: _onCalendarViewModeChanged,
          ),
        ],
      ),
    );
  }
}
