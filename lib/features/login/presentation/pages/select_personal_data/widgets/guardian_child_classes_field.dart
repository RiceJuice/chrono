import 'package:flutter/material.dart';

import '../../../widgets/login_flow_spacing.dart';
import '../../../widgets/login_labeled_field.dart';
import '../../../widgets/login_multi_select_dropdown_field.dart';

class GuardianChildClassesField extends StatelessWidget {
  const GuardianChildClassesField({
    super.key,
    required this.classOptions,
    required this.selectedClasses,
    required this.onChanged,
    this.formFieldKey,
  });

  final List<String> classOptions;
  final List<String> selectedClasses;
  final ValueChanged<List<String>> onChanged;
  final GlobalKey<FormFieldState<dynamic>>? formFieldKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blockGap = LoginFlowSpacing.gapBetweenFields(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: blockGap),
        LoginLabeledField(
          label: 'Klassen deiner Kinder',
          child: LoginMultiSelectDropdownField(
            formFieldKey: formFieldKey,
            options: classOptions,
            selectedValues: selectedClasses,
            onChanged: onChanged,
            label: 'Klassen',
            hintText: 'Klassen auswählen',
            sheetTitle: 'Klassen deiner Kinder',
            emptyOptionsMessage:
                'Keine Klassen verfügbar. Bitte später erneut versuchen.',
            validator: (values) {
              if (classOptions.isEmpty) {
                return 'Keine Klassen verfügbar.';
              }
              if (values == null || values.isEmpty) {
                return 'Bitte mindestens eine Klasse auswählen.';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Du kannst mehrere Klassen auswählen. Die Kindersuche zeigt nur '
          'Schüler aus diesen Klassen.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
