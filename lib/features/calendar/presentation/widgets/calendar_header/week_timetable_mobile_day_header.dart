import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:chronoapp/features/calendar/presentation/theme/calendar_presentation_theme.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_header/calendar_day_marker_pill.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

const _dayMarkerBottomOffset = 1.0;
const _dayMarkerWidth = 24.0;
const _dayMarkerHeight = 6.0;
const _rowHeight = 52.0;

/// Wochen-Kopf für schmale Viewports: eine Zeile mit 7 Tagen, sichtbare
/// Auswahl und Wochenwechsel per horizontalem Wischen.
class WeekTimetableMobileDayHeader extends ConsumerStatefulWidget {
  const WeekTimetableMobileDayHeader({super.key});

  @override
  ConsumerState<WeekTimetableMobileDayHeader> createState() =>
      _WeekTimetableMobileDayHeaderState();
}

class _WeekTimetableMobileDayHeaderState
    extends ConsumerState<WeekTimetableMobileDayHeader> {
  late final PageController _weekPageController;
  int? _lastProgrammaticPage;

  @override
  void initState() {
    super.initState();
    final monday = weekMondayLocal(ref.read(focusedDayProvider));
    final initialPage = pageIndexForMonday(monday);
    _weekPageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _weekPageController.dispose();
    super.dispose();
  }

  void _syncPageToFocusedWeek(DateTime? previous, DateTime next) {
    final targetPage = pageIndexForMonday(weekMondayLocal(next));

    void apply() {
      if (!mounted) return;
      if (!_weekPageController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) => apply());
        return;
      }
      final visible =
          _weekPageController.page?.round() ??
          _weekPageController.initialPage;
      if (visible == targetPage) return;
      _lastProgrammaticPage = targetPage;
      _weekPageController.jumpToPage(targetPage);
    }

    apply();
  }

  void _onWeekPageChanged(int index) {
    if (_lastProgrammaticPage == index) {
      _lastProgrammaticPage = null;
      return;
    }

    final monday = mondayForPageIndex(index);
    final selected = ref.read(selectedDayProvider);
    final weekdayOffset = (selected.weekday - DateTime.monday).clamp(0, 6);
    final newDay = monday.add(Duration(days: weekdayOffset));
    ref.read(selectedDayProvider.notifier).update(newDay);
    ref.read(focusedDayProvider.notifier).update(newDay);
  }

  void _onDayTapped(DateTime day) {
    ref.read(selectedDayProvider.notifier).update(day);
    ref.read(focusedDayProvider.notifier).update(day);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DateTime>(focusedDayProvider, _syncPageToFocusedWeek);

    final scheme = Theme.of(context).colorScheme;
    final todayAccent = CalendarPresentationTheme.todayAccentColor(context);
    final selectedDay = ref.watch(selectedDayProvider);
    final dayMarkersByDate = ref
        .watch(filteredCalendarAllEntriesProvider)
        .maybeWhen(
          data: buildCalendarDayMarkers,
          orElse: () => const <DateTime, CalendarDayMarkerData>{},
        );
    final activeChoirCount = ref.watch(
      calendarFiltersProvider.select((filters) => filters.choirs.length),
    );
    final markerColorResolver = CalendarMarkerColorResolver.standard(
      distinguishChoirs: activeChoirCount > 1,
    );
    final weekdayFmt = DateFormat.E('de_DE');

    return SizedBox(
      height: _rowHeight + _dayMarkerHeight + _dayMarkerBottomOffset + 4,
      child: PageView.builder(
        controller: _weekPageController,
        itemCount: kWeekPageCount,
        onPageChanged: _onWeekPageChanged,
        itemBuilder: (context, pageIndex) {
          final monday = mondayForPageIndex(pageIndex);
          return Row(
            children: List.generate(7, (i) {
              final day = monday.add(Duration(days: i));
              final isSelected = isSameDay(selectedDay, day);
              final isToday = AppDateTime.isTodayLocal(day);
              final marker = dayMarkersByDate[normalizeCalendarDay(day)];

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _onDayTapped(day),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
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
                          const SizedBox(height: 2),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? scheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                color: isSelected
                                    ? (isToday
                                          ? todayAccent
                                          : scheme.onPrimary)
                                    : (isToday
                                          ? todayAccent
                                          : scheme.onSurface),
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (marker != null && marker.totalMinutes > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: CalendarDayMarkerPill(
                                marker: marker,
                                width: _dayMarkerWidth,
                                height: _dayMarkerHeight,
                                colorResolver: markerColorResolver,
                              ),
                            ),
                        ],
                      ),
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
