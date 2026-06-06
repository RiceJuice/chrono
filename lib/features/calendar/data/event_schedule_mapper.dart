import 'package:sqlite3/common.dart' as sqlite;

import '../../../core/database/backend_enums.dart';
import '../../../core/database/postgres_enum_array_codec.dart';
import '../../../core/time/app_date_time.dart';
import '../domain/models/event_schedule.dart';

class EventScheduleMapper {
  EventScheduleMapper._();

  static EventSchedule fromRow(sqlite.Row row) {
    final startRaw = row['start_time']?.toString();
    if (startRaw == null || startRaw.trim().isEmpty) {
      throw FormatException('event_schedules.start_time fehlt');
    }
    final startTime = AppDateTime.asUtcInstant(
      AppDateTime.parseDatabaseDateTime(
        startRaw,
        assumeUtcWhenTimezoneMissing: true,
      ),
    );

    DateTime? endTime;
    final endRaw = row['end_time']?.toString();
    if (endRaw != null && endRaw.trim().isNotEmpty) {
      endTime = AppDateTime.asUtcInstant(
        AppDateTime.parseDatabaseDateTime(
          endRaw,
          assumeUtcWhenTimezoneMissing: true,
        ),
      );
    }

    return EventSchedule(
      id: row['id']!.toString(),
      eventId: row['event_id']!.toString(),
      title: row['title']!.toString().trim(),
      description: _nullableTrim(row['description']?.toString()),
      startTime: startTime,
      endTime: endTime,
      location: _nullableTrim(row['location']?.toString()),
      choirs: _parseChoirs(row['choir']),
      voices: _parseVoices(row['voices']),
    );
  }

  static List<BackendChoir> _parseChoirs(Object? raw) {
    final tokens = PostgresEnumArrayCodec.decodeTokens(raw?.toString());
    final out = <BackendChoir>[];
    for (final token in tokens) {
      final parsed = BackendChoirCodec.fromBackend(token);
      if (parsed != BackendChoir.unknown && !out.contains(parsed)) {
        out.add(parsed);
      }
    }
    return out;
  }

  static List<BackendVoice> _parseVoices(Object? raw) {
    final tokens = PostgresEnumArrayCodec.decodeTokens(raw?.toString());
    final out = <BackendVoice>[];
    for (final token in tokens) {
      final parsed = BackendVoiceCodec.fromBackend(token);
      if (parsed != BackendVoice.unknown && !out.contains(parsed)) {
        out.add(parsed);
      }
    }
    return out;
  }

  static String? _nullableTrim(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
