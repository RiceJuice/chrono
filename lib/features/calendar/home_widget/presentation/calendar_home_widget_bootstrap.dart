import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../login/presentation/providers/profile_gate_notifier.dart';
import 'calendar_home_widget_coordinator.dart';

/// Startet den Homescreen-Widget-Coordinator nach Login/Profil-Gate.
class CalendarHomeWidgetBootstrap with WidgetsBindingObserver {
  CalendarHomeWidgetBootstrap({
    required ProfileGateNotifier profileGate,
    required WidgetRef ref,
  })  : _profileGate = profileGate,
        _ref = ref {
    WidgetsBinding.instance.addObserver(this);
    _profileGate.addListener(_onProfileGateChanged);
    _onProfileGateChanged();
  }

  final ProfileGateNotifier _profileGate;
  final WidgetRef _ref;
  CalendarHomeWidgetCoordinator? _coordinator;
  static CalendarHomeWidgetBootstrap? _instance;

  static void start({
    required ProfileGateNotifier profileGate,
    required WidgetRef ref,
  }) {
    _instance?.dispose();
    _instance = CalendarHomeWidgetBootstrap(
      profileGate: profileGate,
      ref: ref,
    );
  }

  static void disposeInstance() {
    final instance = _instance;
    _instance = null;
    unawaited(instance?._coordinator?.dispose());
    instance?.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_ensureCoordinator());
    }
  }

  @override
  void didChangePlatformBrightness() {
    unawaited(_ensureCoordinator());
  }

  void _onProfileGateChanged() {
    if (!_profileGate.isReady) return;
    if (!_profileGate.data.hasSession) return;
    unawaited(_ensureCoordinator());
  }

  Future<void> _ensureCoordinator() async {
    if (!_profileGate.isReady || !_profileGate.data.hasSession) return;

    try {
      final coordinator = _ref.read(calendarHomeWidgetCoordinatorProvider);
      _coordinator = coordinator;
      if (!coordinator.isRunning) {
        await coordinator.start();
        return;
      }
      await coordinator.refreshNow();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[HomeWidget] bootstrap failed: $e\n$st');
      }
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _profileGate.removeListener(_onProfileGateChanged);
  }
}
