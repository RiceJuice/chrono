import 'package:flutter/material.dart';

import '../../../widgets/login_text_field.dart';

class LoginRegisterFields extends StatelessWidget {
  const LoginRegisterFields({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.passwordConfirmController,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController passwordConfirmController;

  @override
  Widget build(BuildContext context) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    return Column(
      children: [
        const SizedBox(height: 80),
        LoginTextField(
          controller: emailController,
          hintText: 'E-mail',
          keyboardType: TextInputType.emailAddress,
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
        const SizedBox(height: 24),
        LoginTextField(
          controller: passwordController,
          hintText: 'Passwort',
          obscureText: true,
          validator: (value) {
            final input = value ?? '';
            if (input.isEmpty) {
              return 'Bitte Passwort eingeben.';
            }
            if (input.length < 8) {
              return 'Passwort muss mindestens 8 Zeichen haben.';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        LoginTextField(
          controller: passwordConfirmController,
          hintText: 'Passwort bestätigen',
          obscureText: true,
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
    );
  }
}

