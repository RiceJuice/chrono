import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_all_day_section_metrics.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_grid.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_viewport.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/event_list_page_transition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WeekSchedulePageTransition extends ConsumerWidget {
  const WeekSchedulePageTransition({
    super.key,
    required this.fromMonday,
    required this.toMonday,
    required this.isForward,
    required this.animation,
    this.scrollPadding = EdgeInsets.zero,
  });

  final DateTime fromMonday;
  final DateTime toMonday;
  final bool isForward;
  final Animation<double> animation;
  final EdgeInsets scrollPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hourHeight = weekScheduleHourHeightFor(context);
    final allDaySectionHeight = resolveWeekAllDaySectionHeight(
      ref,
      focusMonday: fromMonday,
      transitionFromMonday: fromMonday,
      transitionToMonday: toMonday,
    );

    return DayContentSlideTransition(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isForward: isForward,
      animation: animation,
      outgoing: WeekScheduleGrid(
        key: ValueKey<String>('from-$fromMonday'),
        monday: fromMonday,
        showTimelineColumn: false,
        hourHeight: hourHeight,
        allDaySectionHeight: allDaySectionHeight,
        scrollPadding: scrollPadding,
      ),
      incoming: WeekScheduleGrid(
        key: ValueKey<String>('to-$toMonday'),
        monday: toMonday,
        showTimelineColumn: false,
        hourHeight: hourHeight,
        allDaySectionHeight: allDaySectionHeight,
        scrollPadding: scrollPadding,
      ),
    );
  }
}
