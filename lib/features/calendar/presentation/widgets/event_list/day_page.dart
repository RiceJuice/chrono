import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/calendar_entry.dart';
import '../../providers/calendar_providers.dart';
import 'cards/calendar_entry_card.dart';

class DayPage extends ConsumerWidget {
  final DateTime date;
  const DayPage({super.key, required this.date});

  bool _isLessonEndingAt1015(CalendarEntry entry) {
    if (entry.type != CalendarEntryType.lesson) return false;
    final localEnd = entry.endTime.toLocal();
    return localEnd.hour == 10 && localEnd.minute == 15;
  }

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
            final hasFollowingEntry = index < entries.length - 1;
            final needsMidMorningBreakGap =
                hasFollowingEntry && _isLessonEndingAt1015(entry);
            return Padding(
              padding: EdgeInsets.only(bottom: needsMidMorningBreakGap ? 15 : 0),
              child: CalendarEntryCard(entry: entry),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Fehler: $err')),
    );
  }
}