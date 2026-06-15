import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:flutter/material.dart';

/// Social-Login-Buttons: etwas großzügiger als Textfelder.
const EdgeInsets kLoginSocialButtonPadding = EdgeInsets.symmetric(
  horizontal: 16,
  vertical: 18,
);

InputDecoration loginInputDecoration(
  BuildContext context,
  String hintText, {
  IconData? prefixIcon,
  Widget? suffixIcon,
  EdgeInsetsGeometry? contentPadding,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final enabledBorder = OutlineInputBorder(
    borderRadius: AppSquircle.borderRadius(AppRadius.s),
    borderSide: BorderSide(
      color: colorScheme.surfaceContainerHighest,
      width: 1,
    ),
  );
  final focusedBorder = OutlineInputBorder(
    borderRadius: AppSquircle.borderRadius(AppRadius.s),
    borderSide: BorderSide(
      color: colorScheme.surfaceContainerHighest,
      width: 2.2,
    ),
  );
  final errorBorder = OutlineInputBorder(
    borderRadius: AppSquircle.borderRadius(AppRadius.s),
    borderSide: BorderSide(
      color: colorScheme.error,
      width: 1.8,
    ),
  );
  final focusedErrorBorder = OutlineInputBorder(
    borderRadius: AppSquircle.borderRadius(AppRadius.s),
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
        : Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              prefixIcon,
              size: 17,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
            ),
          ),
    suffixIcon: suffixIcon,
    border: enabledBorder,
    enabledBorder: enabledBorder,
    focusedBorder: focusedBorder,
    errorBorder: errorBorder,
    focusedErrorBorder: focusedErrorBorder,
  );
}
