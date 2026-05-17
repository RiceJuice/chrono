import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_navigation.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_viewport.dart';
import '../../providers/calendar_providers.dart';
import '../../theme/calendar_presentation_theme.dart';
import 'calendar_day_cell.dart';
import 'calendar_day_marker_pill.dart';
import 'calendar_day_spring_interaction.dart';
import 'week_timetable_mobile_day_header.dart';
import '../calendar_week_layout_tokens.dart';
const _calendarMorphDuration = Duration(milliseconds: 420);
const _calendarMorphCurve = Cubic(0.2, 0.8, 0.2, 1);

class CustomTableCalendar extends ConsumerStatefulWidget {
  const CustomTableCalendar({
    super.key,
    required this.calendarFormat,
    required this.onFormatChanged,
    this.weekTimetableMode = false,
    this.leftGutterWidth = 0,
  });

  final CalendarFormat calendarFormat;
  final ValueChanged<CalendarFormat> onFormatChanged;
  final bool weekTimetableMode;
  final double leftGutterWidth;

  @override
  ConsumerState<CustomTableCalendar> createState() =>
      _CustomTableCalendarState();
}

class _CustomTableCalendarState extends ConsumerState<CustomTableCalendar> {
  DateTime? _pendingProgrammaticFocusedDay;

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  bool get _dayInteractionEnabled => !widget.weekTimetableMode;

  /// Tages-Snap (Phone-Portrait): runde Auswahlbox + leere Pille.
  /// Wochen-Snap (Landscape/Tablet): nur normale Zellen, Pillen außer am Auswahltag.
  bool _showSelectedDayIndicator(BuildContext context) {
    if (!widget.weekTimetableMode) return true;
    return weekSchedulePanStrideFor(context) == WeekSchedulePanStride.day;
  }

  Widget _wrapDayInteraction(Widget child) {
    return CalendarDaySpringInteraction(
      enabled: _dayInteractionEnabled,
      child: child,
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
        return AppDateTime.sameWeekdayInWeekOf(
          weekReference: normalizedFocusedDay,
          weekdaySource: currentSelectedDay,
        );
      case CalendarFormat.twoWeeks:
        return normalizedFocusedDay;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.weekTimetableMode) {
      return AnimatedPadding(
        duration: _calendarMorphDuration,
        curve: _calendarMorphCurve,
        padding: EdgeInsets.only(left: widget.leftGutterWidth),
        child: WeekTimetableMobileDayHeader(
          showSelectedDayIndicator: _showSelectedDayIndicator(context),
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final todayAccentColor = CalendarPresentationTheme.todayAccentColor(
      context,
    );
    final selectedDay = ref.watch(selectedDayProvider);
    final focusedDay = ref.watch(focusedDayProvider);
    final showSelectedDayIndicator = _showSelectedDayIndicator(context);
    final dayMarkersByDate = ref
        .watch(filteredCalendarAllEntriesProvider)
        .maybeWhen(
          data: buildCalendarDayMarkers,
          orElse: () => const <DateTime, CalendarDayMarkerData>{},
        );
    // Pill colour rule: as soon as the user has more than one choir active
    // in the calendar filter, choir- *and* event-type segments are tinted
    // by their associated choir so the user can tell different choirs
    // apart at a glance. With a single (or no) choir selected, the plain
    // per-type colours are used.
    final activeChoirCount = ref.watch(
      calendarFiltersProvider.select((filters) => filters.choirs.length),
    );
    final markerColorResolver = CalendarMarkerColorResolver.standard(
      distinguishChoirs: activeChoirCount > 1,
    );
    ref.listen<DateTime>(selectedDayProvider, (previous, next) {
      if (widget.weekTimetableMode) return;
      final currentFocusedDay = ref.read(focusedDayProvider);
      if (!isSameDay(currentFocusedDay, next)) {
        _pendingProgrammaticFocusedDay = AppDateTime.localDay(next);
        ref.read(focusedDayProvider.notifier).update(next);
      }
    });

    final table = TableCalendar(
      locale: 'de_DE',
      startingDayOfWeek: StartingDayOfWeek.monday,
      firstDay: kCalendarTableFirstDay,
      lastDay: kCalendarTableLastDay,
      calendarFormat: widget.calendarFormat,
      focusedDay: focusedDay,
      pageJumpingEnabled: true,
      pageAnimationEnabled: !widget.weekTimetableMode,
      eventLoader: (day) {
        final marker = dayMarkersByDate[normalizeCalendarDay(day)];
        if (marker == null) return const [];
        return <CalendarDayMarkerData>[marker];
      },
      rowHeight: kCalendarDayRowHeight,
      daysOfWeekHeight: kCalendarDaysOfWeekHeight,
      availableGestures: widget.weekTimetableMode
          ? AvailableGestures.none
          : AvailableGestures.horizontalSwipe,
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
          if (isSameDay(day, selectedDay) && showSelectedDayIndicator) {
            return const SizedBox.shrink();
          }
          if (events.isEmpty) return null;
          final marker = events.first;
          if (marker is! CalendarDayMarkerData || marker.totalMinutes <= 0) {
            return null;
          }
          return CalendarDayMarkerSlot(
            marker: marker,
            colorResolver: markerColorResolver,
          );
        },
        defaultBuilder: (context, day, focusedDay) {
          final isOutsideMonth =
              widget.calendarFormat == CalendarFormat.month &&
              !_isSameMonth(day, focusedDay);
          return _wrapDayInteraction(
            Container(
              margin: const EdgeInsets.all(2),
              alignment: Alignment.center,
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: isOutsideMonth
                      ? scheme.onSurface.withValues(alpha: 0.3)
                      : scheme.onSurface,
                ),
              ),
            ),
          );
        },
        outsideBuilder: (context, day, focusedDay) {
          return _wrapDayInteraction(
            Container(
              margin: const EdgeInsets.all(2),
              alignment: Alignment.center,
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ),
          );
        },
        selectedBuilder: (context, day, focusedDay) {
          if (!showSelectedDayIndicator) {
            return null;
          }
          if (widget.calendarFormat == CalendarFormat.month &&
              !_isSameMonth(day, focusedDay)) {
            return _wrapDayInteraction(
              Container(
                margin: const EdgeInsets.all(2),
                alignment: Alignment.center,
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ),
            );
          }

          final marker = dayMarkersByDate[normalizeCalendarDay(day)];

          return _wrapDayInteraction(
            CalendarDaySelectionAppear(
              day: day,
              child: CalendarSelectedDayCell(
                day: day,
                marker: marker,
                colorResolver: markerColorResolver,
              ),
            ),
          );
        },
        todayBuilder: (context, day, focusedDay) {
          if (isSameDay(day, selectedDay) && showSelectedDayIndicator) {
            return null;
          }
          return _wrapDayInteraction(
            Container(
              margin: const EdgeInsets.all(2),
              alignment: Alignment.center,
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: todayAccentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
      selectedDayPredicate: showSelectedDayIndicator
          ? (day) => isSameDay(selectedDay, day)
          : (_) => false,
      onFormatChanged: widget.onFormatChanged,
      onDaySelected: (newSelectedDay, newFocusedDay) {
        if (widget.weekTimetableMode) return;
        final currentSelectedDay = ref.read(selectedDayProvider);
        if (isSameDay(currentSelectedDay, newSelectedDay)) return;
        ref.read(selectedDayProvider.notifier).update(
              newSelectedDay,
              origin: CalendarDaySelectionOrigin.tap,
            );
        ref.read(focusedDayProvider.notifier).update(newFocusedDay);
      },
      onPageChanged: (newFocusedDay) {
        final pendingProgrammaticFocusedDay = _pendingProgrammaticFocusedDay;
        if (widget.weekTimetableMode) {
          if (pendingProgrammaticFocusedDay != null &&
              isSameDay(
                pendingProgrammaticFocusedDay,
                AppDateTime.localDay(newFocusedDay),
              )) {
            _pendingProgrammaticFocusedDay = null;
            ref
                .read(focusedDayProvider.notifier)
                .update(pendingProgrammaticFocusedDay);
            return;
          }
          _pendingProgrammaticFocusedDay = null;
          ref
              .read(focusedDayProvider.notifier)
              .update(AppDateTime.localDay(newFocusedDay));
          return;
        }
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

    return AnimatedPadding(
      duration: _calendarMorphDuration,
      curve: _calendarMorphCurve,
      padding: EdgeInsets.only(left: widget.leftGutterWidth),
      child: table,
    );
  }
}
