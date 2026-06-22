import 'package:powersync/powersync.dart';
import 'package:sqlite3/common.dart';

import '../../../../core/database/powersync_schema.dart';
import '../../../../core/time/app_date_time.dart';
import '../../data/event_schedule_mapper.dart';
import '../../domain/models/event_schedule.dart';

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
}
