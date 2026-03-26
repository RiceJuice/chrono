import 'package:chronoapp/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/event_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/calendar_header/calendar_header.dart';
import 'package:intl/intl.dart';

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});
  

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    final selectedDay = ref.watch(selectedDayProvider);
    String monthName = DateFormat.MMMM('de').format(selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: Text(monthName),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CalendarHeader(),
            Divider(),
            Expanded(
              child: EventList(),
            ),
          ],
        ),
      ),
    );
  }
}