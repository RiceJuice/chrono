import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../login/presentation/providers/profile_gate_notifier.dart';
import 'schedule_live_activity_coordinator.dart';
import 'schedule_live_activity_deep_link_handler.dart';
import '../../timetable_live_activity/presentation/timetable_live_activity_coordinator.dart';

/// Startet Live-Activity-Coordinator nach Login/Profil-Gate.
class ScheduleLiveActivityBootstrap with WidgetsBindingObserver {
  ScheduleLiveActivityBootstrap({
    required ProfileGateNotifier profileGate,
    required WidgetRef ref,
    required GoRouter router,
  })  : _profileGate = profileGate,
        _ref = ref,
        _router = router {
    WidgetsBinding.instance.addObserver(this);
    _profileGate.addListener(_onProfileGateChanged);
    _onProfileGateChanged();
  }

  final ProfileGateNotifier _profileGate;
  final WidgetRef _ref;
  final GoRouter _router;
  ScheduleLiveActivityDeepLinkHandler? _deepLinkHandler;
  ScheduleLiveActivityCoordinator? _coordinator;
  TimetableLiveActivityCoordinator? _timetableCoordinator;
  static ScheduleLiveActivityBootstrap? _instance;

  static void start({
    required ProfileGateNotifier profileGate,
    required WidgetRef ref,
    required GoRouter router,
  }) {
    _instance?.dispose();
    _instance = ScheduleLiveActivityBootstrap(
      profileGate: profileGate,
      ref: ref,
      router: router,
    );
    unawaited(_instance!._startDeepLinkHandler());
  }

  static void disposeInstance() {
    final instance = _instance;
    _instance = null;
    unawaited(instance?._deepLinkHandler?.dispose());
    unawaited(instance?._coordinator?.dispose());
    unawaited(instance?._timetableCoordinator?.dispose());
    instance?.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_ensureCoordinator());
    }
  }

  Future<void> _startDeepLinkHandler() async {
    _deepLinkHandler ??= ScheduleLiveActivityDeepLinkHandler(
      router: _router,
      ref: _ref,
    );
    await _deepLinkHandler!.start();
  }

  void _onProfileGateChanged() {
    if (!_profileGate.isReady) return;
    if (!_profileGate.data.hasSession) return;
    unawaited(_ensureCoordinator());
  }

  Future<void> _ensureCoordinator() async {
    if (!_profileGate.isReady || !_profileGate.data.hasSession) return;

    try {
      final coordinator = _ref.read(scheduleLiveActivityCoordinatorProvider);
      _coordinator = coordinator;
      ScheduleLiveActivityCoordinator.instance = coordinator;

      final timetableCoordinator =
          _ref.read(timetableLiveActivityCoordinatorProvider);
      _timetableCoordinator = timetableCoordinator;
      TimetableLiveActivityCoordinator.instance = timetableCoordinator;

      if (!coordinator.isRunning) {
        await coordinator.start(
          onUrlScheme: _deepLinkHandler?.handleUrlSchemeData,
        );
      } else {
        await coordinator.refreshNow();
      }

      if (!timetableCoordinator.isRunning) {
        await timetableCoordinator.start();
      } else {
        await timetableCoordinator.refreshNow();
      }
      return;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[LiveActivity] bootstrap failed: $e\n$st');
      }
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _profileGate.removeListener(_onProfileGateChanged);
    unawaited(_deepLinkHandler?.dispose());
    _deepLinkHandler = null;
  }
}
