import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

/// Festere Sheet-Physik fürs Event-Modal — weniger zufälliges Mitgeben beim Scrollen.
///
/// [ClampingSheetPhysics] ohne Bounce-Overshoot; höherer Drag-Start-Schwellwert
/// als iOS-Default, damit leichte vertikale Scrolls nicht sofort das Sheet mitnehmen.
class EventModalSheetPhysics extends ClampingSheetPhysics {
  const EventModalSheetPhysics({super.spring});

  @override
  double? get dragStartDistanceMotionThreshold => 10;
}

/// Anteil sichtbarer Sheet-Höhe, unter dem ein Loslassen zum Schließen führt.
const double kAppEventModalDismissCommitSize = 0.42;

/// Route-Dismiss: etwas strenger als smooth_sheets-Default (2.0 / 0.3).
SwipeDismissSensitivity appEventModalSwipeDismissSensitivity() {
  return SwipeDismissSensitivity(
    minFlingVelocityRatio: 2.35,
    dismissalOffset: SheetOffset.proportionalToViewport(
      kAppEventModalDismissCommitSize,
    ),
  );
}

/// Scroll-Physik für den Event-Sheet-Inhalt — kein iOS-Bounce am oberen Rand.
ScrollPhysics eventModalContentScrollPhysics(BuildContext context) {
  return const ClampingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  );
}
