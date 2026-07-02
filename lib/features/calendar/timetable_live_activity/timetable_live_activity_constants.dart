/// Vorlauf bis zum ersten Unterricht, ab dem die Live Activity startet.
const int kTimetableLiveActivityPreStartMinutes = 15;

/// App Group für iOS Live Activities (Runner + Widget Extension).
const String kTimetableLiveActivityKind = 'timetable';

/// Host für den Deep Link in den Tages-Stundenplan.
const String kTimetableLiveActivityDeepLinkHost = 'timetable';

/// Stable Activity-ID pro Kalendertag (lokales Datum yyyy-MM-dd).
String liveActivityCustomIdForTimetableDay(String dayDateKey) =>
    'timetable_$dayDateKey';

/// Lokales Datum als Schlüssel (Europe/Berlin via [AppDateTime]).
String timetableDayDateKey(DateTime localDay) {
  final y = localDay.year.toString().padLeft(4, '0');
  final m = localDay.month.toString().padLeft(2, '0');
  final d = localDay.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Deep Link, wenn die Nutzer:in die Stundenplan-Live Activity antippt.
String timetableLiveActivityDeepLinkForDay(String dayDateKey) {
  return 'chronoapp://$kTimetableLiveActivityDeepLinkHost'
      '?date=${Uri.encodeQueryComponent(dayDateKey)}';
}

/// Liest den Tages-Schlüssel aus einem Stundenplan-Deep-Link.
String? parseTimetableLiveActivityDayDateKey(Uri uri) {
  final date = uri.queryParameters['date']?.trim();
  if (date == null || date.isEmpty) return null;

  if (uri.scheme == 'chronoapp' &&
      uri.host == kTimetableLiveActivityDeepLinkHost) {
    return date;
  }

  if (uri.path == '/timetable' || uri.path == 'timetable') {
    return date;
  }

  if (uri.host == kTimetableLiveActivityDeepLinkHost && uri.path.isEmpty) {
    return date;
  }

  return null;
}

bool isTimetableLiveActivityDeepLink(Uri uri) =>
    parseTimetableLiveActivityDayDateKey(uri) != null;
