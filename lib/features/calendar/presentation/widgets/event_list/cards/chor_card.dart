import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/base_calendar_card.dart';
import 'package:flutter/material.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';

import '../../../../domain/models/calendar_entry.dart';

class ChorCard extends StatelessWidget {
  final CalendarEntry entry;
  final bool applyPastStyling;
  const ChorCard({
    super.key,
    required this.entry,
    this.applyPastStyling = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BaseCalendarCard(
      entry: entry,
      applyPastStyling: applyPastStyling,
      backgroundColor: scheme.secondary,
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
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
