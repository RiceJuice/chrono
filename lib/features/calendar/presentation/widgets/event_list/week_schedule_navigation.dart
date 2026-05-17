import 'package:chronoapp/core/time/local_calendar_index.dart';

/// Genügend großer Wochenbereich für Kalender-Header und Wochen-[PageView].
final DateTime kWeekPageAnchorMonday = DateTime(2018, 1, 1);

const int kWeekPageCount = 700;

/// Anzahl Tages-Slots in der nahtlosen Mobile-ListView (= [kWeekPageCount] Wochen).
const int kWeekScheduleTotalDaySlots = kWeekPageCount * 7;

final LocalCalendarIndex kWeekScheduleDayIndex = LocalCalendarIndex(
  kWeekPageAnchorMonday,
);

/// Gleicher Zeitraum wie [kWeekPageCount] — für [TableCalendar.firstDay]/[lastDay].
final DateTime kCalendarTableFirstDay = kWeekScheduleDayIndex.anchor;

final DateTime kCalendarTableLastDay = kWeekScheduleDayIndex.dayAt(
  kWeekScheduleTotalDaySlots - 1,
);

int pageIndexForMonday(DateTime monday) =>
    kWeekScheduleDayIndex.weekPageIndex(monday, pageCount: kWeekPageCount);

DateTime mondayForPageIndex(int page) => kWeekScheduleDayIndex.mondayForPage(page);

int weekScheduleGlobalDayIndex(DateTime day) => kWeekScheduleDayIndex
    .indexOf(day)
    .clamp(0, kWeekScheduleTotalDaySlots - 1);

DateTime weekScheduleDayFromGlobalIndex(int globalDayIndex) =>
    kWeekScheduleDayIndex.dayAt(
      globalDayIndex.clamp(0, kWeekScheduleTotalDaySlots - 1),
    );
