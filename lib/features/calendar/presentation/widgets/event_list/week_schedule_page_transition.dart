import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_grid.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_viewport.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/event_list_page_transition.dart';
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

    return DayContentSlideTransition(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isForward: isForward,
      animation: animation,
      outgoing: WeekScheduleGrid(
        key: ValueKey<String>('from-$fromMonday'),
        monday: fromMonday,
        showTimelineColumn: false,
        hourHeight: hourHeight,
      ),
      incoming: WeekScheduleGrid(
        key: ValueKey<String>('to-$toMonday'),
        monday: toMonday,
        showTimelineColumn: false,
        hourHeight: hourHeight,
      ),
    );
  }
}
