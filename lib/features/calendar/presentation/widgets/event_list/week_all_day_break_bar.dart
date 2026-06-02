import 'package:chronoapp/features/calendar/presentation/theme/calendar_presentation_theme.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_all_day_break_layout.dart';
import 'package:flutter/material.dart';

/// Farbiger Ganztags-Balken (Apple-Kalender-Stil) für die Wochenansicht.
class WeekAllDayBreakBar extends StatelessWidget {
  const WeekAllDayBreakBar({
    required this.label,
    required this.segment,
    required this.showLabel,
    super.key,
  });

  final String label;
  final WeekAllDayBreakBarSegment segment;
  final bool showLabel;

  static const _radius = Radius.circular(7);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = CalendarPresentationTheme.holidayBlue(context);
    final fill = Color.alphaBlend(
      accent.withValues(alpha: scheme.brightness == Brightness.dark ? 0.34 : 0.20),
      scheme.surfaceContainerHigh,
    );

    final borderRadius = BorderRadius.horizontal(
      left: switch (segment) {
        WeekAllDayBreakBarSegment.single ||
        WeekAllDayBreakBarSegment.start => _radius,
        WeekAllDayBreakBarSegment.middle ||
        WeekAllDayBreakBarSegment.end => Radius.zero,
      },
      right: switch (segment) {
        WeekAllDayBreakBarSegment.single ||
        WeekAllDayBreakBarSegment.end => _radius,
        WeekAllDayBreakBarSegment.start ||
        WeekAllDayBreakBarSegment.middle => Radius.zero,
      },
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: borderRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: showLabel
              ? Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.1,
                      ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
