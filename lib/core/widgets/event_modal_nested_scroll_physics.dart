import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Scroll-Physics für die verschachtelte Ablauf-Liste im Event-Sheet.
///
/// Die innere Liste scrollt eigenständig. Nur am oberen Rand und bei
/// Ziehen nach unten wird der äußere Sheet-Scroll zurückgesetzt, bevor
/// das Modal verkleinert werden kann.
class EventModalNestedScrollPhysics extends ScrollPhysics {
  const EventModalNestedScrollPhysics({
    required this.outerScrollController,
    this.topTolerance = 0.5,
    super.parent,
  });

  final ScrollController outerScrollController;
  final double topTolerance;

  @override
  EventModalNestedScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return EventModalNestedScrollPhysics(
      outerScrollController: outerScrollController,
      topTolerance: topTolerance,
      parent: const ClampingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
    );
  }

  bool _isAtTop(ScrollMetrics position) =>
      position.pixels <= position.minScrollExtent + topTolerance;

  bool _outerIsAtTop() {
    if (!outerScrollController.hasClients) return true;
    return outerScrollController.position.pixels <= topTolerance;
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // Nur am oberen Rand der inneren Liste und nur beim Runterziehen
    // (positiver Offset) an den äußeren Scroll koppeln.
    if (offset <= 0 || !_isAtTop(position) || !outerScrollController.hasClients) {
      return super.applyPhysicsToUserOffset(position, offset);
    }

    final outer = outerScrollController.position;
    var remaining = offset;

    if (outer.pixels > topTolerance) {
      final consumed = math.min(remaining, outer.pixels);
      final target = outer.pixels - consumed;
      if (outer.pixels != target) {
        outer.jumpTo(target);
      }
      remaining -= consumed;
    } else if (outer.pixels > 0) {
      outer.jumpTo(0);
    }

    if (remaining <= 0 || !_outerIsAtTop()) {
      return 0;
    }

    // Beide Scrolls oben: inneren Bounce unterdrücken — das äußere Sheet
    // übernimmt das Runterziehen über seinen eigenen SheetScrollController.
    return 0;
  }
}
