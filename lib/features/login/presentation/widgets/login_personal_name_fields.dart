import 'package:flutter/material.dart';

import 'login_flow_spacing.dart';
import 'login_labeled_field.dart';
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
    final double blockGap = LoginFlowSpacing.gapBetweenFields(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LoginLabeledField(
          label: 'Vorname',
          child: LoginTextField(
            formFieldKey: firstNameFieldKey,
            controller: firstNameController,
            hintText: 'Max',
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Bitte Vornamen eingeben.';
              }
              return null;
            },
          ),
        ),
        SizedBox(height: blockGap),
        LoginLabeledField(
          label: 'Nachname',
          child: LoginTextField(
            formFieldKey: lastNameFieldKey,
            controller: lastNameController,
            hintText: 'Mustermann',
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Bitte Nachnamen eingeben.';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}
