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
          SELECT id, event_name, description, location, note, start_time, end_time, type,
                choir, voices, schooltrack, class, image_paths
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
          return _mapRows(rows, isSearch: false);
        });
  }

  Stream<List<CalendarEntry>> watchEntriesByQuery(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return Stream.value(const <CalendarEntry>[]);
    }

    final likeArg = '%$normalizedQuery%';
    return _db
        .watch(
          '''
          SELECT id, event_name, description, location, note, start_time, end_time, type,
                choir, voices, schooltrack, class, image_paths
          FROM $kCalendarEventsTable
          WHERE lower(event_name) LIKE ?
            OR lower(COALESCE(description, '')) LIKE ?
            OR lower(COALESCE(location, '')) LIKE ?
            OR lower(COALESCE(note, '')) LIKE ?
          ORDER BY julianday(start_time) ASC
          ''',
          parameters: [likeArg, likeArg, likeArg, likeArg],
          triggerOnTables: const {kCalendarEventsTable},
        )
        .map((ResultSet rows) {
          return _mapRows(rows, isSearch: true);
        });
  }

  Stream<List<CalendarEntry>> watchAllEntries() {
    return _db
        .watch(
          '''
          SELECT id, event_name, description, location, note, start_time, end_time, type,
                choir, voices, schooltrack, class, image_paths
          FROM $kCalendarEventsTable
          ORDER BY julianday(start_time) ASC
          ''',
          triggerOnTables: const {kCalendarEventsTable},
        )
        .map((ResultSet rows) => _mapRows(rows, isSearch: true));
  }

  List<CalendarEntry> _mapRows(ResultSet rows, {required bool isSearch}) {
    final out = <CalendarEntry>[];
    for (final row in rows) {
      try {
        out.add(CalendarEntryMapper.fromRow(row));
      } catch (e) {
        if (kDebugMode) {
          final id = _safeRowValue(row, 'id');
          final startTime = _safeRowValue(row, 'start_time');
          final prefix = isSearch ? 'Search-' : '';
          debugPrint(
            '[Calendar] ${prefix}Mapper-Fehler id=$id start_time=$startTime: $e',
          );
        }
      }
    }
    return out;
  }

  Object? _safeRowValue(Row row, String key) {
    try {
      return row[key];
    } catch (_) {
      return null;
    }
  }
}
