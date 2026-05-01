import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/base_calendar_card.dart';
import 'package:flutter/material.dart';
import '../../../../domain/models/calendar_entry.dart';

class LessionCard extends StatelessWidget {
  final CalendarEntry entry;
  final bool applyPastStyling;
  final bool showTimeColumn;
  final bool weekGridCompact;
  const LessionCard({
    super.key,
    required this.entry,
    this.applyPastStyling = false,
    this.showTimeColumn = true,
    this.weekGridCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BaseCalendarCard(
      entry: entry,
      applyPastStyling: applyPastStyling,
      showTimeColumn: showTimeColumn,
      weekGridCompact: weekGridCompact,
      backgroundColor: scheme.surfaceContainerHigh,
      contentPadding: EdgeInsetsGeometry.symmetric(
        vertical: weekGridCompact ? 4 : 8,
        horizontal: weekGridCompact ? 8 : 14,
      ),
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
