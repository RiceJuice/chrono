import 'package:flutter/material.dart';

/// @deprecated Verwende [calendarIsTabletLayout] — orientierungsstabil über
/// [kCalendarPhoneLayoutMaxShortestSide], nicht über die Breite.
const double kCalendarTabletBreakpoint = 900;

/// Breite der linken Spalne: Zeitachse im Raster und Ausgleich im Kalender-Header.
const double kCalendarTimelineGutterWidth = 56;

/// Gemeinsame Maße für Tageszellen und Marker-Pillen (TableCalendar + mobiler Wochenkopf).
const double kCalendarDayMarkerBottomOffset = 1.0;
const double kCalendarDayMarkerWidth = 24.0;
const double kCalendarDayMarkerHeight = 6.0;

const double kCalendarSelectedDayBoxSize = 36.5;
const double kCalendarDayRowHeight = 40.0;
const double kCalendarDaysOfWeekHeight = 20.0;
const double kCalendarWeekDayHeaderHeight =
    kCalendarDaysOfWeekHeight + kCalendarDayRowHeight;

/// Oberhalb gilt als Tablet; darunter als Handy (Material compact, ca. Phone).
const double kCalendarPhoneLayoutMaxShortestSide = 600;

/// Tablet-Layout: kürzere Kante >= 600dp — gilt in Portrait und Landscape gleich.
bool calendarIsTabletLayout(BuildContext context) {
  return MediaQuery.sizeOf(context).shortestSide >=
      kCalendarPhoneLayoutMaxShortestSide;
}

bool calendarIsPhoneLayout(BuildContext context) =>
    !calendarIsTabletLayout(context);

/// Querformat-Sonderlayout (Vollbild, ohne AppBar, ohne untere Nav): nur **Handy**
/// im Landscape — Tablets bleiben unverändert.
bool calendarUsePhoneLandscapeChrome(BuildContext context) {
  if (MediaQuery.orientationOf(context) != Orientation.landscape) {
    return false;
  }
  return MediaQuery.sizeOf(context).shortestSide <
      kCalendarPhoneLayoutMaxShortestSide;
}
