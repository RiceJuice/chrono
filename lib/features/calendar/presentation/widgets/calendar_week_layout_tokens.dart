import 'package:flutter/material.dart';

/// Gemeinsame Layout-Werte für die Tablet-Wochenansicht (Header + Raster).
const double kCalendarTabletBreakpoint = 900;

/// Breite der linken Spalne: Zeitachse im Raster und Ausgleich im Kalender-Header.
const double kCalendarTimelineGutterWidth = 56;

/// Oberhalb gilt als Tablet; darunter als Handy (Material compact, ca. Phone).
const double kCalendarPhoneLayoutMaxShortestSide = 600;

/// Querformat-Sonderlayout (Vollbild, ohne AppBar, ohne untere Nav): nur **Handy**
/// im Landscape — Tablets bleiben unverändert.
bool calendarUsePhoneLandscapeChrome(BuildContext context) {
  if (MediaQuery.orientationOf(context) != Orientation.landscape) {
    return false;
  }
  return MediaQuery.sizeOf(context).shortestSide <
      kCalendarPhoneLayoutMaxShortestSide;
}
