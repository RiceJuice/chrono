import 'package:chronoapp/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Icon-Glyphe (24 dp) sitzt zentriert im 48-dp-[IconButton].
const double _kIconGlyphSize = 24;
const double _kIconSlotInset =
    (kMinInteractiveDimension - _kIconGlyphSize) / 2;

/// Feintuning relativ zur rechten unteren Icon-Ecke (negativ = näher/rüberlappend).
const double kFilterDeviationBadgeOffsetX = 0;
const double kFilterDeviationBadgeOffsetY = 0;

/// Filter-Action: Icon zentriert, Zahl unten rechts an der Glyphe.
class CalendarFilterDeviationIcon extends ConsumerWidget {
  const CalendarFilterDeviationIcon({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(
      calendarFiltersProvider.select((filters) => filters.deviationCategoryCount),
    );
    final showsBadge = count > 0;

    return SizedBox(
      width: kMinInteractiveDimension,
      height: kMinInteractiveDimension,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: onPressed,
            tooltip: 'Kalenderfilter',
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          if (showsBadge)
            Positioned(
              left: _kIconSlotInset +
                  _kIconGlyphSize +
                  kFilterDeviationBadgeOffsetX,
              bottom: _kIconSlotInset + kFilterDeviationBadgeOffsetY,
              child: _OutlinedIconStyleCount(text: '$count'),
            ),
        ],
      ),
    );
  }
}

/// Ziffern im Outline-Stil wie [Icons.calendar_month_outlined].
class _OutlinedIconStyleCount extends StatelessWidget {
  const _OutlinedIconStyleCount({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final color = iconTheme.color ?? Theme.of(context).colorScheme.onSurface;
    final iconSize = iconTheme.size ?? 24.0;
    final strokeWidth = iconSize / 20;
    final fontSize = iconSize * 0.375;

    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w200,
        height: 1,
        letterSpacing: 0,
        fontFeatures: const [FontFeature.tabularFigures()],
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = color
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      ),
    );
  }
}
