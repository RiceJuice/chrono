import 'package:flutter/material.dart';

import '../../../../domain/models/calendar_entry.dart';
import 'chor_card.dart';
import 'event_card.dart';
import 'lession_card.dart';
import 'meal_card.dart';

class CalendarEntryCard extends StatelessWidget {
  const CalendarEntryCard({
    required this.entry,
    this.applyPastStyling = false,
    this.showTimeColumn = true,
    this.weekGridCompact = false,
    super.key,
  });

  final CalendarEntry entry;
  final bool applyPastStyling;
  final bool showTimeColumn;
  final bool weekGridCompact;

  @override
  Widget build(BuildContext context) {
    switch (entry.type) {
      case CalendarEntryType.lesson:
        return LessionCard(
          entry: entry,
          applyPastStyling: applyPastStyling,
          showTimeColumn: showTimeColumn,
          weekGridCompact: weekGridCompact,
        );
      case CalendarEntryType.choir:
        return ChorCard(
          entry: entry,
          applyPastStyling: applyPastStyling,
          showTimeColumn: showTimeColumn,
          weekGridCompact: weekGridCompact,
        );
      case CalendarEntryType.meal:
        return MealCard(
          entry: entry,
          applyPastStyling: applyPastStyling,
          showTimeColumn: showTimeColumn,
          weekGridCompact: weekGridCompact,
        );
      case CalendarEntryType.event:
        return EventCard(
          entry: entry,
          applyPastStyling: applyPastStyling,
          showTimeColumn: showTimeColumn,
          weekGridCompact: weekGridCompact,
        );
    }
  }
}
