import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextThemes {
  AppTextThemes._();

  static TextTheme build(ColorScheme scheme) {
    final base = ThemeData(brightness: scheme.brightness).textTheme;

    return base.copyWith(
      titleLarge: GoogleFonts.libreBaskerville(
        textStyle: base.titleLarge?.copyWith(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: scheme.onSurface,
        ),
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 13,
      ),
      displaySmall: GoogleFonts.libreBaskerville(
        textStyle: base.displaySmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      headlineLarge: GoogleFonts.libreBaskerville(
        textStyle: base.headlineLarge?.copyWith(
          fontSize: 36,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}
