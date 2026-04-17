import 'package:flutter/material.dart';

import '../../../widgets/login_dropdown_field.dart';
import '../../../widgets/login_text_field.dart';

class LoginPersonalDataFields extends StatelessWidget {
  const LoginPersonalDataFields({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.selectedClass,
    required this.classOptions,
    required this.onClassChanged,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final String? selectedClass;
  final List<String> classOptions;
  final ValueChanged<String?> onClassChanged;

  @override
  Widget build(BuildContext context) {
    const fieldContentPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 15);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vorname',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        LoginTextField(
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
        const Text(
          'Nachname',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        LoginTextField(
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
        const Text(
          'Klasse',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        LoginDropdownField(
          selectedValue: selectedClass,
          options: classOptions,
          label: 'Klasse',
          hintText: 'z. B. 10a',
          leadingIcon: const Icon(Icons.school_outlined, color: Colors.white70),
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

