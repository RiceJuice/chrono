import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/domain/filter/calendar_display_filters.dart';
import 'package:chronoapp/features/calendar/domain/filter/calendar_filters_state.dart';
import 'package:chronoapp/features/calendar/domain/layout/school_track_lane_order.dart';
import 'package:chronoapp/features/calendar/domain/meal_period.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/timetable_live_activity/domain/timetable_live_activity_segment.dart';
import 'package:chronoapp/features/calendar/timetable_live_activity/domain/timetable_live_activity_snapshot.dart';
import 'package:chronoapp/features/calendar/presentation/helpers/lesson_week_grid_display_name.dart';
import 'package:chronoapp/features/calendar/timetable_live_activity/timetable_live_activity_constants.dart';
import 'package:flutter/material.dart';

typedef TimetableAccentResolver = Color Function(CalendarEntry entry);

/// Ermittelt den Tages-Stundenplan für die Live Activity.
abstract final class TimetableLiveActivityResolver {
  TimetableLiveActivityResolver._();

  /// Wie im Wochen-Stundenplan: unbekannte Metadaten ausblenden, wenn
  /// Profil-Filter aktiv sind.
  static bool _hideUnknownWhenFilterActive(CalendarFiltersState filters) =>
      filters.hasInitializedDefaults && filters.hasActiveFilters;

  static TimetableLiveActivitySnapshot? resolve({
    required DateTime day,
    required List<CalendarEntry> entries,
    required CalendarFiltersState filters,
    required TimetableAccentResolver resolveAccent,
    String? imageUrlForEntry(CalendarEntry entry)?,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final localDay = AppDateTime.localDay(day);
    if (!AppDateTime.isTodayLocal(localDay, now: clock)) {
      if (clock.isBefore(localDay)) return null;
    }

    final filtered = applyCalendarDisplayFilters(
      entries: entries,
      filters: filters,
      hideUnknownWhenFilterActive: _hideUnknownWhenFilterActive(filters),
      forEventList: true,
    ).where((entry) {
      if (entry.type != CalendarEntryType.lesson &&
          entry.type != CalendarEntryType.meal) {
        return false;
      }
      if (entry.type == CalendarEntryType.meal &&
          resolveMealPeriod(entry.startTime) != MealPeriod.lunch) {
        return false;
      }
      return AppDateTime.isSameLocalDay(entry.startTime, localDay);
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final ownProfileEntries = filtered
        .where(
          (entry) => lessonMatchesOwnSchoolProfile(
            entry: entry,
            filters: filters,
          ),
        )
        .toList(growable: false);

    if (ownProfileEntries.isEmpty) return null;

    final lessons = ownProfileEntries
        .where((e) => e.type == CalendarEntryType.lesson)
        .toList(growable: false);
    if (lessons.isEmpty) return null;

    final firstLesson = lessons.first;
    final firstLessonStart = AppDateTime.toLocal(firstLesson.startTime);
    final activityStart = firstLessonStart.subtract(
      const Duration(minutes: kTimetableLiveActivityPreStartMinutes),
    );
    final activityStartMs = activityStart.millisecondsSinceEpoch;

    final segments = ownProfileEntries
        .map((entry) => _segmentFromEntry(
              entry: entry,
              resolveAccent: resolveAccent,
              imageUrlForEntry: imageUrlForEntry,
            ))
        .toList(growable: false);

    final lastEnd = segments
        .map((s) => s.endMs)
        .reduce((a, b) => a > b ? a : b);

    if (clock.millisecondsSinceEpoch >= lastEnd) return null;
    if (clock.isBefore(activityStart)) return null;

    final dayDateKey = timetableDayDateKey(localDay);
    final resolved = _resolveCurrent(
      segments: segments,
      activityStartMs: activityStartMs,
      nowMs: clock.millisecondsSinceEpoch,
    );
    if (resolved == null) return null;

    final remainingLessons = _remainingLessonCount(
      segments: segments,
      fromIndex: resolved.index,
      isPreStart: resolved.isPreStart,
    );

    final current = segments[resolved.index];
    final next = resolved.index + 1 < segments.length
        ? segments[resolved.index + 1]
        : null;

    return TimetableLiveActivitySnapshot(
      dayDateKey: dayDateKey,
      customId: liveActivityCustomIdForTimetableDay(dayDateKey),
      segments: segments,
      activityStartMs: activityStartMs,
      dayEndMs: lastEnd,
      currentIndex: resolved.index,
      currentTitle: current.title,
      currentSubtitle: current.subtitle,
      hasNext: next != null,
      nextTitle: next?.title ?? '',
      nextSubtitle: next?.subtitle ?? '',
      segmentStartMs: resolved.segmentStartMs,
      segmentEndMs: resolved.segmentEndMs,
      accentColorHex: current.accentColorHex,
      isMeal: current.isMeal,
      imageUrl: current.imageUrl ?? '',
      remainingLessons: remainingLessons,
      isPreStart: resolved.isPreStart,
    );
  }

  static bool isDayFinished({
    required DateTime day,
    required List<CalendarEntry> entries,
    required CalendarFiltersState filters,
    DateTime? now,
  }) {
    final snapshot = resolve(
      day: day,
      entries: entries,
      filters: filters,
      resolveAccent: (_) => const Color(0xFF124E30),
      now: now,
    );
    return snapshot == null;
  }

  static DateTime? activityStartForDay({
    required DateTime day,
    required List<CalendarEntry> entries,
    required CalendarFiltersState filters,
  }) {
    final filtered = applyCalendarDisplayFilters(
      entries: entries,
      filters: filters,
      hideUnknownWhenFilterActive: _hideUnknownWhenFilterActive(filters),
      forEventList: true,
    ).where((e) => e.type == CalendarEntryType.lesson).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (filtered.isEmpty) return null;
    final firstLessonStart = AppDateTime.toLocal(filtered.first.startTime);
    return firstLessonStart.subtract(
      const Duration(minutes: kTimetableLiveActivityPreStartMinutes),
    );
  }

  static DateTime? dayEndForDay({
    required DateTime day,
    required List<CalendarEntry> entries,
    required CalendarFiltersState filters,
  }) {
    final filtered = applyCalendarDisplayFilters(
      entries: entries,
      filters: filters,
      hideUnknownWhenFilterActive: _hideUnknownWhenFilterActive(filters),
      forEventList: true,
    ).where((entry) {
      return entry.type == CalendarEntryType.lesson ||
          (entry.type == CalendarEntryType.meal &&
              resolveMealPeriod(entry.startTime) == MealPeriod.lunch);
    }).toList();

    if (filtered.isEmpty) return null;
    final last = filtered.reduce(
      (a, b) => a.endTime.isAfter(b.endTime) ? a : b,
    );
    return AppDateTime.toLocal(last.endTime);
  }

  static TimetableLiveActivitySegment _segmentFromEntry({
    required CalendarEntry entry,
    required TimetableAccentResolver resolveAccent,
    String? Function(CalendarEntry entry)? imageUrlForEntry,
  }) {
    final start = AppDateTime.toLocal(entry.startTime);
    final end = AppDateTime.toLocal(entry.endTime);
    final subtitle = entry.type == CalendarEntryType.lesson
        ? (entry.location?.trim() ?? '')
        : '';

    return TimetableLiveActivitySegment(
      id: entry.id,
      type: entry.type,
      title: entry.eventName,
      shortTitle: _shortTitleForEntry(entry),
      subtitle: subtitle,
      startMs: start.millisecondsSinceEpoch,
      endMs: end.millisecondsSinceEpoch,
      accentColorHex: TimetableLiveActivitySegment.accentHexFor(
        resolveAccent(entry),
      ),
      imageUrl: entry.type == CalendarEntryType.meal
          ? imageUrlForEntry?.call(entry)
          : null,
    );
  }

  static ({int index, int segmentStartMs, int segmentEndMs, bool isPreStart})?
      _resolveCurrent({
    required List<TimetableLiveActivitySegment> segments,
    required int activityStartMs,
    required int nowMs,
  }) {
    if (segments.isEmpty) return null;

    final first = segments.first;
    if (nowMs < first.startMs) {
      return (
        index: 0,
        segmentStartMs: activityStartMs,
        segmentEndMs: first.startMs,
        isPreStart: true,
      );
    }

    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      if (nowMs < segment.endMs) {
        return (
          index: i,
          segmentStartMs: segment.startMs,
          segmentEndMs: segment.endMs,
          isPreStart: false,
        );
      }
    }

    return null;
  }

  static String _shortTitleForEntry(CalendarEntry entry) {
    if (entry.type == CalendarEntryType.meal) return 'Essen';
    final display = lessonWeekGridDisplayName(entry.eventName);
    if (display.length <= 3) return display;
    return display.substring(0, 3);
  }

  static int _remainingLessonCount({
    required List<TimetableLiveActivitySegment> segments,
    required int fromIndex,
    required bool isPreStart,
  }) {
    var count = 0;
    for (var i = fromIndex; i < segments.length; i++) {
      final segment = segments[i];
      if (!segment.isLesson) continue;
      if (i == fromIndex && !isPreStart) continue;
      count++;
    }
    return count;
  }
}
