import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Ein-/Ausblend-Animation für den Kalender-Suchmodus (Shell-Overlay).
abstract final class CalendarSearchEntranceTransition {
  static const duration = Duration(milliseconds: 400);
  static const reverseDuration = Duration(milliseconds: 360);

  /// Spring-nahe Kurve — passend zu [CNTabBarSearchStyle.animationDuration].
  static const curve = Cubic(0.2, 1.0, 0.3, 1.0);
  static const reverseCurve = Cubic(0.4, 0.0, 0.6, 1.0);

  static double _t(Animation<double> animation) =>
      animation.value.clamp(0.0, 1.0);

  /// Kalender-Inhalt: leicht nach unten, dezenter Zoom-Out und Abdunklung.
  static Widget backdrop({
    required Animation<double> animation,
    required Widget child,
    bool reduceMotion = false,
  }) {
    if (reduceMotion) return child;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final eased = curve.transform(_t(animation));
        return Transform.translate(
          offset: Offset(0, eased * 8),
          child: Transform.scale(
            scale: lerpDouble(1.0, 0.985, eased)!,
            alignment: Alignment.topCenter,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.06 * eased),
                BlendMode.darken,
              ),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }

  /// Such-Overlay: Reveal von unten mit leichtem Lift und Scale.
  static Widget layer({
    required Animation<double> animation,
    required Widget child,
    bool reduceMotion = false,
  }) {
    if (reduceMotion) return child;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = _t(animation);
        final slide = curve.transform(t);
        final fade = const Interval(0.0, 0.75, curve: Curves.easeOut)
            .transform(t);
        final reveal = lerpDouble(0.9, 1.0, slide)!;

        return Opacity(
          opacity: fade,
          child: ClipRect(
            child: Align(
              alignment: Alignment.bottomCenter,
              heightFactor: reveal,
              child: Transform.translate(
                offset: Offset(0, (1 - slide) * 28),
                child: Transform.scale(
                  scale: lerpDouble(0.988, 1.0, slide)!,
                  alignment: Alignment.bottomCenter,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }

  /// Titelzeile „Suchen“ — leicht verzögert von oben.
  static Widget titleRow({
    required Animation<double> animation,
    required Widget child,
    bool reduceMotion = false,
  }) {
    if (reduceMotion) return child;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = const Interval(0.14, 0.88, curve: Curves.easeOutCubic)
            .transform(_t(animation));
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * -14),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Filter-Chips — noch etwas später.
  static Widget filtersRow({
    required Animation<double> animation,
    required Widget child,
    bool reduceMotion = false,
  }) {
    if (reduceMotion) return child;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = const Interval(0.24, 1.0, curve: Curves.easeOutCubic)
            .transform(_t(animation));
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * -10),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
