import 'dart:async';

import 'package:chronoapp/core/database/database_provider.dart';
import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/live_activity/data/schedule_live_activity_data_source.dart';
import 'package:chronoapp/features/calendar/live_activity/data/schedule_live_activity_local_scheduler.dart';
import 'package:chronoapp/features/calendar/live_activity/data/schedule_live_activity_repository.dart';
import 'package:chronoapp/features/calendar/live_activity/data/schedule_live_activity_service.dart';
import 'package:chronoapp/features/calendar/live_activity/domain/schedule_live_activity_resolver.dart';
import 'package:chronoapp/features/calendar/live_activity/domain/schedule_live_activity_snapshot.dart';
import 'package:chronoapp/features/calendar/domain/filter/event_schedule_filter.dart';
import 'package:chronoapp/features/calendar/live_activity/presentation/schedule_list_filter_provider.dart';
import 'package:chronoapp/features/calendar/presentation/providers/filter/calendar/calendar_filters_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Steuert Start/Update/Ende der Live Activities aus lokaler DB + Timer.
class ScheduleLiveActivityCoordinator {
  ScheduleLiveActivityCoordinator({
    required ScheduleLiveActivityDataSource dataSource,
    required ScheduleLiveActivityService service,
    required ScheduleLiveActivityRepository repository,
    required ScheduleLiveActivityLocalScheduler localScheduler,
    required Ref ref,
  })  : _dataSource = dataSource,
        _service = service,
        _repository = repository,
        _localScheduler = localScheduler,
        _ref = ref;

  final ScheduleLiveActivityDataSource _dataSource;
  final ScheduleLiveActivityService _service;
  final ScheduleLiveActivityRepository _repository;
  final ScheduleLiveActivityLocalScheduler _localScheduler;
  final Ref _ref;

  final Set<String> _activeCustomIds = {};
  Timer? _tickTimer;
  StreamSubscription<void>? _dbSub;
  bool _running = false;

  static ScheduleLiveActivityCoordinator? instance;

  Future<void> start() async {
    if (_running) return;
    final enabled = await _service.init();
    if (!enabled) return;

    _service.onLiveActivityPushToken = (token) {
      unawaited(_repository.syncLiveActivityPushToken(token));
    };
    _service.onPushToStartToken = (token) {
      unawaited(_repository.syncPushToStartToken(token));
    };

    await _localScheduler.init(
      onPayload: handleLocalNotificationPayload,
    );
    _running = true;

    _dbSub = _dataSource.watchScheduleChanges().listen((_) {
      unawaited(_refresh());
    });

    _tickTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(_syncActiveActivities());
    });

    unawaited(_refresh());
  }

  Future<void> dispose() async {
    _running = false;
    await _dbSub?.cancel();
    _tickTimer?.cancel();
    _dbSub = null;
    _tickTimer = null;
    await _service.dispose();
  }

  Future<void> handleLocalNotificationPayload(String payload) async {
    final parts = payload.split('|');
    if (parts.length != 2) return;
    await _activateForEvent(parts[0]);
  }

  Future<void> handleFcmData(Map<String, String> data) async {
    final type = data['type'];
    if (type != 'schedule_live_activity') return;

    final event = data['event'] ?? 'update';
    final eventId = data['event_id'];
    if (eventId == null || eventId.isEmpty) return;

    if (event == 'end') {
      final customId = data['activity_id'];
      if (customId != null) {
        await _service.end(customId);
        _activeCustomIds.remove(customId);
      }
      return;
    }

    await _activateForEvent(eventId);
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
    await _localScheduler.rescheduleSegments(segments: segments);
    await _syncActiveActivities();
  }

  Future<void> _syncActiveActivities() async {
    if (!_running) return;

    final now = DateTime.now();
    final today = AppDateTime.localDay(now);
    final dayAfterTomorrow = AppDateTime.addLocalCalendarDays(today, 2);

    final eventIds = await _dataSource.eventIdsWithSchedulesOnDays(
      dayStart: today,
      dayEndExclusive: dayAfterTomorrow,
    );

    final filters = _ref.read(calendarFiltersProvider);
    final listFilter = _ref.read(scheduleListFilterProvider).value ??
        EventScheduleListFilter.all;
    final stillActive = <String>{};

    for (final eventId in eventIds) {
      final schedules = await _dataSource.schedulesForEvent(eventId);
      final snapshot = ScheduleLiveActivityResolver.resolve(
        eventId: eventId,
        schedules: schedules,
        listFilter: listFilter,
        filters: filters,
        now: now,
      );

      if (snapshot != null) {
        stillActive.add(snapshot.customId);
        await _applySnapshot(snapshot);
        continue;
      }

      final finished = ScheduleLiveActivityResolver.isScheduleDayFinished(
        schedules: schedules,
        listFilter: listFilter,
        filters: filters,
        now: now,
      );
      if (finished) {
        final customId = 'event_$eventId';
        if (_activeCustomIds.contains(customId)) {
          await _service.end(customId);
        }
      }
    }

    final ended = _activeCustomIds.difference(stillActive).toList();
    for (final customId in ended) {
      await _service.end(customId);
    }
    _activeCustomIds
      ..clear()
      ..addAll(stillActive);
  }

  Future<void> _activateForEvent(String eventId) async {
    final schedules = await _dataSource.schedulesForEvent(eventId);
    final filters = _ref.read(calendarFiltersProvider);
    final listFilter = _ref.read(scheduleListFilterProvider).value ??
        EventScheduleListFilter.all;
    final snapshot = ScheduleLiveActivityResolver.resolve(
      eventId: eventId,
      schedules: schedules,
      listFilter: listFilter,
      filters: filters,
    );
    if (snapshot == null) return;
    await _applySnapshot(snapshot);
    _activeCustomIds.add(snapshot.customId);
  }

  Future<void> _applySnapshot(ScheduleLiveActivitySnapshot snapshot) async {
    final activitiesEnabled = await _service.areActivitiesEnabled();
    if (!activitiesEnabled) return;
    await _service.createOrUpdate(snapshot);
  }
}

final scheduleLiveActivityCoordinatorProvider =
    Provider<ScheduleLiveActivityCoordinator>((ref) {
  final coordinator = ScheduleLiveActivityCoordinator(
    dataSource: ScheduleLiveActivityDataSource(ref.watch(dbProvider)),
    service: ScheduleLiveActivityService(),
    repository: ScheduleLiveActivityRepository(),
    localScheduler: ScheduleLiveActivityLocalScheduler(),
    ref: ref,
  );
  ref.onDispose(() {
    unawaited(coordinator.dispose());
  });
  return coordinator;
});
