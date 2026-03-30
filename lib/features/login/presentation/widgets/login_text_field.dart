import 'package:flutter/material.dart';

import 'login_input_decoration.dart';

class LoginTextField extends StatelessWidget {
  const LoginTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: loginInputDecoration(hintText),
    );
  }
}
