import 'package:flutter/material.dart';

/// Admin-Action: flaches Plus-Icon wie [CalendarFilterDeviationIcon] — kein Liquid Glass.
class CalendarCreateEventButton extends StatelessWidget {
  const CalendarCreateEventButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurface;

    return SizedBox(
      width: kMinInteractiveDimension,
      height: kMinInteractiveDimension,
      child: IconButton(
        onPressed: onPressed,
        tooltip: 'Neuer Termin',
        style: IconButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: foreground,
        ),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
