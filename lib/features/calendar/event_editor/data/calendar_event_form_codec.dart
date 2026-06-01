import 'dart:convert';

import '../../../../core/database/backend_enums.dart';
import '../../../../core/database/postgres_enum_array_codec.dart';
import '../../../../core/time/app_date_time.dart';
import '../../domain/models/calendar_entry.dart';
import '../domain/calendar_event_form_state.dart';

class CalendarEventFormCodec {
  CalendarEventFormCodec._();

  static Map<String, Object?> toEventRow(CalendarEventFormState state) {
    return {
      'event_name': state.eventName.trim(),
      'description': _nullableTrim(state.description),
      'location': _nullableTrim(state.location),
      'note': _nullableTrim(state.note),
      'start_time': AppDateTime.asUtcInstant(state.startTime).toIso8601String(),
      'end_time': AppDateTime.asUtcInstant(state.endTime).toIso8601String(),
      'type': _typeToBackend(state.type),
      'choir': _encodeChoirForEvent(state.choir),
      'voices': _encodeVoices(state.voices),
      'schooltrack': state.schoolTrack.toBackend(),
      'class': _nullableTrim(state.className),
      'diet': state.diet.toBackend(),
    };
  }

  /// Gemeinsame Serien-Felder ohne Zeit/RRULE (siehe [CalendarEventSeriesCodec]).
  static Map<String, Object?> toSeriesSharedFields(CalendarEventFormState state) {
    return {
      'event_name': state.eventName.trim(),
      'location': _nullableTrim(state.location),
      'type': _typeToBackend(state.type),
      'choir': state.choir.toBackend(),
      'voices': _encodeVoices(state.voices),
      'schooltrack': state.schoolTrack.toBackend(),
      'class': _nullableTrim(state.className),
      'subject_id': state.type == CalendarEntryType.lesson
          ? _nullableTrim(state.subjectId)
          : null,
    };
  }

  static String? _nullableTrim(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _typeToBackend(CalendarEntryType type) {
    final backend = switch (type) {
      CalendarEntryType.lesson => CalendarEventType.lesson,
      CalendarEntryType.meal => CalendarEventType.meal,
      CalendarEntryType.event => CalendarEventType.event,
      CalendarEntryType.choir => CalendarEventType.choir,
      CalendarEntryType.breakType => CalendarEventType.breakType,
    };
    return backend.toBackend() ?? 'event';
  }

  /// `calendar_events.choir` ist in Postgres ein Enum-Array (`{Giehl}`).
  static String? _encodeChoirForEvent(BackendChoir choir) {
    return PostgresEnumArrayCodec.encodeLocalSingle(choir.toBackend());
  }

  static String? _encodeVoices(List<BackendVoice> voices) {
    final labels = voices
        .where((v) => v != BackendVoice.unknown)
        .map((v) => v.toBackend())
        .whereType<String>()
        .toList();
    if (labels.isEmpty) return null;
    return jsonEncode(labels);
  }
}
