import 'package:flutter/material.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/calendar_entry_bottom_modal.dart';
import '../../../../domain/models/calendar_entry.dart';

class ChorCard extends StatelessWidget {
  final CalendarEntry entry;
  const ChorCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final timeStyle = Theme.of(context).textTheme.bodyMedium;
    return ListTile(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (context) {
            return CalendarEntryBottomModal(entry: entry);
          },
        );
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${entry.startTime.hour.toString().padLeft(2, '0')}:${entry.startTime.minute.toString().padLeft(2, '0')}',
            style: timeStyle,
          ),
          Text(
            '${entry.endTime.hour.toString().padLeft(2, '0')}:${entry.endTime.minute.toString().padLeft(2, '0')}',
            style: timeStyle,
          ),
        ],
      ),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: entry.accentColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
