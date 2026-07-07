import 'dart:convert';

import 'package:flutter/material.dart';

import 'subject_color_codec.dart';

/// JSON in [profiles.calendar_preferences].
class CalendarPreferencesCodec {
  CalendarPreferencesCodec._();

  static const String subjectAccentsKey = 'subject_accents';
  static const String eventChangeNotificationsKey = 'event_change_notifications';
  static const String showMealImagesKey = 'show_meal_images';

  static Map<String, dynamic> decodeRoot(Object? raw) {
    if (raw == null) return <String, dynamic>{};

    if (raw is Map<String, dynamic>) {
      return Map<String, dynamic>.from(raw);
    }

    final text = raw.toString().trim();
    if (text.isEmpty) return <String, dynamic>{};

    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Ignoriere kaputtes JSON
    }
    return <String, dynamic>{};
  }

  static Map<String, Color> decodeSubjectAccents(Object? raw) {
    final accentsRaw = decodeRoot(raw)[subjectAccentsKey];
    if (accentsRaw is! Map) return const {};

    final out = <String, Color>{};
    for (final entry in accentsRaw.entries) {
      final subjectId = entry.key.toString().trim();
      if (subjectId.isEmpty) continue;
      final color = SubjectColorCodec.parseHex(entry.value);
      if (color != null) {
        out[subjectId] = color;
      }
    }
    return out;
  }

  static String encodeSubjectAccents(Map<String, Color> subjectAccents) {
    return encodeRootWithSubjectAccents(
      existingPreferences: null,
      subjectAccents: subjectAccents,
    );
  }

  static String encodeRootWithSubjectAccents({
    required Object? existingPreferences,
    required Map<String, Color> subjectAccents,
  }) {
    final root = decodeRoot(existingPreferences);
    if (subjectAccents.isEmpty) {
      root.remove(subjectAccentsKey);
    } else {
      root[subjectAccentsKey] = {
        for (final e in subjectAccents.entries)
          e.key: SubjectColorCodec.toHex(e.value),
      };
    }
    return jsonEncode(root);
  }

  /// Standard: aktiv, wenn der Schlüssel fehlt oder ungültig ist.
  static bool decodeEventChangeNotifications(Object? raw) {
    final value = decodeRoot(raw)[eventChangeNotificationsKey];
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    return true;
  }

  static String encodeEventChangeNotifications({
    required Object? existingPreferences,
    required bool enabled,
  }) {
    final root = decodeRoot(existingPreferences);
    if (enabled) {
      root.remove(eventChangeNotificationsKey);
    } else {
      root[eventChangeNotificationsKey] = false;
    }
    return jsonEncode(root);
  }

  /// Standard: aktiv, wenn der Schlüssel fehlt oder ungültig ist.
  static bool decodeShowMealImages(Object? raw) {
    final value = decodeRoot(raw)[showMealImagesKey];
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    return true;
  }

  static String encodeShowMealImages({
    required Object? existingPreferences,
    required bool enabled,
  }) {
    final root = decodeRoot(existingPreferences);
    if (enabled) {
      root.remove(showMealImagesKey);
    } else {
      root[showMealImagesKey] = false;
    }
    return jsonEncode(root);
  }

  static String mergeSubjectAccent({
    required Object? existingPreferences,
    required String subjectId,
    required Color color,
  }) {
    final current = decodeSubjectAccents(existingPreferences);
    final next = Map<String, Color>.from(current)..[subjectId] = color;
    return encodeRootWithSubjectAccents(
      existingPreferences: existingPreferences,
      subjectAccents: next,
    );
  }
}
