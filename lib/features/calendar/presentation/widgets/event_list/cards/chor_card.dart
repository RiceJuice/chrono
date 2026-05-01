import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/base_calendar_card.dart';
import 'package:flutter/material.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';

import '../../../../domain/models/calendar_entry.dart';

class ChorCard extends StatelessWidget {
  final CalendarEntry entry;
  final bool applyPastStyling;
  final bool showTimeColumn;
  final bool weekGridCompact;
  const ChorCard({
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
      showChoirAboveTitle: true,
      titleFontSize: weekGridCompact ? 14 : 17,
      titleFontWeight: FontWeight.w500,
      backgroundColor: scheme.primary,
      contentPadding: EdgeInsets.symmetric(
        vertical: weekGridCompact ? 6 : 12,
        horizontal: weekGridCompact ? 8 : 14,
      ),
      leadingIndicator: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.m),
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
