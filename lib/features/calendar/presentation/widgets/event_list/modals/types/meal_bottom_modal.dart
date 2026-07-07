import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/providers/meal_images_preference_provider.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/bottom_modal_images.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/bottom_modal_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MealBottomModal extends ConsumerWidget {
  final CalendarEntry entry;
  const MealBottomModal({super.key, required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showMealImages = ref.watch(showMealImagesProvider).value ?? true;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showMealImages)
          BottomModalImages(
            entry: entry,
            layout: BottomModalImagesLayout.single,
          ),
        BottomModalText(entry: entry),
      ],
    );
  }
}
