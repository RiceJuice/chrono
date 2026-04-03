
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:flutter/material.dart';

class TextContent extends StatelessWidget{
  const TextContent({super.key,required this.entry});

  final CalendarEntry entry;

  @override
  Widget build (BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(entry.title),
        if ((entry.subtitle ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            entry.subtitle!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}