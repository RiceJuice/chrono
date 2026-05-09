import 'package:flutter/material.dart';

import 'login_text_field.dart';

class LoginPersonalNameFields extends StatelessWidget {
  const LoginPersonalNameFields({
    super.key,
    required this.firstNameFieldKey,
    required this.lastNameFieldKey,
    required this.firstNameController,
    required this.lastNameController,
  });

  final GlobalKey<FormFieldState<dynamic>> firstNameFieldKey;
  final GlobalKey<FormFieldState<dynamic>> lastNameFieldKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;

  @override
  Widget build(BuildContext context) {
    const fieldContentPadding =
        EdgeInsets.symmetric(horizontal: 12, vertical: 15);
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
      ],
    );
  }
}
