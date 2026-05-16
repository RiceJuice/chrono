import 'package:flutter/material.dart';

/// Horizontale Physik für den mobilen Wochen-Stundenplan: snappy Einrasten auf
/// [snapStride] (ein Tag oder eine Woche) mit begrenztem Flingsprung.
///
/// [dayColumnWidth] dient nur der normierten Flug-Geschwindigkeit.
class WeekScheduleSnapScrollPhysics extends ScrollPhysics {
  const WeekScheduleSnapScrollPhysics({
    required this.snapStride,
    required this.dayColumnWidth,
    super.parent,
  });

  final double snapStride;
  final double dayColumnWidth;

  /// Ab dieser normierten Geschwindigkeit (|v| / [dayColumnWidth]) darf ein
  /// zweiter Schritt in Wischrichtung dazukommen.
  static const double _twoStepFlingNormVelocity = 7.5;

  @override
  WeekScheduleSnapScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      WeekScheduleSnapScrollPhysics(
        snapStride: snapStride,
        dayColumnWidth: dayColumnWidth,
        parent: buildParent(ancestor),
      );

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
    final stride = snapStride;
    final maxExtent = position.maxScrollExtent;
    if (stride <= 0) return position.pixels.clamp(0.0, maxExtent);

    final page = position.pixels / stride;
    final double targetPage;
    if (velocity.abs() < tolerance.velocity) {
      targetPage = page.roundToDouble();
    } else {
      final sign = velocity > 0 ? 1.0 : -1.0;
      final adjustedPage = page + 0.5 * sign;
      final primary = adjustedPage.round();
      final norm = velocity.abs() / dayColumnWidth;
      final extra = norm >= _twoStepFlingNormVelocity ? 1 : 0;
      targetPage = (primary + sign * extra).toDouble();
    }
    return (targetPage * stride).clamp(0.0, maxExtent);
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
    if (snapStride <= 0) {
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
