import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/database/backend_enums.dart';
import '../../../../../core/theme/theme_tokens.dart';
import '../../providers/calendar_providers.dart';
import '../../providers/filter/shared/calendar_filters_notifier_base.dart';
import '../event_list/modals/base_bottom_modal.dart';

enum CalendarFilterBottomSheetMode { calendarSettings, searchFilter }

class CalendarFilterBottomSheet extends ConsumerWidget {
  const CalendarFilterBottomSheet({required this.mode, super.key});

  final CalendarFilterBottomSheetMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomSheetTheme = Theme.of(context).bottomSheetTheme;
    final isCalendarSettings =
        mode == CalendarFilterBottomSheetMode.calendarSettings;
    final filters = ref.watch(
      isCalendarSettings ? calendarFiltersProvider : searchFiltersProvider,
    );
    final choirOptions = ref.watch(calendarChoirFilterOptionsProvider);
    final voiceOptions = ref.watch(calendarVoiceFilterOptionsProvider);
    final schoolTrackOptions = ref.watch(
      calendarSchoolTrackFilterOptionsProvider,
    );
    final dietOptions = ref.watch(calendarDietFilterOptionsProvider);
    final classOptionsAsync = ref.watch(calendarClassFilterOptionsProvider);
    final classOptions = classOptionsAsync.asData?.value ?? const <String>[];
    final title = isCalendarSettings ? 'Kalender-Einstellungen' : 'Suchfilter';
    final calendarFiltersNotifier = ref.read(calendarFiltersProvider.notifier);

    return ColoredBox(
      color:
          bottomSheetTheme.modalBackgroundColor ?? colorScheme.surfaceContainer,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                if (isCalendarSettings) ...[
                  _CalendarSettingsListSection(
                    filters: filters,
                    onToggleVisibility: calendarFiltersNotifier.setCalendarVisibility,
                    onOpenCalendarFilters: (calendarType) async {
                      await showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        sheetAnimationStyle: kCalendarBottomSheetMotion,
                        builder: (_) => _CalendarSpecificFiltersSheet(
                          calendarType: calendarType,
                          choirOptions: choirOptions,
                          voiceOptions: voiceOptions,
                          classOptions: classOptions,
                          schoolTrackOptions: schoolTrackOptions,
                          dietOptions: dietOptions,
                          labelForChoir: _choirLabel,
                          labelForVoice: _voiceLabel,
                          labelForClass: _classLabel,
                          labelForSchoolTrack: _schoolTrackLabel,
                          labelForDiet: _dietLabel,
                        ),
                      );
                    },
                  ),
                ] else ...[
                  _FilterSection(
                    title: 'Chor',
                    selectedValues: filters.choirs,
                    defaultValues: filters.defaultChoirs,
                    isExplicitSelection: filters.isChoirExplicit,
                    isSearchFilterMode: !isCalendarSettings,
                    options: choirOptions,
                    labelFor: _choirLabel,
                    selectedColor: colorScheme.primary,
                    chipBackgroundColor: colorScheme.surfaceContainerHighest,
                    onToggle: (value) {
                      ref.read(searchFiltersProvider.notifier).toggleChoir(value);
                    },
                    onClear: () {
                      ref.read(searchFiltersProvider.notifier).clearChoirs();
                    },
                  ),
                  const SizedBox(height: 12),
                  _FilterSection(
                    title: 'Stimme',
                    selectedValues: filters.voices,
                    defaultValues: filters.defaultVoices,
                    isExplicitSelection: filters.isVoiceExplicit,
                    isSearchFilterMode: !isCalendarSettings,
                    options: voiceOptions,
                    labelFor: _voiceLabel,
                    selectedColor: colorScheme.primary,
                    chipBackgroundColor: colorScheme.surfaceContainerHighest,
                    onToggle: (value) {
                      ref.read(searchFiltersProvider.notifier).toggleVoice(value);
                    },
                    onClear: () {
                      ref.read(searchFiltersProvider.notifier).clearVoices();
                    },
                  ),
                  const SizedBox(height: 12),
                  _FilterSection(
                    title: 'Klasse',
                    selectedValues: filters.classNames,
                    defaultValues: filters.defaultClassNames,
                    isExplicitSelection: filters.isClassNameExplicit,
                    isSearchFilterMode: !isCalendarSettings,
                    options: classOptions,
                    labelFor: _classLabel,
                    selectedColor: colorScheme.primary,
                    chipBackgroundColor: colorScheme.surfaceContainerHighest,
                    onToggle: (value) {
                      ref.read(searchFiltersProvider.notifier).toggleClassName(value);
                    },
                    onClear: () {
                      ref.read(searchFiltersProvider.notifier).clearClassNames();
                    },
                  ),
                  const SizedBox(height: 12),
                  _FilterSection(
                    title: 'Schulzweig',
                    selectedValues: filters.schoolTracks,
                    defaultValues: filters.defaultSchoolTracks,
                    isExplicitSelection: filters.isSchoolTrackExplicit,
                    isSearchFilterMode: !isCalendarSettings,
                    options: schoolTrackOptions,
                    labelFor: _schoolTrackLabel,
                    selectedColor: colorScheme.primary,
                    chipBackgroundColor: colorScheme.surfaceContainerHighest,
                    onToggle: (value) {
                      ref.read(searchFiltersProvider.notifier).toggleSchoolTrack(value);
                    },
                    onClear: () {
                      ref.read(searchFiltersProvider.notifier).clearSchoolTracks();
                    },
                  ),
                  const SizedBox(height: 12),
                  _FilterSection(
                    title: 'Ernährung',
                    selectedValues: filters.diets,
                    defaultValues: filters.defaultDiets,
                    isExplicitSelection: filters.isDietExplicit,
                    isSearchFilterMode: !isCalendarSettings,
                    options: dietOptions,
                    labelFor: _dietLabel,
                    selectedColor: colorScheme.primary,
                    chipBackgroundColor: colorScheme.surfaceContainerHighest,
                    onToggle: (value) {
                      ref.read(searchFiltersProvider.notifier).toggleDiet(value);
                    },
                    onClear: () {
                      ref.read(searchFiltersProvider.notifier).clearDiets();
                    },
                  ),
                ],
                const SizedBox(height: 16),
                _FilterActionButtons(
                  onReset: () {
                    if (isCalendarSettings) {
                      ref
                          .read(calendarFiltersProvider.notifier)
                          .resetToDefaults();
                    } else {
                      ref
                          .read(searchFiltersProvider.notifier)
                          .resetToDefaults();
                    }
                  },
                  onDone: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).maybePop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _CalendarSettingsType { choir, meal, school }

class _CalendarSettingsListSection extends StatelessWidget {
  const _CalendarSettingsListSection({
    required this.filters,
    required this.onToggleVisibility,
    required this.onOpenCalendarFilters,
  });

  final CalendarFiltersState filters;
  final void Function(CalendarVisibility, bool) onToggleVisibility;
  final Future<void> Function(_CalendarSettingsType) onOpenCalendarFilters;

  @override
  Widget build(BuildContext context) {
    final rows = <_CalendarSettingsRowData>[
      _CalendarSettingsRowData(
        title: 'Chor',
        isVisible: filters.showChoirCalendar,
        calendarVisibility: CalendarVisibility.choir,
        calendarType: _CalendarSettingsType.choir,
      ),
      _CalendarSettingsRowData(
        title: 'Speiseplan',
        isVisible: filters.showMealCalendar,
        calendarVisibility: CalendarVisibility.meal,
        calendarType: _CalendarSettingsType.meal,
      ),
      _CalendarSettingsRowData(
        title: 'Schule',
        isVisible: filters.showSchoolCalendar,
        calendarVisibility: CalendarVisibility.school,
        calendarType: _CalendarSettingsType.school,
      ),
    ];

    return Column(
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          _CalendarSettingsRow(
            data: rows[index],
            onToggleVisibility: onToggleVisibility,
            onOpenCalendarFilters: onOpenCalendarFilters,
          ),
          if (index < rows.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _CalendarSettingsRowData {
  const _CalendarSettingsRowData({
    required this.title,
    required this.isVisible,
    required this.calendarVisibility,
    required this.calendarType,
  });

  final String title;
  final bool isVisible;
  final CalendarVisibility calendarVisibility;
  final _CalendarSettingsType calendarType;
}

class _CalendarSettingsRow extends StatelessWidget {
  const _CalendarSettingsRow({
    required this.data,
    required this.onToggleVisibility,
    required this.onOpenCalendarFilters,
  });

  final _CalendarSettingsRowData data;
  final void Function(CalendarVisibility, bool) onToggleVisibility;
  final Future<void> Function(_CalendarSettingsType) onOpenCalendarFilters;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeColor = const Color(0xFF2DD36F);
    final inactiveColor = scheme.primary.withValues(alpha: 0.24);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            IconButton(
              onPressed: () => onToggleVisibility(
                data.calendarVisibility,
                !data.isVisible,
              ),
              iconSize: 28,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                data.isVisible ? Icons.check_circle : Icons.circle_outlined,
                color: data.isVisible ? activeColor : inactiveColor,
              ),
              tooltip: data.isVisible
                  ? '${data.title} ausblenden'
                  : '${data.title} einblenden',
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                data.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              onPressed: () => onOpenCalendarFilters(data.calendarType),
              icon: const Icon(Icons.info_outline_rounded),
              color: Colors.redAccent,
              tooltip: 'Filter für ${data.title}',
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarSpecificFiltersSheet extends ConsumerWidget {
  const _CalendarSpecificFiltersSheet({
    required this.calendarType,
    required this.choirOptions,
    required this.voiceOptions,
    required this.classOptions,
    required this.schoolTrackOptions,
    required this.dietOptions,
    required this.labelForChoir,
    required this.labelForVoice,
    required this.labelForClass,
    required this.labelForSchoolTrack,
    required this.labelForDiet,
  });

  final _CalendarSettingsType calendarType;
  final List<String> choirOptions;
  final List<String> voiceOptions;
  final List<String> classOptions;
  final List<String> schoolTrackOptions;
  final List<String> dietOptions;
  final String Function(String) labelForChoir;
  final String Function(String) labelForVoice;
  final String Function(String) labelForClass;
  final String Function(String) labelForSchoolTrack;
  final String Function(String) labelForDiet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomSheetTheme = Theme.of(context).bottomSheetTheme;
    final notifier = ref.read(calendarFiltersProvider.notifier);
    final filters = ref.watch(calendarFiltersProvider);

    return ColoredBox(
      color:
          bottomSheetTheme.modalBackgroundColor ?? colorScheme.surfaceContainer,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _calendarSettingsTitle(calendarType),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ..._calendarSpecificSections(
                  filters: filters,
                  notifier: notifier,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.of(context).maybePop();
                    },
                    child: const Text('Fertig'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _calendarSpecificSections({
    required CalendarFiltersState filters,
    required CalendarFiltersNotifierBase notifier,
    required ColorScheme colorScheme,
  }) {
    final chipColor = colorScheme.surfaceContainerHighest;
    final selectedColor = colorScheme.primary;

    switch (calendarType) {
      case _CalendarSettingsType.choir:
        return [
          _FilterSection(
            title: 'Chor',
            selectedValues: filters.choirs,
            defaultValues: filters.defaultChoirs,
            isExplicitSelection: filters.isChoirExplicit,
            isSearchFilterMode: false,
            options: choirOptions,
            labelFor: labelForChoir,
            selectedColor: selectedColor,
            chipBackgroundColor: chipColor,
            onToggle: notifier.toggleChoir,
            onClear: notifier.clearChoirs,
          ),
          const SizedBox(height: 12),
          _FilterSection(
            title: 'Stimme',
            selectedValues: filters.voices,
            defaultValues: filters.defaultVoices,
            isExplicitSelection: filters.isVoiceExplicit,
            isSearchFilterMode: false,
            options: voiceOptions,
            labelFor: labelForVoice,
            selectedColor: selectedColor,
            chipBackgroundColor: chipColor,
            onToggle: notifier.toggleVoice,
            onClear: notifier.clearVoices,
          ),
        ];
      case _CalendarSettingsType.meal:
        return [
          _FilterSection(
            title: 'Ernährung',
            selectedValues: filters.diets,
            defaultValues: filters.defaultDiets,
            isExplicitSelection: filters.isDietExplicit,
            isSearchFilterMode: false,
            options: dietOptions,
            labelFor: labelForDiet,
            selectedColor: selectedColor,
            chipBackgroundColor: chipColor,
            onToggle: notifier.toggleDiet,
            onClear: notifier.clearDiets,
          ),
        ];
      case _CalendarSettingsType.school:
        return [
          _FilterSection(
            title: 'Klasse',
            selectedValues: filters.classNames,
            defaultValues: filters.defaultClassNames,
            isExplicitSelection: filters.isClassNameExplicit,
            isSearchFilterMode: false,
            options: classOptions,
            labelFor: labelForClass,
            selectedColor: selectedColor,
            chipBackgroundColor: chipColor,
            onToggle: notifier.toggleClassName,
            onClear: notifier.clearClassNames,
          ),
          const SizedBox(height: 12),
          _FilterSection(
            title: 'Schulzweig',
            selectedValues: filters.schoolTracks,
            defaultValues: filters.defaultSchoolTracks,
            isExplicitSelection: filters.isSchoolTrackExplicit,
            isSearchFilterMode: false,
            options: schoolTrackOptions,
            labelFor: labelForSchoolTrack,
            selectedColor: selectedColor,
            chipBackgroundColor: chipColor,
            onToggle: notifier.toggleSchoolTrack,
            onClear: notifier.clearSchoolTracks,
          ),
        ];
    }
  }

  String _calendarSettingsTitle(_CalendarSettingsType type) {
    return switch (type) {
      _CalendarSettingsType.choir => 'Chor-Filter',
      _CalendarSettingsType.meal => 'Speiseplan-Filter',
      _CalendarSettingsType.school => 'Schul-Filter',
    };
  }
}

class _FilterActionButtons extends StatelessWidget {
  const _FilterActionButtons({required this.onReset, required this.onDone});

  final VoidCallback onReset;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final base = theme.elevatedButtonTheme.style!;
    final surfaceHighest = scheme.surfaceContainerHighest;
    final onSurface = scheme.onSurface;
    final resetStyle = base.copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return surfaceHighest.withValues(alpha: AppOpacity.disabled);
        }
        return surfaceHighest;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return onSurface.withValues(alpha: AppOpacity.disabled);
        }
        return onSurface;
      }),
      iconColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return onSurface.withValues(alpha: AppOpacity.disabled);
        }
        return onSurface;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return onSurface.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.hovered)) {
          return onSurface.withValues(alpha: 0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return onSurface.withValues(alpha: 0.10);
        }
        return null;
      }),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            style: resetStyle,
            onPressed: onReset,
            icon: const Icon(Icons.restart_alt),
            label: const Text('Auf Standardwerte zurücksetzen'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: ElevatedButton(onPressed: onDone, child: const Text('Fertig')),
        ),
      ],
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
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

    return Column(
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
  }
}

String _choirLabel(String value) {
  final choir = BackendChoirCodec.fromBackend(value);
  if (choir == BackendChoir.unknown) {
    return _capitalize(value);
  }
  return choir.displayLabel;
}

String _voiceLabel(String value) {
  final voice = BackendVoiceCodec.fromBackend(value);
  if (voice == BackendVoice.unknown) {
    return _capitalize(value);
  }
  return voice.displayLabel;
}

String _classLabel(String value) => value.toUpperCase();

String _schoolTrackLabel(String value) {
  final schoolTrack = BackendSchoolTrackCodec.fromBackend(value);
  if (schoolTrack == BackendSchoolTrack.unknown) {
    return _capitalize(value);
  }
  return schoolTrack.displayLabel;
}

String _dietLabel(String value) {
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
