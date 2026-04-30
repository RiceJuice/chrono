import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:chronoapp/core/time/app_date_time.dart';
import '../../providers/calendar_providers.dart';
import '../../theme/calendar_presentation_theme.dart';
import 'calendar_day_marker_pill.dart';

const _selectedDayBoxSize = 36.5;
const _dayMarkerBottomOffset = 1.0;
const _dayMarkerWidth = 24.0;
const _dayMarkerHeight = 6.0;

class CustomTableCalendar extends ConsumerStatefulWidget {
  const CustomTableCalendar({
    super.key,
    required this.calendarFormat,
    required this.onFormatChanged,
  });

  final CalendarFormat calendarFormat;
  final ValueChanged<CalendarFormat> onFormatChanged;

  @override
  ConsumerState<CustomTableCalendar> createState() =>
      _CustomTableCalendarState();
}

class _CustomTableCalendarState extends ConsumerState<CustomTableCalendar> {
  DateTime? _pendingProgrammaticFocusedDay;

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  DateTime _startOfWeek(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final offsetFromMonday = normalizedDay.weekday - DateTime.monday;
    return DateTime(
      normalizedDay.year,
      normalizedDay.month,
      normalizedDay.day - offsetFromMonday,
    );
  }

  DateTime _selectedDayForPage(
    DateTime focusedDay,
    DateTime currentSelectedDay,
  ) {
    final normalizedFocusedDay = DateTime(
      focusedDay.year,
      focusedDay.month,
      focusedDay.day,
    );

    switch (widget.calendarFormat) {
      case CalendarFormat.month:
        final today = AppDateTime.todayLocal();
        if (today.year == normalizedFocusedDay.year &&
            today.month == normalizedFocusedDay.month) {
          return today;
        }
        return DateTime(
          normalizedFocusedDay.year,
          normalizedFocusedDay.month,
          1,
        );
      case CalendarFormat.week:
        final weekStart = _startOfWeek(normalizedFocusedDay);
        final weekdayOffset = currentSelectedDay.weekday - DateTime.monday;
        return DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + weekdayOffset,
        );
      case CalendarFormat.twoWeeks:
        return normalizedFocusedDay;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final todayAccentColor = CalendarPresentationTheme.todayAccentColor(
      context,
    );
    final selectedDay = ref.watch(selectedDayProvider);
    final focusedDay = ref.watch(focusedDayProvider);
    final dayMarkersByDate = ref
        .watch(filteredCalendarAllEntriesProvider)
        .maybeWhen(
          data: buildCalendarDayMarkers,
          orElse: () => const <DateTime, CalendarDayMarkerData>{},
        );
    ref.listen<DateTime>(selectedDayProvider, (previous, next) {
      final currentFocusedDay = ref.read(focusedDayProvider);
      if (!isSameDay(currentFocusedDay, next)) {
        _pendingProgrammaticFocusedDay = AppDateTime.localDay(next);
        ref.read(focusedDayProvider.notifier).update(next);
      }
    });

    return TableCalendar(
      locale: 'de_DE',
      startingDayOfWeek: StartingDayOfWeek.monday,
      firstDay: DateTime(2020, 1, 1), //TODO: make this dynamic
      lastDay: DateTime(2030, 12, 31), //TODO: make this dynamic
      calendarFormat: widget.calendarFormat,
      focusedDay: focusedDay,
      pageJumpingEnabled: true,
      eventLoader: (day) {
        final marker = dayMarkersByDate[normalizeCalendarDay(day)];
        if (marker == null) return const [];
        return <CalendarDayMarkerData>[marker];
      },
      rowHeight: 40,
      daysOfWeekHeight: 20,
      availableGestures: AvailableGestures.horizontalSwipe,
      headerVisible: false,
      calendarStyle: CalendarStyle(
        cellMargin: const EdgeInsets.all(2),
        selectedDecoration: BoxDecoration(
          color: scheme.primary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        todayDecoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
          color: CalendarPresentationTheme.todayAccentColor(context),
          fontWeight: FontWeight.w700,
        ),
        weekendTextStyle: TextStyle(color: scheme.onSurface),
        outsideTextStyle: TextStyle(
          color: scheme.onSurface.withValues(alpha: 0.3),
        ),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: false,
        leftChevronVisible: false,
        rightChevronVisible: false,
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          if (isSameDay(day, selectedDay)) return const SizedBox.shrink();
          if (events.isEmpty) return null;
          final marker = events.first;
          if (marker is! CalendarDayMarkerData || marker.totalMinutes <= 0) {
            return null;
          }
          return Positioned(
            bottom: _dayMarkerBottomOffset,
            child: CalendarDayMarkerPill(
              marker: marker,
              width: _dayMarkerWidth,
              height: _dayMarkerHeight,
            ),
          );
        },
        selectedBuilder: (context, day, focusedDay) {
          if (widget.calendarFormat == CalendarFormat.month &&
              !_isSameMonth(day, focusedDay)) {
            return Container(
              margin: const EdgeInsets.all(2),
              alignment: Alignment.center,
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
            );
          }

          final isToday = AppDateTime.isTodayLocal(day);
          final marker = dayMarkersByDate[normalizeCalendarDay(day)];

          return Center(
            child: Transform.translate(
              offset: const Offset(0, -2),
              child: SizedBox.square(
                dimension: _selectedDayBoxSize,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Transform.translate(
                        offset: const Offset(0, 4),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        color: isToday ? todayAccentColor : scheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Positioned(
                      bottom: _dayMarkerBottomOffset,
                      child: CalendarDayMarkerPill(
                        marker: marker,
                        width: _dayMarkerWidth,
                        height: _dayMarkerHeight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        todayBuilder: (context, day, focusedDay) {
          if (isSameDay(day, selectedDay)) return null;
          return Container(
            margin: const EdgeInsets.all(2),
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: todayAccentColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        },
      ),
      selectedDayPredicate: (day) => isSameDay(selectedDay, day),
      onFormatChanged: widget.onFormatChanged,
      onDaySelected: (newSelectedDay, newFocusedDay) {
        final currentSelectedDay = ref.read(selectedDayProvider);
        if (isSameDay(currentSelectedDay, newSelectedDay)) return;
        ref.read(selectedDayProvider.notifier).update(newSelectedDay);
        ref.read(focusedDayProvider.notifier).update(newFocusedDay);
      },
      onPageChanged: (newFocusedDay) {
        final pendingProgrammaticFocusedDay = _pendingProgrammaticFocusedDay;
        final isProgrammaticMonthJump =
            pendingProgrammaticFocusedDay != null &&
            widget.calendarFormat == CalendarFormat.month &&
            _isSameMonth(pendingProgrammaticFocusedDay, newFocusedDay);
        if (isProgrammaticMonthJump ||
            (pendingProgrammaticFocusedDay != null &&
                isSameDay(pendingProgrammaticFocusedDay, newFocusedDay))) {
          _pendingProgrammaticFocusedDay = null;
          ref
              .read(focusedDayProvider.notifier)
              .update(pendingProgrammaticFocusedDay);
          return;
        }
        _pendingProgrammaticFocusedDay = null;
        final currentSelectedDay = ref.read(selectedDayProvider);
        final nextSelectedDay = _selectedDayForPage(
          newFocusedDay,
          currentSelectedDay,
        );
        ref.read(selectedDayProvider.notifier).update(nextSelectedDay);
        ref.read(focusedDayProvider.notifier).update(nextSelectedDay);
      },
    );
  }
}
