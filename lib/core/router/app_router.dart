import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/calendar/presentation/pages/calendar_page.dart';
import '../../features/login/presentation/providers/profile_gate_notifier.dart';
import '../../features/login/presentation/routes/login_flow_specs.dart';
import '../../features/login/presentation/routes/login_routes.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../loading_page.dart';

/// Löst [GoRouter.refresh] bei Auth-Änderungen aus.
class AuthSessionNotifier extends ChangeNotifier {
  AuthSessionNotifier() {
    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

class AppRouter {
  AppRouter({
    required AppStartupNotifier startupNotifier,
    required AuthSessionNotifier authSessionNotifier,
    required ProfileGateNotifier profileGateNotifier,
  })  : _startup = startupNotifier,
        _gate = profileGateNotifier,
        _refresh = Listenable.merge([
          startupNotifier,
          authSessionNotifier,
          profileGateNotifier,
        ]);

  final AppStartupNotifier _startup;
  final ProfileGateNotifier _gate;
  final Listenable _refresh;

  late final router = GoRouter(
    refreshListenable: _refresh,
    initialLocation: '/loading',
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isLoadingRoute = loc == '/loading';
      final session = Supabase.instance.client.auth.currentSession;
      final loggedIn = session != null;

      if (!_startup.isReady) {
        if (!isLoadingRoute) return '/loading';
        return null;
      }

      if (!loggedIn) {
        if (isLoadingRoute) {
          LoginRouteTransitionTracker.reset();
          return LoginPaths.login;
        }
        if (loc == '/calendar' || loc == '/settings') {
          LoginRouteTransitionTracker.reset();
          return LoginPaths.login;
        }
        return null;
      }

      // Session vorhanden – warten, bis das Profil-Gate eine Entscheidung
      // treffen kann, damit kein kurzer Redirect nach /calendar flackert.
      //
      // Wichtig: Nach Sign-In kann `_gate.isReady` noch true sein (vom vorherigen
      // signedOut-Zustand), während `_data.hasSession` noch false ist, bis
      // `_refresh()` fertig ist. Ohne diese Zeile liefert `requiredPath` dann
      // fälschlich null → kurzer Sprung auf /calendar (sicherheitsrelevant).
      final gateData = _gate.data;
      if (!_gate.isReady || !gateData.hasSession) {
        return isLoadingRoute ? null : '/loading';
      }

      final requiredPath = _gate.requiredPath;

      if (requiredPath == null) {
        if (isLoadingRoute) return '/calendar';
        if (loc.startsWith(LoginPaths.login)) return '/calendar';
        return null;
      }

      // Onboarding noch offen: geschützte App-Bereiche und /loading auf den
      // richtigen Schritt umleiten. Vorherige Schritte bleiben erreichbar
      // (z. B. zum Korrigieren), überspringen per Deep-Link wird verhindert.
      if (isLoadingRoute || loc == '/calendar' || loc == '/settings') {
        return requiredPath;
      }

      if (loc.startsWith(LoginPaths.login)) {
        if (!onboardingLoginPaths.contains(loc)) {
          return requiredPath;
        }
        final currentIdx = loginFlowOrderIndex(loc);
        final requiredIdx = loginFlowOrderIndex(requiredPath);
        if (currentIdx >= 0 &&
            requiredIdx >= 0 &&
            currentIdx > requiredIdx) {
          return requiredPath;
        }
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(path: '/loading', builder: (context, state) => const LoadingPage()),
      GoRoute(
        path: '/calendar',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const CalendarPage(),
        ),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const SettingsPage(),
        ),
      ),
      ...loginRoutes,
    ],
  );
}

class AppStartupNotifier extends ChangeNotifier {
  bool isReady = false;

  void setReady() {
    isReady = true;
    notifyListeners();
  }
}
