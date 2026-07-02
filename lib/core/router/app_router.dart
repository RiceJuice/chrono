import 'dart:async';

import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/calendar/home_widget/domain/calendar_home_widget_constants.dart';
import '../../features/calendar/live_activity/live_activity_constants.dart';
import '../../features/calendar/live_activity/presentation/schedule_live_activity_deep_link_pending.dart';
import '../../features/calendar/timetable_live_activity/timetable_live_activity_constants.dart';
import '../../features/calendar/presentation/pages/calendar_page.dart';
import '../../features/login/presentation/providers/profile_gate_notifier.dart';
import '../../features/login/presentation/routes/login_flow_specs.dart';
import '../../features/login/presentation/routes/login_routes.dart';
import '../../features/homework/presentation/pages/homework_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../loading_page.dart';
import '../network/connectivity_notifier.dart';
import '../network/no_connection_page.dart';
import '../widgets/main_shell_scaffold.dart';

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

const String kNoConnectionPath = '/no-connection';

final rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  AppRouter({
    required AppStartupNotifier startupNotifier,
    required AuthSessionNotifier authSessionNotifier,
    required ProfileGateNotifier profileGateNotifier,
    required ConnectivityNotifier connectivityNotifier,
    GlobalKey<NavigatorState>? navigatorKey,
  })  : _startup = startupNotifier,
        _gate = profileGateNotifier,
        _connectivity = connectivityNotifier,
        _navigatorKey = navigatorKey ?? rootNavigatorKey,
        _refresh = Listenable.merge([
          startupNotifier,
          authSessionNotifier,
          profileGateNotifier,
          connectivityNotifier,
        ]);

  final AppStartupNotifier _startup;
  final ProfileGateNotifier _gate;
  final ConnectivityNotifier _connectivity;
  final GlobalKey<NavigatorState> _navigatorKey;
  final Listenable _refresh;

  late final router = GoRouter(
    navigatorKey: _navigatorKey,
    observers: [CNTabBarRouteObserver()],
    refreshListenable: _refresh,
    initialLocation: '/loading',
    onException: (context, state, router) {
      final eventId = parseScheduleLiveActivityEventId(state.uri);
      if (eventId != null) {
        ScheduleLiveActivityDeepLinkPending.set(eventId);
        router.go('/calendar');
        return;
      }
      final timetableDay = parseTimetableLiveActivityDayDateKey(state.uri);
      if (timetableDay != null) {
        router.go('/calendar');
        return;
      }
      if (isCalendarHomeWidgetDeepLink(state.uri)) {
        router.go('/calendar');
        return;
      }
    },
    redirect: (context, state) {
      final scheduleEventId = parseScheduleLiveActivityEventId(state.uri);
      if (scheduleEventId != null) {
        ScheduleLiveActivityDeepLinkPending.set(scheduleEventId);
      }
      if (isCalendarHomeWidgetDeepLink(state.uri)) {
        return '/calendar';
      }

      final loc = state.matchedLocation;
      final isLoadingRoute = loc == '/loading';
      final session = Supabase.instance.client.auth.currentSession;
      final loggedIn = session != null;

      if (!_startup.isReady) {
        if (!isLoadingRoute) return '/loading';
        return null;
      }

      if (loggedIn && loc == kNoConnectionPath) {
        return '/loading';
      }

      if (!loggedIn) {
        final offline = _connectivity.isOffline;

        if (offline) {
          if (loc == kNoConnectionPath) return null;
          LoginRouteTransitionTracker.reset();
          return kNoConnectionPath;
        }

        if (loc == kNoConnectionPath) {
          LoginRouteTransitionTracker.reset();
          return LoginPaths.login;
        }

        if (isLoadingRoute) {
          LoginRouteTransitionTracker.reset();
          return LoginPaths.login;
        }
        if (loc == '/calendar' ||
            loc == '/homework' ||
            loc == '/settings') {
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
        if (scheduleEventId != null && !isLoadingRoute) {
          return '/calendar';
        }
        if (isLoadingRoute) return '/calendar';
        if (loc == LoginPaths.success) return null;
        if (loc.startsWith(LoginPaths.login)) return '/calendar';
        return null;
      }

      // Onboarding noch offen: geschützte App-Bereiche und /loading auf den
      // richtigen Schritt umleiten. Vorherige Schritte bleiben erreichbar
      // (z. B. zum Korrigieren), überspringen per Deep-Link wird verhindert.
      if (isLoadingRoute ||
          loc == '/calendar' ||
          loc == '/homework' ||
          loc == '/settings') {
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
      GoRoute(
        path: '/loading',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const LoadingPage(),
        ),
      ),
      GoRoute(
        path: kNoConnectionPath,
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: NoConnectionPage(connectivity: _connectivity),
        ),
      ),
      GoRoute(
        path: '/schedule',
        redirect: (context, state) {
          final eventId = parseScheduleLiveActivityEventId(state.uri) ??
              state.uri.queryParameters['eventId']?.trim();
          if (eventId != null && eventId.isNotEmpty) {
            ScheduleLiveActivityDeepLinkPending.set(eventId);
          }
          return '/calendar';
        },
      ),
      GoRoute(
        path: '/timetable',
        redirect: (context, state) => '/calendar',
      ),
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, navigationShell) => NoTransitionPage(
          key: state.pageKey,
          child: MainShellScaffold(navigationShell: navigationShell),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const CalendarPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/homework',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const HomeworkPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const SettingsPage(),
                ),
              ),
            ],
          ),
        ],
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
