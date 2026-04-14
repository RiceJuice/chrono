import 'package:flutter/foundation.dart';
import 'package:powersync/powersync.dart';
import 'package:rrule/rrule.dart';
import 'package:sqlite3/common.dart';

import '../../../../core/database/powersync_schema.dart';
import '../../data/calendar_entry_mapper.dart';
import '../models/calendar_entry.dart';

class CalendarRepository {
  CalendarRepository(this._db);

  final PowerSyncDatabase _db;
  static const Duration _searchHorizon = Duration(days: 365);

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
    return _watchMergedWindow(startUtc: startUtc, endExclusiveUtc: endUtc);
  }

  Stream<List<CalendarEntry>> watchEntriesByQuery(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return Stream.value(const <CalendarEntry>[]);
    }

    final nowUtc = DateTime.now().toUtc();
    final startUtc = nowUtc.subtract(_searchHorizon);
    final endUtc = nowUtc.add(_searchHorizon);

    return _watchMergedWindow(
      startUtc: startUtc,
      endExclusiveUtc: endUtc,
      query: normalizedQuery,
    );
  }

  Stream<List<CalendarEntry>> watchAllEntries() {
    final nowUtc = DateTime.now().toUtc();
    final startUtc = nowUtc.subtract(_searchHorizon);
    final endUtc = nowUtc.add(_searchHorizon);
    return _watchMergedWindow(startUtc: startUtc, endExclusiveUtc: endUtc);
  }

  Stream<List<CalendarEntry>> _watchMergedWindow({
    required DateTime startUtc,
    required DateTime endExclusiveUtc,
    String? query,
  }) {
    final lo = startUtc.toIso8601String();
    final hi = endExclusiveUtc.toIso8601String();
    final loDate = startUtc.toIso8601String().split('T').first;
    final hiDate = endExclusiveUtc.toIso8601String().split('T').first;

    return _db
        .watch(
          '''
          SELECT
              'event' AS source,
              id, event_name, description, location, note, start_time, end_time, type,
              choir, voices, schooltrack, class, image_paths, series_id, recurrence_id,
              NULL AS rrule, NULL AS series_start, NULL AS series_end
          FROM $kCalendarEventsTable
          WHERE julianday(start_time) >= julianday(?)
            AND julianday(start_time) < julianday(?)

          UNION ALL

          SELECT
              'series' AS source,
              id, event_name, NULL AS description, location, NULL AS note, start_time, end_time, type,
              choir, voices, NULL AS schooltrack, class, NULL AS image_paths, id AS series_id,
              NULL AS recurrence_id, rrule, series_start, series_end
          FROM $kCalendarSeriesTable
          WHERE date(series_start) <= date(?)
            AND (series_end IS NULL OR date(series_end) >= date(?))
          ''',
          parameters: [lo, hi, hiDate, loDate],
          triggerOnTables: const {kCalendarEventsTable, kCalendarSeriesTable},
        )
        .map((rows) => _mapMergedRows(
              rows,
              startUtc: startUtc,
              endExclusiveUtc: endExclusiveUtc,
              query: query,
            ));
  }

  List<CalendarEntry> _mapMergedRows(
    ResultSet rows, {
    required DateTime startUtc,
    required DateTime endExclusiveUtc,
    String? query,
  }) {
    final events = <CalendarEntry>[];
    final series = <CalendarEntry>[];
    final rulesBySeriesId = <String, RecurrenceRule>{};
    final seriesEndExclusiveBySeriesId = <String, DateTime>{};

    for (final row in rows) {
      try {
        final source = _safeRowValue(row, 'source')?.toString();
        if (source == 'series') {
          final mapped = CalendarEntryMapper.fromSeriesRow(row);
          series.add(mapped);
          final parsedRule = _parseRecurrenceRule(
            _safeRowValue(row, 'rrule')?.toString(),
          );
          if (parsedRule != null) {
            rulesBySeriesId[mapped.seriesId ?? mapped.id] = parsedRule;
          }
          final seriesEndExclusiveUtc = _parseSeriesEndExclusiveUtc(
            _safeRowValue(row, 'series_end'),
          );
          if (seriesEndExclusiveUtc != null) {
            seriesEndExclusiveBySeriesId[mapped.seriesId ?? mapped.id] =
                seriesEndExclusiveUtc;
          }
        } else {
          events.add(CalendarEntryMapper.fromEventRow(row));
        }
      } catch (e) {
        if (kDebugMode) {
          final id = _safeRowValue(row, 'id');
          final startTime = _safeRowValue(row, 'start_time');
          debugPrint(
            '[Calendar] Mapper-Fehler id=$id start_time=$startTime: $e',
          );
        }
      }
    }

    final expandedSeries = _expandSeriesOccurrences(
      seriesTemplates: series,
      rulesBySeriesId: rulesBySeriesId,
      seriesEndExclusiveBySeriesId: seriesEndExclusiveBySeriesId,
      startUtc: startUtc,
      endExclusiveUtc: endExclusiveUtc,
    );

    final merged = _mergeWithOverrides(events, expandedSeries);
    final filtered = query == null
        ? merged
        : merged.where((entry) => _matchesQuery(entry, query)).toList();
    filtered.sort((a, b) => a.startTime.compareTo(b.startTime));
    return filtered;
  }

  List<CalendarEntry> _expandSeriesOccurrences({
    required List<CalendarEntry> seriesTemplates,
    required Map<String, RecurrenceRule> rulesBySeriesId,
    required Map<String, DateTime> seriesEndExclusiveBySeriesId,
    required DateTime startUtc,
    required DateTime endExclusiveUtc,
  }) {
    final out = <CalendarEntry>[];

    for (final seriesTemplate in seriesTemplates) {
      final seriesId = seriesTemplate.seriesId ?? seriesTemplate.id;
      final rule = rulesBySeriesId[seriesId];
      if (rule == null) continue;

      try {
        final duration = seriesTemplate.endTime.difference(seriesTemplate.startTime);
        final templateStartUtc = seriesTemplate.startTime.toUtc();
        final seriesEndExclusiveUtc = seriesEndExclusiveBySeriesId[seriesId];
        final effectiveBefore = seriesEndExclusiveUtc == null
            ? endExclusiveUtc
            : (seriesEndExclusiveUtc.isBefore(endExclusiveUtc)
                ? seriesEndExclusiveUtc
                : endExclusiveUtc);
        final requestedAfter = startUtc.subtract(const Duration(milliseconds: 1));
        final safeAfter = requestedAfter.isBefore(templateStartUtc)
            ? templateStartUtc
            : requestedAfter;
        if (!effectiveBefore.isAfter(safeAfter)) {
          continue;
        }

        final instances = rule.getInstances(
          start: templateStartUtc,
          after: safeAfter,
          includeAfter: true,
          before: effectiveBefore,
          includeBefore: false,
        );

        for (final instance in instances) {
          final instanceEnd = instance.add(duration);
          out.add(
            CalendarEntry(
              id: 'series:$seriesId:${instance.toIso8601String()}',
              eventName: seriesTemplate.eventName,
              description: seriesTemplate.description,
              note: seriesTemplate.note,
              location: seriesTemplate.location,
              startTime: instance,
              endTime: instanceEnd,
              imageUrls: seriesTemplate.imageUrls,
              accentColor: seriesTemplate.accentColor,
              type: seriesTemplate.type,
              choir: seriesTemplate.choir,
              voice: seriesTemplate.voice,
              voices: seriesTemplate.voices,
              schoolTrack: seriesTemplate.schoolTrack,
              className: seriesTemplate.className,
              imagePaths: seriesTemplate.imagePaths,
              tags: seriesTemplate.tags,
              userId: seriesTemplate.userId,
              seriesId: seriesId,
              recurrenceId: instance.toUtc(),
              isRecurringInstance: true,
            ),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[Calendar] Fehler bei RRULE-Expansion fuer series_id=$seriesId: $e');
        }
      }
    }

    return out;
  }

  List<CalendarEntry> _mergeWithOverrides(
    List<CalendarEntry> events,
    List<CalendarEntry> expandedSeries,
  ) {
    final overrides = <String>{};
    for (final event in events) {
      final key = _seriesOverrideKey(event.seriesId, event.recurrenceId);
      if (key != null) {
        overrides.add(key);
      }
    }

    final remainingSeries = expandedSeries.where((seriesEntry) {
      final key = _seriesOverrideKey(seriesEntry.seriesId, seriesEntry.recurrenceId);
      return key == null || !overrides.contains(key);
    });

    return <CalendarEntry>[...events, ...remainingSeries];
  }

  String? _seriesOverrideKey(String? seriesId, DateTime? recurrenceId) {
    if (seriesId == null || recurrenceId == null) return null;
    return '$seriesId|${recurrenceId.toUtc().toIso8601String()}';
  }

  bool _matchesQuery(CalendarEntry entry, String query) {
    final q = query.toLowerCase();
    final searchable = <String>[
      entry.eventName,
      entry.description ?? '',
      entry.location ?? '',
      entry.note ?? '',
    ].join(' ').toLowerCase();
    return searchable.contains(q);
  }

  DateTime? _parseSeriesEndExclusiveUtc(Object? value) {
    final s = value?.toString();
    if (s == null || s.trim().isEmpty) return null;
    final parsed = DateTime.parse(s.trim());
    return DateTime.utc(parsed.year, parsed.month, parsed.day).add(
      const Duration(days: 1),
    );
  }

  RecurrenceRule? _parseRecurrenceRule(String? rawRule) {
    final normalized = _normalizeRruleText(rawRule);
    if (normalized == null) return null;
    try {
      return RecurrenceRule.fromString(normalized);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Calendar] Ungueltige RRULE "$normalized": $e');
      }
      return null;
    }
  }

  String? _normalizeRruleText(String? rawRule) {
    final raw = rawRule?.trim();
    if (raw == null || raw.isEmpty) return null;

    final lines = raw
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) return null;

    for (final line in lines) {
      final upper = line.toUpperCase();
      if (upper.startsWith('RRULE:')) {
        final value = line.substring(6).trim();
        return value.isEmpty ? null : 'RRULE:$value';
      }
    }

    final first = lines.first;
    final upperFirst = first.toUpperCase();
    if (upperFirst.startsWith('FREQ=')) {
      return 'RRULE:$first';
    }
    if (upperFirst.contains('FREQ=')) {
      final idx = upperFirst.indexOf('FREQ=');
      final extracted = first.substring(idx).trim();
      return extracted.isEmpty ? null : 'RRULE:$extracted';
    }

    return null;
  }

  Object? _safeRowValue(Row row, String key) {
    try {
      return row[key];
    } catch (_) {
      return null;
    }
  }
}
