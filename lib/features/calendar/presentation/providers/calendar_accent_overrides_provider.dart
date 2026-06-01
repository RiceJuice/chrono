import 'dart:async';
import 'dart:convert';

import 'package:chronoapp/core/database/backend_enums.dart';
import 'package:chronoapp/core/theme/app_color_schemes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/filter/calendar_filter_text.dart';
import '../../domain/models/calendar_entry.dart';
import 'filter/calendar/calendar_filters_provider.dart';
import '../widgets/calendar_header/calendar_marker_color_palette.dart';

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
  final type = entry.type;
  if (type == CalendarEntryType.choir || type == CalendarEntryType.event) {
    final ownChoirs = ref.watch(
      calendarFiltersProvider.select((filters) => filters.defaultChoirs),
    );
    if (ownChoirs.isNotEmpty && !_entryMatchesUserChoir(entry.choir, ownChoirs)) {
      return _choirMarkerAccent(entry.choir);
    }
  }

  final overrides = ref.watch(calendarAccentOverridesProvider);
  return overrides[entry.type] ?? entry.accentColor;
}

/// Farbe des linken Streifens in Terminkarten — bei Chor-Beige besser lesbar.
Color resolveCalendarEntryLeadingIndicatorColor(
  WidgetRef ref,
  CalendarEntry entry,
) {
  final accent = resolveCalendarEntryAccent(ref, entry);
  if (_isChoirBeigeAccent(accent)) {
    return AppColorSchemes.eventCardDark;
  }
  return accent;
}

bool _isChoirBeigeAccent(Color color) =>
    color.toARGB32() == AppColorSchemes.accent.toARGB32();

bool _entryMatchesUserChoir(BackendChoir choir, List<String> userChoirs) {
  if (choir == BackendChoir.unknown) return true;
  final normalized = normalizeCalendarFilterText(choir.toBackend());
  return normalized != null && userChoirs.contains(normalized);
}

Color _choirMarkerAccent(BackendChoir choir) {
  const palette = CalendarMarkerColorPalette.standard;
  return palette.byChoir[choir] ?? palette.fallback;
}

Color resolveCalendarTypeAccent(
  WidgetRef ref,
  CalendarEntryType type,
  Color fallback,
) {
  final overrides = ref.watch(calendarAccentOverridesProvider);
  return overrides[type] ?? fallback;
}
