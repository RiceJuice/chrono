import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/time/app_date_time.dart';
import '../../theme/calendar_presentation_theme.dart';

/// Tages-Header wie in der Kalender-Suche (inkl. roter „Heute“-Markierung).
class CalendarDaySectionHeader extends StatelessWidget {
  const CalendarDaySectionHeader({
    required this.day,
    this.height = 40,
    super.key,
  });

  final DateTime day;
  final double height;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.titleMedium;
    final isToday = AppDateTime.isTodayLocal(day);
    final isPastDay = AppDateTime.isBeforeTodayLocal(day);
    final style = isToday
        ? CalendarPresentationTheme.todayHeaderTextStyle(context, baseStyle)
        : isPastDay
        ? CalendarPresentationTheme.pastHeaderTextStyle(context, baseStyle)
        : baseStyle;

    return Container(
      height: height,
      color: Theme.of(context).scaffoldBackgroundColor,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        DateFormat('EEEE, d. MMMM', 'de').format(day),
        style: style?.copyWith(fontSize: 16),
      ),
    );
  }
}
