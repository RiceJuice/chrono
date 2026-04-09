import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/models/calendar_entry.dart';
import '../providers/calendar_providers.dart';
import '../widgets/event_list/cards/calendar_entry_card.dart';

class CalendarSearchPage extends ConsumerWidget {
  const CalendarSearchPage({required this.query, super.key});

  final String query;

  DateTime _dayKey(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(filteredCalendarEntriesByQueryProvider(query));

    return entriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(child: Text('Keine Treffer gefunden.'));
        }

        final grouped = <DateTime, List<CalendarEntry>>{};
        for (final entry in entries) {
          final key = _dayKey(entry.startTime);
          grouped.putIfAbsent(key, () => <CalendarEntry>[]).add(entry);
        }
        final days = grouped.keys.toList()..sort();

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          itemCount: days.length,
          itemBuilder: (context, index) {
            final day = days[index];
            final dayEntries = grouped[day]!;
            final dayLabel = DateFormat('EEEE, d. MMMM', 'de').format(day);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    dayLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                for (final entry in dayEntries) CalendarEntryCard(entry: entry),
              ],
            );
          },
        );
      },
      loading: () => const _DebouncedLoadingIndicator(),
      error: (err, stack) => Center(child: Text('Fehler: $err')),
    );
  }
}

class _DebouncedLoadingIndicator extends StatefulWidget {
  const _DebouncedLoadingIndicator();

  @override
  State<_DebouncedLoadingIndicator> createState() =>
      _DebouncedLoadingIndicatorState();
}

class _DebouncedLoadingIndicatorState extends State<_DebouncedLoadingIndicator> {
  static const Duration _delay = Duration(milliseconds: 220);
  bool _showSpinner = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(_delay, () {
      if (!mounted) return;
      setState(() {
        _showSpinner = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showSpinner) {
      return const SizedBox.shrink();
    }
    return const Center(child: CircularProgressIndicator());
  }
}
