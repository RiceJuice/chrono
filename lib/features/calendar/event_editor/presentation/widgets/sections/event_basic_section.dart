import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:flutter/material.dart';

import '../../../../domain/models/calendar_entry.dart';
import '../../../domain/calendar_event_form_state.dart';
import '../chips/event_enum_chip_section.dart';
import '../event_form_island.dart';
import 'event_form_text_field.dart';

const _typeLabels = <CalendarEntryType, String>{
  CalendarEntryType.lesson: 'Stunde',
  CalendarEntryType.meal: 'Essen',
  CalendarEntryType.event: 'Event',
  CalendarEntryType.choir: 'Chor',
};

class EventBasicSection extends StatelessWidget {
  const EventBasicSection({
    super.key,
    required this.state,
    required this.onChanged,
    required this.eventNameController,
    required this.descriptionController,
    required this.locationController,
  });

  final CalendarEventFormState state;
  final ValueChanged<CalendarEventFormState> onChanged;
  final TextEditingController eventNameController;
  final TextEditingController descriptionController;
  final TextEditingController locationController;

  static List<CalendarEntryType> get typeOptions => CalendarEntryType.values;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EventFormIsland(
          children: [
            EventFormTextField(
              hint: 'Terminname',
              controller: eventNameController,
              textInputAction: TextInputAction.next,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        EventFormIsland(
          children: [
            EventFormTextField(
              hint: 'Ort',
              controller: locationController,
              textInputAction: TextInputAction.next,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        EventSingleSelectChipSection(
          title: 'Typ',
          options: typeOptions.map((t) => t.name).toList(),
          labelFor: (value) =>
              _typeLabels[CalendarEntryType.values.byName(value)]!,
          selectedValue: state.type.name,
          selectedColor: scheme.primary,
            chipBackgroundColor: scheme.surfaceContainerHighest,
          onSelected: (value) {
            if (value == null) return;
            onChanged(
              state.copyWith(type: CalendarEntryType.values.byName(value)),
            );
          },
        ),
        const SizedBox(height: AppSpacing.m),
        EventFormIsland(
          children: [
            EventFormTextField(
              hint: 'Beschreibung',
              controller: descriptionController,
              maxLines: 3,
              textInputAction: TextInputAction.newline,
            ),
          ],
        ),
      ],
    );
  }
}
