import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as fr;
import 'package:shared_preferences/shared_preferences.dart';

const _calendarViewModePreferenceKey = 'calendar_view_mode';

CalendarViewMode? _bootstrappedCalendarViewMode;

enum CalendarViewMode { day, week }

class CalendarViewOption {
  const CalendarViewOption({
    required this.mode,
    required this.label,
    required this.icon,
  });

  final CalendarViewMode mode;
  final String label;
  final IconData icon;
}

const calendarViewOptions = <CalendarViewOption>[
  CalendarViewOption(
    mode: CalendarViewMode.day,
    label: 'Tag',
    icon: Icons.view_day_outlined,
  ),
  CalendarViewOption(
    mode: CalendarViewMode.week,
    label: 'Woche',
    icon: Icons.view_week_outlined,
  ),
];

CalendarViewMode get kDefaultCalendarViewMode => calendarViewOptions.first.mode;

/// Nur Modi, die in [calendarViewOptions] registriert sind, werden geladen/gespeichert.
bool isRegisteredCalendarViewMode(CalendarViewMode mode) =>
    calendarViewOptions.any((option) => option.mode == mode);

/// Parst [CalendarViewMode.name]; unbekannte oder leere Werte → null.
CalendarViewMode? tryParseCalendarViewMode(String? stored) {
  if (stored == null || stored.isEmpty) return null;
  for (final mode in CalendarViewMode.values) {
    if (mode.name == stored) return mode;
  }
  return null;
}

/// Gespeicherten Modus auflösen; veraltete oder noch nicht freigeschaltete Modi → Default.
CalendarViewMode resolveCalendarViewMode(String? stored) {
  final parsed = tryParseCalendarViewMode(stored);
  if (parsed != null && isRegisteredCalendarViewMode(parsed)) {
    return parsed;
  }
  return kDefaultCalendarViewMode;
}

Future<CalendarViewMode> loadStoredCalendarViewMode() async {
  final preferences = await SharedPreferences.getInstance();
  return resolveCalendarViewMode(
    preferences.getString(_calendarViewModePreferenceKey),
  );
}

/// Lädt den Modus vor dem ersten Frame (Splash / Ladescreen).
Future<CalendarViewMode> bootstrapCalendarViewMode() async {
  final mode = await loadStoredCalendarViewMode();
  _bootstrappedCalendarViewMode = mode;
  return mode;
}

/// Für Kalender-Preload in [_finishStartup], bevor der Provider den Cache leert.
CalendarViewMode bootstrappedCalendarViewModeOrDefault() =>
    _bootstrappedCalendarViewMode ?? kDefaultCalendarViewMode;

class CalendarViewModeController extends fr.Notifier<CalendarViewMode> {
  bool _hasLocalChange = false;

  @override
  CalendarViewMode build() {
    final bootstrapped = _bootstrappedCalendarViewMode;
    if (bootstrapped != null) {
      _bootstrappedCalendarViewMode = null;
      return bootstrapped;
    }
    unawaited(_load());
    return kDefaultCalendarViewMode;
  }

  void update(CalendarViewMode mode) {
    if (state == mode || !isRegisteredCalendarViewMode(mode)) return;
    _hasLocalChange = true;
    state = mode;
    unawaited(_persist(mode));
  }

  Future<void> _load() async {
    if (_hasLocalChange) return;
    final loaded = await loadStoredCalendarViewMode();
    if (state != loaded) {
      state = loaded;
    }
  }

  Future<void> _persist(CalendarViewMode mode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_calendarViewModePreferenceKey, mode.name);
  }
}

final calendarViewModeProvider =
    fr.NotifierProvider<CalendarViewModeController, CalendarViewMode>(
      CalendarViewModeController.new,
    );

CalendarViewOption calendarViewOptionFor(CalendarViewMode mode) {
  return calendarViewOptions.firstWhere(
    (option) => option.mode == mode,
    orElse: () => calendarViewOptions.first,
  );
}
