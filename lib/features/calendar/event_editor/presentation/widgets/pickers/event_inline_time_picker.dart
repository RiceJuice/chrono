import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:flutter/cupertino.dart';

/// Eingebettete 24h-Uhrzeit-Auswahl (kein Popup).
///
/// Auf iOS liefert [CupertinoDatePicker] natives Rad-Feedback; zusätzlich
/// [AppHaptics.pickerScrollTick] für Android/Material.
class EventInlineTimePicker extends StatelessWidget {
  const EventInlineTimePicker({
    super.key,
    required this.value,
    required this.dayAnchor,
    required this.onChanged,
  });

  final DateTime value;
  final DateTime dayAnchor;
  final ValueChanged<DateTime> onChanged;

  static const double height = 216;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.time,
        use24hFormat: true,
        initialDateTime: value.toLocal(),
        onDateTimeChanged: (picked) {
          AppHaptics.pickerScrollTick();
          onChanged(
            AppDateTime.localWallTimeAsUtcInstant(
              dayAnchor,
              hour: picked.hour,
              minute: picked.minute,
            ),
          );
        },
      ),
    );
  }
}
