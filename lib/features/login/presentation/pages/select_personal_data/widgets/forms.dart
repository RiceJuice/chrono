import 'package:flutter/material.dart';

import '../../../widgets/login_dropdown_field.dart';
import '../../../widgets/login_text_field.dart';

class LoginPersonalDataFields extends StatelessWidget {
  const LoginPersonalDataFields({
    super.key,
    required this.firstNameFieldKey,
    required this.lastNameFieldKey,
    required this.classFieldKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.selectedClass,
    required this.classOptions,
    required this.onClassChanged,
  });

  final GlobalKey<FormFieldState<dynamic>> firstNameFieldKey;
  final GlobalKey<FormFieldState<dynamic>> lastNameFieldKey;
  final GlobalKey<FormFieldState<dynamic>> classFieldKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final String? selectedClass;
  final List<String> classOptions;
  final ValueChanged<String?> onClassChanged;

  @override
  Widget build(BuildContext context) {
    const fieldContentPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 15);
    final Color labelColor = Theme.of(context).colorScheme.onSurface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vorname',
          style: TextStyle(
            color: labelColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        LoginTextField(
          formFieldKey: firstNameFieldKey,
          controller: firstNameController,
          hintText: 'Max',
          prefixIcon: Icons.person_outline_rounded,
          contentPadding: fieldContentPadding,
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return 'Bitte Vornamen eingeben.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Nachname',
          style: TextStyle(
            color: labelColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        LoginTextField(
          formFieldKey: lastNameFieldKey,
          controller: lastNameController,
          hintText: 'Mustermann',
          prefixIcon: Icons.badge_outlined,
          contentPadding: fieldContentPadding,
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return 'Bitte Nachnamen eingeben.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Klasse',
          style: TextStyle(
            color: labelColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        LoginDropdownField(
          formFieldKey: classFieldKey,
          selectedValue: selectedClass,
          options: classOptions,
          label: 'Klasse',
          hintText: 'z. B. 10a',
          leadingIcon: const Icon(Icons.school_outlined),
          validator: (value) {
            if (classOptions.isEmpty) {
              return 'Keine Klassen verfuegbar. Bitte spaeter erneut versuchen.';
            }
            if (value == null || value.trim().isEmpty) {
              return 'Bitte eine Klasse auswaehlen.';
            }
            return null;
          },
          onChanged: onClassChanged,
        ),
      ],
    );
  }
}

