import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/calendar_entry.dart';

const _prefsKey = 'calendar_accent_overrides';

/// Lokale Überschreibungen der Akzentfarbe pro [CalendarEntryType].
class CalendarAccentOverridesNotifier
    extends Notifier<Map<CalendarEntryType, Color>> {
  bool _hasLocalChange = false;

  @override
  Map<CalendarEntryType, Color> build() {
    unawaited(_load());
    return const {};
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;
    if (_hasLocalChange) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final next = <CalendarEntryType, Color>{};
      for (final e in decoded.entries) {
        CalendarEntryType? type;
        for (final t in CalendarEntryType.values) {
          if (t.name == e.key) {
            type = t;
            break;
          }
        }
        if (type == null) continue;
        final v = e.value;
        if (v is int) {
          next[type] = Color(v);
        }
      }
      state = next;
    } catch (_) {
      // Ignoriere kaputtes JSON
    }
  }

  Future<void> setOverride(CalendarEntryType type, Color color) async {
    _hasLocalChange = true;
    state = {...state, type: color};
    await _persist();
  }

  Future<void> clearOverride(CalendarEntryType type) async {
    _hasLocalChange = true;
    final next = Map<CalendarEntryType, Color>.from(state)..remove(type);
    state = next;
    await _persist();
  }

  /// Setzt den kompletten Override-State (z.B. zum Verwerfen ungespeicherter
  /// Live-Preview-Änderungen aus einem Bottom-Sheet).
  Future<void> replaceState(Map<CalendarEntryType, Color> next) async {
    _hasLocalChange = true;
    state = Map<CalendarEntryType, Color>.from(next);
    await _persist();
  }

  Future<void> _persist() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode({
      for (final e in state.entries) e.key.name: e.value.toARGB32(),
    } as Map<String, dynamic>);
    await preferences.setString(_prefsKey, encoded);
  }
}

final calendarAccentOverridesProvider =
    NotifierProvider<CalendarAccentOverridesNotifier,
        Map<CalendarEntryType, Color>>(CalendarAccentOverridesNotifier.new);

Color resolveCalendarEntryAccent(WidgetRef ref, CalendarEntry entry) {
  final overrides = ref.watch(calendarAccentOverridesProvider);
  return overrides[entry.type] ?? entry.accentColor;
}

Color resolveCalendarTypeAccent(
  WidgetRef ref,
  CalendarEntryType type,
  Color fallback,
) {
  final overrides = ref.watch(calendarAccentOverridesProvider);
  return overrides[type] ?? fallback;
}
