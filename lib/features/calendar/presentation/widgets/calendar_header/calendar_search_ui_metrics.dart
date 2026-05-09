/// Gleiche Dauer wie der Body-Morph in [CalendarPage], damit Overlay-Slide und
/// Morph-Transition gemeinsam enden.
const Duration kCalendarSearchMorphDuration = Duration(milliseconds: 380);

/// Vertikale Maße des Such-Overlays — der untere Inset in [CalendarPage] muss
/// dieselben Werte verwenden wie [CalendarSearchOverlay].
class CalendarSearchOverlayMetrics {
  CalendarSearchOverlayMetrics._();

  static const double topPadding = 12;
  static const double bottomPadding = 8;
  static const double inputRowHeight = 48;
  static const double inputToChipsGap = 10;
  static const double chipRowExtent = 40;
}
