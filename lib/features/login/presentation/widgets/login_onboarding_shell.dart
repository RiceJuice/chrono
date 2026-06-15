import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routes/login_paths.dart';
import 'login_split_screen.dart';

/// Fester Rahmen für den Login-Onboarding-Flow: Scaffold + Split-Layout.
/// Top-Bar und Schritt-Indikator liegen in [LoginFlowChrome] im Seiteninhalt.
class LoginOnboardingShell extends StatelessWidget {
  const LoginOnboardingShell({
    super.key,
    required this.state,
    required this.child,
  });

  final GoRouterState state;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = state.matchedLocation;
    final isStart = location == LoginPaths.login;
    final isChoirPage = location == LoginPaths.choir;
    final bool resizeBody = location != LoginPaths.credentials;

    return Scaffold(
      resizeToAvoidBottomInset: resizeBody,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LoginSplitScreen(
        contentMaxWidth: isChoirPage ? 620 : 560,
        child: SafeArea(
          // Startscreen: Squircle-Panel bis zum unteren Bildschirmrand.
          bottom: !isStart,
          child: child,
        ),
      ),
    );
  }
}
