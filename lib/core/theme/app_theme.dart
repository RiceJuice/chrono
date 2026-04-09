import 'package:flutter/material.dart';

import 'app_color_schemes.dart';
import 'app_component_themes.dart';
import 'app_text_theme.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final scheme = AppColorSchemes.darkScheme();
    final textTheme = AppTextThemes.build(scheme);
    return _buildThemeData(
      scheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColorSchemes.darkBackground,
    );
  }

  static ThemeData get light {
    final scheme = AppColorSchemes.lightScheme();
    final textTheme = AppTextThemes.build(scheme);
    return _buildThemeData(
      scheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColorSchemes.lightBackground,
    );
  }

  static ThemeData _buildThemeData({
    required ColorScheme scheme,
    required TextTheme textTheme,
    required Color scaffoldBackgroundColor,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      textTheme: textTheme,
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      canvasColor: scaffoldBackgroundColor,
      appBarTheme: AppComponentThemes.appBarTheme(scheme),
      cardTheme: AppComponentThemes.cardTheme(scheme),
      listTileTheme: AppComponentThemes.listTileTheme(scheme),
      dividerTheme: AppComponentThemes.dividerTheme(scheme),
      iconTheme: AppComponentThemes.iconTheme(scheme),
      elevatedButtonTheme: AppComponentThemes.elevatedButtonTheme(scheme),
      filledButtonTheme: AppComponentThemes.filledButtonTheme(scheme),
      textButtonTheme: AppComponentThemes.textButtonTheme(scheme),
      inputDecorationTheme: AppComponentThemes.inputDecorationTheme(scheme),
      chipTheme: AppComponentThemes.chipTheme(scheme),
      bottomSheetTheme: AppComponentThemes.bottomSheetTheme(scheme),
      navigationBarTheme: AppComponentThemes.navigationBarTheme(scheme),
    );
  }
}
