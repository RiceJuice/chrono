import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/base_bottom_modal.dart';
import 'package:flutter/material.dart';

class MealBottomModal extends StatelessWidget {
  final CalendarEntry entry;
  const MealBottomModal({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final tags = entry.tags ?? const <String>[];
    return BaseBottomModal(
      entry: entry,
      extraContent: tags.isEmpty
          ? null
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags
                  .map(
                    (tag) => Chip(
                      label: Text(tag),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}
