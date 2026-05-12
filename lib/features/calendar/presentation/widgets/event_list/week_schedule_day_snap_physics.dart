import 'package:flutter/material.dart';

/// Rastet horizontale Scrollpositionen auf Vielfache von [dayColumnWidth] ein
/// (langsames Loslassen / geringe Endgeschwindigkeit).
///
/// Schnelle Wisch-Gesten enden oft zwischen Gitterpunkten; in diesem Fall
/// ergänzt der Aufrufer nach [ScrollEndNotification] ein kurzes `animateTo`.
class WeekDaySnapScrollPhysics extends ScrollPhysics {
  const WeekDaySnapScrollPhysics({
    required this.dayColumnWidth,
    super.parent,
  });

  final double dayColumnWidth;

  @override
  WeekDaySnapScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      WeekDaySnapScrollPhysics(
        dayColumnWidth: dayColumnWidth,
        parent: buildParent(ancestor),
      );

  double _snapTarget(double pixels, double maxExtent) {
    if (dayColumnWidth <= 0) return pixels.clamp(0.0, maxExtent);
    final page = (pixels / dayColumnWidth).roundToDouble();
    return (page * dayColumnWidth).clamp(0.0, maxExtent);
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final tolerance = toleranceFor(position);
    if (velocity.abs() >= tolerance.velocity || position.outOfRange) {
      return super.createBallisticSimulation(position, velocity);
    }

    final snapped = _snapTarget(position.pixels, position.maxScrollExtent);
    if ((snapped - position.pixels).abs() < tolerance.distance) {
      return null;
    }
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      snapped,
      velocity,
      tolerance: tolerance,
    );
  }
}
