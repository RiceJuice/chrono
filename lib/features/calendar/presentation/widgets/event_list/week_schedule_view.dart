import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_week_layout_tokens.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_grid.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_layout.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_navigation.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WeekScheduleView extends ConsumerStatefulWidget {
  const WeekScheduleView({super.key});

  @override
  ConsumerState<WeekScheduleView> createState() => _WeekScheduleViewState();
}

class _WeekScheduleViewState extends ConsumerState<WeekScheduleView> {
  late final PageController _weekPageController;
  int? _lastProgrammaticPage;
  double _timelineScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    final monday = weekMondayLocal(ref.read(focusedDayProvider));
    _weekPageController = PageController(
      initialPage: pageIndexForMonday(monday),
    );
  }

  @override
  void dispose() {
    _weekPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DateTime>(focusedDayProvider, _syncPageToFocusedWeek);

    return Stack(
      children: [
        Positioned.fill(
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleScheduleScrollNotification,
            child: Padding(
              padding: const EdgeInsets.only(
                left: kCalendarTimelineGutterWidth,
              ),
              child: PageView.builder(
                controller: _weekPageController,
                itemCount: kWeekPageCount,
                onPageChanged: _handlePageChanged,
                itemBuilder: (context, pageIndex) {
                  return WeekScheduleGrid(
                    monday: mondayForPageIndex(pageIndex),
                    showTimelineColumn: false,
                  );
                },
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: kCalendarTimelineGutterWidth,
          child: IgnorePointer(child: _buildFixedTimeline(context)),
        ),
      ],
    );
  }

  Widget _buildFixedTimeline(BuildContext context) {
    final monday = weekMondayLocal(ref.watch(focusedDayProvider));
    final weekDays = List<DateTime>.generate(
      7,
      (index) => monday.add(Duration(days: index)),
    );
    final asyncDays = weekDays
        .map((day) => ref.watch(filteredCalendarEntriesForDayProvider(day)))
        .toList(growable: false);

    if (asyncDays.any((day) => day.isLoading || day.hasError)) {
      return const SizedBox.shrink();
    }

    final entriesByDay = asyncDays
        .map((asyncDay) => asyncDay.requireValue)
        .toList(growable: false);
    final bounds = computeWeekScheduleBounds(entriesByDay);
    if (bounds == null) return const SizedBox.shrink();

    final totalHeight = bounds.heightForHourHeight(kWeekScheduleHourHeight);
    final showCurrentTime = weekDays.any(AppDateTime.isTodayLocal);

    return ClipRect(
      child: Transform.translate(
        offset: Offset(0, -_timelineScrollOffset),
        child: WeekTimelineColumn(
          bounds: bounds,
          totalHeight: totalHeight,
          showCurrentTime: showCurrentTime,
        ),
      ),
    );
  }

  bool _handleScheduleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    final offset = notification.metrics.pixels.clamp(
      0.0,
      notification.metrics.maxScrollExtent,
    );
    if ((offset - _timelineScrollOffset).abs() > 0.5) {
      setState(() {
        _timelineScrollOffset = offset;
      });
    }
    return false;
  }

  void _syncPageToFocusedWeek(DateTime? previous, DateTime next) {
    final targetPage = pageIndexForMonday(weekMondayLocal(next));
    if (!_weekPageController.hasClients) return;

    final currentPage =
        _weekPageController.page?.round() ?? _weekPageController.initialPage;
    if (currentPage == targetPage) return;

    _lastProgrammaticPage = targetPage;
    if (_timelineScrollOffset != 0) {
      setState(() {
        _timelineScrollOffset = 0;
      });
    }
    _weekPageController.jumpToPage(targetPage);
  }

  void _handlePageChanged(int index) {
    if (_timelineScrollOffset != 0) {
      setState(() {
        _timelineScrollOffset = 0;
      });
    }

    if (_lastProgrammaticPage == index) {
      _lastProgrammaticPage = null;
      return;
    }

    ref.read(focusedDayProvider.notifier).update(mondayForPageIndex(index));
  }
}
