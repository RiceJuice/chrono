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
    final backgroundColor = Color.alphaBlend(
      entry.accentColor.withValues(alpha: 0.05),
      scheme.surfaceContainerHigh,
    );

    return BaseCalendarCard(
      entry: entry,
      applyPastStyling: applyPastStyling,
      showTimeColumn: showTimeColumn,
      showInlineTimeRange: false,
      weekGridCompact: weekGridCompact,
      backgroundColor: backgroundColor,
      contentPadding: weekGridCompact
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : EdgeInsets.zero,
      leadingIndicator: Container(
        width: 6,
        decoration: BoxDecoration(
          color: entry.accentColor,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}
