import 'package:flutter/material.dart';

import '../../../../../core/database/backend_enums.dart';
import '../../../../../core/haptics/app_haptics.dart';
import '../event_list/modals/base_bottom_modal.dart';
import '../../../domain/filter/calendar_filters_state.dart';
import '../../../domain/preview/calendar_settings_kind.dart';
import '../../providers/filter/shared/calendar_filters_notifier_base.dart';
import 'calendar_marker_color_palette.dart';

/// Aktionen für die Filter-Chips (Notifier oder lokaler Entwurf im Appearance-Sheet).
class CalendarFilterSectionActions {
  const CalendarFilterSectionActions({
    required this.toggleChoir,
    required this.clearChoirs,
    required this.toggleVoice,
    required this.clearVoices,
    required this.toggleDiet,
    required this.clearDiets,
    required this.toggleClassName,
    required this.clearClassNames,
    required this.toggleSchoolTrack,
    required this.clearSchoolTracks,
  });

  final void Function(String value) toggleChoir;
  final VoidCallback clearChoirs;
  final void Function(String value) toggleVoice;
  final VoidCallback clearVoices;
  final void Function(String value) toggleDiet;
  final VoidCallback clearDiets;
  final void Function(String value) toggleClassName;
  final VoidCallback clearClassNames;
  final void Function(String value) toggleSchoolTrack;
  final VoidCallback clearSchoolTracks;

  factory CalendarFilterSectionActions.fromNotifier(
    CalendarFiltersNotifierBase notifier,
  ) {
    return CalendarFilterSectionActions(
      toggleChoir: notifier.toggleChoir,
      clearChoirs: notifier.clearChoirs,
      toggleVoice: notifier.toggleVoice,
      clearVoices: notifier.clearVoices,
      toggleDiet: notifier.toggleDiet,
      clearDiets: notifier.clearDiets,
      toggleClassName: notifier.toggleClassName,
      clearClassNames: notifier.clearClassNames,
      toggleSchoolTrack: notifier.toggleSchoolTrack,
      clearSchoolTracks: notifier.clearSchoolTracks,
    );
  }
}

List<Widget> calendarSettingsFilterSections({
  required CalendarSettingsKind calendarKind,
  required CalendarFiltersState filters,
  required ColorScheme colorScheme,
  required List<String> choirOptions,
  required List<String> voiceOptions,
  required List<String> classOptions,
  required List<String> schoolTrackOptions,
  required List<String> dietOptions,
  required CalendarFilterSectionActions actions,
  bool animateChipEntrance = false,
}) {
  final chipColor = colorScheme.surfaceContainerHighest;
  final selectedColor = colorScheme.primary;

  switch (calendarKind) {
    case CalendarSettingsKind.choir:
      return [
        CalendarFilterChipSection(
          title: 'Chor',
          selectedValues: filters.choirs,
          defaultValues: filters.defaultChoirs,
          isExplicitSelection: filters.isChoirExplicit,
          isSearchFilterMode: false,
          options: choirOptions,
          labelFor: calendarFilterChoirLabel,
          selectedAccentForOption: calendarFilterChoirChipSelectedAccent,
          selectedColor: selectedColor,
          chipBackgroundColor: chipColor,
          onToggle: actions.toggleChoir,
          onClear: actions.clearChoirs,
          animateEntrance: animateChipEntrance,
          entranceStaggerIndex: 0,
        ),
        const SizedBox(height: 12),
        CalendarFilterChipSection(
          title: 'Stimme',
          selectedValues: filters.voices,
          defaultValues: filters.defaultVoices,
          isExplicitSelection: filters.isVoiceExplicit,
          isSearchFilterMode: false,
          options: voiceOptions,
          labelFor: calendarFilterVoiceLabel,
          selectedColor: selectedColor,
          chipBackgroundColor: chipColor,
          onToggle: actions.toggleVoice,
          onClear: actions.clearVoices,
          animateEntrance: animateChipEntrance,
          entranceStaggerIndex: 1,
        ),
      ];
    case CalendarSettingsKind.meal:
      return [
        CalendarFilterChipSection(
          title: 'Ernährung',
          selectedValues: filters.diets,
          defaultValues: filters.defaultDiets,
          isExplicitSelection: filters.isDietExplicit,
          isSearchFilterMode: false,
          options: dietOptions,
          labelFor: calendarFilterDietLabel,
          selectedColor: selectedColor,
          chipBackgroundColor: chipColor,
          onToggle: actions.toggleDiet,
          onClear: actions.clearDiets,
          animateEntrance: animateChipEntrance,
          entranceStaggerIndex: 0,
        ),
      ];
    case CalendarSettingsKind.school:
      return [
        CalendarFilterChipSection(
          title: 'Klasse',
          selectedValues: filters.classNames,
          defaultValues: filters.defaultClassNames,
          isExplicitSelection: filters.isClassNameExplicit,
          isSearchFilterMode: false,
          options: classOptions,
          labelFor: calendarFilterClassLabel,
          selectedColor: selectedColor,
          chipBackgroundColor: chipColor,
          onToggle: actions.toggleClassName,
          onClear: actions.clearClassNames,
          animateEntrance: animateChipEntrance,
          entranceStaggerIndex: 0,
        ),
        const SizedBox(height: 12),
        CalendarFilterChipSection(
          title: 'Schulzweig',
          selectedValues: filters.schoolTracks,
          defaultValues: filters.defaultSchoolTracks,
          isExplicitSelection: filters.isSchoolTrackExplicit,
          isSearchFilterMode: false,
          options: schoolTrackOptions,
          labelFor: calendarFilterSchoolTrackLabel,
          selectedColor: selectedColor,
          chipBackgroundColor: chipColor,
          onToggle: actions.toggleSchoolTrack,
          onClear: actions.clearSchoolTracks,
          animateEntrance: animateChipEntrance,
          entranceStaggerIndex: 1,
        ),
      ];
  }
}

const int _kChipEntranceStaggerMs = 40;

/// How much choir marker colour is mixed into [chipBackgroundColor] for
/// selected chips — strong enough to read the choir tint at a glance.
const double _choirChipAccentMixExplicit = 0.42;
const double _choirChipAccentMixImplicit = 0.30;

class _ChipSectionEntrance extends StatefulWidget {
  const _ChipSectionEntrance({required this.staggerIndex, required this.child});

  final int staggerIndex;
  final Widget child;

  @override
  State<_ChipSectionEntrance> createState() => _ChipSectionEntranceState();
}

class _ChipSectionEntranceState extends State<_ChipSectionEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    final duration =
        kCalendarBottomSheetMotion.duration ??
        const Duration(milliseconds: 300);
    final curve = kCalendarBottomSheetMotion.curve ?? Curves.easeInOut;
    _controller = AnimationController(
      vsync: this,
      duration: duration,
      reverseDuration: kCalendarBottomSheetMotion.reverseDuration,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: curve));
    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: curve));

    final delay = Duration(
      milliseconds: _kChipEntranceStaggerMs * widget.staggerIndex,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class CalendarFilterChipSection extends StatelessWidget {
  const CalendarFilterChipSection({
    super.key,
    required this.title,
    required this.selectedValues,
    required this.defaultValues,
    required this.isExplicitSelection,
    required this.isSearchFilterMode,
    required this.options,
    required this.labelFor,
    this.selectedAccentForOption,
    required this.selectedColor,
    required this.chipBackgroundColor,
    required this.onToggle,
    required this.onClear,
    this.animateEntrance = false,
    this.entranceStaggerIndex = 0,
  });

  final String title;
  final List<String> selectedValues;
  final List<String> defaultValues;
  final bool isExplicitSelection;
  final bool isSearchFilterMode;
  final List<String> options;
  final String Function(String value) labelFor;

  /// When set, selected option chips use this colour instead of
  /// [selectedColor] (e.g. per-choir tints matching day-marker pills).
  final Color Function(String option)? selectedAccentForOption;
  final Color selectedColor;
  final Color chipBackgroundColor;
  final ValueChanged<String> onToggle;
  final VoidCallback onClear;
  final bool animateEntrance;
  final int entranceStaggerIndex;

  Color _accentForOption(String option) =>
      selectedAccentForOption?.call(option) ?? selectedColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final defaultSet = defaultValues.toSet();
    final selectedSet = selectedValues.toSet();
    final isImplicitDefaultState =
        isSearchFilterMode &&
        !isExplicitSelection &&
        selectedSet.length == defaultSet.length &&
        selectedSet.containsAll(defaultSet);
    final showAllAsSelected =
        selectedValues.isEmpty && (!isSearchFilterMode || !isExplicitSelection);

    Color optionChipSelectedFill(String option) {
      final accent = _accentForOption(option);
      final choirTint = selectedAccentForOption != null;
      if (choirTint) {
        final t = isImplicitDefaultState
            ? _choirChipAccentMixImplicit
            : _choirChipAccentMixExplicit;
        return Color.lerp(chipBackgroundColor, accent, t)!;
      }
      if (isImplicitDefaultState) {
        return Color.lerp(chipBackgroundColor, accent, 0.45)!;
      }
      return accent;
    }

    Color optionChipLabelColor(String option) {
      final isSelected = selectedValues.contains(option);
      if (!isSelected) return scheme.onSurface;
      // Soft choir tints: keep typography on surface colours (readable, quiet).
      if (selectedAccentForOption != null) {
        return scheme.onSurface;
      }
      final fill = optionChipSelectedFill(option);
      return ThemeData.estimateBrightnessForColor(fill) == Brightness.light
          ? const Color(0xFF1C1B1F)
          : Colors.white;
    }

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Alle'),
              selected: showAllAsSelected,
              showCheckmark: false,
              labelStyle: TextStyle(
                color: showAllAsSelected
                    ? (ThemeData.estimateBrightnessForColor(selectedColor) ==
                            Brightness.light
                        ? const Color(0xFF1C1B1F)
                        : Colors.white)
                    : scheme.onSurface,
              ),
              color: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return selectedColor;
                }
                return chipBackgroundColor;
              }),
              side: BorderSide.none,
              onSelected: (_) {
                AppHaptics.selection();
                onClear();
              },
            ),
            for (final option in options)
              ChoiceChip(
                label: Text(labelFor(option)),
                selected: selectedValues.contains(option),
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: optionChipLabelColor(option),
                ),
                color: WidgetStateProperty.resolveWith((states) {
                  if (!states.contains(WidgetState.selected)) {
                    return chipBackgroundColor;
                  }
                  return optionChipSelectedFill(option);
                }),
                side: BorderSide.none,
                onSelected: (_) {
                  AppHaptics.selection();
                  onToggle(option);
                },
              ),
          ],
        ),
      ],
    );

    if (!animateEntrance) {
      return column;
    }

    return _ChipSectionEntrance(
      staggerIndex: entranceStaggerIndex,
      child: column,
    );
  }
}

String calendarFilterChoirLabel(String value) {
  final choir = BackendChoirCodec.fromBackend(value);
  if (choir == BackendChoir.unknown) {
    return _capitalize(value);
  }
  return choir.displayLabel;
}

/// Saturated choir marker colour; [CalendarFilterChipSection] blends it
/// lightly into the chip background for a subtle tint (see
/// [_choirChipAccentMixExplicit]).
Color calendarFilterChoirChipSelectedAccent(String value) {
  final choir = BackendChoirCodec.fromBackend(value);
  const palette = CalendarMarkerColorPalette.standard;
  return palette.byChoir[choir] ?? palette.fallback;
}

String calendarFilterVoiceLabel(String value) {
  final voice = BackendVoiceCodec.fromBackend(value);
  if (voice == BackendVoice.unknown) {
    return _capitalize(value);
  }
  return voice.displayLabel;
}

String calendarFilterClassLabel(String value) => value.toUpperCase();

String calendarFilterSchoolTrackLabel(String value) {
  final schoolTrack = BackendSchoolTrackCodec.fromBackend(value);
  if (schoolTrack == BackendSchoolTrack.unknown) {
    return _capitalize(value);
  }
  return schoolTrack.displayLabel;
}

String calendarFilterDietLabel(String value) {
  final diet = BackendDietCodec.fromBackend(value);
  if (diet == BackendDiet.unknown) {
    return _capitalize(value);
  }
  return diet.displayLabel;
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}
