import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:chronoapp/features/calendar/presentation/theme/calendar_presentation_theme.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_header/calendar_break_range_bar.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_header/calendar_day_cell.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_header/calendar_header_entry_range.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_header/calendar_day_marker_pill.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_week_layout_tokens.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_navigation.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_viewport.dart';
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
      milliseconds: (delta.clamp(1, 6) * 40 + 220).clamp(220, 420).round(),
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
    ref.read(selectedDayProvider.notifier).update(day);
    ref.read(focusedDayProvider.notifier).update(day);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DateTime?>(weekScheduleScrollDayProvider, (previous, next) {
      if (next == null) return;
      final stride = weekSchedulePanStrideFor(context);
      _syncPageToWeek(next, animated: stride == WeekSchedulePanStride.day);
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
          return Row(
            children: List.generate(7, (i) {
              final day = AppDateTime.addLocalCalendarDays(monday, i);
              final isSelected = isSameDay(highlightDay, day);
              final isToday = AppDateTime.isTodayLocal(day);
              final marker = dayMarkersByDate[normalizeCalendarDay(day)];
              final breakSegment = breakRangeByDate[normalizeCalendarDay(day)];
              final normalizedDay = normalizeCalendarDay(day);
              final isHoliday = holidayDays.contains(normalizedDay);

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _onDayTapped(day),
                    borderRadius: BorderRadius.circular(10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: kCalendarDaysOfWeekHeight,
                          child: Center(
                            child: Text(
                              weekdayFmt.format(day),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.65,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: kCalendarDayRowHeight,
                          child: CalendarDayVacationShell(
                            breakRangeSegment: breakSegment,
                            breakRangeColor: vacationRangeColor,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child:
                                  isSelected && widget.showSelectedDayIndicator
                                  ? CalendarSelectedDayCell(
                                      key: ValueKey<DateTime>(day),
                                      day: day,
                                      marker: marker,
                                      colorResolver: markerColorResolver,
                                      dayNumberColor: isHoliday
                                          ? CalendarPresentationTheme.holidayBlue(
                                              context,
                                            )
                                          : null,
                                    )
                                  : CalendarDayNumberCell(
                                      key: ValueKey('n-$day'),
                                      day: day,
                                      marker: isSelected ? null : marker,
                                      isToday: isToday,
                                      colorResolver: markerColorResolver,
                                      dayNumberColor: isHoliday
                                          ? CalendarPresentationTheme.holidayBlue(
                                              context,
                                            )
                                          : null,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
