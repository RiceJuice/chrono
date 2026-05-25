import 'package:flutter/foundation.dart';
import 'package:powersync/powersync.dart';

import '../../../../core/database/calendar_events_debug_log.dart';
import '../../../../core/database/powersync_schema.dart';
import '../domain/calendar_event_edit_target.dart';
import '../domain/calendar_event_form_state.dart';
import '../domain/calendar_event_save_scope.dart';
import 'calendar_event_form_codec.dart';
import 'calendar_event_id_generator.dart';
import 'calendar_event_recurrence_id.dart';
import 'calendar_event_series_codec.dart';

class CalendarEventWriteException implements Exception {
  CalendarEventWriteException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CalendarEventWriteRepository {
  CalendarEventWriteRepository(this._db);

  final PowerSyncDatabase _db;

  Future<void> save({
    required CalendarEventEditTarget target,
    required CalendarEventFormState state,
    required CalendarEventSaveScope? scope,
  }) async {
    if (target.isRecurring && scope == null) {
      throw CalendarEventWriteException('Speicherumfang für Serientermin fehlt.');
    }

    await _db.writeTransaction((tx) async {
      if (!target.isRecurring) {
        await _updateStandaloneEvent(tx, target.existingEventRowId!, state);
        return;
      }

      switch (scope!) {
        case CalendarEventSaveScope.singleInstance:
          await _saveSeriesInstanceOverride(tx, target, state);
        case CalendarEventSaveScope.entireSeries:
          await _updateSeriesMaster(tx, target.seriesId!, state);
      }
    });

    if (kDebugMode) {
      final queue = await _db.getUploadQueueStats();
      logCalendarEventWriteResult(
        action: 'saved',
        table: target.isRecurring
            ? (scope == CalendarEventSaveScope.entireSeries
                ? kCalendarSeriesTable
                : kCalendarEventsTable)
            : kCalendarEventsTable,
        id: target.existingEventRowId ?? target.seriesId ?? '?',
        uploadQueueCount: queue.count,
      );
    }
  }

  Future<void> _updateStandaloneEvent(
    dynamic tx,
    String eventId,
    CalendarEventFormState state,
  ) async {
    if (eventId.startsWith('series:')) {
      throw CalendarEventWriteException(
        'Dieser Termin ist eine Serien-Instanz — bitte Speicherumfang wählen.',
      );
    }

    await _requireLocalRow(
      tx,
      table: kCalendarEventsTable,
      id: eventId,
      hint: 'Einzeltermin',
    );

    final row = CalendarEventFormCodec.toEventRow(state);
    await _patchTable(tx, kCalendarEventsTable, eventId, row);
  }

  Future<void> _saveSeriesInstanceOverride(
    dynamic tx,
    CalendarEventEditTarget target,
    CalendarEventFormState state,
  ) async {
    final seriesId = target.seriesId;
    final recurrenceId = target.recurrenceId;
    if (seriesId == null || recurrenceId == null) {
      throw CalendarEventWriteException(
        'Serien-Instanz ohne series_id oder recurrence_id.',
      );
    }

    await _requireLocalRow(
      tx,
      table: kCalendarSeriesTable,
      id: seriesId,
      hint: 'Serie',
    );

    final row = CalendarEventFormCodec.toEventRow(state);
    row['series_id'] = seriesId;
    row['recurrence_id'] = formatCalendarRecurrenceId(recurrenceId);

    final existingId = target.existingEventRowId;
    if (existingId != null && existingId.isNotEmpty) {
      await _patchTable(tx, kCalendarEventsTable, existingId, row);
    } else {
      final id = generateCalendarEventId();
      await _insertRow(tx, kCalendarEventsTable, id, row);
    }
  }

  Future<void> _updateSeriesMaster(
    dynamic tx,
    String seriesId,
    CalendarEventFormState state,
  ) async {
    final series = state.seriesEdit;
    if (series == null) {
      throw CalendarEventWriteException(
        'Serien-Daten fehlen. Bitte Formular neu öffnen.',
      );
    }

    await _requireLocalRow(
      tx,
      table: kCalendarSeriesTable,
      id: seriesId,
      hint: 'Serie',
    );

    final row = CalendarEventSeriesCodec.toSeriesRow(state: state, series: series);
    await _patchTable(tx, kCalendarSeriesTable, seriesId, row);
  }

  Future<void> _requireLocalRow(
    dynamic tx, {
    required String table,
    required String id,
    required String hint,
  }) async {
    final rows = await tx.getAll(
      'SELECT id FROM $table WHERE id = ? LIMIT 1',
      [id],
    );
    if (rows.isEmpty) {
      throw CalendarEventWriteException(
        '$hint mit id=$id ist lokal nicht vorhanden — nur synced Daten sind editierbar.',
      );
    }
  }

  Future<void> _patchTable(
    dynamic tx,
    String table,
    String id,
    Map<String, Object?> row,
  ) async {
    if (row.isEmpty) return;
    final keys = row.keys.toList();
    final assignments = keys.map(_sqlColumn).map((k) => '$k = ?').join(', ');
    final values = [...keys.map((k) => row[k]), id];
    await tx.execute(
      'UPDATE $table SET $assignments WHERE id = ?',
      values,
    );
  }

  Future<void> _insertRow(
    dynamic tx,
    String table,
    String id,
    Map<String, Object?> row,
  ) async {
    final keys = ['id', ...row.keys];
    final sqlColumns = keys.map(_sqlColumn).join(', ');
    final placeholders = List.filled(keys.length, '?').join(', ');
    final values = [id, ...row.values];
    await tx.execute(
      'INSERT INTO $table ($sqlColumns) VALUES ($placeholders)',
      values,
    );
  }

  static String _sqlColumn(String name) {
    if (name == 'class') return '"class"';
    return name;
  }
}
