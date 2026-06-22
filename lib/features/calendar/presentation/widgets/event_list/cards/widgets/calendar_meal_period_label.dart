import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/features/calendar/domain/meal_period.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:flutter/material.dart';

/// Kleines Overlay-Label für Mittag/Abendessen — liegt über der Karte, ohne
/// den bestehenden Karteninhalt umzubauen.
class CalendarMealCardPeriodOverlay extends StatelessWidget {
  const CalendarMealCardPeriodOverlay({
    super.key,
    required this.entry,
    required this.labelTextColor,
    required this.child,
    this.compact = false,
  });

  final CalendarEntry entry;
  final Color labelTextColor;
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        child,
        Positioned(
          top: compact ? AppSpacing.xs : AppSpacing.s,
          right: compact ? AppSpacing.xs : AppSpacing.s,
          child: IgnorePointer(
            child: CalendarMealPeriodLabel(
              startTime: entry.startTime,
              textColor: labelTextColor,
              compact: compact,
            ),
          ),
        ),
      ],
    );
  }
}

class CalendarMealPeriodLabel extends StatelessWidget {
  const CalendarMealPeriodLabel({
    super.key,
    required this.startTime,
    required this.textColor,
    this.backgroundColor,
    this.compact = false,
  });

  final DateTime startTime;
  final Color textColor;
  final Color? backgroundColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final period = resolveMealPeriod(startTime);
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? textColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 5 : 6,
          vertical: compact ? 1.5 : 2,
        ),
        child: Text(
          period.label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: textColor.withValues(alpha: 0.9),
            fontSize: compact ? 9 : 10,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
