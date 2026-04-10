import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/database/backend_enums.dart';
import '../../../../../core/theme/theme_tokens.dart';
import '../../providers/calendar_providers.dart';

enum CalendarFilterBottomSheetMode { calendarSettings, searchFilter }

class CalendarFilterBottomSheet extends ConsumerWidget {
  const CalendarFilterBottomSheet({
    required this.mode,
    super.key,
  });

  final CalendarFilterBottomSheetMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCalendarSettings = mode == CalendarFilterBottomSheetMode.calendarSettings;
    final filters = ref.watch(
      isCalendarSettings ? calendarFiltersProvider : searchFiltersProvider,
    );
    final choirOptions = ref.watch(calendarChoirFilterOptionsProvider);
    final voiceOptions = ref.watch(calendarVoiceFilterOptionsProvider);
    final classOptionsAsync = ref.watch(calendarClassFilterOptionsProvider);
    final classOptions = classOptionsAsync.asData?.value ?? const <String>[];
    final title = isCalendarSettings ? 'Kalender Einstellungen' : 'Such Filter';

    return ColoredBox(
      color: colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _FilterSection(
                title: 'Chor',
                selectedValues: filters.choirs,
                options: choirOptions,
                labelFor: _choirLabel,
                selectedColor: colorScheme.primary,
                chipBackgroundColor: colorScheme.surfaceContainerHighest,
                onToggle: (value) {
                  if (isCalendarSettings) {
                    ref.read(calendarFiltersProvider.notifier).toggleChoir(value);
                  } else {
                    ref.read(searchFiltersProvider.notifier).toggleChoir(value);
                  }
                },
                onClear: () {
                  if (isCalendarSettings) {
                    ref.read(calendarFiltersProvider.notifier).clearChoirs();
                  } else {
                    ref.read(searchFiltersProvider.notifier).clearChoirs();
                  }
                },
              ),
              const SizedBox(height: 12),
              _FilterSection(
                title: 'Stimme',
                selectedValues: filters.voices,
                options: voiceOptions,
                labelFor: _voiceLabel,
                selectedColor: colorScheme.primary,
                chipBackgroundColor: colorScheme.surfaceContainerHighest,
                onToggle: (value) {
                  if (isCalendarSettings) {
                    ref.read(calendarFiltersProvider.notifier).toggleVoice(value);
                  } else {
                    ref.read(searchFiltersProvider.notifier).toggleVoice(value);
                  }
                },
                onClear: () {
                  if (isCalendarSettings) {
                    ref.read(calendarFiltersProvider.notifier).clearVoices();
                  } else {
                    ref.read(searchFiltersProvider.notifier).clearVoices();
                  }
                },
              ),
              const SizedBox(height: 12),
              _FilterSection(
                title: 'Klasse',
                selectedValues: filters.classNames,
                options: classOptions,
                labelFor: _classLabel,
                selectedColor: colorScheme.primary,
                chipBackgroundColor: colorScheme.surfaceContainerHighest,
                onToggle: (value) {
                  if (isCalendarSettings) {
                    ref
                        .read(calendarFiltersProvider.notifier)
                        .toggleClassName(value);
                  } else {
                    ref.read(searchFiltersProvider.notifier).toggleClassName(value);
                  }
                },
                onClear: () {
                  if (isCalendarSettings) {
                    ref.read(calendarFiltersProvider.notifier).clearClassNames();
                  } else {
                    ref.read(searchFiltersProvider.notifier).clearClassNames();
                  }
                },
              ),
              const SizedBox(height: 16),
              _FilterActionButtons(
                onReset: () {
                  if (isCalendarSettings) {
                    ref.read(calendarFiltersProvider.notifier).resetToDefaults();
                  } else {
                    ref.read(searchFiltersProvider.notifier).resetToDefaults();
                  }
                },
                onDone: () => Navigator.of(context).maybePop(),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterActionButtons extends StatelessWidget {
  const _FilterActionButtons({
    required this.onReset,
    required this.onDone,
  });

  final VoidCallback onReset;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final base = theme.elevatedButtonTheme.style!;
    final surfaceHighest = scheme.surfaceContainerHighest;
    final resetStyle = base.copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return surfaceHighest.withValues(alpha: AppOpacity.disabled);
        }
        return surfaceHighest;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.white.withValues(alpha: AppOpacity.disabled);
        }
        return Colors.white;
      }),
      iconColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.white.withValues(alpha: AppOpacity.disabled);
        }
        return Colors.white;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return Colors.white.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.hovered)) {
          return Colors.white.withValues(alpha: 0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return Colors.white.withValues(alpha: 0.10);
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
            label: const Text('Auf Standard zurücksetzen'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: onDone,
            child: const Text('Fertig'),
          ),
        ),
      ],
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.selectedValues,
    required this.options,
    required this.labelFor,
    required this.selectedColor,
    required this.chipBackgroundColor,
    required this.onToggle,
    required this.onClear,
  });

  final String title;
  final List<String> selectedValues;
  final List<String> options;
  final String Function(String value) labelFor;
  final Color selectedColor;
  final Color chipBackgroundColor;
  final ValueChanged<String> onToggle;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
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
              selected: selectedValues.isEmpty,
              selectedColor: selectedColor,
              backgroundColor: chipBackgroundColor,
              side: BorderSide.none,
              onSelected: (_) => onClear(),
            ),
            for (final option in options)
              ChoiceChip(
                label: Text(labelFor(option)),
                selected: selectedValues.contains(option),
                selectedColor: selectedColor,
                backgroundColor: chipBackgroundColor,
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

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}
