import 'package:flutter/material.dart';

import 'login_input_decoration.dart';

class LoginTextField extends StatelessWidget {
  const LoginTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.prefixIcon,
    this.contentPadding,
    this.formFieldKey,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final EdgeInsetsGeometry? contentPadding;
  final GlobalKey<FormFieldState<String>>? formFieldKey;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: formFieldKey,
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: loginInputDecoration(
        context,
        hintText,
        prefixIcon: prefixIcon,
        contentPadding: contentPadding,
      ),
    );
  }
}
