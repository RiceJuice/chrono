import 'package:flutter/material.dart';

import 'package:chronoapp/core/theme/theme_tokens.dart';

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
    return baseStyle?.copyWith(color: pastTextColor(context));
  }

  static Color pastTextColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.58);
  }

  static Color pastMutedTextColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.46);
  }

  static Color dimmedSurface(BuildContext context, Color base) {
    final overlay = Theme.of(
      context,
    ).colorScheme.surface.withValues(alpha: 0.5);
    return Color.alphaBlend(overlay, base);
  }

  /// Hintergrundfarbe für die farbigen Kalender-Karten über einer neutralen Surface.
  ///
  /// Motivation: In Dark-Mode wirken fixe Alpha-Overlays mit Akzentfarben oft
  /// “zu bunt”. Große UI-Stylesystems lösen das über semantische Rollen und
  /// passende Overlay-Stärken pro Theme (Light/Dark).
  static Color lessonCardBackgroundColor(BuildContext context, Color accent) {
    final scheme = Theme.of(context).colorScheme;
    final overlayAlpha = scheme.brightness == Brightness.dark
        ? AppOpacity.low * 0.5
        : AppOpacity.low;
    return Color.alphaBlend(
      accent.withValues(alpha: overlayAlpha),
      scheme.surfaceContainerHigh,
    );
  }

  static Color holidayBlue(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return scheme.brightness == Brightness.dark
        ? const Color(0xFF5B8FD8)
        : const Color(0xFF29509E);
  }

  static Color vacationRangeFill(BuildContext context) {
    return vacationRangeBarColor(context);
  }

  /// Neutraler Balken fuer Ferienbereiche im Kalenderkopf.
  ///
  /// Liegt bewusst zwischen `surfaceContainer` und `surfaceContainerHigh`:
  /// sichtbar als Range-Hintergrund, aber ruhiger als normale Cards/Inputs.
  static Color vacationRangeBarColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Color.lerp(
          scheme.surfaceContainer,
          scheme.surfaceContainerHighest,
          1,
        ) ??
        scheme.surfaceContainerHigh;
  }
}
