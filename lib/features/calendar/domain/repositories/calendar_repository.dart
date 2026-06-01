import 'dart:developer' as developer;

import 'package:powersync/powersync.dart';
import 'package:rrule/rrule.dart';
import 'package:sqlite3/common.dart';

import '../../../../core/database/powersync_schema.dart';
import '../../../../core/time/app_date_time.dart';
import '../../data/calendar_entry_mapper.dart';
import '../../event_editor/data/calendar_event_recurrence_id.dart';
import '../models/calendar_entry.dart';

class CalendarRepository {
  CalendarRepository(this._db);

  final PowerSyncDatabase _db;
  static const Duration _searchHorizon = Duration(days: 365);

  Stream<List<CalendarEntry>> watchEntriesForDay(DateTime date) {
    final (startUtc, endUtc) = AppDateTime.utcBoundsForLocalDay(date);
    return _watchMergedWindow(startUtc: startUtc, endExclusiveUtc: endUtc);
  }

  Stream<List<CalendarEntry>> watchEntriesInLocalRange({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) {
    final (startUtc, _) = AppDateTime.utcBoundsForLocalDay(startInclusive);
    final (endUtc, _) = AppDateTime.utcBoundsForLocalDay(endExclusive);
    return _watchMergedWindow(startUtc: startUtc, endExclusiveUtc: endUtc);
  }

  Stream<Set<DateTime>> watchBreakDaysInLocalRange({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) {
    final startDay = AppDateTime.localDay(startInclusive);
    final endDay = AppDateTime.localDay(endExclusive);
    final startDate = _formatDate(startDay);
    final endDate = _formatDate(endDay);

    return _db
        .watch(
          '''
          SELECT id, event_name, series_start, series_end
          FROM $kCalendarSeriesTable
          WHERE type = 'break'
            AND date(series_start) < date(?)
            AND (series_end IS NULL OR date(series_end) >= date(?))
          ''',
          parameters: [endDate, startDate],
          triggerOnTables: const {kCalendarSeriesTable},
        )
        .map(
          (rows) => _expandBreakSeriesRowsToDays(
            rows,
            startInclusive: startDay,
            endExclusive: endDay,
          ),
        );
  }

  Stream<Set<DateTime>> watchHolidayDaysInLocalRange({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) {
    final startDay = AppDateTime.localDay(startInclusive);
    final endDay = AppDateTime.localDay(endExclusive);
    final startDate = _formatDate(startDay);
    final endDate = _formatDate(endDay);

    return _db
        .watch(
          '''
          SELECT id, start_time, end_time
          FROM $kCalendarEventsTable
          WHERE type = 'break'
            AND julianday(start_time) < julianday(?)
            AND julianday(COALESCE(end_time, start_time)) >= julianday(?)
          ''',
          parameters: [endDate, startDate],
          triggerOnTables: const {kCalendarEventsTable},
        )
        .map(
          (rows) => _expandHolidayEventRowsToDays(
            rows,
            startInclusive: startDay,
            endExclusive: endDay,
          ),
        );
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
              choir, voices, schooltrack, class, diet, image_paths, series_id, recurrence_id,
              NULL AS rrule, NULL AS series_start, NULL AS series_end,
              NULL AS subject_id, NULL AS subject_name, NULL AS subject_default_color
          FROM $kCalendarEventsTable
          WHERE (
              type = 'break'
              AND julianday(start_time) < julianday(?)
              AND julianday(COALESCE(end_time, start_time)) >= julianday(?)
            )
             OR (
              type != 'break'
              AND julianday(start_time) >= julianday(?)
              AND julianday(start_time) < julianday(?)
            )

          UNION ALL

          SELECT
              'series' AS source,
              cs.id,
              cs.event_name,
              NULL AS description,
              cs.location,
              NULL AS note,
              cs.start_time,
              cs.end_time,
              cs.type,
              cs.choir,
              cs.voices,
              cs.schooltrack,
              cs.class,
              NULL AS diet,
              NULL AS image_paths,
              cs.id AS series_id,
              NULL AS recurrence_id,
              cs.rrule,
              cs.series_start,
              cs.series_end,
              cs.subject_id,
              s.name AS subject_name,
              s.default_color AS subject_default_color
          FROM $kCalendarSeriesTable cs
          LEFT JOIN $kSubjectsTable s ON s.id = cs.subject_id
          WHERE date(cs.series_start) <= date(?)
            AND (cs.series_end IS NULL OR date(cs.series_end) >= date(?))
          ''',
          parameters: [hi, lo, lo, hi, hiDate, loDate],
          triggerOnTables: const {
            kCalendarEventsTable,
            kCalendarSeriesTable,
            kSubjectsTable,
          },
        )
        .map(
          (rows) => _mapMergedRows(
            rows,
            startUtc: startUtc,
            endExclusiveUtc: endExclusiveUtc,
            query: query,
          ),
        );
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
    final seriesStartBySeriesId = <String, DateTime>{};
    final seriesEndExclusiveBySeriesId = <String, DateTime>{};

    for (final row in rows) {
      try {
        final source = _safeRowValue(row, 'source')?.toString();
        if (source == 'series') {
          final mapped = CalendarEntryMapper.fromSeriesRow(row);
          series.add(mapped);
          final seriesId = mapped.seriesId ?? mapped.id;
          final parsedRule = _parseRecurrenceRule(
            _safeRowValue(row, 'rrule')?.toString(),
          );
          if (parsedRule != null) {
            rulesBySeriesId[seriesId] = parsedRule;
          }
          final seriesStartLocal = _parseSeriesStartLocal(
            _safeRowValue(row, 'series_start'),
          );
          if (seriesStartLocal != null) {
            seriesStartBySeriesId[seriesId] = seriesStartLocal;
          }
          final seriesEndExclusiveUtc = _parseSeriesEndExclusiveUtc(
            _safeRowValue(row, 'series_end'),
          );
          if (seriesEndExclusiveUtc != null) {
            seriesEndExclusiveBySeriesId[seriesId] = seriesEndExclusiveUtc;
          }
        } else {
          events.add(CalendarEntryMapper.fromEventRow(row));
        }
      } catch (error, stackTrace) {
        _logMappingError(row, error, stackTrace);
      }
    }

    final expandedSeries = _expandSeriesOccurrences(
      seriesTemplates: series,
      rulesBySeriesId: rulesBySeriesId,
      seriesStartBySeriesId: seriesStartBySeriesId,
      seriesEndExclusiveBySeriesId: seriesEndExclusiveBySeriesId,
      startUtc: startUtc,
      endExclusiveUtc: endExclusiveUtc,
    );
    final freeDays = _collectFreeDays(events, expandedSeries);
    final filteredSeries = expandedSeries
        .where((entry) {
          if (entry.type == CalendarEntryType.breakType) {
            return true;
          }
          final day = AppDateTime.localDay(entry.startTime);
          return !freeDays.contains(day);
        })
        .toList(growable: false);

    final merged = _mergeWithOverrides(events, filteredSeries);
    final filtered = query == null
        ? merged
        : merged.where((entry) => _matchesQuery(entry, query)).toList();
    filtered.sort((a, b) => a.startTime.compareTo(b.startTime));
    return filtered;
  }

  List<CalendarEntry> _expandSeriesOccurrences({
    required List<CalendarEntry> seriesTemplates,
    required Map<String, RecurrenceRule> rulesBySeriesId,
    required Map<String, DateTime> seriesStartBySeriesId,
    required Map<String, DateTime> seriesEndExclusiveBySeriesId,
    required DateTime startUtc,
    required DateTime endExclusiveUtc,
  }) {
    final out = <CalendarEntry>[];

    for (final seriesTemplate in seriesTemplates) {
      final seriesId = seriesTemplate.seriesId ?? seriesTemplate.id;
      final rule = rulesBySeriesId[seriesId];
      if (rule == null) {
        if (seriesTemplate.type == CalendarEntryType.breakType) {
          final seriesStartLocal = seriesStartBySeriesId[seriesId];
          if (seriesStartLocal != null) {
            out.addAll(
              _expandDateRangeBreakSeries(
                seriesTemplate: seriesTemplate,
                seriesStartLocal: seriesStartLocal,
                seriesEndExclusiveUtc: seriesEndExclusiveBySeriesId[seriesId],
                startUtc: startUtc,
                endExclusiveUtc: endExclusiveUtc,
              ),
            );
          }
        }
        continue;
      }

      try {
        final duration = seriesTemplate.endTime.difference(
          seriesTemplate.startTime,
        );
        final templateStartUtc = seriesTemplate.startTime.toUtc();
        final seriesEndExclusiveUtc = seriesEndExclusiveBySeriesId[seriesId];
        final effectiveBefore = seriesEndExclusiveUtc == null
            ? endExclusiveUtc
            : (seriesEndExclusiveUtc.isBefore(endExclusiveUtc)
                  ? seriesEndExclusiveUtc
                  : endExclusiveUtc);
        final requestedAfter = startUtc.subtract(
          const Duration(milliseconds: 1),
        );
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
              diet: seriesTemplate.diet,
              className: seriesTemplate.className,
              imagePaths: seriesTemplate.imagePaths,
              tags: seriesTemplate.tags,
              userId: seriesTemplate.userId,
              seriesId: seriesId,
              recurrenceId: parseCalendarRecurrenceId(
                formatCalendarRecurrenceId(instance),
              ),
              isRecurringInstance: true,
              subjectId: seriesTemplate.subjectId,
            ),
          );
        }
      } catch (error, stackTrace) {
        _logSeriesExpansionError(seriesTemplate, error, stackTrace);
      }
    }

    return out;
  }

  List<CalendarEntry> _expandDateRangeBreakSeries({
    required CalendarEntry seriesTemplate,
    required DateTime seriesStartLocal,
    required DateTime? seriesEndExclusiveUtc,
    required DateTime startUtc,
    required DateTime endExclusiveUtc,
  }) {
    final seriesId = seriesTemplate.seriesId ?? seriesTemplate.id;
    final windowStartLocal = AppDateTime.localDay(startUtc.toLocal());
    final windowEndExclusiveLocal = AppDateTime.localDay(
      endExclusiveUtc.toLocal(),
    );
    final seriesEndInclusiveLocal = seriesEndExclusiveUtc == null
        ? seriesStartLocal
        : AppDateTime.addLocalCalendarDays(
            AppDateTime.localDay(seriesEndExclusiveUtc.toLocal()),
            -1,
          );

    var day = seriesStartLocal;
    if (day.isBefore(windowStartLocal)) {
      day = windowStartLocal;
    }
    var lastDay = seriesEndInclusiveLocal;
    final lastVisibleDay = AppDateTime.addLocalCalendarDays(
      windowEndExclusiveLocal,
      -1,
    );
    if (lastDay.isAfter(lastVisibleDay)) {
      lastDay = lastVisibleDay;
    }
    if (day.isAfter(lastDay)) {
      return const <CalendarEntry>[];
    }

    final out = <CalendarEntry>[];
    while (!day.isAfter(lastDay)) {
      final (dayStartUtc, dayEndUtc) = AppDateTime.utcBoundsForLocalDay(day);
      out.add(
        CalendarEntry(
          id: 'series:$seriesId:${dayStartUtc.toIso8601String()}',
          eventName: seriesTemplate.eventName,
          description: seriesTemplate.description,
          note: seriesTemplate.note,
          location: seriesTemplate.location,
          startTime: dayStartUtc,
          endTime: dayEndUtc,
          imageUrls: seriesTemplate.imageUrls,
          accentColor: seriesTemplate.accentColor,
          type: seriesTemplate.type,
          choir: seriesTemplate.choir,
          voice: seriesTemplate.voice,
          voices: seriesTemplate.voices,
          schoolTrack: seriesTemplate.schoolTrack,
          diet: seriesTemplate.diet,
          className: seriesTemplate.className,
          imagePaths: seriesTemplate.imagePaths,
          tags: seriesTemplate.tags,
          userId: seriesTemplate.userId,
          seriesId: seriesId,
          recurrenceId: parseCalendarRecurrenceId(
            formatCalendarRecurrenceId(dayStartUtc),
          ),
          isRecurringInstance: true,
          subjectId: seriesTemplate.subjectId,
        ),
      );
      day = AppDateTime.addLocalCalendarDays(day, 1);
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
      final key = _seriesOverrideKey(
        seriesEntry.seriesId,
        seriesEntry.recurrenceId,
      );
      return key == null || !overrides.contains(key);
    });

    return <CalendarEntry>[...events, ...remainingSeries];
  }

  String? _seriesOverrideKey(String? seriesId, DateTime? recurrenceId) {
    if (seriesId == null || recurrenceId == null) return null;
    return '$seriesId|${formatCalendarRecurrenceId(recurrenceId)}';
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

  DateTime? _parseSeriesStartLocal(Object? value) {
    final s = value?.toString();
    if (s == null || s.trim().isEmpty) return null;
    return AppDateTime.localDay(DateTime.parse(s.trim()));
  }

  DateTime? _parseSeriesEndExclusiveUtc(Object? value) {
    final s = value?.toString();
    if (s == null || s.trim().isEmpty) return null;
    final parsed = DateTime.parse(s.trim());
    final endLocal = AppDateTime.localDay(parsed).add(const Duration(days: 1));
    return endLocal.toUtc();
  }

  RecurrenceRule? _parseRecurrenceRule(String? rawRule) {
    final normalized = _normalizeRruleText(rawRule);
    if (normalized == null) return null;
    try {
      return RecurrenceRule.fromString(normalized);
    } catch (_) {
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

  Set<DateTime> _expandBreakSeriesRowsToDays(
    ResultSet rows, {
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) {
    final days = <DateTime>{};
    for (final row in rows) {
      try {
        final seriesStart = _parseSeriesStartLocal(
          _safeRowValue(row, 'series_start'),
        );
        if (seriesStart == null) continue;

        final rawSeriesEnd = _safeRowValue(row, 'series_end')?.toString();
        final seriesEndInclusive =
            rawSeriesEnd == null || rawSeriesEnd.trim().isEmpty
            ? seriesStart
            : AppDateTime.localDay(DateTime.parse(rawSeriesEnd.trim()));

        var day = seriesStart.isBefore(startInclusive)
            ? startInclusive
            : seriesStart;
        final lastVisibleDay = AppDateTime.addLocalCalendarDays(
          endExclusive,
          -1,
        );
        final lastDay = seriesEndInclusive.isAfter(lastVisibleDay)
            ? lastVisibleDay
            : seriesEndInclusive;

        while (!day.isAfter(lastDay)) {
          days.add(day);
          day = AppDateTime.addLocalCalendarDays(day, 1);
        }
      } catch (error, stackTrace) {
        _logBreakSeriesRangeError(row, error, stackTrace);
      }
    }
    return days;
  }

  Set<DateTime> _expandHolidayEventRowsToDays(
    ResultSet rows, {
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) {
    final days = <DateTime>{};
    for (final row in rows) {
      try {
        final start = _parseRequiredDateTime(
          _safeRowValue(row, 'start_time'),
          fieldName: 'start_time',
        );
        final end =
            _parseOptionalDateTime(_safeRowValue(row, 'end_time')) ?? start;
        final startDay = AppDateTime.localDay(start);
        var endDay = AppDateTime.localDay(end);
        final isNextMidnightExclusive =
            end.isAfter(start) &&
            AppDateTime.localCalendarDaysBetween(startDay, endDay) == 1 &&
            end.toLocal().hour == 0 &&
            end.toLocal().minute == 0;
        if (isNextMidnightExclusive) {
          endDay = startDay;
        }

        var day = startDay.isBefore(startInclusive) ? startInclusive : startDay;
        final lastVisibleDay = AppDateTime.addLocalCalendarDays(
          endExclusive,
          -1,
        );
        final lastDay = endDay.isAfter(lastVisibleDay)
            ? lastVisibleDay
            : endDay;

        while (!day.isAfter(lastDay)) {
          days.add(day);
          day = AppDateTime.addLocalCalendarDays(day, 1);
        }
      } catch (error, stackTrace) {
        _logHolidayEventRangeError(row, error, stackTrace);
      }
    }
    return days;
  }

  DateTime _parseRequiredDateTime(Object? value, {required String fieldName}) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) {
      throw FormatException('$fieldName fehlt oder leer');
    }
    return AppDateTime.parseDatabaseDateTime(
      raw,
      assumeUtcWhenTimezoneMissing: true,
    );
  }

  DateTime? _parseOptionalDateTime(Object? value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) return null;
    return AppDateTime.parseDatabaseDateTime(
      raw,
      assumeUtcWhenTimezoneMissing: true,
    );
  }

  String _formatDate(DateTime day) {
    final local = AppDateTime.localDay(day);
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final date = local.day.toString().padLeft(2, '0');
    return '$year-$month-$date';
  }

  void _logMappingError(Row row, Object error, StackTrace stackTrace) {
    assert(() {
      developer.log(
        'Kalenderzeile konnte nicht gemappt werden: '
        'source=${_safeRowValue(row, 'source')} id=${_safeRowValue(row, 'id')}',
        name: 'CalendarRepository',
        error: error,
        stackTrace: stackTrace,
        level: 900,
      );
      return true;
    }());
  }

  void _logSeriesExpansionError(
    CalendarEntry seriesTemplate,
    Object error,
    StackTrace stackTrace,
  ) {
    assert(() {
      developer.log(
        'Kalenderserie konnte nicht expandiert werden: '
        'id=${seriesTemplate.id} name=${seriesTemplate.eventName}',
        name: 'CalendarRepository',
        error: error,
        stackTrace: stackTrace,
        level: 900,
      );
      return true;
    }());
  }

  void _logBreakSeriesRangeError(Row row, Object error, StackTrace stackTrace) {
    assert(() {
      developer.log(
        'Ferienserie konnte nicht zu Tagen expandiert werden: '
        'id=${_safeRowValue(row, 'id')} name=${_safeRowValue(row, 'event_name')}',
        name: 'CalendarRepository',
        error: error,
        stackTrace: stackTrace,
        level: 900,
      );
      return true;
    }());
  }

  void _logHolidayEventRangeError(
    Row row,
    Object error,
    StackTrace stackTrace,
  ) {
    assert(() {
      developer.log(
        'Feiertag aus calendar_events konnte nicht gelesen werden: '
        'id=${_safeRowValue(row, 'id')}',
        name: 'CalendarRepository',
        error: error,
        stackTrace: stackTrace,
        level: 900,
      );
      return true;
    }());
  }

  Set<DateTime> _collectFreeDays(
    List<CalendarEntry> events,
    List<CalendarEntry> expandedSeries,
  ) {
    final freeDays = <DateTime>{};
    for (final event in events) {
      if (event.type != CalendarEntryType.breakType) continue;
      final startDay = AppDateTime.localDay(event.startTime);
      var endDay = AppDateTime.localDay(event.endTime);
      final isNextMidnightExclusive =
          event.endTime.isAfter(event.startTime) &&
          AppDateTime.localCalendarDaysBetween(startDay, endDay) == 1 &&
          event.endTime.toLocal().hour == 0 &&
          event.endTime.toLocal().minute == 0;
      if (isNextMidnightExclusive) {
        endDay = startDay;
      }

      var day = startDay;
      while (!day.isAfter(endDay)) {
        freeDays.add(day);
        day = AppDateTime.addLocalCalendarDays(day, 1);
      }
    }
    for (final seriesEntry in expandedSeries) {
      if (seriesEntry.type != CalendarEntryType.breakType) continue;
      freeDays.add(AppDateTime.localDay(seriesEntry.startTime));
    }
    return freeDays;
  }
}
