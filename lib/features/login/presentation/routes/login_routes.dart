import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../pages/credentials/credentials_page.dart';
import '../pages/credentials/widgets/account_auth_mode.dart';
import '../pages/email_confirmation/email_confirmation_page.dart';
import '../pages/select_choir/select_choir.dart';
import '../pages/select_personal_data/personal_data.dart';
import '../pages/start_screen/start_screen_page.dart';
import '../pages/select_role/select_role.dart';
import '../widgets/login_onboarding_shell.dart';
import 'login_flow_specs.dart';
import 'login_morph_page_transition.dart';
import 'login_paths.dart';

export 'login_paths.dart';

/// Slide-Richtung für Login-Unterseiten: wird im [ShellRoute]-Builder gesetzt,
/// bevor die [CustomTransitionPage]s gebaut werden (vermeidet falsche Richtung
/// bei Zwischen-Builds der ausgehenden Route).
abstract final class LoginRouteTransitionTracker {
  static String? _lastLocation;
  static bool _transitionForward = true;
  static bool _enterWithoutTransition = false;

  static void reset() {
    _lastLocation = null;
    _transitionForward = true;
    _enterWithoutTransition = false;
  }

  static bool get transitionForward => _transitionForward;

  /// Einmalig nach App-Start oder Wechsel von außerhalb des Login-Flows.
  static bool consumeEnterWithoutTransition() {
    if (!_enterWithoutTransition) return false;
    _enterWithoutTransition = false;
    return true;
  }

  static void syncShellLocation(String location) {
    final previous = _lastLocation;
    if (location.startsWith(LoginPaths.login) &&
        (previous == null || !previous.startsWith(LoginPaths.login))) {
      _enterWithoutTransition = true;
    }

    if (previous == location) {
      return;
    }

    if (previous != null &&
        location.startsWith(LoginPaths.login) &&
        previous.startsWith(LoginPaths.login)) {
      final prevIdx = loginFlowOrderIndex(previous);
      final nextIdx = loginFlowOrderIndex(location);
      if (prevIdx >= 0 && nextIdx >= 0) {
        _transitionForward = nextIdx > prevIdx;
      } else {
        _transitionForward = true;
      }
    } else {
      _transitionForward = true;
    }
    _lastLocation = location;
  }
}

Page<void> loginSlidePage({
  required GoRouterState state,
  required Widget child,
}) {
  if (LoginRouteTransitionTracker.consumeEnterWithoutTransition()) {
    return NoTransitionPage<void>(key: state.pageKey, child: child);
  }

  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    opaque: false,
    transitionDuration: kLoginMorphDuration,
    reverseTransitionDuration: kLoginMorphDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Richtung zur Laufzeit lesen: die ausgehende Route wurde oft bei einem
      // frueheren Navigations-Schritt gebaut und haette sonst eine veraltete
      // forward-Richtung (Morph kommt von der falschen Seite).
      return buildLoginMorphPageTransition(
        context: context,
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        forward: LoginRouteTransitionTracker.transitionForward,
        child: child,
      );
    },
  );
}

AccountAuthMode _authModeFromQuery(GoRouterState state) {
  final raw = state.uri.queryParameters['mode'];
  if (raw == 'signIn') return AccountAuthMode.signIn;
  return AccountAuthMode.signUp;
}

final List<RouteBase> loginRoutes = [
  ShellRoute(
    builder: (context, state, child) {
      LoginRouteTransitionTracker.syncShellLocation(state.matchedLocation);
      return LoginOnboardingShell(state: state, child: child);
    },
    routes: [
      GoRoute(
        path: LoginPaths.login,
        pageBuilder: (context, state) => loginSlidePage(
              state: state,
              child: const StartScreenPage(),
            ),
      ),
      GoRoute(
        path: LoginPaths.credentials,
        pageBuilder: (context, state) => loginSlidePage(
              state: state,
              child: CredentialsPage(
                initialMode: _authModeFromQuery(state),
              ),
            ),
      ),
      GoRoute(
        path: LoginPaths.role,
        pageBuilder: (context, state) => loginSlidePage(
              state: state,
              child: const SelectRolePage(),
            ),
      ),
      GoRoute(
        path: LoginPaths.personalData,
        pageBuilder: (context, state) => loginSlidePage(
              state: state,
              child: const PersonalDataPage(),
            ),
      ),
      GoRoute(
        path: LoginPaths.choir,
        pageBuilder: (context, state) => loginSlidePage(
              state: state,
              child: const ChoirPage(),
            ),
      ),
      GoRoute(
        path: LoginPaths.emailConfirmation,
        pageBuilder: (context, state) => loginSlidePage(
              state: state,
              child: const EmailConfirmationPage(),
            ),
      ),
    ],
  ),
];
