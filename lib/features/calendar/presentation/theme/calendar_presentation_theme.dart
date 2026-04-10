import 'package:flutter/material.dart';

class CalendarPresentationTheme {
  CalendarPresentationTheme._();

  static Color todayAccentColor(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }

  static TextStyle? todayHeaderTextStyle(
    BuildContext context,
    TextStyle? baseStyle,
  ) {
    return baseStyle?.copyWith(
      color: todayAccentColor(context),
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle? pastHeaderTextStyle(
    BuildContext context,
    TextStyle? baseStyle,
  ) {
    return baseStyle?.copyWith(
      color: pastTextColor(context),
    );
  }

  static Color pastTextColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.58);
  }

  static Color pastMutedTextColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.46);
  }

  static Color dimmedSurface(BuildContext context, Color base) {
    final overlay = Theme.of(context).colorScheme.surface.withValues(alpha: 0.5);
    return Color.alphaBlend(overlay, base);
  }
}
