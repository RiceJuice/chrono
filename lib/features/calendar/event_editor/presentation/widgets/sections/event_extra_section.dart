import 'package:chronoapp/core/database/backend_enums.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:flutter/material.dart';

import '../../../domain/calendar_event_form_state.dart';
import '../chips/event_enum_chip_section.dart';
import '../event_form_island.dart';
import 'event_form_text_field.dart';

class EventExtraSection extends StatelessWidget {
  const EventExtraSection({
    super.key,
    required this.state,
    required this.onChanged,
    required this.noteController,
  });

  final CalendarEventFormState state;
  final ValueChanged<CalendarEventFormState> onChanged;
  final TextEditingController noteController;

  static List<String> get _dietOptions => BackendDiet.values
      .where((v) => v != BackendDiet.unknown)
      .map((v) => v.toBackend())
      .whereType<String>()
      .toList();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dietSelected = state.diet.toBackend();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EventFormIsland(
          children: [
            EventFormTextField(
              hint: 'Notiz',
              controller: noteController,
              maxLines: 2,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        EventSingleSelectChipSection(
          title: 'Ernährung',
          options: _dietOptions,
          labelFor: (value) {
            final diet = BackendDietCodec.fromBackend(value);
            return diet.displayLabel;
          },
          selectedValue: dietSelected,
          selectedColor: scheme.primary,
          chipBackgroundColor: scheme.surfaceContainerHighest,
          onSelected: (value) {
            final diet = value == null
                ? BackendDiet.unknown
                : BackendDietCodec.fromBackend(value);
            onChanged(state.copyWith(diet: diet));
          },
        ),
      ],
    );
  }
}
