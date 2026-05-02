import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextThemes {
  AppTextThemes._();

  /// [ListTile] (Material 3) nutzt u. a. `defaults.subtitleTextStyle!.textBaseline!`.
  /// Google Fonts / angepasste Styles setzen oft kein [TextStyle.textBaseline] — das löst dann einen Absturz aus.
  static TextStyle? _withAlphabeticBaseline(TextStyle? style) {
    if (style == null) return null;
    if (style.textBaseline != null) return style;
    return style.copyWith(textBaseline: TextBaseline.alphabetic);
  }

  static TextTheme _ensureTextBaselines(TextTheme theme) {
    return theme.copyWith(
      bodyLarge: _withAlphabeticBaseline(theme.bodyLarge),
      bodyMedium: _withAlphabeticBaseline(theme.bodyMedium),
      bodySmall: _withAlphabeticBaseline(theme.bodySmall),
      labelSmall: _withAlphabeticBaseline(theme.labelSmall),
      titleLarge: _withAlphabeticBaseline(theme.titleLarge),
      titleMedium: _withAlphabeticBaseline(theme.titleMedium),
      titleSmall: _withAlphabeticBaseline(theme.titleSmall),
      labelLarge: _withAlphabeticBaseline(theme.labelLarge),
      displaySmall: _withAlphabeticBaseline(theme.displaySmall),
      headlineLarge: _withAlphabeticBaseline(theme.headlineLarge),
    );
  }

  static TextTheme build(ColorScheme scheme) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
    ).textTheme;

    final themed = base.copyWith(
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

    return _ensureTextBaselines(themed);
  }
}
