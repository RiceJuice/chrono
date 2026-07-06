import 'dart:async';

import 'package:chronoapp/core/database/database_provider.dart';
import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/data/calendar_image_url_resolver.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/live_activity/data/schedule_segment_timer_scheduler.dart';
import 'package:chronoapp/features/calendar/data/calendar_signed_url_cache.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_accent_overrides_provider.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:chronoapp/features/calendar/presentation/providers/subjects_providers.dart';
import 'package:chronoapp/features/calendar/timetable_live_activity/data/timetable_live_activity_data_source.dart';
import 'package:chronoapp/features/calendar/timetable_live_activity/data/timetable_live_activity_local_scheduler.dart';
import 'package:chronoapp/features/calendar/live_activity/data/schedule_live_activity_service_provider.dart';
import 'package:chronoapp/features/calendar/timetable_live_activity/data/timetable_live_activity_service.dart';
import 'package:chronoapp/features/calendar/timetable_live_activity/domain/timetable_live_activity_resolver.dart';
import 'package:chronoapp/features/calendar/timetable_live_activity/domain/timetable_live_activity_snapshot.dart';
import 'package:chronoapp/features/calendar/timetable_live_activity/timetable_live_activity_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Steuert Start/Ende der Stundenplan-Live-Activity (voller Tagesplan im Payload).
class TimetableLiveActivityCoordinator {
  TimetableLiveActivityCoordinator({
    required TimetableLiveActivityDataSource dataSource,
    required TimetableLiveActivityService service,
    required TimetableLiveActivityLocalScheduler localScheduler,
    required ScheduleSegmentTimerScheduler segmentTimerScheduler,
    required CalendarImageUrlResolver imageUrlResolver,
    required Ref ref,
  })  : _dataSource = dataSource,
        _service = service,
        _localScheduler = localScheduler,
        _segmentTimerScheduler = segmentTimerScheduler,
        _imageUrlResolver = imageUrlResolver,
        _ref = ref;

  final TimetableLiveActivityDataSource _dataSource;
  final TimetableLiveActivityService _service;
  final TimetableLiveActivityLocalScheduler _localScheduler;
  final ScheduleSegmentTimerScheduler _segmentTimerScheduler;
  final CalendarImageUrlResolver _imageUrlResolver;
  final Ref _ref;

  final Set<String> _activeCustomIds = {};
  final Map<String, String> _lastContentFingerprint = {};
  StreamSubscription<void>? _dbSub;
  ProviderSubscription<CalendarFiltersState>? _filterSub;
  bool _running = false;
  bool _syncRunning = false;
  bool _syncAgain = false;

  bool get isRunning => _running;

  static TimetableLiveActivityCoordinator? instance;

  Future<void> start() async {
    if (_running) return;
    final enabled = await _service.init();
    if (!enabled) return;

    await _localScheduler.init(
      onPayload: handleLocalNotificationPayload,
    );
    _running = true;

    _dbSub = watchTimetableCalendarChanges(_ref.read(dbProvider)).listen((_) {
      unawaited(_refresh());
    });

    _filterSub = _ref.listen(calendarFiltersProvider, (previous, next) {
      if (previous != next) {
        unawaited(_refresh());
      }
    });

    unawaited(_refresh());
  }

  Future<void> refreshNow() async {
    if (!_running) return;
    await _refresh();
    await _reconcileActiveState();
  }

  Future<void> dispose() async {
    _running = false;
    await _dbSub?.cancel();
    _filterSub?.close();
    _dbSub = null;
    _filterSub = null;
    _segmentTimerScheduler.dispose();
  }

  Future<void> handleLocalNotificationPayload(String payload) async {
    final parts = payload.split('|');
    if (parts.length != 2) return;
    final dayDateKey = parts[0];
    if (parts[1] == TimetableLiveActivityLocalScheduler.endPayloadMarker) {
      await _endForDay(dayDateKey);
      return;
    }
    await _activateForDay(dayDateKey);
  }

  Future<void> handleFcmData(Map<String, String> data) async {
    final type = data['type'];
    if (type != 'timetable_live_activity') return;

    final event = data['event'] ?? 'update';
    final dayDateKey = data['day_date'] ?? data['event_id'];
    if (dayDateKey == null || dayDateKey.isEmpty) return;

    if (event == 'end') {
      await _endForDay(dayDateKey, customId: data['activity_id']);
      return;
    }

    await _activateForDay(dayDateKey);
  }

  Future<void> _refresh() async {
    if (!_running) return;

    final now = DateTime.now();
    final today = AppDateTime.localDay(now);
    final dayAfterTomorrow = AppDateTime.addLocalCalendarDays(today, 2);
    final filters = _ref.read(calendarFiltersProvider);

    final starts = await _dataSource.upcomingActivityStarts(
      rangeStart: today,
      rangeEndExclusive: dayAfterTomorrow,
      filters: filters,
    );
    final ends = await _dataSource.upcomingDayEnds(
      rangeStart: today,
      rangeEndExclusive: dayAfterTomorrow,
      filters: filters,
    );
    final boundaries = await _dataSource.upcomingSegmentBoundaries(
      rangeStart: today,
      rangeEndExclusive: dayAfterTomorrow,
      filters: filters,
    );

    await _localScheduler.reschedule(
      starts: starts
          .map((s) => (dayDateKey: s.dayDateKey, start: s.at))
          .toList(),
      ends: ends.map((e) => (dayDateKey: e.dayDateKey, end: e.end)).toList(),
    );

    _segmentTimerScheduler.reschedule(
      starts: [
        ...starts.map(
          (s) => (
            eventId: s.dayDateKey,
            scheduleId: 'start',
            at: AppDateTime.toLocal(s.at),
          ),
        ),
        ...boundaries.map(
          (b) => (
            eventId: b.dayDateKey,
            scheduleId: b.segmentId,
            at: AppDateTime.toLocal(b.at),
          ),
        ),
      ],
      dayEnds: ends
          .map(
            (e) => (
              eventId: e.dayDateKey,
              at: AppDateTime.toLocal(e.end),
            ),
          )
          .toList(),
      onSegmentStart: (dayDateKey) {
        unawaited(_activateForDay(dayDateKey));
      },
      onDayEnd: (dayDateKey) {
        unawaited(_endForDay(dayDateKey));
      },
    );

    await _reconcileActiveState();
  }

  Future<void> _reconcileActiveState() async {
    if (_syncRunning) {
      _syncAgain = true;
      return;
    }
    _syncRunning = true;
    try {
      do {
        _syncAgain = false;
        await _reconcileActiveStateLocked();
      } while (_syncAgain && _running);
    } finally {
      _syncRunning = false;
    }
  }

  Future<void> _reconcileActiveStateLocked() async {
    if (!_running) return;

    final now = DateTime.now();
    final today = AppDateTime.localDay(now);
    final dayDateKey = timetableDayDateKey(today);
    final customId = liveActivityCustomIdForTimetableDay(dayDateKey);

    final snapshot = await _resolveSnapshot(day: today, now: now);
    if (snapshot != null) {
      await _applySnapshotIfNeeded(snapshot);
      _activeCustomIds
        ..clear()
        ..add(customId);
      return;
    }

    if (_activeCustomIds.contains(customId)) {
      await _service.end(customId);
      _activeCustomIds.remove(customId);
      _lastContentFingerprint.remove(customId);
    }
  }

  Future<void> _activateForDay(String dayDateKey) async {
    if (_syncRunning) {
      _syncAgain = true;
      return;
    }

    final day = _parseDayDateKey(dayDateKey);
    if (day == null) return;

    final snapshot = await _resolveSnapshot(day: day);
    if (snapshot == null) return;

    await _applySnapshot(snapshot);
    _activeCustomIds.add(snapshot.customId);
    _lastContentFingerprint[snapshot.customId] = snapshot.contentFingerprint;
  }

  Future<void> _endForDay(String dayDateKey, {String? customId}) async {
    final id = customId ?? liveActivityCustomIdForTimetableDay(dayDateKey);
    await _service.end(id);
    _activeCustomIds.remove(id);
    _lastContentFingerprint.remove(id);
  }

  Future<void> _applySnapshotIfNeeded(
    TimetableLiveActivitySnapshot snapshot,
  ) async {
    final lastFingerprint = _lastContentFingerprint[snapshot.customId];
    if (_activeCustomIds.contains(snapshot.customId) &&
        lastFingerprint == snapshot.contentFingerprint) {
      return;
    }
    await _applySnapshot(snapshot);
    _lastContentFingerprint[snapshot.customId] = snapshot.contentFingerprint;
  }

  Future<void> _applySnapshot(TimetableLiveActivitySnapshot snapshot) async {
    final activitiesEnabled = await _service.areActivitiesEnabled();
    if (!activitiesEnabled) return;
    await _service.createOrUpdate(snapshot);
  }

  Future<TimetableLiveActivitySnapshot?> _resolveSnapshot({
    required DateTime day,
    DateTime? now,
  }) async {
    final entries = await _dataSource.entriesForDay(day);
    final filters = _ref.read(calendarFiltersProvider);

    await CalendarSignedUrlCache.shared.ensureLoaded();
    await _ensureMealImageUrlsResolved(entries);

    return TimetableLiveActivityResolver.resolve(
      day: day,
      entries: entries,
      filters: filters,
      resolveAccent: (entry) => _resolveAccent(entry),
      imageUrlForEntry: _peekMealImageUrl,
      now: now,
    );
  }

  Color _resolveAccent(CalendarEntry entry) {
    if (entry.type == CalendarEntryType.lesson && entry.subjectId != null) {
      final subjectOverrides =
          _ref.read(subjectAccentOverridesProvider).value ??
              const <String, Color>{};
      final subjectOverride = subjectOverrides[entry.subjectId!];
      if (subjectOverride != null) return subjectOverride;
      return entry.accentColor;
    }

    final overrides = _ref.read(calendarAccentOverridesProvider);
    return overrides[entry.type] ?? entry.accentColor;
  }

  String? _peekMealImageUrl(CalendarEntry entry) {
    final urls = entry.imageUrls;
    if (urls != null && urls.isNotEmpty) return urls.first;

    final resolved = _imageUrlResolver.peekResolvedUrls(entry.imagePaths);
    return resolved?.firstOrNull;
  }

  Future<void> _ensureMealImageUrlsResolved(List<CalendarEntry> entries) async {
    for (final entry in entries) {
      if (entry.type != CalendarEntryType.meal) continue;
      if (entry.imageUrls != null && entry.imageUrls!.isNotEmpty) continue;
      final paths = entry.imagePaths;
      if (paths == null || paths.isEmpty) continue;
      await _imageUrlResolver.resolveSignedUrls(paths);
    }
  }

  DateTime? _parseDayDateKey(String dayDateKey) {
    final parts = dayDateKey.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }
}

final timetableLiveActivityCoordinatorProvider =
    Provider<TimetableLiveActivityCoordinator>((ref) {
  ref.keepAlive();
  return TimetableLiveActivityCoordinator(
    dataSource: TimetableLiveActivityDataSource(
      ref.watch(calendarRepositoryProvider),
    ),
    service: TimetableLiveActivityService(
      sharedService: ref.watch(scheduleLiveActivityServiceProvider),
    ),
    localScheduler: TimetableLiveActivityLocalScheduler(),
    segmentTimerScheduler: ScheduleSegmentTimerScheduler(),
    imageUrlResolver: CalendarImageUrlResolver(
      supabase: Supabase.instance.client,
    ),
    ref: ref,
  );
});
