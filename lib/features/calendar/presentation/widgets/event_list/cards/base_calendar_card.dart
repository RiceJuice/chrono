import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/text_content.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/time_column.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/base_bottom_modal.dart';
import 'package:flutter/material.dart';

class BaseCalendarCard extends StatelessWidget {
  final CalendarEntry entry;
  final Color backgroundColor;
  final EdgeInsetsGeometry contentPadding;
  final Widget? leadingIndicator; // Für den farbigen Strich bei Events

  const BaseCalendarCard({
    super.key,
    required this.entry,
    required this.backgroundColor,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
    this.leadingIndicator,
  });

  @override
  Widget build(BuildContext context) {

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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0,),
      leading: TimeColumn(entry: entry),
      title: Container(
        padding: contentPadding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: backgroundColor,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (leadingIndicator != null) leadingIndicator!,
              Expanded(
                child: TextContent(entry: entry,),
              ),
            ],
          ),
        ),
      ),
    );
  }
}