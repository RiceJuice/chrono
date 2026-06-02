import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/presentation/theme/calendar_presentation_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Höhe der Tageszeile oberhalb der Ganztags-Balken (z. B. „Do. 4. Juni“).
const double kWeekAllDayDayLabelHeight = 18;

/// Kurzbeschriftung für eine Spalte in der Ganztags-Zeile.
class WeekAllDayDayLabel extends StatelessWidget {
  const WeekAllDayDayLabel({
    required this.day,
    this.compact = false,
    super.key,
  });

  final DateTime day;
  final bool compact;

  static String formatLabel(DateTime day) {
    final local = AppDateTime.localDay(day);
    final weekday = DateFormat.E('de_DE').format(local);
    final weekdayWithDot = weekday.endsWith('.') ? weekday : '$weekday.';
    final datePart = DateFormat('d. MMMM', 'de_DE').format(local);
    return '$weekdayWithDot $datePart';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isToday = AppDateTime.isTodayLocal(day);

    return SizedBox(
      height: kWeekAllDayDayLabelHeight,
      child: Center(
        child: Text(
          formatLabel(day),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: compact ? 11 : 12,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                height: 1.1,
                color: isToday
                    ? CalendarPresentationTheme.todayAccentColor(context)
                    : scheme.onSurface.withValues(alpha: 0.72),
              ),
        ),
      ),
    );
  }
}

/// Sieben Tageslabels über dem Ganztags-Raster (Tablet/Woche).
class WeekAllDayDayLabelsRow extends StatelessWidget {
  const WeekAllDayDayLabelsRow({
    required this.weekDays,
    super.key,
  });

  final List<DateTime> weekDays;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kWeekAllDayDayLabelHeight,
      child: Row(
        children: [
          for (final day in weekDays.take(7))
            Expanded(
              child: WeekAllDayDayLabel(day: day),
            ),
        ],
      ),
    );
  }
}
