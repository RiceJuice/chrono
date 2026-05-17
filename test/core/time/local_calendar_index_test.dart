import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/core/time/local_calendar_index.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalCalendarIndex', () {
    test('week page index advances one per calendar week across DST', () {
      final timeline = kWeekScheduleDayIndex;
      final beforeDst = DateTime(2026, 3, 23);
      final afterDst = DateTime(2026, 3, 30);
      expect(
        timeline.weekPageIndex(afterDst, pageCount: kWeekPageCount),
        timeline.weekPageIndex(beforeDst, pageCount: kWeekPageCount) + 1,
      );
    });

    test('mondayForPage round-trips weekPageIndex', () {
      final timeline = kWeekScheduleDayIndex;
      for (final monday in <DateTime>[
        DateTime(2018, 1, 1),
        DateTime(2026, 3, 23),
        DateTime(2026, 3, 30),
      ]) {
        final page = timeline.weekPageIndex(monday, pageCount: kWeekPageCount);
        final recovered = timeline.mondayForPage(page);
        expect(recovered, monday);
      }
    });

    test('week schedule helpers delegate to shared timeline', () {
      final day = DateTime(2026, 3, 30);
      final index = weekScheduleGlobalDayIndex(day);
      expect(weekScheduleDayFromGlobalIndex(index), day);
      expect(pageIndexForMonday(day), index ~/ 7);
      expect(mondayForPageIndex(index ~/ 7), AppDateTime.localMondayOfWeek(day));
    });
  });
}
