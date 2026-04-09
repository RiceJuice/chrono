import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sqlite3/common.dart' as sqlite;

import '../../../core/database/backend_enums.dart';
import '../domain/models/calendar_entry.dart';

class CalendarEntryMapper {
  CalendarEntryMapper._();

  static CalendarEntry fromRow(sqlite.Row row) {
    final rawType = _asString(_rowValue(row, 'type'));
    final backendType = CalendarEventTypeCodec.fromBackend(rawType);
    if (rawType != null) {
      debugPrint(
        '[CalendarEntryMapper] type raw="$rawType" mapped="$backendType"',
      );
    }
    if (backendType == CalendarEventType.unknown && rawType != null) {
      debugPrint('[CalendarEntryMapper] Unbekannter type-Wert: "$rawType" -> fallback event');
    }
    final eventName = _asString(_rowValue(row, 'event_name')) ?? '';
    final description = _asString(_rowValue(row, 'description'));
    final choirRaw = _asString(_rowValue(row, 'choir'));
    final voicesRaw = _asString(_rowValue(row, 'voices'));
    final schoolTrackRaw = _asString(_rowValue(row, 'schooltrack'));
    final choir = BackendChoirCodec.fromBackend(choirRaw);
    final voice = BackendVoiceCodec.fromBackend(voicesRaw);
    final schoolTrack = BackendSchoolTrackCodec.fromBackend(schoolTrackRaw);
    final domainType = _toDomainType(backendType);
    final imagePaths = _decodeStringList(_rowValue(row, 'image_paths'));

    if (choir == BackendChoir.unknown && choirRaw != null) {
      debugPrint('[CalendarEntryMapper] Unbekannter choir-Wert: "$choirRaw"');
    }
    if (voice == BackendVoice.unknown && voicesRaw != null) {
      debugPrint('[CalendarEntryMapper] Unbekannter voices-Wert: "$voicesRaw"');
    }
    if (schoolTrack == BackendSchoolTrack.unknown && schoolTrackRaw != null) {
      debugPrint(
        '[CalendarEntryMapper] Unbekannter schooltrack-Wert: "$schoolTrackRaw"',
      );
    }

    return CalendarEntry(
      id: _rowValue(row, 'id').toString(),
      eventName: eventName,
      description: description,
      location: _asString(_rowValue(row, 'location')),
      startTime: _parseDateTime(_rowValue(row, 'start_time')),
      endTime: _parseDateTime(_rowValue(row, 'end_time')),
      imageUrls: null,
      accentColor: _defaultAccentColorForType(domainType),
      type: domainType,
      choir: choir,
      voice: voice,
      schoolTrack: schoolTrack,
      className: _asString(_rowValue(row, 'class')),
      imagePaths: imagePaths,
      tags: null,
      userId: null,
    );
  }

  static Object? _rowValue(sqlite.Row row, String key) {
    try {
      return row[key];
    } catch (_) {
      return null;
    }
  }

  static String? _asString(Object? value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static DateTime _parseDateTime(Object? value) {
    final s = _asString(value);
    if (s == null || s.isEmpty) {
      throw FormatException('start/end_time fehlt oder leer');
    }
    final normalized = s.contains('T') ? s : s.replaceFirst(' ', 'T');
    return DateTime.parse(normalized);
  }

  static CalendarEntryType _toDomainType(CalendarEventType type) {
    return switch (type) {
      CalendarEventType.lesson => CalendarEntryType.lesson,
      CalendarEventType.meal => CalendarEntryType.meal,
      CalendarEventType.event => CalendarEntryType.event,
      CalendarEventType.choir => CalendarEntryType.choir,
      CalendarEventType.unknown => CalendarEntryType.event,
    };
  }

  static Color _defaultAccentColorForType(CalendarEntryType type) {
    return switch (type) {
      CalendarEntryType.lesson => const Color(0xFF3B82F6),
      CalendarEntryType.meal => const Color(0xFFF59E0B),
      CalendarEntryType.event => const Color(0xFF8B5CF6),
      CalendarEntryType.choir => const Color(0xFF10B981),
    };
  }

  static List<String>? _decodeStringList(Object? raw) {
    if (raw == null) return null;
    if (raw is List) {
      final out = raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      return out.isEmpty ? null : out;
    }

    final value = _asString(raw);
    if (value == null || value.trim().isEmpty) return null;
    final text = value.trim();

    if (text.startsWith('[') && text.endsWith(']')) {
      try {
        final decoded = jsonDecode(text);
        if (decoded is List) {
          final out = decoded.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
          return out.isEmpty ? null : out;
        }
      } catch (_) {
        // Fallback auf weitere Parser unten.
      }
    }

    if (text.startsWith('{') && text.endsWith('}')) {
      final body = text.substring(1, text.length - 1).trim();
      if (body.isEmpty) return null;
      final out = body
          .split(',')
          .map((e) => e.trim().replaceAll('"', ''))
          .where((e) => e.isNotEmpty)
          .toList();
      return out.isEmpty ? null : out;
    }

    final out = text
        .split(',')
        .map((e) => e.trim().replaceAll('"', ''))
        .where((e) => e.isNotEmpty)
        .toList();
    return out.isEmpty ? null : out;
  }
}
