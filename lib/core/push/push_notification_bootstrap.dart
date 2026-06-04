import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../firebase_options.dart';
import '../auth/profile_role_ids.dart';
import '../../features/login/domain/models/profile_gate_data.dart';
import '../../features/login/presentation/providers/profile_gate_notifier.dart';
import 'push_notification_service.dart';

/// Startet FCM-Sync für Admins nach Login; stoppt beim Logout.
class PushNotificationBootstrap {
  PushNotificationBootstrap({
    required ProfileGateNotifier profileGate,
    PushNotificationService? pushService,
    SupabaseClient? supabase,
  })  : _profileGate = profileGate,
        _pushService = pushService ?? PushNotificationService(),
        _supabase = supabase ?? Supabase.instance.client {
    _profileGate.addListener(_onProfileGateChanged);
    _authSub = _supabase.auth.onAuthStateChange.listen(_onAuthStateChanged);
    _onProfileGateChanged();
  }

  final ProfileGateNotifier _profileGate;
  final PushNotificationService _pushService;
  final SupabaseClient _supabase;
  StreamSubscription<AuthState>? _authSub;
  bool _syncInFlight = false;

  static PushNotificationBootstrap? _instance;

  static void start({required ProfileGateNotifier profileGate}) {
    if (!DefaultFirebaseOptions.isConfigured) {
      if (kDebugMode) {
        debugPrint(
          '[FCM] skipped: run flutterfire configure (see backend/PUSH_NOTIFICATIONS.md)',
        );
      }
      return;
    }
    if (!PushNotificationService.supportsPush) return;
    _instance?.dispose();
    _instance = PushNotificationBootstrap(profileGate: profileGate);
  }

  static Future<void> disposeInstance() async {
    await _instance?.dispose();
    _instance = null;
  }

  void _onAuthStateChanged(AuthState state) {
    if (state.event == AuthChangeEvent.signedOut) {
      unawaited(_pushService.clearTokenOnLogout());
    }
  }

  void _onProfileGateChanged() {
    if (!_profileGate.isReady) return;
    final data = _profileGate.data;
    if (!data.hasSession) return;
    if (!_isAdmin(data)) return;
    unawaited(_syncIfNeeded());
  }

  bool _isAdmin(ProfileGateData data) =>
      data.role?.trim() == ProfileRoleIds.admin;

  Future<void> _syncIfNeeded() async {
    if (_syncInFlight) return;
    if (_supabase.auth.currentSession == null) return;
    _syncInFlight = true;
    try {
      await _pushService.syncTokenForCurrentUser();
    } finally {
      _syncInFlight = false;
    }
  }

  Future<void> dispose() async {
    _profileGate.removeListener(_onProfileGateChanged);
    await _authSub?.cancel();
    _authSub = null;
  }
}
