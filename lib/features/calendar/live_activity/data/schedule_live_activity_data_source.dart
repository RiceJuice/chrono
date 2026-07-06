import 'package:powersync/powersync.dart';
import 'package:sqlite3/common.dart';

import '../../../../core/database/backend_enums.dart';
import '../../../../core/database/postgres_enum_array_codec.dart';
import '../../../../core/database/powersync_schema.dart';
import '../../../../core/time/app_date_time.dart';
import '../../data/event_schedule_mapper.dart';
import '../../domain/models/event_schedule.dart';
import '../domain/schedule_live_activity_event.dart';

/// Lokale Abfragen für Ablaufplan-Live-Activities.
class ScheduleLiveActivityDataSource {
  ScheduleLiveActivityDataSource(this._db);

  final PowerSyncDatabase _db;

  /// Event-IDs mit mindestens einem Ablaufplanpunkt heute oder morgen.
  Future<Set<String>> eventIdsWithSchedulesOnDays({
    required DateTime dayStart,
    required DateTime dayEndExclusive,
  }) async {
    final rows = await _db.getAll(
      '''
      SELECT DISTINCT event_id
      FROM $kEventSchedulesTable
      WHERE start_time >= ? AND start_time < ?
      ''',
      [
        dayStart.toUtc().toIso8601String(),
        dayEndExclusive.toUtc().toIso8601String(),
      ],
    );
    return rows.map((r) => r['event_id']!.toString()).toSet();
  }

  /// Event-Termine (type event) ohne Ablaufplan im Zeitraum.
  Future<List<ScheduleLiveActivityEvent>> eventsWithoutSchedule({
    required DateTime rangeStart,
    required DateTime rangeEndExclusive,
  }) async {
    final rows = await _db.getAll(
      '''
      SELECT ce.id, ce.event_name, ce.location, ce.start_time, ce.end_time,
             ce.choir, ce.voices
      FROM $kCalendarEventsTable ce
      WHERE ce.type = 'event'
        AND ce.start_time >= ? AND ce.start_time < ?
        AND NOT EXISTS (
          SELECT 1 FROM $kEventSchedulesTable es WHERE es.event_id = ce.id
        )
      ORDER BY ce.start_time ASC
      ''',
      [
        rangeStart.toUtc().toIso8601String(),
        rangeEndExclusive.toUtc().toIso8601String(),
      ],
    );
    return _mapEventRows(rows);
  }

  Future<ScheduleLiveActivityEvent?> eventWithoutScheduleById(
    String eventId,
  ) async {
    final rows = await _db.getAll(
      '''
      SELECT ce.id, ce.event_name, ce.location, ce.start_time, ce.end_time,
             ce.choir, ce.voices
      FROM $kCalendarEventsTable ce
      WHERE ce.id = ?
        AND ce.type = 'event'
        AND NOT EXISTS (
          SELECT 1 FROM $kEventSchedulesTable es WHERE es.event_id = ce.id
        )
      LIMIT 1
      ''',
      [eventId],
    );
    if (rows.isEmpty) return null;
    return _mapEventRows(rows).firstOrNull;
  }

  Future<List<EventSchedule>> schedulesForEvent(String eventId) async {
    final rows = await _db.getAll(
      '''
      SELECT id, event_id, title, description, start_time, end_time,
             location, choir, voices
      FROM $kEventSchedulesTable
      WHERE event_id = ?
      ORDER BY start_time ASC
      ''',
      [eventId],
    );
    return _mapRows(rows);
  }

  /// Segment-Starts heute/morgen für lokale Notification-Planung.
  Future<List<({String eventId, String scheduleId, DateTime start})>>
  upcomingSegmentStarts({
    required DateTime rangeStart,
    required DateTime rangeEndExclusive,
  }) async {
    final rows = await _db.getAll(
      '''
      SELECT id, event_id, start_time
      FROM $kEventSchedulesTable
      WHERE start_time >= ? AND start_time < ?
      ORDER BY start_time ASC
      ''',
      [
        rangeStart.toUtc().toIso8601String(),
        rangeEndExclusive.toUtc().toIso8601String(),
      ],
    );

    final out = <({String eventId, String scheduleId, DateTime start})>[];
    for (final row in rows) {
      final startRaw = row['start_time']?.toString();
      if (startRaw == null || startRaw.trim().isEmpty) continue;
      final start = AppDateTime.asUtcInstant(
        AppDateTime.parseDatabaseDateTime(
          startRaw,
          assumeUtcWhenTimezoneMissing: true,
        ),
      );
      out.add((
        eventId: row['event_id']!.toString(),
        scheduleId: row['id']!.toString(),
        start: start,
      ));
    }
    return out;
  }

  /// Termin-Starts ohne Ablaufplan für lokale Notification-Planung.
  Future<List<({String eventId, DateTime start})>> upcomingEventStarts({
    required DateTime rangeStart,
    required DateTime rangeEndExclusive,
  }) async {
    final events = await eventsWithoutSchedule(
      rangeStart: rangeStart,
      rangeEndExclusive: rangeEndExclusive,
    );
    return events
        .map((event) => (eventId: event.id, start: event.startTime))
        .toList();
  }

  Stream<void> watchScheduleChanges() {
    return _db.watch(
      'SELECT COUNT(*) AS c FROM $kEventSchedulesTable',
      triggerOnTables: const {kEventSchedulesTable, kCalendarEventsTable},
    ).map((_) {});
  }

  List<EventSchedule> _mapRows(ResultSet rows) {
    final out = <EventSchedule>[];
    for (final row in rows) {
      try {
        out.add(EventScheduleMapper.fromRow(row));
      } catch (_) {}
    }
    return out;
  }

  List<ScheduleLiveActivityEvent> _mapEventRows(ResultSet rows) {
    final out = <ScheduleLiveActivityEvent>[];
    for (final row in rows) {
      try {
        out.add(_eventFromRow(row));
      } catch (_) {}
    }
    return out;
  }

  ScheduleLiveActivityEvent _eventFromRow(Row row) {
    final startRaw = row['start_time']?.toString();
    final endRaw = row['end_time']?.toString();
    if (startRaw == null ||
        startRaw.trim().isEmpty ||
        endRaw == null ||
        endRaw.trim().isEmpty) {
      throw FormatException('calendar_events start/end fehlt');
    }

    final startTime = AppDateTime.asUtcInstant(
      AppDateTime.parseDatabaseDateTime(
        startRaw,
        assumeUtcWhenTimezoneMissing: true,
      ),
    );
    final endTime = AppDateTime.asUtcInstant(
      AppDateTime.parseDatabaseDateTime(
        endRaw,
        assumeUtcWhenTimezoneMissing: true,
      ),
    );

    return ScheduleLiveActivityEvent(
      id: row['id']!.toString(),
      eventName: row['event_name']?.toString().trim() ?? '',
      location: _nullableTrim(row['location']?.toString()),
      startTime: startTime,
      endTime: endTime,
      choirs: _parseChoirs(row['choir']),
      voices: _parseVoices(row['voices']),
    );
  }

  static String? _nullableTrim(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
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
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
