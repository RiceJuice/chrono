import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_week_layout_tokens.dart';
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

  static const double _phoneEdgeNudge = 5;
  static const double _phoneTimePairGap = 5;

  @override
  Widget build(BuildContext context) {
    final narrow = calendarIsPhoneLayout(context);
    final baseStyle =
        Theme.of(context).textTheme.bodyMedium?.copyWith(color: textColor);
    final textStyle = narrow
        ? baseStyle?.copyWith(
            fontSize: (baseStyle.fontSize ?? 14) * 0.93,
            height: 1.05,
          )
        : baseStyle;

    final start = AppDateTime.formatLocalHourMinute(entry.startTime);
    final end = AppDateTime.formatLocalHourMinute(entry.endTime);

    Widget column = Column(
      mainAxisAlignment: alignToContentHeight
          ? (narrow
              ? MainAxisAlignment.center
              : MainAxisAlignment.spaceBetween)
          : MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: alignToContentHeight ? MainAxisSize.max : MainAxisSize.min,
      children: narrow && alignToContentHeight
          ? [
              Text(start, style: textStyle),
              const SizedBox(height: _phoneTimePairGap),
              Text(end, style: textStyle),
            ]
          : [
              Text(start, style: textStyle),
              Text(end, style: textStyle),
            ],
    );

    if (narrow) {
      column = Transform.translate(
        offset: const Offset(-_phoneEdgeNudge, 0),
        child: column,
      );
    }

    return column;
  }
}
