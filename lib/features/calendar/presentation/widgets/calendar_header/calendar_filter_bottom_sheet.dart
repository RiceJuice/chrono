import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/theme_tokens.dart';
import '../../../data/calendar_entry_mapper.dart';
import '../../../domain/models/calendar_entry.dart';
import '../../../domain/preview/calendar_appearance_config.dart';
import '../../../domain/preview/calendar_settings_kind.dart';
import '../../providers/calendar_accent_overrides_provider.dart';
import '../../providers/calendar_providers.dart';
import 'calendar_appearance_bottom_sheet.dart';
import 'calendar_settings_filter_widgets.dart';
import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/widgets/app_modal_sheet.dart';

import '../event_list/modals/base_bottom_modal.dart';

enum CalendarFilterBottomSheetMode { calendarSettings, searchFilter }

class CalendarFilterBottomSheet extends ConsumerWidget {
  const CalendarFilterBottomSheet({required this.mode, super.key});

  final CalendarFilterBottomSheetMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
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

    return AppModalSheetChrome(
      child: SafeArea(
        bottom: false,
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
                    onToggleVisibility:
                        calendarFiltersNotifier.setCalendarVisibility,
                    choirOptions: choirOptions,
                    voiceOptions: voiceOptions,
                    classOptions: classOptions,
                    schoolTrackOptions: schoolTrackOptions,
                    dietOptions: dietOptions,
                  ),
                ] else ...[
                  CalendarFilterChipSection(
                    title: 'Chor',
                    selectedValues: filters.choirs,
                    defaultValues: filters.defaultChoirs,
                    isExplicitSelection: filters.isChoirExplicit,
                    isSearchFilterMode: !isCalendarSettings,
                    options: choirOptions,
                    labelFor: calendarFilterChoirLabel,
                    selectedAccentForOption: calendarFilterChoirChipSelectedAccent,
                    selectedColor: colorScheme.primary,
                    chipBackgroundColor: colorScheme.surfaceContainerHighest,
                    onToggle: (value) {
                      ref
                          .read(searchFiltersProvider.notifier)
                          .toggleChoir(value);
                    },
                    onClear: () {
                      ref.read(searchFiltersProvider.notifier).clearChoirs();
                    },
                  ),
                  const SizedBox(height: 12),
                  CalendarFilterChipSection(
                    title: 'Stimme',
                    selectedValues: filters.voices,
                    defaultValues: filters.defaultVoices,
                    isExplicitSelection: filters.isVoiceExplicit,
                    isSearchFilterMode: !isCalendarSettings,
                    options: voiceOptions,
                    labelFor: calendarFilterVoiceLabel,
                    selectedColor: colorScheme.primary,
                    chipBackgroundColor: colorScheme.surfaceContainerHighest,
                    onToggle: (value) {
                      ref
                          .read(searchFiltersProvider.notifier)
                          .toggleVoice(value);
                    },
                    onClear: () {
                      ref.read(searchFiltersProvider.notifier).clearVoices();
                    },
                  ),
                  const SizedBox(height: 12),
                  CalendarFilterChipSection(
                    title: 'Klasse',
                    selectedValues: filters.classNames,
                    defaultValues: filters.defaultClassNames,
                    isExplicitSelection: filters.isClassNameExplicit,
                    isSearchFilterMode: !isCalendarSettings,
                    options: classOptions,
                    labelFor: calendarFilterClassLabel,
                    selectedColor: colorScheme.primary,
                    chipBackgroundColor: colorScheme.surfaceContainerHighest,
                    onToggle: (value) {
                      ref
                          .read(searchFiltersProvider.notifier)
                          .toggleClassName(value);
                    },
                    onClear: () {
                      ref
                          .read(searchFiltersProvider.notifier)
                          .clearClassNames();
                    },
                  ),
                  const SizedBox(height: 12),
                  CalendarFilterChipSection(
                    title: 'Schulzweig',
                    selectedValues: filters.schoolTracks,
                    defaultValues: filters.defaultSchoolTracks,
                    isExplicitSelection: filters.isSchoolTrackExplicit,
                    isSearchFilterMode: !isCalendarSettings,
                    options: schoolTrackOptions,
                    labelFor: calendarFilterSchoolTrackLabel,
                    selectedColor: colorScheme.primary,
                    chipBackgroundColor: colorScheme.surfaceContainerHighest,
                    onToggle: (value) {
                      ref
                          .read(searchFiltersProvider.notifier)
                          .toggleSchoolTrack(value);
                    },
                    onClear: () {
                      ref
                          .read(searchFiltersProvider.notifier)
                          .clearSchoolTracks();
                    },
                  ),
                  const SizedBox(height: 12),
                  CalendarFilterChipSection(
                    title: 'Ernährung',
                    selectedValues: filters.diets,
                    defaultValues: filters.defaultDiets,
                    isExplicitSelection: filters.isDietExplicit,
                    isSearchFilterMode: !isCalendarSettings,
                    options: dietOptions,
                    labelFor: calendarFilterDietLabel,
                    selectedColor: colorScheme.primary,
                    chipBackgroundColor: colorScheme.surfaceContainerHighest,
                    onToggle: (value) {
                      ref
                          .read(searchFiltersProvider.notifier)
                          .toggleDiet(value);
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

CalendarEntryType _accentTypeForSettingsRow(CalendarSettingsKind kind) {
  return switch (kind) {
    CalendarSettingsKind.choir => CalendarEntryType.choir,
    CalendarSettingsKind.meal => CalendarEntryType.meal,
    CalendarSettingsKind.school => CalendarEntryType.lesson,
  };
}

class _CalendarSettingsListSection extends ConsumerStatefulWidget {
  const _CalendarSettingsListSection({
    required this.filters,
    required this.onToggleVisibility,
    required this.choirOptions,
    required this.voiceOptions,
    required this.classOptions,
    required this.schoolTrackOptions,
    required this.dietOptions,
  });

  final CalendarFiltersState filters;
  final void Function(CalendarVisibility, bool) onToggleVisibility;
  final List<String> choirOptions;
  final List<String> voiceOptions;
  final List<String> classOptions;
  final List<String> schoolTrackOptions;
  final List<String> dietOptions;

  @override
  ConsumerState<_CalendarSettingsListSection> createState() =>
      _CalendarSettingsListSectionState();
}

class _CalendarSettingsListSectionState
    extends ConsumerState<_CalendarSettingsListSection> {
  final Set<CalendarSettingsKind> _expanded = {};
  bool _isAppearanceSheetOpen = false;

  void _toggleExpanded(CalendarSettingsKind kind) {
    AppHaptics.selection();
    setState(() {
      if (_expanded.contains(kind)) {
        _expanded.remove(kind);
      } else {
        _expanded.add(kind);
      }
    });
  }

  Future<void> _openAppearance(CalendarSettingsKind kind) async {
    if (_isAppearanceSheetOpen) return;

    _isAppearanceSheetOpen = true;
    try {
      await AppModalSheet.show<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => CalendarAppearanceBottomSheet(
          config: CalendarAppearanceByKind(kind),
        ),
      );
    } finally {
      _isAppearanceSheetOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = <_CalendarSettingsRowData>[
      _CalendarSettingsRowData(
        title: 'Chor',
        isVisible: widget.filters.showChoirCalendar,
        calendarVisibility: CalendarVisibility.choir,
        settingsKind: CalendarSettingsKind.choir,
      ),
      _CalendarSettingsRowData(
        title: 'Speiseplan',
        isVisible: widget.filters.showMealCalendar,
        calendarVisibility: CalendarVisibility.meal,
        settingsKind: CalendarSettingsKind.meal,
      ),
      _CalendarSettingsRowData(
        title: 'Schule',
        isVisible: widget.filters.showSchoolCalendar,
        calendarVisibility: CalendarVisibility.school,
        settingsKind: CalendarSettingsKind.school,
      ),
    ];

    final notifier = ref.read(calendarFiltersProvider.notifier);
    final filters = ref.watch(calendarFiltersProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          _CalendarSettingsRow(
            data: rows[index],
            onToggleVisibility: widget.onToggleVisibility,
            isExpanded: _expanded.contains(rows[index].settingsKind),
            onToggleExpand: () => _toggleExpanded(rows[index].settingsKind),
            onOpenAppearance: () => _openAppearance(rows[index].settingsKind),
          ),
          AnimatedSize(
            duration:
                kCalendarBottomSheetMotion.duration ??
                const Duration(milliseconds: 300),
            curve: kCalendarBottomSheetMotion.curve ?? Curves.easeInOut,
            reverseDuration: kCalendarBottomSheetMotion.reverseDuration,
            alignment: Alignment.topCenter,
            clipBehavior: Clip.hardEdge,
            child: _expanded.contains(rows[index].settingsKind)
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 8,
                          right: 8,
                          bottom: 4,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: calendarSettingsFilterSections(
                                calendarKind: rows[index].settingsKind,
                                filters: filters,
                                colorScheme: colorScheme,
                                choirOptions: widget.choirOptions,
                                voiceOptions: widget.voiceOptions,
                                classOptions: widget.classOptions,
                                schoolTrackOptions: widget.schoolTrackOptions,
                                dietOptions: widget.dietOptions,
                                actions:
                                    CalendarFilterSectionActions.fromNotifier(
                                      notifier,
                                    ),
                                animateChipEntrance: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
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
    required this.settingsKind,
  });

  final String title;
  final bool isVisible;
  final CalendarVisibility calendarVisibility;
  final CalendarSettingsKind settingsKind;
}

class _CalendarSettingsRow extends ConsumerWidget {
  const _CalendarSettingsRow({
    required this.data,
    required this.onToggleVisibility,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onOpenAppearance,
  });

  final _CalendarSettingsRowData data;
  final void Function(CalendarVisibility, bool) onToggleVisibility;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onOpenAppearance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final accentType = _accentTypeForSettingsRow(data.settingsKind);
    final fallback = CalendarEntryMapper.defaultAccentColorForType(accentType);
    final activeColor = resolveCalendarTypeAccent(ref, accentType, fallback);
    final ringColor = activeColor;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Row(
          children: [
            IconButton(
              onPressed: () =>
                  onToggleVisibility(data.calendarVisibility, !data.isVisible),
              iconSize: 28,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                data.isVisible ? Icons.check_circle : Icons.circle_outlined,
                color: data.isVisible ? activeColor : ringColor,
              ),
              tooltip: data.isVisible
                  ? '${data.title} ausblenden'
                  : '${data.title} einblenden',
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                data.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (data.settingsKind != CalendarSettingsKind.school)
              IconButton(
                onPressed: onOpenAppearance,
                icon: Icon(Icons.settings_rounded, color: scheme.primary),
                tooltip: 'Erscheinungsbild: ${data.title}',
              ),
            IconButton(
              onPressed: onToggleExpand,
              icon: Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: scheme.onSurfaceVariant,
              ),
              tooltip: isExpanded ? 'Filter einklappen' : 'Filter anzeigen',
            ),
          ],
        ),
      ),
    );
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
