import 'package:chronoapp/core/database/backend_enums.dart';
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

  /// Horizontaler Außenabstand der Zeile im Listen-Modus ([ListTile.contentPadding]).
  /// Standard: [AppSpacing.l].
  final double? listTileHorizontalPadding;

  /// Wenn `null`: wie bisher `!showTimeColumn`. Z. B. [LessionCard] setzt `false`.
  final bool? showInlineTimeRange;

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
    this.listTileHorizontalPadding,
    this.showInlineTimeRange,
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

    final inlineTime = showInlineTimeRange ?? (!showTimeColumn);

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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.s),
            child: Ink(
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.s),
                color: style.cardBackgroundColor,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (leadingIndicator != null) ...[
                    leadingIndicator!,
                    SizedBox(
                      width: _stripeToTextGap(
                        0,
                        weekGridCompact: true,
                      ),
                    ),
                  ],
                  Expanded(
                    child: Padding(
                      padding: contentPadding,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final showCompactInlineTime =
                              shouldShowCalendarEntryTimeRangeRow(
                                constraints: constraints,
                                wantTimeRange: inlineTime,
                                compact: true,
                                hasChoirLine:
                                    showChoirAboveTitle &&
                                    entry.choir != BackendChoir.unknown,
                                hasDescription: false,
                              );
                          return Align(
                            alignment: Alignment.topLeft,
                            child: TextContent(
                              entry: entry,
                              primaryTextColor: style.primaryTextColor,
                              secondaryTextColor: style.secondaryTextColor,
                              showChoirAboveTitle: showChoirAboveTitle,
                              titleFontSize: titleFontSize,
                              titleFontWeight: titleFontWeight,
                              compact: true,
                              showInlineTimeRange: showCompactInlineTime,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ListTile(
      titleAlignment: ListTileTitleAlignment.top,
      minVerticalPadding: 0,
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
      contentPadding: EdgeInsets.only(
        left:
            listTileHorizontalPadding ?? (weekGridCompact ? AppSpacing.s : AppSpacing.l),
        right:
            listTileHorizontalPadding ?? (weekGridCompact ? AppSpacing.s : AppSpacing.l),
        bottom: weekGridCompact ? 2 : 0,
      ),
      leading: showTimeColumn
          ? TimeColumn(entry: entry, textColor: style.timeTextColor)
          : null,
      title: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.s),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.s),
            color: style.cardBackgroundColor,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (leadingIndicator != null) ...[
                  leadingIndicator!,
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Padding(
                    padding: contentPadding,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: TextContent(
                        entry: entry,
                        primaryTextColor: style.primaryTextColor,
                        secondaryTextColor: style.secondaryTextColor,
                        showChoirAboveTitle: showChoirAboveTitle,
                        titleFontSize: titleFontSize,
                        titleFontWeight: titleFontWeight,
                        showInlineTimeRange: inlineTime,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontaler Abstand zwischen Farbstreifen und Text, abhängig von der
/// verfügbaren Innenbreite der Karte (schmale Wochenspalten vs. volle Liste).
double _stripeToTextGap(double rowInnerWidth, {required bool weekGridCompact}) {
  if (weekGridCompact) {
    return 6.0;
  }
  if (!rowInnerWidth.isFinite || rowInnerWidth <= 0) {
    return 12.0;
  }
  return (rowInnerWidth * 0.03).clamp(8.0, 8.0);
}
