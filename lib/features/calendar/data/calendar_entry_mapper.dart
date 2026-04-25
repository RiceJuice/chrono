import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sqlite3/common.dart' as sqlite;

import '../../../core/database/backend_enums.dart';
import '../domain/models/calendar_entry.dart';

class CalendarEntryMapper {
  CalendarEntryMapper._();

  static CalendarEntry fromEventRow(sqlite.Row row) {
    return _fromRow(
      row,
      forceSeriesIdFromId: false,
      isRecurringInstance: false,
    );
  }

  static CalendarEntry fromSeriesRow(sqlite.Row row) {
    final rowId = _rowValue(row, 'id').toString();
    final seriesStart = _parseDate(_rowValue(row, 'series_start'));
    final startDateTimeUtc = _resolveSeriesDateTimeUtc(
      seriesStart: seriesStart,
      rawTimeOrDateTime: _rowValue(row, 'start_time'),
      fieldName: 'start_time',
    );
    final endDateTimeUtc = _resolveSeriesDateTimeUtc(
      seriesStart: seriesStart,
      rawTimeOrDateTime: _rowValue(row, 'end_time'),
      fieldName: 'end_time',
      fallback: startDateTimeUtc,
    );

    final rawType = _asString(_rowValue(row, 'type'));
    final backendType = CalendarEventTypeCodec.fromBackend(rawType);
    final choirRaw = _asString(_rowValue(row, 'choir'));
    final voicesRaw = _asString(_rowValue(row, 'voices'));
    final choir = BackendChoirCodec.fromBackend(choirRaw);
    final voices = _parseVoices(voicesRaw);
    final voice = voices.isEmpty ? BackendVoice.unknown : voices.first;

    return CalendarEntry(
      id: rowId,
      eventName: _asString(_rowValue(row, 'event_name')) ?? '',
      description: null,
      note: null,
      location: _asString(_rowValue(row, 'location')),
      startTime: startDateTimeUtc,
      endTime: endDateTimeUtc.isBefore(startDateTimeUtc)
          ? endDateTimeUtc.add(const Duration(days: 1))
          : endDateTimeUtc,
      imageUrls: null,
      accentColor: _defaultAccentColorForType(_toDomainType(backendType)),
      type: _toDomainType(backendType),
      choir: choir,
      voice: voice,
      voices: voices,
      schoolTrack: BackendSchoolTrack.unknown,
      className: _asString(_rowValue(row, 'class')),
      imagePaths: null,
      tags: null,
      userId: null,
      seriesId: rowId,
      recurrenceId: null,
      isRecurringInstance: true,
    );
  }

  static CalendarEntry fromRow(sqlite.Row row) {
    // Backward-compatible alias for existing callers.
    return fromEventRow(row);
  }

  static CalendarEntry _fromRow(
    sqlite.Row row, {
    required bool forceSeriesIdFromId,
    required bool isRecurringInstance,
  }) {
    final rawType = _asString(_rowValue(row, 'type'));
    final backendType = CalendarEventTypeCodec.fromBackend(rawType);
    final eventName = _asString(_rowValue(row, 'event_name')) ?? '';
    final description = _asString(_rowValue(row, 'description'));
    final choirRaw = _asString(_rowValue(row, 'choir'));
    final voicesRaw = _asString(_rowValue(row, 'voices'));
    final schoolTrackRaw = _asString(_rowValue(row, 'schooltrack'));
    final choir = BackendChoirCodec.fromBackend(choirRaw);
    final voices = _parseVoices(voicesRaw);
    final voice = voices.isEmpty ? BackendVoice.unknown : voices.first;
    final schoolTrack = BackendSchoolTrackCodec.fromBackend(schoolTrackRaw);
    final domainType = _toDomainType(backendType);
    final imagePaths = _decodeStringList(_rowValue(row, 'image_paths'));

    final rowId = _rowValue(row, 'id').toString();
    final parsedRecurrenceId = _parseDateTimeOrNull(_rowValue(row, 'recurrence_id'));
    final parsedSeriesId = forceSeriesIdFromId
        ? rowId
        : _asString(_rowValue(row, 'series_id'));

    return CalendarEntry(
      id: _rowValue(row, 'id').toString(),
      eventName: eventName,
      description: description,
      note: _asString(_rowValue(row, 'note')),
      location: _asString(_rowValue(row, 'location')),
      startTime: _parseDateTime(_rowValue(row, 'start_time')),
      endTime: _parseDateTime(_rowValue(row, 'end_time')),
      imageUrls: null,
      accentColor: _defaultAccentColorForType(domainType),
      type: domainType,
      choir: choir,
      voice: voice,
      voices: voices,
      schoolTrack: schoolTrack,
      className: _asString(_rowValue(row, 'class')),
      imagePaths: imagePaths,
      tags: null,
      userId: null,
      seriesId: parsedSeriesId,
      recurrenceId: parsedRecurrenceId,
      isRecurringInstance: isRecurringInstance,
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

  static DateTime? _parseDateTimeOrNull(Object? value) {
    final s = _asString(value);
    if (s == null || s.isEmpty) return null;
    final normalized = s.contains('T') ? s : s.replaceFirst(' ', 'T');
    return DateTime.parse(normalized);
  }

  static DateTime _parseDate(Object? value) {
    final s = _asString(value);
    if (s == null || s.isEmpty) {
      throw FormatException('series_start fehlt oder leer');
    }
    return DateTime.parse(s);
  }

  static ({int hour, int minute, int second, int millisecond, int microsecond}) _parseTime(
    Object? value,
  ) {
    final s = _asString(value);
    if (s == null || s.isEmpty) {
      throw FormatException('start/end_time (TIME) fehlt oder leer');
    }
    final parts = s.split(':');
    if (parts.length < 2) {
      throw FormatException('Ungueltiges TIME-Format: $s');
    }
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    var second = 0;
    var millisecond = 0;
    var microsecond = 0;
    if (parts.length >= 3) {
      final secAndFraction = parts[2].split('.');
      second = int.parse(secAndFraction[0]);
      if (secAndFraction.length > 1) {
        final fraction = secAndFraction[1].padRight(6, '0');
        microsecond = int.parse(fraction.substring(0, 6));
        millisecond = microsecond ~/ 1000;
        microsecond = microsecond % 1000;
      }
    }
    return (
      hour: hour,
      minute: minute,
      second: second,
      millisecond: millisecond,
      microsecond: microsecond,
    );
  }

  static DateTime _combineDateAndTimeUtc(
    DateTime date,
    ({int hour, int minute, int second, int millisecond, int microsecond}) time,
  ) {
    return DateTime.utc(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
      time.second,
      time.millisecond,
      time.microsecond,
    );
  }

  static DateTime _resolveSeriesDateTimeUtc({
    required DateTime seriesStart,
    required Object? rawTimeOrDateTime,
    required String fieldName,
    DateTime? fallback,
  }) {
    final raw = _asString(rawTimeOrDateTime)?.trim();
    if (raw == null || raw.isEmpty) {
      if (fallback != null) return fallback;
      throw FormatException('$fieldName fehlt oder leer');
    }

    final looksLikeDateTime =
        raw.contains('T') || (raw.contains(' ') && raw.contains('-'));
    if (looksLikeDateTime) {
      final parsed = _parseDateTime(raw);
      return parsed.isUtc ? parsed : parsed.toUtc();
    }

    final time = _parseTime(raw);
    return _combineDateAndTimeUtc(seriesStart, time);
  }

  static List<BackendVoice> _parseVoices(String? voicesRaw) {
    final values = _extractVoiceTokens(voicesRaw);
    final out = <BackendVoice>[];
    for (final value in values) {
      final parsed = BackendVoiceCodec.fromBackend(value);
      if (parsed != BackendVoice.unknown && !out.contains(parsed)) {
        out.add(parsed);
      }
    }
    return out;
  }

  static List<String> _extractVoiceTokens(String? voicesRaw) {
    if (voicesRaw == null) return const <String>[];
    final raw = voicesRaw.trim();
    if (raw.isEmpty) return const <String>[];

    List<Object?> decodedValues;
    if (raw.startsWith('[') && raw.endsWith(']')) {
      try {
        final decoded = jsonDecode(raw);
        decodedValues = decoded is List ? decoded : <Object?>[decoded];
      } catch (_) {
        decodedValues = _splitVoiceCsv(raw.substring(1, raw.length - 1));
      }
    } else if (raw.startsWith('{') && raw.endsWith('}')) {
      decodedValues = _splitVoiceCsv(raw.substring(1, raw.length - 1));
    } else {
      decodedValues = _splitVoiceCsv(raw);
    }

    return decodedValues
        .map(_normalizeVoiceToken)
        .whereType<String>()
        .toList(growable: false);
  }

  static List<String> _splitVoiceCsv(String value) {
    return value
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
  }

  static String? _normalizeVoiceToken(Object? value) {
    if (value == null) return null;
    var text = value.toString().trim();
    if (text.isEmpty) return null;
    if (text.startsWith('"') && text.endsWith('"') && text.length >= 2) {
      text = text.substring(1, text.length - 1).trim();
    }
    if (text.startsWith("'") && text.endsWith("'") && text.length >= 2) {
      text = text.substring(1, text.length - 1).trim();
    }
    if (text.isEmpty) return null;
    if (text.toLowerCase() == 'null') return null;
    return text;
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
