import 'package:chronoapp/core/database/backend_enums.dart';
import 'package:chronoapp/features/calendar/domain/filter/calendar_filter_defaults.dart';
import 'package:chronoapp/features/calendar/domain/filter/calendar_filters_logic.dart';
import 'package:chronoapp/features/calendar/domain/filter/calendar_filters_state.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/providers/filter/calendar/calendar_filter_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CalendarEntry _entry({
  BackendChoir choir = BackendChoir.unknown,
  BackendVoice voice = BackendVoice.unknown,
  List<BackendVoice> voices = const [],
  String? className,
  CalendarEntryType type = CalendarEntryType.choir,
}) {
  return CalendarEntry(
    id: 'entry-1',
    eventName: 'Probe',
    startTime: DateTime.utc(2024, 6, 15, 10),
    endTime: DateTime.utc(2024, 6, 15, 11),
    accentColor: Colors.blue,
    type: type,
    choir: choir,
    voice: voice,
    voices: voices,
    className: className,
  );
}

void main() {
  group('shouldHideUnknownCalendarEntries', () {
    test('ist true bei initialisierten Profil-Filtern', () {
      final filters = calendarFiltersStateFromProfileFields(
        choir: 'Giehl',
        voice: 'Bass',
        className: '10',
      );

      expect(shouldHideUnknownCalendarEntries(filters), isTrue);
    });

    test('ist false ohne aktive Filter', () {
      expect(shouldHideUnknownCalendarEntries(const CalendarFiltersState()), isFalse);
    });
  });

  group('calendarEntryMatchesFilters hideUnknown', () {
    late CalendarFiltersState filters;

    setUp(() {
      filters = calendarFiltersStateFromProfileFields(
        choir: 'Giehl',
        voice: 'Bass',
        className: '10',
      );
    });

    test('blendet Termin ohne Stimme aus wenn hideUnknown aktiv', () {
      final entry = _entry(choir: BackendChoir.giehl);

      expect(
        calendarEntryMatchesFilters(
          entry: entry,
          filters: filters,
          hideUnknownWhenFilterActive: true,
        ),
        isFalse,
      );
    });

    test('zeigt Termin ohne Stimme wenn hideUnknown inaktiv', () {
      final entry = _entry(choir: BackendChoir.giehl);

      expect(
        calendarEntryMatchesFilters(
          entry: entry,
          filters: filters,
          hideUnknownWhenFilterActive: false,
        ),
        isTrue,
      );
    });

    test('zeigt passenden Chor-Termin mit Stimme', () {
      final entry = _entry(
        choir: BackendChoir.giehl,
        voice: BackendVoice.bass,
      );

      expect(
        calendarEntryMatchesFilters(
          entry: entry,
          filters: filters,
          hideUnknownWhenFilterActive: true,
        ),
        isTrue,
      );
    });

    test('blendet fremden Chor aus', () {
      final entry = _entry(
        choir: BackendChoir.dkm,
        voice: BackendVoice.bass,
      );

      expect(
        calendarEntryMatchesFilters(
          entry: entry,
          filters: filters,
          hideUnknownWhenFilterActive: true,
        ),
        isFalse,
      );
    });

    test('blendet Schul-Termin ohne Klasse nicht aus wenn hideUnknown aktiv', () {
      final entry = _entry(
        type: CalendarEntryType.lesson,
        className: null,
      );

      expect(
        calendarEntryMatchesFilters(
          entry: entry,
          filters: filters,
          hideUnknownWhenFilterActive: true,
        ),
        isTrue,
      );
    });

    test('blendet Schul-Termin mit fremder Klasse aus', () {
      final entry = _entry(
        type: CalendarEntryType.lesson,
        className: '11',
      );

      expect(
        calendarEntryMatchesFilters(
          entry: entry,
          filters: filters,
          hideUnknownWhenFilterActive: true,
        ),
        isFalse,
      );
    });

    test('zeigt allgemeines Event ohne Chor wenn hideUnknown aktiv', () {
      final entry = _entry(type: CalendarEntryType.event);

      expect(
        calendarEntryMatchesFilters(
          entry: entry,
          filters: filters,
          hideUnknownWhenFilterActive: true,
        ),
        isTrue,
      );
    });

    test('Ferien bleiben in der Event-Liste sichtbar', () {
      final holiday = CalendarEntry(
        id: 'break-1',
        eventName: 'Ferien',
        startTime: DateTime.utc(2024, 7, 1),
        endTime: DateTime.utc(2024, 7, 14),
        accentColor: Colors.grey,
        type: CalendarEntryType.breakType,
      );

      expect(
        calendarEntryVisibleInEventList(
          entry: holiday,
          filters: filters,
          hideUnknownWhenFilterActive: true,
        ),
        isTrue,
      );
    });

    test('ignoriert Klassenfilter für Chor-Termine', () {
      final entry = _entry(
        choir: BackendChoir.giehl,
        voice: BackendVoice.bass,
      );

      expect(
        calendarEntryMatchesFilters(
          entry: entry,
          filters: filters,
          hideUnknownWhenFilterActive: true,
        ),
        isTrue,
      );
    });
  });
}
