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
  final String selectedClass;
  final ValueChanged<String> onClassChanged;

  static const _classes = ['Klasse', '5A', '6B', '7C', '8D', '9A', 'Q1', 'Q2'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LoginTextField(controller: firstNameController, hintText: 'Vorname'),
        const SizedBox(height: 12),
        LoginTextField(controller: lastNameController, hintText: 'Nachname'),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: selectedClass,
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
          onChanged: (value) {
            if (value != null) {
              onClassChanged(value);
            }
          },
        ),
      ],
    );
  }
}
