import 'package:flutter/material.dart';

import '../../../utils/login_form_validation.dart';
import '../../../widgets/login_flow_spacing.dart';
import '../../../widgets/login_labeled_field.dart';
import '../../../widgets/login_text_field.dart';

class CredentialFormFields extends StatelessWidget {
  const CredentialFormFields({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.passwordConfirmController,
    required this.requirePasswordConfirmation,
    required this.emailFieldKey,
    required this.passwordFieldKey,
    required this.passwordConfirmFieldKey,
    this.fieldErrors,
    this.emailFieldId,
    this.passwordFieldId,
    this.passwordConfirmFieldId,
    this.onFieldEdited,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController passwordConfirmController;
  final bool requirePasswordConfirmation;
  final GlobalKey<FormFieldState<dynamic>> emailFieldKey;
  final GlobalKey<FormFieldState<dynamic>> passwordFieldKey;
  final GlobalKey<FormFieldState<dynamic>> passwordConfirmFieldKey;
  final LoginFormFieldErrors? fieldErrors;
  final Object? emailFieldId;
  final Object? passwordFieldId;
  final Object? passwordConfirmFieldId;
  final ValueChanged<Object>? onFieldEdited;

  @override
  Widget build(BuildContext context) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    final double blockGap = LoginFlowSpacing.gapBetweenFields(context);
    final fieldErrors = this.fieldErrors;

    String? validateEmail(String? value) {
      final input = value?.trim() ?? '';
      if (input.isEmpty) return 'Bitte E-Mail eingeben.';
      if (!emailRegex.hasMatch(input)) {
        return 'Bitte eine gültige E-Mail eingeben.';
      }
      return null;
    }

    String? validatePassword(String? value) {
      final input = value ?? '';
      if (input.isEmpty) return 'Bitte Passwort eingeben.';
      if (requirePasswordConfirmation && input.length < 8) {
        return 'Passwort muss mindestens 8 Zeichen haben.';
      }
      return null;
    }

    String? validatePasswordConfirm(String? value) {
      final input = value ?? '';
      if (input.isEmpty) return 'Bitte Passwort bestätigen.';
      if (input != passwordController.text) {
        return 'Passwörter stimmen nicht überein.';
      }
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LoginLabeledField(
          label: 'E-Mail',
          child: LoginTextField(
            formFieldKey: emailFieldKey,
            controller: emailController,
            hintText: 'name@beispiel.de',
            keyboardType: TextInputType.emailAddress,
            validator: fieldErrors != null && emailFieldId != null
                ? fieldErrors.merge(emailFieldId!, validateEmail)
                : validateEmail,
            onChanged: emailFieldId == null
                ? null
                : (_) => onFieldEdited?.call(emailFieldId!),
          ),
        ),
        SizedBox(height: blockGap),
        LoginLabeledField(
          label: 'Passwort',
          child: LoginTextField(
            formFieldKey: passwordFieldKey,
            controller: passwordController,
            hintText: 'Passwort eingeben',
            obscureText: true,
            showPasswordVisibilityToggle: true,
            validator: fieldErrors != null && passwordFieldId != null
                ? fieldErrors.merge(passwordFieldId!, validatePassword)
                : validatePassword,
            onChanged: passwordFieldId == null
                ? null
                : (_) => onFieldEdited?.call(passwordFieldId!),
          ),
        ),
        if (requirePasswordConfirmation) ...[
          SizedBox(height: blockGap),
          LoginLabeledField(
            label: 'Passwort wiederholen',
            child: LoginTextField(
              formFieldKey: passwordConfirmFieldKey,
              controller: passwordConfirmController,
              hintText: 'Passwort bestätigen',
              obscureText: true,
              showPasswordVisibilityToggle: true,
              validator: fieldErrors != null && passwordConfirmFieldId != null
                  ? fieldErrors.merge(
                      passwordConfirmFieldId!,
                      validatePasswordConfirm,
                    )
                  : validatePasswordConfirm,
              onChanged: passwordConfirmFieldId == null
                  ? null
                  : (_) => onFieldEdited?.call(passwordConfirmFieldId!),
            ),
          ),
        ],
      ],
    );
  }
}
