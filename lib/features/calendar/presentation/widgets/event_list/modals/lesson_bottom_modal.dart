import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/base_bottom_modal.dart';
import 'package:flutter/material.dart';

class LessonBottomModal extends StatelessWidget {
  final CalendarEntry entry;
  const LessonBottomModal({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return BaseBottomModal(
      entry: entry,
    );
  }
}
