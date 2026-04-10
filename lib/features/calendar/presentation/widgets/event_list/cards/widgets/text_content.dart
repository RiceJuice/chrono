
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:flutter/material.dart';

class TextContent extends StatelessWidget {
  const TextContent({
    super.key,
    required this.entry,
    this.primaryTextColor,
    this.secondaryTextColor,
  });

  final CalendarEntry entry;
  final Color? primaryTextColor;
  final Color? secondaryTextColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.eventName,
          style: theme.textTheme.bodyLarge?.copyWith(color: primaryTextColor),
        ),
        if ((entry.description ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            entry.description!,
            style: theme.textTheme.bodySmall?.copyWith(color: secondaryTextColor),
          ),
        ],
      ],
    );
  }
}