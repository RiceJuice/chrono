import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../login/presentation/providers/profile_gate_notifier.dart';
import '../presentation/schedule_live_activity_coordinator.dart';

/// Startet Live-Activity-Coordinator nach Login/Profil-Gate.
class ScheduleLiveActivityBootstrap {
  ScheduleLiveActivityBootstrap({
    required ProfileGateNotifier profileGate,
    required WidgetRef ref,
  })  : _profileGate = profileGate,
        _ref = ref {
    _profileGate.addListener(_onProfileGateChanged);
    _onProfileGateChanged();
  }

  final ProfileGateNotifier _profileGate;
  final WidgetRef _ref;
  static ScheduleLiveActivityBootstrap? _instance;

  static void start({
    required ProfileGateNotifier profileGate,
    required WidgetRef ref,
  }) {
    _instance?.dispose();
    _instance = ScheduleLiveActivityBootstrap(
      profileGate: profileGate,
      ref: ref,
    );
  }

  static void disposeInstance() {
    _instance?.dispose();
    _instance = null;
  }

  void _onProfileGateChanged() {
    if (!_profileGate.isReady) return;
    if (!_profileGate.data.hasSession) return;
    unawaited(_startCoordinator());
  }

  Future<void> _startCoordinator() async {
    try {
      final coordinator = _ref.read(scheduleLiveActivityCoordinatorProvider);
      ScheduleLiveActivityCoordinator.instance = coordinator;
      await coordinator.start();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[LiveActivity] bootstrap failed: $e\n$st');
      }
    }
  }

  void dispose() {
    _profileGate.removeListener(_onProfileGateChanged);
  }
}
