import 'package:flutter/material.dart';

import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/types/chor_bottom_modal.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/types/event_bottom_modal.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/types/lesson_bottom_modal.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/types/meal_bottom_modal.dart';

class BaseBottomModal extends StatelessWidget {
  final CalendarEntry entry;
  final double? minHeight;

  const BaseBottomModal({
    super.key,
    required this.entry,
    this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double effectiveMinHeight = minHeight ?? (screenHeight * 0.6);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: effectiveMinHeight,
            maxHeight: screenHeight * 0.9,
          ),
          child: SingleChildScrollView(
            child: _buildModalContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildModalContent() {
    return switch (entry.type) {
      CalendarEntryType.lesson => LessonBottomModal(entry: entry),
      CalendarEntryType.meal => MealBottomModal(entry: entry),
      CalendarEntryType.event => EventBottomModal(entry: entry),
      CalendarEntryType.chor => ChorBottomModal(entry: entry),
    };
  }
}