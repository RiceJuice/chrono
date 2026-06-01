import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:chronoapp/features/calendar/data/calendar_entry_mapper.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/domain/preview/calendar_appearance_config.dart';
import 'package:chronoapp/features/calendar/domain/preview/calendar_settings_preview_entry.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_accent_overrides_provider.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_settings_preview_entry_provider.dart';
import 'package:chronoapp/features/calendar/presentation/providers/subjects_providers.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_header/accent_picker_colors.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_header/calendar_appearance_subject_panel.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_header/calendar_settings_filter_widgets.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/bottom_modal_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalendarAppearanceBottomSheet extends ConsumerStatefulWidget {
  const CalendarAppearanceBottomSheet({required this.config, super.key});

  final CalendarAppearanceConfig config;

  static Future<void> show(
    BuildContext context, {
    required CalendarAppearanceConfig config,
  }) {
    return AppModalSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CalendarAppearanceBottomSheet(config: config),
    );
  }

  @override
  ConsumerState<CalendarAppearanceBottomSheet> createState() =>
      _CalendarAppearanceBottomSheetState();
}

class _CalendarAppearanceBottomSheetState
    extends ConsumerState<CalendarAppearanceBottomSheet> {
  CalendarFiltersState? _filtersSnapshotAtOpen;
  Map<CalendarEntryType, Color>? _accentOverridesAtOpen;

  late final List<CalendarEntryType> _accentTypes;
  late final PageController _pageController;
  double _pageValue = 0;
  int _activeIndex = 0;

  bool get _isSubjectMode => widget.config is CalendarAppearanceBySubject;

  CalendarAppearanceByKind get _kindConfig =>
      widget.config as CalendarAppearanceByKind;

  CalendarAppearanceBySubject get _subjectConfig =>
      widget.config as CalendarAppearanceBySubject;

  final GlobalKey<CalendarAppearanceSubjectPanelState> _subjectPanelKey =
      GlobalKey();

  @override
  void initState() {
    super.initState();
    if (_isSubjectMode) {
      _accentTypes = const [];
      _pageController = PageController();
    } else {
      _filtersSnapshotAtOpen = ref.read(calendarFiltersProvider).deepClone();
      _accentOverridesAtOpen = Map<CalendarEntryType, Color>.from(
        ref.read(calendarAccentOverridesProvider),
      );
      _accentTypes = accentTypesForSettingsKind(_kindConfig.kind);
      _pageController = PageController()..addListener(_onPageChanged);
    }
  }

  @override
  void dispose() {
    if (!_isSubjectMode) {
      _pageController.removeListener(_onPageChanged);
    }
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    if (!_pageController.hasClients) return;
    final page = _pageController.page ?? 0;
    final maxIdx = _accentTypes.isEmpty ? 0 : _accentTypes.length - 1;
    final nextRounded = page.round().clamp(0, maxIdx);
    final prevRounded = _pageValue.round().clamp(0, maxIdx);

    if (_accentTypes.length > 1 && nextRounded != prevRounded) {
      HapticFeedback.mediumImpact();
    }

    if (page != _pageValue || nextRounded != _activeIndex) {
      setState(() {
        _pageValue = page;
        _activeIndex = nextRounded;
      });
    }
  }

  Future<void> _discardAndClose() async {
    if (_isSubjectMode) {
      await _subjectPanelKey.currentState?.discardChanges();
    } else {
      HapticFeedback.mediumImpact();
      ref
          .read(calendarFiltersProvider.notifier)
          .replaceState(_filtersSnapshotAtOpen!);
      ref
          .read(calendarAccentOverridesProvider.notifier)
          .replaceState(_accentOverridesAtOpen!);
    }
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  void _confirmAndClose() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubjectMode) {
      return _buildSubjectMode(context);
    }
    return _buildKindMode(context);
  }

  Widget _buildSubjectMode(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final subjectOverrides =
        ref.watch(subjectAccentOverridesProvider).value ??
        const <String, Color>{};
    final baseEntry = _subjectConfig.previewEntry;
    final currentColor =
        subjectOverrides[_subjectConfig.subjectId] ?? baseEntry.accentColor;
    final previewEntry = baseEntry.copyWith(accentColor: currentColor);

    return AppModalSheetChrome(
      color: scheme.surfaceContainerHigh,
      constraints: BoxConstraints(
        minHeight: screenHeight * 0.7,
        maxHeight: screenHeight * 0.9,
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  BottomModalHeaderPreview(
                    entry: previewEntry,
                    clipTopCorners: false,
                  ),
                  Positioned(
                    top: MediaQuery.viewPaddingOf(context).top + 6,
                    left: 6,
                    child: CalendarAppearanceSheetHeaderButton(
                      icon: Icons.close,
                      tooltip: 'Verwerfen',
                      onPressed: _discardAndClose,
                      scheme: scheme,
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.viewPaddingOf(context).top + 6,
                    right: 6,
                    child: CalendarAppearanceSheetHeaderButton(
                      icon: Icons.check,
                      tooltip: 'Fertig',
                      onPressed: _confirmAndClose,
                      scheme: scheme,
                    ),
                  ),
                ],
              ),
              CalendarAppearanceSubjectPanel(
                key: _subjectPanelKey,
                config: _subjectConfig,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKindMode(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final filters = ref.watch(calendarFiltersProvider);
    final notifier = ref.read(calendarFiltersProvider.notifier);
    final choirOptions = ref.watch(calendarChoirFilterOptionsProvider);
    final voiceOptions = ref.watch(calendarVoiceFilterOptionsProvider);
    final schoolTrackOptions = ref.watch(
      calendarSchoolTrackFilterOptionsProvider,
    );
    final dietOptions = ref.watch(calendarDietFilterOptionsProvider);
    final classOptionsAsync = ref.watch(calendarClassFilterOptionsProvider);
    final classOptions = classOptionsAsync.asData?.value ?? const <String>[];

    final overrides = ref.watch(calendarAccentOverridesProvider);
    final previewEntries = _accentTypes.map((type) {
      final asyncEntry = ref.watch(
        calendarAccentTypePreviewEntryProvider(type),
      );
      final entry =
          asyncEntry.asData?.value ?? calendarPreviewPlaceholderForType(type);
      final accent = overrides[type] ??
          CalendarEntryMapper.defaultAccentColorForType(type);
      return entry.copyWith(accentColor: accent);
    }).toList(growable: false);

    final activeAccentType = _accentTypes[_activeIndex];

    return AppModalSheetChrome(
      color: scheme.surfaceContainerHigh,
      constraints: BoxConstraints(
        minHeight: screenHeight * 0.7,
        maxHeight: screenHeight * 0.9,
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  BottomModalHeaderPreviewSwiper(
                    entries: previewEntries,
                    pageController: _pageController,
                    pageValue: _pageValue,
                    activeIndex: _activeIndex,
                    clipTopCorners: false,
                  ),
                  Positioned(
                    top: MediaQuery.viewPaddingOf(context).top + 6,
                    left: 6,
                    child: CalendarAppearanceSheetHeaderButton(
                      icon: Icons.close,
                      tooltip: 'Verwerfen',
                      onPressed: _discardAndClose,
                      scheme: scheme,
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.viewPaddingOf(context).top + 6,
                    right: 6,
                    child: CalendarAppearanceSheetHeaderButton(
                      icon: Icons.check,
                      tooltip: 'Fertig',
                      onPressed: _confirmAndClose,
                      scheme: scheme,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AccentColorPickerSection(accentType: activeAccentType),
                    const SizedBox(height: 16),
                    ...calendarSettingsFilterSections(
                      calendarKind: _kindConfig.kind,
                      filters: filters,
                      colorScheme: scheme,
                      choirOptions: choirOptions,
                      voiceOptions: voiceOptions,
                      classOptions: classOptions,
                      schoolTrackOptions: schoolTrackOptions,
                      dietOptions: dietOptions,
                      actions: CalendarFilterSectionActions.fromNotifier(
                        notifier,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccentColorPickerSection extends ConsumerWidget {
  const _AccentColorPickerSection({required this.accentType});

  final CalendarEntryType accentType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fallback = CalendarEntryMapper.defaultAccentColorForType(accentType);
    final overrides = ref.watch(calendarAccentOverridesProvider);
    final currentColor = overrides[accentType] ?? fallback;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: BlockPicker(
        key: ValueKey('${accentType.name}-${currentColor.toARGB32()}'),
        pickerColor: currentColor,
        availableColors: kCalendarAccentPickerColors,
        layoutBuilder: calendarAccentBlockPickerLayout,
        itemBuilder: calendarAccentBlockPickerItem,
        onColorChanged: (color) {
          HapticFeedback.selectionClick();
          ref
              .read(calendarAccentOverridesProvider.notifier)
              .setOverride(accentType, color);
        },
      ),
    );
  }
}

class CalendarAppearanceSheetHeaderButton extends StatelessWidget {
  const CalendarAppearanceSheetHeaderButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.scheme,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: scheme.surface.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurface,
          padding: const EdgeInsets.all(12),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
      ),
    );
  }
}
