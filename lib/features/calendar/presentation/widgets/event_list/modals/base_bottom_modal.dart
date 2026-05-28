import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/types/chor_bottom_modal.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/types/event_bottom_modal.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/types/lesson_bottom_modal.dart';
import 'package:chronoapp/features/calendar/event_editor/presentation/widgets/admin_edit_button.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/types/meal_bottom_modal.dart';
import 'package:flutter/material.dart';

export 'package:chronoapp/core/widgets/app_modal_sheet.dart' show kAppModalSheetMotion;

/// Alias für bestehende Importe im Kalender-Feature.
const AnimationStyle kCalendarBottomSheetMotion = kAppModalSheetMotion;

class BaseBottomModal extends StatelessWidget {
  final CalendarEntry entry;
  final double? minHeight;

  const BaseBottomModal({super.key, required this.entry, this.minHeight});

  static Future<T?> show<T>(
    BuildContext context, {
    required CalendarEntry entry,
    double? minHeight,
  }) {
    return AppModalSheet.show<T>(
      context: context,
      useSafeArea: false,
      builder: (_) => BaseBottomModal(entry: entry, minHeight: minHeight),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double effectiveMinHeight = minHeight ?? (screenHeight * 0.7);
    final sheetSurface = Theme.of(context).colorScheme.surface;

    return AppModalSheetChrome(
      color: sheetSurface,
      constraints: BoxConstraints(
        minHeight: effectiveMinHeight,
        maxHeight: screenHeight * 0.9,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SingleChildScrollView(child: _buildModalContent()),
          AdminEditButton(entry: entry),
        ],
      ),
    );
  }

  Widget _buildModalContent() {
    return switch (entry.type) {
      CalendarEntryType.lesson => LessonBottomModal(entry: entry),
      CalendarEntryType.meal => MealBottomModal(entry: entry),
      CalendarEntryType.event => EventBottomModal(entry: entry),
      CalendarEntryType.breakType => EventBottomModal(entry: entry),
      CalendarEntryType.choir => ChorBottomModal(entry: entry),
    };
  }
}
