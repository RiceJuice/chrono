import 'package:flutter/material.dart';

import 'theme_tokens.dart';

class AppComponentThemes {
  AppComponentThemes._();

  static AppBarTheme appBarTheme(ColorScheme scheme) {
    final fg = scheme.onSurface;
    return AppBarTheme(
      backgroundColor: scheme.surfaceContainer,
      foregroundColor: fg,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: fg,
        letterSpacing: 0.2,
      ),
    );
  }

  static CardThemeData cardTheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    return CardThemeData(
      color: scheme.surfaceContainer,
      elevation: isDark ? 0 : 6,
      shadowColor: isDark ? null : Colors.black.withValues(alpha: 0.14),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.l),
      ),
    );
  }

  static ListTileThemeData listTileTheme(ColorScheme scheme) {
    return ListTileThemeData(
      iconColor: scheme.onSurface,
      textColor: scheme.onSurface,
    );
  }

  static DividerThemeData dividerTheme(ColorScheme scheme) {
    final alpha = scheme.brightness == Brightness.dark ? 0.20 : 0.15;
    return DividerThemeData(
      color: scheme.onSurface.withValues(alpha: alpha),
      thickness: 0.5,
      space: 1,
    );
  }

  static IconThemeData iconTheme(ColorScheme scheme) {
    return IconThemeData(color: scheme.onSurface);
  }

  static ElevatedButtonThemeData elevatedButtonTheme(ColorScheme scheme) {
    return ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.primary.withValues(alpha: AppOpacity.disabled);
          }
          return scheme.primary;
        }),
        foregroundColor: const WidgetStatePropertyAll(Colors.black),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        padding: const WidgetStatePropertyAll(AppInsets.buttonContentWide),
        elevation: const WidgetStatePropertyAll(0),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.s),
          ),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(0, 60)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  static FilledButtonThemeData filledButtonTheme(ColorScheme scheme) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
        ),
      ),
    );
  }

  static TextButtonThemeData textButtonTheme(ColorScheme scheme) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: scheme.primary),
    );
  }

  static InputDecorationTheme inputDecorationTheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    const inputBorderWidth = 1.0;
    final inputBorderSide = BorderSide(
      color: scheme.onSurface.withValues(
        alpha: isDark ? AppOpacity.muted : AppOpacity.low,
      ),
      width: inputBorderWidth,
    );

    return InputDecorationTheme(
      hintStyle: TextStyle(
        color: scheme.onSurface.withValues(alpha: AppOpacity.secondaryContent),
        fontSize: 13,
      ),
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      contentPadding: AppInsets.inputContent,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.m),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.s),
        borderSide: inputBorderSide,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.s),
        borderSide: inputBorderSide,
      ),
    );
  }

  static ChipThemeData chipTheme(ColorScheme scheme) {
    return ChipThemeData(
      selectedColor: scheme.primary,
      backgroundColor: scheme.surfaceContainerHighest,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      labelStyle: TextStyle(color: scheme.onSurface),
      secondaryLabelStyle: TextStyle(color: scheme.onPrimary),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      brightness: scheme.brightness,
    );
  }

  static BottomSheetThemeData bottomSheetTheme(ColorScheme scheme) {
    return BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainer,
      modalBackgroundColor: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: scheme.outlineVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
    );
  }

  static NavigationBarThemeData navigationBarTheme(ColorScheme scheme) {
    return NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
      indicatorColor: Colors.transparent,
      elevation: 0,
      height: 50,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: scheme.primary,
          );
        }
        return TextStyle(
          fontSize: 12,
          color: scheme.onSurfaceVariant,
        );
      }),
    );
  }
}
