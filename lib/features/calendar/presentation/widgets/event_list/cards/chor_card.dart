import 'package:chronoapp/features/calendar/presentation/providers/calendar_accent_overrides_provider.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/base_calendar_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/calendar_entry.dart';

class ChorCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final accent = resolveCalendarEntryAccent(ref, entry);
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
          color: accent,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}
