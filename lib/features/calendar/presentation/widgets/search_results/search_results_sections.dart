import 'package:chronoapp/core/time/app_date_time.dart';

import '../../../domain/models/calendar_entry.dart';

class SearchDaySection {
  const SearchDaySection({required this.day, required this.entries});

  final DateTime day;
  final List<CalendarEntry> entries;
}

class SearchResultsSections {
  const SearchResultsSections({
    required this.sections,
    required this.initialSectionIndex,
    required this.firstUpcomingEntryId,
  });

  final List<SearchDaySection> sections;
  final int initialSectionIndex;
  final String? firstUpcomingEntryId;
}

DateTime _dayKey(DateTime date) {
  return AppDateTime.localDay(date);
}

SearchResultsSections buildSearchResultsSections({
  required List<CalendarEntry> entries,
  DateTime? now,
}) {
  if (entries.isEmpty) {
    return const SearchResultsSections(
      sections: <SearchDaySection>[],
      initialSectionIndex: 0,
      firstUpcomingEntryId: null,
    );
  }

  final today = AppDateTime.todayLocal(now: now);
  final sortedEntries = List<CalendarEntry>.from(entries)
    ..sort((a, b) => a.startTime.compareTo(b.startTime));

  final grouped = <DateTime, List<CalendarEntry>>{};
  for (final entry in sortedEntries) {
    final key = _dayKey(entry.startTime);
    grouped.putIfAbsent(key, () => <CalendarEntry>[]).add(entry);
  }

  final days = grouped.keys.toList()..sort();
  final sections = days
      .map((day) => SearchDaySection(day: day, entries: grouped[day]!))
      .toList(growable: false);

  final todayIndex = days.indexOf(today);
  if (todayIndex >= 0) {
    return SearchResultsSections(
      sections: sections,
      initialSectionIndex: todayIndex,
      firstUpcomingEntryId: null,
    );
  }

  final nextDayIndex = days.indexWhere((day) => !day.isBefore(today));
  if (nextDayIndex >= 0) {
    return SearchResultsSections(
      sections: sections,
      initialSectionIndex: nextDayIndex,
      firstUpcomingEntryId: null,
    );
  }

  // Wenn nur Vergangenheit vorhanden ist: letzten Tag zeigen.
  return SearchResultsSections(
    sections: sections,
    initialSectionIndex: sections.length - 1,
    firstUpcomingEntryId: null,
  );
}
