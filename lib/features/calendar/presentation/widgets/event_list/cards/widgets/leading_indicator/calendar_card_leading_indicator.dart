import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:flutter/material.dart';

/// Einheitlicher farbiger Streifen links in Kalenderkarten (Schule, Chor, …).
class CalendarCardLeadingIndicator extends StatelessWidget {
  const CalendarCardLeadingIndicator({super.key, required this.color});

  final Color color;

  static const double barWidth = 6;
  static const double barBorderRadius = 3;
  static const double gapAfterBar = AppSpacing.s;

  /// Innenabstand der Kartenfläche, wenn ein Leading Indicator angezeigt wird.
  static const EdgeInsets contentPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.s,
    vertical: AppSpacing.s,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: barWidth,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(barBorderRadius),
      ),
    );
  }
}
