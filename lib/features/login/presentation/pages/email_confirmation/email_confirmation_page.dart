import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/auth_repository.dart';
import '../../../domain/models/login_flow_step.dart';
import '../../providers/auth_repository_provider.dart';
import '../../providers/login_step_scaffold.dart';
import '../../routes/login_routes.dart';
import '../../state/login_flow_draft.dart';

class EmailConfirmationPage extends ConsumerStatefulWidget {
  const EmailConfirmationPage({super.key});

  @override
  ConsumerState<EmailConfirmationPage> createState() =>
      _EmailConfirmationPageState();
}

class _EmailConfirmationPageState extends ConsumerState<EmailConfirmationPage> {
  bool _busy = false;
  bool _resendBusy = false;

  Future<void> _showMessage(
    String message, {
    AppToastKind kind = AppToastKind.info,
  }) async {
    if (!mounted) return;
    showAppToast(context, message, kind: kind);
  }

  Future<void> _retryVerification(void Function() goNext) async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final draft = LoginFlowDraft.instance;

      final hasVerifiedSession = await repo.refreshUserVerificationState();
      if (hasVerifiedSession) {
        if (!mounted) return;
        context.go(LoginPaths.role);
        return;
      }

      await repo.signInWithPassword(
        email: draft.email,
        password: draft.password,
      );
      if (!mounted) return;
      goNext();
    } on AuthRepositoryException catch (e) {
      await _showMessage(e.message, kind: AppToastKind.error);
    } catch (_) {
      await _showMessage(
        'Bestätigungsstatus konnte nicht geprüft werden. Bitte versuche es erneut.',
        kind: AppToastKind.error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resendEmail() async {
    setState(() => _resendBusy = true);
    try {
      final draft = LoginFlowDraft.instance;
      final repo = ref.read(authRepositoryProvider);
      final sessionUserEmail = repo.currentUserEmail;
      final targetEmail = draft.email.trim().isNotEmpty
          ? draft.email
          : (sessionUserEmail ?? '');
      await repo.resendConfirmationEmail(
            email: targetEmail,
          );
      await _showMessage(
        'Bestätigungs-E-Mail wurde erneut gesendet.',
        kind: AppToastKind.success,
      );
    } on AuthRepositoryException catch (e) {
      await _showMessage(e.message, kind: AppToastKind.error);
    } catch (_) {
      await _showMessage(
        'Bestätigungs-E-Mail konnte nicht erneut gesendet werden.',
        kind: AppToastKind.error,
      );
    } finally {
      if (mounted) setState(() => _resendBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = LoginFlowDraft.instance.email.trim();
    return LoginStepScaffold(
      step: LoginFlowStep.credentials,
      titleOverride: 'E-Mail bestätigen',
      submitLabel: 'Erneut prüfen',
      submitBusy: _busy,
      backPath: LoginPaths.credentials,
      nextPath: LoginPaths.role,
      onAsyncProceed: _retryVerification,
      footer: Column(
        children: [
          TextButton(
            onPressed: _resendBusy ? null : _resendEmail,
            child: _resendBusy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Bestätigungs-E-Mail erneut senden'),
          ),
          TextButton(
            onPressed: () => context.go(LoginPaths.login),
            child: const Text('Zur Anmeldung'),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Text(
          'Wir haben eine Bestätigungs-E-Mail an $email gesendet. '
          'Bitte bestätige deine Adresse und tippe dann auf „Erneut prüfen“.',
          style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
        ),
      ),
    );
  }
}
