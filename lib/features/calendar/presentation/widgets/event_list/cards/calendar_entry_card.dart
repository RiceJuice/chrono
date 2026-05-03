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
    this.showInlineTimeRange,
    this.listTileHorizontalPadding,
    this.cardContentPadding,
    this.cardTitleFontSize,
    super.key,
  });

  final CalendarEntry entry;
  final bool applyPastStyling;
  final bool showTimeColumn;
  final bool weekGridCompact;

  /// `null`: abgeleitet wie bisher (z. B. inline Zeit bei `showTimeColumn: false`).
  final bool? showInlineTimeRange;

  /// `null`: Standard horizontaler Außenabstand der Listenkarte ([AppSpacing.l] / kompakt [AppSpacing.s]).
  final double? listTileHorizontalPadding;

  /// Optional: Innenabstand der Kartenfläche (z. B. Sheet-Header-Vorschau).
  final EdgeInsetsGeometry? cardContentPadding;

  /// Optional: Titelgröße (z. B. Sheet-Header-Vorschau).
  final double? cardTitleFontSize;

  @override
  Widget build(BuildContext context) {
    switch (entry.type) {
      case CalendarEntryType.lesson:
        return LessionCard(
          entry: entry,
          applyPastStyling: applyPastStyling,
          showTimeColumn: showTimeColumn,
          weekGridCompact: weekGridCompact,
          showInlineTimeRange: showInlineTimeRange,
          listTileHorizontalPadding: listTileHorizontalPadding,
          contentPadding: cardContentPadding,
          titleFontSize: cardTitleFontSize,
        );
      case CalendarEntryType.choir:
        return ChorCard(
          entry: entry,
          applyPastStyling: applyPastStyling,
          showTimeColumn: showTimeColumn,
          weekGridCompact: weekGridCompact,
          showInlineTimeRange: showInlineTimeRange,
          listTileHorizontalPadding: listTileHorizontalPadding,
          contentPadding: cardContentPadding,
          titleFontSize: cardTitleFontSize,
        );
      case CalendarEntryType.meal:
        return MealCard(
          entry: entry,
          applyPastStyling: applyPastStyling,
          showTimeColumn: showTimeColumn,
          weekGridCompact: weekGridCompact,
          showInlineTimeRange: showInlineTimeRange,
          listTileHorizontalPadding: listTileHorizontalPadding,
        );
      case CalendarEntryType.event:
        return EventCard(
          entry: entry,
          applyPastStyling: applyPastStyling,
          showTimeColumn: showTimeColumn,
          weekGridCompact: weekGridCompact,
          showInlineTimeRange: showInlineTimeRange,
          listTileHorizontalPadding: listTileHorizontalPadding,
        );
    }
  }
}
