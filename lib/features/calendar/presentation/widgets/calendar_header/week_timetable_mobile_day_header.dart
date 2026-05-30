import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:chronoapp/features/calendar/presentation/theme/calendar_presentation_theme.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_header/calendar_break_range_bar.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_header/calendar_day_cell.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_header/calendar_day_spring_interaction.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_header/calendar_header_entry_range.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_header/calendar_sliding_day_selection.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_header/calendar_day_marker_pill.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_week_layout_tokens.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

/// Wie [TableCalendar] mit `pageAnimationEnabled` (package table_calendar).
const Curve _kWeekPageAnimCurve = Curves.easeOutCubic;

/// Wochen-Kopf für schmale Viewports: eine Zeile mit 7 Tagen, sichtbare
/// Auswahl und Wochenwechsel per horizontalem Wischen.
class WeekTimetableMobileDayHeader extends ConsumerStatefulWidget {
  const WeekTimetableMobileDayHeader({
    this.showSelectedDayIndicator = true,
    super.key,
  });

  /// Bei [WeekSchedulePanStride.week]: keine Auswahlbox, Pillen nur an nicht
  /// ausgewählten Tagen (siehe [CustomTableCalendar]).
  final bool showSelectedDayIndicator;

  @override
  ConsumerState<WeekTimetableMobileDayHeader> createState() =>
      _WeekTimetableMobileDayHeaderState();
}

class _WeekTimetableMobileDayHeaderState
    extends ConsumerState<WeekTimetableMobileDayHeader> {
  late final PageController _weekPageController;
  int? _programmaticTargetPage;

  @override
  void initState() {
    super.initState();
    final monday = AppDateTime.localMondayOfWeek(ref.read(focusedDayProvider));
    final initialPage = pageIndexForMonday(monday);
    _weekPageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _weekPageController.dispose();
    super.dispose();
  }

  Duration _durationForPageDelta(int delta) {
    return Duration(
      milliseconds: (delta.clamp(1, 6) * 55 + 320).clamp(320, 580).round(),
    );
  }

  void _syncPageToWeek(DateTime day, {required bool animated}) {
    final targetPage = pageIndexForMonday(AppDateTime.localMondayOfWeek(day));

    void apply() {
      if (!mounted) return;
      if (!_weekPageController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) => apply());
        return;
      }

      final visible =
          _weekPageController.page?.round() ?? _weekPageController.initialPage;
      if (visible == targetPage) return;

      _programmaticTargetPage = targetPage;

      if (animated) {
        final delta = (targetPage - visible).abs();
        _weekPageController
            .animateToPage(
              targetPage,
              duration: _durationForPageDelta(delta),
              curve: _kWeekPageAnimCurve,
            )
            .whenComplete(() {
              if (mounted && _programmaticTargetPage == targetPage) {
                _programmaticTargetPage = null;
              }
            });
      } else {
        _weekPageController.jumpToPage(targetPage);
        _programmaticTargetPage = null;
      }
    }

    apply();
  }

  void _onWeekPageChanged(int index) {
    if (_programmaticTargetPage != null) {
      if (index == _programmaticTargetPage) {
        _programmaticTargetPage = null;
      }
      return;
    }

    final monday = mondayForPageIndex(index);
    final selected = ref.read(selectedDayProvider);
    final newDay = AppDateTime.sameWeekdayInWeekOf(
      weekReference: monday,
      weekdaySource: selected,
    );
    ref.read(selectedDayProvider.notifier).update(newDay);
    ref.read(focusedDayProvider.notifier).update(newDay);
  }

  void _onDayTapped(DateTime day) {
    ref.read(weekScheduleScrollDayProvider.notifier).clear();
    ref
        .read(selectedDayProvider.notifier)
        .update(day, origin: CalendarDaySelectionOrigin.tap);
    ref.read(focusedDayProvider.notifier).update(day);
  }

  int _selectedColumnIndex(DateTime monday, DateTime highlightDay) {
    final mondayLocal = DateTime(monday.year, monday.month, monday.day);
    final highlightLocal = DateTime(
      highlightDay.year,
      highlightDay.month,
      highlightDay.day,
    );
    final delta = highlightLocal.difference(mondayLocal).inDays;
    if (delta >= 0 && delta < 7) return delta;
    return highlightDay.weekday - 1;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DateTime?>(weekScheduleScrollDayProvider, (previous, next) {
      if (next == null) return;
      // Vorschau beim Wischen: Seite ohne Animation nachziehen, sonst
      // überlappen PageView-Übergänge mit AnimatedSwitcher-Updates.
      _syncPageToWeek(next, animated: false);
    });

    ref.listen<DateTime>(selectedDayProvider, (previous, next) {
      if (previous == null) return;
      _syncPageToWeek(next, animated: true);
    });

    ref.listen<DateTime>(focusedDayProvider, (previous, next) {
      if (previous == null) return;
      if (AppDateTime.isSameLocalWeek(previous, next)) {
        return;
      }
      _syncPageToWeek(next, animated: false);
    });

    final scheme = Theme.of(context).colorScheme;
    final scrollPreviewDay = ref.watch(weekScheduleScrollDayProvider);
    final selectedDay = ref.watch(selectedDayProvider);
    final highlightDay = scrollPreviewDay ?? selectedDay;
    final headerRange = calendarWeekHeaderEntryRange(highlightDay);
    final dayMarkersByDate = ref
        .watch(filteredCalendarEntriesInLocalRangeProvider(headerRange))
        .maybeWhen(
          data: buildCalendarDayMarkers,
          orElse: () => const <DateTime, CalendarDayMarkerData>{},
        );
    final breakRangeByDate = ref
        .watch(calendarBreakDaysInLocalRangeProvider(headerRange))
        .maybeWhen(
          data: buildBreakRangeSegmentsFromDays,
          orElse: () => const <DateTime, CalendarBreakRangeSegment>{},
        );
    final holidayDays = ref
        .watch(calendarHolidayDaysInLocalRangeProvider(headerRange))
        .maybeWhen(
          data: (days) => days.map(normalizeCalendarDay).toSet(),
          orElse: () => const <DateTime>{},
        );
    final activeChoirCount = ref.watch(
      calendarFiltersProvider.select((filters) => filters.choirs.length),
    );
    final markerColorResolver = CalendarMarkerColorResolver.standard(
      distinguishChoirs: activeChoirCount > 1,
      palette: CalendarMarkerColorPalette.standard.copyWith(
        byType: <CalendarEntryType, Color>{
          ...CalendarMarkerColorPalette.standard.byType,
          CalendarEntryType.breakType: CalendarPresentationTheme.holidayBlue(
            context,
          ),
        },
      ),
    );
    final vacationRangeColor = CalendarPresentationTheme.vacationRangeBarColor(
      context,
    );
    final weekdayFmt = DateFormat.E('de_DE');

    return SizedBox(
      height: kCalendarWeekDayHeaderHeight,
      child: PageView.builder(
        controller: _weekPageController,
        itemCount: kWeekPageCount,
        onPageChanged: _onWeekPageChanged,
        itemBuilder: (context, pageIndex) {
          final monday = mondayForPageIndex(pageIndex);

          Widget buildVacationBarRow() {
            return Row(
              children: List.generate(7, (columnIndex) {
                final day = AppDateTime.addLocalCalendarDays(monday, columnIndex);
                final normalizedDay = normalizeCalendarDay(day);
                final breakSegment = breakRangeByDate[normalizedDay];

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(kCalendarDayCellMargin),
                    child: CalendarDayVacationShell(
                      breakRangeSegment: breakSegment,
                      breakRangeColor: vacationRangeColor,
                      child: const SizedBox.expand(),
                    ),
                  ),
                );
              }),
            );
          }

          Widget buildDayRow({required bool useSlidingSelectionOverlay}) {
            return Row(
              children: List.generate(7, (columnIndex) {
                final day = AppDateTime.addLocalCalendarDays(monday, columnIndex);
                final normalizedDay = normalizeCalendarDay(day);
                final isSelected = isSameDay(highlightDay, day);
                final isToday = AppDateTime.isTodayLocal(day);
                final marker = dayMarkersByDate[normalizedDay];
                final breakSegment = breakRangeByDate[normalizedDay];
                final isHoliday = holidayDays.contains(normalizedDay);

                final dayCell = _buildDayCell(
                  context: context,
                  day: day,
                  normalizedDay: normalizedDay,
                  isSelected: isSelected,
                  isToday: isToday,
                  isHoliday: isHoliday,
                  marker: marker,
                  markerColorResolver: markerColorResolver,
                  useSlidingSelectionOverlay: useSlidingSelectionOverlay,
                );

                final cellContent = useSlidingSelectionOverlay
                    ? dayCell
                    : CalendarDayVacationShell(
                        breakRangeSegment: breakSegment,
                        breakRangeColor: vacationRangeColor,
                        child: dayCell,
                      );

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(kCalendarDayCellMargin),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _onDayTapped(day),
                        borderRadius: BorderRadius.circular(10),
                        child: CalendarDaySpringInteraction(child: cellContent),
                      ),
                    ),
                  ),
                );
              }),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: List.generate(7, (i) {
                  final day = AppDateTime.addLocalCalendarDays(monday, i);
                  return Expanded(
                    child: SizedBox(
                      height: kCalendarDaysOfWeekHeight,
                      child: Center(
                        child: Transform.translate(
                          offset: const Offset(
                            0,
                            kCalendarWeekdayLabelOffsetY,
                          ),
                          child: Text(
                          weekdayFmt.format(day),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.65),
                                fontWeight: FontWeight.w600,
                              ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(
                height: kCalendarDayRowHeight,
                child: widget.showSelectedDayIndicator
                    ? Stack(
                        fit: StackFit.expand,
                        clipBehavior: Clip.none,
                        children: [
                          buildVacationBarRow(),
                          CalendarSlidingDaySelectionLayer(
                            selectedIndex: _selectedColumnIndex(
                              monday,
                              highlightDay,
                            ),
                            itemCount: 7,
                            animate: scrollPreviewDay == null,
                            child: buildDayRow(useSlidingSelectionOverlay: true),
                          ),
                        ],
                      )
                    : buildDayRow(useSlidingSelectionOverlay: false),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDayCell({
    required BuildContext context,
    required DateTime day,
    required DateTime normalizedDay,
    required bool isSelected,
    required bool isToday,
    required bool isHoliday,
    required CalendarDayMarkerData? marker,
    required CalendarMarkerColorResolver markerColorResolver,
    required bool useSlidingSelectionOverlay,
  }) {
    final showSelected = isSelected && widget.showSelectedDayIndicator;
    final dayKey = normalizedDay.millisecondsSinceEpoch;
    final holidayColor = isHoliday
        ? CalendarPresentationTheme.holidayBlue(context)
        : null;

    if (useSlidingSelectionOverlay) {
      final scheme = Theme.of(context).colorScheme;
      final todayAccent = CalendarPresentationTheme.todayAccentColor(context);
      return CalendarDayNumberCell(
        key: ValueKey('slide-$dayKey'),
        day: day,
        marker: marker,
        isToday: isToday,
        colorResolver: markerColorResolver,
        showEmptyPill: showSelected,
        dayNumberColor: showSelected
            ? (holidayColor ?? (isToday ? todayAccent : scheme.onPrimary))
            : holidayColor,
      );
    }

    if (showSelected) {
      return CalendarSelectedDayCell(
        key: ValueKey('sel-$dayKey'),
        day: day,
        marker: marker,
        colorResolver: markerColorResolver,
        dayNumberColor: holidayColor,
      );
    }

    return CalendarDayNumberCell(
      key: ValueKey('num-$dayKey'),
      day: day,
      marker: marker,
      isToday: isToday,
      colorResolver: markerColorResolver,
      dayNumberColor: holidayColor,
    );
  }
}
