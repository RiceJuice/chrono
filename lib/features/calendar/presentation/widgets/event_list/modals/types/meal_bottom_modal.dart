import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/bottom_modal_images.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/bottom_modal_text.dart';
import 'package:flutter/material.dart';

class MealBottomModal extends StatelessWidget {
  final CalendarEntry entry;
  const MealBottomModal({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BottomModalImages(entry: entry),
        BottomModalText(entry: entry)
      ],
    );
  }
}
