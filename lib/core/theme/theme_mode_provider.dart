import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as fr;
import 'package:shared_preferences/shared_preferences.dart';

const _themeModePreferenceKey = 'app_theme_mode';

class AppThemeModeController extends fr.Notifier<ThemeMode> {
  bool _hasLocalChange = false;

  @override
  ThemeMode build() {
    unawaited(_loadThemeMode());
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    _hasLocalChange = true;
    state = themeMode;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeModePreferenceKey, state.name);
  }

  Future<void> setDarkMode(bool enabled) {
    return setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> _loadThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    final storedValue = preferences.getString(_themeModePreferenceKey);
    if (storedValue == null) return;
    if (_hasLocalChange) return;

    state = ThemeMode.values.firstWhere(
      (mode) => mode.name == storedValue,
      orElse: () => ThemeMode.system,
    );
  }
}

final appThemeModeProvider =
    fr.NotifierProvider<AppThemeModeController, ThemeMode>(
      AppThemeModeController.new,
    );

bool isDarkModeEnabled(ThemeMode themeMode, Brightness platformBrightness) {
  return switch (themeMode) {
    ThemeMode.dark => true,
    ThemeMode.light => false,
    ThemeMode.system => platformBrightness == Brightness.dark,
  };
}
