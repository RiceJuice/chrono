import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:flutter/material.dart';

/// Eingebetteter Kalender (kein Popup).
class EventInlineDatePicker extends StatelessWidget {
  const EventInlineDatePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return CalendarDatePicker(
      initialDate: AppDateTime.localDay(value),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      onDateChanged: (picked) {
        AppHaptics.selection();
        onChanged(AppDateTime.localDay(picked));
      },
    );
  }
}
