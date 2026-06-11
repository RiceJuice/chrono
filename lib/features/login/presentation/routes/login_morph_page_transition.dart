import 'package:flutter/material.dart';

/// Dauer des Login-Crossfade-Slides — bewusst langsam fuer einen ruhigen,
/// luxorioesen Wechsel ohne harten Sprung.
const Duration kLoginMorphDuration = Duration(milliseconds: 480);

/// Dezenter horizontaler Versatz — weniger Bewegung, dafuer laengerer Crossfade.
const double _kSlideFraction = 0.12;

/// Weiche Gesamtkurve: langsamer Start und Ende, kein abruptes Einsetzen.
const Curve _kMotionCurve = Cubic(0.25, 0.1, 0.25, 1.0);

/// Gestreckte Fade-Intervalle fuer einen laengeren, ueberlappenden Crossfade.
const Curve _kOutgoingFadeCurve =
    Interval(0.0, 0.88, curve: Curves.easeInOutCubic);
const Curve _kIncomingFadeCurve =
    Interval(0.06, 0.94, curve: Curves.easeInOutCubic);

/// Horizontaler Push mit Crossfade — wie der externe Tageswechsel in der Event-Liste,
/// nur etwas laenger und weicher.
///
/// Eintretende Seite gleitet leicht herein und blendet ein, die verdeckte Seite
/// wandert dezent in die Gegenrichtung und blendet aus. Beide Surfaces bleiben
/// opak und vollflaechig, damit kein Flackern durch halbtransparente Routes entsteht.
Widget buildLoginMorphPageTransition({
  required BuildContext context,
  required Animation<double> animation,
  required Animation<double> secondaryAnimation,
  required Widget child,
  required bool forward,
}) {
  final bg = Theme.of(context).scaffoldBackgroundColor;
  final direction = forward ? 1.0 : -1.0;

  final enterSlide = Tween<Offset>(
    begin: Offset(direction * _kSlideFraction, 0),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: animation,
      curve: _kMotionCurve,
      reverseCurve: _kMotionCurve.flipped,
    ),
  );

  final exitSlide = Tween<Offset>(
    begin: Offset.zero,
    end: Offset(-direction * _kSlideFraction, 0),
  ).animate(
    CurvedAnimation(
      parent: secondaryAnimation,
      curve: _kMotionCurve,
      reverseCurve: _kMotionCurve.flipped,
    ),
  );

  final enterFade = Tween<double>(begin: 0, end: 1).animate(
    CurvedAnimation(
      parent: animation,
      curve: _kIncomingFadeCurve,
      reverseCurve: _kIncomingFadeCurve.flipped,
    ),
  );

  final exitFade = Tween<double>(begin: 1, end: 0).animate(
    CurvedAnimation(
      parent: secondaryAnimation,
      curve: _kOutgoingFadeCurve,
      reverseCurve: _kOutgoingFadeCurve.flipped,
    ),
  );

  final pageSurface = ColoredBox(
    color: bg,
    child: SizedBox.expand(child: child),
  );

  return ClipRect(
    child: AnimatedBuilder(
      animation: Listenable.merge([enterSlide, exitSlide, enterFade, exitFade]),
      child: pageSurface,
      builder: (context, surface) {
        final opacity = (enterFade.value * exitFade.value).clamp(0.0, 1.0);
        final dx = enterSlide.value.dx + exitSlide.value.dx;

        return Opacity(
          opacity: opacity,
          child: FractionalTranslation(
            translation: Offset(dx, 0),
            child: surface,
          ),
        );
      },
    ),
  );
}
