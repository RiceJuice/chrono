import 'package:flutter/material.dart';

import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/types/chor_bottom_modal.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/types/event_bottom_modal.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/types/lesson_bottom_modal.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/types/meal_bottom_modal.dart';

/// Etwas langsameres, weicheres Ein-/Ausblenden als Material-Default (~250 ms),
/// näher an typischen iOS-Sheet-Präsentationen.
const AnimationStyle kCalendarBottomSheetMotion = AnimationStyle(
  duration: Duration(milliseconds: 300),
  reverseDuration: Duration(milliseconds: 300),
  curve: Cubic(0.25, 0.1, 0.25, 1.0),
  reverseCurve: Cubic(0.33, 0.0, 0.67, 1.0),
);

class BaseBottomModal extends StatelessWidget {
  final CalendarEntry entry;
  final double? minHeight;

  const BaseBottomModal({super.key, required this.entry, this.minHeight});

  static Future<T?> show<T>(
    BuildContext context, {
    required CalendarEntry entry,
    double? minHeight,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      sheetAnimationStyle: kCalendarBottomSheetMotion,
      builder: (_) => BaseBottomModal(entry: entry, minHeight: minHeight),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double effectiveMinHeight = minHeight ?? (screenHeight * 0.7);
    final sheetSurface = Theme.of(context).colorScheme.surface;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: effectiveMinHeight,
          maxHeight: screenHeight * 0.9,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
          child: ColoredBox(
            color: sheetSurface,
            child: SingleChildScrollView(child: _buildModalContent()),
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
      CalendarEntryType.choir => ChorBottomModal(entry: entry),
    };
  }
}
