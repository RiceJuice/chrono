import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/base_calendar_card.dart';
import 'package:flutter/material.dart';

import '../../../../domain/models/calendar_entry.dart';

class ChorCard extends StatelessWidget {
  final CalendarEntry entry;
  final bool applyPastStyling;
  final bool showTimeColumn;
  final bool weekGridCompact;
  final bool? showInlineTimeRange;
  final double? listTileHorizontalPadding;
  final EdgeInsetsGeometry? contentPadding;
  final double? titleFontSize;

  const ChorCard({
    super.key,
    required this.entry,
    this.applyPastStyling = false,
    this.showTimeColumn = true,
    this.weekGridCompact = false,
    this.showInlineTimeRange,
    this.listTileHorizontalPadding,
    this.contentPadding,
    this.titleFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BaseCalendarCard(
      entry: entry,
      applyPastStyling: applyPastStyling,
      showTimeColumn: showTimeColumn,
      weekGridCompact: weekGridCompact,
      showInlineTimeRange: showInlineTimeRange,
      listTileHorizontalPadding: listTileHorizontalPadding,
      showChoirAboveTitle: true,
      titleFontSize: weekGridCompact
          ? 14
          : (titleFontSize ?? 17),
      titleFontWeight: FontWeight.w500,
      backgroundColor: scheme.primary,
      contentPadding: weekGridCompact
          ? const EdgeInsets.symmetric(vertical: 6, horizontal: 8)
          : (contentPadding ??
              const EdgeInsets.symmetric(vertical: 12, horizontal: 14)),
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
