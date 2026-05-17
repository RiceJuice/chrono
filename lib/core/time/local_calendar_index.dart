import 'package:chronoapp/core/time/app_date_time.dart';

/// DST-sichere Indexierung lokaler Kalendertage ab einem festen Ankertag.
///
/// Verwendet dieselbe Arithmetik wie [AppDateTime.localCalendarDayNumber] /
/// [AppDateTime.addLocalCalendarDays] — keine [Duration]-basierten Tageszählungen.
class LocalCalendarIndex {
  LocalCalendarIndex(DateTime anchor) : _anchor = AppDateTime.localDay(anchor);

  final DateTime _anchor;

  DateTime get anchor => _anchor;

  DateTime normalize(DateTime day) => AppDateTime.localDay(day);

  int indexOf(DateTime day) => AppDateTime.localCalendarDaysBetween(_anchor, day);

  DateTime dayAt(int index) => AppDateTime.addLocalCalendarDays(_anchor, index);

  /// Seitenindex für einen Montag in einer wöchentlichen [PageView].
  int weekPageIndex(DateTime monday, {required int pageCount}) {
    return (indexOf(monday) ~/ 7).clamp(0, pageCount - 1);
  }

  DateTime mondayForPage(int page) => dayAt(page * 7);
}
