import 'dart:async';

import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_mail/open_mail.dart';

import '../../../data/auth_repository.dart';
import '../../../domain/models/login_flow_step.dart';
import '../../providers/auth_repository_provider.dart';
import '../../providers/login_step_scaffold.dart';
import '../../providers/profile_gate_provider.dart';
import '../../routes/login_routes.dart';
import '../../state/login_flow_draft.dart';
import '../credentials/credentials_page.dart';
import 'widgets/email_confirmation_body.dart';
import 'widgets/email_confirmation_footer.dart';
import 'widgets/email_confirmation_ui.dart';

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
  bool _resendBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      unawaited(_runAdvanceCheck());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_runAdvanceCheck());
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
      unawaited(_runAdvanceCheck());
    }
  }

  Future<void> _showMessage(
    String message, {
    AppToastKind kind = AppToastKind.info,
  }) async {
    if (!mounted) return;
    showAppToast(context, message, kind: kind);
  }

  Future<void> _runAdvanceCheck() async {
    if (!mounted || _advancing) return;
    _advancing = true;
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
    } on AuthRepositoryException {
      if (!mounted) return;
    } catch (_) {
      if (!mounted) return;
    } finally {
      _advancing = false;
    }
  }

  Future<void> _openMailApp() async {
    try {
      final result = await OpenMail.openMailApp();
      if (result.didOpen) return;
    } catch (_) {
      // Fehler wird über Toast behandelt.
    }

    if (!mounted) return;
    await _showMessage(
      'Die E-Mail-App konnte nicht geöffnet werden.',
      kind: AppToastKind.error,
    );
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
      await repo.resendConfirmationEmail(email: targetEmail);
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
    final metrics = EmailConfirmationLayoutMetrics.fromContext(context);
    final styles = EmailConfirmationTextStyles.fromContext(context);
    final email = _resolveRecipientEmail();

    return LoginStepScaffold(
      step: LoginFlowStep.credentials,
      titleOverride: 'E-Mail bestätigen',
      showPrimaryButton: true,
      submitLabel: 'E-Mail-App öffnen',
      nextPath: LoginPaths.role,
      centerChildInScrollViewport: true,
      contentMaxWidth: CredentialsPage.maxFormWidth,
      primaryButtonMaxWidth: CredentialsPage.maxFormWidth,
      footerLeadHeight: metrics.footerLead,
      footerTailHeight: metrics.footerTail,
      onAsyncProceed: (_) async {
        await _openMailApp();
      },
      footer: EmailConfirmationFooter(
        styles: styles,
        resendBusy: _resendBusy,
        onResend: () => unawaited(_resendEmail()),
      ),
      child: EmailConfirmationBody(
        email: email,
        metrics: metrics,
        styles: styles,
        onEmailTap: () => unawaited(_openMailApp()),
      ),
    );
  }

  String _resolveRecipientEmail() {
    final draftEmail = LoginFlowDraft.instance.email.trim();
    if (draftEmail.isNotEmpty) return draftEmail;
    final repoEmail = ref.read(authRepositoryProvider).currentUserEmail?.trim();
    if (repoEmail != null && repoEmail.isNotEmpty) return repoEmail;
    return 'deine E-Mail-Adresse';
  }
}
