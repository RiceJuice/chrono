import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Dauer des speziellen Einstiegs-Übergangs Start ↔ Credentials.
const Duration kLoginEntryDuration = Duration(milliseconds: 720);

const Curve _kPrimaryCurve = Curves.easeOutCubic;
const Curve _kExitCurve = Curves.easeInCubic;

/// Übergang Startscreen → Credentials: Marke gleitet weg, Formular steigt ein.
Widget buildLoginEntryTransition({
  required BuildContext context,
  required Animation<double> animation,
  required Animation<double> secondaryAnimation,
  required Widget child,
  required bool forward,
}) {
  final bg = Theme.of(context).scaffoldBackgroundColor;
  final direction = forward ? 1.0 : -1.0;

  final enterSlide = Tween<Offset>(
    begin: Offset(0, direction * 0.1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: animation, curve: _kPrimaryCurve));

  final exitSlide = Tween<Offset>(
    begin: Offset.zero,
    end: Offset(0, -direction * 0.08),
  ).animate(CurvedAnimation(parent: secondaryAnimation, curve: _kExitCurve));

  final enterFade = Tween<double>(begin: 0, end: 1).animate(
    CurvedAnimation(
      parent: animation,
      curve: const Interval(0.12, 1.0, curve: Curves.easeOut),
    ),
  );

  final exitFade = Tween<double>(begin: 1, end: 0).animate(
    CurvedAnimation(
      parent: secondaryAnimation,
      curve: const Interval(0.0, 0.65, curve: Curves.easeIn),
    ),
  );

  final enterScale = Tween<double>(begin: 0.96, end: 1.0).animate(
    CurvedAnimation(
      parent: animation,
      curve: const Interval(0.12, 1.0, curve: Curves.easeOutBack),
    ),
  );

  final exitScale = Tween<double>(begin: 1.0, end: 0.95).animate(
    CurvedAnimation(
      parent: secondaryAnimation,
      curve: const Interval(0.0, 0.55, curve: Curves.easeInCubic),
    ),
  );

  final blurSigma = Tween<double>(begin: 0, end: 1).animate(
    CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ),
  );

  final pageSurface = ColoredBox(
    color: bg,
    child: SizedBox.expand(child: child),
  );

  return ClipRect(
    child: AnimatedBuilder(
      animation: Listenable.merge([
        enterSlide,
        exitSlide,
        enterFade,
        exitFade,
        enterScale,
        exitScale,
        blurSigma,
      ]),
      child: pageSurface,
      builder: (context, surface) {
        final opacity = (enterFade.value * exitFade.value).clamp(0.0, 1.0);
        final slide = enterSlide.value + exitSlide.value;
        final scale = (enterScale.value * exitScale.value).clamp(0.9, 1.0);
        final incomingBlur = forward ? (1 - blurSigma.value) * 4.0 : 0.0;

        Widget revealed = surface!;

        if (incomingBlur > 0.1) {
          revealed = ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: incomingBlur,
              sigmaY: incomingBlur,
            ),
            child: revealed,
          );
        }

        return Opacity(
          opacity: opacity,
          child: FractionalTranslation(
            translation: slide,
            child: Transform.scale(
              scale: scale,
              alignment:
                  forward ? Alignment.bottomCenter : Alignment.topCenter,
              child: revealed,
            ),
          ),
        );
      },
    ),
  );
}
