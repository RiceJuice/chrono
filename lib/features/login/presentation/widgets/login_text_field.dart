import 'package:flutter/material.dart';

import 'login_input_decoration.dart';
import 'password_visibility_toggle_button.dart';

class LoginTextField extends StatefulWidget {
  const LoginTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.showPasswordVisibilityToggle = false,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.contentPadding,
    this.formFieldKey,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool showPasswordVisibilityToggle;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final IconData? prefixIcon;
  final EdgeInsetsGeometry? contentPadding;
  final GlobalKey<FormFieldState<dynamic>>? formFieldKey;

  @override
  State<LoginTextField> createState() => _LoginTextFieldState();
}

class _LoginTextFieldState extends State<LoginTextField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  void didUpdateWidget(LoginTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.showPasswordVisibilityToggle &&
        oldWidget.obscureText != widget.obscureText) {
      _obscured = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final obscured = widget.showPasswordVisibilityToggle
        ? _obscured
        : widget.obscureText;

    return TextFormField(
      key: widget.formFieldKey,
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: obscured,
      validator: widget.validator,
      onChanged: widget.onChanged,
      style: TextStyle(color: colorScheme.onSurface),
      decoration: loginInputDecoration(
        context,
        widget.hintText,
        prefixIcon: widget.prefixIcon,
        contentPadding: widget.contentPadding,
        suffixIcon: widget.showPasswordVisibilityToggle
            ? PasswordVisibilityToggleButton(
                obscured: _obscured,
                iconColor: colorScheme.onSurfaceVariant,
                onPressed: () => setState(() => _obscured = !_obscured),
              )
            : null,
      ),
    );
  }
}
