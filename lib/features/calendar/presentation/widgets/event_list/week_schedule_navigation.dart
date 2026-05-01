import 'package:chronoapp/core/time/app_date_time.dart';

/// Montag der Kalenderwoche (lokal), [day] nur Datumsteil relevant.
DateTime weekMondayLocal(DateTime day) {
  final normalized = AppDateTime.localDay(day);
  final offsetFromMonday = normalized.weekday - DateTime.monday;
  return DateTime(
    normalized.year,
    normalized.month,
    normalized.day - offsetFromMonday,
  );
}

/// Genügend großer Wochenbereich für den bestehenden Kalender-Header.
final DateTime kWeekPageAnchorMonday = DateTime(2018, 1, 1);

const int kWeekPageCount = 700;

int pageIndexForMonday(DateTime monday) {
  final days = monday.difference(kWeekPageAnchorMonday).inDays;
  final page = days ~/ 7;
  return page.clamp(0, kWeekPageCount - 1);
}

DateTime mondayForPageIndex(int page) {
  return kWeekPageAnchorMonday.add(Duration(days: page * 7));
}
