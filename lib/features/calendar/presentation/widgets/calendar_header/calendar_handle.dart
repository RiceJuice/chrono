import 'package:flutter/material.dart';

class CalendarHandle extends StatelessWidget {
  const CalendarHandle({
    super.key,
    required this.isPressed,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.onVerticalDragStart,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
  });

  final bool isPressed;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCancelCallback? onTapCancel;
  final GestureDragStartCallback? onVerticalDragStart;
  final GestureDragUpdateCallback? onVerticalDragUpdate;
  final GestureDragEndCallback? onVerticalDragEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: onTapDown,
      onTapUp: onTapUp,
      onTapCancel: onTapCancel,
      onVerticalDragStart: onVerticalDragStart,
      onVerticalDragUpdate: onVerticalDragUpdate,
      onVerticalDragEnd: onVerticalDragEnd,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          width: isPressed ? 40 : 36,
          height: 5,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withValues(
              alpha: isPressed ? 0.55 : 0.35,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
