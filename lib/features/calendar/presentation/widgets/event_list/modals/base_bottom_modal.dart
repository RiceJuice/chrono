import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/core/widgets/app_expandable_modal_sheet.dart';
import 'package:chronoapp/core/widgets/app_modal_scroll_surface.dart';
import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:chronoapp/core/widgets/app_smooth_event_modal_sheet.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/domain/preview/calendar_appearance_config.dart';
import 'package:chronoapp/features/calendar/domain/preview/calendar_settings_kind.dart';
import 'package:chronoapp/features/calendar/event_editor/presentation/widgets/admin_edit_button.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:chronoapp/features/calendar/presentation/providers/subjects_providers.dart';
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
import 'package:flutter/material.dart';
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
      return AppSmoothEventModalSheet(
        color: sheetSurface,
        builder: (context, scrollController, isFullyExpanded) {
          return _buildEventSheetContent(
            morph: t,
            sheetSurface: sheetSurface,
            scrollController: scrollController,
            isFullyExpanded: isFullyExpanded,
          );
        },
      );
    }

    final initialSize = BaseBottomModal.isEventSheetType(entryType)
        ? kAppExpandableModalEventInitialSize
        : kAppExpandableModalInitialSize;

    return AppExpandableModalSheet(
      color: sheetSurface,
      initialChildSize: initialSize,
      builder: (context, scrollController, maxSheetHeight, isFullyExpanded) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(child: _buildModalContent(t)),
              ],
            ),
            if (_supportsAccentMorph) ..._buildAccentChrome(context, t),
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
        );
      },
    );
  }

  Widget _buildEventSheetContent({
    required double morph,
    required Color sheetSurface,
    required ScrollController scrollController,
    required bool isFullyExpanded,
  }) {
    final entry = _liveEntry;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AppModalScrollSurface(
          controller: scrollController,
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(child: _buildModalContent(morph)),
              EventBottomModalSchedulePane(
                eventId: entry.id,
                sliverLayout: true,
                isSheetFullyExpanded: isFullyExpanded,
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: BottomModalScrollTopBlurOverlay(
            controller: scrollController,
            isFullyExpanded: isFullyExpanded,
            surfaceColor: sheetSurface,
          ),
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
