import 'package:flutter/material.dart';

/// Leerer Tageszustand in der Terminliste (Tag ohne echte Termine).
class CalendarDayEmptyState extends StatelessWidget {
  const CalendarDayEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Keine Termine an diesem Tag.'),
    );
  }
}
