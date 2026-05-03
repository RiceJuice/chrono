import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:flutter/material.dart';

class TimeColumn extends StatelessWidget {
  const TimeColumn({
    super.key,
    required this.entry,
    this.textColor,
    /// Start- und Endzeit an Ober- und Unterkante der verfügbaren Höhe
    /// (sinnvoll neben gestrecktem Karteninhalt, z. B. [BaseCalendarCard]).
    this.alignToContentHeight = false,
  });

  final CalendarEntry entry;
  final Color? textColor;
  final bool alignToContentHeight;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: textColor);

    return Column(
      mainAxisAlignment: alignToContentHeight
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          AppDateTime.formatLocalHourMinute(entry.startTime),
          style: textStyle,
        ),
        Text(
          AppDateTime.formatLocalHourMinute(entry.endTime),
          style: textStyle,
        ),
      ],
    );
  }
}
