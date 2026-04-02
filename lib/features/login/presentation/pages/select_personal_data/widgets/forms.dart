import 'package:flutter/material.dart';

import '../../../widgets/login_input_decoration.dart';
import '../../../widgets/login_text_field.dart';

class LoginPersonalDataFields extends StatelessWidget {
  const LoginPersonalDataFields({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.selectedClass,
    required this.onClassChanged,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final String? selectedClass;
  final ValueChanged<String?> onClassChanged;

  static const _classes = ['5A', '6B', '7C', '8D', '9A', 'Q1', 'Q2'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LoginTextField(
          controller: firstNameController,
          hintText: 'Vorname',
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return 'Bitte Vornamen eingeben.';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),
        LoginTextField(
          controller: lastNameController,
          hintText: 'Nachname',
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return 'Bitte Nachnamen eingeben.';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          value: selectedClass,
          hint: const Text(
            'Klasse auswählen',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          dropdownColor: const Color(0xFF121212),
          iconEnabledColor: Colors.white,
          style: const TextStyle(color: Colors.white),
          decoration: loginInputDecoration('Klasse'),
          items: _classes
              .map(
                (item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item)),
              )
              .toList(),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Bitte eine Klasse auswaehlen.';
            }
            return null;
          },
          onChanged: (value) {
            onClassChanged(value);
          },
        ),
      ],
    );
  }
}

