import 'package:flutter/material.dart';

import '../utils/login_form_validation.dart';
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
    this.fieldErrors,
    this.firstNameFieldId,
    this.lastNameFieldId,
    this.onFieldEdited,
  });

  final GlobalKey<FormFieldState<dynamic>> firstNameFieldKey;
  final GlobalKey<FormFieldState<dynamic>> lastNameFieldKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final LoginFormFieldErrors? fieldErrors;
  final Object? firstNameFieldId;
  final Object? lastNameFieldId;
  final ValueChanged<Object>? onFieldEdited;

  @override
  Widget build(BuildContext context) {
    final double blockGap = LoginFlowSpacing.gapBetweenFields(context);
    final fieldErrors = this.fieldErrors;

    String? validateFirstName(String? value) {
      if ((value ?? '').trim().isEmpty) {
        return 'Bitte Vornamen eingeben.';
      }
      return null;
    }

    String? validateLastName(String? value) {
      if ((value ?? '').trim().isEmpty) {
        return 'Bitte Nachnamen eingeben.';
      }
      return null;
    }

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
            validator: fieldErrors != null && firstNameFieldId != null
                ? fieldErrors.merge(firstNameFieldId!, validateFirstName)
                : validateFirstName,
            onChanged: firstNameFieldId == null
                ? null
                : (_) => onFieldEdited?.call(firstNameFieldId!),
          ),
        ),
        SizedBox(height: blockGap),
        LoginLabeledField(
          label: 'Nachname',
          child: LoginTextField(
            formFieldKey: lastNameFieldKey,
            controller: lastNameController,
            hintText: 'Mustermann',
            validator: fieldErrors != null && lastNameFieldId != null
                ? fieldErrors.merge(lastNameFieldId!, validateLastName)
                : validateLastName,
            onChanged: lastNameFieldId == null
                ? null
                : (_) => onFieldEdited?.call(lastNameFieldId!),
          ),
        ),
      ],
    );
  }
}
