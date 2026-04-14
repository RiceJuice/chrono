import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/login_flow_step.dart';
import '../routes/login_routes.dart';
import 'top_bar/login_top_bar.dart';
import 'top_bar/step_indicator.dart';

/// Fester Rahmen für den Login-Onboarding-Flow: Top-Bar und Schritt-Indikator
/// werden nicht mit dem Seitenwechsel animiert.
class LoginOnboardingShell extends StatelessWidget {
  const LoginOnboardingShell({
    super.key,
    required this.state,
    required this.child,
  });

  final GoRouterState state;
  final Widget child;

  String? _backPath(String location) {
    switch (location) {
      case LoginPaths.login:
        return null;
      case LoginPaths.credentials:
        return LoginPaths.login;
      case LoginPaths.emailConfirmation:
        return LoginPaths.credentials;
      case LoginPaths.role:
        return LoginPaths.credentials;
      case LoginPaths.personalData:
        return LoginPaths.role;
      case LoginPaths.choir:
        return LoginPaths.personalData;
      default:
        return null;
    }
  }

  int? _stepNumber(String location) {
    switch (location) {
      case LoginPaths.login:
        return null;
      case LoginPaths.credentials:
      case LoginPaths.emailConfirmation:
        return LoginFlowStep.credentials.stepNumber;
      case LoginPaths.role:
        return LoginFlowStep.role.stepNumber;
      case LoginPaths.personalData:
        return LoginFlowStep.personalData.stepNumber;
      case LoginPaths.choir:
        return LoginFlowStep.choir.stepNumber;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = state.matchedLocation;
    final isStart = location == LoginPaths.login;
    final isChoirPage = location == LoginPaths.choir;
    final back = _backPath(location);
    final step = _stepNumber(location);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: LoginTopBar(
                onBack: back != null ? () => context.go(back) : null,
              ),
            ),
            if (!isStart && step != null) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: LoginStepIndicator(currentStep: step),
              ),
              const SizedBox(height: 30),
            ],
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isChoirPage ? 0 : 20,
                  0,
                  isChoirPage ? 0 : 20,
                  18,
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
