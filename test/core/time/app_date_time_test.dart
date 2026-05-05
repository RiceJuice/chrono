import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
