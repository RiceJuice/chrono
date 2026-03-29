import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/chor_bottom_modal.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/event_bottom_modal.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/lesson_bottom_modal.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/meal_bottom_modal.dart';
import 'package:flutter/material.dart';

class CalendarEntryBottomModal extends StatelessWidget {
  final CalendarEntry entry;
  const CalendarEntryBottomModal({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    switch (entry.type) {
      case CalendarEntryType.lesson:
        return LessonBottomModal(entry: entry);
      case CalendarEntryType.meal:
        return MealBottomModal(entry: entry);
      case CalendarEntryType.event:
        return EventBottomModal(entry: entry);
      case CalendarEntryType.chor:
        return ChorBottomModal(entry: entry);
    }
  }
}
