import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/core/database/backend_enums.dart';
import 'package:flutter/material.dart';

/// Ob die Uhrzeit-Zeile bei begrenzter Kartenhöhe Platz hat (vermeidet Overflow).
bool shouldShowCalendarEntryTimeRangeRow({
  required BoxConstraints constraints,
  required bool wantTimeRange,
  required bool compact,
  required bool hasChoirLine,
  required bool hasDescription,
}) {
  if (!wantTimeRange) return false;
  if (!constraints.hasBoundedHeight || !constraints.maxHeight.isFinite) {
    return true;
  }
  var minH = 0.0;
  if (hasChoirLine) minH += 16;
  if (compact) {
    minH += 38;
    minH += 18;
  } else {
    minH += 26;
    if (hasDescription) minH += 36;
    minH += 22;
  }
  return constraints.maxHeight >= minH;
}

/// Zeile mit Uhrzeit-Icon und „HH:mm – HH:mm“ (für Karten ohne [TimeColumn]).
class CalendarEntryTimeRangeRow extends StatelessWidget {
  const CalendarEntryTimeRangeRow({
    super.key,
    required this.entry,
    required this.mutedColor,
    this.compact = false,
  });

  final CalendarEntry entry;
  final Color mutedColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconSize = compact ? 13.0 : 15.0;
    final range =
        '${AppDateTime.formatLocalHourMinute(entry.startTime)} – ${AppDateTime.formatLocalHourMinute(entry.endTime)}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.schedule_rounded, size: iconSize, color: mutedColor),

        SizedBox(width: compact ? 4 : 6),
        Expanded(
          child: Text(
            range,
            maxLines: compact ? 1 : null,
            overflow: compact ? TextOverflow.ellipsis : null,
            style: theme.textTheme.bodySmall?.copyWith(
              color: mutedColor,
              fontWeight: FontWeight.w400,
              height: 1.15,
              fontSize: compact ? 11 : 13,
            ),
          ),
        ),
      ],
    );
  }
}

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
    this.showInlineTimeRange = false,
  });

  final CalendarEntry entry;
  final Color? primaryTextColor;
  final Color? secondaryTextColor;
  final bool showChoirAboveTitle;
  final double? titleFontSize;
  final FontWeight? titleFontWeight;
  final bool compact;

  /// Wenn true: Zeitspanne unter Titel/Beschreibung (z. B. Wochenraster ohne Zeitleiste).
  final bool showInlineTimeRange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedTimeColor = (secondaryTextColor ?? theme.colorScheme.onSurface)
        .withValues(alpha: 0.58);
    final hasDescription =
        !compact && (entry.description ?? '').trim().isNotEmpty;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
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
        if (hasDescription) ...[
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
        if (showInlineTimeRange) ...[
          SizedBox(height: compact ? 3 : (hasDescription ? 6 : 4)),
          CalendarEntryTimeRangeRow(
            entry: entry,
            mutedColor: mutedTimeColor,
            compact: compact,
          ),
        ],
      ],
    );
  }
}
