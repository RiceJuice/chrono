import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/text_content.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/time_column.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/base_bottom_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import '../../../../domain/models/calendar_entry.dart';
import 'calendar_card_style_resolver.dart';
import 'calendar_entry_temporal_state.dart';

class MealCard extends StatelessWidget {
  final CalendarEntry entry;
  final bool applyPastStyling;
  final bool showTimeColumn;
  final bool weekGridCompact;
  const MealCard({
    super.key,
    required this.entry,
    this.applyPastStyling = false,
    this.showTimeColumn = true,
    this.weekGridCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final temporalState = CalendarEntryTemporalState.fromEntry(entry);
    final style = CalendarCardStyleResolver.resolve(
      context: context,
      baseBackgroundColor: const Color(0xFF124E30),
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
              builder: (context) => BaseBottomModal(entry: entry),
            );
          },
          child: Ink(
            height: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.s),
              color: style.cardBackgroundColor,
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: TextContent(
                entry: entry,
                primaryTextColor: style.primaryTextColor,
                secondaryTextColor: style.secondaryTextColor,
                compact: true,
                showInlineTimeRange: !showTimeColumn,
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
          builder: (context) => BaseBottomModal(entry: entry),
        );
      },
      contentPadding: EdgeInsets.symmetric(
        horizontal: weekGridCompact ? AppSpacing.s : AppSpacing.l,
        vertical: weekGridCompact ? 2 : 0,
      ),
      leading: showTimeColumn
          ? TimeColumn(entry: entry, textColor: style.timeTextColor)
          : null,
      title: Padding(
        padding: EdgeInsets.symmetric(vertical: weekGridCompact ? 4 : 15),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.s),
            color: style.cardBackgroundColor,
          ),
          // IntrinsicHeight sorgt dafür, dass die Row so hoch ist wie ihr höchstes Kind
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment
                  .stretch, // WICHTIG: Streckt Kinder auf die volle Höhe
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      weekGridCompact ? 8 : 14,
                      weekGridCompact ? 6 : 24,
                      0,
                      weekGridCompact ? 6 : 24,
                    ),
                    child: TextContent(
                      entry: entry,
                      primaryTextColor: style.primaryTextColor,
                      secondaryTextColor: style.secondaryTextColor,
                      showInlineTimeRange: !showTimeColumn,
                    ),
                  ),
                ),
                if (!weekGridCompact &&
                    entry.imageUrls != null &&
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
                                .withValues(alpha: style.imageOverlayOpacity),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
