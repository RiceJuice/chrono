import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/core/database/backend_enums.dart';
import 'package:flutter/material.dart';

class TextContent extends StatelessWidget {
  static const _compactTextHeightBehavior = TextHeightBehavior(
    applyHeightToFirstAscent: false,
    applyHeightToLastDescent: false,
  );

  const TextContent({
    super.key,
    required this.entry,
    this.primaryTextColor,
    this.secondaryTextColor,
    this.showChoirAboveTitle = false,
    this.titleFontSize,
    this.titleFontWeight,
    this.compact = false,
  });

  final CalendarEntry entry;
  final Color? primaryTextColor;
  final Color? secondaryTextColor;
  final bool showChoirAboveTitle;
  final double? titleFontSize;
  final FontWeight? titleFontWeight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showChoirAboveTitle && entry.choir != BackendChoir.unknown) ...[
          Text(
            entry.choir.displayLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textHeightBehavior: _compactTextHeightBehavior,
            style: theme.textTheme.bodySmall?.copyWith(
              color: secondaryTextColor?.withValues(alpha: 0.75),
              fontWeight: FontWeight.w400,
              height: 1,
              fontSize: 12,
            ),
          ),
        ],
        Text(
          entry.eventName,
          maxLines: compact ? 2 : null,
          overflow: compact ? TextOverflow.ellipsis : null,
          textHeightBehavior: _compactTextHeightBehavior,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: primaryTextColor,
            height: 1,
            fontWeight: titleFontWeight ?? FontWeight.w400,
            fontSize: titleFontSize ?? 16,
          ),
        ),
        if (!compact) const SizedBox(height: 2),
        if (!compact && (entry.description ?? '').trim().isNotEmpty) ...[
          Text(
            entry.description!,
            textHeightBehavior: _compactTextHeightBehavior,
            style: theme.textTheme.bodySmall?.copyWith(
              color: secondaryTextColor,
              fontWeight: FontWeight.w300,
              height: 1,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }
}
