import 'package:flutter/material.dart';

import '../../../../../core/database/backend_enums.dart';
import '../event_list/modals/base_bottom_modal.dart';
import '../../../domain/filter/calendar_filters_state.dart';
import '../../../domain/preview/calendar_settings_kind.dart';
import '../../providers/filter/shared/calendar_filters_notifier_base.dart';

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
  final Color selectedColor;
  final Color chipBackgroundColor;
  final ValueChanged<String> onToggle;
  final VoidCallback onClear;
  final bool animateEntrance;
  final int entranceStaggerIndex;

  @override
  Widget build(BuildContext context) {
    final initialSelectedColor = Color.lerp(
      chipBackgroundColor,
      selectedColor,
      0.45,
    )!;
    final defaultSet = defaultValues.toSet();
    final selectedSet = selectedValues.toSet();
    final isImplicitDefaultState =
        isSearchFilterMode &&
        !isExplicitSelection &&
        selectedSet.length == defaultSet.length &&
        selectedSet.containsAll(defaultSet);
    final showAllAsSelected =
        selectedValues.isEmpty && (!isSearchFilterMode || !isExplicitSelection);

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
              color: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return selectedColor;
                }
                return chipBackgroundColor;
              }),
              side: BorderSide.none,
              onSelected: (_) => onClear(),
            ),
            for (final option in options)
              ChoiceChip(
                label: Text(labelFor(option)),
                selected: selectedValues.contains(option),
                showCheckmark: false,
                color: WidgetStateProperty.resolveWith((states) {
                  if (!states.contains(WidgetState.selected)) {
                    return chipBackgroundColor;
                  }
                  if (isImplicitDefaultState) {
                    return initialSelectedColor;
                  }
                  return selectedColor;
                }),
                side: BorderSide.none,
                onSelected: (_) => onToggle(option),
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
