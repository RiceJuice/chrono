import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/core/database/backend_enums.dart';
import 'package:flutter/material.dart';

const _cardTextHeightTight = TextHeightBehavior(
  applyHeightToFirstAscent: false,
  applyHeightToLastDescent: false,
);

/// Layout-Entscheidungen für kompakte Wochenraster-Karten (kein Overflow).
({int titleMaxLines, bool showTimeRange}) resolveCalendarCompactTextLayout({
  required BoxConstraints constraints,
  required bool wantTimeRange,
  required bool hasChoirLine,
  double titleFontSize = 16,
}) {
  if (!constraints.hasBoundedHeight || !constraints.maxHeight.isFinite) {
    return (titleMaxLines: 2, showTimeRange: wantTimeRange);
  }

  final maxH = constraints.maxHeight;
  final choirH = hasChoirLine ? 14.0 : 0.0;
  final lineH = titleFontSize + 2.0;
  const timeBlock = 3.0 + 16.0;

  final oneLineAndTime = choirH + lineH + timeBlock;
  final twoLines = choirH + lineH * 2;
  final twoLinesAndTime = twoLines + timeBlock;

  if (twoLines <= maxH) {
    final showTime = wantTimeRange && twoLinesAndTime <= maxH;
    return (titleMaxLines: 2, showTimeRange: showTime);
  }
  if (oneLineAndTime <= maxH && wantTimeRange) {
    return (titleMaxLines: 1, showTimeRange: true);
  }
  if (choirH + lineH <= maxH) {
    return (titleMaxLines: 1, showTimeRange: false);
  }
  return (titleMaxLines: 1, showTimeRange: false);
}

/// Ob die Uhrzeit-Zeile bei begrenzter Kartenhöhe Platz hat (vermeidet Overflow).
bool shouldShowCalendarEntryTimeRangeRow({
  required BoxConstraints constraints,
  required bool wantTimeRange,
  required bool compact,
  required bool hasChoirLine,
  required bool hasLocation,
}) {
  if (!wantTimeRange) return false;
  if (!constraints.hasBoundedHeight || !constraints.maxHeight.isFinite) {
    return true;
  }
  if (compact) {
    return resolveCalendarCompactTextLayout(
      constraints: constraints,
      wantTimeRange: wantTimeRange,
      hasChoirLine: hasChoirLine,
    ).showTimeRange;
  }
  var minH = 0.0;
  if (hasChoirLine) minH += 16;
  minH += 26;
  if (hasLocation) minH += 22;
  minH += 22;
  return constraints.maxHeight >= minH;
}

/// Kompakter Karteninhalt für das Wochenraster: [TextContent] mit
/// höhenabhängigem Ausblenden der Uhrzeitzeile (vermeidet Overflow).
class CalendarCompactCardText extends StatelessWidget {
  const CalendarCompactCardText({
    super.key,
    required this.entry,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.wantInlineTimeRange,
    this.showChoirAboveTitle = false,
    this.titleFontSize,
    this.titleFontWeight,
  });

  final CalendarEntry entry;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final bool wantInlineTimeRange;
  final bool showChoirAboveTitle;
  final double? titleFontSize;
  final FontWeight? titleFontWeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fontSize = titleFontSize ?? 16;
        final layout = resolveCalendarCompactTextLayout(
          constraints: constraints,
          wantTimeRange: wantInlineTimeRange,
          hasChoirLine:
              showChoirAboveTitle && entry.choir != BackendChoir.unknown,
          titleFontSize: fontSize,
        );
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: constraints.maxHeight),
          child: ClipRect(
            child: TextContent(
              entry: entry,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              showChoirAboveTitle: showChoirAboveTitle,
              titleFontSize: titleFontSize,
              titleFontWeight: titleFontWeight,
              compact: true,
              compactTitleMaxLines: layout.titleMaxLines,
              showInlineTimeRange: layout.showTimeRange,
            ),
          ),
        );
      },
    );
  }
}

/// Uhrzeit „HH:mm – HH:mm“ (für Karten ohne [TimeColumn], z. B. Wochenraster).
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
    final range =
        '${AppDateTime.formatLocalHourMinute(entry.startTime)} – ${AppDateTime.formatLocalHourMinute(entry.endTime)}';

    return Text(
      range,
      maxLines: compact ? 1 : null,
      overflow: compact ? TextOverflow.ellipsis : null,
      textHeightBehavior: _cardTextHeightTight,
      style: theme.textTheme.bodySmall?.copyWith(
        color: mutedColor,
        fontWeight: FontWeight.w300,
        height: 1.15,
        fontSize: compact ? 11 : 14,
      ),
    );
  }
}

/// Ort mit Icon.
class CalendarEntryLocationRow extends StatelessWidget {
  const CalendarEntryLocationRow({
    super.key,
    required this.location,
    required this.subtitleColor,
    this.compact = false,
  });

  final String location;
  final Color subtitleColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = subtitleColor.withValues(alpha: 0.6);
    final iconSize = compact ? 13.0 : 15.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: compact ? 0 : 1),
          child: Icon(Icons.place_outlined, size: iconSize, color: iconColor),
        ),
        SizedBox(width: compact ? 4 : 6),
        Expanded(
          child: Text(
            location,
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            textHeightBehavior: _cardTextHeightTight,
            style: theme.textTheme.bodySmall?.copyWith(
              color: subtitleColor,
              fontWeight: FontWeight.w300,
              height: 1.15,
              fontSize: compact ? 11 : 14,
            ),
          ),
        ),
      ],
    );
  }
}

class TextContent extends StatelessWidget {
  const TextContent({
    super.key,
    required this.entry,
    this.primaryTextColor,
    this.secondaryTextColor,
    this.showChoirAboveTitle = false,
    this.titleFontSize,
    this.titleFontWeight,
    this.compact = false,
    this.compactTitleMaxLines,
    this.showInlineTimeRange = false,
  });

  final CalendarEntry entry;
  final Color? primaryTextColor;
  final Color? secondaryTextColor;
  final bool showChoirAboveTitle;
  final double? titleFontSize;
  final FontWeight? titleFontWeight;
  final bool compact;

  /// Nur im Kompaktmodus: 1 oder 2 Titelzeilen je nach verfügbarer Höhe.
  final int? compactTitleMaxLines;

  /// Wenn true: Zeitspanne unter Titel/Ort (z. B. Wochenraster ohne Zeitleiste).
  final bool showInlineTimeRange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveTitleFontSize = (titleFontSize ?? 16) - (compact ? 1 : 0);
    final mutedTimeColor = (secondaryTextColor ?? theme.colorScheme.onSurface)
        .withValues(alpha: 0.58);
    final trimmedLocation = (entry.location ?? '').trim();
    final hasLocation = trimmedLocation.isNotEmpty;
    final subtitleColor =
        secondaryTextColor ?? theme.colorScheme.onSurface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showChoirAboveTitle && entry.choir != BackendChoir.unknown) ...[
          Text(
            entry.choir.displayLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textHeightBehavior: _cardTextHeightTight,
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
          maxLines: compact ? (compactTitleMaxLines ?? 2).clamp(1, 2) : null,
          overflow: compact ? TextOverflow.ellipsis : null,
          textHeightBehavior: _cardTextHeightTight,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: primaryTextColor,
            height: compact ? 0.95 : 1,
            fontWeight: titleFontWeight ?? FontWeight.w400,
            fontSize: effectiveTitleFontSize,
          ),
        ),
        if (!compact && hasLocation) ...[
          const SizedBox(height: 2),
          CalendarEntryLocationRow(
            location: trimmedLocation,
            subtitleColor: subtitleColor,
          ),
        ],
        if (showInlineTimeRange) ...[
          SizedBox(height: compact ? 3 : 6),
          CalendarEntryTimeRangeRow(
            entry: entry,
            mutedColor: mutedTimeColor,
            compact: compact,
          ),
        ],
        if (compact && hasLocation) ...[
          const SizedBox(height: 2),
          CalendarEntryLocationRow(
            location: trimmedLocation,
            subtitleColor: subtitleColor,
            compact: true,
          ),
        ],
      ],
    );
  }
}
