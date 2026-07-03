import 'dart:async';

import 'package:chronoapp/core/database/database_provider.dart';
import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/domain/filter/event_schedule_filter.dart';
import 'package:chronoapp/features/calendar/live_activity/data/schedule_live_activity_data_source.dart';
import 'package:chronoapp/features/calendar/live_activity/data/schedule_live_activity_local_scheduler.dart';
import 'package:chronoapp/features/calendar/live_activity/data/schedule_live_activity_repository.dart';
import 'package:chronoapp/features/calendar/live_activity/data/schedule_live_activity_service.dart';
import 'package:chronoapp/features/calendar/live_activity/data/schedule_segment_timer_scheduler.dart';
import 'package:chronoapp/features/calendar/live_activity/domain/schedule_live_activity_resolver.dart';
import 'package:chronoapp/features/calendar/live_activity/domain/schedule_live_activity_snapshot.dart';
import 'package:chronoapp/features/calendar/live_activity/live_activity_constants.dart';
import 'package:chronoapp/features/calendar/live_activity/presentation/schedule_list_filter_provider.dart';
import 'package:chronoapp/features/calendar/presentation/providers/filter/calendar/calendar_filters_provider.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/calendar_now_anchor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:live_activities/models/url_scheme_data.dart';

/// Steuert Start/Ende der Live Activities ereignisgesteuert (Segmentstart, FCM, Resume).
class ScheduleLiveActivityCoordinator {
  ScheduleLiveActivityCoordinator({
    required ScheduleLiveActivityDataSource dataSource,
    required ScheduleLiveActivityService service,
    required ScheduleLiveActivityRepository repository,
    required ScheduleLiveActivityLocalScheduler localScheduler,
    required ScheduleSegmentTimerScheduler segmentTimerScheduler,
    required Ref ref,
  })  : _dataSource = dataSource,
        _service = service,
        _repository = repository,
        _localScheduler = localScheduler,
        _segmentTimerScheduler = segmentTimerScheduler,
        _ref = ref;

  final ScheduleLiveActivityDataSource _dataSource;
  final ScheduleLiveActivityService _service;
  final ScheduleLiveActivityRepository _repository;
  final ScheduleLiveActivityLocalScheduler _localScheduler;
  final ScheduleSegmentTimerScheduler _segmentTimerScheduler;
  final Ref _ref;

  final Set<String> _activeCustomIds = {};
  final Map<String, String> _lastAppliedScheduleId = {};
  final Map<String, String> _lastContentFingerprint = {};
  StreamSubscription<void>? _dbSub;
  ProviderSubscription<AsyncValue<EventScheduleListFilter>>? _filterSub;
  bool _running = false;

  bool _syncRunning = false;
  bool _syncAgain = false;

  bool get isRunning => _running;

  static ScheduleLiveActivityCoordinator? instance;

  Future<void> start({void Function(UrlSchemeData data)? onUrlScheme}) async {
    if (_running) return;
    final enabled = await _service.init();
    if (!enabled) return;

    _service.onLiveActivityPushToken = (token) {
      unawaited(_repository.syncLiveActivityPushToken(token));
    };
    _service.onPushToStartToken = (token) {
      unawaited(_repository.syncPushToStartToken(token));
    };
    _service.onUrlScheme = onUrlScheme;

    await _localScheduler.init(
      onPayload: handleLocalNotificationPayload,
    );
    _running = true;

    _dbSub = _dataSource.watchScheduleChanges().listen((_) {
      unawaited(_refresh());
    });

    _filterSub = _ref.listen(scheduleListFilterProvider, (previous, next) {
      if (previous?.value != next.value) {
        unawaited(_refresh());
      }
    });

    unawaited(_refresh());
  }

  /// Erneuter Sync nach App-Resume oder Hot-Restart.
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
    await _service.dispose();
  }

  Future<void> handleLocalNotificationPayload(String payload) async {
    final parts = payload.split('|');
    if (parts.length != 2) return;
    if (parts[1] == ScheduleLiveActivityLocalScheduler.endPayloadMarker) {
      await _endForEvent(parts[0]);
      return;
    }
    await _activateForEvent(parts[0]);
  }

  Future<void> handleFcmData(Map<String, String> data) async {
    final type = data['type'];
    if (type != 'schedule_live_activity') return;

    final event = data['event'] ?? 'update';
    final eventId = data['event_id'];
    if (eventId == null || eventId.isEmpty) return;

    if (event == 'end') {
      await _endForEvent(eventId, customId: data['activity_id']);
      return;
    }

    if (event == 'update') {
      await _activateForEvent(eventId);
      return;
    }

    if (event == 'start') {
      await _activateForEvent(eventId);
    }
  }

  Future<void> _refresh() async {
    if (!_running) return;

    final now = DateTime.now();
    final today = AppDateTime.localDay(now);
    final dayAfterTomorrow = AppDateTime.addLocalCalendarDays(today, 2);

    final segments = await _dataSource.upcomingSegmentStarts(
      rangeStart: today,
      rangeEndExclusive: dayAfterTomorrow,
    );
    final eventStarts = await _dataSource.upcomingEventStarts(
      rangeStart: today,
      rangeEndExclusive: dayAfterTomorrow,
    );

    final dayEnds = await _computeDayEnds(
      dayStart: today,
      dayEndExclusive: dayAfterTomorrow,
    );

    await _localScheduler.rescheduleSegments(
      segments: segments,
      eventStarts: eventStarts,
    );
    await _localScheduler.rescheduleDayEnds(ends: dayEnds);

    _segmentTimerScheduler.reschedule(
      starts: [
        ...segments.map(
          (s) => (
            eventId: s.eventId,
            scheduleId: s.scheduleId,
            at: AppDateTime.toLocal(s.start),
          ),
        ),
        ...eventStarts.map(
          (s) => (
            eventId: s.eventId,
            scheduleId: s.eventId,
            at: AppDateTime.toLocal(s.start),
          ),
        ),
      ],
      dayEnds: dayEnds
          .map((e) => (eventId: e.eventId, at: AppDateTime.toLocal(e.end)))
          .toList(),
      onSegmentStart: (eventId) {
        unawaited(_activateForEvent(eventId));
      },
      onDayEnd: (eventId) {
        unawaited(_endForEvent(eventId));
      },
    );

    await _reconcileActiveState();
  }

  Future<List<({String eventId, DateTime end})>> _computeDayEnds({
    required DateTime dayStart,
    required DateTime dayEndExclusive,
  }) async {
    final eventIds = await _dataSource.eventIdsWithSchedulesOnDays(
      dayStart: dayStart,
      dayEndExclusive: dayEndExclusive,
    );
    final eventsWithoutSchedule = await _dataSource.eventsWithoutSchedule(
      rangeStart: dayStart,
      rangeEndExclusive: dayEndExclusive,
    );

    final filters = _ref.read(calendarFiltersProvider);
    final listFilter = _ref.read(scheduleListFilterProvider).value ??
        EventScheduleListFilter.all;
    final now = DateTime.now();
    final ends = <({String eventId, DateTime end})>[];

    for (final eventId in eventIds) {
      final schedules = await _dataSource.schedulesForEvent(eventId);
      final visibleToday = schedules.where((schedule) {
        if (!AppDateTime.isTodayLocal(schedule.startTime, now: now)) {
          return false;
        }
        if (listFilter == EventScheduleListFilter.mine &&
            !eventScheduleMatchesUserProfile(
              schedule: schedule,
              filters: filters,
            )) {
          return false;
        }
        return eventScheduleVisible(schedule: schedule, filters: filters);
      }).toList();

      if (visibleToday.isEmpty) continue;

      final last = visibleToday.reduce((a, b) {
        final aEnd = CalendarNowAnchor.scheduleEffectiveEnd(a);
        final bEnd = CalendarNowAnchor.scheduleEffectiveEnd(b);
        return aEnd.isAfter(bEnd) ? a : b;
      });

      ends.add((
        eventId: eventId,
        end: CalendarNowAnchor.scheduleEffectiveEnd(last),
      ));
    }

    for (final event in eventsWithoutSchedule) {
      if (!AppDateTime.isTodayLocal(event.startTime, now: now)) continue;
      if (listFilter == EventScheduleListFilter.mine &&
          !calendarEventMatchesUserProfile(event: event, filters: filters)) {
        continue;
      }
      if (!calendarEventVisible(event: event, filters: filters)) continue;
      ends.add((eventId: event.id, end: event.endTime));
    }

    return ends;
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
    final dayAfterTomorrow = AppDateTime.addLocalCalendarDays(today, 2);

    final eventIds = await _dataSource.eventIdsWithSchedulesOnDays(
      dayStart: today,
      dayEndExclusive: dayAfterTomorrow,
    );
    final eventsWithoutSchedule = await _dataSource.eventsWithoutSchedule(
      rangeStart: today,
      rangeEndExclusive: dayAfterTomorrow,
    );

    final filters = _ref.read(calendarFiltersProvider);
    final listFilter = _ref.read(scheduleListFilterProvider).value ??
        EventScheduleListFilter.all;
    final stillActive = <String>{};

    for (final eventId in eventIds) {
      final customId = liveActivityCustomIdForEvent(eventId);
      final schedules = await _dataSource.schedulesForEvent(eventId);
      final snapshot = ScheduleLiveActivityResolver.resolve(
        eventId: eventId,
        schedules: schedules,
        listFilter: listFilter,
        filters: filters,
        now: now,
      );

      if (snapshot != null) {
        stillActive.add(customId);
        await _applySnapshotIfNeeded(snapshot);
        continue;
      }

      final finished = ScheduleLiveActivityResolver.isScheduleDayFinished(
        schedules: schedules,
        listFilter: listFilter,
        filters: filters,
        now: now,
      );
      if (finished && _activeCustomIds.contains(customId)) {
        await _service.end(customId);
      }
    }

    for (final event in eventsWithoutSchedule) {
      final customId = liveActivityCustomIdForEvent(event.id);
      if (listFilter == EventScheduleListFilter.mine &&
          !calendarEventMatchesUserProfile(event: event, filters: filters)) {
        continue;
      }

      final snapshot = ScheduleLiveActivityResolver.resolveFromEvent(
        event: event,
        filters: filters,
        now: now,
      );

      if (snapshot != null) {
        stillActive.add(customId);
        await _applySnapshotIfNeeded(snapshot);
        continue;
      }

      if (ScheduleLiveActivityResolver.isEventFinished(event: event, now: now) &&
          _activeCustomIds.contains(customId)) {
        await _service.end(customId);
      }
    }

    final ended = _activeCustomIds.difference(stillActive).toList();
    for (final customId in ended) {
      await _service.end(customId);
      _lastAppliedScheduleId.remove(customId);
      _lastContentFingerprint.remove(customId);
    }
    _activeCustomIds
      ..clear()
      ..addAll(stillActive);
  }

  Future<void> _activateForEvent(String eventId) async {
    if (_syncRunning) {
      _syncAgain = true;
      return;
    }

    final filters = _ref.read(calendarFiltersProvider);
    final listFilter = _ref.read(scheduleListFilterProvider).value ??
        EventScheduleListFilter.all;

    final schedules = await _dataSource.schedulesForEvent(eventId);
    ScheduleLiveActivitySnapshot? snapshot;
    if (schedules.isNotEmpty) {
      snapshot = ScheduleLiveActivityResolver.resolve(
        eventId: eventId,
        schedules: schedules,
        listFilter: listFilter,
        filters: filters,
      );
    } else {
      final event = await _dataSource.eventWithoutScheduleById(eventId);
      if (event != null) {
        if (listFilter == EventScheduleListFilter.mine &&
            !calendarEventMatchesUserProfile(event: event, filters: filters)) {
          return;
        }
        snapshot = ScheduleLiveActivityResolver.resolveFromEvent(
          event: event,
          filters: filters,
        );
      }
    }

    if (snapshot == null) return;
    await _applySnapshot(snapshot);
    _activeCustomIds.add(snapshot.customId);
    _lastAppliedScheduleId[snapshot.customId] = snapshot.currentScheduleId;
    _lastContentFingerprint[snapshot.customId] = snapshot.contentFingerprint;
  }

  Future<void> _endForEvent(String eventId, {String? customId}) async {
    final id = customId ?? liveActivityCustomIdForEvent(eventId);
    await _service.end(id);
    _activeCustomIds.remove(id);
    _lastAppliedScheduleId.remove(id);
    _lastContentFingerprint.remove(id);
  }

  Future<void> _applySnapshotIfNeeded(
    ScheduleLiveActivitySnapshot snapshot,
  ) async {
    final lastId = _lastAppliedScheduleId[snapshot.customId];
    final lastFingerprint = _lastContentFingerprint[snapshot.customId];
    if (_activeCustomIds.contains(snapshot.customId) &&
        lastId == snapshot.currentScheduleId &&
        lastFingerprint == snapshot.contentFingerprint) {
      return;
    }
    await _applySnapshot(snapshot);
    _lastAppliedScheduleId[snapshot.customId] = snapshot.currentScheduleId;
    _lastContentFingerprint[snapshot.customId] = snapshot.contentFingerprint;
  }

  Future<void> _applySnapshot(ScheduleLiveActivitySnapshot snapshot) async {
    final activitiesEnabled = await _service.areActivitiesEnabled();
    if (!activitiesEnabled) return;
    await _service.createOrUpdate(snapshot);
  }
}

final scheduleLiveActivityCoordinatorProvider =
    Provider<ScheduleLiveActivityCoordinator>((ref) {
  ref.keepAlive();
  return ScheduleLiveActivityCoordinator(
    dataSource: ScheduleLiveActivityDataSource(ref.watch(dbProvider)),
    service: ScheduleLiveActivityService(),
    repository: ScheduleLiveActivityRepository(),
    localScheduler: ScheduleLiveActivityLocalScheduler(),
    segmentTimerScheduler: ScheduleSegmentTimerScheduler(),
    ref: ref,
  );
});
