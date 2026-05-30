import 'package:flutter/material.dart';
import 'day_page.dart';

/// Feder und Geschwindigkeit für Tageswechsel-Overlays (UIKit-artig: lang, weich, ohne Snap).
abstract final class DayContentTransitionPhysics {
  static final SpringDescription spring = SpringDescription.withDampingRatio(
    mass: 1.15,
    stiffness: 155,
    ratio: 0.98,
  );

  static const Tolerance tolerance = Tolerance(
    velocity: 0.008,
    distance: 0.0008,
  );

  static double simulationVelocityFor({
    required int pageDelta,
    double swipeSpeed = 0,
  }) {
    if (swipeSpeed > 0) {
      return swipeSpeed.clamp(0.15, 1.0);
    }
    return (0.08 + pageDelta * 0.035).clamp(0.08, 0.45);
  }
}

/// Horizontaler Push mit Crossfade — analog iOS-Kalender beim Tippen auf einen Tag.
class DayContentSlideTransition extends StatelessWidget {
  const DayContentSlideTransition({
    super.key,
    required this.outgoing,
    required this.incoming,
    required this.isForward,
    required this.animation,
    required this.backgroundColor,
  });

  final Widget outgoing;
  final Widget incoming;
  final bool isForward;
  final Animation<double> animation;
  final Color backgroundColor;

  static const double _slideFraction = 0.20;

  @override
  Widget build(BuildContext context) {
    final direction = isForward ? 1.0 : -1.0;
    final motion = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
    );

    final outgoingSlide = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(-direction * _slideFraction, 0),
    ).animate(motion);
    final incomingSlide = Tween<Offset>(
      begin: Offset(direction * _slideFraction, 0),
      end: Offset.zero,
    ).animate(motion);

    final outgoingFade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.88, curve: Curves.easeInOut),
      ),
    );
    final incomingFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.08, 1.0, curve: Curves.easeInOut),
      ),
    );

    return IgnorePointer(
      child: ColoredBox(
        color: backgroundColor,
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              FadeTransition(
                opacity: outgoingFade,
                child: SlideTransition(
                  position: outgoingSlide,
                  child: outgoing,
                ),
              ),
              FadeTransition(
                opacity: incomingFade,
                child: SlideTransition(
                  position: incomingSlide,
                  child: incoming,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
    return DayContentSlideTransition(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isForward: isForward,
      animation: animation,
      outgoing: DayPage(
        key: ValueKey<String>('from-$fromDate'),
        date: fromDate,
      ),
      incoming: DayPage(
        key: ValueKey<String>('to-$toDate'),
        date: toDate,
      ),
    );
  }
}
