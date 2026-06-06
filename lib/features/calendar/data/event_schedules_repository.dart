import 'package:powersync/powersync.dart';
import 'package:sqlite3/common.dart';

import '../../../core/database/powersync_schema.dart';
import '../domain/models/event_schedule.dart';
import 'event_schedule_mapper.dart';

class EventSchedulesRepository {
  EventSchedulesRepository(this._db);

  final PowerSyncDatabase _db;

  Stream<List<EventSchedule>> watchForEvent(String eventId) {
    return _db
        .watch(
          '''
          SELECT id, event_id, title, description, start_time, end_time,
                 location, choir, voices
          FROM $kEventSchedulesTable
          WHERE event_id = ?
          ORDER BY start_time ASC
          ''',
          parameters: [eventId],
          triggerOnTables: const {kEventSchedulesTable},
        )
        .map(_mapRows);
  }

  List<EventSchedule> _mapRows(ResultSet rows) {
    final out = <EventSchedule>[];
    for (final row in rows) {
      try {
        out.add(EventScheduleMapper.fromRow(row));
      } catch (_) {
        // Ungültige Zeile überspringen — Modal soll nicht abbrechen.
      }
    }
    return out;
  }
}
