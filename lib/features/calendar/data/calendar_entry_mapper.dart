import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sqlite3/common.dart' as sqlite;

import '../../../core/database/backend_enums.dart';
import '../../../core/database/postgres_enum_array_codec.dart';
import '../../../core/time/app_date_time.dart';
import '../domain/models/calendar_entry.dart';
import 'subject_color_codec.dart';

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
    final choir = _parseChoir(_rowValue(row, 'choir'));
    final voices = _parseVoices(_asString(_rowValue(row, 'voices')));
    final voice = voices.isEmpty ? BackendVoice.unknown : voices.first;
    final schoolTrack = BackendSchoolTrackCodec.fromBackend(
      _asString(_rowValue(row, 'schooltrack')),
    );
    final diet = BackendDietCodec.fromBackend(
      _asString(_rowValue(row, 'diet')),
    );

    final domainType = _toDomainType(backendType);
    final subjectId = _asSubjectId(_rowValue(row, 'subject_id'));

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
      accentColor: _resolveAccentColor(
        domainType: domainType,
        subjectDefaultColor: _rowValue(row, 'subject_default_color'),
      ),
      type: domainType,
      subjectId: subjectId,
      choir: choir,
      voice: voice,
      voices: voices,
      schoolTrack: schoolTrack,
      diet: diet,
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
    final choir = _parseChoir(_rowValue(row, 'choir'));
    final voices = _parseVoices(_asString(_rowValue(row, 'voices')));
    final schoolTrackRaw = _asString(_rowValue(row, 'schooltrack'));
    final dietRaw = _asString(_rowValue(row, 'diet'));
    final voice = voices.isEmpty ? BackendVoice.unknown : voices.first;
    final schoolTrack = BackendSchoolTrackCodec.fromBackend(schoolTrackRaw);
    final diet = BackendDietCodec.fromBackend(dietRaw);
    final domainType = _toDomainType(backendType);
    final subjectId = _asSubjectId(_rowValue(row, 'subject_id'));
    final imagePaths = _decodeStringList(_rowValue(row, 'image_paths'));

    final rowId = _rowValue(row, 'id').toString();
    final parsedRecurrenceId = _parseDateTimeOrNull(
      _rowValue(row, 'recurrence_id'),
    );
    final parsedSeriesId = forceSeriesIdFromId
        ? rowId
        : _asString(_rowValue(row, 'series_id'));
    final startTime = _parseDateTime(_rowValue(row, 'start_time'));
    final endTime =
        _parseDateTimeOrNull(_rowValue(row, 'end_time')) ?? startTime;

    return CalendarEntry(
      id: _rowValue(row, 'id').toString(),
      eventName: eventName,
      description: description,
      note: _asString(_rowValue(row, 'note')),
      location: _asString(_rowValue(row, 'location')),
      startTime: startTime,
      endTime: endTime,
      imageUrls: null,
      accentColor: _resolveAccentColor(
        domainType: domainType,
        subjectDefaultColor: _rowValue(row, 'subject_default_color'),
      ),
      type: domainType,
      subjectId: subjectId,
      choir: choir,
      voice: voice,
      voices: voices,
      schoolTrack: schoolTrack,
      diet: diet,
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
    return AppDateTime.parseDatabaseDateTime(
      s,
      assumeUtcWhenTimezoneMissing: true,
    );
  }

  static DateTime? _parseDateTimeOrNull(Object? value) {
    final s = _asString(value);
    if (s == null || s.isEmpty) return null;
    return AppDateTime.parseDatabaseDateTime(
      s,
      assumeUtcWhenTimezoneMissing: true,
    );
  }

  static DateTime _parseDate(Object? value) {
    final s = _asString(value);
    if (s == null || s.isEmpty) {
      throw FormatException('series_start fehlt oder leer');
    }
    return DateTime.parse(s);
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
      final parsed = AppDateTime.parseDatabaseDateTime(
        raw,
        assumeUtcWhenTimezoneMissing: true,
      );
      return AppDateTime.asUtcInstant(parsed);
    }

    return AppDateTime.parseDatabaseTimeOnDate(seriesStart, raw);
  }

  static BackendChoir _parseChoir(Object? raw) {
    final token = PostgresEnumArrayCodec.decodeFirstToken(_asString(raw));
    return BackendChoirCodec.fromBackend(token);
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
      CalendarEventType.breakType => CalendarEntryType.breakType,
      CalendarEventType.unknown => CalendarEntryType.event,
    };
  }

  static Color defaultAccentColorForType(CalendarEntryType type) {
    return _defaultAccentColorForType(type);
  }

  static Color? parseSubjectAccentColor(Object? value) {
    return SubjectColorCodec.parseHex(value);
  }

  static String? _asSubjectId(Object? value) {
    final s = _asString(value);
    if (s == null || s.trim().isEmpty) return null;
    return s.trim();
  }

  static Color _resolveAccentColor({
    required CalendarEntryType domainType,
    Object? subjectDefaultColor,
  }) {
    final fromSubject = parseSubjectAccentColor(subjectDefaultColor);
    if (fromSubject != null) return fromSubject;
    return _defaultAccentColorForType(domainType);
  }

  static Color _defaultAccentColorForType(CalendarEntryType type) {
    return switch (type) {
      CalendarEntryType.lesson => const Color(0xFF124E30),
      CalendarEntryType.meal => const Color(0xFF124E30),
      CalendarEntryType.event => const Color(0xFF29509E),
      CalendarEntryType.choir => const Color(0xFFCBBBA0),
      CalendarEntryType.breakType => const Color(0xFF29509E),
    };
  }

  static List<String>? _decodeStringList(Object? raw) {
    if (raw == null) return null;
    if (raw is List) {
      final out = raw
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
      return out.isEmpty ? null : out;
    }

    final value = _asString(raw);
    if (value == null || value.trim().isEmpty) return null;
    final text = value.trim();

    if (text.startsWith('[') && text.endsWith(']')) {
      try {
        final decoded = jsonDecode(text);
        if (decoded is List) {
          final out = decoded
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList();
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
