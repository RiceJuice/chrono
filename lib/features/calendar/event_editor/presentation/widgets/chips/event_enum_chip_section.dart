import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:flutter/material.dart';

/// Einzelauswahl per ChoiceChips (ohne „Alle“-Chip).
class EventSingleSelectChipSection extends StatelessWidget {
  const EventSingleSelectChipSection({
    super.key,
    required this.title,
    required this.options,
    required this.labelFor,
    required this.selectedValue,
    required this.onSelected,
    this.selectedColor,
    this.chipBackgroundColor,
  });

  final String title;
  final List<String> options;
  final String Function(String value) labelFor;
  final String? selectedValue;
  final ValueChanged<String?> onSelected;
  final Color? selectedColor;
  final Color? chipBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedFill = selectedColor ?? scheme.primary;
    final chipBg = chipBackgroundColor ?? scheme.surfaceContainerHighest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              ChoiceChip(
                label: Text(labelFor(option)),
                selected: selectedValue == option,
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: selectedValue == option
                      ? (ThemeData.estimateBrightnessForColor(selectedFill) ==
                              Brightness.light
                          ? const Color(0xFF1C1B1F)
                          : Colors.white)
                      : scheme.onSurface,
                ),
                color: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return selectedFill;
                  }
                  return chipBg;
                }),
                side: BorderSide.none,
                onSelected: (selected) {
                  AppHaptics.selection();
                  onSelected(selected ? option : null);
                },
              ),
          ],
        ),
      ],
    );
  }
}

/// Mehrfachauswahl — gleiches Muster wie Kalender-Filter-Chips.
class EventMultiSelectChipSection extends StatelessWidget {
  const EventMultiSelectChipSection({
    super.key,
    required this.title,
    required this.options,
    required this.labelFor,
    required this.selectedValues,
    required this.onToggle,
    this.selectedColor,
    this.chipBackgroundColor,
  });

  final String title;
  final List<String> options;
  final String Function(String value) labelFor;
  final List<String> selectedValues;
  final ValueChanged<String> onToggle;
  final Color? selectedColor;
  final Color? chipBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedFill = selectedColor ?? scheme.primary;
    final chipBg = chipBackgroundColor ?? scheme.surfaceContainerHighest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              ChoiceChip(
                label: Text(labelFor(option)),
                selected: selectedValues.contains(option),
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: selectedValues.contains(option)
                      ? (ThemeData.estimateBrightnessForColor(selectedFill) ==
                              Brightness.light
                          ? const Color(0xFF1C1B1F)
                          : Colors.white)
                      : scheme.onSurface,
                ),
                color: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return selectedFill;
                  }
                  return chipBg;
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
  }
}
