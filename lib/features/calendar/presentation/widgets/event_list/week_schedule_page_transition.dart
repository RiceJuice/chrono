import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_grid.dart';
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
              child: WeekScheduleGrid(
                key: ValueKey<String>('from-$fromMonday'),
                monday: fromMonday,
                showTimelineColumn: false,
              ),
            ),
            SlideTransition(
              position: Tween<Offset>(
                begin: Offset(incomingStartX, 0),
                end: Offset.zero,
              ).animate(animation),
              child: WeekScheduleGrid(
                key: ValueKey<String>('to-$toMonday'),
                monday: toMonday,
                showTimelineColumn: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
