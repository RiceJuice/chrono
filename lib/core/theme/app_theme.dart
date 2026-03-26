import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const _darkBackground = Color(0xFF000000); // 000000
  static const _darkSurface = Color.fromARGB(255, 16, 16, 16); // 0D0D0D
  static const _accent = Color(0xFFCBBBA0); // CBBBA0
  static const _lightBackground = Color(0xFFFFFFFF); // FFFFFF
  static const _lightSurfaceContainer = Color(0xFFF6F6F6); // F6F6F6

  static ThemeData get dark {
    final scheme = ColorScheme.dark(
      primary: _accent,
      secondary: _accent,
      tertiary: _accent,
      surface: _darkSurface,
      onSurface: Colors.white,
      error: const Color(0xFFCF6679),
      onError: Colors.black,
    ).copyWith(
      surfaceContainer: _darkSurface,
      surfaceContainerLow: _darkSurface,
      surfaceContainerHigh: _darkSurface,
      surfaceContainerHighest: _darkSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: _darkBackground,
      canvasColor: _darkBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: _darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.libreBaskerville(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: _darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: Colors.white,
        textColor: Colors.white,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.10),
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: _accent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData get light {
    final scheme = ColorScheme.light(
      primary: _accent,
      secondary: _accent,
      tertiary: _accent,
      surface: Colors.white,
      onSurface: Colors.black,
      error: const Color(0xFFB00020),
      onError: Colors.white,
    ).copyWith(
      surfaceContainer: _lightSurfaceContainer,
      surfaceContainerLow: _lightSurfaceContainer,
      surfaceContainerHigh: _lightSurfaceContainer,
      surfaceContainerHighest: _lightSurfaceContainer,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: _lightBackground,
      canvasColor: _lightBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: _lightBackground,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.libreBaskerville(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: Colors.black,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.14),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.black.withValues(alpha: 0.08),
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
      ),
    );
  }
}

