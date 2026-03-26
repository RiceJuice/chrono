
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/event_list.dart';
import 'package:flutter/material.dart';
import '../widgets/calendar_header/calendar_header.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});
  

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
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