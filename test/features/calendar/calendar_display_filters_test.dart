import 'package:chronoapp/core/database/backend_enums.dart';
import 'package:chronoapp/features/calendar/domain/filter/calendar_display_filters.dart';
import 'package:chronoapp/features/calendar/domain/filter/calendar_filter_defaults.dart';
import 'package:chronoapp/features/calendar/domain/filter/calendar_filters_logic.dart';
import 'package:chronoapp/features/calendar/domain/filter/calendar_filters_state.dart';
import 'package:chronoapp/features/calendar/domain/filter/calendar_meal_diet_filter.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CalendarEntry _meal({
  required String id,
  BackendDiet diet = BackendDiet.noRestriction,
  DateTime? startTime,
}) {
  final start = startTime ?? DateTime(2024, 6, 15, 12);
  return CalendarEntry(
    id: id,
    eventName: id,
    startTime: start,
    endTime: start.add(const Duration(hours: 1)),
    accentColor: Colors.green,
    type: CalendarEntryType.meal,
    diet: diet,
  );
}

CalendarEntry _event({
  required String id,
  DateTime? startTime,
  DateTime? endTime,
  CalendarEntryType type = CalendarEntryType.event,
}) {
  final start = startTime ?? DateTime(2024, 6, 15, 10);
  final end = endTime ?? start.add(const Duration(hours: 2));
  return CalendarEntry(
    id: id,
    eventName: id,
    startTime: start,
    endTime: end,
    accentColor: Colors.blue,
    type: type,
  );
}

void main() {
  group('collectMealSlotsWithDietAlternatives', () {
    test('erkennt Slot mit vegetarischer und fleischhaltiger Alternative', () {
      final lunch = DateTime(2024, 6, 15, 12);
      final slots = collectMealSlotsWithDietAlternatives([
        _meal(id: 'veg', diet: BackendDiet.vegetarian, startTime: lunch),
        _meal(id: 'meat', diet: BackendDiet.noRestriction, startTime: lunch),
      ]);

      expect(slots, {mealDietSlotKey(_meal(id: 'x', startTime: lunch))});
    });

    test('ignoriert Slot mit nur einer Alternative', () {
      final lunch = DateTime(2024, 6, 15, 12);
      final slots = collectMealSlotsWithDietAlternatives([
        _meal(id: 'veg', diet: BackendDiet.vegetarian, startTime: lunch),
      ]);

      expect(slots, isEmpty);
    });
  });

  group('Diätfilter mit Alternativen', () {
    late CalendarFiltersState filters;

    setUp(() {
      filters = calendarFiltersStateFromProfileFields(diet: 'Keine Einschränkung');
    });

    test('zeigt vegetarisches Essen wenn keine fleischhaltige Alternative existiert', () {
      final lunch = DateTime(2024, 6, 15, 12);
      final vegetarian = _meal(
        id: 'veg',
        diet: BackendDiet.vegetarian,
        startTime: lunch,
      );
      final entries = [vegetarian];
      final slots = collectMealSlotsWithDietAlternatives(entries);

      expect(
        calendarEntryMatchesFilters(
          entry: vegetarian,
          filters: filters,
          hideUnknownWhenFilterActive: false,
          mealSlotsWithDietAlternatives: slots,
        ),
        isTrue,
      );
    });

    test('blendet vegetarisches Essen aus wenn beide Alternativen existieren', () {
      final lunch = DateTime(2024, 6, 15, 12);
      final vegetarian = _meal(
        id: 'veg',
        diet: BackendDiet.vegetarian,
        startTime: lunch,
      );
      final meat = _meal(
        id: 'meat',
        diet: BackendDiet.noRestriction,
        startTime: lunch,
      );
      final entries = [vegetarian, meat];
      final slots = collectMealSlotsWithDietAlternatives(entries);

      expect(
        calendarEntryMatchesFilters(
          entry: vegetarian,
          filters: filters,
          hideUnknownWhenFilterActive: false,
          mealSlotsWithDietAlternatives: slots,
        ),
        isFalse,
      );
      expect(
        calendarEntryMatchesFilters(
          entry: meat,
          filters: filters,
          hideUnknownWhenFilterActive: false,
          mealSlotsWithDietAlternatives: slots,
        ),
        isTrue,
      );
    });
  });

  group('suppressCalendarEntriesOverlappedByEvents', () {
    test('blendet gleichzeitige Nicht-Event-Termine aus', () {
      final event = _event(id: 'event');
      final lesson = _event(
        id: 'lesson',
        type: CalendarEntryType.lesson,
      );

      final result = suppressCalendarEntriesOverlappedByEvents([event, lesson]);

      expect(result, [event]);
    });

    test('lässt nicht überlappende Termine sichtbar', () {
      final event = _event(
        id: 'event',
        startTime: DateTime(2024, 6, 15, 8),
        endTime: DateTime(2024, 6, 15, 9),
      );
      final lesson = _event(
        id: 'lesson',
        type: CalendarEntryType.lesson,
        startTime: DateTime(2024, 6, 15, 10),
        endTime: DateTime(2024, 6, 15, 11),
      );

      final result = suppressCalendarEntriesOverlappedByEvents([event, lesson]);

      expect(result, [event, lesson]);
    });

    test('belässt Ferien auch bei Event-Überlappung', () {
      final event = _event(id: 'event');
      final holiday = _event(
        id: 'holiday',
        type: CalendarEntryType.breakType,
        startTime: DateTime(2024, 6, 15),
        endTime: DateTime(2024, 6, 16),
      );

      final result = suppressCalendarEntriesOverlappedByEvents([event, holiday]);

      expect(result, [event, holiday]);
    });
  });
}
