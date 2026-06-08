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

/// Hilft [SheetScrollHandlingBehavior.onlyFromTop]: kleine Rest-Offsets nach
/// Scroll-Ende auf 0 setzen — ohne mitten in der Geste zu springen.
class EventModalScrollNearTopSnap extends StatefulWidget {
  const EventModalScrollNearTopSnap({
    super.key,
    required this.controller,
    required this.child,
    this.threshold = 14,
  });

  final ScrollController controller;
  final Widget child;
  final double threshold;

  @override
  State<EventModalScrollNearTopSnap> createState() =>
      _EventModalScrollNearTopSnapState();
}

class _EventModalScrollNearTopSnapState extends State<EventModalScrollNearTopSnap> {
  bool _snapPending = false;

  bool _onScrollNotification(ScrollNotification notification) {
    if (_snapPending ||
        notification is! ScrollEndNotification ||
        !widget.controller.hasClients) {
      return false;
    }

    final offset = widget.controller.offset;
    if (offset <= 0 || offset > widget.threshold) {
      return false;
    }

    _snapPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _snapPending = false;
      if (!mounted || !widget.controller.hasClients) return;

      final currentOffset = widget.controller.offset;
      if (currentOffset > 0 && currentOffset <= widget.threshold) {
        widget.controller.jumpTo(0);
      }
    });
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: widget.child,
    );
  }
}

/// Scroll-Physik für den Event-Sheet-Inhalt — kein iOS-Bounce am oberen Rand.
ScrollPhysics eventModalContentScrollPhysics(BuildContext context) {
  return const ClampingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  );
}
