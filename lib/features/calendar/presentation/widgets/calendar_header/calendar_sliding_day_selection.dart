import 'package:chronoapp/features/calendar/presentation/widgets/calendar_header/calendar_day_spring_interaction.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_week_layout_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Gleitende Auswahl-Pille für eine gleichmäßige Tageszeile (iOS-Kalender-Stil).
///
/// Die Kind-Widgets zeigen nur Zahl + Marker; die Pille bewegt sich federnd
/// unter dem aktiven Tag.
class CalendarSlidingDaySelectionLayer extends StatefulWidget {
  const CalendarSlidingDaySelectionLayer({
    required this.selectedIndex,
    required this.itemCount,
    required this.child,
    this.animate = true,
    super.key,
  }) : assert(itemCount > 0);

  final int selectedIndex;
  final int itemCount;
  final Widget child;
  final bool animate;

  @override
  State<CalendarSlidingDaySelectionLayer> createState() =>
      _CalendarSlidingDaySelectionLayerState();
}

class _CalendarSlidingDaySelectionLayerState
    extends State<CalendarSlidingDaySelectionLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _indexController;
  int _committedIndex = 0;

  @override
  void initState() {
    super.initState();
    _committedIndex = widget.selectedIndex.clamp(0, widget.itemCount - 1);
    _indexController = AnimationController(
      vsync: this,
      value: _committedIndex.toDouble(),
      lowerBound: 0,
      upperBound: (widget.itemCount - 1).toDouble(),
    );
  }

  @override
  void didUpdateWidget(CalendarSlidingDaySelectionLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.selectedIndex.clamp(0, widget.itemCount - 1);
    if (next == _committedIndex) return;

    if (widget.animate) {
      final velocity = (next - _indexController.value) * 11;
      _indexController.stop();
      final simulation = SpringSimulation(
        CalendarDaySpringPhysics.slide,
        _indexController.value,
        next.toDouble(),
        velocity,
        tolerance: CalendarDaySpringPhysics.simulationTolerance,
      );
      _indexController.animateWith(simulation);
    } else {
      _indexController.value = next.toDouble();
    }
    _committedIndex = next;
  }

  @override
  void dispose() {
    _indexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / widget.itemCount;
        final horizontalInset =
            (itemWidth - kCalendarSelectedDayBoxSize) / 2;

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            AnimatedBuilder(
              animation: _indexController,
              builder: (context, _) {
                final left =
                    _indexController.value * itemWidth + horizontalInset;
                return Positioned(
                  left: left,
                  top: kCalendarSelectedDayContainerOffsetY,
                  width: kCalendarSelectedDayBoxSize,
                  height: kCalendarSelectedDayBoxSize,
                  child: Transform.translate(
                    offset: const Offset(0, kCalendarSelectedDayFillOffsetY),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ),
                );
              },
            ),
            widget.child,
          ],
        );
      },
    );
  }
}
