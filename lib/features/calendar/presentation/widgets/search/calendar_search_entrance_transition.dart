import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Ein-/Ausblend-Animation für den Kalender-Suchmodus (Shell-Overlay).
abstract final class CalendarSearchEntranceTransition {
  static const duration = Duration(milliseconds: 440);
  static const reverseDuration = Duration(milliseconds: 360);

  /// Snappy ease-out — wirkt lebendig, ohne zu springen.
  static const curve = Cubic(0.16, 1.0, 0.3, 1.0);
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
        final eased = Curves.easeOutCubic.transform(_t(animation));
        return Transform.translate(
          offset: Offset(0, eased * 10),
          child: Transform.scale(
            scale: lerpDouble(1.0, 0.97, eased)!,
            alignment: Alignment.topCenter,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.08 * eased),
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
        final fade = const Interval(0.0, 0.7, curve: Curves.easeOut).transform(t);
        final reveal = lerpDouble(0.88, 1.0, slide)!;

        return Opacity(
          opacity: fade,
          child: ClipRect(
            child: Align(
              alignment: Alignment.bottomCenter,
              heightFactor: reveal,
              child: Transform.translate(
                offset: Offset(0, (1 - slide) * 32),
                child: Transform.scale(
                  scale: lerpDouble(0.982, 1.0, slide)!,
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
        final t = const Interval(0.16, 0.9, curve: Curves.easeOutCubic)
            .transform(_t(animation));
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * -16),
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
        final t = const Interval(0.26, 1.0, curve: Curves.easeOutCubic)
            .transform(_t(animation));
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * -12),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
