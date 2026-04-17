import 'package:flutter/material.dart';

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
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController passwordConfirmController;
  final bool requirePasswordConfirmation;
  final GlobalKey<FormFieldState<String>> emailFieldKey;
  final GlobalKey<FormFieldState<String>> passwordFieldKey;
  final GlobalKey<FormFieldState<String>> passwordConfirmFieldKey;

  @override
  Widget build(BuildContext context) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 80),
        const Text(
          'E-Mail',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        LoginTextField(
          formFieldKey: emailFieldKey,
          controller: emailController,
          hintText: 'name@beispiel.de',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          validator: (value) {
            final input = value?.trim() ?? '';
            if (input.isEmpty) {
              return 'Bitte E-Mail eingeben.';
            }
            if (!emailRegex.hasMatch(input)) {
              return 'Bitte eine gültige E-Mail eingeben.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Passwort',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        LoginTextField(
          formFieldKey: passwordFieldKey,
          controller: passwordController,
          hintText: 'Passwort eingeben',
          obscureText: true,
          prefixIcon: Icons.lock_outline_rounded,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          validator: (value) {
            final input = value ?? '';
            if (input.isEmpty) {
              return 'Bitte Passwort eingeben.';
            }
            if (requirePasswordConfirmation && input.length < 8) {
              return 'Passwort muss mindestens 8 Zeichen haben.';
            }
            return null;
          },
        ),
        if (requirePasswordConfirmation) ...[
          const SizedBox(height: 10),
          const Text(
            'Passwort wiederholen',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          LoginTextField(
            formFieldKey: passwordConfirmFieldKey,
            controller: passwordConfirmController,
            hintText: 'Passwort bestätigen	',
            obscureText: true,
            prefixIcon: Icons.lock_reset_rounded,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            validator: (value) {
              final input = value ?? '';
              if (input.isEmpty) {
                return 'Bitte Passwort bestätigen.';
              }
              if (input != passwordController.text) {
                return 'Passwörter stimmen nicht überein.';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }
}
