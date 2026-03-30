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
    return Column(
      children: [
        LoginTextField(
          controller: emailController,
          hintText: 'E-mail',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        LoginTextField(
          controller: passwordController,
          hintText: 'Passwort',
          obscureText: true,
        ),
        const SizedBox(height: 12),
        LoginTextField(
          controller: passwordConfirmController,
          hintText: 'Passwort bestätigen',
          obscureText: true,
        ),
      ],
    );
  }
}
