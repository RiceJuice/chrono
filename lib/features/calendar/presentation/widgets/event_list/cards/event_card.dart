import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/time_column.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/base_bottom_modal.dart';
import 'package:flutter/material.dart';
import '../../../../domain/models/calendar_entry.dart';

class EventCard extends StatelessWidget {
  final CalendarEntry entry;
  const EventCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (context) => BaseBottomModal(entry: entry),
        );
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      leading: TimeColumn(entry: entry),
      title: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFF111827),
        ),
        // IntrinsicHeight sorgt dafür, dass die Row so hoch ist wie ihr höchstes Kind
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment
                .stretch, // WICHTIG: Streckt Kinder auf die volle Höhe
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsGeometry.symmetric(
                    vertical: 8,
                    horizontal: 14,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.title, style: TextStyle(color: Theme.of(context).colorScheme.tertiary),),
                      if ((entry.subtitle ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          entry.subtitle!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadiusGeometry.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
                child: Image.network(
                  entry.imageUrls![0],
                  width: 120,
                  height: 130,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
