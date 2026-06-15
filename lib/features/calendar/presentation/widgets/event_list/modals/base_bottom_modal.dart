import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/core/widgets/app_modal_scroll_surface.dart';
import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:chronoapp/core/widgets/app_smooth_event_modal_sheet.dart';
import 'package:chronoapp/core/widgets/event_modal_sheet_physics.dart';
import 'package:chronoapp/core/widgets/event_schedule_scroll_coordinator.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/domain/preview/calendar_appearance_config.dart';
import 'package:chronoapp/features/calendar/domain/preview/calendar_settings_kind.dart';
import 'package:chronoapp/features/calendar/event_editor/presentation/widgets/admin_edit_button.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:chronoapp/features/calendar/presentation/providers/event_schedules_providers.dart';
import 'package:chronoapp/features/calendar/presentation/providers/subjects_providers.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/calendar_now_anchor.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_header/calendar_appearance_bottom_sheet.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_header/calendar_appearance_subject_panel.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/event_list.dart'
    show kBottomModalHeaderHeight;
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/types/chor_bottom_modal.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/types/event_bottom_modal.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/types/lesson_bottom_modal.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/types/meal_bottom_modal.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/bottom_modal_header.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/bottom_modal_top_blur_fade.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/lesson_accent_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:chronoapp/core/widgets/app_modal_sheet.dart' show kAppModalSheetMotion;

/// Alias für bestehende Importe im Kalender-Feature.
const AnimationStyle kCalendarBottomSheetMotion = kAppModalSheetMotion;

class BaseBottomModal extends ConsumerStatefulWidget {
  final CalendarEntry entry;

  const BaseBottomModal({super.key, required this.entry});

  static bool isEventSheetType(CalendarEntryType type) =>
      type == CalendarEntryType.event || type == CalendarEntryType.breakType;

  static Future<T?> show<T>(
    BuildContext context, {
    required CalendarEntry entry,
    double? minHeight,
  }) {
    if (isEventSheetType(entry.type)) {
      return AppSmoothModalSheet.show<T>(
        context: context,
        builder: (_) => BaseBottomModal(entry: entry),
      );
    }
    return AppModalSheet.show<T>(
      context: context,
      useSafeArea: false,
      builder: (_) => BaseBottomModal(entry: entry),
    );
  }

  @override
  ConsumerState<BaseBottomModal> createState() => _BaseBottomModalState();
}

class _BaseBottomModalState extends ConsumerState<BaseBottomModal>
    with SingleTickerProviderStateMixin {
  static const Duration _morphDuration = Duration(milliseconds: 540);

  late final AnimationController _morphController;
  late final Animation<double> _morph;
  bool _appearanceActive = false;
  CalendarAppearanceBySubject? _subjectAppearance;
  final GlobalKey<CalendarAppearanceSubjectPanelState> _subjectPanelKey =
      GlobalKey();
  final EventScheduleScrollCoordinator _scheduleScrollCoordinator =
      EventScheduleScrollCoordinator();

  CalendarEntry get _liveEntry {
    final anchor = widget.entry;
    final anchorDay = AppDateTime.localDay(anchor.startTime);
    final dayEntries =
        ref.watch(calendarEntriesForDayProvider(anchorDay)).asData?.value;
    if (dayEntries != null) {
      for (final entry in dayEntries) {
        if (entry.id == anchor.id) return entry;
      }
    }

    final allEntries = ref.watch(calendarAllEntriesProvider).asData?.value;
    if (allEntries != null) {
      for (final entry in allEntries) {
        if (entry.id == anchor.id) return entry;
      }
    }

    return anchor;
  }

  bool get _supportsAccentMorph =>
      _liveEntry.type == CalendarEntryType.lesson &&
      _liveEntry.subjectId != null;

  bool _eventSheetStartsExpanded(CalendarEntry entry) {
    if (!BaseBottomModal.isEventSheetType(entry.type)) return false;

    final schedulesAsync = ref.watch(eventSchedulesForEntryProvider(entry.id));
    return schedulesAsync.when(
      data: (schedules) =>
          schedules.isNotEmpty &&
          CalendarNowAnchor.scheduleHasStarted(schedules),
      loading: () =>
          AppDateTime.isTodayLocal(entry.startTime) &&
          AppDateTime.isPastInstant(entry.startTime),
      error: (_, _) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    _morphController = AnimationController(
      vsync: this,
      duration: _morphDuration,
    );
    _morph = CurvedAnimation(
      parent: _morphController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _morphController.dispose();
    super.dispose();
  }

  CalendarEntry get _displayEntry {
    final entry = _liveEntry;
    final subjectId = entry.subjectId;
    if (subjectId == null) return entry;
    final overrides =
        ref.watch(subjectAccentOverridesProvider).value ??
        const <String, Color>{};
    final accent = overrides[subjectId] ?? entry.accentColor;
    return entry.copyWith(accentColor: accent);
  }

  void _onAccentPressed() {
    AppHaptics.light();
    final entry = _liveEntry;
    final subjectId = entry.subjectId;
    final config = subjectId != null
        ? CalendarAppearanceBySubject(
            subjectId: subjectId,
            previewEntry: entry,
          )
        : const CalendarAppearanceByKind(CalendarSettingsKind.school);

    if (!_supportsAccentMorph) {
      CalendarAppearanceBottomSheet.show(context, config: config);
      return;
    }

    setState(() {
      _appearanceActive = true;
      _subjectAppearance = config as CalendarAppearanceBySubject;
    });
    _morphController.forward();
  }

  Future<void> _closeAppearance({required bool discard}) async {
    if (discard) {
      await _subjectPanelKey.currentState?.discardChanges();
    } else {
      _subjectPanelKey.currentState?.confirmChanges();
    }
    await _morphController.reverse();
    if (!mounted) return;
    setState(() {
      _appearanceActive = false;
      _subjectAppearance = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _morph,
      builder: (context, _) => _buildSheet(context),
    );
  }

  Widget _buildSheet(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = _morph.value;
    final sheetSurface = Color.lerp(
      scheme.surface,
      scheme.surfaceContainerHigh,
      t,
    )!;

    final entryType = _liveEntry.type;
    final isEventSheet =
        !_supportsAccentMorph && BaseBottomModal.isEventSheetType(entryType);

    if (isEventSheet) {
      final entry = _liveEntry;
      final startsExpanded = _eventSheetStartsExpanded(entry);

      return AppSmoothEventModalSheet(
        color: sheetSurface,
        startExpanded: startsExpanded,
        builder: (context, scrollController, isFullyExpanded) {
          return _EventSheetAnchorScrollGate(
            isFullyExpanded: isFullyExpanded,
            scrollCoordinator: _scheduleScrollCoordinator,
            requiresExpandedViewport: startsExpanded,
            child: _buildEventSheetContent(
              morph: t,
              sheetSurface: sheetSurface,
              scrollController: scrollController,
              isFullyExpandedListenable: isFullyExpanded,
            ),
          );
        },
      );
    }

    return _buildSimpleDetailSheet(
      context: context,
      sheetSurface: sheetSurface,
      morph: t,
    );
  }

  /// Feste Höhe + innerer Scroll — kein Expand/Snap (Lesson, Meal, Choir).
  Widget _buildSimpleDetailSheet({
    required BuildContext context,
    required Color sheetSurface,
    required double morph,
  }) {
    final sheetHeight =
        MediaQuery.sizeOf(context).height * kAppDetailModalInitialSize;

    return SizedBox(
      height: sheetHeight,
      child: AppModalSheetChrome(
        color: sheetSurface,
        clipTopCorners: true,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SingleChildScrollView(
              child: _buildModalContent(morph),
            ),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: BottomModalHandle(),
            ),
            if (_supportsAccentMorph) ..._buildAccentChrome(context, morph),
            if (!_supportsAccentMorph &&
                _liveEntry.type == CalendarEntryType.lesson)
              Positioned(
                top: 6,
                right: 6,
                child: LessonAccentButton(
                  entry: _liveEntry,
                  onAccentPressed: _onAccentPressed,
                ),
              ),
            _buildAdminEditButtonPositioned(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventSheetContent({
    required double morph,
    required Color sheetSurface,
    required ScrollController scrollController,
    required ValueListenable<bool> isFullyExpandedListenable,
  }) {
    final entry = _liveEntry;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AppModalScrollSurface(
          controller: scrollController,
          child: EventModalScrollNearTopSnap(
            controller: scrollController,
            child: NotificationListener<UserScrollNotification>(
              onNotification: (notification) {
                if (notification.direction != ScrollDirection.idle) {
                  _scheduleScrollCoordinator.notifyUserScroll();
                }
                return false;
              },
              child: ScrollConfiguration(
                behavior: const EventModalScrollBehavior(),
                child: CustomScrollView(
                  controller: scrollController,
                  physics: eventBottomModalScrollPhysics(context),
                  cacheExtent: 480,
                  slivers: [
                    EventBottomModalSchedulePane(
                      eventId: entry.id,
                      entry: entry,
                      sliverLayout: true,
                      sheetScrollController: scrollController,
                      scrollCoordinator: _scheduleScrollCoordinator,
                      sheetSurfaceColor: sheetSurface,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: isFullyExpandedListenable,
          builder: (context, isFullyExpanded, _) {
            return Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: BottomModalScrollTopBlurOverlay(
                controller: scrollController,
                isFullyExpanded: isFullyExpanded,
                surfaceColor: sheetSurface,
              ),
            );
          },
        ),
        _buildAdminEditButtonPositioned(),
      ],
    );
  }

  Positioned _buildAdminEditButtonPositioned() {
    const inset = 6.0;
    const buttonSide = 44.0;
    final hasTopRightButton = _liveEntry.type == CalendarEntryType.lesson;
    final top = hasTopRightButton
        ? kBottomModalHeaderHeight - buttonSide - inset
        : inset;

    return Positioned(
      top: top,
      right: inset,
      child: AdminEditButton(entry: _liveEntry),
    );
  }

  List<Widget> _buildAccentChrome(BuildContext context, double t) {
    final scheme = Theme.of(context).colorScheme;
    final top = MediaQuery.viewPaddingOf(context).top + 6;
    final chromeOpacity = t.clamp(0.0, 1.0);
    final paletteOpacity = (1 - t).clamp(0.0, 1.0);

    return [
      Positioned(
        top: top,
        left: 6,
        child: IgnorePointer(
          ignoring: chromeOpacity < 0.5,
          child: Opacity(
            opacity: chromeOpacity,
            child: CalendarAppearanceSheetHeaderButton(
              icon: Icons.close,
              tooltip: 'Verwerfen',
              onPressed: () => _closeAppearance(discard: true),
              scheme: scheme,
            ),
          ),
        ),
      ),
      Positioned(
        top: top,
        right: 6,
        child: IgnorePointer(
          ignoring: chromeOpacity < 0.5,
          child: Opacity(
            opacity: chromeOpacity,
            child: CalendarAppearanceSheetHeaderButton(
              icon: Icons.check,
              tooltip: 'Fertig',
              onPressed: () => _closeAppearance(discard: false),
              scheme: scheme,
            ),
          ),
        ),
      ),
      Positioned(
        top: 6,
        right: 6,
        child: IgnorePointer(
          ignoring: paletteOpacity < 0.5,
          child: Opacity(
            opacity: paletteOpacity,
            child: LessonAccentButton(
              entry: _liveEntry,
              onAccentPressed: _onAccentPressed,
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildModalContent(double t) {
    if (_supportsAccentMorph) {
      return _buildLessonMorphContent(t);
    }
    return _buildModalContentByType();
  }

  Widget _buildLessonMorphContent(double t) {
    final textOpacity = (1 - Curves.easeOut.transform(t)).clamp(0.0, 1.0);
    final pickerOpacity = Curves.easeIn.transform(t).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BottomModalHeaderMorph(
          entry: _displayEntry,
          morph: _morph,
          clipTopCorners: false,
          showHandle: false,
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IgnorePointer(
              ignoring: textOpacity < 0.05,
              child: Opacity(
                opacity: textOpacity,
                child: LessonBottomModal(
                  entry: _liveEntry,
                  includeHeader: false,
                ),
              ),
            ),
            if (_appearanceActive && _subjectAppearance != null)
              IgnorePointer(
                ignoring: pickerOpacity < 0.05,
                child: Opacity(
                  opacity: pickerOpacity,
                  child: CalendarAppearanceSubjectPanel(
                    key: _subjectPanelKey,
                    config: _subjectAppearance!,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildModalContentByType() {
    final entry = _liveEntry;
    return switch (entry.type) {
      CalendarEntryType.lesson => LessonBottomModal(entry: entry),
      CalendarEntryType.meal => MealBottomModal(entry: entry),
      CalendarEntryType.event => EventBottomModalHeader(entry: entry),
      CalendarEntryType.breakType => EventBottomModalHeader(entry: entry),
      CalendarEntryType.choir => ChorBottomModal(entry: entry),
    };
  }
}

/// Meldet dem [EventScheduleScrollCoordinator], wenn das Sheet voll expandiert ist.
class _EventSheetAnchorScrollGate extends StatefulWidget {
  const _EventSheetAnchorScrollGate({
    required this.isFullyExpanded,
    required this.scrollCoordinator,
    required this.requiresExpandedViewport,
    required this.child,
  });

  final ValueListenable<bool> isFullyExpanded;
  final EventScheduleScrollCoordinator scrollCoordinator;
  final bool requiresExpandedViewport;
  final Widget child;

  @override
  State<_EventSheetAnchorScrollGate> createState() =>
      _EventSheetAnchorScrollGateState();
}

class _EventSheetAnchorScrollGateState extends State<_EventSheetAnchorScrollGate> {
  @override
  void initState() {
    super.initState();
    if (widget.requiresExpandedViewport) {
      widget.scrollCoordinator.requireExpandedViewportForAnchorScroll();
    }
    widget.isFullyExpanded.addListener(_onFullyExpandedChanged);
    _onFullyExpandedChanged();
  }

  @override
  void didUpdateWidget(covariant _EventSheetAnchorScrollGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFullyExpanded != widget.isFullyExpanded) {
      oldWidget.isFullyExpanded.removeListener(_onFullyExpandedChanged);
      widget.isFullyExpanded.addListener(_onFullyExpandedChanged);
      _onFullyExpandedChanged();
    }
    if (!oldWidget.requiresExpandedViewport && widget.requiresExpandedViewport) {
      widget.scrollCoordinator.requireExpandedViewportForAnchorScroll();
      _onFullyExpandedChanged();
    }
  }

  @override
  void dispose() {
    widget.isFullyExpanded.removeListener(_onFullyExpandedChanged);
    super.dispose();
  }

  void _onFullyExpandedChanged() {
    if (!widget.requiresExpandedViewport) return;
    if (!widget.isFullyExpanded.value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.scrollCoordinator.markAnchorScrollViewportReady();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
