import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/base_calendar_card.dart';
import 'package:flutter/material.dart';
import '../../../../domain/models/calendar_entry.dart';

class MealCard extends StatelessWidget {
  final CalendarEntry entry;
  const MealCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return BaseCalendarCard(
      entry: entry,
      backgroundColor: const Color(0xFF124E30),
      contentPadding: const EdgeInsets.fromLTRB(16.0, 12.0, 0, 48.0),
    );
  }
}
