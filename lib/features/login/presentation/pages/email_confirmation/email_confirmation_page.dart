import 'dart:async';

import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/auth_repository.dart';
import '../../../domain/models/login_flow_step.dart';
import '../../providers/auth_repository_provider.dart';
import '../../providers/login_step_scaffold.dart';
import '../../providers/profile_gate_provider.dart';
import '../../routes/login_routes.dart';
import '../../state/login_flow_draft.dart';

class EmailConfirmationPage extends ConsumerStatefulWidget {
  const EmailConfirmationPage({super.key});

  @override
  ConsumerState<EmailConfirmationPage> createState() =>
      _EmailConfirmationPageState();
}

class _EmailConfirmationPageState extends ConsumerState<EmailConfirmationPage>
    with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 5);

  Timer? _pollTimer;
  bool _advancing = false;
  bool _manualBusy = false;
  bool _resendBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      unawaited(_runAdvanceCheck(silent: true));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_runAdvanceCheck(silent: true));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_runAdvanceCheck(silent: true));
    }
  }

  Future<void> _showMessage(
    String message, {
    AppToastKind kind = AppToastKind.info,
  }) async {
    if (!mounted) return;
    showAppToast(context, message, kind: kind);
  }

  Future<void> _runAdvanceCheck({required bool silent}) async {
    if (!mounted || _advancing) return;
    _advancing = true;
    if (!silent && mounted) setState(() => _manualBusy = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final draft = LoginFlowDraft.instance;

      final advanced = await repo.tryAdvanceAfterEmailConfirmation(
        email: draft.email,
        password: draft.password,
      );
      if (!advanced || !mounted) return;

      await ref.read(profileGateProvider).refresh();
      if (!mounted) return;
      final target =
          ref.read(profileGateProvider).requiredPath ?? LoginPaths.role;
      context.go(target);
    } on AuthRepositoryException catch (e) {
      if (!mounted) return;
      if (silent) {
        debugPrint('E-Mail-Bestätigung (Hintergrund): ${e.message}');
        return;
      }
      await _showMessage(e.message, kind: AppToastKind.error);
    } catch (_) {
      if (!mounted) return;
      if (silent) {
        debugPrint('E-Mail-Bestätigung (Hintergrund): unbekannter Fehler');
        return;
      }
      await _showMessage(
        'Bestätigungsstatus konnte nicht geprüft werden. Bitte versuche es erneut.',
        kind: AppToastKind.error,
      );
    } finally {
      _advancing = false;
      if (mounted && !silent) setState(() => _manualBusy = false);
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
      showPrimaryButton: false,
      nextPath: LoginPaths.role,
      footer: Column(
        children: [
          TextButton(
            onPressed: (_manualBusy || _resendBusy)
                ? null
                : () => unawaited(_runAdvanceCheck(silent: false)),
            child: _manualBusy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Jetzt prüfen'),
          ),
          TextButton(
            onPressed: _resendBusy ? null : () => unawaited(_resendEmail()),
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
          'Bitte bestätige deine Adresse — wir prüfen automatisch im Hintergrund, '
          'sobald du den Link in der Mail nutzt.',
          style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
        ),
      ),
    );
  }
}
