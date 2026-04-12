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
    final outgoingEndX = isForward ? -1.0 : 1.0;
    final incomingStartX = isForward ? 1.0 : -1.0;

    return IgnorePointer(
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Stack(
          children: [
            SlideTransition(
              position: Tween<Offset>(
                begin: Offset.zero,
                end: Offset(outgoingEndX, 0),
              ).animate(animation),
              child: DayPage(
                key: ValueKey<String>('from-$fromDate'),
                date: fromDate,
              ),
            ),
            SlideTransition(
              position: Tween<Offset>(
                begin: Offset(incomingStartX, 0),
                end: Offset.zero,
              ).animate(animation),
              child: DayPage(
                key: ValueKey<String>('to-$toDate'),
                date: toDate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
