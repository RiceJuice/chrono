import 'package:flutter/material.dart';

class AppColorSchemes {
  AppColorSchemes._();

  static const accent = Color(0xFFCBBBA0); // primary accent color
  static const darkBackground = Color(0xFF000000);
  static const darkSurface = Color(0xFF0F0F0F);
  static const darkSurfaceContainer = Color(0xFF0F0F0F);
  static const darkSurfaceContainerHighest = Color.fromARGB(255, 32, 32, 32);

  static const lightAccent = Color(0xFF273655);
  static const lightBackground = Color(0xFFFFFFFF);
  static const lightSurfaceContainer = Color.fromARGB(255, 248, 248, 248);
  static const lightSurfaceContainerHighest = Color(0xFFE7E7E7);

  static const eventCardDark = Color(0xFF111827);
  static const toastSuccess = Color(0xFF2E7D32);
  static const toastInfo = Color(0xFF1565C0);

  static ColorScheme darkScheme() {
    return const ColorScheme.dark(
      primary: accent,
      secondary: eventCardDark,
      tertiary: accent,
      surface: darkSurface,
      onSurface: Colors.white,
      error: Color(0xFFCF6679),
      onError: Colors.black,
      background: darkBackground, // ignore: deprecated_member_use
    ).copyWith(
      surfaceContainer: darkSurfaceContainer,
      surfaceContainerLow: darkSurfaceContainer,
      surfaceContainerHigh: darkSurfaceContainer,
      surfaceContainerHighest: darkSurfaceContainerHighest,
      tertiaryContainer: eventCardDark,
      surfaceTint: Colors.transparent,
    );
  }

  static ColorScheme lightScheme() {
    return const ColorScheme.light(
      primary: accent,
      secondary: lightAccent,
      tertiary: lightAccent,
      surface: Colors.white,
      onSurface: Colors.black,
      error: Color(0xFFB00020),
      onError: Colors.white,
    ).copyWith(
      surfaceContainer: lightSurfaceContainer,
      surfaceContainerLow: lightSurfaceContainer,
      surfaceContainerHigh: lightSurfaceContainer,
      surfaceContainerHighest: lightSurfaceContainerHighest,
      tertiaryContainer: lightSurfaceContainerHighest,
    );
  }
}
