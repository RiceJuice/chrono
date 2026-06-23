import 'dart:async';

import 'package:chronoapp/core/database/powersync_schema.dart';
import 'package:chronoapp/core/database/database_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart';

import '../../domain/filter/calendar_filters_state.dart';
import '../../presentation/providers/filter/calendar/calendar_filters_provider.dart';
import '../data/calendar_home_widget_service.dart';

/// Aktualisiert das Homescreen-Widget bei DB-, Filter- und Theme-Änderungen.
class CalendarHomeWidgetCoordinator {
  CalendarHomeWidgetCoordinator({
    required CalendarHomeWidgetService service,
    required PowerSyncDatabase db,
    required Ref ref,
  })  : _service = service,
        _db = db,
        _ref = ref;

  final CalendarHomeWidgetService _service;
  final PowerSyncDatabase _db;
  final Ref _ref;

  StreamSubscription<void>? _dbSub;
  ProviderSubscription<CalendarFiltersState>? _filtersSub;
  Timer? _midnightTimer;
  bool _running = false;
  bool _refreshRunning = false;
  bool _refreshAgain = false;

  bool get isRunning => _running;

  Future<void> start() async {
    if (_running) return;
    _running = true;

    _dbSub = _db
        .watch(
          'SELECT id FROM $kCalendarEventsTable LIMIT 1',
          triggerOnTables: const {
            kCalendarEventsTable,
            kCalendarSeriesTable,
          },
        )
        .listen((_) {
          unawaited(refreshNow());
        });

    _filtersSub = _ref.listen<CalendarFiltersState>(
      calendarFiltersProvider,
      (_, _) => unawaited(refreshNow()),
    );

    _scheduleMidnightRefresh();
    await refreshNow();
  }

  Future<void> dispose() async {
    _running = false;
    await _dbSub?.cancel();
    _dbSub = null;
    _filtersSub?.close();
    _filtersSub = null;
    _midnightTimer?.cancel();
    _midnightTimer = null;
  }

  Future<void> refreshNow() async {
    if (!_running) return;
    if (_refreshRunning) {
      _refreshAgain = true;
      return;
    }
    _refreshRunning = true;
    try {
      do {
        _refreshAgain = false;
        await _render();
      } while (_refreshAgain);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[HomeWidget] refresh failed: $e\n$st');
      }
    } finally {
      _refreshRunning = false;
    }
  }

  Future<void> _render() async {
    final targets = await _service.resolveRenderTargets();

    await _service.renderAndUpdate(
      container: _ref.container,
      targets: targets,
    );
  }

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final delay = tomorrow.difference(now) + const Duration(seconds: 5);
    _midnightTimer = Timer(delay, () {
      unawaited(refreshNow());
      _scheduleMidnightRefresh();
    });
  }
}

final calendarHomeWidgetCoordinatorProvider =
    Provider<CalendarHomeWidgetCoordinator>((ref) {
      return CalendarHomeWidgetCoordinator(
        service: ref.watch(calendarHomeWidgetServiceProvider),
        db: ref.watch(dbProvider),
        ref: ref,
      );
    });
