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
  final GlobalKey<FormFieldState<dynamic>> emailFieldKey;
  final GlobalKey<FormFieldState<dynamic>> passwordFieldKey;
  final GlobalKey<FormFieldState<dynamic>> passwordConfirmFieldKey;

  @override
  Widget build(BuildContext context) {
    final Color labelColor = Theme.of(context).colorScheme.onSurface;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    final double h = MediaQuery.sizeOf(context).height;
    final double topGap = (h * 0.028).clamp(6.0, 24.0);
    final double blockGap = (h * 0.02).clamp(12.0, 20.0);
    final double confirmGap = (h * 0.014).clamp(8.0, 14.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: topGap),
        Text(
          'E-Mail',
          style: TextStyle(
            color: labelColor,
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
        SizedBox(height: blockGap),
        Text(
          'Passwort',
          style: TextStyle(
            color: labelColor,
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
          SizedBox(height: confirmGap),
          Text(
            'Passwort wiederholen',
            style: TextStyle(
              color: labelColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          LoginTextField(
            formFieldKey: passwordConfirmFieldKey,
            controller: passwordConfirmController,
            hintText: 'Passwort bestätigen',
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
