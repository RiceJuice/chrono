import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/auth_repository.dart';
import '../../domain/models/login_flow_step.dart';
import '../widgets/buttons.dart';
import '../widgets/login_slide_scope.dart';
import '../widgets/top_bar/login_top_bar.dart';
import '../widgets/top_bar/step_indicator.dart';

/// [LoginStepScaffold.canProceed] hat `false` geliefert; kein zusätzlicher Toast.
final class LoginStepProceedBlocked implements Exception {
  const LoginStepProceedBlocked();
}

/// Fehler wurde bereits auf der Seite angezeigt (z. B. Toast); kein zweiter Toast.
final class LoginStepErrorAlreadyShown implements Exception {
  const LoginStepErrorAlreadyShown();
}

class LoginStepScaffold extends StatelessWidget {
  const LoginStepScaffold({
    super.key,
    required this.step,
    required this.child,
    this.backPath,
    this.nextPath,
    this.canProceed,
    this.onAsyncProceed,
    this.submitBusy = false,
    this.titleOverride,
    this.submitLabel,
    this.footer,
    this.resizeToAvoidBottomInset = true,
  });

  final LoginFlowStep step;
  final Widget child;
  final String? backPath;
  final String? nextPath;
  final bool Function()? canProceed;
  final Future<void> Function(void Function() goNext)? onAsyncProceed;
  final bool submitBusy;
  final String? titleOverride;
  final String? submitLabel;
  final Widget? footer;

  /// `false`: Tastatur legt sich über den Inhalt (kein Hochschieben); sinnvoll bei
  /// Formularen, wenn der Submit-Button unten fix bleiben soll.
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoginTopBar(
                onBack: backPath != null ? () => context.go(backPath!) : null,
              ),
              const SizedBox(height: 20),
              LoginStepIndicator(currentStep: step.stepNumber),
              const SizedBox(height: 30),
              Text(
                titleOverride ?? step.title,
                style: GoogleFonts.libreBaskerville(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Expanded(
                child: LoginSlideLayer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: child),
                      if (footer != null) ...[
                        Align(alignment: Alignment.center, child: footer!),
                        const SizedBox(height: 32),
                      ],
                      Align(
                        child: LoginPrimaryButton(
                          label: submitLabel ?? 'Speichern',
                          color: step.accentColor,
                          isLoading: submitBusy,
                          onPressed: () async {
                            final shouldProceed = canProceed?.call() ?? true;
                            if (!shouldProceed) {
                              throw const LoginStepProceedBlocked();
                            }

                            void goNext() {
                              final path = nextPath;
                              if (path == null) {
                                context.go('/calendar');
                                return;
                              }
                              context.go(path);
                            }

                            final asyncProceed = onAsyncProceed;
                            if (asyncProceed != null) {
                              try {
                                await asyncProceed(goNext);
                              } catch (e) {
                                if (e is LoginStepErrorAlreadyShown) {
                                  rethrow;
                                }
                                if (!context.mounted) return;
                                final message = e is AuthRepositoryException
                                    ? e.message
                                    : 'Der Schritt konnte nicht abgeschlossen werden. Bitte erneut versuchen.';
                                showAppToast(
                                  context,
                                  message,
                                  kind: AppToastKind.error,
                                );
                                rethrow;
                              }
                            } else {
                              goNext();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}