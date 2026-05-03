import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/base_calendar_card.dart';
import 'package:flutter/material.dart';

class LessionCard extends StatelessWidget {
  final CalendarEntry entry;
  final bool applyPastStyling;
  final bool showTimeColumn;
  final bool weekGridCompact;
  final bool? showInlineTimeRange;
  final double? listTileHorizontalPadding;
  final EdgeInsetsGeometry? contentPadding;
  final double? titleFontSize;

  const LessionCard({
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
    final backgroundColor = Color.alphaBlend(
      entry.accentColor.withValues(alpha: 0.06),
      scheme.surfaceContainerHigh,
    );

    return BaseCalendarCard(
      entry: entry,
      applyPastStyling: applyPastStyling,
      showTimeColumn: showTimeColumn,
      weekGridCompact: weekGridCompact,
      showInlineTimeRange: showInlineTimeRange,
      listTileHorizontalPadding: listTileHorizontalPadding,
      contentPadding: contentPadding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.s,
            vertical: AppSpacing.s,
          ),
      titleFontSize: titleFontSize,
      backgroundColor: backgroundColor,
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
