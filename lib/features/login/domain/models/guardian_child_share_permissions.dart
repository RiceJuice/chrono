import 'dart:convert';

/// Freigaben des Kindes für einen bestätigten Eltern-Zugriff.
///
/// Schlüssel entsprechen [CalendarVisibility] (`school`, `meal`, `choir`)
/// plus `homework`. Weitere Keys können ohne Schema-Änderung ergänzt werden.
class GuardianChildSharePermissions {
  const GuardianChildSharePermissions({
    this.shareSchool = false,
    this.shareMeal = false,
    this.shareChoir = false,
    this.shareHomework = false,
    this.extra = const {},
  });

  final bool shareSchool;
  final bool shareMeal;
  final bool shareChoir;
  final bool shareHomework;

  /// Zukünftige Freigaben ohne Migration.
  final Map<String, bool> extra;

  static const schoolKey = 'school';
  static const mealKey = 'meal';
  static const choirKey = 'choir';
  static const homeworkKey = 'homework';

  static const minimal = GuardianChildSharePermissions();

  bool get sharesAnyCalendar => shareSchool || shareMeal || shareChoir;

  bool get sharesAnything =>
      shareSchool || shareMeal || shareChoir || shareHomework;

  bool isEnabled(String key) {
    switch (key) {
      case schoolKey:
        return shareSchool;
      case mealKey:
        return shareMeal;
      case choirKey:
        return shareChoir;
      case homeworkKey:
        return shareHomework;
      default:
        return extra[key] ?? false;
    }
  }

  GuardianChildSharePermissions copyWith({
    bool? shareSchool,
    bool? shareMeal,
    bool? shareChoir,
    bool? shareHomework,
    Map<String, bool>? extra,
  }) {
    return GuardianChildSharePermissions(
      shareSchool: shareSchool ?? this.shareSchool,
      shareMeal: shareMeal ?? this.shareMeal,
      shareChoir: shareChoir ?? this.shareChoir,
      shareHomework: shareHomework ?? this.shareHomework,
      extra: extra ?? this.extra,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      schoolKey: shareSchool,
      mealKey: shareMeal,
      choirKey: shareChoir,
      homeworkKey: shareHomework,
    };
    for (final entry in extra.entries) {
      if (entry.key == schoolKey ||
          entry.key == mealKey ||
          entry.key == choirKey ||
          entry.key == homeworkKey) {
        continue;
      }
      map[entry.key] = entry.value;
    }
    return map;
  }

  factory GuardianChildSharePermissions.fromJson(Object? raw) {
    final map = _decodeToMap(raw);
    if (map == null) return minimal;
    final extra = <String, bool>{};
    for (final entry in map.entries) {
      final key = entry.key.toString();
      if (key == schoolKey ||
          key == mealKey ||
          key == choirKey ||
          key == homeworkKey) {
        continue;
      }
      extra[key] = _readBool(entry.value);
    }

    return GuardianChildSharePermissions(
      shareSchool: _readBool(map[schoolKey]),
      shareMeal: _readBool(map[mealKey]),
      shareChoir: _readBool(map[choirKey]),
      shareHomework: _readBool(map[homeworkKey]),
      extra: extra,
    );
  }

  /// PowerSync speichert JSONB-Spalten als Text; Supabase liefert oft eine Map.
  static Map<String, dynamic>? _decodeToMap(Object? raw) {
    if (raw == null) return null;
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty || trimmed == 'null') return null;
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static bool _readBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase();
    return text == 'true' || text == '1';
  }

  @override
  bool operator ==(Object other) {
    return other is GuardianChildSharePermissions &&
        other.shareSchool == shareSchool &&
        other.shareMeal == shareMeal &&
        other.shareChoir == shareChoir &&
        other.shareHomework == shareHomework &&
        _mapEquals(other.extra, extra);
  }

  @override
  int get hashCode => Object.hash(
        shareSchool,
        shareMeal,
        shareChoir,
        shareHomework,
        Object.hashAll(extra.entries),
      );

  static bool _mapEquals(Map<String, bool> a, Map<String, bool> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}

/// Bekannte Freigabe-Optionen für UI (Reihenfolge für Walkthrough/Einstellungen).
const guardianSharePermissionOptions = <({String key, String label})>[
  (key: GuardianChildSharePermissions.schoolKey, label: 'Stundenplan'),
  (key: GuardianChildSharePermissions.mealKey, label: 'Speiseplan'),
  (key: GuardianChildSharePermissions.choirKey, label: 'Chor'),
  (key: GuardianChildSharePermissions.homeworkKey, label: 'Aufgaben'),
];
