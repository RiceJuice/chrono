import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/models/login_flow_step.dart';
import '../widgets/buttons.dart';
import '../widgets/top_bar/login_top_bar.dart';
import '../widgets/top_bar/step_indicator.dart';

class LoginStepScaffold extends StatelessWidget {
  const LoginStepScaffold({
    super.key,
    required this.step,
    required this.child,
    this.backPath,
    this.nextPath,
  });

  final LoginFlowStep step;
  final Widget child;
  final String? backPath;
  final String? nextPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoginTopBar(
                canGoBack: backPath != null,
                onBack: () {
                  final path = backPath;
                  if (path != null) {
                    context.go(path);
                  }
                },
              ),
              const SizedBox(height: 12),
              LoginStepIndicator(currentStep: step.stepNumber),
              const SizedBox(height: 18),
              Text(
                step.title,
                style: GoogleFonts.libreBaskerville(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 28),
              Expanded(child: child),
              Align(
                alignment: Alignment.bottomRight,
                child: LoginPrimaryButton(
                  label: 'Speichern',
                  color: step.accentColor,
                  onPressed: () {
                    final path = nextPath;
                    if (path == null) {
                      context.go('/calendar');
                      return;
                    }
                    context.go(path);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
