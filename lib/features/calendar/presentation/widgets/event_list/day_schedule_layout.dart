import 'package:chronoapp/features/calendar/domain/layout/school_track_lane_order.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/calendar_now_anchor.dart';

sealed class DayScheduleListItem {
  const DayScheduleListItem();

  DateTime get sortStartTime;

  Iterable<CalendarEntry> get entries;
}

final class DayScheduleSingleItem extends DayScheduleListItem {
  const DayScheduleSingleItem(this.entry);

  final CalendarEntry entry;

  @override
  DateTime get sortStartTime => entry.startTime;

  @override
  Iterable<CalendarEntry> get entries => [entry];
}

final class DayScheduleLessonRowItem extends DayScheduleListItem {
  const DayScheduleLessonRowItem(this.lessons);

  final List<CalendarEntry> lessons;

  @override
  DateTime get sortStartTime => lessons.first.startTime;

  @override
  Iterable<CalendarEntry> get entries => lessons;
}

List<DayScheduleListItem> buildDayScheduleListItems({
  required List<CalendarEntry> entries,
  required List<String> ownSchoolTracks,
}) {
  if (entries.isEmpty) return const [];

  final lessonGroups = _groupOverlappingLessons(
    entries,
    ownSchoolTracks: ownSchoolTracks,
  );
  final groupedLessonIds = <String>{
    for (final group in lessonGroups) for (final lesson in group) lesson.id,
  };

  final items = <DayScheduleListItem>[
    for (final entry in entries)
      if (!groupedLessonIds.contains(entry.id))
        DayScheduleSingleItem(entry),
    for (final group in lessonGroups) DayScheduleLessonRowItem(group),
  ]..sort((a, b) {
    final byStart = a.sortStartTime.compareTo(b.sortStartTime);
    if (byStart != 0) return byStart;
    return _stableItemOrder(a).compareTo(_stableItemOrder(b));
  });

  return items;
}

int entryIndexForNowAnchorInDayItems(List<DayScheduleListItem> items) {
  final flatEntries = <CalendarEntry>[
    for (final item in items) ...item.entries,
  ];
  final anchorEntryIndex = CalendarNowAnchor.entryIndexForNowAnchor(
    flatEntries,
  );
  if (anchorEntryIndex >= flatEntries.length) {
    return items.length;
  }

  final anchorEntry = flatEntries[anchorEntryIndex];
  for (var i = 0; i < items.length; i++) {
    if (items[i].entries.any((entry) => entry.id == anchorEntry.id)) {
      return i;
    }
  }
  return items.length;
}

int _stableItemOrder(DayScheduleListItem item) {
  return switch (item) {
    DayScheduleSingleItem(:final entry) => entry.type.index,
    DayScheduleLessonRowItem() => CalendarEntryType.lesson.index,
  };
}

List<List<CalendarEntry>> _groupOverlappingLessons(
  List<CalendarEntry> entries, {
  required List<String> ownSchoolTracks,
}) {
  final lessons = entries
      .where((entry) => entry.type == CalendarEntryType.lesson)
      .toList(growable: false);
  if (lessons.length < 2) return const [];

  final sortedLessons = [...lessons]
    ..sort(
      (a, b) => compareCalendarEntriesForLaneOrder(
        a,
        b,
        ownSchoolTracks: ownSchoolTracks,
      ),
    );

  final groups = <List<CalendarEntry>>[];
  var currentGroup = <CalendarEntry>[sortedLessons.first];
  var groupEnd = sortedLessons.first.endTime;

  for (var i = 1; i < sortedLessons.length; i++) {
    final lesson = sortedLessons[i];
    if (lesson.startTime.isBefore(groupEnd)) {
      currentGroup.add(lesson);
      if (lesson.endTime.isAfter(groupEnd)) {
        groupEnd = lesson.endTime;
      }
      continue;
    }

    if (currentGroup.length > 1) {
      groups.add(_sortedLessonGroup(currentGroup, ownSchoolTracks));
    }
    currentGroup = [lesson];
    groupEnd = lesson.endTime;
  }

  if (currentGroup.length > 1) {
    groups.add(_sortedLessonGroup(currentGroup, ownSchoolTracks));
  }

  return groups;
}

List<CalendarEntry> _sortedLessonGroup(
  List<CalendarEntry> lessons,
  List<String> ownSchoolTracks,
) {
  final sorted = [...lessons]
    ..sort(
      (a, b) => compareCalendarEntriesForLaneOrder(
        a,
        b,
        ownSchoolTracks: ownSchoolTracks,
      ),
    );
  return sorted;
}
