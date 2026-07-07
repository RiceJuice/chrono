import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/database/powersync_schema.dart';
import '../../data/guardian_link_repository.dart';
import '../../domain/models/guardian_child_link.dart';
import '../../domain/models/profile_gate_data.dart';
import '../routes/login_flow_specs.dart';

/// Lädt Profil- und Auth-Status vom Backend und berechnet daraus den nächsten
/// Onboarding-Pfad. Triggert [GoRouter.refresh] via [ChangeNotifier], sobald
/// sich der Gate-Zustand ändert.
class ProfileGateNotifier extends ChangeNotifier {
  ProfileGateNotifier({
    SupabaseClient? client,
    PowerSyncDatabase? localDb,
    GuardianLinkRepository? guardianLinkRepository,
  })  : _client = client ?? Supabase.instance.client,
        _localDb = localDb,
        _guardianLinks = guardianLinkRepository {
    _authSub = _client.auth.onAuthStateChange.listen(_handleAuthEvent);
    _attachSyncListener();

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
  final GuardianLinkRepository? _guardianLinks;
  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<SyncStatus>? _syncSub;
  DateTime? _lastHandledSyncAt;
  bool _ready = false;
  Future<void>? _inFlightRefresh;
  ProfileGateData _data = const ProfileGateData.signedOut();

  bool get isReady => _ready;
  ProfileGateData get data => _data;

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
        if (_client.auth.currentSession != null && !_data.hasSession) {
          _ready = false;
          notifyListeners();
        }
        unawaited(refresh(remote: true));
      case AuthChangeEvent.tokenRefreshed:
        unawaited(refresh(remote: false));
      case AuthChangeEvent.initialSession:
        if (_client.auth.currentSession != null && !_data.hasSession) {
          _ready = false;
          notifyListeners();
        }
        unawaited(refresh(remote: true));
      case AuthChangeEvent.signedOut:
        _data = const ProfileGateData.signedOut();
        _ready = true;
        notifyListeners();
      default:
        break;
    }
  }

  /// [remote]: Supabase-Abfrage nur bei Auth/Profil-Schreibvorgängen nötig.
  /// Nach PowerSync-Download reicht die lokale SQLite-Kopie.
  Future<void> refresh({bool remote = true}) {
    return _inFlightRefresh ??= _runRefresh(remote: remote).whenComplete(() {
      _inFlightRefresh = null;
    });
  }

  void _attachSyncListener() {
    final db = _localDb;
    if (db == null) return;

    _syncSub = db.statusStream.listen((status) {
      if (_client.auth.currentSession == null) return;
      final syncedAt = status.lastSyncedAt;
      if (syncedAt == null || syncedAt == _lastHandledSyncAt) return;
      _lastHandledSyncAt = syncedAt;
      unawaited(refresh(remote: false));
    });
  }

  Future<void> _bootstrapWithSession() async {
    final user = _client.auth.currentUser;
    if (user != null) {
      final localRow = await _loadLocalProfileRow(user.id);
      if (localRow != null) {
        final linkSummary = await _loadGuardianLinkSummary(user.id);
        _setData(_profileDataFromRow(user, localRow, linkSummary));
      }
    }
    await refresh();
  }

  Future<void> _runRefresh({required bool remote}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      _setData(const ProfileGateData.signedOut());
      return;
    }

    final localFuture = _loadLocalProfileRow(user.id);
    Map<String, dynamic>? row;
    if (remote) {
      try {
        row = await _fetchRemoteProfileRow(user.id)
            .timeout(_remoteProfileTimeout);
      } catch (_) {
        row = null;
      }
    }

    row ??= await localFuture;
    final linkSummary = remote
        ? await _loadGuardianLinkSummary(user.id)
        : await _loadGuardianLinkSummaryLocal(user.id);

    _setData(_profileDataFromRow(user, row, linkSummary));
  }

  Future<Map<String, dynamic>?> _fetchRemoteProfileRow(String userId) async {
    return _client
        .from('profiles')
        .select(
          'first_name, last_name, class_name, schooltrack, voice, role, choir, diet, '
          'onboarding_completed_at, active_child_id',
        )
        .eq('id', userId)
        .maybeSingle();
  }

  Future<GuardianLinkSummary> _loadGuardianLinkSummary(String userId) async {
    final repo = _guardianLinks;
    if (repo == null) {
      return _loadGuardianLinkSummaryLocal(userId);
    }
    try {
      return await repo.loadSummaryForGuardian(userId);
    } catch (_) {
      return _loadGuardianLinkSummaryLocal(userId);
    }
  }

  Future<GuardianLinkSummary> _loadGuardianLinkSummaryLocal(
    String userId,
  ) async {
    final db = _localDb;
    if (db == null) {
      return const GuardianLinkSummary(
        confirmedLinks: [],
        pendingLinks: [],
      );
    }
    try {
      final rows = await db.getAll(
        '''
        SELECT id, guardian_id, child_id, status
        FROM $kGuardianChildLinksTable
        WHERE guardian_id = ?
        ''',
        [userId],
      );
      final links = rows
          .map((row) => GuardianChildLink.fromRow(
                Map<String, dynamic>.from(row),
              ))
          .toList(growable: false);
      return GuardianLinkSummary(
        confirmedLinks:
            links.where((l) => l.isConfirmed).toList(growable: false),
        pendingLinks:
            links.where((l) => l.isPending).toList(growable: false),
      );
    } catch (_) {
      return const GuardianLinkSummary(
        confirmedLinks: [],
        pendingLinks: [],
      );
    }
  }

  ProfileGateData _profileDataFromRow(
    User user,
    Map<String, dynamic>? row,
    GuardianLinkSummary linkSummary,
  ) {
    final role = _asString(row?['role']);

    return ProfileGateData(
      hasSession: true,
      emailConfirmed: user.emailConfirmedAt != null,
      firstName: _asString(row?['first_name']),
      lastName: _asString(row?['last_name']),
      className: _asString(row?['class_name']),
      schoolTrack: _asString(row?['schooltrack']),
      role: role,
      voice: _asString(row?['voice']),
      choir: _asString(row?['choir']),
      diet: _asString(row?['diet']),
      onboardingCompletedAt: _asDateTime(row?['onboarding_completed_at']),
      activeChildId: _asString(row?['active_child_id']),
      hasAnyGuardianLink: linkSummary.hasAnyLink,
      hasConfirmedGuardianLink: linkSummary.hasConfirmedLink,
      hasPendingGuardianLink: linkSummary.hasPendingLink,
    );
  }

  Future<Map<String, dynamic>?> _loadLocalProfileRow(String userId) async {
    final db = _localDb;
    if (db == null) return null;
    try {
      final sqliteRow = await db.getOptional(
        '''
        SELECT first_name, last_name, class_name, schooltrack, voice, role, choir, diet,
               onboarding_completed_at, active_child_id
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
    unawaited(_syncSub?.cancel());
    _authSub = null;
    _syncSub = null;
    super.dispose();
  }
}
