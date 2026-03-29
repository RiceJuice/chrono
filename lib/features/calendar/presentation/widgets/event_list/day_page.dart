import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/meal_card.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/chor_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/calendar_providers.dart';
import 'cards/event_card.dart';

class DayPage extends ConsumerWidget {
  final DateTime date;
  const DayPage({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Riverpod lädt die Daten für DIESES Datum automatisch im Hintergrund
    final entriesAsync = ref.watch(calendarEntriesForDayProvider(date));

    return entriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(child: Text('Keine Einträge für diesen Tag.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            
            final entry = entries[index];
            if (entry.type == CalendarEntryType.lesson) {
              return EventCard(entry: entry);
            } else if (entry.type == CalendarEntryType.chor) {
              return ChorCard(entry: entry);
            } else if (entry.type == CalendarEntryType.meal) {
              return MealCard(entry: entry);
            } else {
              return EventCard(entry: entry);
            }
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Fehler: $err')),
    );
  }
}