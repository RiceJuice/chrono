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

/// Scroll-Physik für den Event-Sheet-Inhalt.
///
/// Oben geklammert (Sheet-Übergabe via [SheetScrollHandlingBehavior.onlyFromTop]),
/// unten mit Plattform-Overscroll: iOS-Bounce bzw. Android-Stretch.
ScrollPhysics eventModalContentScrollPhysics(BuildContext context) {
  const always = AlwaysScrollableScrollPhysics();
  final platform = Theme.of(context).platform;

  if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
    return const _EventModalTopClampingScrollPhysics(
      parent: BouncingScrollPhysics(parent: always),
    );
  }

  return const _EventModalTopClampingScrollPhysics(parent: always);
}

/// Material-Scroll-Verhalten für Event-Sheets — Android-Stretch am Listenende.
class EventModalScrollBehavior extends MaterialScrollBehavior {
  const EventModalScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    final platform = getPlatform(context);
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return child;
    }
    return StretchingOverscrollIndicator(
      axisDirection: details.direction,
      child: child,
    );
  }
}

/// Verhindert Overscroll am oberen Listenrand, lässt ihn am unteren Ende zu.
class _EventModalTopClampingScrollPhysics extends ScrollPhysics {
  const _EventModalTopClampingScrollPhysics({super.parent});

  @override
  _EventModalTopClampingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _EventModalTopClampingScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (value < position.pixels &&
        position.pixels <= position.minScrollExtent) {
      return value - position.pixels;
    }
    return super.applyBoundaryConditions(position, value);
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final tolerance = toleranceFor(position);
    if (position.pixels > position.maxScrollExtent) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        position.maxScrollExtent,
        velocity,
        tolerance: tolerance,
      );
    }
    if (position.pixels < position.minScrollExtent) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        position.minScrollExtent,
        velocity,
        tolerance: tolerance,
      );
    }
    return super.createBallisticSimulation(position, velocity);
  }
}
