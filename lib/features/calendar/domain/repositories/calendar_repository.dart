import 'package:flutter/foundation.dart';
import 'package:powersync/powersync.dart';
import 'package:sqlite3/common.dart';

import '../../../../core/database/powersync_schema.dart';
import '../../data/calendar_entry_mapper.dart';
import '../models/calendar_entry.dart';

class CalendarRepository {
  CalendarRepository(this._db);

  final PowerSyncDatabase _db;

  /// Start/Ende des **lokalen** Kalendertags als UTC-Instants.
  ///
  /// Filterung per SQLite `julianday()`, nicht per String-Vergleich: sonst schlagen
  /// z. B. `2026-04-10 16:00:00+00` (Leerzeichen) vs `2026-04-10T00:00:00.000Z`
  /// lexikographisch fehl (Leerzeichen < „T“) und Zeilen verschwinden.
  static (DateTime startUtc, DateTime endExclusiveUtc) _dayBoundsUtcForLocalDay(
    DateTime date,
  ) {
    final local = date.toLocal();
    final startLocal = DateTime(local.year, local.month, local.day);
    final endLocal = startLocal.add(const Duration(days: 1));
    return (startLocal.toUtc(), endLocal.toUtc());
  }

  Stream<List<CalendarEntry>> watchEntriesForDay(DateTime date) {
    final (startUtc, endUtc) = _dayBoundsUtcForLocalDay(date);
    final lo = startUtc.toIso8601String();
    final hi = endUtc.toIso8601String();

    return _db
        .watch(
          '''
SELECT id, title, subtitle, location, start_time, end_time, type,
       accent_color, image_urls, tags, user_id
FROM $kCalendarEventsTable
WHERE julianday(start_time) >= julianday(?)
  AND julianday(start_time) < julianday(?)
ORDER BY julianday(start_time) ASC
''',
          parameters: [lo, hi],
          triggerOnTables: const {kCalendarEventsTable},
        )
        .map((ResultSet rows) {
          if (kDebugMode) {
            debugPrint(
              '[Calendar] Tag ${date.toLocal()} → julianday(?) mit [$lo .. $hi) → '
              '${rows.length} Zeile(n) in $kCalendarEventsTable',
            );
          }
          final out = <CalendarEntry>[];
          for (final row in rows) {
            try {
              out.add(CalendarEntryMapper.fromRow(row));
            } catch (e) {
              if (kDebugMode) {
                debugPrint(
                  '[Calendar] Mapper-Fehler id=${row['id']} start_time=${row['start_time']}: $e',
                );
              }
            }
          }
          return out;
        });
  }
}
