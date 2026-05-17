import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/leading_indicator/calendar_card_leading_indicator.dart';
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
  /// Akzentfarbe für den farbigen Streifen links; `null` = kein Streifen.
  final Color? leadingIndicatorColor;
  final bool showChoirAboveTitle;
  final double? titleFontSize;
  final FontWeight? titleFontWeight;
  final bool showTimeColumn;
  final bool weekGridCompact;

  /// Horizontaler Außenabstand der Zeile im Listen-Modus ([ListTile.contentPadding]).
  final double? listTileHorizontalPadding;

  /// Wenn `null`: wie bisher `!showTimeColumn`.
  final bool? showInlineTimeRange;

  const BaseCalendarCard({
    super.key,
    required this.entry,
    this.applyPastStyling = false,
    this.backgroundColor,
    this.contentPadding = CalendarCardLeadingIndicator.contentPadding,
    this.leadingIndicatorColor,
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
            BaseBottomModal.show(context, entry: entry);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.s),
            child: Ink(
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.s),
                color: style.cardBackgroundColor,
              ),
              child: Padding(
                padding: contentPadding,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (leadingIndicatorColor != null) ...[
                      CalendarCardLeadingIndicator(color: leadingIndicatorColor!),
                      const SizedBox(width: CalendarCardLeadingIndicator.gapAfterBar),
                    ],
                    Expanded(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: CalendarCompactCardText(
                          entry: entry,
                          primaryTextColor: style.primaryTextColor,
                          secondaryTextColor: style.secondaryTextColor,
                          wantInlineTimeRange: inlineTime,
                          showChoirAboveTitle: showChoirAboveTitle,
                          titleFontSize: titleFontSize,
                          titleFontWeight: titleFontWeight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final rowHorizontalPadding =
        listTileHorizontalPadding ?? AppSpacing.l;
    final contentInsets = contentPadding.resolve(Directionality.of(context));

    void onCardTap() {
      HapticFeedback.heavyImpact();
      BaseBottomModal.show(context, entry: entry);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: rowHorizontalPadding),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onCardTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showTimeColumn)
                  Padding(
                    padding: EdgeInsets.only(
                      top: contentInsets.top,
                      bottom: contentInsets.bottom,
                      right: AppSpacing.s,
                    ),
                    child: TimeColumn(
                      entry: entry,
                      textColor: style.timeTextColor,
                      alignToContentHeight: true,
                    ),
                  ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.s),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.s),
                        color: style.cardBackgroundColor,
                      ),
                      child: Padding(
                        padding: contentPadding,
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (leadingIndicatorColor != null) ...[
                                CalendarCardLeadingIndicator(
                                  color: leadingIndicatorColor!,
                                ),
                                const SizedBox(
                                  width: CalendarCardLeadingIndicator.gapAfterBar,
                                ),
                              ],
                              Expanded(
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
                            ],
                          ),
                        ),
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
