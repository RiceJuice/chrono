import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../pages/credentials/credentials_page.dart';
import '../pages/credentials/widgets/account_auth_mode.dart';
import '../pages/email_confirmation/email_confirmation_page.dart';
import '../pages/select_choir/select_choir.dart';
import '../pages/select_personal_data/personalData.dart';
import '../pages/start_screen/start_screen_page.dart';
import '../pages/select_role/select_role.dart';
import '../widgets/login_slide_scope.dart';

abstract final class LoginPaths {
  static const login = '/login';
  static const credentials = '/login/credentials';
  static const role = '/login/role';
  static const personalData = '/login/personal-data';
  static const choir = '/login/choir';
  static const emailConfirmation = '/login/email-confirmation';

  /// Reihenfolge im Onboarding für Slide-Richtung (größer = weiter im Flow).
  static int slideIndex(String location) {
    switch (location) {
      case login:
        return 0;
      case credentials:
        return 1;
      case emailConfirmation:
        return 2;
      case role:
        return 3;
      case personalData:
        return 4;
      case choir:
        return 5;
      default:
        return -1;
    }
  }
}

/// Merkt sich die letzte Login-URL, damit [context.go] Vorwärts vs. Zurück erkennen kann.
///
/// Wichtig: Bei verschachtelten [GoRoute]s ruft go_router den [pageBuilder] auch für
/// Parent-Matches auf (z. B. `/login` unter `/login/credentials`). Nur der **Leaf**-Match
/// (`state.matchedLocation == state.uri.path`) darf den Tracker aktualisieren, sonst wird
/// `_lastLocation` mit dem Parent-Pfad überschrieben und die Richtung ist falsch.
abstract final class LoginRouteTransitionTracker {
  static String? _lastLocation;

  static void reset() => _lastLocation = null;

  /// `true`: neue Seite kommt von rechts. `false`: von links (zurück im Flow).
  static bool consumeSlideForward(String location) {
    final previous = _lastLocation;
    _lastLocation = location;

    if (previous == null || !previous.startsWith(LoginPaths.login)) {
      return true;
    }
    if (!location.startsWith(LoginPaths.login)) {
      _lastLocation = null;
      return true;
    }

    final prevIdx = LoginPaths.slideIndex(previous);
    final nextIdx = LoginPaths.slideIndex(location);
    if (prevIdx < 0 || nextIdx < 0) {
      return true;
    }
    if (prevIdx == nextIdx) {
      return true;
    }
    return nextIdx > prevIdx;
  }
}

const Duration _loginSlideDuration = Duration(milliseconds: 300);

CustomTransitionPage<void> loginSlidePage({
  required GoRouterState state,
  required Widget child,
}) {
  final uriPath = state.uri.path;
  final isLeafMatch = state.matchedLocation == uriPath;
  final forward = isLeafMatch
      ? LoginRouteTransitionTracker.consumeSlideForward(uriPath)
      : true;

  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: _loginSlideDuration,
    reverseTransitionDuration: _loginSlideDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return LoginSlideScope(
        forward: forward,
        animation: animation,
        child: child,
      );
    },
  );
}

AccountAuthMode _authModeFromQuery(GoRouterState state) {
  final raw = state.uri.queryParameters['mode'];
  if (raw == 'signUp') return AccountAuthMode.signUp;
  return AccountAuthMode.signIn;
}

final List<RouteBase> loginRoutes = [
  GoRoute(
    path: LoginPaths.login,
    pageBuilder: (context, state) => loginSlidePage(
          state: state,
          child: const StartScreenPage(),
        ),
    routes: [
      GoRoute(
        path: 'credentials',
        pageBuilder: (context, state) => loginSlidePage(
              state: state,
              child: CredentialsPage(
                initialMode: _authModeFromQuery(state),
              ),
            ),
      ),
      GoRoute(
        path: 'role',
        pageBuilder: (context, state) => loginSlidePage(
              state: state,
              child: const SelectRolePage(),
            ),
      ),
      GoRoute(
        path: 'personal-data',
        pageBuilder: (context, state) => loginSlidePage(
              state: state,
              child: const PersonalDataPage(),
            ),
      ),
      GoRoute(
        path: 'choir',
        pageBuilder: (context, state) => loginSlidePage(
              state: state,
              child: const ChoirPage(),
            ),
      ),
      GoRoute(
        path: 'email-confirmation',
        pageBuilder: (context, state) => loginSlidePage(
              state: state,
              child: const EmailConfirmationPage(),
            ),
      ),
    ],
  ),
];
