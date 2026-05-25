import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:flutter/material.dart';

/// Randloses Textfeld für Insel-Gruppen (ohne eigenen Hintergrund).
class EventFormTextField extends StatelessWidget {
  const EventFormTextField({
    super.key,
    required this.hint,
    required this.controller,
    this.maxLines = 1,
    this.textInputAction,
  });

  final String hint;
  final TextEditingController controller;
  final int maxLines;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return TextField(
      controller: controller,
      maxLines: maxLines,
      textInputAction: textInputAction,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: theme.textTheme.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.m + 2,
        ),
      ),
    );
  }
}
