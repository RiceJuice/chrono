import 'package:chronoapp/features/calendar/presentation/providers/calendar_accent_overrides_provider.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/text_content.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/time_column.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/base_bottom_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/calendar_entry.dart';
import 'calendar_card_style_resolver.dart';
import 'calendar_entry_temporal_state.dart';

class MealCard extends ConsumerWidget {
  final CalendarEntry entry;
  final bool applyPastStyling;
  final bool showTimeColumn;
  final bool weekGridCompact;
  final bool? showInlineTimeRange;
  final double? listTileHorizontalPadding;
  final bool modalHeaderPreview;
  final double? neighborGlassBlurSigma;
  final double? neighborGlassTintAlpha;

  const MealCard({
    super.key,
    required this.entry,
    this.applyPastStyling = false,
    this.showTimeColumn = true,
    this.weekGridCompact = false,
    this.showInlineTimeRange,
    this.listTileHorizontalPadding,
    this.modalHeaderPreview = false,
    this.neighborGlassBlurSigma,
    this.neighborGlassTintAlpha,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final temporalState = CalendarEntryTemporalState.fromEntry(entry);
    final accent = resolveCalendarEntryAccent(ref, entry);
    final style = CalendarCardStyleResolver.resolve(
      context: context,
      baseBackgroundColor: accent,
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
            BaseBottomModal.show(context, entry: entry);
          },
          child: Ink(
            height: double.infinity,
            padding: AppInsets.eventCardContentCompact,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.s),
              color: style.cardBackgroundColor,
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: CalendarCompactCardText(
                entry: entry,
                primaryTextColor: style.primaryTextColor,
                secondaryTextColor: style.secondaryTextColor,
                wantInlineTimeRange: showInlineTimeRange ?? !showTimeColumn,
              ),
            ),
          ),
        ),
      );
    }

    final rowHorizontalPadding = listTileHorizontalPadding ?? AppSpacing.l;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: rowHorizontalPadding),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.heavyImpact();
            BaseBottomModal.show(context, entry: entry);
          },
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showTimeColumn)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.s,
                      bottom: AppSpacing.s,
                      right: AppSpacing.s,
                    ),
                    child: TimeColumn(
                      entry: entry,
                      textColor: style.timeTextColor,
                      alignToContentHeight: true,
                      suppressEdgeNudge: modalHeaderPreview,
                    ),
                  ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.s),
                      color: style.cardBackgroundColor,
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s,
                                vertical: AppSpacing.s,
                              ),
                              child: TextContent(
                                entry: entry,
                                primaryTextColor: style.primaryTextColor,
                                secondaryTextColor: style.secondaryTextColor,
                                showInlineTimeRange:
                                    showInlineTimeRange ?? !showTimeColumn,
                              ),
                            ),
                          ),
                          if (entry.imageUrls != null &&
                              entry.imageUrls!.isNotEmpty)
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(AppRadius.s),
                                    bottomRight: Radius.circular(AppRadius.s),
                                  ),
                                  child: Image.network(
                                    entry.imageUrls![0],
                                    width: 140,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                if (style.imageOverlayOpacity > 0)
                                  Positioned.fill(
                                    child: ColoredBox(
                                      color: Theme.of(context).colorScheme.surface
                                          .withValues(
                                            alpha: style.imageOverlayOpacity,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
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
