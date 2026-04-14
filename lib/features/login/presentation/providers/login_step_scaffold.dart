import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/auth_repository.dart';
import '../../domain/models/login_flow_step.dart';
import '../routes/login_routes.dart';
import '../widgets/buttons.dart';
import '../widgets/login_scroll_surface.dart';

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
    this.nextPath,
    this.canProceed,
    this.onAsyncProceed,
    this.submitBusy = false,
    this.titleOverride,
    this.submitLabel,
    this.footer,
  });

  final LoginFlowStep step;
  final Widget child;
  final String? nextPath;
  final bool Function()? canProceed;
  final Future<void> Function(void Function() goNext)? onAsyncProceed;
  final bool submitBusy;
  final String? titleOverride;
  final String? submitLabel;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    final double buttonHorizontalPadding = location == LoginPaths.choir ? 20 : 0;

    // SafeArea/Padding/Scaffold liefert [LoginOnboardingShell].
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titleOverride ?? step.title,
          style: GoogleFonts.libreBaskerville(
            color: Colors.white,
            fontSize: 44,
            fontWeight: FontWeight.w700,
          ),
        ),
        Expanded(
          child: LoginScrollSurface(child: child),
        ),
        if (footer != null) ...[
          Align(alignment: Alignment.center, child: footer!),
          const SizedBox(height: 32),
        ],
        Padding(
          padding: EdgeInsets.symmetric(horizontal: buttonHorizontalPadding),
          child: Align(
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
        ),
      ],
    );
  }
}