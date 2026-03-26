import 'package:flutter/material.dart';
import 'custom_table_calendar.dart'; // Importiere die neue Datei

class CalendarHeader extends StatelessWidget {
  const CalendarHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      // Hier rufen wir das ausgelagerte Widget auf
      child: const CustomTableCalendar(),
    );
  }
}