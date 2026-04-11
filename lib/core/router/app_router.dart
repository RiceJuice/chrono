import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/calendar/presentation/pages/calendar_page.dart';
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
  })  : _startup = startupNotifier,
        _refresh = Listenable.merge([startupNotifier, authSessionNotifier]);

  final AppStartupNotifier _startup;
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

      if (loggedIn) {
        if (isLoadingRoute) return '/calendar';
        if (loc.startsWith(LoginPaths.login) && !_isAllowedOnboardingPath(loc)) {
          return '/calendar';
        }
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

  bool _isAllowedOnboardingPath(String location) {
    const allowed = <String>{
      LoginPaths.login,
      LoginPaths.credentials,
      LoginPaths.role,
      LoginPaths.personalData,
      LoginPaths.choir,
      LoginPaths.emailConfirmation,
    };
    return allowed.contains(location);
  }
}

class AppStartupNotifier extends ChangeNotifier {
  bool isReady = false;

  void setReady() {
    isReady = true;
    notifyListeners();
  }
}
