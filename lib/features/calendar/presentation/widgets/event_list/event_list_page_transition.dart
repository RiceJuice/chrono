import 'package:flutter/material.dart';
import 'day_page.dart';

/// Kurze Dauer; bei höherer gemessener Wisch-Geschwindigkeit (Seiten/s) etwas kürzer.
/// Overlay: [AnimationController] mit linearem Fortschritt (kein Ease).
Duration eventListTransitionDuration(double normalizedSwipeSpeed) {
  const maxMs = 88;
  const minMs = 40;
  final speed = normalizedSwipeSpeed.abs().clamp(0.0, 14.0);
  final ms =
      (maxMs / (1.0 + speed * 0.5)).round().clamp(minMs, maxMs);
  return Duration(milliseconds: ms);
}

/// Längere Dauer für Navigation ohne Swipe-Geschwindigkeit (z. B. Header-Auswahl).
Duration eventListSelectionTransitionDuration(int pageDelta) {
  const baseMs = 200;
  const maxMs = 350;
  final ms = (baseMs + pageDelta.abs() * 10).clamp(baseMs, maxMs);
  return Duration(milliseconds: ms);
}

class EventListPageTransition extends StatelessWidget {
  const EventListPageTransition({
    super.key,
    required this.fromDate,
    required this.toDate,
    required this.isForward,
    required this.animation,
  });

  final DateTime fromDate;
  final DateTime toDate;
  final bool isForward;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final outgoingEndY = isForward ? -1.0 : 1.0;
    final incomingStartY = isForward ? 1.0 : -1.0;

    final slideCurve = Curves.easeOutCubic;
    final outgoingSlide = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(0, outgoingEndY),
    ).animate(CurvedAnimation(parent: animation, curve: slideCurve));
    final incomingSlide = Tween<Offset>(
      begin: Offset(0, incomingStartY),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: slideCurve));

    final outgoingFade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.18, curve: Curves.easeOutCubic),
      ),
    );
    final incomingFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.08, 1.0, curve: Curves.easeInCubic),
      ),
    );

    return IgnorePointer(
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Stack(
          children: [
            FadeTransition(
              opacity: outgoingFade,
              child: SlideTransition(
                position: outgoingSlide,
                child: DayPage(
                  key: ValueKey<String>('from-$fromDate'),
                  date: fromDate,
                ),
              ),
            ),
            FadeTransition(
              opacity: incomingFade,
              child: SlideTransition(
                position: incomingSlide,
                child: DayPage(
                  key: ValueKey<String>('to-$toDate'),
                  date: toDate,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
