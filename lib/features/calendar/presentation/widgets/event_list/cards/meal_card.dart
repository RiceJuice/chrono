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
  const MealCard({
    super.key,
    required this.entry,
    this.applyPastStyling = false,
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
    return ListTile(
      onTap: () {
        HapticFeedback.heavyImpact();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (context) => BaseBottomModal(entry: entry),
        );
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      leading: TimeColumn(entry: entry, textColor: style.timeTextColor),
      title: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
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
                    padding: const EdgeInsets.fromLTRB(14, 24, 0, 24),
                    child: TextContent(
                      entry: entry,
                      primaryTextColor: style.primaryTextColor,
                      secondaryTextColor: style.secondaryTextColor,
                    ),
                  ),
                ),
                if (entry.imageUrls != null && entry.imageUrls!.isNotEmpty)
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
                            color: Theme.of(context).colorScheme.surface.withValues(
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
    );
  }
}
