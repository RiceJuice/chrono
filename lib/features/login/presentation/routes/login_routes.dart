import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../pages/credentials/credentials_page.dart';
import '../pages/credentials/widgets/account_auth_mode.dart';
import '../pages/email_confirmation/email_confirmation_page.dart';
import '../pages/select_choir/select_choir.dart';
import '../pages/select_personal_data/personalData.dart';
import '../pages/start_screen/start_screen_page.dart';
import '../pages/select_role/select_role.dart';
import '../widgets/login_onboarding_shell.dart';

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

/// Slide-Richtung für Login-Unterseiten: wird im [ShellRoute]-Builder gesetzt,
/// bevor die [CustomTransitionPage]s gebaut werden (vermeidet falsche Richtung
/// bei Zwischen-Builds der ausgehenden Route).
abstract final class LoginRouteTransitionTracker {
  static String? _lastLocation;
  static bool _transitionForward = true;

  static void reset() {
    _lastLocation = null;
    _transitionForward = true;
  }

  static bool get transitionForward => _transitionForward;

  static void syncShellLocation(String location) {
    if (_lastLocation == location) {
      return;
    }

    if (_lastLocation != null &&
        location.startsWith(LoginPaths.login) &&
        _lastLocation!.startsWith(LoginPaths.login)) {
      final prevIdx = LoginPaths.slideIndex(_lastLocation!);
      final nextIdx = LoginPaths.slideIndex(location);
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

const Duration _loginSlideDuration = Duration(milliseconds: 300);

CustomTransitionPage<void> loginSlidePage({
  required GoRouterState state,
  required Widget child,
}) {
  final forward = LoginRouteTransitionTracker.transitionForward;

  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: _loginSlideDuration,
    reverseTransitionDuration: _loginSlideDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Vorwärts im Flow: Inhalt kommt von rechts. Zurück: von links.
      // (secondaryAnimation betrifft die darunterliegende Route; hier nur die
      // eingehende Seite animieren, damit der Shell-Header statisch bleibt.)
      final bg = Theme.of(context).scaffoldBackgroundColor;
      final begin = forward ? const Offset(1, 0) : const Offset(-1, 0);
      return SlideTransition(
        position: Tween<Offset>(begin: begin, end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: ClipRect(
          child: DecoratedBox(
            decoration: BoxDecoration(color: bg),
            child: SizedBox.expand(child: child),
          ),
        ),
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
