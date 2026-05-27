import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_accent_overrides_provider.dart';
import 'package:chronoapp/features/calendar/presentation/theme/calendar_presentation_theme.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/base_calendar_card.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/leading_indicator/calendar_card_leading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LessionCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = resolveCalendarEntryAccent(ref, entry);

    return BaseCalendarCard(
      entry: entry,
      applyPastStyling: applyPastStyling,
      showTimeColumn: showTimeColumn,
      weekGridCompact: weekGridCompact,
      showInlineTimeRange: showInlineTimeRange,
      listTileHorizontalPadding: listTileHorizontalPadding,
      contentPadding:
          contentPadding ?? CalendarCardLeadingIndicator.contentPadding,
      titleFontSize: titleFontSize,
      backgroundColor:
          CalendarPresentationTheme.lessonCardBackgroundColor(context, accent),
      leadingIndicatorColor: accent,
    );
  }
}
