import '../../../domain/models/calendar_entry.dart';

class SearchDaySection {
  const SearchDaySection({
    required this.day,
    required this.entries,
  });

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
  final local = date.toLocal();
  return DateTime(local.year, local.month, local.day);
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

  final nowLocal = now ?? DateTime.now();
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

  DateTime? firstUpcomingDay;
  String? firstUpcomingEntryId;
  for (final entry in sortedEntries) {
    if (!entry.endTime.isBefore(nowLocal)) {
      firstUpcomingDay = _dayKey(entry.startTime);
      firstUpcomingEntryId = entry.id;
      break;
    }
  }

  if (firstUpcomingDay == null) {
    return SearchResultsSections(
      sections: sections,
      initialSectionIndex: sections.length - 1,
      firstUpcomingEntryId: null,
    );
  }

  final initialIndex = days.indexOf(firstUpcomingDay);
  return SearchResultsSections(
    sections: sections,
    initialSectionIndex: initialIndex < 0 ? 0 : initialIndex,
    firstUpcomingEntryId: firstUpcomingEntryId,
  );
}
