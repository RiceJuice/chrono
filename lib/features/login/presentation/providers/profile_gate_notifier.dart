import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/database/powersync_schema.dart';
import '../../domain/models/profile_gate_data.dart';
import '../routes/login_flow_specs.dart';

/// Lädt Profil- und Auth-Status vom Backend und berechnet daraus den nächsten
/// Onboarding-Pfad. Triggert [GoRouter.refresh] via [ChangeNotifier], sobald
/// sich der Gate-Zustand ändert.
class ProfileGateNotifier extends ChangeNotifier {
  ProfileGateNotifier({
    SupabaseClient? client,
    PowerSyncDatabase? localDb,
  })  : _client = client ?? Supabase.instance.client,
        _localDb = localDb {
    _authSub = _client.auth.onAuthStateChange.listen(_handleAuthEvent);

    if (_client.auth.currentSession == null) {
      _data = const ProfileGateData.signedOut();
      _ready = true;
    } else {
      unawaited(_bootstrapWithSession());
    }
  }

  static const Duration _remoteProfileTimeout = Duration(seconds: 2);

  final SupabaseClient _client;
  final PowerSyncDatabase? _localDb;
  StreamSubscription<AuthState>? _authSub;
  bool _ready = false;
  bool _refreshing = false;
  ProfileGateData _data = const ProfileGateData.signedOut();

  bool get isReady => _ready;
  ProfileGateData get data => _data;

  /// Wartet bis Gate-Daten verfügbar sind (z. B. vor Verlassen des Ladescreens).
  Future<void> waitUntilReady({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (_ready) return;
    final deadline = DateTime.now().add(timeout);
    while (!_ready && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  }
  String? get requiredPath => resolveRequiredOnboardingPath(_data);
  bool get isOnboardingComplete => _data.isOnboardingComplete;

  void _handleAuthEvent(AuthState event) {
    switch (event.event) {
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.userUpdated:
      case AuthChangeEvent.tokenRefreshed:
      case AuthChangeEvent.initialSession:
        // Synchron: Router darf nicht kurz mit altem signedOut + neuer Session
        // laufen (siehe AppRouter-Redirect), bevor `_refresh()` Daten geladen hat.
        if (_client.auth.currentSession != null && !_data.hasSession) {
          _ready = false;
          notifyListeners();
        }
        unawaited(_refresh());
      case AuthChangeEvent.signedOut:
        _data = const ProfileGateData.signedOut();
        _ready = true;
        notifyListeners();
      default:
        break;
    }
  }

  /// Erzwingt einen Refresh des Gate-Zustands, z. B. nach einem erfolgreichen
  /// `updateProfile`. Doppelte Aufrufe werden zusammengefasst.
  Future<void> refresh() => _refresh();

  /// Lokales Profil sofort laden, damit Offline-Start nicht aufs Netz wartet.
  Future<void> _bootstrapWithSession() async {
    final user = _client.auth.currentUser;
    if (user != null) {
      final localRow = await _loadLocalProfileRow(user.id);
      if (localRow != null) {
        _setData(_profileDataFromRow(user, localRow));
      }
    }
    await _refresh();
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        _setData(const ProfileGateData.signedOut());
        return;
      }

      final localFuture = _loadLocalProfileRow(user.id);
      Map<String, dynamic>? row;
      try {
        row = await _fetchRemoteProfileRow(user.id)
            .timeout(_remoteProfileTimeout);
      } catch (_) {
        row = null;
      }

      row ??= await localFuture;

      _setData(_profileDataFromRow(user, row));
    } finally {
      _refreshing = false;
    }
  }

  Future<Map<String, dynamic>?> _fetchRemoteProfileRow(String userId) async {
    return _client
        .from('profiles')
        .select(
          'first_name, last_name, class_name, schooltrack, voice, role, choir, '
          'onboarding_completed_at',
        )
        .eq('id', userId)
        .maybeSingle();
  }

  ProfileGateData _profileDataFromRow(
    User user,
    Map<String, dynamic>? row,
  ) {
    return ProfileGateData(
      hasSession: true,
      emailConfirmed: user.emailConfirmedAt != null,
      firstName: _asString(row?['first_name']),
      lastName: _asString(row?['last_name']),
      className: _asString(row?['class_name']),
      schoolTrack: _asString(row?['schooltrack']),
      role: _asString(row?['role']),
      voice: _asString(row?['voice']),
      choir: _asString(row?['choir']),
      onboardingCompletedAt: _asDateTime(row?['onboarding_completed_at']),
    );
  }

  Future<Map<String, dynamic>?> _loadLocalProfileRow(String userId) async {
    final db = _localDb;
    if (db == null) return null;
    try {
      final sqliteRow = await db.getOptional(
        '''
        SELECT first_name, last_name, class_name, schooltrack, voice, role, choir,
               onboarding_completed_at
        FROM $kProfilesTable
        WHERE id = ?
        LIMIT 1
        ''',
        [userId],
      );
      if (sqliteRow == null) return null;
      return Map<String, dynamic>.from(sqliteRow);
    } catch (_) {
      return null;
    }
  }

  void _setData(ProfileGateData data) {
    _data = data;
    _ready = true;
    notifyListeners();
  }

  static String? _asString(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static DateTime? _asDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  @override
  void dispose() {
    unawaited(_authSub?.cancel());
    _authSub = null;
    super.dispose();
  }
}
