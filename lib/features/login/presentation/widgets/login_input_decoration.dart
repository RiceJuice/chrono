import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:flutter/material.dart';

InputDecoration loginInputDecoration(
  BuildContext context,
  String hintText, {
  IconData? prefixIcon,
  EdgeInsetsGeometry? contentPadding,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final enabledBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.s),
    borderSide: BorderSide(
      color: colorScheme.surfaceContainerHighest,
      width: 1,
    ),
  );
  final focusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.s),
    borderSide: BorderSide(
      color: colorScheme.surfaceContainerHighest,
      width: 2.2,
    ),
  );
  final errorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.s),
    borderSide: BorderSide(
      color: colorScheme.error,
      width: 1.8,
    ),
  );
  final focusedErrorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.s),
    borderSide: BorderSide(
      color: colorScheme.error,
      width: 2.2,
    ),
  );

  return InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(
      fontSize: 13,
      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
    ),
    filled: true,
    fillColor: colorScheme.surfaceContainer,
    contentPadding: contentPadding ?? AppInsets.inputContent,
    prefixIcon: prefixIcon == null
        ? null
        : Icon(prefixIcon, color: colorScheme.onSurfaceVariant),
    border: enabledBorder,
    enabledBorder: enabledBorder,
    focusedBorder: focusedBorder,
    errorBorder: errorBorder,
    focusedErrorBorder: focusedErrorBorder,
  );
}
