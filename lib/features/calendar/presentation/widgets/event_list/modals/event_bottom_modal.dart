import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/base_bottom_modal.dart';
import 'package:flutter/material.dart';

class EventBottomModal extends StatelessWidget {
  final CalendarEntry entry;
  const EventBottomModal({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return BaseBottomModal(
      entry: entry,
      extraContent: (entry.imageUrl ?? '').isEmpty
          ? null
          : ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                entry.imageUrl!,
                height: 400,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
    );
  }
}
