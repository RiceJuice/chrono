import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/base_calendar_card.dart';
import 'package:flutter/material.dart';
import '../../../../domain/models/calendar_entry.dart';

class LessionCard extends StatelessWidget {
  final CalendarEntry entry;
  const LessionCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return BaseCalendarCard(
      entry: entry,
      contentPadding: EdgeInsetsGeometry.symmetric(vertical: 8, horizontal: 14),
      leadingIndicator: Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: Container(
          width: 6,
          decoration: BoxDecoration(
            color: entry.accentColor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}
