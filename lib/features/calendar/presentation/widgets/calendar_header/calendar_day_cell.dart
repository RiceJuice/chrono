import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/presentation/theme/calendar_presentation_theme.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_header/calendar_day_marker_pill.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_week_layout_tokens.dart';
import 'package:flutter/material.dart';

/// Marker-Pille am unteren Zellenrand — gleiches Layout wie früher
/// `Positioned(bottom: …)` im [TableCalendar.markerBuilder].
class CalendarDayMarkerSlot extends StatelessWidget {
  const CalendarDayMarkerSlot({
    required this.marker,
    required this.colorResolver,
    this.showEmptyPill = false,
    super.key,
  });

  final CalendarDayMarkerData? marker;
  final CalendarMarkerColorResolver colorResolver;

  /// Leere Pille nur für den ausgewählten Tag ([CalendarSelectedDayCell]).
  final bool showEmptyPill;

  @override
  Widget build(BuildContext context) {
    final hasEvents = marker != null && marker!.totalMinutes > 0;
    if (!hasEvents && !showEmptyPill) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: kCalendarDayMarkerBottomOffset,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: CalendarDayMarkerPill(
          marker: hasEvents ? marker : null,
          width: kCalendarDayMarkerWidth,
          height: kCalendarDayMarkerHeight,
          colorResolver: colorResolver,
        ),
      ),
    );
  }
}

/// Normale Tageszahl mit Marker-Pille (mobiler Wochenkopf u. ä.).
class CalendarDayNumberCell extends StatelessWidget {
  const CalendarDayNumberCell({
    required this.day,
    required this.colorResolver,
    this.marker,
    this.isToday = false,
    super.key,
  });

  final DateTime day;
  final CalendarDayMarkerData? marker;
  final CalendarMarkerColorResolver colorResolver;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final todayAccent = CalendarPresentationTheme.todayAccentColor(context);

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Center(
          child: Text(
            '${day.day}',
            style: TextStyle(
              color: isToday ? todayAccent : scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        CalendarDayMarkerSlot(marker: marker, colorResolver: colorResolver),
      ],
    );
  }
}

/// Ausgewählter Tag — identisch zu [CustomTableCalendar] `selectedBuilder`.
class CalendarSelectedDayCell extends StatelessWidget {
  const CalendarSelectedDayCell({
    required this.day,
    required this.colorResolver,
    this.marker,
    super.key,
  });

  final DateTime day;
  final CalendarDayMarkerData? marker;
  final CalendarMarkerColorResolver colorResolver;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final todayAccent = CalendarPresentationTheme.todayAccentColor(context);
    final isToday = AppDateTime.isTodayLocal(day);

    return Center(
      child: Transform.translate(
        offset: const Offset(0, -2),
        child: SizedBox.square(
          dimension: kCalendarSelectedDayBoxSize,
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
                  color: isToday ? todayAccent : scheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              CalendarDayMarkerSlot(
                marker: marker,
                colorResolver: colorResolver,
                showEmptyPill: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
