import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_grid.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_viewport.dart';
import 'package:flutter/material.dart';

class WeekSchedulePageTransition extends StatelessWidget {
  const WeekSchedulePageTransition({
    super.key,
    required this.fromMonday,
    required this.toMonday,
    required this.isForward,
    required this.animation,
  });

  final DateTime fromMonday;
  final DateTime toMonday;
  final bool isForward;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final hourHeight = weekScheduleHourHeightFor(context);
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
                child: WeekScheduleGrid(
                  key: ValueKey<String>('from-$fromMonday'),
                  monday: fromMonday,
                  showTimelineColumn: false,
                  hourHeight: hourHeight,
                ),
              ),
            ),
            FadeTransition(
              opacity: incomingFade,
              child: SlideTransition(
                position: incomingSlide,
                child: WeekScheduleGrid(
                  key: ValueKey<String>('to-$toMonday'),
                  monday: toMonday,
                  showTimelineColumn: false,
                  hourHeight: hourHeight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
