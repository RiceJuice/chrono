import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

/// Internet-Status für Router-Redirects (Login → No-Connection).
///
/// Nutzt [InternetConnectionChecker] v3: bei `ConnectivityResult.none` wird
/// **sofort** `disconnected` gemeldet; sonst periodische HTTP-Reachability-Checks
/// mit konfigurierbarem Intervall.
class ConnectivityNotifier extends ChangeNotifier {
  /// Live-Monitoring (Timer + Streams) — nicht in Widget-Tests verwenden.
  ConnectivityNotifier() {
    final checker = InternetConnectionChecker.createInstance(
      checkInterval: const Duration(seconds: 2),
      checkTimeout: const Duration(seconds: 2),
    );
    _checker = checker;
    _statusSub = checker.onStatusChange.listen(_onStatus);
    unawaited(_bootstrap());
  }

  /// Fest „online“, ohne Netzwerk/Timers (z. B. [WidgetTester]).
  ConnectivityNotifier.test()
      : _checker = null,
        _statusSub = null {
    _initialCheckComplete = true;
    _lastKnownOnline = true;
  }

  InternetConnectionChecker? _checker;
  StreamSubscription<InternetConnectionStatus>? _statusSub;

  bool _initialCheckComplete = false;
  bool _lastKnownOnline = true;

  /// `true`, wenn keine nutzbare Verbindung (nur [InternetConnectionStatus.disconnected]).
  ///
  /// Vor dem ersten Ergebnis: `false`, damit der Login nicht blockiert wird.
  bool get isOffline {
    if (!_initialCheckComplete) return false;
    return !_lastKnownOnline;
  }

  static bool _isOnlineStatus(InternetConnectionStatus status) =>
      status != InternetConnectionStatus.disconnected;

  void _onStatus(InternetConnectionStatus status) {
    _lastKnownOnline = _isOnlineStatus(status);
    _initialCheckComplete = true;
    notifyListeners();
  }

  static const Duration _bootstrapTimeout = Duration(seconds: 2);

  Future<void> _bootstrap() async {
    final checker = _checker;
    if (checker == null) return;
    try {
      final status = await checker.connectionStatus.timeout(
        _bootstrapTimeout,
        onTimeout: () => InternetConnectionStatus.disconnected,
      );
      _lastKnownOnline = _isOnlineStatus(status);
    } catch (_) {
      _lastKnownOnline = false;
    }
    _initialCheckComplete = true;
    notifyListeners();
  }

  /// Manuell erneut prüfen (z. B. „Erneut versuchen“ auf dem Offline-Screen).
  Future<void> recheck() async {
    final checker = _checker;
    if (checker == null) {
      notifyListeners();
      return;
    }
    try {
      _lastKnownOnline = await checker.hasConnection;
    } catch (_) {
      _lastKnownOnline = false;
    }
    _initialCheckComplete = true;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_statusSub?.cancel());
    _statusSub = null;
    _checker?.dispose();
    _checker = null;
    super.dispose();
  }
}
