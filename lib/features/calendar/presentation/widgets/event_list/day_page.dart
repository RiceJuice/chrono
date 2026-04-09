import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/calendar_providers.dart';
import 'cards/calendar_entry_card.dart';

class DayPage extends ConsumerWidget {
  final DateTime date;
  const DayPage({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(filteredCalendarEntriesForDayProvider(date));

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
            return CalendarEntryCard(entry: entry);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Fehler: $err')),
    );
  }
}