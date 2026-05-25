import 'dart:convert';

/// Hilfen für Postgres-Enum-Arrays (`choir[]`, `voices[]` in `calendar_events`).
///
/// `calendar_series.choir` ist ein einzelnes Enum — dort Skalar-Strings nutzen.
class PostgresEnumArrayCodec {
  PostgresEnumArrayCodec._();

  /// Lokale SQLite-Speicherung (TEXT): JSON-Array, z. B. `["Giehl"]`.
  static String? encodeLocalSingle(String? label) {
    if (label == null || label.trim().isEmpty) return null;
    return jsonEncode([label.trim()]);
  }

  /// PostgREST erwartet für `text[]`/Enum-Arrays ein JSON-Array, nicht `"Giehl"`.
  static List<String>? toSupabaseArray(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      final out = value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
      return out.isEmpty ? null : out;
    }
    if (value is! String) return null;

    final tokens = decodeTokens(value);
    return tokens.isEmpty ? null : tokens;
  }

  /// Erstes Element für Domain-Enums (ein Chor pro Termin).
  static String? decodeFirstToken(String? raw) {
    final tokens = decodeTokens(raw);
    return tokens.isEmpty ? null : tokens.first;
  }

  static List<String> decodeTokens(String? raw) {
    if (raw == null) return const <String>[];
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return const <String>[];

    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) {
          return _stringListFromObjects(decoded);
        }
      } catch (_) {
        // Fallback unten.
      }
    }

    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      return _splitCsv(trimmed.substring(1, trimmed.length - 1));
    }

    if (trimmed.contains(',')) {
      return _splitCsv(trimmed);
    }

    return [trimmed];
  }

  static List<String> _stringListFromObjects(List<Object?> values) {
    return values
        .map(_normalizeToken)
        .whereType<String>()
        .toList(growable: false);
  }

  static List<String> _splitCsv(String value) {
    return value
        .split(',')
        .map(_normalizeToken)
        .whereType<String>()
        .toList(growable: false);
  }

  static String? _normalizeToken(Object? value) {
    if (value == null) return null;
    var text = value.toString().trim();
    if (text.isEmpty) return null;
    if (text.startsWith('"') && text.endsWith('"') && text.length >= 2) {
      text = text.substring(1, text.length - 1).trim();
    }
    if (text.startsWith("'") && text.endsWith("'") && text.length >= 2) {
      text = text.substring(1, text.length - 1).trim();
    }
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return text;
  }
}
