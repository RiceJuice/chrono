import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:flutter/material.dart';

class TimeColumn extends StatelessWidget {
  const TimeColumn({super.key, required this.entry});

  final CalendarEntry entry;

  @override
  Widget build(BuildContext context) {
    String formatTime(DateTime time) =>
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(formatTime(entry.startTime)),
        Text(formatTime(entry.endTime)),
      ],
    );
  }
}
