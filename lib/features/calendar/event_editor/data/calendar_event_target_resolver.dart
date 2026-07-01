import 'package:powersync/powersync.dart';

import '../../../../core/database/powersync_schema.dart';
import '../../domain/models/calendar_entry.dart';
import '../domain/calendar_event_edit_target.dart';
import 'calendar_event_recurrence_id.dart';

class CalendarEventTargetResolver {
  CalendarEventTargetResolver(this._db);

  final PowerSyncDatabase _db;

  static final RegExp _syntheticSeriesIdPattern = RegExp(r'^series:([^:]+):');

  Future<CalendarEventEditTarget> resolve(CalendarEntry entry) async {
    final parsedSeriesId = _resolveSeriesId(entry);
    final recurrenceId = entry.recurrenceId;

    if (parsedSeriesId == null) {
      return CalendarEventEditTarget(
        kind: CalendarEventEditTargetKind.standalone,
        sourceEntry: entry,
        existingEventRowId: entry.id,
      );
    }

    final existingOverrideId = await _findOverrideRowId(
      seriesId: parsedSeriesId,
      recurrenceId: recurrenceId,
      startTimeFallback: recurrenceId ?? entry.startTime,
    );

    return CalendarEventEditTarget(
      kind: CalendarEventEditTargetKind.seriesInstance,
      sourceEntry: entry,
      existingEventRowId: existingOverrideId,
      seriesId: parsedSeriesId,
      recurrenceId: recurrenceId,
    );
  }

  static bool needsSaveScopeDialog(CalendarEntry entry) {
    return resolveSeriesId(entry) != null;
  }

  static String? resolveSeriesId(CalendarEntry entry) {
    return _resolveSeriesId(entry);
  }

  static String? _resolveSeriesId(CalendarEntry entry) {
    if (entry.seriesId != null && entry.seriesId!.isNotEmpty) {
      return entry.seriesId;
    }
    final match = _syntheticSeriesIdPattern.firstMatch(entry.id);
    return match?.group(1);
  }

  Future<String?> _findOverrideRowId({
    required String seriesId,
    DateTime? recurrenceId,
    DateTime? startTimeFallback,
  }) async {
    if (recurrenceId != null) {
      final recurrenceIso = formatCalendarRecurrenceId(recurrenceId);
      final exactRows = await _db.getAll(
        '''
        SELECT id FROM $kCalendarEventsTable
        WHERE series_id = ? AND recurrence_id = ?
        LIMIT 1
        ''',
        [seriesId, recurrenceIso],
      );
      if (exactRows.isNotEmpty) {
        return exactRows.first['id']?.toString();
      }

      final normalizedTarget = recurrenceIso;
      final candidateRows = await _db.getAll(
        '''
        SELECT id, recurrence_id FROM $kCalendarEventsTable
        WHERE series_id = ? AND recurrence_id IS NOT NULL
        ''',
        [seriesId],
      );
      for (final row in candidateRows) {
        final rawRecurrence = row['recurrence_id']?.toString();
        if (rawRecurrence == null || rawRecurrence.trim().isEmpty) {
          continue;
        }
        try {
          final normalizedRow = formatCalendarRecurrenceId(
            parseCalendarRecurrenceId(rawRecurrence),
          );
          if (normalizedRow == normalizedTarget) {
            return row['id']?.toString();
          }
        } catch (_) {
          continue;
        }
      }
    }

    if (startTimeFallback == null) {
      return null;
    }

    final startIso = formatCalendarRecurrenceId(startTimeFallback);
    final fallbackRows = await _db.getAll(
      '''
      SELECT id FROM $kCalendarEventsTable
      WHERE series_id = ?
        AND (
          recurrence_id IS NULL
          OR trim(recurrence_id) = ''
        )
        AND start_time = ?
      LIMIT 1
      ''',
      [seriesId, startIso],
    );
    if (fallbackRows.isEmpty) {
      return null;
    }
    return fallbackRows.first['id']?.toString();
  }
}
