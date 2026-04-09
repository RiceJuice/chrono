import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/database/backend_enums.dart';
import '../../../../../core/theme/theme_tokens.dart';
import '../../providers/calendar_providers.dart';

class CalendarFilterBottomSheet extends ConsumerWidget {
  const CalendarFilterBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final filters = ref.watch(calendarLocalFiltersProvider);
    final choirOptions = ref.watch(calendarChoirFilterOptionsProvider);
    final voiceOptions = ref.watch(calendarVoiceFilterOptionsProvider);
    final classOptionsAsync = ref.watch(calendarClassFilterOptionsProvider);
    final classOptions = classOptionsAsync.asData?.value ?? const <String>[];

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
                'Kalender-Filter',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _FilterSection(
                title: 'Chor',
                selectedValue: filters.choir,
                options: choirOptions,
                labelFor: _choirLabel,
                selectedColor: colorScheme.primary,
                chipBackgroundColor: colorScheme.surfaceContainerHighest,
                onSelected: (value) => ref
                    .read(calendarLocalFiltersProvider.notifier)
                    .setChoir(value),
              ),
              const SizedBox(height: 12),
              _FilterSection(
                title: 'Stimme',
                selectedValue: filters.voice,
                options: voiceOptions,
                labelFor: _voiceLabel,
                selectedColor: colorScheme.primary,
                chipBackgroundColor: colorScheme.surfaceContainerHighest,
                onSelected: (value) => ref
                    .read(calendarLocalFiltersProvider.notifier)
                    .setVoice(value),
              ),
              const SizedBox(height: 12),
              _FilterSection(
                title: 'Klasse',
                selectedValue: filters.className,
                options: classOptions,
                labelFor: _classLabel,
                selectedColor: colorScheme.primary,
                chipBackgroundColor: colorScheme.surfaceContainerHighest,
                onSelected: (value) => ref
                    .read(calendarLocalFiltersProvider.notifier)
                    .setClassName(value),
              ),
              const SizedBox(height: 16),
              _FilterActionButtons(
                onReset: () => ref
                    .read(calendarLocalFiltersProvider.notifier)
                    .resetToProfileDefaults(),
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
            label: const Text('Auf Profil zurücksetzen'),
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
    required this.selectedValue,
    required this.options,
    required this.labelFor,
    required this.selectedColor,
    required this.chipBackgroundColor,
    required this.onSelected,
  });

  final String title;
  final String? selectedValue;
  final List<String> options;
  final String Function(String value) labelFor;
  final Color selectedColor;
  final Color chipBackgroundColor;
  final ValueChanged<String?> onSelected;

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
              selected: selectedValue == null,
              selectedColor: selectedColor,
              backgroundColor: chipBackgroundColor,
              side: BorderSide.none,
              onSelected: (_) => onSelected(null),
            ),
            for (final option in options)
              ChoiceChip(
                label: Text(labelFor(option)),
                selected: selectedValue == option,
                selectedColor: selectedColor,
                backgroundColor: chipBackgroundColor,
                side: BorderSide.none,
                onSelected: (_) => onSelected(option),
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
