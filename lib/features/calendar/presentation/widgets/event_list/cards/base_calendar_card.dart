import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/text_content.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/time_column.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/base_bottom_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'calendar_card_style_resolver.dart';
import 'calendar_entry_temporal_state.dart';

class BaseCalendarCard extends StatelessWidget {
  final CalendarEntry entry;
  final bool applyPastStyling;
  final Color? backgroundColor;
  final EdgeInsetsGeometry contentPadding;
  final Widget? leadingIndicator; // Für den farbigen Strich bei Events
  final bool showChoirAboveTitle;
  final double? titleFontSize;
  final FontWeight? titleFontWeight;
  final bool showTimeColumn;
  final bool weekGridCompact;

  const BaseCalendarCard({
    super.key,
    required this.entry,
    this.applyPastStyling = false,
    this.backgroundColor,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.m,
      vertical: 6,
    ),
    this.leadingIndicator,
    this.showChoirAboveTitle = false,
    this.titleFontSize,
    this.titleFontWeight,
    this.showTimeColumn = true,
    this.weekGridCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final temporalState = CalendarEntryTemporalState.fromEntry(entry);
    final style = CalendarCardStyleResolver.resolve(
      context: context,
      baseBackgroundColor: backgroundColor ?? scheme.surface,
      temporalState: temporalState,
      applyPastStyling: applyPastStyling,
    );

    if (weekGridCompact) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.s),
          onTap: () {
            HapticFeedback.heavyImpact();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (context) {
                return BaseBottomModal(entry: entry);
              },
            );
          },
          child: Ink(
            height: double.infinity,
            padding: contentPadding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.s),
              color: style.cardBackgroundColor,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ?leadingIndicator,
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextContent(
                      entry: entry,
                      primaryTextColor: style.primaryTextColor,
                      secondaryTextColor: style.secondaryTextColor,
                      showChoirAboveTitle: showChoirAboveTitle,
                      titleFontSize: titleFontSize,
                      titleFontWeight: titleFontWeight,
                      compact: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListTile(
      dense: weekGridCompact,
      visualDensity: weekGridCompact ? VisualDensity.compact : null,
      onTap: () {
        HapticFeedback.heavyImpact();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (context) {
            return BaseBottomModal(entry: entry);
          },
        );
      },
      contentPadding: EdgeInsets.symmetric(
        horizontal: weekGridCompact ? AppSpacing.s : AppSpacing.l,
        vertical: weekGridCompact ? 2 : 0,
      ),
      leading: showTimeColumn
          ? TimeColumn(entry: entry, textColor: style.timeTextColor)
          : null,
      title: Container(
        padding: contentPadding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.s),
          color: style.cardBackgroundColor,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ?leadingIndicator,
              Expanded(
                child: TextContent(
                  entry: entry,
                  primaryTextColor: style.primaryTextColor,
                  secondaryTextColor: style.secondaryTextColor,
                  showChoirAboveTitle: showChoirAboveTitle,
                  titleFontSize: titleFontSize,
                  titleFontWeight: titleFontWeight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
