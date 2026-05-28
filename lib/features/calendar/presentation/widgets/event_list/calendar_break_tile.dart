import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:flutter/material.dart';

/// Einheitliche Darstellung fuer Ferien-/Feiertags-Termine.
class CalendarBreakTile extends StatelessWidget {
  const CalendarBreakTile({
    required this.label,
    this.compact = false,
    this.centered = false,
    this.fontSize,
    this.fontWeight,
    super.key,
  });

  final String label;
  final bool compact;
  final bool centered;
  final double? fontSize;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 2 : AppSpacing.xs,
        vertical: compact ? 1 : 2,
      ),
      child: Text(
        label,
        maxLines: compact ? 1 : 3,
        overflow: TextOverflow.ellipsis,
        textAlign: centered ? TextAlign.center : TextAlign.start,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: fontWeight ?? FontWeight.w600,
          fontSize: fontSize ?? (compact ? 15 : 17),
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
