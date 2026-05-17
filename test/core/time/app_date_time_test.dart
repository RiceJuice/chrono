import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppDateTime local calendar', () {
    test('sameWeekdayInWeekOf keeps weekday across DST spring week', () {
      final monday = DateTime(2026, 3, 30);
      final friday = DateTime(2026, 3, 27);
      final result = AppDateTime.sameWeekdayInWeekOf(
        weekReference: monday,
        weekdaySource: friday,
      );
      expect(result.year, 2026);
      expect(result.month, 4);
      expect(result.day, 3);
    });

    test('localCalendarDaysBetween differs from Duration.inDays after DST', () {
      final anchor = DateTime(2018, 1, 1);
      final target = DateTime(2026, 3, 30);
      expect(
        AppDateTime.localCalendarDaysBetween(anchor, target),
        isNot(target.difference(anchor).inDays),
      );
    });
  });

  group('AppDateTime.parseDatabaseTimeOnDate', () {
    test('converts Postgres timetz values with hour-only offsets', () {
      final parsed = AppDateTime.parseDatabaseTimeOnDate(
        DateTime(2026, 5, 5),
        '10:35:00+02',
      );

      expect(parsed, DateTime.utc(2026, 5, 5, 8, 35));
    });

    test('converts Postgres timetz values with minute offsets', () {
      final parsed = AppDateTime.parseDatabaseTimeOnDate(
        DateTime(2026, 5, 5),
        '10:35:00+02:30',
      );

      expect(parsed, DateTime.utc(2026, 5, 5, 8, 5));
    });
  });
}
