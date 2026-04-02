import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/bottom_modal_header.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/bottom_modal_text.dart';
import 'package:flutter/material.dart';

class LessonBottomModal extends StatelessWidget {
  final CalendarEntry entry;
  const LessonBottomModal({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BottomModalHeader(entry: entry),
        BottomModalText(entry: entry)
      ],
    );
  }
}
