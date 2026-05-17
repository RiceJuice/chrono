import 'package:chronoapp/features/calendar/presentation/providers/calendar_view_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveCalendarViewMode', () {
    test('null und leer → Default (Tag)', () {
      expect(resolveCalendarViewMode(null), CalendarViewMode.day);
      expect(resolveCalendarViewMode(''), CalendarViewMode.day);
    });

    test('bekannte Modi', () {
      expect(resolveCalendarViewMode('day'), CalendarViewMode.day);
      expect(resolveCalendarViewMode('week'), CalendarViewMode.week);
    });

    test('unbekannter String → Default', () {
      expect(resolveCalendarViewMode('month'), CalendarViewMode.day);
      expect(resolveCalendarViewMode('typo'), CalendarViewMode.day);
    });
  });

  group('tryParseCalendarViewMode', () {
    test('parst alle Enum-Werte per name', () {
      for (final mode in CalendarViewMode.values) {
        expect(tryParseCalendarViewMode(mode.name), mode);
      }
    });

    test('unbekannt → null', () {
      expect(tryParseCalendarViewMode('quarter'), isNull);
    });
  });

  group('isRegisteredCalendarViewMode', () {
    test('nur Optionen aus calendarViewOptions', () {
      for (final option in calendarViewOptions) {
        expect(isRegisteredCalendarViewMode(option.mode), isTrue);
      }
    });
  });
}
