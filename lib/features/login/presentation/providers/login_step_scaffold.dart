import 'package:chronoapp/core/widgets/app_toast.dart';
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
    this.canProceed,
    this.onAsyncProceed,
    this.submitBusy = false,
    this.titleOverride,
    this.submitLabel,
    this.footer,
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
                    if (!shouldProceed) return;

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
                      } catch (_) {
                        if (!context.mounted) return;
                        showAppToast(
                          context,
                          'Der Schritt konnte nicht abgeschlossen werden. Bitte erneut versuchen.',
                          kind: AppToastKind.error,
                        );
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
    );
  }
}