import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:chronoapp/features/calendar/data/calendar_entry_mapper.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/domain/preview/calendar_settings_kind.dart';
import 'package:chronoapp/features/calendar/domain/preview/calendar_settings_preview_entry.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_accent_overrides_provider.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_settings_preview_entry_provider.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_header/accent_picker_colors.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_header/calendar_settings_filter_widgets.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/bottom_modal_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalendarAppearanceBottomSheet extends ConsumerStatefulWidget {
  const CalendarAppearanceBottomSheet({required this.kind, super.key});

  final CalendarSettingsKind kind;

  @override
  ConsumerState<CalendarAppearanceBottomSheet> createState() =>
      _CalendarAppearanceBottomSheetState();
}

class _CalendarAppearanceBottomSheetState
    extends ConsumerState<CalendarAppearanceBottomSheet> {
  late final CalendarFiltersState _snapshotAtOpen;
  late final Map<CalendarEntryType, Color> _accentOverridesAtOpen;
  late final List<CalendarEntryType> _accentTypes;
  late final PageController _pageController;
  double _pageValue = 0;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _snapshotAtOpen = ref.read(calendarFiltersProvider).deepClone();
    _accentOverridesAtOpen = Map<CalendarEntryType, Color>.from(
      ref.read(calendarAccentOverridesProvider),
    );
    _accentTypes = accentTypesForSettingsKind(widget.kind);
    _pageController = PageController()..addListener(_onPageChanged);
  }

  @override
  void dispose() {
    _pageController
      ..removeListener(_onPageChanged)
      ..dispose();
    super.dispose();
  }

  void _onPageChanged() {
    if (!_pageController.hasClients) return;
    final page = _pageController.page ?? 0;
    final maxIdx =
        _accentTypes.isEmpty ? 0 : _accentTypes.length - 1;
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

  void _discardAndClose() {
    HapticFeedback.mediumImpact();
    ref.read(calendarFiltersProvider.notifier).replaceState(_snapshotAtOpen);
    ref
        .read(calendarAccentOverridesProvider.notifier)
        .replaceState(_accentOverridesAtOpen);
    if (context.mounted) Navigator.of(context).maybePop();
  }

  void _confirmAndClose() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
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
                          child: _SheetHeaderIconButton(
                            icon: Icons.close,
                            tooltip: 'Verwerfen',
                            onPressed: _discardAndClose,
                            scheme: scheme,
                          ),
                        ),
                        Positioned(
                          top: MediaQuery.viewPaddingOf(context).top + 6,
                          right: 6,
                          child: _SheetHeaderIconButton(
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
                            calendarKind: widget.kind,
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
        layoutBuilder: _blockPickerLayout,
        itemBuilder: _blockPickerItemBuilder,
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

Widget _blockPickerLayout(
  BuildContext context,
  List<Color> colors,
  PickerItem child,
) {
  return SizedBox(
    width: double.infinity,
    child: Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [for (final color in colors) child(color)],
    ),
  );
}

Widget _blockPickerItemBuilder(
  Color color,
  bool isCurrentColor,
  void Function() changeColor,
) {
  return Container(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(6),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.4),
          offset: const Offset(0, 1),
          blurRadius: 4,
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: changeColor,
        child: SizedBox(
          width: 32,
          height: 32,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: isCurrentColor ? 1 : 0,
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
    ),
  );
}

class _SheetHeaderIconButton extends StatelessWidget {
  const _SheetHeaderIconButton({
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
