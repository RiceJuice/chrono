import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:flutter/material.dart';

/// Einheitlicher farbiger Streifen links in Kalenderkarten (Schule, Chor, …).
class CalendarCardLeadingIndicator extends StatelessWidget {
  const CalendarCardLeadingIndicator({
    super.key,
    required this.color,
    this.emphasized = false,
  });

  final Color color;
  final bool emphasized;

  static const double barWidth = 6;
  static const double emphasizedBarWidth = 9;
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
      width: emphasized ? emphasizedBarWidth : barWidth,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(barBorderRadius),
        boxShadow: emphasized
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 6,
                  spreadRadius: 0.5,
                ),
              ]
            : null,
      ),
    );
  }
}
