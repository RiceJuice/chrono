import 'dart:async';

import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend_connector.dart';
import 'powersync_config.dart';

/// Verbindet PowerSync mit dem Supabase-Auth-Lebenszyklus (Demo-Pattern).
class PowerSyncAuthBinding {
  PowerSyncAuthBinding._();

  static StreamSubscription<AuthState>? _authSub;
  static BackendConnector? _connector;

  static const Duration _connectTimeout = Duration(seconds: 8);

  static Future<void> start(PowerSyncDatabase db) async {
    if (!isPowerSyncSyncEnabled()) return;

    await _authSub?.cancel();
    final client = Supabase.instance.client;

    Future<void> connectIfNeeded() async {
      if (client.auth.currentSession == null) return;
      if (db.connected) await db.disconnect();
      _connector = BackendConnector(supabase: client);
      await db.connect(connector: _connector!);
    }

    _authSub = client.auth.onAuthStateChange.listen((data) async {
      switch (data.event) {
        case AuthChangeEvent.signedIn:
          await _connectSafely(connectIfNeeded);
        case AuthChangeEvent.signedOut:
          _connector = null;
          await db.disconnect();
        case AuthChangeEvent.tokenRefreshed:
          _connector?.prefetchCredentials();
        default:
          break;
      }
    });

    await _connectSafely(connectIfNeeded);
  }

  static Future<void> _connectSafely(Future<void> Function() connect) async {
    try {
      await connect().timeout(_connectTimeout);
    } catch (_) {
      // Offline oder langsames Netz: Sync verbindet sich beim nächsten Versuch.
    }
  }

  static Future<void> dispose() async {
    await _authSub?.cancel();
    _authSub = null;
    _connector = null;
  }
}
