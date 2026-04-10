import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/text_content.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/time_column.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/base_bottom_modal.dart';
import 'package:flutter/material.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'calendar_card_style_resolver.dart';
import 'calendar_entry_temporal_state.dart';

class BaseCalendarCard extends StatelessWidget {
  final CalendarEntry entry;
  final bool applyPastStyling;
  final Color? backgroundColor;
  final EdgeInsetsGeometry contentPadding;
  final Widget? leadingIndicator; // Für den farbigen Strich bei Events

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

    return ListTile(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (context) {
            return BaseBottomModal(entry: entry);
          },
        );
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      leading: TimeColumn(entry: entry, textColor: style.timeTextColor),
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
              if (leadingIndicator != null) leadingIndicator!,
              Expanded(
                child: TextContent(
                  entry: entry,
                  primaryTextColor: style.primaryTextColor,
                  secondaryTextColor: style.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}