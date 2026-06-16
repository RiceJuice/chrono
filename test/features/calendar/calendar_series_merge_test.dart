import 'package:chronoapp/features/calendar/domain/calendar_series_merge.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CalendarEntry _entry({
  required String id,
  DateTime? startTime,
  DateTime? endTime,
  String? seriesId,
  DateTime? recurrenceId,
  bool isRecurringInstance = false,
}) {
  final start = startTime ?? DateTime.utc(2024, 6, 15, 10);
  final end = endTime ?? DateTime.utc(2024, 6, 15, 11);
  return CalendarEntry(
    id: id,
    eventName: id,
    startTime: start,
    endTime: end,
    accentColor: Colors.blue,
    type: CalendarEntryType.event,
    seriesId: seriesId,
    recurrenceId: recurrenceId,
    isRecurringInstance: isRecurringInstance,
  );
}

void main() {
  final windowStart = DateTime.utc(2024, 6, 15);
  final windowEnd = DateTime.utc(2024, 6, 16);

  test('Einzeltermin mit series_id und recurrence_id blendet Serien-Instanz aus', () {
    const seriesId = 'series-1';
    final recurrence = DateTime.utc(2024, 6, 15, 10);

    final override = _entry(
      id: 'override-1',
      seriesId: seriesId,
      recurrenceId: recurrence,
      startTime: DateTime.utc(2024, 6, 15, 10, 30),
      endTime: DateTime.utc(2024, 6, 15, 11, 30),
    );
    final seriesInstance = _entry(
      id: 'series:series-1:2024-06-15T10:00:00.000Z',
      seriesId: seriesId,
      recurrenceId: recurrence,
      isRecurringInstance: true,
    );

    final merged = mergeCalendarEntriesWithSeriesOverrides(
      events: [override],
      expandedSeries: [seriesInstance],
      startUtc: windowStart,
      endExclusiveUtc: windowEnd,
    );

    expect(merged, [override]);
  });

  test('Storno blendet Serien-Instanz aus ohne sichtbaren Einzeltermin', () {
    const seriesId = 'series-1';
    final recurrence = DateTime.utc(2024, 6, 15, 10);

    final cancellation = _entry(
      id: 'cancel-1',
      seriesId: seriesId,
      recurrenceId: recurrence,
      startTime: recurrence,
      endTime: recurrence,
    );
    final seriesInstance = _entry(
      id: 'series:series-1:2024-06-15T10:00:00.000Z',
      seriesId: seriesId,
      recurrenceId: recurrence,
      isRecurringInstance: true,
    );

    final merged = mergeCalendarEntriesWithSeriesOverrides(
      events: [cancellation],
      expandedSeries: [seriesInstance],
      startUtc: windowStart,
      endExclusiveUtc: windowEnd,
    );

    expect(merged, isEmpty);
  });

  test(
    'Override nur per recurrence_id im Fenster blendet Serie aus ohne Anzeige',
    () {
      const seriesId = 'series-1';
      final recurrence = DateTime.utc(2024, 6, 15, 10);

      final movedOverride = _entry(
        id: 'override-1',
        seriesId: seriesId,
        recurrenceId: recurrence,
        startTime: DateTime.utc(2024, 6, 16, 14),
        endTime: DateTime.utc(2024, 6, 16, 15),
      );
      final seriesInstance = _entry(
        id: 'series:series-1:2024-06-15T10:00:00.000Z',
        seriesId: seriesId,
        recurrenceId: recurrence,
        isRecurringInstance: true,
      );

      final merged = mergeCalendarEntriesWithSeriesOverrides(
        events: [movedOverride],
        expandedSeries: [seriesInstance],
        startUtc: windowStart,
        endExclusiveUtc: windowEnd,
      );

      expect(merged, isEmpty);
    },
  );

  test('series_id ohne recurrence_id nutzt start_time als Override-Schlüssel', () {
    const seriesId = 'series-1';
    final start = DateTime.utc(2024, 6, 15, 10);

    final override = _entry(
      id: 'override-1',
      seriesId: seriesId,
      startTime: start,
      endTime: DateTime.utc(2024, 6, 15, 11),
    );
    final seriesInstance = _entry(
      id: 'series:series-1:2024-06-15T10:00:00.000Z',
      seriesId: seriesId,
      recurrenceId: start,
      isRecurringInstance: true,
    );

    final merged = mergeCalendarEntriesWithSeriesOverrides(
      events: [override],
      expandedSeries: [seriesInstance],
      startUtc: windowStart,
      endExclusiveUtc: windowEnd,
    );

    expect(merged, [override]);
  });
}
