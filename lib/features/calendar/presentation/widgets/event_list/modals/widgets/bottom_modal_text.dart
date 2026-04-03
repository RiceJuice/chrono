import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:flutter/material.dart';

class BottomModalText extends StatelessWidget {
  const BottomModalText({super.key, required this.entry, this.titleStyle});

  final CalendarEntry entry;
  final TextStyle? titleStyle;

  String _formatTime(DateTime value) {
    final hours = value.hour.toString().padLeft(2, '0');
    final minutes = value.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),

          Text(
            entry.title,
            style: titleStyle ?? Theme.of(context).textTheme.titleLarge,
          ), // Komma hier nicht vergessen

          if ((entry.subtitle ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              entry.subtitle!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],

          const SizedBox(height: 4),

          Text(
            '${_formatTime(entry.startTime)} - ${_formatTime(entry.endTime)} Uhr',
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          if ((entry.location ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Ort: ${entry.location!}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}
