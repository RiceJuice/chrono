import 'package:flutter/foundation.dart';
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
const double kCalendarSelectedDayContainerOffsetY = -2.0;
const double kCalendarSelectedDayFillOffsetY = 4.0;
const double kCalendarSelectedDayVisualOffsetY =
    kCalendarSelectedDayContainerOffsetY + kCalendarSelectedDayFillOffsetY;
const double kCalendarDayRowHeight = 40.0;

/// Wie [CalendarStyle.cellMargin] in [CustomTableCalendar] — Innenabstand pro Tageszelle.
const double kCalendarDayCellMargin = 2.0;
const double kCalendarDayCellContentHeight =
    kCalendarDayRowHeight - 2 * kCalendarDayCellMargin;

const double kCalendarDaysOfWeekHeight = 20.0;

/// Wochentags-Label im mobilen Wochenkopf etwas anheben, damit es zur
/// Tagesansicht passt (negativ = nach oben).
const double kCalendarWeekdayLabelOffsetY = -3.0;
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
///
/// Bewusst auf echte Handy-Plattformen (iOS/Android) beschränkt: Auf
/// Desktop/Web ist ein breites, niedriges Fenster der Normalfall und würde
/// sonst fälschlich den Vollbildmodus auslösen und u. a. die
/// Navigationsleiste (Material-Fallback) ausblenden.
bool calendarUsePhoneLandscapeChrome(BuildContext context) {
  final isMobilePlatform =
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android;
  if (kIsWeb || !isMobilePlatform) {
    return false;
  }
  if (MediaQuery.orientationOf(context) != Orientation.landscape) {
    return false;
  }
  return MediaQuery.sizeOf(context).shortestSide <
      kCalendarPhoneLayoutMaxShortestSide;
}
