import 'package:flutter/material.dart';

/// Horizontale Physik für den mobilen Wochen-Stundenplan: wie `PageScrollPhysics`,
/// aber mit **Tages-Spalten** als Seiten (nicht Viewport-Breite) und begrenztem
/// Flingsprung (1 Tag, bei sehr schnellem Wisch maximal 2).
///
/// Analog zum snappy `PageView` in `event_list.dart`: kein langes Ausrollen über
/// viele Tage — Zielposition immer per Feder-Simulation.
class WeekDaySnapScrollPhysics extends ScrollPhysics {
  const WeekDaySnapScrollPhysics({
    required this.dayColumnWidth,
    super.parent,
  });

  final double dayColumnWidth;

  /// Ab dieser normierten Geschwindigkeit (|v| / [dayColumnWidth]) darf ein
  /// zweiter Tag in Wischrichtung dazukommen.
  static const double _twoStepFlingNormVelocity = 7.5;

  @override
  WeekDaySnapScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      WeekDaySnapScrollPhysics(
        dayColumnWidth: dayColumnWidth,
        parent: buildParent(ancestor),
      );

  /// Steifere Feder: schnelleres Einrasten, weniger Nachlauf als zuvor.
  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(
        mass: 0.18,
        stiffness: 520.0,
        ratio: 1.14,
      );

  double _targetPixelsForBallistic(
    ScrollMetrics position,
    Tolerance tolerance,
    double velocity,
  ) {
    final w = dayColumnWidth;
    final maxExtent = position.maxScrollExtent;
    if (w <= 0) return position.pixels.clamp(0.0, maxExtent);

    final page = position.pixels / w;
    final double targetPage;
    if (velocity.abs() < tolerance.velocity) {
      targetPage = page.roundToDouble();
    } else {
      final sign = velocity > 0 ? 1.0 : -1.0;
      final adjustedPage = page + 0.5 * sign;
      final primary = adjustedPage.round();
      final norm = velocity.abs() / w;
      final extra = norm >= _twoStepFlingNormVelocity ? 1 : 0;
      targetPage = (primary + sign * extra).toDouble();
    }
    return (targetPage * w).clamp(0.0, maxExtent);
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    if (position.outOfRange) {
      return super.createBallisticSimulation(position, velocity);
    }

    final tolerance = toleranceFor(position);
    final w = dayColumnWidth;
    if (w <= 0) {
      return super.createBallisticSimulation(position, velocity);
    }

    final target = _targetPixelsForBallistic(position, tolerance, velocity);
    if ((target - position.pixels).abs() < tolerance.distance) {
      return null;
    }

    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }
}
